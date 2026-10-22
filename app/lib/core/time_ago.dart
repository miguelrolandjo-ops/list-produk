/// "hari ini", "kemarin", "12 hari lalu", "2 bulan lalu", "1 tahun lalu".
///
/// Counted in calendar days (not 24-hour periods), so something from 23.00
/// yesterday is "kemarin" even if it was only two hours ago. [then] and [now]
/// are compared in the same time zone (pass local times).
String timeAgo(DateTime then, DateTime now) {
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(then.year, then.month, then.day))
      .inDays;
  if (days <= 0) return 'hari ini'; // also a time slightly in the future
  if (days == 1) return 'kemarin';
  if (days < 30) return '$days hari lalu';
  if (days < 365) return '${days ~/ 30} bulan lalu';
  return '${days ~/ 365} tahun lalu';
}
