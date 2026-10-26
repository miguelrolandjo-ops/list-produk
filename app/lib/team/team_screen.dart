import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/server_api.dart';
import '../core/server_providers.dart';
import '../core/time_ago.dart';
import '../core/ui.dart';
import 'owner_account_service.dart';

class _TeamData {
  const _TeamData(this.members, this.invites);
  final List<StoreMember> members;
  final List<StoreInvite> invites;
}

final _teamProvider = FutureProvider.autoDispose<_TeamData>((ref) async {
  final team = ref.watch(teamServiceProvider);
  return _TeamData(await team.members(), await team.activeInvites());
});

/// "Tim": invite employees with a code, see who joined, revoke access.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await ref.read(teamServiceProvider).createInvite();
      ref.invalidate(_teamProvider);
      final storeName = ref.read(ownerLinkProvider).value?.storeName;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _InviteDialog(code: code, storeName: storeName),
      );
    } on ServerException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    StoreMember m,
  ) async {
    final name = m.displayName ?? 'karyawan ini';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cabut akses $name?'),
        content: const Text(
          'Katalog di HP-nya dihapus saat aplikasinya tersambung lagi. '
          'Untuk bergabung kembali, perlu kode undangan baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cabut akses'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(teamServiceProvider).revokeMember(m.userId);
      ref.invalidate(_teamProvider);
      messenger.showSnackBar(SnackBar(content: Text('Akses $name dicabut')));
    } on ServerException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _cancelInvite(WidgetRef ref, StoreInvite invite) async {
    await ref.read(teamServiceProvider).revokeInvite(invite.id);
    ref.invalidate(_teamProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(ownerLinkProvider).value;
    final compact = screenSizeOf(context) == ScreenSize.compact;
    final pad = compact ? 16.0 : 28.0;

    if (link == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (link.state != OwnerLinkState.linked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tim')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👥', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'Ajak karyawan melihat harga',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Karyawan melihat nama produk dan harga jual saja, di HP '
                    'mereka sendiri dan tetap bisa dipakai tanpa sinyal. '
                    'Untuk mulai, masuk dengan akun pemilik dan buat toko '
                    'online.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.push('/pengaturan/akun'),
                    child: const Text('Masuk atau daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final team = ref.watch(_teamProvider);
    return Scaffold(
      appBar: compact ? AppBar(title: const Text('Tim')) : null,
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              onPressed: () => _invite(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Undang karyawan'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_teamProvider.future),
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, compact ? 4 : 28, pad, 96),
          children: [
            PageHeader(
              title: compact ? (link.storeName ?? 'Toko Anda') : 'Tim',
              subtitle: 'Karyawan hanya melihat nama produk dan harga jual.',
              actions: compact
                  ? const []
                  : [
                      FilledButton.icon(
                        onPressed: () => _invite(context, ref),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Undang karyawan'),
                      ),
                    ],
            ),
            const SizedBox(height: 20),
            ...team.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                Text(e is ServerException ? e.message : '$e'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(_teamProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
              data: (data) => _content(context, ref, data),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, _TeamData data) {
    final text = Theme.of(context).textTheme;
    final active = data.members.where((m) => m.isActive).toList();
    final revoked = data.members.where((m) => !m.isActive).toList();
    final now = DateTime.now();
    final dateFmt = DateFormat('d MMM', 'id_ID');
    return [
      SummaryLine(
        items: [
          ('Karyawan aktif', '${active.length}', null),
          ('Kode berlaku', '${data.invites.length}', null),
        ],
      ),
      const SizedBox(height: 16),
      if (data.invites.isNotEmpty) ...[
        Text('Kode undangan', style: text.titleMedium),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, inv) in data.invites.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: const Text('🎟️', style: TextStyle(fontSize: 24)),
                  title: Text(
                    inv.code,
                    style: const TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Berlaku sampai ${dateFmt.format(inv.expiresAt.toLocal())}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Bagikan kode ${inv.code}',
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(
                            text: TeamService.inviteMessage(
                              inv.code,
                              storeName: ref
                                  .read(ownerLinkProvider)
                                  .value
                                  ?.storeName,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Batalkan kode ${inv.code}',
                        icon: const Icon(Icons.close),
                        onPressed: () => _cancelInvite(ref, inv),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
      Text('Karyawan', style: text.titleMedium),
      const SizedBox(height: 8),
      if (active.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Belum ada karyawan. Ketuk "Undang karyawan" lalu kirim kodenya '
              'lewat WhatsApp.',
            ),
          ),
        )
      else
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, m) in active.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.tint,
                    foregroundColor: AppColors.navy,
                    child: Text(
                      _initial(m.displayName),
                    ),
                  ),
                  title: Text(m.displayName ?? 'Tanpa nama'),
                  subtitle: Text(
                    [
                      if (m.deviceLabel != null) m.deviceLabel!,
                      m.lastSeenAt == null
                          ? 'belum membuka katalog'
                          : 'terakhir buka '
                                '${timeAgo(m.lastSeenAt!.toLocal(), now)}',
                    ].join(' · '),
                  ),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warn,
                    ),
                    onPressed: () => _revoke(context, ref, m),
                    child: const Text('Cabut'),
                  ),
                ),
              ],
            ],
          ),
        ),
      if (revoked.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(
          'Sudah dicabut',
          style: text.titleSmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        for (final m in revoked)
          ListTile(
            dense: true,
            title: Text(m.displayName ?? 'Tanpa nama'),
            subtitle: Text(
              'Dicabut ${timeAgo(m.revokedAt!.toLocal(), now)}',
            ),
          ),
      ],
    ];
  }
}

String _initial(String? name) {
  final n = name?.trim() ?? '';
  return n.isEmpty ? '?' : n.characters.first.toUpperCase();
}

class _InviteDialog extends StatelessWidget {
  const _InviteDialog({required this.code, this.storeName});

  final String code;
  final String? storeName;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Kode undangan'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.tint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SelectableText(
            code,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              letterSpacing: 6,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Berlaku 7 hari. Karyawan memasang aplikasi Harga Toko, memilih '
          '"Gabung sebagai karyawan", lalu memasukkan kode ini.',
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: code));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kode disalin')));
        },
        child: const Text('Salin'),
      ),
      FilledButton.icon(
        onPressed: () {
          Navigator.pop(context);
          SharePlus.instance.share(
            ShareParams(
              text: TeamService.inviteMessage(code, storeName: storeName),
            ),
          );
        },
        icon: const Icon(Icons.share),
        label: const Text('Kirim lewat WhatsApp'),
      ),
    ],
  );
}
