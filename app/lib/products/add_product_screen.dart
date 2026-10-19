import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';
import '../core/thousands_formatter.dart';
import '../pricing/margin.dart';
import 'name_field.dart';
import 'product_service.dart';

const productUnits = ['pcs', 'pack', 'box', 'dus'];

final _pct = NumberFormat.decimalPatternDigits(
  locale: 'id_ID',
  decimalDigits: 1,
);

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _supply = TextEditingController();
  final _retail = TextEditingController();

  String _category = '';
  String _supplier = '';
  String _unit = productUnits.first;
  bool _retailEdited = false;
  bool _saving = false;
  PricingConfig? _config;

  List<String> _categoryNames = [];
  List<String> _supplierNames = [];

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  @override
  void dispose() {
    _name.dispose();
    _model.dispose();
    _supply.dispose();
    _retail.dispose();
    super.dispose();
  }

  Future<void> _loadNames() async {
    final service = ref.read(productServiceProvider);
    final config = await service.pricingConfig();
    final categories = await service.categoryNames();
    final suppliers = await service.supplierNames();
    if (!mounted) return;
    setState(() {
      _config = config;
      _categoryNames = categories;
      _supplierNames = suppliers;
    });
  }

  int? get _supplyValue => parseGrouped(_supply.text);
  int? get _retailValue => parseGrouped(_retail.text);

  /// Calculated retail for the typed supply price. Synchronous (the config is
  /// cached), so typing never waits on the database.
  int? get _calculatedRetail {
    final supply = _supplyValue;
    final config = _config;
    if (supply == null || supply <= 0 || config == null) return null;
    return config.calc(supply);
  }

  void _onSupplyChanged(String _) {
    if (_retailEdited) return;
    final calculated = _calculatedRetail;
    if (calculated == null) {
      _retail.clear();
    } else {
      _retail.text = groupThousands(calculated);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(productServiceProvider)
          .addManual(
            NewProductInput(
              name: _name.text,
              model: _model.text,
              categoryName: _category,
              unit: _unit,
              supplierName: _supplier,
              supplyPrice: _supplyValue!,
              retailPrice: _retailValue,
            ),
          );
      if (mounted) context.pop();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah manual')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nama produk'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nama produk wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model (opsional)'),
            ),
            const SizedBox(height: 12),
            NameField(
              label: 'Kategori (opsional)',
              options: _categoryNames,
              onChanged: (v) => _category = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: [
                for (final u in productUnits)
                  DropdownMenuItem(value: u, child: Text(u)),
              ],
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
            const SizedBox(height: 12),
            NameField(
              label: 'Supplier',
              options: _supplierNames,
              onChanged: (v) => _supplier = v,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Supplier wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supply,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(
                labelText: 'Harga supplier',
                prefixText: 'Rp ',
              ),
              onChanged: _onSupplyChanged,
              validator: (v) {
                final n = parseGrouped(v ?? '');
                return n == null || n <= 0
                    ? 'Harga supplier harus lebih dari 0'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            // Only the price fields rebuild while typing, not the whole form.
            ListenableBuilder(
              listenable: Listenable.merge([_supply, _retail]),
              builder: (context, _) {
                final calculated = _calculatedRetail;
                final supply = _supplyValue;
                final margin = supply == null
                    ? null
                    : marginPct(supply, _retailValue);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _retail,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [ThousandsFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Harga jual',
                        prefixText: 'Rp ',
                        helperText:
                            calculated != null &&
                                _retailEdited &&
                                _retailValue != calculated
                            ? 'Diubah manual (hitungan: ${formatRupiah(calculated)})'
                            : 'Dihitung otomatis dari harga supplier',
                      ),
                      onChanged: (v) => _retailEdited = v.isNotEmpty,
                      validator: (v) {
                        final n = parseGrouped(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Isi harga supplier dulu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    if (margin != null)
                      Text(
                        'Margin ${_pct.format(margin)}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          // Selling at a loss: show it in red.
                          color: margin < 0
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
