/// Normalization used for `product_aliases.alias_norm` (build guide section 9).
/// Keep this exactly as is: stored alias_norm values must keep matching.
String normalizeName(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Tokens used for fuzzy comparison. Starts from [normalizeName], then applies
/// one deterministic measure rule: whole-meter lengths written in cm become
/// meters ("100cm" -> "1m"), because cable lengths are written both ways.
List<String> baseTokens(String s) {
  final withMeters = s.toLowerCase().replaceAllMapped(
    RegExp(r'(\d+)\s*cm\b'),
    (m) {
      final cm = int.parse(m[1]!);
      return cm > 0 && cm % 100 == 0 ? '${cm ~/ 100}m' : m[0]!;
    },
  );
  final n = normalizeName(withMeters);
  return n.isEmpty ? const [] : n.split(' ');
}
