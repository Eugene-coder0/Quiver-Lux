import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/widgets/product_image.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);
    final pendingPaymentOrders = orders.where((order) => order.isPendingPayment).toList();
    final activeOrders = orders.where((order) => !order.isPendingPayment).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: QuiverLuxTheme.matteBlack,
        title: const Text('Track my orders',
            style: TextStyle(color: QuiverLuxTheme.champagneGold)),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: () => ref.read(orderProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: orders.isEmpty
          ? const Center(child: Text('No order activity yet.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingPaymentOrders.isNotEmpty) ...[
                  const Text(
                    'Awaiting payment confirmation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...pendingPaymentOrders.map((order) => _OrderCard(order: order)),
                  const SizedBox(height: 16),
                ],
                if (activeOrders.isNotEmpty) ...[
                  const Text(
                    'Paid and fulfilled orders',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...activeOrders.map((order) => _OrderCard(order: order)),
                ],
              ],
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final currentStep = order.statusStep;
    final isCancelled = order.isCancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  'Order #${order.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(order),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.statusHint, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '${order.items.length} item(s) - ${formatNaira(order.totalAmount)}',
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Payment method: ${order.paymentMethodLabel}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (order.isManualBankTransfer && order.isPendingPayment) ...[
            const SizedBox(height: 8),
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
                    'Transfer to: ${order.paystackAccountName}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('Account number: ${order.paystackAccountNumber}',
                      style: const TextStyle(fontSize: 12)),
                  Text('Bank code: ${order.paystackBankCode}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
          if (order.trackingNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tracking #: ${order.trackingNumber}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
          if (order.trackingNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Vendor: ${order.trackingNote}',
              style: const TextStyle(color: QuiverLuxTheme.forest, fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Ordered ${DateFormat('d MMM y, h:mm a').format(order.createdAt)}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ProductImage(
                        imageUrl: item.product.imageUrl,
                        imageBytes: item.product.imageBytes,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.product.title} x${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          if (isCancelled)
            const Text(
              'This order was cancelled before delivery.',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            )
          else
            Row(
              children: [
                _buildStepCircle(0, currentStep, 'Payment'),
                _buildStepLine(0, currentStep),
                _buildStepCircle(1, currentStep, 'Paid'),
                _buildStepLine(1, currentStep),
                _buildStepCircle(2, currentStep, 'Processing'),
                _buildStepLine(2, currentStep),
                _buildStepCircle(3, currentStep, 'Shipped'),
                _buildStepLine(3, currentStep),
                _buildStepCircle(4, currentStep, 'Delivered'),
              ],
            ),
        ],
      ),
    );
  }

  static Color _statusColor(OrderModel order) {
    if (order.isCancelled) {
      return Colors.redAccent;
    }
    if (order.isPendingPayment) {
      return order.paymentStatus == 'failed'
          ? Colors.redAccent
          : const Color(0xFFC27A1A);
    }
    if (order.lifecycleStatus == 'paid') {
      return const Color(0xFF6A4C93);
    }
    switch (order.status) {
      case OrderStatus.placed:
        return const Color(0xFFC27A1A);
      case OrderStatus.processing:
        return const Color(0xFF2C4C9C);
      case OrderStatus.shipped:
        return const Color(0xFF1D6FA3);
      case OrderStatus.dispatched:
        return const Color(0xFF2C4C9C);
      case OrderStatus.successful:
        return const Color(0xFF2E7D4F);
    }
  }

  static Widget _buildStepCircle(int step, int currentStep, String label) {
    final bool isDone = step <= currentStep;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor:
              isDone ? QuiverLuxTheme.matteBlack : Colors.grey.shade300,
          child: isDone
              ? const Icon(Icons.check, size: 12, color: QuiverLuxTheme.champagneGold)
              : Text('${step + 1}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  static Widget _buildStepLine(int step, int currentStep) {
    final bool isDone = step < currentStep;
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? QuiverLuxTheme.matteBlack : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }
}
