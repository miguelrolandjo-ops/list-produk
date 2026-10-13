import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../data/owner_database.dart';

final _date = DateFormat('d MMM y, HH.mm', 'id_ID');

/// Archived products, most recently archived first. Restoring puts a product
/// back in the list.
class ArchivedProductsScreen extends ConsumerWidget {
  const ArchivedProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = ref.watch(archivedProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Produk diarsipkan')),
      body: archived.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Tidak ada produk diarsipkan'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = items[i];
              final when = DateTime.tryParse(p.deletedAt ?? '')?.toLocal();
              return ListTile(
                title: Text(p.name),
                subtitle: Text(
                  [
                    if (p.model != null) p.model!,
                    if (when != null) 'Diarsipkan ${_date.format(when)}',
                  ].join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(productServiceProvider)
                            .restoreProduct(p.id!);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${p.name} dipulihkan')),
                        );
                      },
                      child: const Text('Pulihkan'),
                    ),
                    IconButton(
                      tooltip: 'Hapus permanen',
                      icon: Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _deleteForGood(context, ref, p),
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

Future<void> _deleteForGood(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus permanen?'),
      content: Text(
        '"${product.name}" dan seluruh riwayat harga supplier-nya akan '
        'dihapus dan tidak bisa dikembalikan, kecuali dari file cadangan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus permanen'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(productServiceProvider).deleteArchivedProduct(product.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} dihapus permanen')));
  } on ArgumentError catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${e.message}')));
  }
}
