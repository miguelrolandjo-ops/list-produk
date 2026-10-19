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

  testWidgets('a new product shows a suggested category and it can be changed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    late String poId;
    await tester.runAsync(() async {
      final service = ProductService(db);
      for (final name in ['Kabel Roll 10M', 'Kabel Listrik 5M', 'Kabel HDMI 3M']) {
        await service.addManual(
          NewProductInput(
            name: name,
            categoryName: 'Kabel',
            supplierName: 'Toko Lama',
            supplyPrice: 9500,
          ),
        );
      }
      poId = await seedSamplePo(db, PoImportService(db));
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: MaterialApp(home: ReviewScreen(poId: poId)),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    // Suggested from the catalog, marked as a guess.
    expect(find.text('Produk baru · Kabel (saran)'), findsOneWidget);

    await tester.tap(find.text('Kabel Micro USB 1M'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah kategori'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Aksesoris');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    // Now the owner's decision: no "(saran)".
    expect(find.text('Produk baru · Aksesoris'), findsOneWidget);
    expect(find.textContaining('(saran)'), findsNothing);
  });

  testWidgets('pick an existing product for a line by hand', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    late String poId;
    await tester.runAsync(() async {
      final service = ProductService(db);
      for (final name in ['Casing Silikon Premium', 'Charger Mobil']) {
        await service.addManual(
          NewProductInput(name: name, supplierName: 'Toko Lama', supplyPrice: 18000),
        );
      }
      poId = await seedSamplePo(db, PoImportService(db));
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: MaterialApp(home: ReviewScreen(poId: poId)),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    // The matcher left this line as a new product (and its price is unreadable).
    expect(find.text('Harga tidak terbaca, isi harga'), findsOneWidget);
    await tester.tap(find.text('Sarung HP Silikon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih produk yang sudah ada'));
    await tester.pumpAndSettle();

    // Search narrows the list; nothing found says so.
    expect(find.text('Casing Silikon Premium'), findsOneWidget);
    expect(find.text('Charger Mobil'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'casing sil');
    await tester.pump();
    expect(find.text('Charger Mobil'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Tidak ada produk yang cocok'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'casing');
    await tester.pump();
    await tester.tap(find.text('Casing Silikon Premium'));
    await tester.pumpAndSettle();

    // The row shows the new mapping right away, together with its warning:
    // the warning no longer hides what the line is linked to.
    expect(find.text('Terhubung: Casing Silikon Premium'), findsOneWidget);
    expect(find.text('Harga tidak terbaca, isi harga'), findsOneWidget);
    expect(find.text('Produk baru'), findsWidgets); // the other new lines

    // The menu agrees: it now offers another product and a way back to
    // "new product", instead of "pick an existing one".
    await tester.tap(find.text('Sarung HP Silikon'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih produk lain'), findsOneWidget);
    expect(find.text('Bukan produk ini, buat produk baru'), findsOneWidget);
    expect(find.text('Pilih produk yang sudah ada'), findsNothing);
  });
}
