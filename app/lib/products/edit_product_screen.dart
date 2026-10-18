import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/thousands_formatter.dart';
import 'add_product_screen.dart' show productUnits;
import 'name_field.dart';
import 'product_service.dart';

/// Edit a product's name, unit, category and supplier prices.
class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _prices = <String, TextEditingController>{};

  ProductDetail? _detail;
  List<String> _categoryNames = [];
  String _category = '';
  String _unit = productUnits.first;
  bool _missing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _prices.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final service = ref.read(productServiceProvider);
    final detail = await service.detail(widget.productId);
    final categories = await service.categoryNames();
    if (!mounted) return;
    if (detail == null) {
      setState(() => _missing = true);
      return;
    }
    _name.text = detail.product.name;
    for (final e in detail.currentPrices) {
      _prices[e.supplierId] = TextEditingController(
        text: groupThousands(e.unitPrice),
      );
    }
    setState(() {
      _detail = detail;
      _categoryNames = categories;
      _category = detail.categoryName ?? '';
      _unit = detail.product.unit;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(productServiceProvider)
          .updateProduct(
            widget.productId,
            name: _name.text,
            unit: _unit,
            categoryName: _category,
            supplyPrices: {
              for (final e in _prices.entries)
                e.key: parseGrouped(e.value.text)!,
            },
          );
      ref.invalidate(productDetailProvider(widget.productId));
      if (mounted) context.pop();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final units = {...productUnits, _unit}.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah produk')),
      body: _missing
          ? const Center(child: Text('Produk tidak ditemukan'))
          : detail == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nama produk'),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Nama produk wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  NameField(
                    label: 'Kategori (opsional)',
                    options: _categoryNames,
                    initialText: _category,
                    onChanged: (v) => _category = v,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                    items: [
                      for (final u in units)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                  if (detail.currentPrices.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Harga supplier',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.product.retailIsOverride == 1
                          ? 'Harga jual manual tidak berubah.'
                          : 'Harga jual dihitung ulang jika harga berubah.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    for (final e in detail.currentPrices) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _prices[e.supplierId],
                        keyboardType: TextInputType.number,
                        inputFormatters: const [ThousandsFormatter()],
                        decoration: InputDecoration(
                          labelText: e.supplierName,
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
                  ],
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
