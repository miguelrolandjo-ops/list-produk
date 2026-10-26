import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/display_prefs.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/price_suggestions_screen.dart';
import 'package:flutter_application_1/products/product_detail_screen.dart';
import 'package:flutter_application_1/products/product_list_screen.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  late ProductService service;

  Future<String> add(
    WidgetTester tester,
    String name, {
    int supply = 9500,
    int? retail,
    int? newPrice,
  }) async {
    final id = (await tester.runAsync(
      () => service.addManual(
        NewProductInput(
          name: name,
          supplierName: 'CV Maju',
          supplyPrice: supply,
          retailPrice: retail,
        ),
      ),
    ))!;
    if (newPrice != null) {
      await tester.runAsync(() async {
        final sup = (await db.customSelect('SELECT id FROM suppliers').getSingle())
            .read<String>('id');
        await service.recordSupplierPrice(id, sup, newPrice);
      });
    }
    return id;
  }

  Future<void> pump(
    WidgetTester tester, {
    required String location,
    required void Function() seed,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    db = OwnerDatabase(NativeDatabase.memory());
    // Each "now" is a minute later, so "the latest price" is never a tie
    // between two prices recorded in the same millisecond.
    var minute = 0;
    service = ProductService(
      db,
      now: () => DateTime.utc(2026, 10, 4, 8, minute++),
    );
    addTearDown(() => tester.runAsync(db.close));
    await tester.runAsync(() => initializeDateFormatting('id_ID'));
    seed();
  }

  Future<void> show(WidgetTester tester, String location) async {
    // Open the screen fresh, as navigating to it does: unmount whatever was
    // showing, or its cached providers are reused and show stale data.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerDbProvider.overrideWithValue(db),
          displayPrefsProvider.overrideWith(_FakeDisplayPrefs.new),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: location,
            routes: [
              GoRoute(path: '/', builder: (_, _) => const ProductListScreen()),
              GoRoute(
                path: '/saran-harga',
                builder: (_, _) => const PriceSuggestionsScreen(),
              ),
              GoRoute(
                path: '/produk/:id',
                builder: (_, s) =>
                    ProductDetailScreen(productId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: '/pengaturan/harga',
                builder: (_, _) => const Text('layar aturan harga'),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);
    await frames(tester);
  }

  Future<int> retailOf(WidgetTester tester, String id) async => (await tester
          .runAsync(
            () => db
                .customSelect(
                  'SELECT retail_price FROM products WHERE id = ?',
                  variables: [Variable.withString(id)],
                )
                .getSingle(),
          ))!
      .read<int>('retail_price');

  group('product detail', () {
    testWidgets('shows the suggestion, higher, and nothing changes until yes', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', newPrice: 10200);
      await show(tester, '/produk/$id');

      expect(find.text('Harga supplier berubah'), findsOneWidget);
      expect(
        find.text('Harga jual disarankan Rp 20.000 (naik Rp 5.000 dari Rp 15.000).'),
        findsOneWidget,
      );
      expect(find.textContaining('Margin dengan harga ini'), findsOneWidget);
      expect(find.text('Terapkan'), findsOneWidget);
      expect(find.text('Tidak'), findsOneWidget);
      // The current price is still the old one.
      expect(await retailOf(tester, id), 15000);
      expect(find.text('Rp 15.000'), findsWidgets);
    });

    testWidgets('lower prices are proposed too', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', supply: 45000, newPrice: 9500);
      await show(tester, '/produk/$id');
      expect(
        find.text('Harga jual disarankan Rp 15.000 (turun Rp 55.000 dari Rp 70.000).'),
        findsOneWidget,
      );
    });

    testWidgets('Terapkan changes the price and the banner goes away', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', newPrice: 10200);
      await show(tester, '/produk/$id');

      await tester.tap(find.text('Terapkan'));
      await settle(tester);
      await frames(tester);

      expect(await retailOf(tester, id), 20000);
      expect(find.text('Harga supplier berubah'), findsNothing);
      expect(find.text('Harga jual diubah menjadi Rp 20.000'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsWidgets);
    });

    testWidgets('Tidak keeps the price, and it is not asked again on reopening', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', newPrice: 10200);
      await show(tester, '/produk/$id');

      await tester.tap(find.text('Tidak'));
      await settle(tester);
      await frames(tester);

      expect(await retailOf(tester, id), 15000);
      expect(find.text('Harga supplier berubah'), findsNothing);
      expect(find.textContaining('Ditanyakan lagi saat harga supplier berubah'), findsOneWidget);

      // Open the product again: no new question.
      await show(tester, '/produk/$id');
      expect(find.text('Harga supplier berubah'), findsNothing);

      // The next supplier price change asks again.
      await tester.runAsync(() async {
        final sup = (await db.customSelect('SELECT id FROM suppliers').getSingle())
            .read<String>('id');
        await service.recordSupplierPrice(id, sup, 10300);
      });
      await show(tester, '/produk/$id');
      expect(
        find.text('Harga jual disarankan Rp 20.000 (naik Rp 5.000 dari Rp 15.000).'),
        findsOneWidget,
      );
    });

    testWidgets('a product with a manual price is never asked about', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', retail: 20000, newPrice: 45000);
      await show(tester, '/produk/$id');
      expect(find.text('Harga supplier berubah'), findsNothing);
    });

    testWidgets('below the margin limit: a recommended price instead of the plain suggestion', (
      tester,
    ) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', newPrice: 12000); // 15.000 is now 20%
      await show(tester, '/produk/$id');

      expect(find.text('Margin di bawah batas'), findsWidgets);
      expect(
        find.text('Margin 20%, batasnya 30%. Disarankan Rp 20.000 (margin 40%).'),
        findsOneWidget,
      );
      expect(find.text('Ubah ke Rp 20.000'), findsOneWidget);
      expect(find.text('Harga supplier berubah'), findsNothing); // taken over
      expect(await retailOf(tester, id), 15000);
    });

    testWidgets('changing to the recommended price takes two clicks', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', newPrice: 12000);
      await show(tester, '/produk/$id');

      // First click: only asks.
      await tester.tap(find.text('Ubah ke Rp 20.000'));
      await tester.pump();
      expect(find.text('Ubah harga jual dari Rp 15.000 ke Rp 20.000?'), findsOneWidget);
      expect(find.text('Ya, ubah'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(await retailOf(tester, id), 15000); // nothing changed yet

      // Batal goes back to the first step.
      await tester.tap(find.text('Batal'));
      await tester.pump();
      expect(find.text('Ubah ke Rp 20.000'), findsOneWidget);
      expect(await retailOf(tester, id), 15000);

      // Second click: confirms.
      await tester.tap(find.text('Ubah ke Rp 20.000'));
      await tester.pump();
      await tester.tap(find.text('Ya, ubah'));
      await settle(tester);
      await frames(tester);

      expect(await retailOf(tester, id), 20000);
      expect(find.text('Harga jual diubah menjadi Rp 20.000'), findsOneWidget);
      expect(find.text('Ubah ke Rp 20.000'), findsNothing); // no longer below the limit
    });

    testWidgets('Abaikan hides the card for good, and Ubah harga still offers the price', (
      tester,
    ) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', newPrice: 12000);
      await show(tester, '/produk/$id');

      await tester.tap(find.text('Abaikan'));
      await settle(tester);
      await frames(tester);
      expect(find.text('Ubah ke Rp 20.000'), findsNothing);
      expect(find.text('Margin di bawah batas'), findsNothing);
      expect(await retailOf(tester, id), 15000); // nothing changed

      // The price dialog still has the recommended price as an option.
      await tester.tap(find.text('Ubah harga'));
      await frames(tester);
      expect(find.text('Disarankan Rp 20.000 (margin 40%)'), findsOneWidget);
      await tester.tap(find.text('Disarankan Rp 20.000 (margin 40%)'));
      await tester.pump();
      expect(find.widgetWithText(TextField, '20.000'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      await settle(tester);
      await frames(tester);
      expect(await retailOf(tester, id), 20000);
    });

    testWidgets('Tambah supplier adds a supplier with its price', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel');
      await show(tester, '/produk/$id');

      await tester.tap(find.text('Tambah supplier'));
      await frames(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Supplier'), 'UD Baru');
      await tester.enterText(find.widgetWithText(TextFormField, 'Harga'), '8000');
      await tester.tap(find.text('Simpan'));
      await settle(tester);
      await frames(tester);

      expect(find.text('UD Baru'), findsOneWidget);
      expect(find.text('Rp 8.000'), findsOneWidget);
    });

    testWidgets('a manual price below the limit gets a recommendation too, and stays manual', (
      tester,
    ) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel', retail: 11000); // 13,6% at 9.500
      await show(tester, '/produk/$id');

      expect(find.text('Ubah ke Rp 15.000'), findsOneWidget);
      await tester.tap(find.text('Ubah ke Rp 15.000'));
      await tester.pump();
      await tester.tap(find.text('Ya, ubah'));
      await settle(tester);
      await frames(tester);

      expect(await retailOf(tester, id), 15000);
      final manual = (await tester.runAsync(
        () => db.customSelect('SELECT retail_is_override AS o FROM products').getSingle(),
      ))!
          .read<int>('o');
      expect(manual, 1);
    });

    testWidgets('a price within the margin limit has no recommendation', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel');
      await show(tester, '/produk/$id');
      expect(find.textContaining('Ubah ke Rp'), findsNothing);
    });

    testWidgets('no banner when nothing changed', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Kabel');
      await show(tester, '/produk/$id');
      expect(find.text('Harga supplier berubah'), findsNothing);
    });
  });

  group('product list', () {
    testWidgets('marks products with a suggestion; the bell counts the urgent ones', (
      tester,
    ) async {
      await pump(tester, location: '/', seed: () {});
      await add(tester, 'Alfa', newPrice: 3000); // lower: not urgent
      await add(tester, 'Zeta', newPrice: 12000); // 15.000 now sells too low: urgent
      await add(tester, 'Mid'); // nothing pending
      await show(tester, '/');

      expect(find.byTooltip('Saran harga'), findsOneWidget);
      // One urgent suggestion: the badge says 1 (not 2).
      expect(
        tester.widget<Badge>(find.byType(Badge)).label,
        isA<Text>().having((t) => t.data, 'data', '1'),
      );
      // Two products carry the marker, the third does not.
      expect(find.byIcon(Icons.price_change_outlined), findsNWidgets(2));
      await finish(tester);
    });

    testWidgets('no bell without suggestions', (tester) async {
      await pump(tester, location: '/', seed: () {});
      await add(tester, 'Mid');
      await show(tester, '/');
      expect(find.byTooltip('Saran harga'), findsNothing);
      await finish(tester);
    });

    testWidgets('a non-urgent suggestion shows the bell without a number', (tester) async {
      await pump(tester, location: '/', seed: () {});
      await add(tester, 'Alfa', newPrice: 3000);
      await show(tester, '/');
      expect(find.byTooltip('Saran harga'), findsOneWidget);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      await finish(tester);
    });

    testWidgets('the bell opens Saran harga', (tester) async {
      await pump(tester, location: '/', seed: () {});
      await add(tester, 'Zeta', newPrice: 12000);
      await show(tester, '/');
      await tester.tap(find.byTooltip('Saran harga'));
      await frames(tester);
      await settle(tester);
      expect(find.text('Zeta'), findsOneWidget);
      expect(find.textContaining('Rp 15.000 → Rp 20.000'), findsOneWidget);
      await finish(tester);
    });
  });

  group('Saran harga screen', () {
    testWidgets('lists suggestions, the ones selling below the margin limit first', (
      tester,
    ) async {
      await pump(tester, location: '/', seed: () {});
      await add(tester, 'Alfa', newPrice: 3000);
      await add(tester, 'Zeta', newPrice: 12000);
      await show(tester, '/saran-harga');

      expect(
        tester.getTopLeft(find.text('Zeta')).dy,
        lessThan(tester.getTopLeft(find.text('Alfa')).dy),
      );
      expect(find.textContaining('Rp 15.000 → Rp 20.000 (naik Rp 5.000)'), findsOneWidget);
      expect(find.textContaining('Rp 15.000 → Rp 10.000 (turun Rp 5.000)'), findsOneWidget);
      expect(find.text('Margin di bawah batas dengan harga sekarang'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Terapkan and Tidak work from the list', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final alfa = await add(tester, 'Alfa', newPrice: 3000);
      final zeta = await add(tester, 'Zeta', newPrice: 12000);
      await show(tester, '/saran-harga');

      // Zeta sells below the margin limit now: Terapkan asks once more.
      await tester.tap(find.byTooltip('Terapkan: Zeta'));
      await frames(tester);
      expect(find.text('Ubah harga jual?'), findsOneWidget);
      expect(find.textContaining('Zeta: dari Rp 15.000 ke Rp 20.000'), findsOneWidget);
      expect(await retailOf(tester, zeta), 15000); // not changed by the first click
      await tester.tap(find.text('Ya, ubah'));
      await settle(tester);
      await frames(tester);
      expect(await retailOf(tester, zeta), 20000);

      await tester.tap(find.byTooltip('Tidak: Alfa'));
      await settle(tester);
      await frames(tester);
      expect(await retailOf(tester, alfa), 15000);

      // Both answered: the list is empty.
      expect(find.text('Tidak ada saran harga'), findsOneWidget);
      await finish(tester);
    });


    testWidgets('an urgent row can be cancelled at the confirmation', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final zeta = await add(tester, 'Zeta', newPrice: 12000);
      await show(tester, '/saran-harga');

      await tester.tap(find.byTooltip('Terapkan: Zeta'));
      await frames(tester);
      await tester.tap(find.text('Batal'));
      await frames(tester);

      expect(await retailOf(tester, zeta), 15000);
      expect(find.text('Zeta'), findsOneWidget); // still waiting
      await finish(tester);
    });
    testWidgets('tapping a row opens the product', (tester) async {
      await pump(tester, location: '/', seed: () {});
      final id = await add(tester, 'Zeta', newPrice: 12000);
      await show(tester, '/saran-harga');
      await tester.tap(find.text('Zeta'));
      await frames(tester);
      await settle(tester);
      expect(find.text('Detail produk'), findsOneWidget);
      expect(id, isNotEmpty);
      await finish(tester);
    });

    testWidgets('says so when there is nothing to confirm', (tester) async {
      await pump(tester, location: '/', seed: () {});
      await show(tester, '/saran-harga');
      expect(find.text('Tidak ada saran harga'), findsOneWidget);
      await finish(tester);
    });
  });
}
