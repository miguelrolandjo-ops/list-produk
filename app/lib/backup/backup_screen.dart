import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io';

import '../core/display_prefs.dart';
import '../core/providers.dart';
import 'backup_service.dart';

final _date = DateFormat('d MMM y, HH.mm', 'id_ID');

String daysAgo(DateTime then, DateTime now) {
  final days = now.difference(then).inDays;
  return days <= 0 ? 'hari ini' : '$days hari lalu';
}

/// "Cadangkan data": share a backup file, or restore from one.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      final file = await service.createBackup();
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/zip')],
          subject: 'Cadangan Harga Toko',
        ),
      );
      // Only count it as a backup if the owner didn't close the share sheet.
      if (result.status != ShareResultStatus.dismissed) {
        await service.markBackedUp();
        _message('Cadangan dibuat. Pastikan file tersimpan di tempat aman.');
      }
    } catch (e) {
      _message('Gagal membuat cadangan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = picked?.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      final candidate = await service.inspect(File(path));
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _ConfirmRestoreDialog(candidate: candidate),
      );
      if (confirmed != true) return;

      await service.restore(candidate);
      // The old database is closed; every provider that used it must reopen.
      ref.invalidate(ownerDbProvider);
      if (!mounted) return;
      context.go('/');
      _message('Data berhasil dipulihkan.');
    } on BackupException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Pemulihan gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(backupStatusProvider).value;
    final prefs = ref.watch(displayPrefsProvider);
    final last = status?.lastBackup;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadangkan data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cadangan terakhir'),
                  const SizedBox(height: 4),
                  Text(
                    last == null ? 'Belum pernah' : _date.format(last),
                    style: theme.textTheme.titleLarge,
                  ),
                  if (last != null)
                    Text(
                      daysAgo(last, DateTime.now()),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pengingat otomatis'),
            subtitle: const Text('Jika lebih dari 7 hari'),
            value: prefs.backupReminder,
            onChanged: ref
                .read(displayPrefsProvider.notifier)
                .setBackupReminder,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _backupNow,
            icon: const Icon(Icons.ios_share),
            label: const Text('Cadangkan sekarang'),
          ),
          const SizedBox(height: 6),
          Text(
            'Simpan file ke Google Drive atau kirim ke diri sendiri. '
            'Foto tidak ikut dicadangkan.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.restore),
            label: const Text('Pulihkan dari file'),
          ),
          const SizedBox(height: 6),
          Text(
            'Mengganti semua data di HP ini',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRestoreDialog extends StatelessWidget {
  const _ConfirmRestoreDialog({required this.candidate});
  final BackupCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pulihkan data?'),
      content: Text(
        'Cadangan dari ${_date.format(candidate.createdAt)} '
        'berisi ${candidate.productCount} produk.\n\n'
        'Semua data di HP ini akan diganti dengan data cadangan. '
        'Perubahan setelah tanggal itu hilang.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ganti semua data'),
        ),
      ],
    );
  }
}
