/// Kinds of shop the app is set up for. Choosing one (or more) during
/// onboarding gives starter categories with fitting emoji, and puts that
/// shop's emoji first in the category icon picker.
class ShopType {
  const ShopType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.example,
    required this.categories,
    required this.emojis,
  });

  /// Stable id, saved on the phone. Never rename.
  final String id;
  final String name;
  final String emoji;

  /// What such a shop sells, to help recognise it ("Wajan, panci, sendok").
  final String example;

  /// Starter categories (name, emoji). The owner can untick, rename later in
  /// the product form, or add more.
  final List<(String, String)> categories;

  /// Icons offered first in the picker for this kind of shop.
  final List<String> emojis;
}

const shopTypes = <ShopType>[
  ShopType(
    id: 'kitchen',
    name: 'Peralatan dapur',
    emoji: '🍳',
    example: 'Wajan, panci, sendok, pisau, piring',
    categories: [
      ('Wajan', '🍳'),
      ('Panci', '🍲'),
      ('Sendok & garpu', '🥄'),
      ('Pisau', '🔪'),
      ('Piring & mangkuk', '🍽️'),
      ('Gelas & cangkir', '☕'),
      ('Teko & termos', '🫖'),
      ('Wadah & toples', '🫙'),
      ('Spatula & sutil', '🥢'),
      ('Kompor & gas', '🔥'),
    ],
    emojis: [
      '🍳', '🥘', '🍲', '🥄', '🍴', '🔪', '🍽️', '🥣', '🫖', '☕', '🥛', '🫙',
      '🧂', '🥢', '🔥', '🧊', '🧽', '🧺', '🧁', '🍵',
    ],
  ),
  ShopType(
    id: 'phone',
    name: 'Elektronik & aksesoris HP',
    emoji: '📱',
    example: 'Kabel, charger, casing, earphone',
    categories: [
      ('Kabel', '🔌'),
      ('Charger', '🔋'),
      ('Casing', '📱'),
      ('Pelindung layar', '🛡️'),
      ('Earphone', '🎧'),
      ('Speaker', '🔊'),
      ('Memori', '💾'),
      ('Powerbank', '🔋'),
      ('Lampu', '💡'),
    ],
    emojis: [
      '📱', '🔌', '🔋', '🛡️', '🎧', '🔊', '💾', '💡', '🖱️', '⌨️', '💻', '📷',
      '📺', '⌚', '🧩', '🔦',
    ],
  ),
  ShopType(
    id: 'grocery',
    name: 'Sembako & kelontong',
    emoji: '🛒',
    example: 'Beras, minyak, mi instan, minuman',
    categories: [
      ('Beras', '🍚'),
      ('Minyak goreng', '🫗'),
      ('Gula & tepung', '🧂'),
      ('Mi instan', '🍜'),
      ('Telur', '🥚'),
      ('Minuman', '🥤'),
      ('Kopi & teh', '☕'),
      ('Camilan', '🍪'),
      ('Rokok', '🚬'),
      ('Sabun & deterjen', '🧼'),
    ],
    emojis: [
      '🍚', '🫗', '🧂', '🍜', '🥚', '🥤', '☕', '🍵', '🥛', '🍪', '🍬', '🧃',
      '🫘', '🚬', '🧼', '🧻',
    ],
  ),
  ShopType(
    id: 'building',
    name: 'Bangunan & perkakas',
    emoji: '🧱',
    example: 'Cat, semen, pipa, paku, kunci',
    categories: [
      ('Cat', '🎨'),
      ('Semen & pasir', '🧱'),
      ('Pipa & keran', '🚰'),
      ('Paku & baut', '🔩'),
      ('Perkakas', '🔧'),
      ('Listrik', '⚡'),
      ('Kunci & gembok', '🔐'),
      ('Tangga', '🪜'),
    ],
    emojis: [
      '🧱', '🎨', '🪣', '🚰', '🔩', '🪛', '🔧', '🔨', '⚡', '🔐', '🪜', '🪚',
      '🧰', '🟫',
    ],
  ),
  ShopType(
    id: 'stationery',
    name: 'Alat tulis & fotokopi',
    emoji: '✏️',
    example: 'Buku, pulpen, kertas, map',
    categories: [
      ('Buku', '📚'),
      ('Pulpen & pensil', '✏️'),
      ('Kertas', '📄'),
      ('Map & amplop', '📁'),
      ('Gunting & penggaris', '✂️'),
      ('Perlengkapan sekolah', '🎒'),
      ('Jasa cetak', '🖨️'),
    ],
    emojis: [
      '✏️', '🖊️', '📚', '📄', '📁', '✂️', '📏', '📐', '🖍️', '🎒', '🖨️', '📎',
      '📌', '🗂️',
    ],
  ),
  ShopType(
    id: 'clothing',
    name: 'Pakaian & sepatu',
    emoji: '👕',
    example: 'Kaos, celana, sepatu, tas',
    categories: [
      ('Kaos', '👕'),
      ('Kemeja', '👔'),
      ('Celana', '👖'),
      ('Gamis & dress', '👗'),
      ('Sepatu', '👟'),
      ('Sandal', '🩴'),
      ('Tas', '👜'),
      ('Topi', '🧢'),
      ('Kaus kaki', '🧦'),
    ],
    emojis: [
      '👕', '👔', '👖', '👗', '🧥', '👟', '🩴', '👠', '👜', '🎒', '🧢', '🧦',
      '🩱', '🧣',
    ],
  ),
  ShopType(
    id: 'beauty',
    name: 'Kosmetik & perawatan',
    emoji: '💄',
    example: 'Skincare, makeup, sampo, parfum',
    categories: [
      ('Perawatan wajah', '🧴'),
      ('Makeup', '💄'),
      ('Perawatan rambut', '💇'),
      ('Parfum', '🌸'),
      ('Sabun & mandi', '🧼'),
      ('Perawatan kuku', '💅'),
    ],
    emojis: ['🧴', '💄', '💅', '🪮', '💇', '🌸', '🧼', '🪥', '🫧', '🪞'],
  ),
  ShopType(
    id: 'automotive',
    name: 'Bengkel & suku cadang',
    emoji: '🏍️',
    example: 'Oli, ban, aki, lampu motor',
    categories: [
      ('Oli', '🛢️'),
      ('Ban', '🛞'),
      ('Aki', '🔋'),
      ('Lampu kendaraan', '💡'),
      ('Suku cadang', '⚙️'),
      ('Aksesoris motor', '🏍️'),
    ],
    emojis: ['🏍️', '🛵', '🚗', '🛢️', '🛞', '⚙️', '🔧', '🔩', '🔋', '💡', '🪛'],
  ),
  ShopType(
    id: 'farm',
    name: 'Pertanian & pakan',
    emoji: '🌱',
    example: 'Benih, pupuk, alat kebun, pakan',
    categories: [
      ('Benih', '🌱'),
      ('Pupuk', '🧪'),
      ('Alat kebun', '🪴'),
      ('Pakan ternak', '🐔'),
      ('Pakan ikan', '🐟'),
    ],
    emojis: ['🌱', '🌾', '🪴', '🧪', '🐔', '🐄', '🐟', '💧', '🌽', '🍅'],
  ),
  ShopType(
    id: 'toys',
    name: 'Mainan & hobi',
    emoji: '🧸',
    example: 'Mainan anak, olahraga, pancing',
    categories: [
      ('Mainan anak', '🧸'),
      ('Olahraga', '⚽'),
      ('Alat musik', '🎸'),
      ('Kerajinan', '🧶'),
      ('Pancing', '🎣'),
    ],
    emojis: ['🧸', '🪀', '⚽', '🏸', '🎸', '🧶', '🎣', '🎨', '🧩', '🎲'],
  ),
  ShopType(
    id: 'health',
    name: 'Kesehatan & bayi',
    emoji: '🍼',
    example: 'Vitamin, plester, popok, susu bayi',
    categories: [
      ('Vitamin', '🍊'),
      ('Alat kesehatan', '🩺'),
      ('Perawatan luka', '🩹'),
      ('Masker', '😷'),
      ('Perlengkapan bayi', '🍼'),
    ],
    emojis: ['🍊', '🩺', '🩹', '🌡️', '😷', '🍼', '🧷', '🧴'],
  ),
  ShopType(
    id: 'other',
    name: 'Lainnya',
    emoji: '📦',
    example: 'Mulai tanpa kategori, buat sendiri',
    categories: [],
    emojis: [],
  ),
];

ShopType? shopTypeById(String id) {
  for (final t in shopTypes) {
    if (t.id == id) return t;
  }
  return null;
}

/// Starter categories for the chosen shop types, without duplicate names.
List<(String, String)> starterCategories(Iterable<String> typeIds) {
  final seen = <String>{};
  return [
    for (final id in typeIds)
      for (final c in shopTypeById(id)?.categories ?? const <(String, String)>[])
        if (seen.add(c.$1.toLowerCase())) c,
  ];
}

/// The emoji of a starter category with exactly this name (any shop type),
/// so employee phones, which only receive category names, show the same icon.
String? starterEmojiFor(String categoryName) {
  final lower = categoryName.trim().toLowerCase();
  for (final t in shopTypes) {
    for (final (name, emoji) in t.categories) {
      if (name.toLowerCase() == lower) return emoji;
    }
  }
  return null;
}
