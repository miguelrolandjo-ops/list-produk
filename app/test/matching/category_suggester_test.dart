import 'package:flutter_application_1/matching/category_suggester.dart';
import 'package:flutter_application_1/matching/product_matcher.dart';
import 'package:flutter_application_1/matching/token_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

MatchCandidate p(String id, String name, String? category, {List<String> aliases = const []}) =>
    MatchCandidate(
      productId: id,
      name: name,
      categoryName: category,
      aliases: [for (final a in aliases) AliasEntry(supplierId: 's', alias: a)],
    );

void main() {
  final catalog = [
    p('1', 'Kabel USB-C 1M', 'Kabel'),
    p('2', 'Kabel Lightning 1M', 'Kabel'),
    p('3', 'Kabel Micro USB 2M', 'Kabel'),
    p('4', 'Charger Fast 20W', 'Charger'),
    p('5', 'Charger Mobil 2 Port', 'Charger'),
    p('6', 'Earphone TWS Bluetooth', 'Audio'),
    p('7', 'Casing Silikon', null), // uncategorized: teaches nothing
  ];

  CategorySuggester suggester([List<MatchCandidate>? c, TokenDictionary? d]) =>
      CategorySuggester(c ?? catalog, d ?? TokenDictionary());

  test('suggests the category of the most similar products', () {
    final s = suggester().suggest('Kabel Type C 2M');
    expect(s?.category, 'Kabel');
    expect(s!.confidence, greaterThan(0.5));
  });

  test('a different product family gets its own category', () {
    expect(suggester().suggest('Charger Fast 33W')?.category, 'Charger');
    expect(suggester().suggest('Earphone TWS Pro')?.category, 'Audio');
  });

  test('an unrelated name gets no suggestion', () {
    expect(suggester().suggest('Sarung Bantal Polos'), isNull);
  });

  test('uncategorized products and an empty name never produce a suggestion', () {
    expect(suggester([p('7', 'Casing Silikon', null)]).suggest('Casing Silikon'), isNull);
    expect(suggester().suggest('  '), isNull);
    expect(suggester([]).suggest('Kabel'), isNull);
  });

  test('a split vote gets no suggestion rather than a bad one', () {
    final split = [
      p('1', 'Kabel Charger 1M', 'Kabel'),
      p('2', 'Kabel Charger 2M', 'Charger'),
    ];
    // Equal similarity to both categories: no clear majority.
    final s = CategorySuggester(split, TokenDictionary(), minShare: 0.6);
    expect(s.suggest('Kabel Charger 3M'), isNull);
  });

  test('learned abbreviations carry over: "kbl" finds the Kabel category', () {
    final dict = TokenDictionary({'kbl': 'kabel'});
    expect(suggester(catalog, dict).suggest('Kbl USB-C 1M')?.category, 'Kabel');
  });

  test("a product's supplier aliases also count", () {
    final c = [
      p('1', 'Perangkat 9', 'Kabel', aliases: ['Kbl Type C 100cm']),
      p('2', 'Charger Fast 20W', 'Charger'),
    ];
    expect(CategorySuggester(c, TokenDictionary()).suggest('Kbl Type C 100cm')?.category, 'Kabel');
  });

  test('it learns: filing one more product changes the next suggestion', () {
    expect(suggester().suggest('Powerbank 10000mAh'), isNull);
    final more = [...catalog, p('8', 'Powerbank 20000mAh', 'Powerbank')];
    expect(suggester(more).suggest('Powerbank 10000mAh')?.category, 'Powerbank');
  });

  test('fromMatcher uses the matcher catalog and its learned dictionary', () {
    final matcher = ProductMatcher(
      candidates: [
        p('1', 'Kabel USB-C', 'Kabel', aliases: ['Kbl USB-C']),
        p('2', 'Charger Fast', 'Charger'),
      ],
    );
    expect(matcher.dictionary.entries['kbl'], 'kabel');
    expect(CategorySuggester.fromMatcher(matcher).suggest('Kbl USB-C 2M')?.category, 'Kabel');
  });
}
