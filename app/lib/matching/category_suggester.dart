import 'normalize.dart';
import 'product_matcher.dart';
import 'token_dictionary.dart';

class CategorySuggestion {
  const CategorySuggestion(this.category, this.confidence);

  final String category;

  /// Share of the similar products' weight that voted for [category], 0 to 1.
  final double confidence;
}

/// Suggests a category for a product name from the catalog the owner already
/// organized (k-nearest-neighbours on name similarity, on the phone).
///
/// The [k] most similar categorized products vote for their category, each
/// weighted by its similarity. A category wins only with a clear majority, so
/// an ambiguous name gets no suggestion rather than a bad one. Every product
/// the owner files makes the next suggestion better; nothing leaves the phone.
class CategorySuggester {
  CategorySuggester(
    Iterable<MatchCandidate> candidates,
    this.dictionary, {
    this.k = 5,
    this.minSimilarity = 0.3,
    this.minShare = 0.5,
  }) {
    for (final c in candidates) {
      final category = c.categoryName?.trim();
      if (category == null || category.isEmpty) continue;
      _items.add((
        category: category,
        grams: [
          trigrams(dictionary.apply('${c.name} ${c.model ?? ''}')),
          trigrams(dictionary.apply(c.name)),
          for (final a in c.aliases) trigrams(dictionary.apply(a.alias)),
        ],
      ));
    }
  }

  factory CategorySuggester.fromMatcher(ProductMatcher matcher) =>
      CategorySuggester(matcher.candidates, matcher.dictionary);

  final TokenDictionary dictionary;
  final int k;
  final double minSimilarity;
  final double minShare;

  final _items = <({String category, List<Set<String>> grams})>[];

  CategorySuggestion? suggest(String rawName) {
    final query = trigrams(dictionary.apply(rawName));
    if (query.isEmpty) return null;

    final scored = <({String category, double score})>[];
    for (final item in _items) {
      var best = 0.0;
      for (final g in item.grams) {
        final s = diceSimilarity(query, g);
        if (s > best) best = s;
      }
      if (best >= minSimilarity) scored.add((category: item.category, score: best));
    }
    if (scored.isEmpty) return null;
    scored.sort((a, b) => b.score.compareTo(a.score));
    final nearest = scored.take(k).toList();

    final weight = <String, double>{};
    var total = 0.0;
    for (final n in nearest) {
      weight[n.category] = (weight[n.category] ?? 0) + n.score;
      total += n.score;
    }
    // Highest total weight wins; the nearest product breaks a tie.
    final winner = weight.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    final share = winner.value / total;
    if (share < minShare) return null;
    return CategorySuggestion(winner.key, share);
  }
}
