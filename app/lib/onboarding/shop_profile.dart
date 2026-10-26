import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/app_mode.dart';
import '../data/owner_database.dart';
import 'shop_types.dart';

const shopTypesKey = 'shop_types';
const shopNameKey = 'shop_name';
const customEmojisKey = 'custom_emojis';

const shopProfileKeys = {shopTypesKey, shopNameKey, customEmojisKey};

/// What onboarding learned about the shop: its kinds (for the emoji picker)
/// and the emoji the owner added. Per phone, like display settings; the
/// category emoji themselves are in the database and so in backups.
class ShopProfile {
  const ShopProfile({
    this.typeIds = const [],
    this.name,
    this.customEmojis = const [],
  });

  final List<String> typeIds;

  /// Store name typed during onboarding; proposed when creating the online
  /// store later.
  final String? name;
  final List<String> customEmojis;

  List<ShopType> get types => [
    for (final id in typeIds)
      if (shopTypeById(id) case final t?) t,
  ];
}

/// One emoji, not text: a single visible character that isn't a letter or
/// digit. Used to check what the owner types into "Tambah emoji sendiri".
bool isSingleEmoji(String value) {
  final v = value.trim();
  if (v.isEmpty || v.characters.length != 1) return false;
  return !RegExp(r'[\p{L}\p{N}\s]', unicode: true).hasMatch(v);
}

class ShopProfileNotifier extends Notifier<ShopProfile> {
  @override
  ShopProfile build() {
    final kv = ref.watch(keyValueStoreProvider);
    List<String> list(String key) => (kv.getString(key) ?? '')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();
    return ShopProfile(
      typeIds: list(shopTypesKey),
      name: kv.getString(shopNameKey),
      customEmojis: list(customEmojisKey),
    );
  }

  KeyValueStore get _kv => ref.read(keyValueStoreProvider);

  Future<void> setTypes(List<String> ids) async {
    await _kv.setString(shopTypesKey, ids.join(' '));
    state = ShopProfile(
      typeIds: ids,
      name: state.name,
      customEmojis: state.customEmojis,
    );
  }

  Future<void> setName(String? name) async {
    final v = name?.trim() ?? '';
    if (v.isEmpty) {
      await _kv.remove(shopNameKey);
    } else {
      await _kv.setString(shopNameKey, v);
    }
    state = ShopProfile(
      typeIds: state.typeIds,
      name: v.isEmpty ? null : v,
      customEmojis: state.customEmojis,
    );
  }

  /// Adds an emoji to "Emoji Anda" (newest first, no duplicates).
  Future<void> addCustomEmoji(String emoji) async {
    final e = emoji.trim();
    if (!isSingleEmoji(e)) return;
    final list = [e, ...state.customEmojis.where((x) => x != e)];
    await _kv.setString(customEmojisKey, list.join(' '));
    state = ShopProfile(
      typeIds: state.typeIds,
      name: state.name,
      customEmojis: list,
    );
  }

  Future<void> removeCustomEmoji(String emoji) async {
    final list = state.customEmojis.where((x) => x != emoji).toList();
    await _kv.setString(customEmojisKey, list.join(' '));
    state = ShopProfile(
      typeIds: state.typeIds,
      name: state.name,
      customEmojis: list,
    );
  }
}

final shopProfileProvider = NotifierProvider<ShopProfileNotifier, ShopProfile>(
  ShopProfileNotifier.new,
);

/// Creates the categories the owner kept during onboarding. A category that
/// already exists (same name) keeps its products and gets the emoji only if
/// it had none. Returns how many were new.
Future<int> createStarterCategories(
  OwnerDatabase db,
  List<(String name, String emoji)> categories, {
  Uuid uuid = const Uuid(),
}) => db.transaction(() async {
  var created = 0;
  for (final (name, emoji) in categories) {
    final n = name.trim();
    if (n.isEmpty) continue;
    final existing = await db
        .customSelect(
          'SELECT id, emoji FROM categories WHERE name = ? COLLATE NOCASE',
          variables: [Variable.withString(n)],
        )
        .getSingleOrNull();
    if (existing == null) {
      await db.customInsert(
        'INSERT INTO categories (id, name, emoji) VALUES (?, ?, ?)',
        variables: [
          Variable.withString(uuid.v4()),
          Variable.withString(n),
          Variable.withString(emoji),
        ],
        updates: {db.categories},
      );
      created++;
    } else if (existing.readNullable<String>('emoji') == null) {
      await db.customUpdate(
        'UPDATE categories SET emoji = ? WHERE id = ?',
        variables: [
          Variable.withString(emoji),
          Variable.withString(existing.read<String>('id')),
        ],
        updates: {db.categories},
      );
    }
  }
  return created;
});
