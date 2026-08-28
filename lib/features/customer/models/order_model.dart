import 'cart_item_model.dart';

enum OrderStatus { placed, processing, shipped, dispatched, successful }

enum FulfillmentStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderModel {
  final String id;
  final String orderId;
  final String vendorOrderId;
  final List<CartItemModel> items;
  final double totalAmount;
  final String deliveryAddress;
  final DateTime createdAt;
  final OrderStatus status;
  final String lifecycleStatus;
  final FulfillmentStatus fulfillmentStatus;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String trackingNote;
  final String trackingNumber;
  final DateTime? statusUpdatedAt;
  final String paymentStatus;
  final String paymentMethod;
  final String vendorName;
  final String paystackBusinessName;
  final String paystackAccountName;
  final String paystackAccountNumber;
  final String paystackBankCode;
  final double vendorEarnings;
  final double commissionAmount;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.vendorOrderId,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.createdAt,
    required this.status,
    this.lifecycleStatus = 'payment_pending',
    this.fulfillmentStatus = FulfillmentStatus.pending,
    this.customerName = 'Guest shopper',
    this.customerEmail = '',
    this.customerPhone = '',
    this.trackingNote = '',
    this.trackingNumber = '',
    this.statusUpdatedAt,
    this.paymentStatus = 'pending',
    this.paymentMethod = 'card',
    this.vendorName = 'Quiver Lux Vendor',
    this.paystackBusinessName = '',
    this.paystackAccountName = '',
    this.paystackAccountNumber = '',
    this.paystackBankCode = '',
    this.vendorEarnings = 0,
    this.commissionAmount = 0,
  });

  OrderModel copyWith({
    String? id,
    String? orderId,
    String? vendorOrderId,
    List<CartItemModel>? items,
    double? totalAmount,
    String? deliveryAddress,
    DateTime? createdAt,
    OrderStatus? status,
    String? lifecycleStatus,
    FulfillmentStatus? fulfillmentStatus,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? trackingNote,
    String? trackingNumber,
    DateTime? statusUpdatedAt,
    String? paymentStatus,
    String? paymentMethod,
    String? vendorName,
    String? paystackBusinessName,
    String? paystackAccountName,
    String? paystackAccountNumber,
    String? paystackBankCode,
    double? vendorEarnings,
    double? commissionAmount,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      vendorOrderId: vendorOrderId ?? this.vendorOrderId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      fulfillmentStatus: fulfillmentStatus ?? this.fulfillmentStatus,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      trackingNote: trackingNote ?? this.trackingNote,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vendorName: vendorName ?? this.vendorName,
      paystackBusinessName: paystackBusinessName ?? this.paystackBusinessName,
      paystackAccountName: paystackAccountName ?? this.paystackAccountName,
      paystackAccountNumber:
          paystackAccountNumber ?? this.paystackAccountNumber,
      paystackBankCode: paystackBankCode ?? this.paystackBankCode,
      vendorEarnings: vendorEarnings ?? this.vendorEarnings,
      commissionAmount: commissionAmount ?? this.commissionAmount,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((item) => CartItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final paymentStatus = (json['paymentStatus']?.toString() ?? 'pending').toLowerCase();
    final fulfillmentStatus = parseFulfillmentStatus(
      json['fulfillmentStatus']?.toString() ?? json['status']?.toString(),
    );
    final lifecycleStatus = parseLifecycleStatus(
      json['lifecycleStatus']?.toString(),
      paymentStatus: paymentStatus,
      fulfillmentStatus: fulfillmentStatus,
    );

    return OrderModel(
      id: json['id']?.toString() ?? json['vendorOrderId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      vendorOrderId: json['vendorOrderId']?.toString() ?? json['id']?.toString() ?? '',
      items: items,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: parseStatus(
        lifecycleStatus,
        paymentStatus: paymentStatus,
        fulfillmentStatus: fulfillmentStatus,
      ),
      lifecycleStatus: lifecycleStatus,
      fulfillmentStatus: fulfillmentStatus,
      customerName: json['customerName']?.toString() ?? 'Guest shopper',
      customerEmail: json['customerEmail']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      trackingNote: json['trackingNote']?.toString() ?? '',
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      statusUpdatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      paymentStatus: paymentStatus,
      paymentMethod: json['paymentMethod']?.toString() ?? 'card',
      vendorName: json['vendorName']?.toString() ?? 'Quiver Lux Vendor',
      paystackBusinessName: json['paystackBusinessName']?.toString() ?? '',
      paystackAccountName: json['paystackAccountName']?.toString() ?? '',
      paystackAccountNumber: json['paystackAccountNumber']?.toString() ?? '',
      paystackBankCode: json['paystackBankCode']?.toString() ?? '',
      vendorEarnings: (json['vendorEarnings'] as num?)?.toDouble() ?? 0,
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  static FulfillmentStatus parseFulfillmentStatus(String? statusStr) {
    switch ((statusStr ?? '').toLowerCase()) {
      case 'processing':
        return FulfillmentStatus.processing;
      case 'shipped':
        return FulfillmentStatus.shipped;
      case 'delivered':
        return FulfillmentStatus.delivered;
      case 'cancelled':
        return FulfillmentStatus.cancelled;
      case 'pending':
      default:
        return FulfillmentStatus.pending;
    }
  }

  static String parseLifecycleStatus(
    String? lifecycle, {
    required String paymentStatus,
    required FulfillmentStatus fulfillmentStatus,
  }) {
    final candidate = (lifecycle ?? '').toLowerCase();
    if (candidate.isNotEmpty) {
      return candidate;
    }
    if (fulfillmentStatus == FulfillmentStatus.cancelled) return 'cancelled';
    if (paymentStatus != 'success') return 'payment_pending';
    if (fulfillmentStatus == FulfillmentStatus.pending) return 'paid';
    if (fulfillmentStatus == FulfillmentStatus.processing) return 'processing';
    if (fulfillmentStatus == FulfillmentStatus.shipped) return 'shipped';
    return 'delivered';
  }

  static OrderStatus parseStatus(
    String lifecycleStatus, {
    required String paymentStatus,
    required FulfillmentStatus fulfillmentStatus,
  }) {
    switch (lifecycleStatus) {
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.successful;
      default:
        if (fulfillmentStatus == FulfillmentStatus.shipped) {
          return OrderStatus.shipped;
        }
        if (fulfillmentStatus == FulfillmentStatus.delivered) {
          return OrderStatus.successful;
        }
        return OrderStatus.placed;
    }
  }

  bool get isPaid => paymentStatus == 'success';
  bool get isPendingPayment => lifecycleStatus == 'payment_pending';
  bool get isCancelled => lifecycleStatus == 'cancelled';
  bool get isManualBankTransfer => paymentMethod == 'manual_bank_transfer';

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'bank':
        return 'BANK';
      case 'bank_transfer':
        return 'BANK TRANSFER';
      case 'ussd':
        return 'USSD';
      case 'manual_bank_transfer':
        return 'DIRECT VENDOR TRANSFER';
      case 'card':
      default:
        return 'CARD';
    }
  }

  int get statusStep {
    if (isCancelled) {
      return fulfillmentStatus == FulfillmentStatus.pending ? 1 : 2;
    }
    switch (lifecycleStatus) {
      case 'payment_pending':
        return 0;
      case 'paid':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  String get statusLabel {
    switch (lifecycleStatus) {
      case 'payment_pending':
        return paymentStatus == 'failed' ? 'PAYMENT FAILED' : 'PAYMENT PENDING';
      case 'paid':
        return 'PAID';
      case 'processing':
        return 'PROCESSING';
      case 'shipped':
        return 'SHIPPED';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'ORDER ACTIVE';
    }
  }

  String get statusHint {
    switch (lifecycleStatus) {
      case 'payment_pending':
        return paymentStatus == 'failed'
            ? 'Payment was not completed. Retry checkout if you still want these items.'
            : isManualBankTransfer
                ? 'Waiting for the vendor or admin to confirm your bank transfer.'
                : 'Waiting for Paystack to confirm this order payment.';
      case 'paid':
        return 'Payment confirmed. The vendor has not started fulfillment yet.';
      case 'processing':
        return 'The vendor is preparing your pieces.';
      case 'shipped':
        return 'Your order is in transit.';
      case 'delivered':
        return 'Delivered. Enjoy your Quiver Lux pieces.';
      case 'cancelled':
        return 'This order was cancelled before delivery.';
      default:
        return 'Your order is being processed.';
    }
  }

  String get itemSummary {
    if (items.isEmpty) return 'No items';
    if (items.length == 1) {
      return '${items.first.product.title} x${items.first.quantity}';
    }
    return '${items.first.product.title} + ${items.length - 1} more';
  }
}
