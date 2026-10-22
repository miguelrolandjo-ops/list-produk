import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';
import 'product_service.dart';

/// "Saran harga": retail prices the app proposes after supplier prices changed.
/// Nothing here changes a price until the owner says yes. Products that now
/// sell below the margin limit are listed first.
class PriceSuggestionsScreen extends ConsumerWidget {
  const PriceSuggestionsScreen({super.key});

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    PriceSuggestion s,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    // Below the margin limit: two clicks. The second is this confirmation.
    if (s.belowMargin) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ubah harga jual?'),
          content: Text(
            '${s.name}: dari ${formatRupiah(s.currentRetail)} '
            'ke ${formatRupiah(s.suggestedRetail)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, ubah'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(productServiceProvider).applySuggestion(s.productId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${s.name}: harga jual menjadi ${formatRupiah(s.suggestedRetail)}',
          ),
        ),
      );
  }

  Future<void> _dismiss(
    BuildContext context,
    WidgetRef ref,
    PriceSuggestion s,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(productServiceProvider).dismissSuggestion(s.productId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${s.name}: harga jual tidak diubah. '
            'Ditanyakan lagi saat harga supplier berubah.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(priceSuggestionsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Saran harga')),
      body: suggestions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Tidak ada saran harga'));
          }
          return ListView.separated(
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Harga supplier berubah. Harga jual baru hanya dipakai '
                    'setelah Anda menyetujuinya.',
                  ),
                );
              }
              final s = items[i - 1];
              final up = s.change > 0;
              return ListTile(
                onTap: () => context.push('/produk/${s.productId}'),
                title: Text(s.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatRupiah(s.currentRetail)} → '
                      '${formatRupiah(s.suggestedRetail)} '
                      '(${up ? 'naik' : 'turun'} ${formatRupiah(s.change.abs())})',
                    ),
                    if (s.belowMargin)
                      Text(
                        'Margin di bawah batas dengan harga sekarang',
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                isThreeLine: s.belowMargin,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Tidak: ${s.name}',
                      icon: const Icon(Icons.close),
                      onPressed: () => _dismiss(context, ref, s),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Terapkan: ${s.name}',
                      icon: const Icon(Icons.check),
                      onPressed: () => _apply(context, ref, s),
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
