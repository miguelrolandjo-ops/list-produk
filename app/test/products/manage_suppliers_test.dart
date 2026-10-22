import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/display_prefs.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/manage_suppliers_screen.dart';
import 'package:flutter_application_1/products/product_list_screen.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeDisplayPrefs extends DisplayPrefsNotifier {
  @override
  DisplayPrefs build() => const DisplayPrefs(
    showMarginWarning: true,
    showOverrideIcon: true,
    backupReminder: true,
  );
}

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

/// Drift closes its streams on a timer once the widgets are gone.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  late OwnerDatabase db;

  Future<void> pump(WidgetTester tester, {required String initial}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.runAsync(() async {
      final service = ProductService(db);
      Future<void> add(String name, String supplier) => service.addManual(
        NewProductInput(name: name, supplierName: supplier, supplyPrice: 9500),
      );
      await add('Kabel A', 'CV Maju');
      await add('Kabel B', 'CV Maju');
      await add('Charger A', 'Toko Sinar');
      await db.customStatement("INSERT INTO suppliers (id, name) VALUES ('s9', 'Tanpa Produk')");
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerDbProvider.overrideWithValue(db),
          displayPrefsProvider.overrideWith(_FakeDisplayPrefs.new),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: initial,
            routes: [
              GoRoute(path: '/', builder: (_, _) => const ProductListScreen()),
              GoRoute(
                path: '/supplier',
                builder: (_, _) => const ManageSuppliersScreen(),
              ),
              GoRoute(path: '/kategori', builder: (_, _) => const Text('kategori')),
            ],
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<List<String>> suppliers() async => (await db
          .customSelect('SELECT name FROM suppliers ORDER BY name')
          .get())
      .map((r) => r.read<String>('name'))
      .toList();

  testWidgets('lists suppliers with how many products they have prices for', (tester) async {
    await pump(tester, initial: '/supplier');
    expect(find.text('CV Maju'), findsOneWidget);
    expect(find.text('2 produk'), findsOneWidget);
    expect(find.text('Toko Sinar'), findsOneWidget);
    expect(find.text('1 produk'), findsOneWidget);
    expect(find.text('Tanpa Produk'), findsOneWidget);
    expect(find.text('0 produk'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('delete explains what goes and asks first; Batal keeps the supplier', (tester) async {
    await pump(tester, initial: '/supplier');
    await tester.tap(find.byTooltip('Hapus supplier CV Maju'));
    await frames(tester);

    expect(find.text('Hapus supplier "CV Maju"?'), findsOneWidget);
    expect(find.textContaining('2 produk punya harga dari supplier ini'), findsOneWidget);
    expect(find.textContaining('Produknya tidak dihapus'), findsOneWidget);
    expect(find.textContaining('menunggu persetujuan Anda'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await frames(tester);
    expect(await tester.runAsync(suppliers), ['CV Maju', 'Tanpa Produk', 'Toko Sinar']);
    await finish(tester);
  });

  testWidgets('confirming removes the supplier and keeps every product', (tester) async {
    await pump(tester, initial: '/supplier');
    await tester.tap(find.byTooltip('Hapus supplier CV Maju'));
    await frames(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await settle(tester);
    await frames(tester);

    expect(await tester.runAsync(suppliers), ['Tanpa Produk', 'Toko Sinar']);
    expect(find.text('CV Maju'), findsNothing);
    expect(find.text('Supplier "CV Maju" dihapus'), findsOneWidget);
    final products = await tester.runAsync(
      () => db.customSelect('SELECT COUNT(*) AS n FROM products').getSingle(),
    );
    expect(products!.read<int>('n'), 3);
    await finish(tester);
  });

  testWidgets('a supplier without prices says so in the dialog', (tester) async {
    await pump(tester, initial: '/supplier');
    await tester.tap(find.byTooltip('Hapus supplier Tanpa Produk'));
    await frames(tester);
    expect(find.text('Supplier ini tidak punya harga untuk produk mana pun.'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the side menu opens Kelola supplier', (tester) async {
    await pump(tester, initial: '/');
    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await frames(tester);
    await tester.tap(find.text('Kelola supplier'));
    await frames(tester);
    await settle(tester);

    expect(find.text('2 produk'), findsOneWidget); // CV Maju, on the new screen
    expect(find.byTooltip('Hapus supplier CV Maju'), findsOneWidget);
    await finish(tester);
  });
}
