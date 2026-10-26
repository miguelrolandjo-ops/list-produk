import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';
import '../core/time_ago.dart';
import '../data/owner_database.dart' show Product;
import '../core/thousands_formatter.dart';
import '../pricing/margin.dart';
import 'name_field.dart';
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

/// "Diubah 12 hari lalu (sebelumnya Rp 10.000)", or null if no change of the
/// retail price has been recorded (older data, or never changed).
String? _changeText(Product p) {
  final raw = p.retailChangedAt;
  final at = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  if (at == null) return null;
  final before = p.retailPrev;
  return 'Diubah ${timeAgo(at, DateTime.now())}'
      '${before == null ? '' : ' (sebelumnya ${formatRupiah(before)})'}';
}

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

  Future<void> _applySuggestion(
    BuildContext context,
    WidgetRef ref,
    ProductDetail detail,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final price = detail.product.pendingRetail;
    await ref.read(productServiceProvider).applySuggestion(productId);
    ref.invalidate(productDetailProvider(productId));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            price == null
                ? 'Saran harga sudah tidak berlaku'
                : 'Harga jual diubah menjadi ${formatRupiah(price)}',
          ),
        ),
      );
  }

  Future<void> _applyRecommendation(
    BuildContext context,
    WidgetRef ref,
    PriceRecommendation r,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(productServiceProvider).applyRecommendation(productId);
    ref.invalidate(productDetailProvider(productId));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Harga jual diubah menjadi ${formatRupiah(r.recommendedRetail)}',
          ),
        ),
      );
  }

  Future<void> _ignoreRecommendation(WidgetRef ref) async {
    await ref.read(productServiceProvider).ignoreRecommendation(productId);
    ref.invalidate(productDetailProvider(productId));
  }

  Future<void> _addSupplier(BuildContext context, WidgetRef ref) async {
    final service = ref.read(productServiceProvider);
    final names = await service.supplierNames();
    if (!context.mounted) return;
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => _AddSupplierDialog(supplierNames: names),
    );
    if (result == null) return;
    try {
      await service.addSupplierPrice(
        productId,
        supplierName: result.$1,
        unitPrice: result.$2,
      );
    } on ArgumentError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message}')),
      );
      return;
    }
    ref.invalidate(productDetailProvider(productId));
  }

  Future<void> _dismissSuggestion(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(productServiceProvider).dismissSuggestion(productId);
    ref.invalidate(productDetailProvider(productId));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Harga jual tidak diubah. Ditanyakan lagi saat harga supplier berubah.',
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
      builder: (_) => _EditPriceDialog(
        initial: detail.product.retailPrice,
        recommendation: detail.recommendation,
      ),
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
            onApplyRecommendation: () =>
                _applyRecommendation(context, ref, d.recommendation!),
            onIgnoreRecommendation: () => _ignoreRecommendation(ref),
            onAddSupplier: () => _addSupplier(context, ref),
            onApplySuggestion: () => _applySuggestion(context, ref, d),
            onDismissSuggestion: () => _dismissSuggestion(context, ref),
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
  const _EditPriceDialog({this.initial, this.recommendation});

  final int? initial;

  /// Offered as a one-tap option, even if its card was ignored.
  final PriceRecommendation? recommendation;

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
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
          if (widget.recommendation case final r?) ...[
            const SizedBox(height: 12),
            ActionChip(
              avatar: const Icon(Icons.lightbulb_outline, size: 18),
              label: Text(
                'Disarankan ${formatRupiah(r.recommendedRetail)} '
                '(margin ${_pct.format(r.recommendedMargin)}%)',
              ),
              onPressed: () => setState(() {
                _error = null;
                _controller.text = groupThousands(r.recommendedRetail);
              }),
            ),
          ],
        ],
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
    required this.onApplySuggestion,
    required this.onDismissSuggestion,
    required this.onApplyRecommendation,
    required this.onIgnoreRecommendation,
    required this.onAddSupplier,
  });

  final ProductDetail detail;
  final VoidCallback onHistory;
  final VoidCallback onEdit;

  /// Opens the pricing rules (Aturan harga).
  final VoidCallback onMargin;

  /// Yes / no to the suggested retail price (shown only when there is one).
  final VoidCallback onApplySuggestion;
  final VoidCallback onDismissSuggestion;

  /// Confirmed (second click) recommended price for a below-margin product.
  final VoidCallback onApplyRecommendation;

  /// "Abaikan": hides the recommendation card (the edit dialog still offers it).
  final VoidCallback onIgnoreRecommendation;
  final VoidCallback onAddSupplier;

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
              // Below the margin limit: a recommended price, applied in two clicks.
              // It takes over from the plain suggestion (it is the suggestion
              // itself when that already reaches the limit).
              if (detail.recommendation case final r?)
                // Ignored: no card at all (the plain suggestion stays hidden
                // too); the price edit dialog still offers the price.
                if (!detail.recommendationIgnored)
                  _RecommendationCard(
                    recommendation: r,
                    onConfirmed: onApplyRecommendation,
                    onIgnore: onIgnoreRecommendation,
                  )
                else
                  const SizedBox.shrink()
              else if (p.pendingRetail != null &&
                  p.retailIsOverride == 0 &&
                  retail != null)
                _SuggestionCard(
                  current: retail,
                  suggested: p.pendingRetail!,
                  marginAtSuggested: supply == null
                      ? null
                      : marginPct(supply, p.pendingRetail),
                  belowLimitNow: belowLimit,
                  onApply: onApplySuggestion,
                  onDismiss: onDismissSuggestion,
                ),
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
                        if (p.retailIsOverride == 0)
                          Text(
                            'Otomatis dari harga supplier '
                            '${_basisLabel[detail.basis] ?? ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                        // When the price last changed and what it was before.
                        if (_changeText(p) case final text?)
                          Text(text, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Harga supplier',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddSupplier,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah supplier'),
                  ),
                ],
              ),
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

/// "Harga supplier berubah": the app's proposed retail price, higher or lower,
/// waiting for a yes or no. Nothing changes until the owner says yes.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.current,
    required this.suggested,
    required this.marginAtSuggested,
    required this.belowLimitNow,
    required this.onApply,
    required this.onDismiss,
  });

  final int current;
  final int suggested;
  final double? marginAtSuggested;
  final bool belowLimitNow;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final up = suggested > current;
    final change = formatRupiah((suggested - current).abs());
    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.price_change_outlined,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Harga supplier berubah',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Harga jual disarankan ${formatRupiah(suggested)} '
              '(${up ? 'naik' : 'turun'} $change dari ${formatRupiah(current)}).',
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
            if (marginAtSuggested != null)
              Text(
                'Margin dengan harga ini ${_pct.format(marginAtSuggested)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
            if (belowLimitNow)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Dengan harga sekarang, margin di bawah batas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDismiss, child: const Text('Tidak')),
                const SizedBox(width: 8),
                FilledButton(onPressed: onApply, child: const Text('Terapkan')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Margin di bawah batas": a recommended price that reaches the limit. Changing
/// the price takes two clicks, "Ubah ke Rp X" and then the confirmation.
class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onConfirmed,
    required this.onIgnore,
  });

  final PriceRecommendation recommendation;
  final VoidCallback onConfirmed;
  final VoidCallback onIgnore;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = widget.recommendation;
    final onColor = scheme.onErrorContainer;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: onColor),
                const SizedBox(width: 8),
                Text(
                  'Margin di bawah batas',
                  style: theme.textTheme.titleSmall?.copyWith(color: onColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Margin ${_pct.format(r.currentMargin)}%, batasnya '
              '${_pct.format(r.minMarginPct)}%. Disarankan '
              '${formatRupiah(r.recommendedRetail)} '
              '(margin ${_pct.format(r.recommendedMargin)}%).',
              style: TextStyle(color: onColor),
            ),
            const SizedBox(height: 8),
            if (!_confirming)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onIgnore,
                    child: const Text('Abaikan'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => setState(() => _confirming = true),
                    child: Text('Ubah ke ${formatRupiah(r.recommendedRetail)}'),
                  ),
                ],
              )
            else ...[
              Text(
                'Ubah harga jual dari ${formatRupiah(r.currentRetail)} '
                'ke ${formatRupiah(r.recommendedRetail)}?',
                style: TextStyle(color: onColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _confirming = false),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.onConfirmed,
                    child: const Text('Ya, ubah'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Supplier name (existing or new) and price for one more supplier of the
/// product. Owns its controller, like [_EditPriceDialog].
class _AddSupplierDialog extends StatefulWidget {
  const _AddSupplierDialog({required this.supplierNames});

  final List<String> supplierNames;

  @override
  State<_AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<_AddSupplierDialog> {
  final _price = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _supplier = '';

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (_supplier.trim(), parseGrouped(_price.text)!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah supplier'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NameField(
              label: 'Supplier',
              options: widget.supplierNames,
              onChanged: (v) => _supplier = v,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Supplier wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(
                labelText: 'Harga',
                prefixText: 'Rp ',
              ),
              validator: (v) {
                final n = parseGrouped(v ?? '');
                return n == null || n <= 0
                    ? 'Harga supplier harus lebih dari 0'
                    : null;
              },
            ),
          ],
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
