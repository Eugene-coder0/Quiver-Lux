import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({super.key, this.reference});

  final String? reference;

  @override
  ConsumerState<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = 'Confirming your payment...';
  String _reference = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyPayment();
    });
  }

  Future<void> _verifyPayment() async {
    final reference = (widget.reference ?? '').trim();
    if (reference.isEmpty) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = 'We could not find a Paystack payment reference for this return.';
      });
      return;
    }

    setState(() {
      _reference = reference;
      _isLoading = true;
      _message = 'Confirming your payment...';
    });

    try {
      final data = await ref.read(orderProvider.notifier).verifyPayment(reference);
      final status = (data['status']?.toString() ?? '').toLowerCase();
      final isSuccess = status == 'success';
      if (isSuccess) {
        ref.read(cartProvider.notifier).clearCart();
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = isSuccess;
        _message = isSuccess
            ? 'Payment confirmed. Your order is now in the paid workflow and visible to the vendor.'
            : 'Payment was not confirmed. Your order was not moved into fulfillment.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(color: QuiverLuxTheme.champagneGold)
                else
                  Icon(
                    _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: _isSuccess ? QuiverLuxTheme.champagneGold : Colors.redAccent,
                    size: 80,
                  ),
                const SizedBox(height: 20),
                Text(
                  _isLoading
                      ? 'Verifying payment'
                      : _isSuccess
                          ? 'Payment confirmed'
                          : 'Payment not confirmed',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: QuiverLuxTheme.matteBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _message,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (_reference.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Reference: $_reference',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),
                if (!_isLoading)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuiverLuxTheme.matteBlack,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    onPressed: () => context.go('/order-tracking'),
                    icon: const Icon(Icons.local_shipping_outlined, color: Colors.white),
                    label: Text(
                      _isSuccess ? 'VIEW ORDER STATUS' : 'VIEW ORDER HISTORY',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 8),
                if (!_isLoading)
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Continue shopping'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
