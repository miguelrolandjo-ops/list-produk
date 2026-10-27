import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../catalog/join_service.dart';
import '../core/app_mode.dart';
import '../core/server_api.dart';
import '../core/server_providers.dart';
import '../core/ui.dart';
import '../onboarding/shop_types.dart';

/// First launch (mockup screen A): create a shop, restore a backup onto this
/// phone, or join a shop as an employee with an invite code.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.initialCode});

  /// The code from an invite link: the join form opens with it filled in.
  final String? initialCode;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late bool _joining = widget.initialCode != null;
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    await ref.read(appModeProvider.notifier).set(AppMode.owner);
    if (!mounted) return;
    context.go('/');
    context.push('/pengaturan/cadangan');
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final store = await ref
          .read(joinServiceProvider)
          .join(
            _code.text,
            name: _name.text,
            device: Platform.isAndroid ? 'Android' : Platform.operatingSystem,
          );
      await ref.read(appModeProvider.notifier).set(AppMode.employee);
      messenger.showSnackBar(
        SnackBar(content: Text('Bergabung dengan $store')),
      );
      if (mounted) context.go('/karyawan');
    } on ServerException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on Object catch (e) {
      // Not a server answer (the phone's database, for example): never fail
      // silently.
      messenger.showSnackBar(
        SnackBar(content: Text('Tidak bisa bergabung: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final options = _Options(
      joining: _joining,
      onCreate: () => context.push('/mulai/toko'),
      onRestore: _restore,
      onToggleJoin: () => setState(() => _joining = !_joining),
      joinForm: _joinForm(context),
    );
    if (size == ScreenSize.compact) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            children: [const _Brand(compact: true), const SizedBox(height: 28), options],
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            const Expanded(child: _BrandPanel()),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(32),
                    children: [options],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _joinForm(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.initialCode != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.link, color: AppColors.navy),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kode dari tautan undangan sudah diisi. Tulis nama Anda, '
                    'lalu ketuk Gabung.',
                  ),
                ),
              ],
            ),
          ),
        TextFormField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9 -]')),
            LengthLimitingTextInputFormatter(12),
          ],
          style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Kode undangan',
            hintText: '7KQ2M9XA',
            suffixIcon: IconButton(
              tooltip: 'Tempel kode',
              icon: const Icon(Icons.content_paste),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text ?? '';
                // A whole invite message may be pasted: take the code from it.
                final match = RegExp(r'\b[A-Z0-9]{8}\b').firstMatch(text);
                _code.text = match?.group(0) ?? text.trim();
              },
            ),
          ),
          validator: (v) => JoinService.isValidCode(v ?? '')
              ? null
              : 'Kode harus 8 karakter',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _name,
          // Opened from a link: the code is there, the name is what's next.
          autofocus: widget.initialCode != null,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Anda',
            helperText: 'Supaya pemilik toko tahu siapa yang bergabung',
          ),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _join,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gabung'),
        ),
        if (ref.watch(serverApiProvider) == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Aplikasi ini belum terhubung ke server, jadi belum bisa '
              'bergabung.',
              style: TextStyle(color: AppColors.warn),
            ),
          ),
      ],
    ),
  );
}

class _Options extends StatelessWidget {
  const _Options({
    required this.joining,
    required this.onCreate,
    required this.onRestore,
    required this.onToggleJoin,
    required this.joinForm,
  });

  final bool joining;
  final VoidCallback onCreate;
  final VoidCallback onRestore;
  final VoidCallback onToggleJoin;
  final Widget joinForm;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _OptionCard(
        emoji: '🏪',
        title: 'Buat toko baru',
        subtitle: 'Untuk pemilik toko',
        onTap: onCreate,
      ),
      const SizedBox(height: 10),
      _OptionCard(
        emoji: '💾',
        title: 'Pulihkan dari cadangan',
        subtitle: 'Pindah ke HP baru',
        onTap: onRestore,
      ),
      const SizedBox(height: 10),
      _OptionCard(
        emoji: '👥',
        title: 'Gabung sebagai karyawan',
        subtitle: 'Masukkan kode undangan',
        onTap: onToggleJoin,
        expanded: joining,
        child: joining
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: joinForm,
              )
            : null,
      ),
    ],
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.expanded,
    this.child,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool? expanded;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleMedium),
                        Text(
                          subtitle,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded == null
                        ? Icons.chevron_right
                        : (expanded! ? Icons.expand_less : Icons.expand_more),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('🏷️', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 16),
        Text('Harga Toko', style: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 4),
        Text(
          'Panduan harga untuk toko Anda',
          style: text.bodyLarge?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Tablet: a navy panel with the shop kinds the app knows, so a new owner
/// sees right away that it fits their shop.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏷️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 20),
          Text(
            'Harga Toko',
            style: text.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Harga jual yang selalu benar, untuk Anda dan karyawan. '
            'Data supplier tetap di HP pemilik.',
            style: text.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const Spacer(),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final t in shopTypes.where((t) => t.id != 'other'))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${t.emoji}  ${t.name}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
