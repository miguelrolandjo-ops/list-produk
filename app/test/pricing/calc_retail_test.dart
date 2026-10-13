import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/pricing/calc_retail.dart';
import 'package:flutter_application_1/pricing/defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vectors = (jsonDecode(
    File('../shared/pricing_vectors.json').readAsStringSync(),
  ) as List).map((e) => (e[0] as int, e[1] as int)).toList();

  test('vectors file is not empty', () => expect(vectors, isNotEmpty));

  for (final (supply, expected) in vectors) {
    test('supply $supply -> retail $expected', () {
      expect(calcRetail(supply, defaultAnchors), expected);
    });
  }

  test('default anchors are sorted, multiples of 5000, and increasing', () {
    for (var i = 0; i < defaultAnchors.length; i++) {
      expect(defaultAnchors[i].$2 % 5000, 0);
      if (i > 0) {
        expect(defaultAnchors[i].$1, greaterThan(defaultAnchors[i - 1].$1));
        expect(defaultAnchors[i].$2, greaterThan(defaultAnchors[i - 1].$2));
      }
    }
    expect(defaultAnchors, hasLength(18));
  });
}
