import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

import '../core/display_prefs.dart';
import '../core/providers.dart';
import 'backup_exporter.dart' show BackupDestination;
import 'backup_service.dart';

final _date = DateFormat('d MMM y, HH.mm', 'id_ID');

String daysAgo(DateTime then, DateTime now) {
  final days = now.difference(then).inDays;
  return days <= 0 ? 'hari ini' : '$days hari lalu';
}

/// "Cadangkan data": back up to Google Drive or the phone's Download folder,
/// or restore from a backup file.
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
    final destination = await showModalBottomSheet<BackupDestination>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Simpan cadangan ke mana?')),
            ListTile(
              leading: const Icon(Icons.add_to_drive),
              title: const Text('Google Drive'),
              subtitle: const Text('Pilih Drive di menu berbagi'),
              onTap: () => Navigator.pop(context, BackupDestination.drive),
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: const Text('Simpan di HP'),
              subtitle: const Text('Langsung ke folder Download'),
              onTap: () => Navigator.pop(context, BackupDestination.local),
            ),
          ],
        ),
      ),
    );
    if (destination == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      final exporter = ref.read(backupExporterProvider);
      final file = await service.createBackup();
      switch (destination) {
        case BackupDestination.drive:
          // Only count it as a backup if the owner didn't close the sheet.
          if (await exporter.shareFile(file)) {
            await service.markBackedUp();
            _message('Cadangan dibuat. Pastikan file tersimpan di tempat aman.');
          }
        case BackupDestination.local:
          if (await exporter.saveToDownloads(file)) {
            await service.markBackedUp();
            _message('Cadangan disimpan di folder Download: ${p.basename(file.path)}');
          } else {
            _message(
              'Gagal menyimpan ke folder Download. Coba lewat Google Drive.',
            );
          }
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
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Cadangkan sekarang'),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih Google Drive atau simpan di folder Download HP. '
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
