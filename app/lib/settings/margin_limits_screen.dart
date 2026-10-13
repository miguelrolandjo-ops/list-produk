import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';
import '../core/thousands_formatter.dart';
import '../pricing/margin_service.dart';

final _pct = NumberFormat.decimalPattern('id_ID');

/// Minimum margin per supply price range. Products below their limit get a
/// warning in the list and on the detail screen.
class MarginLimitsScreen extends ConsumerStatefulWidget {
  const MarginLimitsScreen({super.key});

  @override
  ConsumerState<MarginLimitsScreen> createState() => _MarginLimitsScreenState();
}

class _MarginLimitsScreenState extends ConsumerState<MarginLimitsScreen> {
  List<MarginLimit>? _saved;
  List<MarginLimit> _limits = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await ref.read(marginServiceProvider).load();
    if (!mounted) return;
    setState(() {
      _saved = loaded;
      _limits = [...loaded];
    });
  }

  String? get _error => MarginService.validate(_limits);
  bool get _dirty => _saved != null && _limits.toString() != _saved.toString();

  Future<void> _edit(int index) async {
    final isLast = index == _limits.length - 1;
    final result = await showDialog<MarginLimit>(
      context: context,
      builder: (_) => _LimitDialog(initial: _limits[index], isLast: isLast),
    );
    if (result == null) return;
    setState(() => _limits[index] = result);
  }

  /// Adds a range by splitting the last (open-ended) one at its start.
  Future<void> _add() async {
    final previousUpTo = _limits.length < 2
        ? null
        : _limits[_limits.length - 2].$1;
    final result = await showDialog<MarginLimit>(
      context: context,
      builder: (_) => _LimitDialog(
        initial: (null, _limits.last.$2),
        isLast: false,
        askUpTo: true,
        minUpTo: previousUpTo,
      ),
    );
    if (result == null) return;
    setState(() => _limits.insert(_limits.length - 1, result));
  }

  void _remove(int index) {
    // The last range keeps no upper limit; removing a middle one widens the
    // next range downwards.
    if (_limits.length == 1) return;
    setState(() {
      final wasLast = index == _limits.length - 1;
      _limits.removeAt(index);
      // The range before it becomes the open-ended one.
      if (wasLast) _limits[_limits.length - 1] = (null, _limits.last.$2);
    });
  }

  Future<void> _save() async {
    await ref.read(marginServiceProvider).save(_limits);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Batas margin disimpan')));
  }

  String _label(int index) {
    final ranges = MarginService.toRanges(_limits);
    final (min, max, _) = ranges[index];
    if (max == null) return 'Di atas ${formatRupiah(min)}';
    if (min == 0) return 'Di bawah ${formatRupiah(max)}';
    return '${formatRupiah(min)} – ${formatRupiah(max)}';
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Buang perubahan?'),
            content: const Text('Perubahan batas margin belum disimpan.'),
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
        if (discard == true && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Batas margin'),
          actions: [
            IconButton(
              tooltip: 'Tambah rentang',
              icon: const Icon(Icons.add),
              onPressed: _saved == null ? null : _add,
            ),
          ],
        ),
        body: _saved == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Produk dengan margin di bawah batas rentang harga '
                      'supplier-nya diberi tanda peringatan.',
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var i = 0; i < _limits.length; i++)
                          ListTile(
                            onTap: () => _edit(i),
                            title: Text(_label(i)),
                            subtitle: Text(
                              'Peringatan jika margin di bawah '
                              '${_pct.format(_limits[i].$2)}%',
                            ),
                            trailing: _limits.length > 1
                                ? IconButton(
                                    tooltip: 'Hapus',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    onPressed: () => _remove(i),
                                  )
                                : null,
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
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          FilledButton(
                            onPressed: _dirty && error == null ? _save : null,
                            child: const Text('Simpan'),
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
}

class _LimitDialog extends StatefulWidget {
  const _LimitDialog({
    required this.initial,
    required this.isLast,
    this.askUpTo = false,
    this.minUpTo,
  });

  final MarginLimit initial;
  final bool isLast;

  /// True when adding: the upper bound is asked even though it is empty.
  final bool askUpTo;
  final int? minUpTo;

  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  late final _upTo = TextEditingController(
    text: widget.initial.$1 == null ? '' : groupThousands(widget.initial.$1!),
  );
  late final _pctField = TextEditingController(
    text: widget.initial.$2 == widget.initial.$2.roundToDouble()
        ? widget.initial.$2.toStringAsFixed(0)
        : widget.initial.$2.toString().replaceAll('.', ','),
  );
  String? _error;

  @override
  void dispose() {
    _upTo.dispose();
    _pctField.dispose();
    super.dispose();
  }

  void _submit() {
    final pct = double.tryParse(_pctField.text.trim().replaceAll(',', '.'));
    if (pct == null || pct < 0 || pct >= 100) {
      setState(() => _error = 'Isi margin 0 sampai 99');
      return;
    }
    int? upTo;
    if (!widget.isLast) {
      upTo = parseGrouped(_upTo.text);
      if (upTo == null || upTo <= 0) {
        setState(() => _error = 'Isi batas atas lebih dari 0');
        return;
      }
    }
    Navigator.pop(context, (upTo, pct));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batas margin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isLast)
            TextField(
              controller: _upTo,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(
                labelText: 'Harga supplier di bawah',
                prefixText: 'Rp ',
              ),
            ),
          if (!widget.isLast) const SizedBox(height: 12),
          TextField(
            controller: _pctField,
            autofocus: widget.isLast,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Margin minimum',
              suffixText: '%',
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
