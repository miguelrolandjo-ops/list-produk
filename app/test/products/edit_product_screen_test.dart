import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/edit_product_screen.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('edit name, unit, category and supplier price, then save', (
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
      id = await ProductService(db).addManual(
        const NewProductInput(
          name: 'Kabel USB-C',
          categoryName: 'Kabel',
          supplierName: 'CV Maju',
          supplyPrice: 9500,
        ),
      );
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/ubah',
          builder: (_, _) => EditProductScreen(productId: id),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/ubah');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle();

    // Pre-filled from the product.
    expect(find.widgetWithText(TextFormField, 'Kabel USB-C'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Kabel'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '9.500'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kabel USB-C'),
      'Kabel USB-C 2M',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kabel'),
      'Aksesoris',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '9.500'), '12000');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('box').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await settle();
    await settle();

    final rows = await tester.runAsync(
      () => db
          .customSelect(
            'SELECT p.name, p.unit, c.name AS category, p.retail_price '
            'FROM products p LEFT JOIN categories c ON c.id = p.category_id',
          )
          .get(),
    );
    final p = rows!.single;
    expect(p.read<String>('name'), 'Kabel USB-C 2M');
    expect(p.read<String>('unit'), 'box');
    expect(p.read<String>('category'), 'Aksesoris');
    final retail = await tester.runAsync(
      () => ProductService(db).preview(12000),
    );
    expect(p.read<int>('retail_price'), retail!.retail);
    final prices = await tester.runAsync(
      () => db.customSelect('SELECT unit_price FROM supplier_prices').get(),
    );
    expect(prices, hasLength(2)); // history kept
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('an empty name is refused', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    late String id;
    await tester.runAsync(() async {
      id = await ProductService(db).addManual(
        const NewProductInput(
          name: 'Kabel',
          supplierName: 'CV Maju',
          supplyPrice: 9500,
        ),
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: MaterialApp(home: EditProductScreen(productId: id)),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Kabel'), '  ');
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('Nama produk wajib diisi'), findsOneWidget);
  });
}
