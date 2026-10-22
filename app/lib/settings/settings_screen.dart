import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/display_prefs.dart';
import '../core/providers.dart';
import '../inbox/debug_sample.dart';

/// Settings menu. Backup entries are added in 2.3.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(displayPrefsProvider);
    final notifier = ref.read(displayPrefsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
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
