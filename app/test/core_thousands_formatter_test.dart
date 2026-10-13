import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/thousands_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const f = ThousandsFormatter();

  TextEditingValue type(String text, [int? cursor]) => f.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor ?? text.length),
    ),
  );

  test('groupThousands and parseGrouped round-trip', () {
    expect(groupThousands(0), '0');
    expect(groupThousands(999), '999');
    expect(groupThousands(15000), '15.000');
    expect(groupThousands(1350000), '1.350.000');
    expect(parseGrouped('1.350.000'), 1350000);
    expect(parseGrouped(''), isNull);
  });

  test('groups digits while typing and ignores other characters', () {
    expect(type('1500').text, '1.500');
    expect(type('12a3b4567').text, '1.234.567');
    expect(type('').text, '');
  });

  test('drops leading zeros', () {
    expect(type('007').text, '7');
  });

  test('keeps the cursor after the same digit', () {
    // Typed a digit at the end: "1.500" + "0" -> "1.5000" -> "15.000"
    final v = type('1.5000');
    expect(v.text, '15.000');
    expect(v.selection.baseOffset, 6);
    // Inserted in the middle: "1|500" typed "2" -> "12|500" -> "12.500"
    final m = type('12500', 2);
    expect(m.text, '12.500');
    expect(m.selection.baseOffset, 2);
  });
}
