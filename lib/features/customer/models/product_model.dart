import 'dart:typed_data';

class ProductModel {
  final String id;
  final String title;
  final double price;
  final String category;
  final String imageUrl;
  final String description;
  final String vendorName;
  final int stockQuantity;
  final bool isLightningDeal;
  final Uint8List? imageBytes;
  final double rating;
  final String approvalStatus; // 'approved', 'pending', 'rejected'
  final String? vendorId;
  final double? discountPrice;
  final DateTime? offerStartsAt;
  final DateTime? offerEndsAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.vendorName,
    this.stockQuantity = 5,
    this.isLightningDeal = false,
    this.imageBytes,
    this.rating = 4.8,
    this.approvalStatus = 'approved',
    this.vendorId,
    this.discountPrice,
    this.offerStartsAt,
    this.offerEndsAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'vendorName': vendorName,
      'stockQuantity': stockQuantity,
      'isLightningDeal': isLightningDeal,
      'rating': rating,
      'approvalStatus': approvalStatus,
      'vendorId': vendorId,
      'discountPrice': discountPrice,
      'offerStartsAt': offerStartsAt?.toIso8601String(),
      'offerEndsAt': offerEndsAt?.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final categoryData = json['category'];
    final vendorData = json['vendor'];
    final imagesData = json['images'];
    final offerStartsAt = DateTime.tryParse(json['offerStartsAt']?.toString() ?? '');
    final offerEndsAt = DateTime.tryParse(json['offerEndsAt']?.toString() ?? '');
    final limitedOffer = json['isLightningDeal'] as bool? ??
      json['isLimitedOffer'] as bool? ?? false;
    final now = DateTime.now();
    final offerIsActive = limitedOffer &&
      (offerStartsAt == null || !now.isBefore(offerStartsAt)) &&
      (offerEndsAt == null || !now.isAfter(offerEndsAt));
    final primaryImage = imagesData is List && imagesData.isNotEmpty
      ? imagesData.first
      : null;

    return ProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: categoryData is Map
        ? (categoryData['name']?.toString() ?? '')
        : categoryData?.toString() ?? '',
      imageUrl: json['imageUrl'] as String? ??
        (primaryImage is Map ? primaryImage['url']?.toString() : null) ??
        '',
      description: json['description'] as String? ?? '',
      vendorName: json['vendorName'] as String? ??
        (vendorData is Map ? vendorData['storeName']?.toString() : null) ??
        'Quiver Lux Vendor',
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 5,
          isLightningDeal: offerIsActive,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      approvalStatus: json['approvalStatus'] as String? ?? 'approved',
      vendorId: json['vendorId']?.toString(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      offerStartsAt: offerStartsAt,
      offerEndsAt: offerEndsAt,
    );
  }

  ProductModel copyWith({
    String? id,
    String? title,
    double? price,
    String? category,
    String? imageUrl,
    String? description,
    String? vendorName,
    int? stockQuantity,
    bool? isLightningDeal,
    Uint8List? imageBytes,
    double? rating,
    String? approvalStatus,
    String? vendorId,
    double? discountPrice,
    DateTime? offerStartsAt,
    DateTime? offerEndsAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      vendorName: vendorName ?? this.vendorName,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isLightningDeal: isLightningDeal ?? this.isLightningDeal,
      imageBytes: imageBytes ?? this.imageBytes,
      rating: rating ?? this.rating,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      vendorId: vendorId ?? this.vendorId,
      discountPrice: discountPrice ?? this.discountPrice,
      offerStartsAt: offerStartsAt ?? this.offerStartsAt,
      offerEndsAt: offerEndsAt ?? this.offerEndsAt,
    );
  }
}
