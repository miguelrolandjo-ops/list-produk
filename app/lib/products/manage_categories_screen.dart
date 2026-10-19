import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// "Kelola kategori": see every category with its product count, and delete
/// the ones that are no longer needed. Reached from the list's side menu and
/// from Settings.
class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CategoryCount category,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(productServiceProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus kategori "${category.name}"?'),
        content: Text(
          category.count == 0
              ? 'Kategori ini tidak dipakai produk mana pun.'
              : '${category.count} produk akan menjadi tanpa kategori. '
                    'Produknya tidak dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await service.deleteCategory(category.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Kategori "${category.name}" dihapus')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(categoryCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola kategori')),
      body: counts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (data) {
          if (data.categories.isEmpty) {
            return const Center(child: Text('Belum ada kategori'));
          }
          return ListView.separated(
            itemCount: data.categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = data.categories[i];
              return ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(c.name),
                subtitle: Text('${c.count} produk'),
                trailing: IconButton(
                  tooltip: 'Hapus kategori ${c.name}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
