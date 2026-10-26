import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/ui.dart';
import '../onboarding/shop_profile.dart' show createStarterCategories;
import 'category_emoji.dart';

/// "Kelola kategori": see every category with its product count, and delete
/// the ones that are no longer needed. Reached from the list's side menu and
/// from Settings.
class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CategoryCount category,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(productServiceProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus kategori "${category.name}"?'),
        content: Text(
          category.count == 0
              ? 'Kategori ini tidak dipakai produk mana pun.'
              : '${category.count} produk akan menjadi tanpa kategori. '
                    'Produknya tidak dihapus.',
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
    await service.deleteCategory(category.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Kategori "${category.name}" dihapus')),
      );
  }

  Future<void> _changeEmoji(
    BuildContext context,
    WidgetRef ref,
    CategoryCount c,
    String? current,
  ) async {
    final e = await pickCategoryEmoji(
      context,
      categoryName: c.name,
      current: categoryEmoji(c.name, picked: current),
    );
    if (e == null) return;
    await setCategoryEmoji(ref.read(ownerDbProvider), c.id, e.isEmpty ? null : e);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _NewCategoryDialog(),
    );
    if (result == null) return;
    final created = await createStarterCategories(
      ref.read(ownerDbProvider),
      [result],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created == 0
              ? 'Kategori "${result.$1}" sudah ada'
              : 'Kategori "${result.$1}" ditambahkan',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(categoryCountsProvider);
    final picked =
        ref.watch(pickedCategoryEmojiProvider).value ??
        const <String, String?>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola kategori')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kategori baru'),
      ),
      body: counts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (data) {
          if (data.categories.isEmpty) {
            return const Center(child: Text('Belum ada kategori'));
          }
          return ListView.separated(
            itemCount: data.categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = data.categories[i];
              return ListTile(
                leading: Semantics(
                  button: true,
                  label: 'Ubah ikon ${c.name}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _changeEmoji(context, ref, c, picked[c.id]),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        categoryEmoji(c.name, picked: picked[c.id]),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
                title: Text(c.name),
                subtitle: Text('${c.count} produk'),
                trailing: IconButton(
                  tooltip: 'Hapus kategori ${c.name}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Name and emoji for a new category. Returns (name, emoji) or null.
class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _name = TextEditingController();
  String? _emoji;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name, _emoji ?? categoryEmoji(name)));
  }

  @override
  Widget build(BuildContext context) {
    final shown = _emoji ?? categoryEmoji(_name.text);
    return AlertDialog(
      title: const Text('Kategori baru'),
      content: Row(
        children: [
          Semantics(
            button: true,
            label: 'Pilih ikon',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final e = await pickCategoryEmoji(
                  context,
                  categoryName: _name.text.trim().isEmpty
                      ? 'kategori baru'
                      : _name.text.trim(),
                  current: shown,
                );
                if (e == null) return;
                setState(() => _emoji = e.isEmpty ? null : e);
              },
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(shown, style: const TextStyle(fontSize: 26)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nama kategori'),
              // The automatic icon follows the name until one is picked.
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Tambah')),
      ],
    );
  }
}
