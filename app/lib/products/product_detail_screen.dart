import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';
import '../core/thousands_formatter.dart';
import '../pricing/margin.dart';
import 'product_service.dart';

final _date = DateFormat('d MMM y', 'id_ID');
final _pct = NumberFormat.decimalPatternDigits(
  locale: 'id_ID',
  decimalDigits: 0,
);

const _basisLabel = {
  'highest': 'tertinggi',
  'lowest': 'terendah',
  'latest': 'terbaru',
};

String _marginBasisLabel(ProductDetail d) => d.marginBasis == 'average'
    ? 'rata-rata ${d.marginAvgCount} PO terakhir'
    : 'harga PO terakhir';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    // Taken before any await. The app-wide messenger outlives this screen, so
    // the Undo snackbar still shows after it closes.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final service = ref.read(productServiceProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: const Text(
          'Produk dihapus dari daftar dan dari katalog karyawan.',
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
    await service.deleteProduct(productId);
    router.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Produk dihapus'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => service.restoreProduct(productId),
          ),
        ),
      );
  }

  Future<void> _showHistory(BuildContext context, WidgetRef ref) async {
    final history = await ref
        .read(productServiceProvider)
        .priceHistory(productId);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Riwayat harga supplier')),
              for (final h in history)
                ListTile(
                  dense: true,
                  title: Text(h.supplierName),
                  subtitle: Text(_date.format(h.observedAt)),
                  trailing: Text(formatRupiah(h.unitPrice)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editPrice(
    BuildContext context,
    WidgetRef ref,
    ProductDetail detail,
  ) async {
    final price = await showDialog<int>(
      context: context,
      builder: (_) => _EditPriceDialog(initial: detail.product.retailPrice),
    );
    if (price == null) return;
    await ref
        .read(productServiceProvider)
        .setRetailOverride(detail.product.id!, price);
    ref.invalidate(productDetailProvider(productId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail produk'),
        actions: [
          IconButton(
            tooltip: 'Ubah produk',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/produk/$productId/ubah'),
          ),
          IconButton(
            tooltip: 'Hapus produk',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (d) {
          if (d == null) {
            return const Center(child: Text('Produk tidak ditemukan'));
          }
          return _Body(
            detail: d,
            onHistory: () => _showHistory(context, ref),
            onEdit: () => _editPrice(context, ref, d),
            onMargin: () => context.push('/pengaturan/harga'),
          );
        },
      ),
    );
  }
}

/// Owns its controller, so it is disposed only after the dialog's closing
/// animation has finished (disposing it right after showDialog returns
/// crashes while the field is still on screen).
class _EditPriceDialog extends StatefulWidget {
  const _EditPriceDialog({this.initial});

  final int? initial;

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  late final _controller = TextEditingController(
    text: widget.initial == null ? '' : groupThousands(widget.initial!),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final n = parseGrouped(_controller.text);
    if (n == null || n <= 0) {
      setState(() => _error = 'Isi harga lebih dari 0');
      return;
    }
    Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah harga jual'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: const [ThousandsFormatter()],
        decoration: InputDecoration(
          prefixText: 'Rp ',
          errorText: _error,
          helperText: 'Tidak dihitung ulang otomatis.',
          helperMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.detail,
    required this.onHistory,
    required this.onEdit,
    required this.onMargin,
  });

  final ProductDetail detail;
  final VoidCallback onHistory;
  final VoidCallback onEdit;

  /// Opens the pricing rules (Aturan harga).
  final VoidCallback onMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = detail.product;
    final retail = p.retailPrice;
    final supply = detail.marginSupply;
    final margin = supply == null ? null : marginPct(supply, retail);
    final limit = detail.minMarginPct;
    final belowLimit = margin != null && limit != null && margin < limit;
    // Selling at a loss: the margin itself is shown in red, besides the warning.
    final isLoss = margin != null && margin < 0;
    final subtitle = [
      if (p.model != null) p.model!,
      if (detail.categoryName != null) detail.categoryName!,
      p.unit,
    ].join(' · ');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                // Tapping the card edits the retail price, like "Ubah harga".
                child: InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Harga jual'),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              retail == null ? '-' : formatRupiah(retail),
                              style: theme.textTheme.headlineMedium,
                            ),
                            if (margin != null)
                              // Tapping the margin goes to Batas margin instead.
                              ActionChip(
                                label: Text(
                                  'Margin ${_pct.format(margin)}%',
                                  style: isLoss
                                      ? TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onErrorContainer,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : null,
                                ),
                                backgroundColor: isLoss
                                    ? theme.colorScheme.errorContainer
                                    : null,
                                side: isLoss
                                    ? BorderSide(color: theme.colorScheme.error)
                                    : null,
                                onPressed: onMargin,
                              ),
                          ],
                        ),
                        if (belowLimit)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Margin di bawah batas '
                                    '${_pct.format(detail.minMarginPct)}%',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (supply != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Margin dari ${_marginBasisLabel(detail)} '
                              '${formatRupiah(supply)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          p.retailIsOverride == 1
                              ? 'Diubah manual, tidak dihitung ulang otomatis'
                              : 'Otomatis dari harga supplier '
                                    '${_basisLabel[detail.basis] ?? ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Harga supplier', style: theme.textTheme.titleSmall),
              for (final e in detail.currentPrices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.supplierName),
                  subtitle: Text(_date.format(e.observedAt)),
                  trailing: Text(
                    formatRupiah(e.unitPrice),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('Riwayat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Ubah harga'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
