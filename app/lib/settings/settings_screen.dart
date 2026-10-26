import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/display_prefs.dart';
import '../core/providers.dart';
import '../core/server_providers.dart';
import '../core/ui.dart';
import '../team/owner_account_service.dart';
import '../inbox/debug_sample.dart';

/// Settings menu (mockup screen C).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(displayPrefsProvider);
    final notifier = ref.read(displayPrefsProvider.notifier);
    final link = ref.watch(ownerLinkProvider).value;
    final unsent = ref.watch(unsentCountProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const _Section('Toko'),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Akun dan toko'),
            subtitle: Text(switch (link?.state) {
              OwnerLinkState.linked =>
                [link!.storeName, link.email].whereType<String>().join(' · '),
              OwnerLinkState.noStore => 'Masuk sebagai ${link!.email ?? '-'}'
                  ' · toko belum dibuat',
              OwnerLinkState.notOwner => 'Perlu diperiksa',
              OwnerLinkState.notConfigured => 'Server belum diatur',
              _ => 'Belum masuk · bagikan harga ke karyawan',
            }),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pengaturan/akun'),
          ),
          if (unsent != null)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Katalog karyawan'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  unsent == 0
                      ? const StatusBadge('Terbaru', color: AppColors.ok)
                      : StatusBadge(
                          '$unsent belum terkirim',
                          color: AppColors.attention,
                        ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => context.push('/pengaturan/akun'),
            ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Tim'),
            subtitle: const Text('Undang karyawan, cabut akses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/tim'),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_emotions_outlined),
            title: const Text('Jenis toko dan ikon'),
            subtitle: const Text('Tambah jenis toko dan kategori awalnya'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pengaturan/jenis-toko'),
          ),
          const _Section('Harga'),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Aturan harga'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pengaturan/harga'),
          ),
          ListTile(
            leading: const Icon(Icons.percent),
            title: const Text('Batas margin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pengaturan/margin'),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Ubah massal per rentang'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pengaturan/massal'),
          ),
          const _Section('Tampilan daftar produk'),
          SwitchListTile(
            secondary: const Icon(Icons.warning_amber_rounded),
            title: const Text('Ikon peringatan margin'),
            subtitle: const Text('Tanda jika margin di bawah batas'),
            value: prefs.showMarginWarning,
            onChanged: notifier.setShowMarginWarning,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.edit),
            title: const Text('Ikon harga manual'),
            subtitle: const Text('Tanda pensil jika harga diubah manual'),
            value: prefs.showOverrideIcon,
            onChanged: notifier.setShowOverrideIcon,
          ),
          const _Section('Data'),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Kelola kategori'),
            subtitle: const Text('Lihat dan hapus kategori'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/kategori'),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Kelola supplier'),
            subtitle: const Text('Lihat dan hapus supplier'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/supplier'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Cadangkan data'),
            subtitle: const Text('Cadangkan atau pulihkan dari file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pengaturan/cadangan'),
          ),
          if (kDebugMode) ...[
            const _Section('Uji coba (hanya build debug)'),
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Impor PO contoh'),
              subtitle: const Text('Buat PO palsu lalu buka layar Review'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final id = await seedSamplePo(
                  ref.read(ownerDbProvider),
                  ref.read(poImportServiceProvider),
                );
                if (context.mounted) context.push('/po/$id/review');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(label, style: Theme.of(context).textTheme.labelLarge),
  );
}
