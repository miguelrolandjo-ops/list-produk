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
