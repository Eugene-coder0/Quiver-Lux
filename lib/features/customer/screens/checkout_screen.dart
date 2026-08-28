import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/payments/payment_redirect.dart';
import '../../../providers/api_provider.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/account_profile_provider.dart';
import '../providers/cart_provider.dart';

enum CheckoutPaymentMethod { card, bank, bankTransfer, ussd }

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  bool _isProcessing = false;
  CheckoutPaymentMethod _paymentMethod = CheckoutPaymentMethod.card;

  @override
  void initState() {
    super.initState();
    final account = ref.read(accountProfileProvider);
    _addressController = TextEditingController(text: account.address);
    _phoneController = TextEditingController(text: account.phone);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    final cartItems = ref.read(cartProvider);
    final auth = ref.read(authProvider);
    final account = ref.read(accountProfileProvider);

    if (cartItems.isEmpty) return;

    setState(() => _isProcessing = true);

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    await ref.read(accountProfileProvider.notifier).update(
          address: address,
          phone: phone,
        );

    try {
      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.ordersCheckout,
        data: {
          'paymentChannel': switch (_paymentMethod) {
            CheckoutPaymentMethod.card => 'card',
            CheckoutPaymentMethod.bank => 'bank',
            CheckoutPaymentMethod.bankTransfer => 'bank_transfer',
            CheckoutPaymentMethod.ussd => 'ussd',
          },
          if (buildPaymentCallbackUrl('/payment-status') != null)
            'callbackUrl': buildPaymentCallbackUrl('/payment-status'),
          'shippingAddress': {
            'fullName': account.fullName.trim().isNotEmpty
                ? account.fullName.trim()
                : (auth.user?.name ?? 'Guest shopper'),
            'phone': phone,
            'streetLine1': address,
            'city': 'Lagos',
            'state': 'Lagos',
            'country': 'Nigeria',
          },
          'items': cartItems
              .map((item) => {
                    'productId': item.product.id,
                    'quantity': item.quantity,
                  })
              .toList(),
        },
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};

      final paymentUrl = data['paymentUrl']?.toString() ?? '';
      if (paymentUrl.isEmpty) {
        throw Exception('Checkout did not return a payment link.');
      }

      await redirectToPaymentUrl(paymentUrl);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final isCompact = MediaQuery.sizeOf(context).width < 560;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        title: const Text(
          'CHECKOUT',
          style: TextStyle(letterSpacing: 2, fontSize: 16),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.champagneGold),
                  SizedBox(height: 16),
                  Text('Preparing secure Paystack checkout...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DELIVERY DETAILS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration:
                        const InputDecoration(labelText: 'Delivery Address'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Contact Phone Number'),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAYMENT METHOD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isCompact)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: CheckoutPaymentMethod.values
                                .map(
                                  (method) => ChoiceChip(
                                    selected: _paymentMethod == method,
                                    label: Text(_paymentMethodLabel(method)),
                                    avatar: Icon(
                                      _paymentMethodIcon(method),
                                      size: 18,
                                      color: _paymentMethod == method
                                          ? AppColors.matteBlack
                                          : Colors.black54,
                                    ),
                                    onSelected: (_) {
                                      setState(() => _paymentMethod = method);
                                    },
                                  ),
                                )
                                .toList(),
                          )
                        else
                          SegmentedButton<CheckoutPaymentMethod>(
                            segments: const [
                              ButtonSegment(
                                value: CheckoutPaymentMethod.card,
                                label: Text('Card'),
                                icon: Icon(Icons.credit_card_outlined),
                              ),
                              ButtonSegment(
                                value: CheckoutPaymentMethod.bank,
                                label: Text('Bank'),
                                icon: Icon(Icons.account_balance_wallet_outlined),
                              ),
                              ButtonSegment(
                                value: CheckoutPaymentMethod.bankTransfer,
                                label: Text('Bank transfer'),
                                icon: Icon(Icons.account_balance_outlined),
                              ),
                              ButtonSegment(
                                value: CheckoutPaymentMethod.ussd,
                                label: Text('USSD'),
                                icon: Icon(Icons.smartphone_outlined),
                              ),
                            ],
                            selected: {_paymentMethod},
                            onSelectionChanged: (selection) {
                              setState(() => _paymentMethod = selection.first);
                            },
                          ),
                        const SizedBox(height: 12),
                        Text(
                          switch (_paymentMethod) {
                            CheckoutPaymentMethod.card =>
                              'Customer will enter card details on Paystack after redirect.',
                            CheckoutPaymentMethod.bank =>
                              'Customer will choose their bank inside the secure Paystack checkout.',
                            CheckoutPaymentMethod.bankTransfer =>
                              'Paystack will provide the bank transfer instructions inside checkout.',
                            CheckoutPaymentMethod.ussd =>
                              'Paystack will guide the customer through the USSD payment steps.',
                          },
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                                _paymentMethod == CheckoutPaymentMethod.card
                                    ? Icons.verified_user_outlined
                                    : Icons.account_balance_outlined,
                                color: AppColors.champagneGold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                switch (_paymentMethod) {
                                  CheckoutPaymentMethod.card =>
                                    'Secure Paystack checkout. Card details stay on Paystack, not inside the Quiver Lux app.',
                                  CheckoutPaymentMethod.bank =>
                                    'Secure Paystack checkout. Customers can authorize payment from their bank on the hosted Paystack screen.',
                                  CheckoutPaymentMethod.bankTransfer =>
                                    'Secure Paystack checkout. Paystack will show the transfer instructions and still return to Quiver Lux for verification.',
                                  CheckoutPaymentMethod.ussd =>
                                    'Secure Paystack checkout. Paystack will prompt the customer with the USSD instructions after redirect.',
                                },
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ORDER SUMMARY',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Column(
                      children: [
                        ...cartItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item.product.title} x${item.quantity}'),
                                Text(formatNaira(
                                    item.product.price * item.quantity)),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(formatNaira(cartNotifier.subtotal)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated VAT (7.5%)'),
                            Text(formatNaira(cartNotifier.tax)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Lagos metro delivery'),
                            Text(formatNaira(cartNotifier.shipping)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              formatNaira(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.champagneGold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.matteBlack,
                      ),
                      onPressed: _processPayment,
                      child: const Text(
                        'CONTINUE TO PAYSTACK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _paymentMethodLabel(CheckoutPaymentMethod method) {
    switch (method) {
      case CheckoutPaymentMethod.card:
        return 'Card';
      case CheckoutPaymentMethod.bank:
        return 'Bank';
      case CheckoutPaymentMethod.bankTransfer:
        return 'Bank transfer';
      case CheckoutPaymentMethod.ussd:
        return 'USSD';
    }
  }

  IconData _paymentMethodIcon(CheckoutPaymentMethod method) {
    switch (method) {
      case CheckoutPaymentMethod.card:
        return Icons.credit_card_outlined;
      case CheckoutPaymentMethod.bank:
        return Icons.account_balance_wallet_outlined;
      case CheckoutPaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case CheckoutPaymentMethod.ussd:
        return Icons.smartphone_outlined;
    }
  }
}
