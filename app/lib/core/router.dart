import 'package:go_router/go_router.dart';

import '../products/add_product_screen.dart';
import '../products/product_list_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ProductListScreen()),
    GoRoute(path: '/tambah', builder: (_, _) => const AddProductScreen()),
  ],
);
