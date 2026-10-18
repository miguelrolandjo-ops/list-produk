import '../data/owner_database.dart';
import 'product_matcher.dart';

/// Builds a [ProductMatcher] from the local catalog.
///
/// Reads only. Archived products are left out: they are no longer part of the
/// catalog, so a PO line should not silently re-link to them.
class MatchRepository {
  MatchRepository(this._db);

  final OwnerDatabase _db;

  Future<ProductMatcher> buildMatcher() async =>
      ProductMatcher(candidates: await loadCandidates());

  Future<List<MatchCandidate>> loadCandidates() async {
    final products = await _db
        .customSelect(
          'SELECT p.id, p.name, p.model, c.name AS category FROM products p '
          'LEFT JOIN categories c ON c.id = p.category_id '
          'WHERE p.deleted_at IS NULL',
        )
        .get();

    final aliases = <String, List<AliasEntry>>{};
    final aliasRows = await _db
        .customSelect('SELECT product_id, supplier_id, alias FROM product_aliases')
        .get();
    for (final r in aliasRows) {
      aliases
          .putIfAbsent(r.read<String>('product_id'), () => [])
          .add(
            AliasEntry(
              supplierId: r.read<String>('supplier_id'),
              alias: r.read<String>('alias'),
            ),
          );
    }

    final prices = <String, Map<String, int>>{};
    final priceRows = await _db
        .customSelect(
          'SELECT product_id, supplier_id, unit_price FROM current_supplier_prices',
        )
        .get();
    for (final r in priceRows) {
      prices.putIfAbsent(r.read<String>('product_id'), () => {})[r.read<String>(
            'supplier_id',
          )] =
          r.read<int>('unit_price');
    }

    return [
      for (final p in products)
        MatchCandidate(
          productId: p.read<String>('id'),
          name: p.read<String>('name'),
          model: p.readNullable<String>('model'),
          categoryName: p.readNullable<String>('category'),
          aliases: aliases[p.read<String>('id')] ?? const [],
          lastPriceBySupplier: prices[p.read<String>('id')] ?? const {},
        ),
    ];
  }
}
