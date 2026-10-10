import 'defaults.dart';

/// Retail price for [supply], from [anchors] (sorted by supply, ascending).
///
/// Money stays in `int`. Interpolation uses integer math; only the
/// above-last-anchor markup involves a percentage (a double), and its
/// result is nudged by a tiny epsilon so 1.3 * 1_100_000 can't round up
/// to the next step because of binary floating point.
int calcRetail(
  int supply,
  List<Anchor> anchors, {
  int minRetail = 5000,
  int roundTo = 5000,
  double aboveMarkupPct = 30,
}) {
  int roundUpInt(int numerator, int denominator) {
    final steps =
        (numerator + denominator * roundTo - 1) ~/ (denominator * roundTo);
    return steps * roundTo;
  }

  final first = anchors.first;
  if (supply <= first.$1) return supply == first.$1 ? first.$2 : minRetail;

  final last = anchors.last;
  if (supply > last.$1) {
    final marked = supply * (100 + aboveMarkupPct) / 100;
    final r = ((marked / roundTo) - 1e-9).ceil() * roundTo;
    return r > last.$2 ? r : last.$2;
  }

  for (var i = 1; i < anchors.length; i++) {
    final (a, b) = anchors[i - 1];
    final (c, d) = anchors[i];
    if (supply == c) return d;
    if (supply < c) {
      // b + (supply - a) * (d - b) / (c - a), rounded up, all in integers.
      return roundUpInt(b * (c - a) + (supply - a) * (d - b), c - a);
    }
  }
  return last.$2;
}
