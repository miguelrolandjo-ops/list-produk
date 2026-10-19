import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/display_prefs.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/manage_categories_screen.dart';
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

/// Frames without pumpAndSettle: the list's progress indicators never stop.
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
      for (final (name, category) in [
        ('Kabel A', 'Kabel'),
        ('Kabel B', 'Kabel'),
        ('Charger A', 'Charger'),
        ('Casing', null),
      ]) {
        await service.addManual(
          NewProductInput(
            name: name,
            categoryName: category,
            supplierName: 'CV Maju',
            supplyPrice: 9500,
          ),
        );
      }
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
                path: '/kategori',
                builder: (_, _) => const ManageCategoriesScreen(),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<List<String>> categories() async => (await db
          .customSelect('SELECT name FROM categories ORDER BY name')
          .get())
      .map((r) => r.read<String>('name'))
      .toList();

  testWidgets('lists categories with their product counts', (tester) async {
    await pump(tester, initial: '/kategori');
    expect(find.text('Kategori'), findsNothing);
    expect(find.text('Kabel'), findsOneWidget);
    expect(find.text('2 produk'), findsOneWidget);
    expect(find.text('Charger'), findsOneWidget);
    expect(find.text('1 produk'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('delete asks first; cancelling keeps the category', (tester) async {
    await pump(tester, initial: '/kategori');
    await tester.tap(find.byTooltip('Hapus kategori Kabel'));
    await frames(tester);
    expect(find.text('Hapus kategori "Kabel"?'), findsOneWidget);
    expect(find.textContaining('2 produk akan menjadi tanpa kategori'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await frames(tester);
    expect(await tester.runAsync(categories), ['Charger', 'Kabel']);
    await finish(tester);
  });

  testWidgets('confirming deletes the category and keeps the products', (tester) async {
    await pump(tester, initial: '/kategori');
    await tester.tap(find.byTooltip('Hapus kategori Kabel'));
    await frames(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await settle(tester);
    await frames(tester);

    expect(await tester.runAsync(categories), ['Charger']);
    expect(find.text('Kabel'), findsNothing); // gone from the list
    expect(find.text('Kategori "Kabel" dihapus'), findsOneWidget);
    final products = await tester.runAsync(
      () => db.customSelect('SELECT COUNT(*) AS n FROM products').getSingle(),
    );
    expect(products!.read<int>('n'), 4);
    await finish(tester);
  });

  testWidgets('the side menu opens Kelola kategori and drops a deleted filter', (
    tester,
  ) async {
    await pump(tester, initial: '/');

    // Filter the list by Kabel through the side menu.
    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await frames(tester);
    await tester.tap(find.text('Kabel'));
    await frames(tester);
    expect(find.byType(InputChip), findsOneWidget);
    expect(find.text('Charger A'), findsNothing);

    // Delete that category from Kelola kategori.
    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await frames(tester);
    await tester.tap(find.text('Kelola kategori'));
    await frames(tester);
    await tester.tap(find.byTooltip('Hapus kategori Kabel'));
    await frames(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await settle(tester);
    await frames(tester);

    // Back on the list: the filter is gone and everything is shown again.
    await tester.pageBack();
    await settle(tester);
    await frames(tester);
    expect(find.byType(InputChip), findsNothing);
    expect(find.text('Charger A'), findsOneWidget);
    expect(find.text('Kabel A'), findsOneWidget); // still there, uncategorized
    await finish(tester);
  });
}
