import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: QuiverLuxTheme.champagneGold,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: QuiverLuxTheme.matteBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for shopping with Quiver Lux.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuiverLuxTheme.matteBlack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text(
                  'VIEW ORDER & TRACKING',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.go('/'), child: const Text('Continue shopping')),
            ],
          ),
        ),
      ),
    );
  }
}
