import 'package:go_router/go_router.dart';

import '../products/add_product_screen.dart';
import '../backup/backup_screen.dart';
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

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ProductListScreen()),
    GoRoute(path: '/tambah', builder: (_, _) => const AddProductScreen()),
    GoRoute(
      path: '/pengaturan/cadangan',
      builder: (_, _) => const BackupScreen(),
    ),
    GoRoute(path: '/saran-harga', builder: (_, _) => const PriceSuggestionsScreen()),
    GoRoute(path: '/supplier', builder: (_, _) => const ManageSuppliersScreen()),
    GoRoute(path: '/kategori', builder: (_, _) => const ManageCategoriesScreen()),
    GoRoute(path: '/pengaturan', builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: '/pengaturan/margin',
      builder: (_, _) => const MarginLimitsScreen(),
    ),
    GoRoute(
      path: '/pengaturan/massal',
      builder: (_, _) => const BulkAdjustScreen(),
    ),
    GoRoute(
      path: '/pengaturan/harga',
      builder: (_, _) => const PriceRulesScreen(),
    ),
    GoRoute(
      path: '/po/:id/review',
      builder: (_, state) => ReviewScreen(poId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/produk/:id',
      builder: (_, state) =>
          ProductDetailScreen(productId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'ubah',
          builder: (_, state) =>
              EditProductScreen(productId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
