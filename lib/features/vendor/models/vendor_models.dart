enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled
}

class VendorProduct {
  final String id;
  final String title;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;

  VendorProduct({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  VendorProduct copyWith({
    String? id,
    String? title,
    String? category,
    double? price,
    int? stock,
    String? imageUrl,
  }) {
    return VendorProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class VendorOrder {
  final String id;
  final String customerName;
  final String? itemTitle;
  final double totalAmount;
  final double totalPrice;
  final OrderStatus status;

  VendorOrder({
    required this.id,
    required this.customerName,
    this.itemTitle,
    required this.totalAmount,
    double? totalPrice,
    required this.status,
  }) : totalPrice = totalPrice ?? totalAmount;
}
