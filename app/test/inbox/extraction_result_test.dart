import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/inbox/extraction_result.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> sample() =>
    jsonDecode(File('../shared/extraction_sample.json').readAsStringSync())
        as Map<String, Object?>;

void main() {
  test('parses the shared sample that the Go FakeExtractor must produce', () {
    final r = ExtractionResult.fromJson(sample());
    expect(r.supplier.name, 'CV Maju Elektrik');
    expect(r.supplier.confidence, 0.96);
    expect(r.poDate, DateTime.utc(2026, 10, 4));
    expect(r.lines, hasLength(5));

    final first = r.lines.first;
    expect(first.name, 'Kbl Type C 100cm');
    expect(first.qty, 20.0);
    expect(first.unit, 'pcs');
    expect(first.unitPrice, 9500);
    expect(first.unitPriceConfidence, 0.95);

    final noPrice = r.lines[3];
    expect(noPrice.unitPrice, isNull);
    final shipping = r.lines[4];
    expect(shipping.qty, isNull);
    expect(shipping.unit, isNull);
    expect(shipping.unitPrice, 25000);
  });

  test('null header fields are allowed', () {
    final r = ExtractionResult.fromJson({
      'supplier': {'name': null, 'phone': null, 'address': null, 'confidence': 0},
      'po_date': null,
      'lines': [],
    });
    expect(r.supplier.name, isNull);
    expect(r.poDate, isNull);
    expect(r.lines, isEmpty);
  });

  test('whole-number prices written as 9500.0 are accepted', () {
    final j = sample();
    ((j['lines'] as List).first as Map)['unit_price'] = 9500.0;
    expect(ExtractionResult.fromJson(j).lines.first.unitPrice, 9500);
  });

  group('rejects malformed results', () {
    void bad(String why, void Function(Map<String, Object?> j) mutate) {
      test(why, () {
        final j = sample();
        mutate(j);
        expect(() => ExtractionResult.fromJson(j), throwsFormatException);
      });
    }

    Map line(Map<String, Object?> j) => (j['lines'] as List).first as Map;

    bad('fractional price', (j) => line(j)['unit_price'] = 9500.5);
    bad('price as a string', (j) => line(j)['unit_price'] = '9.500');
    bad('negative price', (j) => line(j)['unit_price'] = -5);
    bad('zero qty', (j) => line(j)['qty'] = 0);
    bad('empty name', (j) => line(j)['name'] = '  ');
    bad('missing name', (j) => line(j).remove('name'));
    bad('confidence above 1', (j) => (line(j)['confidence'] as Map)['name'] = 1.5);
    bad('wrong date format', (j) => j['po_date'] = '04-10-2026');
    bad('impossible date', (j) => j['po_date'] = '2026-02-31');
    bad('lines not a list', (j) => j['lines'] = 'none');
    bad('missing supplier', (j) => j.remove('supplier'));
  });

  test('top level must be an object', () {
    expect(() => ExtractionResult.fromJson([]), throwsFormatException);
    expect(() => ExtractionResult.fromJson(null), throwsFormatException);
  });
}
