import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/matching/normalize.dart';
import 'package:flutter_application_1/matching/product_matcher.dart';
import 'package:flutter_application_1/matching/token_dictionary.dart';

void main() {
  group('normalize', () {
    test('normalizeName matches the alias_norm rule', () {
      expect(normalizeName('  Kbl  Type-C 100CM '), 'kbl type c 100cm');
    });

    test('whole-meter cm lengths become meters', () {
      expect(baseTokens('Kbl 100cm'), ['kbl', '1m']);
      expect(baseTokens('Kbl 200 cm'), ['kbl', '2m']);
      expect(baseTokens('Kbl 150cm'), ['kbl', '150cm']);
      expect(baseTokens('Kabel 1M'), ['kabel', '1m']);
    });

    test('empty input gives no tokens', () {
      expect(baseTokens('  -- '), isEmpty);
    });
  });

  group('TokenDictionary.learn', () {
    test('learns a clear abbreviation', () {
      final d = TokenDictionary.learn([
        (alias: 'Kbl Type C 100cm', canonical: 'Kabel USB-C 1M'),
      ]);
      expect(d.entries['kbl'], 'kabel');
    });

    test('does not learn unrelated word swaps or numbers', () {
      final d = TokenDictionary.learn([
        (alias: 'Kabel Data Biru 100', canonical: 'Kabel Data Hitam 1'),
      ]);
      expect(d.entries, isEmpty);
    });

    test('skips an ambiguous abbreviation', () {
      final d = TokenDictionary.learn([
        (alias: 'Hd Case', canonical: 'Hard Hold Case'),
      ]);
      expect(d.entries.containsKey('hd'), isFalse);
    });

    test('expands learned tokens', () {
      final d = TokenDictionary({'kbl': 'kabel'});
      expect(d.apply('Kbl USB 100cm'), 'kabel usb 1m');
    });
  });

  group('ProductMatcher', () {
    const sup = 'sup-a';
    const other = 'sup-b';

    const usbc = MatchCandidate(
      productId: 'p1',
      name: 'Kabel USB-C 1M',
      aliases: [AliasEntry(supplierId: sup, alias: 'Kabel USB-C 1M Hitam')],
      lastPriceBySupplier: {sup: 9500},
    );
    const charger = MatchCandidate(
      productId: 'p2',
      name: 'Charger Fast 20W',
      aliases: [AliasEntry(supplierId: other, alias: 'Adaptor 20W')],
    );

    test('exact alias for the same supplier is auto, ignoring case and spacing', () {
      final m = ProductMatcher(candidates: [usbc, charger]);
      final r = m.match(rawName: ' kabel  usb-c 1m HITAM', supplierId: sup);
      expect(r.status, MatchStatus.auto);
      expect(r.productId, 'p1');
    });

    test('same alias text from another supplier is not auto', () {
      final m = ProductMatcher(candidates: [usbc, charger]);
      final r = m.match(rawName: 'Kabel USB-C 1M Hitam', supplierId: other);
      expect(r.status, MatchStatus.suggested);
      expect(r.productId, 'p1');
    });

    test('no supplier never auto-links', () {
      final m = ProductMatcher(candidates: [usbc, charger]);
      final r = m.match(rawName: 'Kabel USB-C 1M Hitam');
      expect(r.status, MatchStatus.suggested);
    });

    test('similar name is suggested', () {
      final m = ProductMatcher(candidates: [usbc, charger]);
      final r = m.match(rawName: 'Kabel USB C 1 M', supplierId: sup);
      expect(r.status, MatchStatus.suggested);
      expect(r.productId, 'p1');
    });

    test('unrelated name is new', () {
      final m = ProductMatcher(candidates: [usbc, charger]);
      final r = m.match(rawName: 'Sarung Bantal Polos', supplierId: sup);
      expect(r.status, MatchStatus.isNew);
      expect(r.productId, isNull);
    });

    test('empty name is new', () {
      final m = ProductMatcher(candidates: [usbc]);
      expect(m.match(rawName: '  ').status, MatchStatus.isNew);
    });

    test('a learned abbreviation lifts an otherwise weak match', () {
      const target = MatchCandidate(
        productId: 'p3',
        name: 'Kabel Charger Samsung',
        aliases: [AliasEntry(supplierId: other, alias: 'Kbl Charger Samsung')],
      );
      // Same alias pair teaches kbl -> kabel for every supplier.
      final withLearning = ProductMatcher(candidates: [target]);
      final without = ProductMatcher(
        candidates: [target],
        dictionary: TokenDictionary(),
        suggestThreshold: 0,
      );
      final a = withLearning.match(rawName: 'Kbl Chrgr Samsung', supplierId: sup);
      final b = without.match(rawName: 'Kbl Chrgr Samsung', supplierId: sup);
      expect(a.suggestions.first.score, greaterThan(b.suggestions.first.score));
    });

    test('price near the last supply price breaks a tie', () {
      const x = MatchCandidate(
        productId: 'a',
        name: 'Kabel Data 1M',
        lastPriceBySupplier: {sup: 20000},
      );
      const y = MatchCandidate(
        productId: 'b',
        name: 'Kabel Data 1M',
        lastPriceBySupplier: {sup: 9500},
      );
      final m = ProductMatcher(candidates: [x, y]);
      final r = m.match(rawName: 'Kabel Data 1M', supplierId: sup, unitPrice: 9800);
      expect(r.productId, 'b');
      expect([for (final s in r.suggestions) s.productId], ['b', 'a']);
    });

    test('price and supplier cannot create a match from a dissimilar name', () {
      const z = MatchCandidate(
        productId: 'z',
        name: 'Sarung Bantal Polos',
        aliases: [AliasEntry(supplierId: sup, alias: 'Sarung Bantal')],
        lastPriceBySupplier: {sup: 9500},
      );
      final m = ProductMatcher(candidates: [z]);
      final r = m.match(rawName: 'Kabel USB', supplierId: sup, unitPrice: 9500);
      expect(r.status, MatchStatus.isNew);
    });

    test('returns at most maxSuggestions, best first', () {
      final cs = [
        for (var i = 0; i < 5; i++)
          MatchCandidate(productId: 'p$i', name: 'Kabel Data 1M'),
      ];
      final r = ProductMatcher(candidates: cs).match(rawName: 'Kabel Data 1M');
      expect(r.suggestions.length, 3);
    });
  });
}
