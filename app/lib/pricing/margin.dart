/// Margin as a percentage of the retail price: (retail - supply) / retail.
/// Returns null when there is no retail price to compare against.
double? marginPct(int supply, int? retail) {
  if (retail == null || retail <= 0) return null;
  return (retail - supply) / retail * 100;
}
