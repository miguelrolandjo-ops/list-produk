import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';

/// Minimal product list so manually added products are visible.
/// Search, detail and delete come in step 1.3.
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Harga Toko')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tambah'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah manual'),
      ),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada produk'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i];
              final subtitle = [
                if (p.model != null) p.model!,
                p.unit,
              ].join(' · ');
              return ListTile(
                title: Text(p.name),
                subtitle: Text(subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.retailIsOverride == 1)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.edit, size: 16),
                      ),
                    Text(
                      p.retailPrice == null
                          ? '-'
                          : formatRupiah(p.retailPrice!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
