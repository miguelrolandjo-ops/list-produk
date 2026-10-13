import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/display_prefs.dart';
import '../core/providers.dart';
import '../backup/backup_screen.dart' show daysAgo;
import '../backup/backup_service.dart' show backupReminderDue;
import '../core/rupiah.dart';

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

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(
      productsProvider((query: _query, categoryId: _categoryId)),
    );
    final display = ref.watch(displayPrefsProvider);
    final warned = display.showMarginWarning
        ? ref.watch(marginWarningsProvider).value ?? const <String>{}
        : const <String>{};
    return Scaffold(
      drawer: _CategoryDrawer(
        selectedId: _categoryId,
        onSelected: (id, name) => setState(() {
          _categoryId = id;
          _categoryName = name;
        }),
      ),
      appBar: AppBar(
        title: const Text('Harga Toko'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/pengaturan'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                      title: Text(p.name),
                      subtitle: Text(subtitle),
                      onTap: () => context.push('/produk/${p.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
    );
  }
}

/// Hamburger menu: group the list by category.
class _CategoryDrawer extends ConsumerWidget {
  const _CategoryDrawer({required this.selectedId, required this.onSelected});

  final String? selectedId;
  final void Function(String? id, String? name) onSelected;

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
