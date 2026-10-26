import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/server_api.dart';
import '../core/server_providers.dart';
import '../core/ui.dart';
import '../onboarding/shop_profile.dart';
import '../publish/publish_service.dart';
import 'owner_account_service.dart';

/// "Akun dan toko": sign in, create the store on the server, and see whether
/// the employee catalog is up to date. Everything else in the app works
/// without this.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(ownerLinkProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Akun dan toko')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: link.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(
              emoji: '⚠️',
              title: 'Tidak bisa memeriksa akun',
              body: e is ServerException ? e.message : '$e',
              action: FilledButton(
                onPressed: () => ref.invalidate(ownerLinkProvider),
                child: const Text('Coba lagi'),
              ),
            ),
            data: (l) => switch (l.state) {
              OwnerLinkState.notConfigured => const _Message(
                emoji: '🔌',
                title: 'Server belum diatur',
                body:
                    'Aplikasi ini dibuat tanpa alamat server. Jalankan dengan '
                    '--dart-define-from-file=config.json (lihat '
                    'config.example.json).',
              ),
              OwnerLinkState.signedOut => const _SignInForm(),
              OwnerLinkState.noStore => _CreateStore(email: l.email),
              OwnerLinkState.notOwner => _NotOwner(email: l.email),
              OwnerLinkState.linked => _Linked(link: l),
            },
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.emoji,
    required this.title,
    required this.body,
    this.action,
  });

  final String emoji;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(emoji, style: const TextStyle(fontSize: 44)),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(body),
      if (action != null) ...[const SizedBox(height: 20), action!],
    ],
  );
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _signUp = false;
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(ownerAccountServiceProvider);
    try {
      if (_signUp) {
        final signedIn = await service.signUp(_email.text, _password.text);
        if (!signedIn) {
          messenger.showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 8),
              content: Text(
                'Akun dibuat. Buka email konfirmasi dari Supabase, lalu '
                'kembali ke sini dan pilih Masuk.',
              ),
            ),
          );
          setState(() => _signUp = false);
        }
      } else {
        await service.signIn(_email.text, _password.text);
      }
      ref.invalidate(ownerLinkProvider);
    } on ServerException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('👥', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text('Bagikan harga ke karyawan', style: text.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'Masuk dengan akun pemilik supaya karyawan bisa melihat nama '
            'produk dan harga jual di HP mereka. Harga beli dan data supplier '
            'tidak pernah dikirim.',
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Masuk')),
              ButtonSegment(value: true, label: Text('Daftar baru')),
            ],
            selected: {_signUp},
            onSelectionChanged: (v) => setState(() => _signUp = v.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) =>
                (v ?? '').contains('@') ? null : 'Masukkan email yang benar',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [
              _signUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            decoration: InputDecoration(
              labelText: 'Kata sandi',
              helperText: _signUp ? 'Minimal 8 karakter' : null,
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? 'Sembunyikan kata sandi'
                    : 'Tampilkan kata sandi',
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (v) => (v ?? '').length < 8
                ? 'Kata sandi minimal 8 karakter'
                : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_signUp ? 'Daftar' : 'Masuk'),
          ),
        ],
      ),
    );
  }
}

class _CreateStore extends ConsumerStatefulWidget {
  const _CreateStore({required this.email});
  final String? email;

  @override
  ConsumerState<_CreateStore> createState() => _CreateStoreState();
}

class _CreateStoreState extends ConsumerState<_CreateStore> {
  late final _name = TextEditingController(
    text: ref.read(shopProfileProvider).name ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(ownerAccountServiceProvider).createStore(name);
      await ref.read(shopProfileProvider.notifier).setName(name);
      ref.invalidate(ownerLinkProvider);
      ref.read(autoPublisherProvider)?.kick();
      messenger.showSnackBar(
        SnackBar(content: Text('Toko "$name" dibuat. Katalog sedang dikirim.')),
      );
    } on ServerException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text('🏪', style: TextStyle(fontSize: 44)),
      const SizedBox(height: 12),
      Text(
        'Buat toko online',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        'Masuk sebagai ${widget.email ?? 'pemilik'}. Setelah toko dibuat, '
        'produk dikirim ke katalog karyawan secara otomatis.',
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nama toko'),
        onSubmitted: (_) => _create(),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _create,
        child: const Text('Buat toko'),
      ),
      const SizedBox(height: 8),
      const _SignOutButton(),
    ],
  );
}

class _NotOwner extends ConsumerWidget {
  const _NotOwner({required this.email});
  final String? email;

  Future<void> _newStore(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat toko baru untuk akun ini?'),
        content: const Text(
          'Katalog di HP ini akan dikirim ke toko baru. Karyawan toko lama '
          'tidak menerima perubahan lagi dan perlu diundang ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buat toko baru'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = ref.read(shopProfileProvider).name ?? 'Toko saya';
    try {
      await ref.read(ownerAccountServiceProvider).createStore(name);
      ref.invalidate(ownerLinkProvider);
    } on ServerException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Message(
    emoji: '🔑',
    title: 'Akun ini bukan pemilik toko di HP ini',
    body:
        'Data di HP ini (mungkin dari cadangan) terhubung ke toko milik akun '
        'lain. Keluar lalu masuk dengan akun pemilik yang dulu, atau buat '
        'toko baru untuk ${email ?? 'akun ini'}.',
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => _newStore(context, ref),
          child: const Text('Buat toko baru untuk akun ini'),
        ),
        const SizedBox(height: 8),
        const _SignOutButton(),
      ],
    ),
  );
}

class _Linked extends ConsumerStatefulWidget {
  const _Linked({required this.link});
  final OwnerLink link;

  @override
  ConsumerState<_Linked> createState() => _LinkedState();
}

class _LinkedState extends ConsumerState<_Linked> {
  bool _sending = false;

  Future<void> _sendNow() async {
    setState(() => _sending = true);
    final result = await ref.read(publishServiceProvider).publish();
    if (!mounted) return;
    setState(() => _sending = false);
    final msg = switch (result.outcome) {
      PublishOutcome.sent => '${result.sent} produk terkirim',
      PublishOutcome.nothingToSend => 'Semua sudah terkirim',
      PublishOutcome.offline =>
        'Tidak ada sinyal. Dikirim otomatis saat online.',
      PublishOutcome.notAllowed => 'Ditolak server: akun ini bukan pemilik.',
      _ => result.error?.message ?? 'Belum bisa mengirim',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.link;
    final unsent = ref.watch(unsentCountProvider).value ?? 0;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🏪', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.storeName ?? 'Toko Anda',
                            style: text.titleMedium,
                          ),
                          Text(
                            l.email ?? '',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      l.offline ? 'Offline' : 'Terhubung',
                      color: l.offline ? AppColors.neutral : AppColors.ok,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatBox(
                  rows: [
                    (
                      'Katalog karyawan',
                      unsent == 0 ? 'Terbaru' : '$unsent belum terkirim',
                      unsent == 0 ? AppColors.ok : AppColors.attention,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _sending ? null : _sendNow,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Kirim sekarang'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Perubahan produk dikirim otomatis beberapa detik setelah disimpan '
          'dan saat aplikasi dibuka. Tanpa sinyal, perubahan menunggu dan '
          'dikirim nanti.',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.go('/tim'),
          icon: const Icon(Icons.group_outlined),
          label: const Text('Atur karyawan'),
        ),
        const SizedBox(height: 8),
        const _SignOutButton(),
      ],
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Keluar dari akun?'),
          content: const Text(
            'Data di HP ini tetap ada. Katalog karyawan tidak diperbarui '
            'sampai Anda masuk lagi.',
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
      try {
        await ref.read(ownerAccountServiceProvider).signOut();
      } on ServerException {
        // Signed out locally even without signal.
      }
      ref.invalidate(ownerLinkProvider);
    },
    child: const Text('Keluar dari akun'),
  );
}
