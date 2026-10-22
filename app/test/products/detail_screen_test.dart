import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/add_product_screen.dart';
import 'package:flutter_application_1/products/product_detail_screen.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late OwnerDatabase db;

  /// Opens the detail screen of a product with supply price 9.500.
  /// [retail] is a manual retail price (null = calculated, 15.000).
  Future<void> openDetail(
    WidgetTester tester, {
    int? retail,
    Future<void> Function(OwnerDatabase db, String id)? prepare,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    late String id;
    await tester.runAsync(() async {
      await initializeDateFormatting('id_ID');
      id = await ProductService(db).addManual(
        NewProductInput(
          name: 'Kabel USB-C',
          supplierName: 'CV Maju',
          supplyPrice: 9500,
          retailPrice: retail,
        ),
      );
      await prepare?.call(db, id);
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('daftar')),
        GoRoute(
          path: '/produk/:id',
          builder: (_, state) =>
              ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/pengaturan/harga',
          builder: (_, _) => const Text('layar aturan harga'),
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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
  }

  ColorScheme scheme() => ThemeData().colorScheme;

  testWidgets('the edit button is a simple pencil', (tester) async {
    await openDetail(tester);
    expect(find.byTooltip('Ubah produk'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byTooltip('Ubah produk'),
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.edit_note), findsNothing);
  });

  testWidgets('tapping the Harga jual card edits the retail price', (tester) async {
    await openDetail(tester);
    await tester.tap(find.text('Rp 15.000'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ubah harga jual'), findsOneWidget);
  });

  testWidgets('tapping the margin goes to Aturan harga, not the price dialog', (
    tester,
  ) async {
    await openDetail(tester);
    await tester.tap(find.textContaining('Margin 3'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('layar aturan harga'), findsOneWidget);
    expect(find.text('Ubah harga jual'), findsNothing);
  });

  testWidgets('a normal margin is not red', (tester) async {
    await openDetail(tester);
    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.backgroundColor, isNull);
  });

  testWidgets('selling at a loss shows the margin in red, besides the warning', (
    tester,
  ) async {
    await openDetail(tester, retail: 5000); // below the 9.500 supply price
    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.backgroundColor, scheme().errorContainer);
    final label = tester.widget<Text>(
      find.descendant(of: find.byType(ActionChip), matching: find.byType(Text)),
    );
    expect(label.style?.color, scheme().onErrorContainer);
    expect(label.data, startsWith('Margin -'));
    // The existing "below the limit" warning is still there.
    expect(find.textContaining('Margin di bawah batas'), findsWidgets);
  });

  testWidgets('add product: a loss margin preview is red', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: AddProductScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Harga supplier'), '9500');
    await tester.pump();
    Color? marginColor() => tester
        .widget<Text>(find.textContaining('Margin '))
        .style
        ?.color;
    expect(marginColor(), isNot(scheme().error)); // calculated 15.000: positive

    await tester.enterText(find.widgetWithText(TextFormField, 'Harga jual'), '5000');
    await tester.pump();
    expect(marginColor(), scheme().error);
  });

  testWidgets('a manual price says when it changed and what it was, not "tidak dihitung"', (
    tester,
  ) async {
    // 12 days ago it went from 10.000 to the current price.
    await openDetail(
      tester,
      retail: 20000,
      prepare: (db, id) async {
        final then = DateTime.now().toUtc().subtract(const Duration(days: 12));
        await db.customStatement(
          'UPDATE products SET retail_prev = 10000, retail_changed_at = ? WHERE id = ?',
          [then.toIso8601String(), id],
        );
      },
    );
    expect(find.text('Diubah 12 hari lalu (sebelumnya Rp 10.000)'), findsOneWidget);
    expect(find.textContaining('tidak dihitung ulang'), findsNothing);
    expect(find.textContaining('Diubah manual'), findsNothing);
  });

  testWidgets('a price just changed by the owner says "hari ini" with the old price', (
    tester,
  ) async {
    // Created at 15.000, then set to 20.000 by hand: the trigger recorded it.
    await openDetail(tester, retail: 20000);
    expect(find.text('Diubah hari ini (sebelumnya Rp 15.000)'), findsOneWidget);
  });

  testWidgets('a calculated price shows its basis, and the change when there was one', (
    tester,
  ) async {
    await openDetail(
      tester,
      prepare: (db, id) async {
        await db.customStatement(
          "UPDATE products SET retail_prev = 10000, retail_changed_at = ? WHERE id = ?",
          [DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String(), id],
        );
      },
    );
    expect(find.textContaining('Otomatis dari harga supplier'), findsOneWidget);
    expect(find.text('Diubah 2 hari lalu (sebelumnya Rp 10.000)'), findsOneWidget);
  });

  testWidgets('nothing recorded: no change line at all', (tester) async {
    await openDetail(tester); // calculated at its first price: never changed
    expect(find.textContaining('Diubah '), findsNothing);
    expect(find.textContaining('sebelumnya'), findsNothing);
  });
}
