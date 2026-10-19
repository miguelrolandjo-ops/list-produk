/// The supply price that drives a product's retail price, from its suppliers'
/// current prices. [basis] is settings.basis: 'highest', 'lowest' or 'latest'.
/// Returns null when there are no prices.
int? pickBasisSupply(
  String basis,
  Iterable<({int unitPrice, String observedAt})> prices,
) {
  if (prices.isEmpty) return null;
  switch (basis) {
    case 'lowest':
      return prices.map((r) => r.unitPrice).reduce((a, b) => a < b ? a : b);
    case 'latest':
      // ISO-8601 UTC strings sort chronologically.
      return (prices.toList()
            ..sort((a, b) => a.observedAt.compareTo(b.observedAt)))
          .last
          .unitPrice;
    default:
      return prices.map((r) => r.unitPrice).reduce((a, b) => a > b ? a : b);
  }
}

/// The supply price a product's margin warning is judged against.
///
/// [newestFirst] are the product's recorded supply prices, newest first (any
/// supplier). [basis] is settings.margin_basis: 'latest' uses the newest
/// price; 'average' uses the mean of the newest [count] prices, rounded to a
/// whole Rupiah (with fewer than [count] prices, the mean of those it has).
/// Returns null when there are no prices.
int? pickMarginSupply(String basis, int count, List<int> newestFirst) {
  if (newestFirst.isEmpty) return null;
  if (basis != 'average') return newestFirst.first;
  final used = newestFirst.take(count < 1 ? 1 : count).toList();
  return (used.fold<int>(0, (sum, p) => sum + p) / used.length).round();
}
