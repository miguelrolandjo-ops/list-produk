import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/server_providers.dart';
import '../core/ui.dart';
import '../products/product_list_screen.dart' show BackupBanner;
import '../team/owner_account_service.dart';
import 'inbox_providers.dart';
import 'po_intake_service.dart';

/// Photos are shrunk to this long side before they are kept or uploaded:
/// enough to read a nota, and fast on a weak signal.
const poMaxSide = 1600.0;
const poJpegQuality = 82;

/// "Inbox PO" (mockup screen B): add PO photos and follow them until they are
/// reviewed and saved.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _picker = ImagePicker();
  bool _adding = false;

  Future<void> _add(List<String> paths, PoSource source) async {
    if (paths.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding = true);
    try {
      await ref.read(poIntakeServiceProvider).create(paths, source);
      ref.read(inboxRunnerProvider).kick();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            paths.length == 1
                ? 'Foto PO ditambahkan'
                : 'PO dengan ${paths.length} halaman ditambahkan',
          ),
        ),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan foto: $e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  /// Camera: one photo per page, then "Foto halaman berikutnya" or "Selesai".
  Future<void> _camera() async {
    final pages = <String>[];
    while (mounted) {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: poMaxSide,
        maxHeight: poMaxSide,
        imageQuality: poJpegQuality,
      );
      if (shot == null) break;
      pages.add(shot.path);
      if (!mounted) return;
      final more = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Halaman ${pages.length} diambil'),
          content: const Text('Nota ini punya halaman lain?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Selesai'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Foto halaman berikutnya'),
            ),
          ],
        ),
      );
      if (more != true) break;
    }
    await _add(pages, PoSource.camera);
  }

  /// Gallery: several photos = several pages of one PO, in the order picked.
  Future<void> _gallery() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: poMaxSide,
      maxHeight: poMaxSide,
      imageQuality: poJpegQuality,
    );
    await _add([for (final x in picked) x.path], PoSource.gallery);
  }

  Future<void> _actions(InboxItem item) async {
    final canRetry = item.status == 'failed';
    final canDelete = item.status != 'saved' && item.status != 'uploading';
    if (!canRetry && !canDelete) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRetry)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Coba baca lagi'),
                onTap: () => Navigator.pop(context, 'retry'),
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.warn),
                title: const Text('Hapus PO ini'),
                subtitle: const Text('Fotonya juga dihapus dari HP ini'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (action == 'retry') {
      await ref.read(poSyncServiceProvider).retry(item.id);
      ref.read(inboxRunnerProvider).kick();
    } else if (action == 'delete') {
      try {
        await ref.read(poIntakeServiceProvider).delete(item.id);
        messenger.showSnackBar(const SnackBar(content: Text('PO dihapus')));
      } on StateError {
        messenger.showSnackBar(
          const SnackBar(content: Text('PO ini sedang diunggah. Coba sebentar lagi.')),
        );
      }
    }
  }

  void _open(InboxItem item) {
    switch (item.status) {
      case 'needs_review':
        context.push('/po/${item.id}/review');
      case 'saved':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PO ini sudah tersimpan ke produk')),
        );
      default:
        _actions(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inboxItemsProvider);
    final link = ref.watch(ownerLinkProvider).value;
    final unsent = ref.watch(unsentCountProvider).value;
    final progress = ref.watch(poSyncServiceProvider).uploadProgress;
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final pad = compact ? 16.0 : 28.0;
    final linked = link?.state == OwnerLinkState.linked;

    return Scaffold(
      appBar: compact
          ? AppBar(
              title: const Text('Inbox PO'),
              actions: [
                if ((unsent ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StatusBadge(
                      '$unsent belum terkirim',
                      color: AppColors.attention,
                    ),
                  ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.read(inboxRunnerProvider).kick(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, compact ? 4 : 28, pad, 12),
              sliver: SliverList.list(
                children: [
                  if (!compact)
                    PageHeader(
                      title: 'Inbox PO',
                      subtitle: 'Foto nota supplier dibaca otomatis, lalu Anda '
                          'periksa sebelum disimpan.',
                      actions: [
                        if ((unsent ?? 0) > 0)
                          StatusBadge(
                            '$unsent belum terkirim',
                            color: AppColors.attention,
                          ),
                      ],
                    ),
                  const BackupBanner(margin: EdgeInsets.only(top: 8)),
                  if (link != null && !linked)
                    _NotLinkedBanner(
                      notConfigured:
                          link.state == OwnerLinkState.notConfigured,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AddButton(
                          icon: Icons.photo_camera_outlined,
                          label: 'Kamera',
                          onTap: _adding ? null : _camera,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AddButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Galeri',
                          onTap: _adding ? null : _gallery,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AddButton(
                          icon: Icons.edit_note,
                          label: 'Tambah manual',
                          onTap: () => context.push('/tambah'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: dari WhatsApp, tekan lama foto nota > Bagikan > '
                    'Harga Toko.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            ...items.when(
              loading: () => [
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverToBoxAdapter(child: Center(child: Text('$e'))),
              ],
              data: (list) => list.isEmpty
                  ? [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _Empty(),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(pad, 0, pad, 32),
                        sliver: ValueListenableBuilder<Map<String, int>>(
                          valueListenable: progress,
                          builder: (context, uploaded, _) => SliverList.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) => _PoCard(
                              item: list[i],
                              uploaded: uploaded[list[i].id],
                              linked: linked,
                              onTap: () => _open(list[i]),
                              onMore: () => _actions(list[i]),
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotLinkedBanner extends StatelessWidget {
  const _NotLinkedBanner({required this.notConfigured});
  final bool notConfigured;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    decoration: BoxDecoration(
      color: AppColors.tint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: AppColors.navy),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            notConfigured
                ? 'Aplikasi ini belum terhubung ke server, jadi foto PO belum '
                      'bisa dibaca. Foto tetap disimpan.'
                : 'Foto PO dibaca di server. Masuk ke akun toko dulu; foto '
                      'menunggu dan dikirim setelah itu.',
          ),
        ),
        if (!notConfigured)
          TextButton(
            onPressed: () => context.push('/pengaturan/akun'),
            child: const Text('Masuk'),
          ),
      ],
    ),
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: onTap == null ? AppColors.muted : AppColors.navy),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PoCard extends StatelessWidget {
  const _PoCard({
    required this.item,
    required this.uploaded,
    required this.linked,
    required this.onTap,
    required this.onMore,
  });

  final InboxItem item;
  final int? uploaded;
  final bool linked;
  final VoidCallback onTap;
  final VoidCallback onMore;

  static const _source = {
    'share': 'Dibagikan',
    'whatsapp': 'WhatsApp',
    'camera': 'Kamera',
    'gallery': 'Galeri',
  };

  (String, Color) get _badge => switch (item.status) {
    'queued' => ('Antre', AppColors.neutral),
    'uploading' => ('Mengunggah', AppColors.navy),
    'processing' => ('Diproses', AppColors.attention),
    'needs_review' => ('Perlu dicek', AppColors.warn),
    'saved' => ('Tersimpan', AppColors.ok),
    _ => ('Gagal', AppColors.warn),
  };

  String get _detail {
    final pages = '${item.pages} halaman';
    return switch (item.status) {
      'queued' => linked ? 'Menunggu sinyal' : 'Menunggu akun toko',
      'uploading' => '${uploaded ?? 0} dari ${item.pages} halaman',
      'processing' => 'Sedang dibaca',
      'needs_review' =>
        '${_source[item.source] ?? item.source} · $pages · '
            '${item.lineCount} baris',
      'saved' =>
        'Tersimpan · ${DateFormat('d MMM', 'id_ID').format(item.createdAt)}',
      _ => 'Tidak bisa dibaca. Ketuk untuk coba lagi.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _badge;
    final text = Theme.of(context).textTheme;
    final title = item.supplierName ?? 'Foto baru (${item.pages})';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _Thumb(path: item.firstPage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _detail,
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.status == 'uploading' && item.pages > 0) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (uploaded ?? 0) / item.pages,
                        minHeight: 3,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final p = path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        color: AppColors.tint,
        child: p == null
            ? const Icon(Icons.receipt_long, color: AppColors.navy)
            : Image.file(
                File(p),
                fit: BoxFit.cover,
                // Decode small: a list of full-size photos would use a lot of
                // memory on a cheap phone.
                cacheWidth: 112,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.receipt_long, color: AppColors.navy),
              ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🧾', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text(
            'Belum ada PO',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Foto nota dari supplier, pilih dari galeri, atau bagikan dari '
            'WhatsApp. Harga supplier dibaca otomatis.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
