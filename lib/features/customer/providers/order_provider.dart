import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../providers/api_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order_model.dart';

class OrderNotifier extends StateNotifier<List<OrderModel>> {
  OrderNotifier(this.ref) : super(const []) {
    load();
  }

  final Ref ref;

  Future<void> load() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      state = const [];
      return;
    }

    final path = user.role == 'admin' || user.role == 'vendor'
        ? ApiEndpoints.portalOrders
        : ApiEndpoints.customerOrders;

    try {
      final response = await ref.read(apiClientProvider).get(path);
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final orders = (data['orders'] as List<dynamic>? ?? const [])
          .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = orders;
    } catch (_) {
      state = const [];
    }
  }

  Future<void> refresh() async {
    await load();
  }

  void reset() {
    state = const [];
  }

  Future<Map<String, dynamic>> verifyPayment(String reference) async {
    final response = await ref.read(apiClientProvider).get(
      ApiEndpoints.verifyOrderPayment,
      queryParameters: {'reference': reference},
    );
    await load();
    final data = response.data['data'] as Map<String, dynamic>? ?? const {};
    return Map<String, dynamic>.from(data);
  }

  Future<void> confirmManualPayment(String vendorOrderId) async {
    await ref.read(apiClientProvider).post(
      ApiEndpoints.confirmPortalOrderPayment(vendorOrderId),
    );
    await load();
  }

  Future<void> updateOrderStatus(
    String vendorOrderId,
    OrderStatus status, {
    String? trackingNote,
    String? trackingNumber,
  }) async {
    final apiStatus = switch (status) {
      OrderStatus.placed => 'PENDING',
      OrderStatus.processing => 'PROCESSING',
      OrderStatus.shipped => 'SHIPPED',
      OrderStatus.dispatched => 'SHIPPED',
      OrderStatus.successful => 'DELIVERED',
    };

    await ref.read(apiClientProvider).patch(
      '${ApiEndpoints.portalOrders}/$vendorOrderId',
      data: {
        'status': apiStatus,
        if (trackingNote != null) 'trackingNote': trackingNote,
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
      },
    );
    await load();
  }
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  final notifier = OrderNotifier(ref);
  ref.listen<String?>(
    authProvider.select((state) {
      final user = state.user;
      return user == null ? null : '${user.id}:${user.role}:${user.vendorStatus}';
    }),
    (_, __) {
      notifier.reset();
      notifier.load();
    },
  );
  return notifier;
});
