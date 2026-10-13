import 'package:flutter/services.dart';

/// `15000` -> `15.000` (no "Rp" prefix; the field shows that itself).
String groupThousands(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

/// `15.000` -> `15000`. Null when there are no digits.
int? parseGrouped(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));

/// Keeps only digits and shows them with `.` as thousands separator while the
/// user types. The cursor stays after the same digit it was after before.
class ThousandsFormatter extends TextInputFormatter {
  const ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    // Digits before the cursor, so we can put it back after regrouping.
    final cursor = newValue.selection.baseOffset.clamp(0, raw.length);
    final digitsBeforeCursor = raw
        .substring(0, cursor)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    // Drop leading zeros ("007" -> "7").
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final removed = digits.length - trimmed.length;
    final text = groupThousands(int.parse(trimmed));

    var seen = 0;
    var offset = 0;
    final target = (digitsBeforeCursor - removed).clamp(0, trimmed.length);
    while (offset < text.length && seen < target) {
      if (text[offset] != '.') seen++;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
