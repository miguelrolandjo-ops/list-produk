import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../backup/backup_screen.dart';
import '../catalog/employee_catalog_repository.dart' show noCategoryFilter;
import '../catalog/employee_home_screen.dart';
import '../inbox/inbox_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../products/add_product_screen.dart';
import '../products/category_home_screen.dart';
import '../products/edit_product_screen.dart';
import '../products/manage_categories_screen.dart';
import '../products/manage_suppliers_screen.dart';
import '../products/price_suggestions_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/product_list_screen.dart';
import '../review/review_screen.dart';
import '../settings/bulk_adjust_screen.dart';
import '../settings/margin_limits_screen.dart';
import '../settings/price_rules_screen.dart';
import '../settings/settings_screen.dart';
import '../team/account_screen.dart';
import '../team/team_screen.dart';
import '../welcome/welcome_screen.dart';
import 'app_mode.dart';
import 'app_shell.dart';

/// Where a phone in [mode] may be. Employees only ever see /karyawan; before a
/// mode is chosen only the welcome and onboarding screens exist.
String? redirectFor(AppMode? mode, String location) {
  final welcome = location == '/mulai' || location.startsWith('/mulai/');
  final employee =
      location == '/karyawan' || location.startsWith('/karyawan/');
  switch (mode) {
    case null:
      return welcome ? null : '/mulai';
    case AppMode.employee:
      return employee ? null : '/karyawan';
    case AppMode.owner:
      return welcome || employee ? '/' : null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect when the mode changes (joined, left, revoked).
  final modeChanges = ValueNotifier<AppMode?>(ref.read(appModeProvider));
  ref.listen(appModeProvider, (_, next) => modeChanges.value = next);
  ref.onDispose(modeChanges.dispose);

  return GoRouter(
    refreshListenable: modeChanges,
    redirect: (_, state) =>
        redirectFor(ref.read(appModeProvider), state.matchedLocation),
    routes: [
      // First launch.
      GoRoute(path: '/mulai', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/mulai/toko', builder: (_, _) => const OnboardingScreen()),

      // Employee phones.
      GoRoute(
        path: '/karyawan',
        builder: (_, _) => const EmployeeHomeScreen(),
        routes: [
          GoRoute(
            path: 'daftar',
            builder: (_, state) {
              final q = state.uri.queryParameters;
              return EmployeeListScreen(
                category: q['kategori'],
                autofocusSearch: q['cari'] == '1',
              );
            },
          ),
        ],
      ),

      // Owner phone, inside the bottom bar / sidebar frame.
      ShellRoute(
        builder: (_, state, child) =>
            OwnerShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CategoryHomeScreen()),
          GoRoute(
            path: '/produk',
            builder: (_, state) => ProductListScreen(
              key: const ValueKey('all-products'),
              title: 'Semua produk',
              autofocusSearch: state.uri.queryParameters['cari'] == '1',
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ProductDetailScreen(productId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'ubah',
                    builder: (_, state) => EditProductScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/kategori',
            builder: (_, _) => const ManageCategoriesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return ProductListScreen(
                    key: ValueKey('category-$id'),
                    categoryId: id,
                    categoryName:
                        state.uri.queryParameters['nama'] ??
                        (id == noCategoryFilter ? 'Tanpa kategori' : null),
                  );
                },
              ),
            ],
          ),
          GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
          GoRoute(path: '/tambah', builder: (_, _) => const AddProductScreen()),
          GoRoute(
            path: '/saran-harga',
            builder: (_, _) => const PriceSuggestionsScreen(),
          ),
          GoRoute(
            path: '/supplier',
            builder: (_, _) => const ManageSuppliersScreen(),
          ),
          GoRoute(path: '/tim', builder: (_, _) => const TeamScreen()),
          GoRoute(
            path: '/pengaturan',
            builder: (_, _) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'akun', builder: (_, _) => const AccountScreen()),
              GoRoute(
                path: 'jenis-toko',
                builder: (_, _) => const OnboardingScreen(fromSettings: true),
              ),
              GoRoute(
                path: 'cadangan',
                builder: (_, _) => const BackupScreen(),
              ),
              GoRoute(
                path: 'margin',
                builder: (_, _) => const MarginLimitsScreen(),
              ),
              GoRoute(
                path: 'massal',
                builder: (_, _) => const BulkAdjustScreen(),
              ),
              GoRoute(
                path: 'harga',
                builder: (_, _) => const PriceRulesScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/po/:id/review',
            builder: (_, state) =>
                ReviewScreen(poId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
