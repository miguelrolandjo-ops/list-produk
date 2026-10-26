import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/onboarding/shop_profile.dart';
import 'package:flutter_application_1/onboarding/shop_types.dart';
import 'package:flutter_application_1/products/category_emoji.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shop type ids are unique and every starter category has an emoji', () {
    final ids = shopTypes.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final t in shopTypes) {
      for (final (name, emoji) in t.categories) {
        expect(name.trim(), isNotEmpty);
        expect(isSingleEmoji(emoji), isTrue, reason: '$name: $emoji');
      }
      for (final e in t.emojis) {
        expect(isSingleEmoji(e), isTrue, reason: '${t.id}: $e');
      }
    }
  });

  test('kitchen shops start with pans, woks, spoons and knives', () {
    final names = [for (final c in starterCategories(['kitchen'])) c.$1];
    expect(names, containsAll(['Wajan', 'Panci', 'Sendok & garpu', 'Pisau']));
    expect(shopTypeById('kitchen')!.emojis, containsAll(['🍳', '🥘', '🥄', '🔪']));
  });

  test('several shop types: starter categories without duplicates', () {
    final both = starterCategories(['phone', 'automotive']);
    final lower = both.map((c) => c.$1.toLowerCase()).toList();
    expect(lower.toSet().length, lower.length);
  });

  test('isSingleEmoji accepts one emoji only', () {
    expect(isSingleEmoji('🥘'), isTrue);
    expect(isSingleEmoji(' 🍽️ '), isTrue); // with variation selector
    expect(isSingleEmoji('👨‍🍳'), isTrue); // joined sequence = one character
    expect(isSingleEmoji('🍳🥄'), isFalse);
    expect(isSingleEmoji('a'), isFalse);
    expect(isSingleEmoji('7'), isFalse);
    expect(isSingleEmoji(''), isFalse);
  });

  group('categoryEmoji', () {
    test('picked emoji wins', () {
      expect(categoryEmoji('Kabel', picked: '🧵'), '🧵');
    });

    test('starter category names map to their emoji (employee phones)', () {
      expect(categoryEmoji('Sendok & garpu'), '🥄');
      expect(categoryEmoji('wajan'), '🍳');
    });

    test('words in the name, short ones only as whole words', () {
      expect(categoryEmoji('Aneka kabel data'), '🔌');
      expect(categoryEmoji('Casing HP'), '📱');
      expect(categoryEmoji('Chips'), fallbackCategoryEmoji); // not "hp"
      expect(categoryEmoji('Alat tulis'), '✏️');
      expect(categoryEmoji('Tas sekolah'), '👜');
      expect(categoryEmoji('Pastel'), fallbackCategoryEmoji); // not "tas"
      expect(categoryEmoji(null), noCategoryEmoji);
    });
  });

  group('createStarterCategories', () {
    late OwnerDatabase db;
    setUp(() => db = OwnerDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<Map<String, String?>> rows() async => {
      for (final r in await db
          .customSelect('SELECT name, emoji FROM categories')
          .get())
        r.read<String>('name'): r.readNullable<String>('emoji'),
    };

    test('creates the kept categories with their emoji', () async {
      final n = await createStarterCategories(db, [
        ('Wajan', '🍳'),
        ('Pisau', '🔪'),
        ('  ', '📦'), // blank names are skipped
      ]);
      expect(n, 2);
      expect(await rows(), {'Wajan': '🍳', 'Pisau': '🔪'});
    });

    test('an existing category keeps its products and its own emoji', () async {
      final service = ProductService(db);
      await service.addManual(
        const NewProductInput(
          name: 'Wajan 24cm',
          supplierName: 'CV',
          supplyPrice: 50000,
          categoryName: 'wajan',
        ),
      );
      final n = await createStarterCategories(db, [('Wajan', '🍳')]);
      expect(n, 0);
      expect((await rows()).values.single, '🍳'); // had none, got one
      await setCategoryEmoji(
        db,
        (await db.customSelect('SELECT id FROM categories').getSingle())
            .read<String>('id'),
        '🥘',
      );
      await createStarterCategories(db, [('Wajan', '🍳')]);
      expect((await rows()).values.single, '🥘'); // owner's choice kept
    });
  });

  test('schema v6: the emoji column is added once', () async {
    final db = OwnerDatabase(NativeDatabase.memory());
    await db.ensureCategoryEmojiColumn(); // already there: no error
    final cols = await db.customSelect('PRAGMA table_info(categories)').get();
    expect(cols.where((c) => c.read<String>('name') == 'emoji'), hasLength(1));
    await db.close();
  });
}
