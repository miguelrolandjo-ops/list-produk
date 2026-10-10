import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/rupiah.dart';
import '../pricing/margin.dart';
import 'product_service.dart';

const _units = ['pcs', 'pack', 'box', 'dus'];

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
  String _unit = _units.first;
  bool _retailEdited = false;
  bool _saving = false;
  int? _calculatedRetail;

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
    final categories = await service.categoryNames();
    final suppliers = await service.supplierNames();
    if (!mounted) return;
    setState(() {
      _categoryNames = categories;
      _supplierNames = suppliers;
    });
  }

  int? get _supplyValue => int.tryParse(_supply.text);
  int? get _retailValue => int.tryParse(_retail.text);

  Future<void> _onSupplyChanged(String _) async {
    final supply = _supplyValue;
    if (supply == null || supply <= 0) {
      setState(() => _calculatedRetail = null);
      if (!_retailEdited) _retail.clear();
      return;
    }
    final preview = await ref.read(productServiceProvider).preview(supply);
    if (!mounted || _supplyValue != supply) return;
    setState(() {
      _calculatedRetail = preview.retail;
      if (!_retailEdited) _retail.text = preview.retail.toString();
    });
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
    final supply = _supplyValue;
    final retail = _retailValue;
    final margin = supply == null ? null : marginPct(supply, retail);

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
            _NameField(
              label: 'Kategori (opsional)',
              options: _categoryNames,
              onChanged: (v) => _category = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: [
                for (final u in _units)
                  DropdownMenuItem(value: u, child: Text(u)),
              ],
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
            const SizedBox(height: 12),
            _NameField(
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Harga supplier',
                prefixText: 'Rp ',
              ),
              onChanged: _onSupplyChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0
                    ? 'Harga supplier harus lebih dari 0'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _retail,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Harga jual',
                prefixText: 'Rp ',
                helperText: _calculatedRetail == null
                    ? 'Dihitung otomatis dari harga supplier'
                    : _retailEdited && retail != _calculatedRetail
                    ? 'Diubah manual (hitungan: ${formatRupiah(_calculatedRetail!)})'
                    : 'Dihitung otomatis dari harga supplier',
              ),
              onChanged: (v) => setState(() => _retailEdited = v.isNotEmpty),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Isi harga supplier dulu';
                return n % 5000 != 0 ? 'Harus kelipatan Rp 5.000' : null;
              },
            ),
            const SizedBox(height: 8),
            if (margin != null)
              Text(
                'Margin ${_pct.format(margin)}%',
                style: Theme.of(context).textTheme.titleMedium,
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

/// Text field with suggestions from existing names. Typing a name that
/// isn't in the list creates a new one on save.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.label,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) => options.where(
        (o) => o.toLowerCase().contains(value.text.toLowerCase()),
      ),
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: label,
            helperText: 'Pilih yang ada, atau ketik nama baru',
          ),
          onChanged: onChanged,
          validator: validator,
        );
      },
    );
  }
}
