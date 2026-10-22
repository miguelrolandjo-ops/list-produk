/// Margin as a percentage of the retail price: (retail - supply) / retail.
/// Returns null when there is no retail price to compare against.
double? marginPct(int supply, int? retail) {
  if (retail == null || retail <= 0) return null;
  return (retail - supply) / retail * 100;
}

/// (minSupply, maxSupply or null for no limit, minMarginPct). The lower bound
/// is inclusive and the upper bound exclusive, so 65.000 belongs to the range
/// that starts at 65.000.
typedef MarginRange = (int min, int? max, double pct);

/// The minimum margin that applies to [supply], or null if no range covers it.
double? minMarginFor(int supply, Iterable<MarginRange> ranges) {
  for (final (min, max, pct) in ranges) {
    if (supply >= min && (max == null || supply < max)) return pct;
  }
  return null;
}

/// True when the margin of [retail] over [supply] is below the limit for
/// that supply price. False when there is no limit or no retail price.
bool isBelowMargin(int supply, int? retail, Iterable<MarginRange> ranges) {
  final limit = minMarginFor(supply, ranges);
  final margin = marginPct(supply, retail);
  return limit != null && margin != null && margin < limit;
}

/// The retail price to recommend when [supply] sells below its margin limit:
/// the smallest price, rounded up to [roundTo], whose margin reaches
/// [minMarginPct], but never lower than the normal [calculated] price.
int recommendedRetail({
  required int supply,
  required double minMarginPct,
  required int calculated,
  required int roundTo,
}) {
  // margin = (retail - supply) / retail >= limit  <=>  retail >= supply / (1 - limit).
  // The tiny tolerance keeps a price that meets the limit exactly (7.000 at 30%
  // is exactly 10.000) from being pushed up a step by floating point noise.
  const epsilon = 1e-9;
  var price = (supply * 100 / (100 - minMarginPct) - epsilon).ceil();
  price = ((price + roundTo - 1) ~/ roundTo) * roundTo;
  while ((marginPct(supply, price) ?? 0) < minMarginPct - epsilon) {
    price += roundTo;
  }
  return price > calculated ? price : calculated;
}
