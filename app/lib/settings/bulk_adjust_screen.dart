import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/thousands_formatter.dart';
import '../pricing/bulk_adjust_service.dart';
import 'price_change_preview_dialog.dart';

/// "Ubah massal per rentang": raise or lower retail prices of all products
/// whose supply price is in a range. Results are saved as manual prices.
class BulkAdjustScreen extends ConsumerStatefulWidget {
  const BulkAdjustScreen({super.key});

  @override
  ConsumerState<BulkAdjustScreen> createState() => _BulkAdjustScreenState();
}

class _BulkAdjustScreenState extends ConsumerState<BulkAdjustScreen> {
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _amount = TextEditingController();

  bool _percent = true;
  bool _increase = true;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _amount.dispose();
    super.dispose();
  }

  BulkAdjustInput? _input() {
    final min = parseGrouped(_min.text) ?? 0;
    final max = parseGrouped(_max.text);
    if (max != null && max < min) {
      setState(() => _error = 'Batas atas harus ≥ batas bawah');
      return null;
    }
    final sign = _increase ? 1 : -1;
    if (_percent) {
      final v = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
      if (v == null || v <= 0 || v > 1000) {
        setState(() => _error = 'Isi persen lebih dari 0');
        return null;
      }
      return BulkAdjustInput.percent(sign * v, minSupply: min, maxSupply: max);
    }
    final v = parseGrouped(_amount.text);
    if (v == null || v <= 0) {
      setState(() => _error = 'Isi jumlah Rupiah lebih dari 0');
      return null;
    }
    return BulkAdjustInput.rupiah(sign * v, minSupply: min, maxSupply: max);
  }

  Future<void> _preview() async {
    setState(() => _error = null);
    final input = _input();
    if (input == null) return;
    final service = ref.read(bulkAdjustServiceProvider);
    final preview = await service.preview(input);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PriceChangePreviewDialog(preview: preview),
    );
    if (ok != true || preview.changes.isEmpty) return;
    setState(() => _busy = true);
    final changed = await service.apply(input);
    ref.invalidate(productsProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$changed produk diubah dan ditandai harga manual.'),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah massal per rentang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Rentang harga supplier',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [ThousandsFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Dari',
                    prefixText: 'Rp ',
                    hintText: '0',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [ThousandsFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Sampai',
                    prefixText: 'Rp ',
                    hintText: 'tanpa batas',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Naik')),
              ButtonSegment(value: false, label: Text('Turun')),
            ],
            selected: {_increase},
            onSelectionChanged: (s) => setState(() => _increase = s.first),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Persen (%)')),
              ButtonSegment(value: false, label: Text('Rupiah (Rp)')),
            ],
            selected: {_percent},
            onSelectionChanged: (s) => setState(() {
              _percent = s.first;
              _amount.clear();
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.numberWithOptions(decimal: _percent),
            inputFormatters: _percent ? null : const [ThousandsFormatter()],
            decoration: InputDecoration(
              labelText: 'Jumlah',
              prefixText: _percent ? null : 'Rp ',
              suffixText: _percent ? '%' : null,
              helperText:
                  'Hasil dibulatkan ke atas ke Rp 5.000. Produk dengan harga '
                  'manual tidak ikut berubah.',
              helperMaxLines: 3,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _preview,
            child: const Text('Lihat pratinjau'),
          ),
        ],
      ),
    );
  }
}
