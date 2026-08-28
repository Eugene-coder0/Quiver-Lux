import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/widgets/product_image.dart';
import '../../customer/models/order_model.dart';
import '../../customer/models/product_model.dart';
import '../../customer/providers/order_provider.dart';
import '../../vendor/providers/vendor_providers.dart';
import '../models/admin_models.dart';
import '../models/admin_user_model.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAdminData();
    });
  }

  Future<void> _refreshAdminData() async {
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminAnalyticsProvider);
    await Future.wait([
      ref.read(orderProvider.notifier).refresh(),
      ref.read(vendorApplicationsProvider.notifier).load(),
      ref.read(vendorProductsProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(vendorApplicationsProvider);
    final allProducts = ref.watch(vendorProductsProvider);
    final orders = ref.watch(orderProvider);
    final analytics = ref.watch(adminAnalyticsProvider).valueOrNull;
    final usersAsync = ref.watch(adminUsersProvider);

    final pendingApplications =
        applications.where((a) => a.status == ApprovalStatus.pending).length;
    final pendingProducts =
        allProducts.where((p) => p.approvalStatus == 'pending').length;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F5),
        appBar: AppBar(
          backgroundColor: QuiverLuxTheme.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiver Lux Admin Console',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                'Marketplace oversight & verification',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh admin data',
              onPressed: _refreshAdminData,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: QuiverLuxTheme.champagneGold,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 16),
                    const SizedBox(width: 6),
                    const Text('Orders'),
                    if (orders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Badge(
                        backgroundColor: QuiverLuxTheme.champagneGold,
                        textColor: Colors.black,
                        label: Text('${orders.length}'),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Products'),
                    if (pendingProducts > 0) ...[
                      const SizedBox(width: 6),
                      Badge(
                        backgroundColor: Colors.amberAccent,
                        textColor: Colors.black,
                        label: Text('$pendingProducts'),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.storefront_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Vendors'),
                    if (pendingApplications > 0) ...[
                      const SizedBox(width: 6),
                      Badge(
                        backgroundColor: Colors.amberAccent,
                        textColor: Colors.black,
                        label: Text('$pendingApplications'),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 16),
                    SizedBox(width: 6),
                    Text('Accounts'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _AdminStatsGrid(
                analytics: analytics,
                products: allProducts,
                orders: orders,
                pendingProductCount: pendingProducts,
                pendingVendorCount: pendingApplications,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAdminData,
                child: TabBarView(
                  children: [
                    _AdminOrdersTab(orders: orders),
                    _AdminProductsTab(products: allProducts),
                    _VendorApplicationsTab(applications: applications),
                    _AdminUsersTab(usersAsync: usersAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatsGrid extends StatelessWidget {
  final AdminAnalyticsModel? analytics;
  final List<ProductModel> products;
  final List<OrderModel> orders;
  final int pendingProductCount;
  final int pendingVendorCount;

  const _AdminStatsGrid({
    this.analytics,
    required this.products,
    required this.orders,
    required this.pendingProductCount,
    required this.pendingVendorCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalCustomers = analytics?.totalCustomers ?? 0;
    final totalVendors = analytics?.totalVendors ?? 0;
    final totalProducts = analytics?.totalProducts ?? products.length;
    final totalOrders = analytics?.totalOrders ?? orders.length;
    final totalCustomerSignIns = analytics?.totalCustomerSignIns ?? 0;
    final totalCommission =
        analytics?.totalPlatformCommission ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
                ? 2
                : 1;
        final spacing = 12.0;
        final double cardWidth = crossAxisCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _StatCard(
              title: 'Customer Sign-ins',
              value: '$totalCustomerSignIns',
              subtitle: '$totalCustomers total customers',
              icon: Icons.login_outlined,
              color: Colors.indigo,
              width: cardWidth,
            ),
            _StatCard(
              title: 'Vendors',
              value: '$totalVendors',
              subtitle: '$pendingVendorCount awaiting review',
              icon: Icons.storefront_outlined,
              color: Colors.amber.shade800,
              width: cardWidth,
            ),
            _StatCard(
              title: 'Catalog & Orders',
              value: '$totalProducts products',
              subtitle: '$totalOrders marketplace orders',
              icon: Icons.storefront_outlined,
              color: Colors.blue,
              width: cardWidth,
            ),
            _StatCard(
              title: 'Platform Commission',
              value: formatNaira(totalCommission),
              subtitle: '$pendingProductCount products pending approval',
              icon: Icons.account_balance_wallet_outlined,
              color: pendingProductCount > 0 ? Colors.redAccent : Colors.purple,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: QuiverLuxTheme.matteBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 1. Orders Tab - Synchronized with orderProvider
class _AdminOrdersTab extends ConsumerWidget {
  final List<OrderModel> orders;

  const _AdminOrdersTab({required this.orders});

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

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.processing:
        return 'Preparing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.successful:
        return 'Delivered';
    }
  }

  Color _paymentColor(OrderModel order) {
    if (order.paymentStatus == 'success') {
      return Colors.green.shade700;
    }
    if (order.paymentStatus == 'failed') {
      return Colors.red.shade700;
    }
    return Colors.amber.shade800;
  }

  Future<void> _showAdminOrderUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    OrderStatus initialStatus,
  ) async {
    final noteController = TextEditingController(text: order.trackingNote);
    final trackingController =
        TextEditingController(text: order.trackingNumber);
    OrderStatus selectedStatus = initialStatus;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Update order ${order.orderId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<OrderStatus>(
                initialValue: selectedStatus,
                items: OrderStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedStatus = value);
                  }
                },
                decoration:
                    const InputDecoration(labelText: 'Fulfillment status'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trackingController,
                decoration:
                    const InputDecoration(labelText: 'Tracking number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Tracking note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(orderProvider.notifier).updateOrderStatus(
            order.vendorOrderId,
            selectedStatus,
            trackingNote: noteController.text.trim(),
            trackingNumber: trackingController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated successfully.')),
        );
      }
    }

    noteController.dispose();
    trackingController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No platform orders recorded yet.',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
            const SizedBox(height: 4),
            const Text(
              'Orders placed by customers will automatically sync here in real time.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final sortedOrders = List<OrderModel>.from(orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedOrders.length,
      itemBuilder: (context, index) {
        final order = sortedOrders[index];
        final formattedDate =
            DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt);
        final color = _statusColor(order.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: QuiverLuxTheme.matteBlack,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(order.status),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _paymentColor(order).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Payment ${order.paymentStatus.toUpperCase()}',
                        style: TextStyle(
                          color: _paymentColor(order),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Vendor ${order.vendorName}',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Method ${order.paymentMethodLabel}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_outlined,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress.isNotEmpty
                            ? order.deliveryAddress
                            : 'Standard Delivery',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(
                      'Customer: ${order.customerName}${order.customerEmail.isNotEmpty ? ' • ${order.customerEmail}' : ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
                if (order.customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${order.customerPhone}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.product.title,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatNaira(item.product.price * item.quantity),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                if (order.trackingNumber.isNotEmpty || order.trackingNote.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.trackingNumber.isNotEmpty)
                          Text(
                            'Tracking #: ${order.trackingNumber}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        if (order.trackingNote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.trackingNote,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (order.trackingNumber.isNotEmpty || order.trackingNote.isNotEmpty)
                  const SizedBox(height: 10),
                if (order.isManualBankTransfer && !order.isPaid) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transfer account: ${order.paystackAccountName}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Account number: ${order.paystackAccountNumber}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black87),
                        ),
                        Text(
                          'Bank code: ${order.paystackBankCode}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vendor earnings: ${formatNaira(order.vendorEarnings)}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                    Text(
                      'Commission: ${formatNaira(order.commissionAmount)}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        if (order.isManualBankTransfer && !order.isPaid)
                          FilledButton.tonalIcon(
                            onPressed: () => ref
                                .read(orderProvider.notifier)
                                .confirmManualPayment(order.vendorOrderId),
                            icon: const Icon(Icons.verified_outlined, size: 16),
                            label: const Text('Confirm payment'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _showAdminOrderUpdateDialog(
                            context,
                            ref,
                            order,
                            order.status,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Override order'),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ${formatNaira(order.totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: QuiverLuxTheme.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 2. Product Approvals Tab - Synchronized with vendorProductsProvider
class _AdminProductsTab extends ConsumerWidget {
  final List<ProductModel> products;

  const _AdminProductsTab({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) {
      return const Center(child: Text('No products available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isPending = product.approvalStatus == 'pending';
        final isApproved = product.approvalStatus == 'approved';
        final isRejected = product.approvalStatus == 'rejected';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          imageBytes: product.imageBytes,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _ProductStatusBadge(
                                  status: product.approvalStatus),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vendor: ${product.vendorName}',
                            style: const TextStyle(
                              color: QuiverLuxTheme.forest,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${product.category} • ${formatNaira(product.price)} • Stock: ${product.stockQuantity}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPending || isApproved)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          ref
                              .read(vendorProductsProvider.notifier)
                              .rejectProduct(product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${product.title} has been rejected from customer storefront.'),
                            ),
                          );
                        },
                        child: const Text('Reject / Delist',
                            style: TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(width: 8),
                    if (isPending || isRejected)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QuiverLuxTheme.forest,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          ref
                              .read(vendorProductsProvider.notifier)
                              .approveProduct(product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${product.title} is now APPROVED and live on customer storefront!'),
                            ),
                          );
                        },
                        child: const Text(
                          'Approve & Publish',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductStatusBadge extends StatelessWidget {
  final String status;

  const _ProductStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Approved';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Pending Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 3. Vendor Requests Tab - Synchronized with vendorApplicationsProvider and user accounts
class _VendorApplicationsTab extends ConsumerWidget {
  final List<VendorApplication> applications;

  const _VendorApplicationsTab({required this.applications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (applications.isEmpty) {
      return const Center(
        child: Text(
          'No vendor applications received yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        final isPending = app.status == ApprovalStatus.pending;
        final formattedDate = DateFormat('dd MMM yyyy').format(app.appliedDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        app.storeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: QuiverLuxTheme.matteBlack,
                        ),
                      ),
                    ),
                    _StatusChip(status: app.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Owner: ${app.ownerName} • Email: ${app.email}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Category: ${app.category} • Applied on $formattedDate',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                if (app.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '“${app.description}”',
                      style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87),
                    ),
                  ),
                ],
                if (isPending) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () async {
                          await ref
                              .read(vendorApplicationsProvider.notifier)
                              .rejectApplication(app.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Application for ${app.storeName} rejected.',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Reject Application'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QuiverLuxTheme.forest,
                        ),
                        onPressed: () async {
                          await ref
                              .read(vendorApplicationsProvider.notifier)
                              .approveApplication(app.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${app.storeName} APPROVED! User promoted to Vendor with Vendor Studio access.',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Approve & Promote',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminUsersTab extends StatelessWidget {
  final AsyncValue<List<AdminUserModel>> usersAsync;

  const _AdminUsersTab({required this.usersAsync});

  @override
  Widget build(BuildContext context) {
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (users) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = users[index];
          final role = user.role == 'vendor' ? 'Vendor' : 'Customer';
          final status = user.vendorStatus == 'pending'
              ? 'Vendor application pending'
              : user.vendorStatus == 'approved'
                  ? 'Vendor approved'
                  : role;
          return ListTile(
            tileColor: Colors.white,
            leading: CircleAvatar(
              backgroundColor: QuiverLuxTheme.softGray,
              child: Icon(
                user.role == 'vendor'
                    ? Icons.storefront_outlined
                    : Icons.person_outline,
                color: QuiverLuxTheme.matteBlack,
              ),
            ),
            title: Text(user.name.isEmpty ? user.email : user.name),
            subtitle: Text('${user.email}\n$status'),
            isThreeLine: true,
            trailing: Text(role),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ApprovalStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ApprovalStatus.pending:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Pending Review';
        break;
      case ApprovalStatus.approved:
        bg = Colors.green.shade50;
        fg = Colors.green.shade900;
        label = 'Approved Merchant';
        break;
      case ApprovalStatus.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red.shade900;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

