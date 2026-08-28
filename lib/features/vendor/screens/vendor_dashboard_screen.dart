import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../customer/models/order_model.dart';
import '../../customer/models/product_model.dart';
import '../../customer/providers/order_provider.dart';
import '../providers/vendor_providers.dart';

class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  ConsumerState<VendorDashboardScreen> createState() =>
      _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProductsProvider.notifier).load();
      ref.read(orderProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(vendorProductsProvider);
    final orders = ref.watch(orderProvider);
    final analytics = ref.watch(vendorAnalyticsProvider).valueOrNull;
    final double totalRevenue = analytics?.totalEarnings ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1ED),
      appBar: AppBar(
        backgroundColor: QuiverLuxTheme.forest,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiver LUX',
                style: TextStyle(
                    color: QuiverLuxTheme.champagneGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4)),
            Text('Vendor Studio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh orders and products',
            onPressed: () async {
              await Future.wait([
                ref.read(vendorProductsProvider.notifier).load(),
                ref.read(orderProvider.notifier).refresh(),
              ]);
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Brand settings',
            onPressed: () => _showBrandSettings(context),
            icon: const Icon(Icons.storefront_outlined, color: Colors.white),
          ),
        ],
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: QuiverLuxTheme.champagneGold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Products & Stock (${products.length})'),
              Tab(text: 'Orders (${orders.length})'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Stat Cards
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                final cardWidth = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: QuiverLuxTheme.softGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Store Revenue',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            Text('₦',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatNaira(totalRevenue),
                          style: const TextStyle(
                              color: QuiverLuxTheme.matteBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: QuiverLuxTheme.softGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sold Units',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            Icon(Icons.shopping_bag_outlined,
                                color: QuiverLuxTheme.forest, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${analytics?.totalSoldUnits ?? 0}',
                          style: const TextStyle(
                              color: QuiverLuxTheme.matteBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Products List Tab
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2924),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(item.title,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildApprovalBadge(
                                            item.approvalStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.category} • ${formatNaira(item.price)}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Qty: ${item.stockQuantity}',
                                style: TextStyle(
                                  color: item.stockQuantity > 0
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white70, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => context.push(
                                  '/vendor/products/edit',
                                  extra: item,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Delete listing',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _confirmDelete(item.id, item.title),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt,
                                      color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Feature on Lightning Deals',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                              Switch(
                                value: item.isLightningDeal,
                                activeThumbColor: QuiverLuxTheme.champagneGold,
                                onChanged: (_) => _configureLightningDeal(item),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),

                // Orders List Tab
                orders.isEmpty
                    ? const Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 46, color: Colors.white38),
                          SizedBox(height: 10),
                          Text('New paid orders will appear here.',
                              style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 4),
                          Text('Same ledger as the customer account.',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final allowedStatuses =
                              _availableVendorStatuses(order);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C2924),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('Order #${order.orderId}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: QuiverLuxTheme.champagneGold
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(order.statusLabel,
                                          style: const TextStyle(
                                              color:
                                                  QuiverLuxTheme.champagneGold,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Vendor order ID: ${order.vendorOrderId}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 10),
                                ),
                                const SizedBox(height: 6),
                                Text('Customer: ${order.customerName}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                if (order.customerEmail.isNotEmpty)
                                  Text(order.customerEmail,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                if (order.customerPhone.isNotEmpty)
                                  Text(order.customerPhone,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                const SizedBox(height: 6),
                                Text(
                                  'Payment: ${order.paymentStatus.toUpperCase()}',
                                  style: TextStyle(
                                      color: order.isPaid
                                          ? Colors.greenAccent
                                          : Colors.amberAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Method: ${order.paymentMethodLabel}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  'Fulfillment: ${order.fulfillmentStatus.name.toUpperCase()}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  '${order.itemSummary} • ${formatNaira(order.totalAmount)}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text('Ship to ${order.deliveryAddress}',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                                if (order.trackingNumber.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Tracking #: ${order.trackingNumber}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ],
                                if (order.trackingNote.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(order.trackingNote,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                ],
                                if (order.isManualBankTransfer &&
                                    !order.isPaid) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Transfer account: ${order.paystackAccountName} / ${order.paystackAccountNumber}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _confirmManualPayment(order),
                                    icon: const Icon(Icons.verified, size: 16),
                                    label: const Text('Confirm payment received'),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  order.isPaid
                                      ? 'Update fulfillment'
                                      : 'Awaiting payment verification',
                                  style: TextStyle(
                                      color: order.isPaid
                                          ? Colors.white54
                                          : Colors.amberAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<OrderStatus>(
                                  initialValue: order.status,
                                  dropdownColor: const Color(0xFF2A2A2A),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF15201C),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  items: allowedStatuses
                                      .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                                _vendorStatusLabel(status)),
                                          ))
                                      .toList(),
                                  onChanged: order.isPaid
                                      ? (status) {
                                          if (status == null) return;
                                          _updateTracking(order, status);
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: QuiverLuxTheme.champagneGold,
        onPressed: () => context.push('/vendor/products/new'),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('New Product',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _configureLightningDeal(ProductModel product) async {
    final priceController = TextEditingController(
      text: product.discountPrice?.toStringAsFixed(2) ?? '',
    );
    final durationController = TextEditingController(text: '24');
    final enabled = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lightning deal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'New amount (₦)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (hours)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Remove deal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save deal'),
          ),
        ],
      ),
    );

    if (!mounted) {
      priceController.dispose();
      durationController.dispose();
      return;
    }

    if (enabled == true) {
      final dealPrice = double.tryParse(priceController.text.trim());
      final duration = int.tryParse(durationController.text.trim());
      if (dealPrice == null ||
          dealPrice <= 0 ||
          dealPrice >= product.price ||
          duration == null ||
          duration <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Enter a lower amount and a positive duration.')),
        );
      } else {
        final startsAt = DateTime.now();
        ref.read(vendorProductsProvider.notifier).updateProduct(
              product.copyWith(
                isLightningDeal: true,
                discountPrice: dealPrice,
                offerStartsAt: startsAt,
                offerEndsAt: startsAt.add(Duration(hours: duration)),
              ),
            );
      }
    } else if (enabled == false) {
      ref.read(vendorProductsProvider.notifier).updateProduct(
            product.copyWith(isLightningDeal: false, discountPrice: null),
          );
    }

    priceController.dispose();
    durationController.dispose();
  }

  String _vendorStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed — payment received';
      case OrderStatus.processing:
        return 'Processing — preparing';
      case OrderStatus.shipped:
        return 'Shipped — in transit';
      case OrderStatus.dispatched:
        return 'Out for delivery';
      case OrderStatus.successful:
        return 'Delivered';
    }
  }

  List<OrderStatus> _availableVendorStatuses(OrderModel order) {
    if (!order.isPaid) {
      return [order.status];
    }
    switch (order.fulfillmentStatus) {
      case FulfillmentStatus.pending:
        return [OrderStatus.placed, OrderStatus.processing];
      case FulfillmentStatus.processing:
        return [OrderStatus.processing, OrderStatus.shipped];
      case FulfillmentStatus.shipped:
        return [OrderStatus.shipped, OrderStatus.successful];
      case FulfillmentStatus.delivered:
        return [OrderStatus.successful];
      case FulfillmentStatus.cancelled:
        return [OrderStatus.placed];
    }
  }

  Future<void> _updateTracking(OrderModel order, OrderStatus status) async {
    final note = TextEditingController(
      text: order.trackingNote.isNotEmpty
          ? order.trackingNote
          : _defaultNote(status),
    );
    final trackingNumber = TextEditingController(text: order.trackingNumber);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update customer tracking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'This will show on the customer account as ${_vendorStatusLabel(status)}.'),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note the customer will see',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackingNumber,
              decoration: const InputDecoration(
                labelText: 'Tracking number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send update'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(orderProvider.notifier).updateOrderStatus(
            order.vendorOrderId,
            status,
            trackingNote: note.text.trim(),
            trackingNumber: trackingNumber.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tracking updated. The customer can see this on their account.'),
        ),
      );
    }
    note.dispose();
    trackingNumber.dispose();
  }

  Future<void> _confirmManualPayment(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm bank transfer'),
        content: Text(
          'Mark order ${order.orderId} as paid after verifying the transfer in the vendor account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm payment'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(orderProvider.notifier).confirmManualPayment(
            order.vendorOrderId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment confirmed for this order.')),
      );
    }
  }

  String _defaultNote(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Payment confirmed. We have your order.';
      case OrderStatus.processing:
        return 'Your pieces are being prepared in the studio.';
      case OrderStatus.shipped:
        return 'Your order has left the warehouse.';
      case OrderStatus.dispatched:
        return 'A courier is bringing your order today.';
      case OrderStatus.successful:
        return 'Delivered. Thank you for shopping Quiver Lux.';
    }
  }

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove listing?'),
        content: Text('“$title” will be removed from your storefront.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(vendorProductsProvider.notifier).deleteProduct(id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Listing removed')));
    }
  }

  Widget _buildApprovalBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = Colors.green.shade900.withValues(alpha: 0.3);
        fg = Colors.greenAccent;
        label = 'Approved';
        break;
      case 'rejected':
        bg = Colors.red.shade900.withValues(alpha: 0.3);
        fg = Colors.redAccent;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        bg = Colors.amber.shade900.withValues(alpha: 0.3);
        fg = Colors.amberAccent;
        label = 'Pending Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showBrandSettings(BuildContext context) {
    final controller =
        TextEditingController(text: ref.read(vendorBrandProvider));
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('BRAND SETTINGS',
              style:
                  TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Store name')),
          const SizedBox(height: 8),
          const Text('Store identity is synced from your vendor profile.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(vendorBrandProvider.notifier)
                        .update(controller.text);
                    Navigator.pop(context);
                  },
                  child: const Text('SAVE SETTINGS'))),
        ]),
      ),
    );
  }
}
