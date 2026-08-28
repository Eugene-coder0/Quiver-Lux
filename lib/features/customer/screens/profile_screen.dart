import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/widgets/product_image.dart';
import '../../../providers/api_provider.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order_model.dart';
import '../providers/account_profile_provider.dart';
import '../providers/order_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return const Color(0xFFC27A1A);
      case OrderStatus.processing:
        return const Color(0xFF6A4C93);
      case OrderStatus.shipped:
        return const Color(0xFF1D6FA3);
      case OrderStatus.dispatched:
        return const Color(0xFF2C4C9C);
      case OrderStatus.successful:
        return const Color(0xFF2E7D4F);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final account = ref.watch(accountProfileProvider);
    final orders = ref.watch(orderProvider);
    final userName = account.fullName.trim().isNotEmpty
        ? account.fullName.trim()
        : (auth.user?.name ?? 'Quiver Lux Member');
    final email = auth.user?.email ?? 'Sign in to save your account';
    final pendingPaymentCount =
        orders.where((order) => order.isPendingPayment).length;
    final delivered =
        orders.where((order) => order.status == OrderStatus.successful).length;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1ED),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: QuiverLuxTheme.forest,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: const Text('Your account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                onPressed: () => ref.read(orderProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Keep shopping',
                    style: TextStyle(color: Color(0xFFF5D99B))),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 16,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MemberCard(
                    name: userName,
                    email: email,
                    signedIn: auth.isAuthenticated,
                    onEdit: () => _editProfile(context, ref, userName),
                    onSignIn: () => context.go('/login'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Orders',
                          value: '${orders.length}',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Awaiting payment',
                          value: '$pendingPaymentCount',
                          icon: Icons.local_shipping_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Delivered',
                          value: '$delivered',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Your shortcuts',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: wide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: wide ? 2.2 : 2.05,
                    children: [
                      _Shortcut(
                        icon: Icons.inventory_2_outlined,
                        title: 'Your orders',
                        subtitle: orders.isEmpty
                            ? 'No purchases yet'
                            : '${orders.length} order update(s)',
                        onTap: () => context.push('/order-tracking'),
                      ),
                      _Shortcut(
                        icon: Icons.location_on_outlined,
                        title: 'Addresses',
                        subtitle: account.address,
                        onTap: () => _editAddress(context, ref),
                      ),
                      _Shortcut(
                        icon: Icons.credit_card_outlined,
                        title: 'Payments',
                        subtitle: 'Paystack checkout',
                        onTap: () => _showInfo(
                          context,
                          'Payment methods',
                          'Checkout is Paystack-ready. Cards are entered securely at payment — we do not store card numbers on this device.',
                        ),
                      ),
                      _Shortcut(
                        icon: Icons.support_agent_outlined,
                        title: 'Help',
                        subtitle: 'Concierge & returns',
                        onTap: () => _showInfo(
                          context,
                          'Quiver Lux concierge',
                          'Need help with a delivery? Open any order and share the order number with support. Tracking is updated live by the vendor.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _VendorPortalCard(
                    role: auth.user?.role ?? 'customer',
                    vendorStatus: auth.user?.vendorStatus ?? 'none',
                    onApply: () => _showVendorApplicationDialog(context, ref),
                    onOpenVendorStudio: () => context.push('/vendor'),
                    onOpenAdminConsole: () => context.push('/admin'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Order history & tracking',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      if (orders.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push('/order-tracking'),
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pendingPaymentCount > 0
                        ? 'Orders awaiting Paystack confirmation appear here alongside paid order updates.'
                        : 'Order activity appears here and tracking updates show as vendors move each package.',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (orders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 42, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text('No orders yet',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text(
                            'When you complete checkout, this becomes your order history.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () => context.go('/'),
                            child: const Text('Start shopping'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OrderCard(
                          order: order,
                          statusColor: _statusColor(order.status),
                          onOpen: () =>
                              _showOrderDetails(context, ref, order.orderId),
                          onTrack: () => context.push('/order-tracking'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery details',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.home_outlined),
                          title: Text(account.address),
                          subtitle: Text(account.phone),
                          trailing: TextButton(
                            onPressed: () => _editAddress(context, ref),
                            child: const Text('Edit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Sign out',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVendorApplicationDialog(
      BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);
    final account = ref.read(accountProfileProvider);
    List<Map<String, String>> banks;
    try {
      final banksResponse =
          await ref.read(apiClientProvider).get(ApiEndpoints.paystackBanks);
      if (!context.mounted) return;
      final banksData =
          banksResponse.data['data'] as Map<String, dynamic>? ?? const {};
      banks = (banksData['banks'] as List<dynamic>? ?? const [])
          .map(
            (item) => (item as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                value?.toString() ?? '',
              ),
            ),
          )
          .where((bank) => (bank['code'] ?? '').isNotEmpty)
          .toList()
        ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open vendor application: $error')),
      );
      return;
    }
    final storeNameController = TextEditingController();
    final ownerNameController =
        TextEditingController(text: auth.user?.name ?? '');
    final emailController =
        TextEditingController(text: auth.user?.email ?? '');
    final phoneController = TextEditingController(text: account.phone);
    final businessAddressController = TextEditingController();
    final descController = TextEditingController();
    final paystackBusinessController = TextEditingController();
    final paystackAccountNameController = TextEditingController();
    final paystackAccountNumberController = TextEditingController();
    String selectedCat = 'Clothing';
    String? selectedBankCode;
    bool isVerifyingAccount = false;
    String paystackStatus = 'Pending';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        color: QuiverLuxTheme.forest, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Apply to Become a Vendor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: QuiverLuxTheme.matteBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sell your luxury collections on Quiver Lux. Applications are reviewed by platform administrators.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store / Brand Name *',
                    hintText: 'e.g. Atelier Noir Luxury',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Representative Full Name *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Business Contact Email *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Business Phone Number *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: businessAddressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Business Address *',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(
                    labelText: 'Primary Product Category',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Clothing', child: Text('Clothing')),
                    DropdownMenuItem(
                        value: 'Home Accessories',
                        child: Text('Home Accessories')),
                    DropdownMenuItem(
                        value: 'Footwear', child: Text('Footwear')),
                    DropdownMenuItem(
                        value: 'Jewelry', child: Text('Jewelry')),
                    DropdownMenuItem(value: 'Bags', child: Text('Bags')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Brand Profile & Craftsmanship Story',
                    hintText: 'Tell us about your materials, origin, and offerings.',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paystack Settlement Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: QuiverLuxTheme.matteBlack,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the settlement bank, verify the account name, and Quiver Lux will create and manage the vendor Paystack subaccount.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paystackBusinessController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedBankCode,
                  decoration: const InputDecoration(
                    labelText: 'Settlement Bank',
                  ),
                  items: banks
                      .map(
                        (bank) => DropdownMenuItem(
                          value: bank['code'],
                          child: Text(
                            bank['name'] ?? 'Bank',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) => banks
                      .map(
                        (bank) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            bank['name'] ?? 'Bank',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setModalState(() {
                      selectedBankCode = value;
                      paystackAccountNameController.clear();
                      paystackStatus = 'Pending';
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paystackAccountNumberController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (paystackStatus == 'Verified') {
                      setModalState(() {
                        paystackAccountNameController.clear();
                        paystackStatus = 'Pending';
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Settlement Account Number',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: paystackAccountNameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Verified Account Name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isVerifyingAccount
                          ? null
                          : () async {
                              final accountNumber =
                                  paystackAccountNumberController.text.trim();
                              if ((selectedBankCode ?? '').isEmpty ||
                                  accountNumber.length < 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Choose a bank and enter a valid account number first.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() {
                                isVerifyingAccount = true;
                                paystackStatus = 'Verifying';
                              });
                              try {
                                final verifyResponse = await ref
                                    .read(apiClientProvider)
                                    .post(
                                  ApiEndpoints.paystackVerifyAccount,
                                  data: {
                                    'bankCode': selectedBankCode,
                                    'accountNumber': accountNumber,
                                  },
                                );
                                final verifyData = verifyResponse.data['data']
                                        as Map<String, dynamic>? ??
                                    const {};
                                setModalState(() {
                                  paystackAccountNameController.text =
                                      verifyData['accountName']?.toString() ??
                                          '';
                                  paystackStatus = 'Verified';
                                });
                              } catch (error) {
                                setModalState(() {
                                  paystackStatus = 'Failed';
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              } finally {
                                setModalState(() {
                                  isVerifyingAccount = false;
                                });
                              }
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label:
                          Text(isVerifyingAccount ? 'Verifying' : 'Verify'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: paystackStatus == 'Verified'
                        ? Colors.green.shade50
                        : paystackStatus == 'Failed'
                            ? Colors.red.shade50
                            : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: paystackStatus == 'Verified'
                          ? Colors.green.shade200
                          : paystackStatus == 'Failed'
                              ? Colors.red.shade200
                              : Colors.amber.shade200,
                    ),
                  ),
                  child: Text(
                    'Paystack Status: $paystackStatus',
                    style: TextStyle(
                      color: paystackStatus == 'Verified'
                          ? Colors.green.shade900
                          : paystackStatus == 'Failed'
                              ? Colors.red.shade900
                              : Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuiverLuxTheme.forest,
                    ),
                    onPressed: () async {
                      final store = storeNameController.text.trim();
                      final owner = ownerNameController.text.trim();
                      final email = emailController.text.trim();
                      final phone = phoneController.text.trim();
                      final businessAddress =
                          businessAddressController.text.trim();
                      final paymentBusinessName =
                          paystackBusinessController.text.trim();
                      final accountNumber =
                          paystackAccountNumberController.text.trim();
                      if (store.isEmpty ||
                          owner.isEmpty ||
                          email.isEmpty ||
                          phone.isEmpty ||
                          businessAddress.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields.'),
                          ),
                        );
                        return;
                      }
                      if (paymentBusinessName.isEmpty ||
                          (selectedBankCode ?? '').isEmpty ||
                          accountNumber.length < 10 ||
                          paystackAccountNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Complete the bank verification before submitting.',
                            ),
                          ),
                        );
                        return;
                      }

                      final application = VendorApplication(
                        id: 'v_app_${DateTime.now().millisecondsSinceEpoch}',
                        storeName: store,
                        ownerName: owner,
                        email: email,
                        category: selectedCat,
                        description: descController.text.trim(),
                        phone: phone,
                        businessAddress: businessAddress,
                        paystackBusinessName:
                            paymentBusinessName,
                        paystackAccountName:
                            paystackAccountNameController.text.trim(),
                        paystackAccountNumber: accountNumber,
                        paystackBankCode: selectedBankCode ?? '',
                        appliedDate: DateTime.now(),
                        status: ApprovalStatus.pending,
                      );

                      try {
                        await ref
                            .read(vendorApplicationsProvider.notifier)
                            .submitApplication(application);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Application submitted! Platform admin will review shortly.',
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'SUBMIT APPLICATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account name',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await ref
          .read(accountProfileProvider.notifier)
          .update(fullName: controller.text.trim());
    }
    controller.dispose();
  }

  Future<void> _editAddress(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountProfileProvider);
    final address = TextEditingController(text: account.address);
    final phone = TextEditingController(text: account.phone);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery address',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save address'),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await ref.read(accountProfileProvider.notifier).update(
            address: address.text.trim(),
            phone: phone.text.trim(),
          );
    }
    address.dispose();
    phone.dispose();
  }

  void _showInfo(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, WidgetRef ref, String orderId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Consumer(
        builder: (context, ref, __) {
          final orders = ref.watch(orderProvider);
          final order = orders.firstWhere(
            (item) => item.orderId == orderId,
            orElse: () => orders.isEmpty
                ? OrderModel(
                    id: orderId,
                    orderId: orderId,
                    vendorOrderId: orderId,
                    items: const [],
                    totalAmount: 0,
                    deliveryAddress: '',
                    createdAt: DateTime.now(),
                    status: OrderStatus.placed,
                  )
                : orders.first,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.orderId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(order.statusLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(order.statusHint,
                      style: const TextStyle(color: Colors.black54)),
                  if (order.trackingNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Vendor update: ${order.trackingNote}'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _OrderProgress(status: order.status),
                  const Divider(height: 28),
                  ...order.items.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: ProductImage(
                            imageUrl: item.product.imageUrl,
                            imageBytes: item.product.imageBytes,
                          ),
                        ),
                      ),
                      title: Text(item.product.title),
                      subtitle: Text(
                          '${item.product.vendorName} • ×${item.quantity}'),
                      trailing: Text(formatNaira(item.totalPrice)),
                    ),
                  ),
                  const Divider(),
                  Text('Ship to ${order.deliveryAddress}'),
                  if (order.customerPhone.isNotEmpty)
                    Text('Phone ${order.customerPhone}'),
                  const SizedBox(height: 8),
                  Text('Total ${formatNaira(order.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String email;
  final bool signedIn;
  final VoidCallback onEdit;
  final VoidCallback onSignIn;

  const _MemberCard({
    required this.name,
    required this.email,
    required this.signedIn,
    required this.onEdit,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [QuiverLuxTheme.forest, Color(0xFF245848)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFF5D99B),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'Q',
              style: const TextStyle(
                color: QuiverLuxTheme.forest,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HELLO',
                    style: TextStyle(
                        color: Color(0xFFF5D99B),
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold)),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                const Text('Quiver Lux Member · Secure checkout',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: signedIn ? onEdit : onSignIn,
            child: Text(signedIn ? 'Edit' : 'Sign in',
                style: const TextStyle(color: Color(0xFFF5D99B))),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: QuiverLuxTheme.forest),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: QuiverLuxTheme.forest),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Color statusColor;
  final VoidCallback onOpen;
  final VoidCallback onTrack;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.onOpen,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM y · h:mm a').format(order.createdAt);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Order #${order.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(order.statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(date,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: ProductImage(
                          imageUrl: item.product.imageUrl,
                          imageBytes: item.product.imageBytes,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(order.itemSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
              Text(
                '${order.items.fold<int>(0, (sum, item) => sum + item.quantity)} item(s) • ${formatNaira(order.totalAmount)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              if (order.trackingNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Update: ${order.trackingNote}',
                    style: const TextStyle(
                        fontSize: 12, color: QuiverLuxTheme.forest)),
              ],
              const SizedBox(height: 12),
              _OrderProgress(status: order.status),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpen,
                      child: const Text('View details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTrack,
                      child: const Text('Track package'),
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

class _OrderProgress extends StatelessWidget {
  final OrderStatus status;
  const _OrderProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Placed',
      'Preparing',
      'Shipped',
      'Out for delivery',
      'Delivered'
    ];
    final step = status.index;
    return Row(
      children: List.generate(5, (index) {
        final done = index <= step;
        return Expanded(
          child: Column(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: done ? QuiverLuxTheme.forest : Colors.grey.shade400,
              ),
              const SizedBox(height: 3),
              Text(labels[index],
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                      color: done ? Colors.black87 : Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }),
    );
  }
}

class _VendorPortalCard extends StatelessWidget {
  final String role;
  final String vendorStatus;
  final VoidCallback onApply;
  final VoidCallback onOpenVendorStudio;
  final VoidCallback onOpenAdminConsole;

  const _VendorPortalCard({
    required this.role,
    required this.vendorStatus,
    required this.onApply,
    required this.onOpenVendorStudio,
    required this.onOpenAdminConsole,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final isVendor = role == 'vendor' || vendorStatus == 'approved';
    final isPending = vendorStatus == 'pending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QuiverLuxTheme.softGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAdmin
                    ? Icons.verified_user_outlined
                    : Icons.storefront_outlined,
                color: QuiverLuxTheme.forest,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isAdmin
                    ? 'Administrator Access'
                    : isVendor
                        ? 'Merchant Partner Status'
                        : 'Sell on Quiver Lux',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (isPending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Under Review',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'You have marketplace oversight permissions to manage applications, approvals, and order tracking.'
                : isVendor
                    ? 'Your vendor account is active. Manage listings, stock, and fulfill customer orders in the studio.'
                    : isPending
                        ? 'Your vendor application has been received and is awaiting administrator verification.'
                        : 'Join verified luxury artisans and stores across Nigeria. Apply today to showcase your collections.',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (isAdmin)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuiverLuxTheme.forest,
                    ),
                    onPressed: onOpenAdminConsole,
                    icon: const Icon(Icons.admin_panel_settings_outlined,
                        size: 16, color: Colors.white),
                    label: const Text('Admin Console',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenVendorStudio,
                    icon: const Icon(Icons.storefront_outlined, size: 16),
                    label: const Text('Vendor Studio',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          else if (isVendor)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuiverLuxTheme.forest,
                ),
                onPressed: onOpenVendorStudio,
                icon: const Icon(Icons.storefront_outlined,
                    size: 16, color: Colors.white),
                label: const Text('OPEN VENDOR STUDIO',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            )
          else if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Application submitted. We will notify you once approved.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuiverLuxTheme.forest,
                ),
                onPressed: onApply,
                child: const Text(
                  'APPLY TO BECOME A VENDOR',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
