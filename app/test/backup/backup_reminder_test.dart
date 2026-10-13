import 'package:flutter_application_1/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 6, 12);

  bool due(DateTime? last, {int products = 5, bool enabled = true}) =>
      backupReminderDue(
        lastBackup: last,
        productCount: products,
        now: now,
        enabled: enabled,
      );

  test('never backed up, with data: remind', () => expect(due(null), isTrue));

  test('older than 7 days: remind; exactly 7 days or newer: do not', () {
    expect(due(now.subtract(const Duration(days: 8))), isTrue);
    expect(due(now.subtract(const Duration(days: 7))), isFalse);
    expect(due(now.subtract(const Duration(days: 1))), isFalse);
  });

  test('no products yet: nothing to protect, do not nag', () {
    expect(due(null, products: 0), isFalse);
  });

  test('reminder switched off', () {
    expect(due(null, enabled: false), isFalse);
  });
}
