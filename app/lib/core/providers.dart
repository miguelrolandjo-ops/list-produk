import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_database.dart';
import '../products/product_service.dart';

final ownerDbProvider = Provider<OwnerDatabase>((ref) {
  final db = OwnerDatabase();
  ref.onDispose(db.close);
  return db;
});

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(ref.watch(ownerDbProvider)),
);

/// Products that are not soft-deleted, by name.
final productsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(ownerDbProvider);
  return (db.select(db.products)
        ..where((p) => p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();
});
