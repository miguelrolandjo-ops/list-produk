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
  Future<void> openDetail(WidgetTester tester, {int? retail}) async {
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
          path: '/pengaturan/margin',
          builder: (_, _) => const Text('layar batas margin'),
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

  testWidgets('tapping the margin goes to Batas margin, not the price dialog', (
    tester,
  ) async {
    await openDetail(tester);
    await tester.tap(find.textContaining('Margin 3'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('layar batas margin'), findsOneWidget);
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
    expect(find.textContaining('Margin di bawah batas'), findsOneWidget);
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
}
