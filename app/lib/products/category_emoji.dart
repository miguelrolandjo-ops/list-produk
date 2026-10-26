import 'package:drift/drift.dart' show TableUpdateQuery, Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/owner_database.dart';
import '../onboarding/shop_profile.dart';
import '../onboarding/shop_types.dart';

/// Emoji for the category cards. The app has no product photos, so a big emoji
/// is what makes a category recognisable at a glance.
///
/// The owner can pick one per category (saved in categories.emoji). Until then,
/// and on employee phones (the server only has the category name), the emoji
/// comes from words in the name.
const allProductsEmoji = '🏪';
const noCategoryEmoji = '🗂️';
const fallbackCategoryEmoji = '📦';

/// Word stems → emoji, checked in order. Lower case; matched anywhere in the
/// category name, so "Kabel data" and "Aneka kabel" both get 🔌.
const _keywordEmoji = <(String, String)>[
  ('kabel', '🔌'),
  ('charger', '🔋'),
  ('cas', '🔋'),
  ('baterai', '🔋'),
  ('batre', '🔋'),
  ('powerbank', '🔋'),
  ('lampu', '💡'),
  ('senter', '🔦'),
  ('listrik', '⚡'),
  ('stop kontak', '🔌'),
  ('headset', '🎧'),
  ('earphone', '🎧'),
  ('headphone', '🎧'),
  ('speaker', '🔊'),
  ('audio', '🔊'),
  ('casing', '📱'),
  ('case', '📱'),
  ('hp', '📱'),
  ('handphone', '📱'),
  ('ponsel', '📱'),
  ('aksesoris', '🧩'),
  ('komputer', '💻'),
  ('laptop', '💻'),
  ('mouse', '🖱️'),
  ('keyboard', '⌨️'),
  ('printer', '🖨️'),
  ('tinta', '🖨️'),
  ('kamera', '📷'),
  ('cctv', '📹'),
  ('tv', '📺'),
  ('elektronik', '📺'),
  ('jam', '⌚'),
  ('memori', '💾'),
  ('flashdisk', '💾'),
  ('alat tulis', '✏️'),
  ('perkakas', '🔧'),
  ('alat', '🔧'),
  ('obeng', '🪛'),
  ('baut', '🔩'),
  ('paku', '🔩'),
  ('cat', '🎨'),
  ('pipa', '🚰'),
  ('keran', '🚰'),
  ('bangunan', '🧱'),
  ('semen', '🧱'),
  ('kebun', '🌱'),
  ('tanaman', '🌱'),
  ('makanan', '🍜'),
  ('mie', '🍜'),
  ('snack', '🍪'),
  ('camilan', '🍪'),
  ('kue', '🍪'),
  ('minuman', '🥤'),
  ('kopi', '☕'),
  ('teh', '🍵'),
  ('susu', '🥛'),
  ('beras', '🍚'),
  ('sembako', '🍚'),
  ('bumbu', '🧂'),
  ('minyak', '🫗'),
  ('rokok', '🚬'),
  ('sabun', '🧼'),
  ('sampo', '🧴'),
  ('perawatan', '🧴'),
  ('kosmetik', '💄'),
  ('obat', '💊'),
  ('kesehatan', '💊'),
  ('bayi', '🍼'),
  ('mainan', '🧸'),
  ('atk', '✏️'),
  ('buku', '📚'),
  ('kertas', '📄'),
  ('baju', '👕'),
  ('kaos', '👕'),
  ('pakaian', '👕'),
  ('celana', '👖'),
  ('sepatu', '👟'),
  ('sandal', '🩴'),
  ('tas', '👜'),
  ('dapur', '🍳'),
  ('piring', '🍽️'),
  ('plastik', '🛍️'),
  ('kemasan', '🛍️'),
  ('gas', '🔥'),
  ('air', '💧'),
  ('galon', '💧'),
  ('motor', '🏍️'),
  ('oli', '🛢️'),
  ('mobil', '🚗'),
  ('otomotif', '🚗'),
  ('sepeda', '🚲'),
  ('olahraga', '⚽'),
  ('hewan', '🐾'),
  ('pakan', '🐾'),
  ('kebersihan', '🧹'),
  ('sapu', '🧹'),
];

/// The emoji for a category: the one the owner picked, else the starter
/// category's emoji with that exact name, else one from words in the name,
/// else 📦.
String categoryEmoji(String? name, {String? picked}) {
  if (picked != null && picked.trim().isNotEmpty) return picked.trim();
  if (name == null) return noCategoryEmoji;
  final starter = starterEmojiFor(name);
  if (starter != null) return starter;
  final lower = name.toLowerCase();
  for (final (stem, emoji) in _keywordEmoji) {
    // Short stems ("hp", "tv", "cas", "air", "tas") only count as whole
    // words, so "Chips" isn't a phone and "Pastel" isn't a bag.
    if (stem.length <= 3) {
      if (RegExp('(^|[^a-z])${RegExp.escape(stem)}([^a-z]|\$)')
          .hasMatch(lower)) {
        return emoji;
      }
    } else if (lower.contains(stem)) {
      return emoji;
    }
  }
  return fallbackCategoryEmoji;
}

/// Choices in the emoji picker: things a small Indonesian shop sells.
const emojiChoices = [
  '📦', '🔌', '🔋', '💡', '⚡', '🎧', '🔊', '📱', '🧩', '💻', '🖱️', '⌨️',
  '🖨️', '📷', '📺', '⌚', '💾', '🔧', '🪛', '🔩', '🎨', '🚰', '🧱', '🌱',
  '🍜', '🍪', '🥤', '☕', '🍚', '🧂', '🫗', '🚬', '🧼', '🧴', '💄', '💊',
  '🍼', '🧸', '✏️', '📚', '📄', '👕', '👖', '👟', '👜', '🍳', '🍽️', '🛍️',
  '🔥', '💧', '🏍️', '🛢️', '🚗', '🚲', '⚽', '🐾', '🧹', '🎁', '⭐', '🏷️',
];

/// Saves the owner's pick (null = back to automatic).
Future<void> setCategoryEmoji(
  OwnerDatabase db,
  String categoryId,
  String? emoji,
) => db.customUpdate(
  'UPDATE categories SET emoji = ? WHERE id = ?',
  variables: [Variable<String>(emoji), Variable.withString(categoryId)],
  updates: {db.categories},
);

/// Picker dialog. Returns the chosen emoji, '' for "Otomatis dari nama", or
/// null if cancelled. Shows the shop's own sets first (from onboarding), then
/// the owner's added emoji, then a general set; any emoji can be added.
Future<String?> pickCategoryEmoji(
  BuildContext context, {
  required String categoryName,
  String? current,
  bool allowAutomatic = true,
}) => showDialog<String>(
  context: context,
  builder: (_) => EmojiPickerDialog(
    title: 'Ikon "$categoryName"',
    current: current,
    allowAutomatic: allowAutomatic,
  ),
);

class EmojiPickerDialog extends ConsumerStatefulWidget {
  const EmojiPickerDialog({
    super.key,
    required this.title,
    this.current,
    this.allowAutomatic = true,
  });

  final String title;
  final String? current;
  final bool allowAutomatic;

  @override
  ConsumerState<EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends ConsumerState<EmojiPickerDialog> {
  final _custom = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _addCustom() async {
    final value = _custom.text.trim();
    if (!isSingleEmoji(value)) {
      setState(() => _error = 'Masukkan satu emoji saja');
      return;
    }
    await ref.read(shopProfileProvider.notifier).addCustomEmoji(value);
    if (mounted) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(shopProfileProvider);
    final shown = <String>{};
    List<String> fresh(Iterable<String> list) =>
        [for (final e in list) if (shown.add(e)) e];

    final sections = <(String, List<String>)>[
      for (final t in profile.types)
        if (t.emojis.isNotEmpty) ('${t.emoji} ${t.name}', fresh(t.emojis)),
      if (profile.customEmojis.isNotEmpty)
        ('Emoji Anda', fresh(profile.customEmojis)),
      ('Umum', fresh(emojiChoices)),
    ].where((s) => s.$2.isNotEmpty).toList();

    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, emojis) in sections) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(label, style: text.labelLarge),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final e in emojis)
                      _EmojiButton(
                        emoji: e,
                        selected: e == widget.current,
                        onTap: () => Navigator.pop(context, e),
                        onLongPress: profile.customEmojis.contains(e)
                            ? () => ref
                                  .read(shopProfileProvider.notifier)
                                  .removeCustomEmoji(e)
                            : null,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text('Tambah emoji sendiri', style: text.labelLarge),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _custom,
                      decoration: InputDecoration(
                        hintText: 'Ketik atau tempel, mis. 🥘',
                        errorText: _error,
                        isDense: true,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _addCustom(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addCustom,
                    child: const Text('Pakai'),
                  ),
                ],
              ),
              if (profile.customEmojis.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Tekan lama emoji Anda untuk menghapusnya dari daftar.',
                    style: text.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        if (widget.allowAutomatic)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Otomatis dari nama'),
          ),
      ],
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Pilih $emoji',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? scheme.primaryContainer : null,
            border: selected
                ? Border.all(color: scheme.primary, width: 1.5)
                : null,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

/// One card on the home screen.
class CategoryOverview {
  const CategoryOverview({
    required this.id,
    required this.name,
    required this.emoji,
    required this.productCount,
    required this.belowMargin,
    required this.unpriced,
  });

  /// A category id, or null for "Semua produk", or [uncategorizedFilter].
  final String? id;
  final String name;
  final String emoji;
  final int productCount;

  /// Products selling below their margin limit now.
  final int belowMargin;

  /// Products without a retail price.
  final int unpriced;
}

class CatalogOverview {
  const CatalogOverview({required this.all, required this.categories});

  /// "Semua produk": totals over every product.
  final CategoryOverview all;

  /// Real categories (alphabetical), then "Tanpa kategori" if any product has
  /// no category.
  final List<CategoryOverview> categories;

  int get categoryCount =>
      categories.where((c) => c.id != uncategorizedFilter).length;
}

/// Everything the category home screen shows, recomputed when products,
/// categories or margin warnings change.
final catalogOverviewProvider = StreamProvider<CatalogOverview>((ref) async* {
  final db = ref.watch(ownerDbProvider);
  final warned = ref.watch(marginWarningsProvider).value ?? const <String>{};

  Future<CatalogOverview> load() async {
    final cats = await db
        .customSelect(
          'SELECT id, name, emoji FROM categories ORDER BY name COLLATE NOCASE',
        )
        .get();
    final products = await db
        .customSelect(
          'SELECT id, category_id, retail_price FROM products '
          'WHERE deleted_at IS NULL',
        )
        .get();

    final count = <String?, int>{};
    final below = <String?, int>{};
    final unpriced = <String?, int>{};
    for (final p in products) {
      final c = p.readNullable<String>('category_id');
      count[c] = (count[c] ?? 0) + 1;
      if (warned.contains(p.read<String>('id'))) below[c] = (below[c] ?? 0) + 1;
      if (p.readNullable<int>('retail_price') == null) {
        unpriced[c] = (unpriced[c] ?? 0) + 1;
      }
    }
    int sum(Map<String?, int> m) => m.values.fold(0, (a, b) => a + b);

    return CatalogOverview(
      all: CategoryOverview(
        id: null,
        name: 'Semua produk',
        emoji: allProductsEmoji,
        productCount: products.length,
        belowMargin: sum(below),
        unpriced: sum(unpriced),
      ),
      categories: [
        for (final c in cats)
          CategoryOverview(
            id: c.read<String>('id'),
            name: c.read<String>('name'),
            emoji: categoryEmoji(
              c.read<String>('name'),
              picked: c.readNullable<String>('emoji'),
            ),
            productCount: count[c.read<String>('id')] ?? 0,
            belowMargin: below[c.read<String>('id')] ?? 0,
            unpriced: unpriced[c.read<String>('id')] ?? 0,
          ),
        if ((count[null] ?? 0) > 0)
          CategoryOverview(
            id: uncategorizedFilter,
            name: 'Tanpa kategori',
            emoji: noCategoryEmoji,
            productCount: count[null]!,
            belowMargin: below[null] ?? 0,
            unpriced: unpriced[null] ?? 0,
          ),
      ],
    );
  }

  yield await load();
  final changes = db.tableUpdates(
    TableUpdateQuery.onAllTables([db.products, db.categories]),
  );
  await for (final _ in changes) {
    yield await load();
  }
});

/// Each category's chosen emoji (null = automatic), by id.
final pickedCategoryEmojiProvider = StreamProvider<Map<String, String?>>((ref) {
  final db = ref.watch(ownerDbProvider);
  return db
      .customSelect('SELECT id, emoji FROM categories', readsFrom: {db.categories})
      .watch()
      .map(
        (rows) => {
          for (final r in rows)
            r.read<String>('id'): r.readNullable<String>('emoji'),
        },
      );
});
