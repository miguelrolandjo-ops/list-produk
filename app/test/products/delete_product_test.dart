import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/product_detail_screen.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('delete asks first, hides the product, and Undo brings it back', (
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

    late String id;
    await tester.runAsync(() async {
      await initializeDateFormatting('id_ID'); // as main() does
      id = await ProductService(db).addManual(
        const NewProductInput(
          name: 'Kabel USB-C',
          supplierName: 'CV Maju',
          supplyPrice: 9500,
        ),
      );
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('daftar'))),
        GoRoute(
          path: '/produk/:id',
          builder: (_, state) =>
              ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/produk/$id');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle();

    Future<bool> isDeleted() async => (await tester.runAsync(
      () async => (await db
              .customSelect('SELECT deleted_at IS NOT NULL AS d FROM products')
              .getSingle())
          .read<bool>('d'),
    ))!;

    // Nothing says "arsip" any more.
    expect(find.byTooltip('Arsipkan'), findsNothing);

    // Cancel: nothing happens.
    await tester.tap(find.byTooltip('Hapus produk'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Hapus produk?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(await isDeleted(), isFalse);

    // Confirm: soft-deleted, back on the list, Undo offered.
    await tester.tap(find.byTooltip('Hapus produk'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await settle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(await isDeleted(), isTrue);
    expect(find.text('daftar'), findsOneWidget);
    expect(find.text('Produk dihapus'), findsOneWidget);

    // Undo: the product is back.
    await tester.tap(find.text('Urungkan'));
    await settle();
    expect(await isDeleted(), isFalse);
  });
}
