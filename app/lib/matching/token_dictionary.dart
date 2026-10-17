import 'normalize.dart';

/// Abbreviation dictionary ("kbl" -> "kabel") learned from confirmed aliases.
///
/// It is rebuilt from `product_aliases` + product names whenever matching
/// starts, so it grows with every reviewed PO and needs no table of its own.
class TokenDictionary {
  TokenDictionary([Map<String, String> map = const {}])
    : _map = Map.unmodifiable(map);

  final Map<String, String> _map;

  Map<String, String> get entries => _map;

  /// Learns from pairs of (supplier alias, canonical product name).
  ///
  /// A token that appears only in the alias is learned as an abbreviation of a
  /// token that appears only in the canonical name when it is a clear
  /// abbreviation of exactly one of them (same first letter, letters in order,
  /// shorter). This rejects "biru" -> "hitam" and any token with digits.
  factory TokenDictionary.learn(
    Iterable<({String alias, String canonical})> pairs,
  ) {
    final counts = <String, Map<String, int>>{};
    for (final p in pairs) {
      final a = baseTokens(p.alias).toSet();
      final c = baseTokens(p.canonical).toSet();
      final aliasOnly = a.difference(c);
      final canonOnly = c.difference(a);
      for (final from in aliasOnly) {
        final targets = canonOnly.where((t) => isAbbreviation(from, t)).toList();
        if (targets.length != 1) continue;
        final byTarget = counts.putIfAbsent(from, () => {});
        byTarget[targets.first] = (byTarget[targets.first] ?? 0) + 1;
      }
    }
    final map = <String, String>{};
    counts.forEach((from, byTarget) {
      final best = byTarget.entries.toList()
        ..sort((x, y) => y.value.compareTo(x.value));
      // Skip when two targets are equally likely.
      if (best.length > 1 && best[0].value == best[1].value) return;
      map[from] = best.first.key;
    });
    return TokenDictionary(map);
  }

  /// Tokens of [text] with learned abbreviations expanded.
  List<String> tokens(String text) => [
    for (final t in baseTokens(text)) _map[t] ?? t,
  ];

  /// Space-joined [tokens], ready for similarity.
  String apply(String text) => tokens(text).join(' ');

  static bool isAbbreviation(String from, String to) {
    if (from.length < 2 || from.length >= to.length) return false;
    if (from[0] != to[0]) return false;
    if (RegExp(r'\d').hasMatch(from) || RegExp(r'\d').hasMatch(to)) return false;
    var i = 0;
    for (var j = 0; j < to.length && i < from.length; j++) {
      if (to[j] == from[i]) i++;
    }
    return i == from.length;
  }
}
