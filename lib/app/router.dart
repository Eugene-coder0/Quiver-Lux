import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customer/models/product_model.dart';
import '../features/customer/screens/cart_screen.dart';
import '../features/customer/screens/checkout_screen.dart';
import '../features/customer/screens/customer_home_screen.dart';
import '../features/customer/screens/explore_screen.dart';
import '../features/customer/screens/bank_transfer_payment_screen.dart';
import '../features/customer/screens/order_success_screen.dart';
import '../features/customer/screens/payment_status_screen.dart';
import '../features/customer/screens/order_tracking_screen.dart';
import '../features/customer/screens/product_detail_screen.dart';
import '../features/customer/screens/profile_screen.dart';
import '../features/vendor/screens/add_edit_product_screen.dart';
import '../features/vendor/screens/vendor_dashboard_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/explore',
      builder: (context, state) => const ExploreScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/product-detail',
      builder: (context, state) {
        final product = state.extra;
        if (product == null) {
          return const _MissingProductRedirect();
        }
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/bank-transfer-payment',
      builder: (context, state) => BankTransferPaymentScreen(
        payload: state.extra is Map<String, dynamic>
            ? Map<String, dynamic>.from(state.extra as Map<String, dynamic>)
            : const {},
      ),
    ),
    GoRoute(
      path: '/order-success',
      builder: (context, state) => const OrderSuccessScreen(),
    ),
    GoRoute(
      path: '/payment-status',
      builder: (context, state) => PaymentStatusScreen(
        reference: state.uri.queryParameters['reference'] ??
            state.uri.queryParameters['trxref'],
      ),
    ),
    GoRoute(
      path: '/order-tracking',
      builder: (context, state) => const OrderTrackingScreen(),
    ),
    GoRoute(
      path: '/vendor',
      builder: (context, state) => const _VendorGuard(
        child: VendorDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/vendor/products/new',
      builder: (context, state) => const _VendorGuard(
        child: AddEditProductScreen(),
      ),
    ),
    GoRoute(
      path: '/vendor/products/edit',
      builder: (context, state) {
        final product = state.extra;
        if (product is! ProductModel) {
          return const _VendorGuard(child: AddEditProductScreen());
        }
        return _VendorGuard(child: AddEditProductScreen(productToEdit: product));
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const _AdminGuard(
        child: AdminDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);

/// Shown briefly when `/product-detail` is opened without a product payload.
class _MissingProductRedirect extends StatefulWidget {
  const _MissingProductRedirect();

  @override
  State<_MissingProductRedirect> createState() =>
      _MissingProductRedirectState();
}

class _MissingProductRedirectState extends State<_MissingProductRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AdminGuard extends StatelessWidget {
  final Widget child;

  const _AdminGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    // Temporary admin portal bypass while admin authentication is being wired.
    return child;
  }
}

class _VendorGuard extends ConsumerWidget {
  final Widget child;

  const _VendorGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final isAuthorized = user != null &&
        (user.role == 'admin' ||
            user.role == 'vendor' ||
            user.vendorStatus == 'approved');

    if (isAuthorized) {
      return child;
    }

    final isPending = user?.vendorStatus == 'pending';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Vendor Studio Access',
          style: TextStyle(
            color: QuiverLuxTheme.matteBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPending ? Colors.amber.shade50 : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPending
                      ? Icons.hourglass_top_outlined
                      : Icons.storefront_outlined,
                  size: 64,
                  color: isPending ? Colors.amber.shade800 : QuiverLuxTheme.forest,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isPending
                    ? 'Application Under Admin Review'
                    : 'Vendor Account Required',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: QuiverLuxTheme.matteBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isPending
                    ? 'Your vendor application has been submitted and is currently being evaluated by marketplace administrators. You will be granted Vendor Studio access once approved.'
                    : 'Only registered and verified merchants can manage product listings and orders in the Vendor Studio.',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Return to Home'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuiverLuxTheme.forest,
                    ),
                    onPressed: () => context.push('/profile'),
                    child: Text(
                      isPending ? 'Check Application Status' : 'Apply to Become a Vendor',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
