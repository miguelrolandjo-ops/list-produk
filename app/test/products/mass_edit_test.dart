import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/display_prefs.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/product_list_screen.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Default display settings without touching the real preferences store.
class _FakeDisplayPrefs extends DisplayPrefsNotifier {
  @override
  DisplayPrefs build() => const DisplayPrefs(
    showMarginWarning: true,
    showOverrideIcon: true,
    backupReminder: true,
  );
}

void main() {
  late OwnerDatabase db;

  Future<void> pumpList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.runAsync(() async {
      final service = ProductService(db);
      for (final name in ['Alfa', 'Bravo', 'Charlie']) {
        await service.addManual(
          NewProductInput(name: name, supplierName: 'CV Maju', supplyPrice: 9500),
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
            routes: [
              GoRoute(path: '/', builder: (_, _) => const ProductListScreen()),
            ],
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<List<String>> column(String col) async => [
    for (final r in await db
        .customSelect('SELECT $col AS v FROM products ORDER BY name')
        .get())
      '${r.data['v']}',
  ];

  testWidgets('pick two products and change their unit', (tester) async {
    await pumpList(tester);
    expect(find.text('Harga Toko'), findsOneWidget);

    await tester.tap(find.byTooltip('Ubah massal'));
    await tester.pump();
    expect(find.text('0 dipilih'), findsOneWidget);
    expect(find.byTooltip('Tambah manual'), findsNothing);

    await tester.tap(find.text('Alfa'));
    await tester.tap(find.text('Bravo'));
    await tester.pump();
    expect(find.text('2 dipilih'), findsOneWidget);

    await tester.tap(find.byTooltip('Ubah yang dipilih'));
    await frames(tester);
    await tester.tap(find.text('Ubah satuan'));
    await frames(tester);
    await tester.tap(find.text('box'));
    await settle(tester);
    await frames(tester);

    expect(await tester.runAsync(() => column('unit')), ['box', 'box', 'pcs']);
    expect(find.text('2 produk diubah'), findsOneWidget);
    expect(find.text('Harga Toko'), findsOneWidget); // left selection mode
    await finish(tester);
  });

  testWidgets('long press starts selecting; select all; set a category', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.longPress(find.text('Alfa'));
    await tester.pump();
    expect(find.text('1 dipilih'), findsOneWidget);

    await tester.tap(find.byTooltip('Pilih semua'));
    await tester.pump();
    expect(find.text('3 dipilih'), findsOneWidget);

    await tester.tap(find.byTooltip('Ubah yang dipilih'));
    await frames(tester);
    await tester.tap(find.text('Ubah kategori'));
    await frames(tester);
    await tester.enterText(find.byType(TextFormField), 'Aksesoris');
    await tester.tap(find.text('Terapkan'));
    await settle(tester);
    await frames(tester);

    final categories = await tester.runAsync(
      () => db
          .customSelect(
            'SELECT DISTINCT c.name AS n FROM products p '
            'JOIN categories c ON c.id = p.category_id',
          )
          .get(),
    );
    expect(categories!.map((r) => r.read<String>('n')), ['Aksesoris']);
    expect(find.text('3 produk diubah'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('back leaves selection mode without changing anything', (
    tester,
  ) async {
    await pumpList(tester);
    await tester.tap(find.byTooltip('Ubah massal'));
    await tester.pump();
    await tester.tap(find.text('Alfa'));
    await tester.pump();

    await tester.tap(find.byTooltip('Batal pilih'));
    await tester.pump();
    expect(find.text('Harga Toko'), findsOneWidget);
    expect(await tester.runAsync(() => column('unit')), ['pcs', 'pcs', 'pcs']);
    await finish(tester);
  });
}

Future<void> settle(WidgetTester tester) => tester
    .runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    })
    .then((_) => tester.pump());

/// A few real-time frames: sheets and dialogs finish animating. (Not
/// pumpAndSettle: the list's progress indicators never stop animating.)
Future<void> frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Drift closes its streams on a timer after the widgets go away. Unmount and
/// let that timer run inside the test, or it fails on a pending timer.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(seconds: 1));
}
