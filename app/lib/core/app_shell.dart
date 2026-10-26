import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../inbox/inbox_providers.dart';
import 'providers.dart';
import 'server_providers.dart';
import 'ui.dart';

class _Destination {
  const _Destination(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('/', 'Produk', Icons.grid_view_outlined, Icons.grid_view_rounded),
  _Destination('/inbox', 'Inbox', Icons.inbox_outlined, Icons.inbox),
  _Destination(
    '/saran-harga',
    'Saran harga',
    Icons.notifications_outlined,
    Icons.notifications,
  ),
  _Destination('/tim', 'Tim', Icons.group_outlined, Icons.group),
  _Destination(
    '/pengaturan/cadangan',
    'Cadangan',
    Icons.backup_outlined,
    Icons.backup,
  ),
  _Destination(
    '/pengaturan',
    'Pengaturan',
    Icons.settings_outlined,
    Icons.settings,
  ),
];

/// Phone bottom bar (mockup B): Inbox, Produk, Tim, Atur. "Saran harga" stays
/// the bell in the app bar, backup is in Settings.
const _phoneDestinations = ['/', '/inbox', '/tim', '/pengaturan'];
const _phoneLabels = {
  '/': 'Produk',
  '/inbox': 'Inbox',
  '/tim': 'Tim',
  '/pengaturan': 'Atur',
};

/// The owner's frame around every screen. Phones get a bottom navigation bar
/// on the main screens (and none on detail screens, so they keep their room);
/// tablets get a sidebar with large tiles, after the reference design.
class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  /// Which main place [location] belongs to ('/produk/12' → '/produk').
  static String sectionOf(String location) {
    if (location.startsWith('/po/')) return '/inbox';
    // Longest match first, so /pengaturan/cadangan isn't /pengaturan.
    final paths = [for (final d in _destinations.skip(1)) d.path]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final path in paths) {
      if (location == path || location.startsWith('$path/')) return path;
    }
    return '/'; // categories, product lists and details are all "Produk"
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = screenSizeOf(context);
    final section = sectionOf(location);
    final reviews = ref.watch(needsReviewCountProvider);
    if (size == ScreenSize.compact) {
      final isTop = _phoneDestinations.contains(location);
      return Scaffold(
        body: child,
        bottomNavigationBar: isTop
            ? NavigationBar(
                selectedIndex: _phoneDestinations.indexOf(location),
                onDestinationSelected: (i) => context.go(_phoneDestinations[i]),
                destinations: [
                  for (final path in _phoneDestinations)
                    _navBarItem(
                      _destinations.firstWhere((d) => d.path == path),
                      label: _phoneLabels[path]!,
                      badge: path == '/inbox' && reviews > 0 ? '$reviews' : null,
                    ),
                ],
              )
            : null,
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              section: section,
              wide: size == ScreenSize.expanded,
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _navBarItem(
    _Destination d, {
    required String label,
    String? badge,
  }) => NavigationDestination(
    icon: Badge(
      isLabelVisible: badge != null,
      label: Text(badge ?? ''),
      child: Icon(d.icon),
    ),
    selectedIcon: Badge(
      isLabelVisible: badge != null,
      label: Text(badge ?? ''),
      child: Icon(d.selectedIcon),
    ),
    label: label,
  );
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.section, required this.wide});

  final String section;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final urgent =
        (ref.watch(priceSuggestionsProvider).value ?? const [])
            .where((s) => s.belowMargin)
            .length;
    final unsent = ref.watch(unsentCountProvider).value;
    final link = ref.watch(ownerLinkProvider).value;
    final reviews = ref.watch(needsReviewCountProvider);

    return Container(
      width: wide ? 272 : 224,
      color: AppColors.canvas,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🏷️', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga Toko', style: text.titleLarge),
                    if (link?.storeName != null)
                      Text(
                        link!.storeName!,
                        style: text.bodySmall?.copyWith(color: AppColors.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: wide ? 1.15 : 1.0,
                  children: [
                    for (final d in _destinations)
                      _NavTile(
                        destination: d,
                        selected: section == d.path,
                        badge: switch (d.path) {
                          '/inbox' when reviews > 0 => '$reviews',
                          '/saran-harga' when urgent > 0 => '$urgent',
                          '/pengaturan' when (unsent ?? 0) > 0 => '$unsent',
                          _ => null,
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _SideLink(
                  icon: Icons.inventory_2_outlined,
                  label: 'Semua produk',
                  onTap: () => context.go('/produk'),
                ),
                _SideLink(
                  icon: Icons.storefront_outlined,
                  label: 'Kelola supplier',
                  onTap: () => context.go('/supplier'),
                ),
                _SideLink(
                  icon: Icons.label_outline,
                  label: 'Kelola kategori',
                  onTap: () => context.go('/kategori'),
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          _SideLink(
            icon: Icons.account_circle_outlined,
            label: link?.email ?? 'Akun toko',
            onTap: () => context.go('/pengaturan/akun'),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    this.badge,
  });

  final _Destination destination;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.ink;
    return Material(
      color: selected ? AppColors.tint : AppColors.surface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.navy : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(destination.path),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge != null,
                label: Text(badge ?? ''),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideLink extends StatelessWidget {
  const _SideLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: AppColors.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, size: 20),
        title: Text(label, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    ),
  );
}
