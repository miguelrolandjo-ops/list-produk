import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/server_providers.dart';
import '../core/ui.dart';
import 'category_emoji.dart';
import 'product_list_screen.dart' show BackupBanner;

/// The owner's front screen: one card per category, products inside.
class CategoryHomeScreen extends ConsumerWidget {
  const CategoryHomeScreen({super.key});

  static String pathFor(CategoryOverview c) => c.id == null
      ? '/produk'
      : '/kategori/${Uri.encodeComponent(c.id!)}'
            '?nama=${Uri.encodeQueryComponent(c.name)}';

  Future<void> _changeEmoji(
    BuildContext context,
    WidgetRef ref,
    CategoryOverview c,
  ) async {
    final picked = await pickCategoryEmoji(
      context,
      categoryName: c.name,
      current: c.emoji,
    );
    if (picked == null) return;
    await setCategoryEmoji(
      ref.read(ownerDbProvider),
      c.id!,
      picked.isEmpty ? null : picked,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(catalogOverviewProvider);
    final suggestions = ref.watch(priceSuggestionsProvider).value ?? const [];
    final urgent = suggestions.where((s) => s.belowMargin).length;
    final unsent = ref.watch(unsentCountProvider).value;
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final pad = compact ? 16.0 : 28.0;

    return Scaffold(
      appBar: compact
          ? AppBar(
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
              ],
            )
          : null,
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/tambah'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah produk'),
            )
          : null,
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (data) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, compact ? 4 : 28, pad, 0),
              sliver: SliverList.list(
                children: [
                  if (!compact) ...[
                    Text(
                      'Beranda / Kategori',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  PageHeader(
                    title: 'Kategori produk',
                    subtitle: 'Pilih kategori untuk melihat produk dan '
                        'harganya.',
                    actions: compact
                        ? const []
                        : [
                            OutlinedButton.icon(
                              onPressed: () => context.push('/kategori'),
                              icon: const Icon(Icons.label_outline),
                              label: const Text('Kelola kategori'),
                            ),
                            FilledButton.icon(
                              onPressed: () => context.push('/tambah'),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah produk'),
                            ),
                          ],
                  ),
                  const BackupBanner(margin: EdgeInsets.only(top: 16)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Searching always covers every product, so it opens the
                  // full list with the cursor in the search field.
                  _SearchLauncher(
                    onTap: () => context.push('/produk?cari=1'),
                  ),
                  const SizedBox(height: 14),
                  SummaryLine(
                    items: [
                      ('Kategori', '${data.categoryCount}', null),
                      ('Produk', '${data.all.productCount}', null),
                      (
                        'Margin rendah',
                        '${data.all.belowMargin}',
                        data.all.belowMargin > 0 ? AppColors.warn : null,
                      ),
                      if (unsent != null)
                        (
                          'Belum terkirim',
                          '$unsent',
                          unsent > 0 ? AppColors.attention : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (data.all.productCount == 0)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(onAdd: () => context.push('/tambah')),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, compact ? 96 : 32),
                sliver: categoryGrid(context, [
                  for (final c in [data.all, ...data.categories])
                    CategoryCard(
                      emoji: c.emoji,
                      name: c.name,
                      caption: '${c.productCount} produk',
                      badge: _badgeFor(c),
                      rows: [
                        (
                          'Margin rendah',
                          '${c.belowMargin}',
                          c.belowMargin > 0 ? AppColors.warn : null,
                        ),
                        (
                          'Tanpa harga',
                          '${c.unpriced}',
                          c.unpriced > 0 ? AppColors.attention : null,
                        ),
                      ],
                      onOpen: () => context.push(pathFor(c)),
                      onEmojiTap:
                          c.id == null || c.id == uncategorizedFilter
                          ? null
                          : () => _changeEmoji(context, ref, c),
                    ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  static StatusBadge _badgeFor(CategoryOverview c) {
    if (c.productCount == 0) {
      return const StatusBadge('Kosong', color: AppColors.neutral);
    }
    if (c.belowMargin > 0) {
      return const StatusBadge('Margin rendah', color: AppColors.warn);
    }
    if (c.unpriced > 0) {
      return const StatusBadge('Ada tanpa harga', color: AppColors.attention);
    }
    return const StatusBadge('Aman', color: AppColors.ok);
  }
}

/// Looks like a search field; opens the full product list to type in.
class _SearchLauncher extends StatelessWidget {
  const _SearchLauncher({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Cari semua produk',
    excludeSemantics: true,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const SizedBox(
          height: 52,
          child: Row(
            children: [
              SizedBox(width: 16),
              Icon(Icons.search, color: AppColors.muted),
              SizedBox(width: 12),
              Text('Cari semua produk',
                  style: TextStyle(color: AppColors.muted, fontSize: 16)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏪', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Belum ada produk',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Tambahkan produk pertama. Kategori muncul di sini otomatis.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah produk'),
          ),
        ],
      ),
    ),
  );
}
