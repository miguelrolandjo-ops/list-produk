import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/display_prefs.dart';
import '../core/providers.dart';
import '../backup/backup_screen.dart' show daysAgo;
import '../backup/backup_service.dart' show backupReminderDue;
import '../core/rupiah.dart';
import 'product_service.dart' show PriceSuggestion;
import 'add_product_screen.dart' show productUnits;
import 'name_field.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  Timer? _debounce;
  String _query = '';

  /// null = all, uncategorizedFilter = no category, otherwise a category id.
  String? _categoryId;
  String? _categoryName;

  /// Mass edit: pick products, then change their unit or category together.
  bool _selecting = false;
  final _selected = <String>{};

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Waits for a short pause in typing before querying, so fast typing
  /// doesn't run a database query per keystroke.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _startSelecting([String? firstId]) => setState(() {
    _selecting = true;
    if (firstId != null) _selected.add(firstId);
  });

  void _stopSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  /// Opens Kelola kategori. If the category being filtered on was deleted
  /// there, the filter is dropped so the list is not left empty.
  Future<void> _manageCategories() async {
    await context.push('/kategori');
    if (!mounted) return;
    final id = _categoryId;
    if (id == null || id == uncategorizedFilter) return;
    final counts = await ref.read(categoryCountsProvider.future);
    if (!mounted) return;
    if (!counts.categories.any((c) => c.id == id)) {
      setState(() {
        _categoryId = null;
        _categoryName = null;
      });
    }
  }

  Future<void> _massEdit() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Ubah ${_selected.length} produk')),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Ubah satuan'),
              onTap: () => Navigator.pop(context, 'unit'),
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Ubah kategori'),
              onTap: () => Navigator.pop(context, 'category'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    final service = ref.read(productServiceProvider);
    final ids = _selected.toList();
    int? changed;
    if (action == 'unit') {
      final unit = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Satuan baru'),
          children: [
            for (final u in productUnits)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, u),
                child: Text(u),
              ),
          ],
        ),
      );
      if (unit == null) return;
      changed = await service.setUnitForMany(ids, unit);
    } else {
      final names = await service.categoryNames();
      if (!mounted) return;
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _CategoryDialog(options: names),
      );
      if (name == null) return;
      changed = await service.setCategoryForMany(ids, name);
    }
    if (!mounted) return;
    _stopSelecting();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed == 0 ? 'Tidak ada yang berubah' : '$changed produk diubah',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(
      productsProvider((query: _query, categoryId: _categoryId)),
    );
    final display = ref.watch(displayPrefsProvider);
    // Retail price suggestions waiting for a yes or no. The bell counts only
    // the urgent ones (selling below the margin limit now).
    final suggestions =
        ref.watch(priceSuggestionsProvider).value ?? const <PriceSuggestion>[];
    final suggested = {for (final s in suggestions) s.productId};
    final urgent = suggestions.where((s) => s.belowMargin).length;
    final warned = display.showMarginWarning
        ? ref.watch(marginWarningsProvider).value ?? const <String>{}
        : const <String>{};
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopSelecting();
      },
      child: Scaffold(
        drawer: _selecting
            ? null
            : _CategoryDrawer(
                selectedId: _categoryId,
                onSelected: (id, name) => setState(() {
                  _categoryId = id;
                  _categoryName = name;
                }),
                onManage: _manageCategories,
              ),
        appBar: _selecting
            ? AppBar(
                leading: IconButton(
                  tooltip: 'Batal pilih',
                  icon: const Icon(Icons.close),
                  onPressed: _stopSelecting,
                ),
                title: Text('${_selected.length} dipilih'),
                actions: [
                  // A word, not an icon: "select all" icons are easy to misread.
                  TextButton(
                    onPressed: () => setState(
                      () => _selected.addAll(
                        (products.value ?? const []).map((p) => p.id!),
                      ),
                    ),
                    child: const Text('Pilih semua'),
                  ),
                  IconButton(
                    tooltip: 'Ubah yang dipilih',
                    icon: const Icon(Icons.edit_note),
                    onPressed: _selected.isEmpty ? null : _massEdit,
                  ),
                ],
              )
            : AppBar(
                title: const Text('Harga Toko'),
                actions: [
                  if (suggestions.isNotEmpty)
                    IconButton(
                      tooltip: 'Saran harga',
                      icon: Badge(
                        isLabelVisible: urgent > 0,
                        label: Text('$urgent'),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      onPressed: () => context.push('/saran-harga'),
                    ),
                  IconButton(
                    tooltip: 'Ubah massal',
                    icon: const Icon(Icons.checklist),
                    onPressed: _startSelecting,
                  ),
                  IconButton(
                    tooltip: 'Pengaturan',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push('/pengaturan'),
                  ),
                ],
              ),
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push('/tambah'),
                icon: const Icon(Icons.add),
                label: const Text('Tambah manual'),
              ),
        body: Column(
          children: [
            const _BackupBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                hintText: 'Cari nama atau model',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: _onSearchChanged,
              ),
            ),
            if (_categoryId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InputChip(
                    avatar: const Icon(Icons.label_outline, size: 18),
                    label: Text(_categoryName ?? 'Kategori'),
                    onDeleted: () => setState(() {
                      _categoryId = null;
                      _categoryName = null;
                    }),
                  ),
                ),
              ),
            Expanded(
              child: products.when(
                // Keep showing the previous list while a new query loads.
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        _query.trim().isEmpty && _categoryId == null
                            ? 'Belum ada produk'
                            : 'Tidak ada produk yang cocok',
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final subtitle = [
                        if (p.model != null) p.model!,
                        p.unit,
                      ].join(' · ');
                      return ListTile(
                        leading: _selecting
                            ? Checkbox(
                                value: _selected.contains(p.id),
                                onChanged: (_) => _toggle(p.id!),
                              )
                            : null,
                        title: Text(p.name),
                        subtitle: Text(subtitle),
                        selected: _selected.contains(p.id),
                        onTap: _selecting
                            ? () => _toggle(p.id!)
                            : () => context.push('/produk/${p.id}'),
                        onLongPress: _selecting
                            ? null
                            : () => _startSelecting(p.id),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (suggested.contains(p.id))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.price_change_outlined,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  semanticLabel: 'Ada saran harga',
                                ),
                              ),
                            if (warned.contains(p.id))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.error,
                                  semanticLabel: 'Margin di bawah batas',
                                ),
                              ),
                            if (display.showOverrideIcon &&
                                p.retailIsOverride == 1)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.edit, size: 16),
                              ),
                            Text(
                              p.retailPrice == null
                                  ? '-'
                                  : formatRupiah(p.retailPrice!),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick or type a category for the selected products. Returns the name,
/// an empty string to remove the category, or null if cancelled.
class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.options});

  final List<String> options;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kategori baru'),
      content: NameField(
        label: 'Kategori',
        options: widget.options,
        onChanged: (v) => _name = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Tanpa kategori'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.trim().isNotEmpty) Navigator.pop(context, _name.trim());
          },
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}

/// Hamburger menu: group the list by category.
class _CategoryDrawer extends ConsumerWidget {
  const _CategoryDrawer({
    required this.selectedId,
    required this.onSelected,
    required this.onManage,
  });

  final String? selectedId;
  final void Function(String? id, String? name) onSelected;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(categoryCountsProvider).value;

    void pick(String? id, String? name) {
      onSelected(id, name);
      Navigator.pop(context); // close the drawer
    }

    return Drawer(
      child: SafeArea(
        child: counts == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Kategori',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.apps),
                    title: const Text('Semua produk'),
                    trailing: Text('${counts.total}'),
                    selected: selectedId == null,
                    onTap: () => pick(null, null),
                  ),
                  for (final c in counts.categories)
                    ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(c.name),
                      trailing: Text('${c.count}'),
                      selected: selectedId == c.id,
                      onTap: () => pick(c.id, c.name),
                    ),
                  if (counts.uncategorized > 0)
                    ListTile(
                      leading: const Icon(Icons.label_off_outlined),
                      title: const Text('Tanpa kategori'),
                      trailing: Text('${counts.uncategorized}'),
                      selected: selectedId == uncategorizedFilter,
                      onTap: () => pick(uncategorizedFilter, 'Tanpa kategori'),
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Kelola kategori'),
                    onTap: () {
                      Navigator.pop(context); // close the drawer
                      onManage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Kelola supplier'),
                    onTap: () {
                      Navigator.pop(context); // close the drawer
                      context.push('/supplier');
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

/// "Cadangan terakhir N hari lalu": shown when a backup is overdue.
class _BackupBanner extends ConsumerWidget {
  const _BackupBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backupStatusProvider).value;
    final enabled = ref.watch(displayPrefsProvider).backupReminder;
    final now = DateTime.now();
    if (status == null ||
        !backupReminderDue(
          lastBackup: status.lastBackup,
          productCount: status.productCount,
          now: now,
          enabled: enabled,
        )) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final last = status.lastBackup;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  last == null
                      ? 'Belum pernah dicadangkan'
                      : 'Cadangan terakhir ${daysAgo(last, now)}',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
                Text(
                  'Data supplier hanya ada di HP ini.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/pengaturan/cadangan'),
            child: const Text('Cadangkan'),
          ),
        ],
      ),
    );
  }
}
