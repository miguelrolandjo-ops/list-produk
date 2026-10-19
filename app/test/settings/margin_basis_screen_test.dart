import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/settings/margin_limits_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('choose the average of the last N POs and save it', (tester) async {
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

    Future<Map<String, Object?>> settings() async => (await tester.runAsync(
      () => db
          .customSelect('SELECT margin_basis, margin_avg_count FROM settings')
          .getSingle(),
    ))!.data;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MarginLimitsScreen()),
      ),
    );
    await settle();

    // Default: latest PO price, nothing to save yet.
    expect(find.text('Harga supplier untuk cek margin'), findsOneWidget);
    expect(
      find.text('Harga dari PO terbaru produk ini, dari supplier mana pun.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan')).onPressed,
      isNull,
    );

    await tester.tap(find.text('Rata-rata'));
    await tester.pump();
    expect(find.text('Rata-rata dari 3 PO terakhir'), findsOneWidget);

    await tester.tap(find.byTooltip('Tambah'));
    await tester.pump();
    expect(find.text('Rata-rata dari 4 PO terakhir'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await settle();
    await settle();

    final saved = await settings();
    expect(saved['margin_basis'], 'average');
    expect(saved['margin_avg_count'], 4);
    expect(find.text('Pengaturan margin disimpan'), findsOneWidget);
  });

  testWidgets('N cannot go below 2', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownerDbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MarginLimitsScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();

    await tester.tap(find.text('Rata-rata'));
    await tester.pump();
    await tester.tap(find.byTooltip('Kurangi')); // 3 -> 2
    await tester.pump();
    expect(find.text('Rata-rata dari 2 PO terakhir'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove_circle_outline)).onPressed,
      isNull,
    );
  });
}
