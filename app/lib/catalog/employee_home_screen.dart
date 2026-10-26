import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_mode.dart';
import '../core/rupiah.dart';
import '../core/server_providers.dart';
import '../core/time_ago.dart';
import '../core/ui.dart';
import '../products/category_emoji.dart';
import 'employee_catalog_repository.dart';
import 'employee_sync_service.dart';

/// The whole local catalog, for the category cards.
final _allEntriesProvider = StreamProvider<List<CatalogEntry>>(
  (ref) => ref.watch(employeeCatalogRepositoryProvider).watchSearch(''),
);

/// "Diperbarui 5 menit lalu".
String freshness(DateTime then, DateTime now) {
  final d = now.difference(then);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
  if (d.inHours < 24 && now.day == then.day) return '${d.inHours} jam lalu';
  return timeAgo(then, now);
}

/// Shared by both employee screens: syncing, and leaving when revoked.
mixin _EmployeeSync<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool syncing = false;
  bool offline = false;

  Future<void> sync({bool quiet = true}) async {
    if (syncing) return;
    setState(() => syncing = true);
    final outcome = await ref.read(employeeSyncServiceProvider).sync();
    if (!mounted) return;
    setState(() {
      syncing = false;
      offline = outcome == SyncOutcome.offline;
    });
    switch (outcome) {
      case SyncOutcome.revoked || SyncOutcome.notJoined:
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Akses ke toko berakhir'),
            content: const Text(
              'Pemilik toko telah mencabut akses HP ini, jadi katalognya '
              'dihapus. Minta kode undangan baru untuk bergabung lagi.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        await ref.read(appModeProvider.notifier).set(null);
        if (mounted) context.go('/mulai');
      case SyncOutcome.failed when !quiet:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum bisa memperbarui. Coba lagi.')),
        );
      case SyncOutcome.offline when !quiet:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada sinyal. Memakai data terakhir.'),
          ),
        );
      default:
        break;
    }
  }
}

/// Employee front screen: categories, products inside. Read-only, works
/// offline with the last synced catalog.
class EmployeeHomeScreen extends ConsumerStatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  ConsumerState<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen>
    with WidgetsBindingObserver, _EmployeeSync<EmployeeHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sync();
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari toko?'),
        content: const Text(
          'Katalog di HP ini dihapus. Untuk kembali, perlu kode undangan baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(employeeSyncServiceProvider).leave();
    await ref.read(appModeProvider.notifier).set(null);
    if (mounted) context.go('/mulai');
  }

  static String _listPath({String? category, bool search = false}) {
    final params = <String, String>{
      if (category != null) 'kategori': category,
      if (search) 'cari': '1',
    };
    return Uri(path: '/karyawan/daftar', queryParameters: params.isEmpty ? null : params)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(employeeSessionStoreProvider).read();
    final entries = ref.watch(_allEntriesProvider);
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final pad = compact ? 16.0 : 28.0;
    final now = DateTime.now();
    final synced = session?.syncedAt;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.storeName ?? 'Harga Toko'),
        actions: [
          IconButton(
            tooltip: 'Perbarui',
            onPressed: syncing ? null : () => sync(quiet: false),
            icon: syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (_) => _leave(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'leave', child: Text('Keluar dari toko')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => sync(quiet: false),
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
          data: (all) {
            final groups = _group(all);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 4, pad, 16),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Icon(
                            offline ? Icons.cloud_off : Icons.cloud_done,
                            size: 18,
                            color: offline ? AppColors.muted : AppColors.ok,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              synced == null
                                  ? 'Belum pernah diperbarui'
                                  : '${offline ? 'Offline · ' : ''}'
                                        'Diperbarui ${freshness(synced, now)}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SearchLauncher(
                        onTap: () => context.push(_listPath(search: true)),
                      ),
                      const SizedBox(height: 14),
                      SummaryLine(
                        items: [
                          (
                            'Kategori',
                            '${groups.where((g) => g.category != null && g.category != noCategoryFilter).length}',
                            null,
                          ),
                          ('Produk', '${all.length}', null),
                        ],
                      ),
                    ],
                  ),
                ),
                if (all.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          syncing
                              ? 'Mengambil katalog...'
                              : 'Katalog masih kosong. Tarik ke bawah untuk '
                                    'memperbarui.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 32),
                    sliver: categoryGrid(context, [
                      for (final g in groups)
                        CategoryCard(
                          emoji: g.emoji,
                          name: g.name,
                          caption: '${g.entries.length} produk',
                          rows: [
                            ('Termurah', g.cheapest, null),
                            ('Termahal', g.priciest, null),
                          ],
                          onOpen: () =>
                              context.push(_listPath(category: g.category)),
                        ),
                    ]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static List<_Group> _group(List<CatalogEntry> all) {
    final byCategory = <String, List<CatalogEntry>>{};
    final none = <CatalogEntry>[];
    for (final e in all) {
      if (e.category == null) {
        none.add(e);
      } else {
        byCategory.putIfAbsent(e.category!, () => []).add(e);
      }
    }
    final names = byCategory.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [
      _Group(null, 'Semua produk', allProductsEmoji, all),
      for (final n in names) _Group(n, n, categoryEmoji(n), byCategory[n]!),
      if (none.isNotEmpty)
        _Group(noCategoryFilter, 'Tanpa kategori', noCategoryEmoji, none),
    ];
  }
}

class _Group {
  _Group(this.category, this.name, this.emoji, this.entries);

  /// Filter value: null = all, [noCategoryFilter], or the category name.
  final String? category;
  final String name;
  final String emoji;
  final List<CatalogEntry> entries;

  Iterable<int> get _prices => entries
      .map((e) => e.retailPrice)
      .whereType<int>();

  String get cheapest {
    final p = _prices;
    return p.isEmpty ? '-' : formatRupiah(p.reduce((a, b) => a < b ? a : b));
  }

  String get priciest {
    final p = _prices;
    return p.isEmpty ? '-' : formatRupiah(p.reduce((a, b) => a > b ? a : b));
  }
}

class _SearchLauncher extends StatelessWidget {
  const _SearchLauncher({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Cari produk',
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
              Text(
                'Cari nama atau model',
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Products of one category (or all), with offline search.
class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({
    super.key,
    this.category,
    this.autofocusSearch = false,
  });

  /// null = all products, [noCategoryFilter] = without a category.
  final String? category;
  final bool autofocusSearch;

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen>
    with _EmployeeSync<EmployeeListScreen> {
  Timer? _debounce;
  String _query = '';
  late Stream<List<CatalogEntry>> _results;

  @override
  void initState() {
    super.initState();
    _results = _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Stream<List<CatalogEntry>> _search() => ref
      .read(employeeCatalogRepositoryProvider)
      .watchSearch(_query, category: widget.category);

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _query = v;
        _results = _search();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.category) {
      null => '$allProductsEmoji  Semua produk',
      noCategoryFilter => '$noCategoryEmoji  Tanpa kategori',
      final c => '${categoryEmoji(c)}  $c',
    };
    final expanded = screenSizeOf(context) == ScreenSize.expanded;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SearchBar(
              hintText: 'Cari nama atau model',
              leading: const Icon(Icons.search),
              autoFocus: widget.autofocusSearch,
              onChanged: _onChanged,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => sync(quiet: false),
              child: StreamBuilder<List<CatalogEntry>>(
                stream: _results,
                builder: (context, snap) {
                  final items = snap.data;
                  if (items == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _query.trim().isEmpty
                                ? 'Belum ada produk di sini'
                                : 'Tidak ada produk yang cocok dengan '
                                      '"${_query.trim()}"',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }
                  if (expanded) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            mainAxisExtent: 132,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _EntryCard(entry: items[i]),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _EntryCard(entry: items[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});
  final CatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detail = [
      if (entry.model != null) entry.model!,
      entry.unit,
    ].join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                categoryEmoji(entry.category),
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    detail,
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              entry.retailPrice == null ? '-' : formatRupiah(entry.retailPrice!),
              style: text.titleLarge?.copyWith(color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}
