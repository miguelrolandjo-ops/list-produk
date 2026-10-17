import 'normalize.dart';
import 'token_dictionary.dart';

/// Values mirror `po_lines.match_status`; `isNew` is stored as 'new'.
enum MatchStatus { auto, suggested, isNew }

class AliasEntry {
  const AliasEntry({required this.supplierId, required this.alias});
  final String supplierId;
  final String alias;
}

/// A catalog product as the matcher sees it. Plain data, so the matcher can be
/// tested without a database.
class MatchCandidate {
  const MatchCandidate({
    required this.productId,
    required this.name,
    this.model,
    this.aliases = const [],
    this.lastPriceBySupplier = const {},
  });

  final String productId;
  final String name;
  final String? model;
  final List<AliasEntry> aliases;

  /// Latest supply price per supplier id (whole Rupiah).
  final Map<String, int> lastPriceBySupplier;
}

class MatchSuggestion {
  const MatchSuggestion({required this.productId, required this.score});
  final String productId;
  final double score;
}

class MatchOutcome {
  const MatchOutcome(this.status, {this.productId, this.suggestions = const []});
  final MatchStatus status;

  /// Set for [MatchStatus.auto] and [MatchStatus.suggested] (the best one).
  final String? productId;

  /// Best candidates first, only those at or above the suggest threshold.
  final List<MatchSuggestion> suggestions;
}

class ProductMatcher {
  ProductMatcher({
    required this.candidates,
    TokenDictionary? dictionary,
    this.suggestThreshold = 0.5,
    this.maxSuggestions = 3,
  }) : dictionary = dictionary ?? _learnFrom(candidates) {
    for (final c in candidates) {
      _texts[c.productId] = [
        _grams(this.dictionary.apply('${c.name} ${c.model ?? ''}')),
        _grams(this.dictionary.apply(c.name)),
        for (final a in c.aliases) _grams(this.dictionary.apply(a.alias)),
      ];
    }
  }

  final List<MatchCandidate> candidates;
  final TokenDictionary dictionary;
  final double suggestThreshold;
  final int maxSuggestions;

  /// Context boosts only apply when the names are already somewhat alike, so
  /// a price or supplier can never create a match from nothing.
  static const _boostFloor = 0.3;
  static const _supplierBoost = 0.05;
  static const _priceBoost = 0.1;
  static const _priceTolerancePercent = 15;

  final _texts = <String, List<Set<String>>>{};

  static TokenDictionary _learnFrom(List<MatchCandidate> candidates) =>
      TokenDictionary.learn([
        for (final c in candidates)
          for (final a in c.aliases) (alias: a.alias, canonical: c.name),
      ]);

  MatchOutcome match({
    required String rawName,
    String? supplierId,
    int? unitPrice,
  }) {
    final norm = normalizeName(rawName);
    if (norm.isEmpty) return const MatchOutcome(MatchStatus.isNew);

    // Exact alias for this supplier: auto-link (spec Story 2).
    if (supplierId != null) {
      for (final c in candidates) {
        for (final a in c.aliases) {
          if (a.supplierId == supplierId && normalizeName(a.alias) == norm) {
            return MatchOutcome(
              MatchStatus.auto,
              productId: c.productId,
              suggestions: [MatchSuggestion(productId: c.productId, score: 1)],
            );
          }
        }
      }
    }

    final query = _grams(dictionary.apply(rawName));
    // Raw scores can exceed 1 after boosts; sort on them, clamp for output.
    final scored = <({String id, double raw})>[];
    for (final c in candidates) {
      var base = 0.0;
      for (final g in _texts[c.productId]!) {
        final s = _dice(query, g);
        if (s > base) base = s;
      }
      var score = base;
      if (base >= _boostFloor && supplierId != null) {
        if (c.aliases.any((a) => a.supplierId == supplierId) ||
            c.lastPriceBySupplier.containsKey(supplierId)) {
          score += _supplierBoost;
        }
        final last = c.lastPriceBySupplier[supplierId];
        if (unitPrice != null && last != null && last > 0) {
          if ((unitPrice - last).abs() * 100 <= last * _priceTolerancePercent) {
            score += _priceBoost;
          }
        }
      }
      if (score >= suggestThreshold) {
        scored.add((id: c.productId, raw: score));
      }
    }
    if (scored.isEmpty) return const MatchOutcome(MatchStatus.isNew);

    scored.sort((x, y) {
      final byScore = y.raw.compareTo(x.raw);
      return byScore != 0 ? byScore : x.id.compareTo(y.id);
    });
    final top = [
      for (final s in scored.take(maxSuggestions))
        MatchSuggestion(productId: s.id, score: s.raw > 1 ? 1 : s.raw),
    ];
    return MatchOutcome(
      MatchStatus.suggested,
      productId: top.first.productId,
      suggestions: top,
    );
  }

  /// Trigram set of an already-normalized string (build guide section 9).
  static Set<String> _grams(String normalized) {
    final t = ' $normalized ';
    return {for (var i = 0; i < t.length - 2; i++) t.substring(i, i + 3)};
  }

  static double _dice(Set<String> x, Set<String> y) {
    if (x.isEmpty || y.isEmpty) return 0;
    return 2 * x.intersection(y).length / (x.length + y.length);
  }
}
