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
