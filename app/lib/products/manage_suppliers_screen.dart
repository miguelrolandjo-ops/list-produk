import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// "Kelola supplier": every supplier with the number of products it has prices
/// for, and a way to remove the ones that are no longer needed. Reached from the
/// list's side menu and from Settings, like "Kelola kategori".
class ManageSuppliersScreen extends ConsumerWidget {
  const ManageSuppliersScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SupplierCount supplier,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(productServiceProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus supplier "${supplier.name}"?'),
        content: Text(
          supplier.count == 0
              ? 'Supplier ini tidak punya harga untuk produk mana pun.'
              : '${supplier.count} produk punya harga dari supplier ini. '
                    'Riwayat harga dan nama produk dari supplier ini ikut '
                    'dihapus. Produknya tidak dihapus. Jika harga dari '
                    'supplier ini menentukan harga jual, harga jual baru '
                    'disarankan dulu dan menunggu persetujuan Anda.',
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
    await service.deleteSupplier(supplier.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Supplier "${supplier.name}" dihapus')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(supplierCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola supplier')),
      body: suppliers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada supplier'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = items[i];
              return ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(s.name),
                subtitle: Text('${s.count} produk'),
                trailing: IconButton(
                  tooltip: 'Hapus supplier ${s.name}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, s),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
