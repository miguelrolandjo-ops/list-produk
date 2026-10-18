import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/inbox/debug_sample.dart';
import 'package:flutter_application_1/inbox/po_import_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_application_1/review/review_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('the debug sample equals shared/extraction_sample.json', () {
    final shared = jsonDecode(
      File('../shared/extraction_sample.json').readAsStringSync(),
    );
    expect(jsonDecode(jsonEncode(debugSampleExtraction)), shared);
  });

  testWidgets('review: answer suggestion, fix price, ignore a line, save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    Future<void> settle() => tester
        .runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        })
        .then((_) => tester.pump());

    // A known product from the same supplier, so one line is a suggestion.
    late String poId;
    await tester.runAsync(() async {
      await ProductService(db).addManual(
        const NewProductInput(
          name: 'Kabel Micro USB 1M',
          supplierName: 'CV Maju Elektrik',
          supplyPrice: 7000,
        ),
      );
      poId = await seedSamplePo(db, PoImportService(db));
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/review',
          builder: (_, _) => ReviewScreen(poId: poId),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/review');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle();

    // Header and rows, as in the mockup.
    expect(find.text('CV Maju Elektrik'), findsOneWidget);
    expect(find.text('Cocok 96%'), findsOneWidget);
    expect(find.text('Sama dengan "Kabel Micro USB 1M"?'), findsOneWidget);
    expect(find.text('Teks kurang jelas, cek harga'), findsOneWidget); // 0.62
    expect(find.text('Harga tidak terbaca, isi harga'), findsOneWidget);
    expect(find.text('Simpan 5 produk'), findsOneWidget);
    expect(find.text('Jawab 1 saran produk dulu'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan 5 produk'))
          .onPressed,
      isNull,
    );

    // ✓ on the suggestion.
    await tester.tap(find.byTooltip('Ya'));
    await tester.pump();
    expect(find.text('Isi harga untuk 1 produk baru'), findsOneWidget);

    // Price the line the model could not read.
    await tester.tap(find.text('Sarung HP Silikon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah harga'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20000');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('20.000'), findsOneWidget);

    // Shipping is not a product.
    await tester.tap(find.text('Ongkos kirim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abaikan baris'));
    await tester.pumpAndSettle();
    expect(find.text('Diabaikan'), findsOneWidget);
    expect(find.text('Simpan 4 produk'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Simpan 4 produk'));
    await settle();
    await settle();

    final products = await tester.runAsync(
      () => db.customSelect('SELECT name FROM products ORDER BY name').get(),
    );
    expect(
      products!.map((r) => r.read<String>('name')),
      ['Chrgr Fast 20W', 'Kabel Micro USB 1M', 'Kbl Type C 100cm', 'Sarung HP Silikon'],
    );
    final po = await tester.runAsync(
      () => db.customSelect('SELECT status FROM purchase_orders').getSingle(),
    );
    expect(po!.read<String>('status'), 'saved');
    // Saved and left the screen.
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a PO that is not waiting for review shows an error', (
    tester,
  ) async {
    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ReviewScreen(poId: 'missing')),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    expect(find.text('PO ini tidak bisa dibuka'), findsOneWidget);
  });
}
