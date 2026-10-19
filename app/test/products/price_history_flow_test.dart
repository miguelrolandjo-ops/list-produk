import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/edit_product_screen.dart';
import 'package:flutter_application_1/products/product_detail_screen.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late OwnerDatabase db;
  late GoRouter router;
  late String id;

  Future<void> settle(WidgetTester tester) => tester
      .runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      })
      .then((_) => tester.pump());

  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.runAsync(() async {
      await initializeDateFormatting('id_ID');
      id = await ProductService(db).addManual(
        const NewProductInput(
          name: 'Kabel USB-C',
          supplierName: 'CV Maju',
          supplyPrice: 9500,
        ),
      );
    });
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('daftar')),
        GoRoute(
          path: '/produk/:id',
          builder: (_, s) => ProductDetailScreen(productId: s.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'ubah',
              builder: (_, s) => EditProductScreen(productId: s.pathParameters['id']!),
            ),
          ],
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
    await frames(tester);
    await settle(tester);
  }

  testWidgets('a supplier price changed in Ubah produk shows up in Riwayat', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byTooltip('Ubah produk'));
    await frames(tester);
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '9.500'), '12000');
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await settle(tester);
    await frames(tester);
    await settle(tester);

    // Back on the detail screen: the new price is current...
    expect(find.text('Rp 12.000'), findsWidgets);

    // ...and the history lists both prices, newest first.
    await tester.tap(find.text('Riwayat'));
    await frames(tester);
    await settle(tester);
    expect(find.text('Riwayat harga supplier'), findsOneWidget);
    final prices = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Text),
        ))
        .map((t) => t.data)
        .where((t) => t != null && t.startsWith('Rp '))
        .toList();
    expect(prices, ['Rp 12.000', 'Rp 9.500']);
  });
}
