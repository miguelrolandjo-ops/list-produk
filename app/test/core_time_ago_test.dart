import 'package:flutter_application_1/core/time_ago.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 22, 15, 30);

  test('same day, including a time slightly in the future', () {
    expect(timeAgo(DateTime(2026, 10, 22, 0, 5), now), 'hari ini');
    expect(timeAgo(DateTime(2026, 10, 22, 16, 0), now), 'hari ini');
  });

  test('counts calendar days: late yesterday is "kemarin"', () {
    expect(timeAgo(DateTime(2026, 10, 21, 23, 0), now), 'kemarin');
    expect(timeAgo(DateTime(2026, 10, 21, 1, 0), now), 'kemarin');
  });

  test('days up to a month', () {
    expect(timeAgo(DateTime(2026, 10, 10, 9, 0), now), '12 hari lalu');
    expect(timeAgo(DateTime(2026, 9, 23, 9, 0), now), '29 hari lalu');
  });

  test('months and years', () {
    expect(timeAgo(DateTime(2026, 9, 22), now), '1 bulan lalu'); // 30 days
    expect(timeAgo(DateTime(2026, 4, 22), now), '6 bulan lalu');
    expect(timeAgo(DateTime(2025, 10, 22), now), '1 tahun lalu');
    expect(timeAgo(DateTime(2023, 10, 22), now), '3 tahun lalu');
  });
}
