import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/add_product_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('typing a supply price previews retail and margin, then saves', (
    tester,
  ) async {
    // Tall screen so the whole form is built (ListView builds lazily).
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    // Real async work (SQLite) only progresses inside runAsync.
    Future<void> settle() => tester
        .runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        })
        .then((_) => tester.pump());

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(path: '/tambah', builder: (_, _) => const AddProductScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/tambah');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama produk'),
      'Kabel USB-C',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Supplier'),
      'CV Maju',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Harga supplier'),
      '9500',
    );
    await settle();

    // 9.500 -> 15.000; margin (15000 - 9500) / 15000 = 36,7%
    expect(find.widgetWithText(TextFormField, '15000'), findsOneWidget);
    expect(find.text('Margin 36,7%'), findsOneWidget);

    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await settle();

    final saved = await tester.runAsync(() => db.select(db.products).get());
    expect(saved!.single.name, 'Kabel USB-C');
    expect(saved.single.retailPrice, 15000);
  });
}
