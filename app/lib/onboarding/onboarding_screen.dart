import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_mode.dart';
import '../core/providers.dart';
import '../core/ui.dart';
import '../products/category_emoji.dart';
import 'shop_profile.dart';
import 'shop_types.dart';

/// Setting up a new shop: what it sells, which categories to start with (each
/// with an emoji), and its name. Also reachable later from Settings
/// ([fromSettings]) to add another kind of shop and its categories; then the
/// name step is skipped and nothing about the existing data changes.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _StarterCategory {
  _StarterCategory(this.name, this.emoji, {this.selected = true});
  final String name;
  String emoji;
  bool selected;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _types = <String>[];
  final _categories = <_StarterCategory>[];
  final _newCategory = TextEditingController();
  String _newEmoji = fallbackCategoryEmoji;
  final _shopName = TextEditingController();
  bool _saving = false;

  int get _stepCount => widget.fromSettings ? 2 : 3;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(shopProfileProvider);
    _types.addAll(profile.typeIds);
    _shopName.text = profile.name ?? '';
  }

  @override
  void dispose() {
    _newCategory.dispose();
    _shopName.dispose();
    super.dispose();
  }

  void _toggleType(String id) => setState(() {
    if (!_types.remove(id)) _types.add(id);
  });

  /// Step 1 → 2: rebuild the starter list from the chosen types, keeping what
  /// the owner already changed or added.
  Future<void> _toCategories() async {
    await ref.read(shopProfileProvider.notifier).setTypes(_types);
    final before = {for (final c in _categories) c.name.toLowerCase(): c};
    final added = _categories.where((c) => !_isStarter(c.name)).toList();
    final existing = await ref.read(productServiceProvider).categoryNames();
    final have = {for (final n in existing) n.toLowerCase()};
    setState(() {
      _categories
        ..clear()
        ..addAll([
          for (final (name, emoji) in starterCategories(_types))
            if (!have.contains(name.toLowerCase()))
              before[name.toLowerCase()] ?? _StarterCategory(name, emoji),
          ...added,
        ]);
      _step = 1;
    });
  }

  bool _isStarter(String name) => starterCategories(
    _types,
  ).any((c) => c.$1.toLowerCase() == name.toLowerCase());

  void _addCategory() {
    final name = _newCategory.text.trim();
    if (name.isEmpty) return;
    if (_categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" sudah ada di daftar')),
      );
      return;
    }
    setState(() {
      _categories.add(_StarterCategory(name, _newEmoji));
      _newCategory.clear();
      _newEmoji = fallbackCategoryEmoji;
    });
  }

  Future<void> _pickEmoji({
    required String title,
    required String current,
    required void Function(String) onPicked,
  }) async {
    final e = await showDialog<String>(
      context: context,
      builder: (_) => EmojiPickerDialog(
        title: title,
        current: current,
        allowAutomatic: false,
      ),
    );
    if (e != null && e.isNotEmpty) setState(() => onPicked(e));
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final profile = ref.read(shopProfileProvider.notifier);
    await profile.setTypes(_types);
    if (!widget.fromSettings) await profile.setName(_shopName.text);
    final created = await createStarterCategories(ref.read(ownerDbProvider), [
      for (final c in _categories)
        if (c.selected) (c.name, c.emoji),
    ]);
    if (!mounted) return;
    if (widget.fromSettings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created == 0
                ? 'Jenis toko disimpan'
                : '$created kategori ditambahkan',
          ),
        ),
      );
      context.pop();
      return;
    }
    await ref.read(appModeProvider.notifier).set(AppMode.owner);
    if (mounted) context.go('/');
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final (title, subtitle, body) = switch (_step) {
      0 => (
        'Toko Anda menjual apa?',
        'Pilih satu atau lebih. Ini menentukan kategori awal dan ikon '
            'yang ditawarkan.',
        _typeGrid(context),
      ),
      1 => (
        'Kategori awal',
        'Hapus centang yang tidak perlu, ketuk ikon untuk menggantinya, '
            'atau tambah kategori sendiri.',
        _categoryList(context),
      ),
      _ => ('Hampir selesai', null, _finalStep(context)),
    };
    final canContinue = switch (_step) {
      0 => _types.isNotEmpty,
      _ => !_saving,
    };
    final isLast = _step == _stepCount - 1;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          title: Text(widget.fromSettings ? 'Jenis toko' : 'Buat toko baru'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 24,
                      4,
                      compact ? 16 : 24,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langkah ${_step + 1} dari $_stepCount',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_step + 1) / _stepCount,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                        const SizedBox(height: 20),
                        PageHeader(title: title, subtitle: subtitle),
                      ],
                    ),
                  ),
                  Expanded(child: body),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 24,
                      12,
                      compact ? 16 : 24,
                      16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        if (_step == 0 && _types.isNotEmpty)
                          Expanded(
                            child: Text(
                              '${_types.length} dipilih',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          )
                        else if (_step == 1)
                          Expanded(
                            child: Text(
                              '${_categories.where((c) => c.selected).length} '
                              'kategori akan dibuat',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          )
                        else
                          const Spacer(),
                        FilledButton(
                          onPressed: !canContinue
                              ? null
                              : switch (_step) {
                                  0 => _toCategories,
                                  _ when isLast => _finish,
                                  _ => () => setState(() => _step++),
                                },
                          child: Text(
                            isLast
                                ? (widget.fromSettings
                                      ? 'Simpan'
                                      : 'Mulai pakai')
                                : 'Lanjut',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeGrid(BuildContext context) {
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final text = Theme.of(context).textTheme;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        0,
        compact ? 16 : 24,
        16,
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 128 * (MediaQuery.textScalerOf(context).scale(14) / 14),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: shopTypes.length,
      itemBuilder: (context, i) {
        final t = shopTypes[i];
        final selected = _types.contains(t.id);
        return Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: selected ? AppColors.tint : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: selected ? AppColors.navy : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _toggleType(t.id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 30)),
                        const Spacer(),
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected ? AppColors.navy : AppColors.border,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      t.name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      t.example,
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryList(BuildContext context) {
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final pad = compact ? 16.0 : 24.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
      children: [
        if (_categories.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Belum ada kategori. Tambahkan di bawah, atau lanjut saja: '
              'kategori juga bisa dibuat saat menambah produk.',
            ),
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, c) in _categories.indexed) ...[
                if (i > 0) const Divider(height: 1),
                CheckboxListTile(
                  value: c.selected,
                  onChanged: (v) => setState(() => c.selected = v ?? false),
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: _EmojiChip(
                    emoji: c.emoji,
                    label: 'Ganti ikon ${c.name}',
                    onTap: () => _pickEmoji(
                      title: 'Ikon "${c.name}"',
                      current: c.emoji,
                      onPicked: (e) => c.emoji = e,
                    ),
                  ),
                  title: Text(c.name),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Tambah kategori', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _EmojiChip(
              emoji: _newEmoji,
              label: 'Pilih ikon kategori baru',
              onTap: () => _pickEmoji(
                title: 'Ikon kategori baru',
                current: _newEmoji,
                onPicked: (e) => _newEmoji = e,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _newCategory,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nama kategori, mis. Wajan anti lengket',
                  isDense: true,
                ),
                onSubmitted: (_) => _addCategory(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Tambah ke daftar',
              icon: const Icon(Icons.add),
              onPressed: _addCategory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _finalStep(BuildContext context) {
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final pad = compact ? 16.0 : 24.0;
    final text = Theme.of(context).textTheme;
    Widget tip(String emoji, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                Text(body, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
      children: [
        TextField(
          controller: _shopName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama toko (boleh nanti)',
            hintText: 'mis. Toko Berkah',
          ),
        ),
        const SizedBox(height: 24),
        tip(
          '➕',
          'Tambah produk dengan harga supplier',
          'Harga jual dihitung otomatis dari aturan harga. Bisa diubah kapan saja.',
        ),
        tip(
          '🔒',
          'Data supplier tetap di HP ini',
          'Harga beli dan nama supplier tidak pernah dikirim ke karyawan.',
        ),
        tip(
          '👥',
          'Bagikan harga ke karyawan',
          'Nanti, lewat menu Tim: karyawan hanya melihat nama dan harga jual.',
        ),
        tip(
          '💾',
          'Cadangkan secara rutin',
          'Simpan cadangan ke Google Drive supaya data aman jika HP hilang.',
        ),
      ],
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: AppColors.tint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
      ),
    ),
  );
}
