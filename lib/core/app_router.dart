import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'services/auth_service.dart';

// ─── Auth provider ──────────────────────────────────────────────
final authProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.tokenKey) != null;
});

// ─── Placeholder screens ────────────────────────────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Login Screen')));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: Center(child: Text('Home Screen')),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Dashboard')));
  }
}

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Customer List')));
  }
}

class CustomerDetailScreen extends StatelessWidget {
  final String id;
  const CustomerDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Customer: $id')));
  }
}

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Order List')));
  }
}

class NewOrderScreen extends StatelessWidget {
  const NewOrderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('New Order')));
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Order: $id')));
  }
}

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Product List')));
  }
}

class ProductDetailScreen extends StatelessWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Product: $id')));
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Reports')));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Profile')));
  }
}

// ─── GoRouter ───────────────────────────────────────────────────
final appRouter = GoRouter(
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final isAuthenticated = token != null;
    final goingToLogin = state.uri.toString() == '/login';

    if (!isAuthenticated && !goingToLogin) {
      return '/login';
    }
    if (isAuthenticated && goingToLogin) {
      return '/home';
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return HomeScreenWithNav(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
          routes: [
            GoRoute(
              path: 'customers',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CustomerListScreen(),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  parentBuilder: (context, child) => child,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: CustomerDetailScreen(id: state.pathParameters['id']!),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'orders',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: OrderListScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  parentBuilder: (context, child) => child,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const NewOrderScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
                GoRoute(
                  path: ':id',
                  parentBuilder: (context, child) => child,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: OrderDetailScreen(id: state.pathParameters['id']!),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'products',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProductListScreen(),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  parentBuilder: (context, child) => child,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: ProductDetailScreen(id: state.pathParameters['id']!),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'reports',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ReportsScreen(),
              ),
            ),
            GoRoute(
              path: 'profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ─── Shell wrapper with bottom nav ──────────────────────────────
class HomeScreenWithNav extends ConsumerWidget {
  final Widget child;
  const HomeScreenWithNav({super.key, required this.child});

  static const _routes = [
    '/home',
    '/home/customers',
    '/home/orders',
    '/home/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    for (int i = 0; i < _routes.length; i++) {
      if (currentPath.startsWith(_routes[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          context.go(_routes[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
