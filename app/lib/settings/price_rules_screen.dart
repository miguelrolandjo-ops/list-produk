import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';
import '../core/thousands_formatter.dart';
import '../pricing/defaults.dart';
import '../pricing/margin.dart';
import '../pricing/pricing_settings_service.dart';
import '../products/product_service.dart';
import 'price_change_preview_dialog.dart';

final _pct0 = NumberFormat.decimalPatternDigits(
  locale: 'id_ID',
  decimalDigits: 0,
);
final _factor = NumberFormat.decimalPatternDigits(
  locale: 'id_ID',
  decimalDigits: 2,
);

/// Anchor list + markup. Edits go to a draft; nothing is saved until the
/// owner has seen the "N produk akan berubah" preview and confirmed.
class PriceRulesScreen extends ConsumerStatefulWidget {
  const PriceRulesScreen({super.key});

  @override
  ConsumerState<PriceRulesScreen> createState() => _PriceRulesScreenState();
}

class _PriceRulesScreenState extends ConsumerState<PriceRulesScreen> {
  final _try = TextEditingController();

  PricingConfig? _saved;
  List<Anchor> _anchors = [];
  double _markup = 30;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _try.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await ref.read(productServiceProvider).pricingConfig();
    if (!mounted) return;
    setState(() {
      _saved = config;
      _anchors = [...config.anchors];
      _markup = config.aboveMarkupPct;
    });
  }

  String? get _error => PricingSettingsService.validateAnchors(_anchors);

  bool get _dirty {
    final saved = _saved;
    if (saved == null) return false;
    if (_markup != saved.aboveMarkupPct) return true;
    if (_anchors.length != saved.anchors.length) return true;
    for (var i = 0; i < _anchors.length; i++) {
      if (_anchors[i] != saved.anchors[i]) return true;
    }
    return false;
  }

  /// Draft pricing for the "Coba harga" box, or null while the draft is
  /// invalid.
  PricingConfig? get _draftConfig {
    final saved = _saved;
    if (saved == null || _error != null) return null;
    return PricingConfig(
      anchors: _anchors,
      minRetail: saved.minRetail,
      roundTo: saved.roundTo,
      aboveMarkupPct: _markup,
    );
  }

  void _setAnchors(List<Anchor> next) => setState(
    () => _anchors = [...next]..sort((a, b) => a.$1.compareTo(b.$1)),
  );

  Future<void> _editAnchor([int? index]) async {
    final result = await showDialog<Anchor>(
      context: context,
      builder: (_) =>
          _AnchorDialog(initial: index == null ? null : _anchors[index]),
    );
    if (result == null) return;
    final next = [..._anchors];
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    _setAnchors(next);
  }

  Future<void> _editMarkup() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _MarkupDialog(initial: _markup),
    );
    if (result != null) setState(() => _markup = result);
  }

  Future<void> _apply() async {
    final service = ref.read(pricingSettingsServiceProvider);
    final preview = await service.preview(_anchors, _markup);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PriceChangePreviewDialog(preview: preview),
    );
    if (ok != true) return;
    setState(() => _applying = true);
    final changed = await service.apply(_anchors, _markup);
    ref.invalidate(productsProvider);
    await _load();
    if (!mounted) return;
    setState(() => _applying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aturan harga disimpan. $changed produk berubah.'),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan aturan harga belum diterapkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lanjut mengedit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    final last = _anchors.isEmpty ? null : _anchors.last;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Aturan harga'),
          actions: [
            IconButton(
              tooltip: 'Tambah titik harga',
              icon: const Icon(Icons.add),
              onPressed: _saved == null ? null : () => _editAnchor(),
            ),
          ],
        ),
        body: _saved == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _tryBox(theme),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            children: [
                              Expanded(child: Text('Supplier ≤')),
                              Expanded(child: Text('Harga jual')),
                              Text('Margin'),
                              SizedBox(width: 48),
                            ],
                          ),
                        ),
                        for (var i = 0; i < _anchors.length; i++) _anchorRow(i),
                        if (last != null)
                          ListTile(
                            onTap: _editMarkup,
                            title: Text('> ${formatRupiah(last.$1)}'),
                            subtitle: Text(
                              '× ${_factor.format(1 + _markup / 100)}, '
                              'minimal ${formatRupiah(last.$2)}',
                            ),
                            trailing: const Icon(Icons.edit, size: 18),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/pengaturan/massal'),
                            icon: const Icon(Icons.tune),
                            label: const Text('Ubah massal per rentang'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          FilledButton(
                            onPressed: _dirty && error == null && !_applying
                                ? _apply
                                : null,
                            child: const Text('Terapkan perubahan'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _anchorRow(int i) {
    final (supply, retail) = _anchors[i];
    final margin = marginPct(supply, retail);
    return ListTile(
      onTap: () => _editAnchor(i),
      title: Row(
        children: [
          Expanded(child: Text(formatRupiah(supply))),
          Expanded(child: Text(formatRupiah(retail))),
          Text(margin == null ? '-' : '${_pct0.format(margin)}%'),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Hapus',
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () => _setAnchors([..._anchors]..removeAt(i)),
      ),
    );
  }

  Widget _tryBox(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _try,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(
                labelText: 'Coba harga supplier',
                prefixText: 'Rp ',
              ),
            ),
            // Only this part rebuilds while typing.
            ListenableBuilder(
              listenable: _try,
              builder: (context, _) {
                final supply = parseGrouped(_try.text);
                if (supply == null || supply <= 0) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Masukkan harga lebih dari 0'),
                  );
                }
                final config = _draftConfig;
                if (config == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Perbaiki aturan harga dulu'),
                  );
                }
                final retail = config.calc(supply);
                final margin = marginPct(supply, retail);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatRupiah(retail),
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (margin != null)
                        Chip(label: Text('Margin ${_pct0.format(margin)}%')),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnchorDialog extends StatefulWidget {
  const _AnchorDialog({this.initial});
  final Anchor? initial;

  @override
  State<_AnchorDialog> createState() => _AnchorDialogState();
}

class _AnchorDialogState extends State<_AnchorDialog> {
  late final _supply = TextEditingController(
    text: widget.initial == null ? '' : groupThousands(widget.initial!.$1),
  );
  late final _retail = TextEditingController(
    text: widget.initial == null ? '' : groupThousands(widget.initial!.$2),
  );
  String? _error;

  @override
  void dispose() {
    _supply.dispose();
    _retail.dispose();
    super.dispose();
  }

  void _submit() {
    final supply = parseGrouped(_supply.text);
    final retail = parseGrouped(_retail.text);
    if (supply == null || supply <= 0 || retail == null || retail <= 0) {
      setState(() => _error = 'Isi kedua harga, lebih dari 0');
      return;
    }
    if (retail % 5000 != 0) {
      setState(() => _error = 'Harga jual harus kelipatan Rp 5.000');
      return;
    }
    Navigator.pop(context, (supply, retail));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Tambah titik harga' : 'Ubah titik'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _supply,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsFormatter()],
            decoration: const InputDecoration(
              labelText: 'Harga supplier',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _retail,
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsFormatter()],
            decoration: InputDecoration(
              labelText: 'Harga jual',
              prefixText: 'Rp ',
              helperText: 'Kelipatan Rp 5.000',
              errorText: _error,
            ),
          ),
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

class _MarkupDialog extends StatefulWidget {
  const _MarkupDialog({required this.initial});
  final double initial;

  @override
  State<_MarkupDialog> createState() => _MarkupDialogState();
}

class _MarkupDialogState extends State<_MarkupDialog> {
  late final _controller = TextEditingController(
    text: widget.initial == widget.initial.roundToDouble()
        ? widget.initial.toStringAsFixed(0)
        : widget.initial.toString().replaceAll('.', ','),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 500) {
      setState(() => _error = 'Isi angka 0 sampai 500');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Markup di atas titik terakhir'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: '%',
          helperText: 'Dibulatkan ke atas ke Rp 5.000',
          errorText: _error,
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
