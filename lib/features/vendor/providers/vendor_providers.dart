import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../providers/api_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/models/product_model.dart';

class VendorAnalyticsModel {
  final int totalProducts;
  final int totalSoldUnits;
  final int totalVendorOrders;
  final double totalEarnings;

  const VendorAnalyticsModel({
    this.totalProducts = 0,
    this.totalSoldUnits = 0,
    this.totalVendorOrders = 0,
    this.totalEarnings = 0,
  });

  factory VendorAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return VendorAnalyticsModel(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalSoldUnits: (json['totalSoldUnits'] as num?)?.toInt() ?? 0,
      totalVendorOrders: (json['totalVendorOrders'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
    );
  }
}

class VendorBrandNotifier extends StateNotifier<String> {
  VendorBrandNotifier(this.ref) : super('Quiver Lux Vendor') {
    load();
  }

  final Ref ref;

  Future<void> load() async {
    try {
      final response = await ref.read(apiClientProvider).get(ApiEndpoints.vendorMe);
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final vendor = Map<String, dynamic>.from(data['vendor'] as Map? ?? const {});
      state = (vendor['brandName']?.toString().trim().isNotEmpty ?? false)
          ? vendor['brandName'].toString().trim()
          : (vendor['storeName']?.toString() ?? state);
      await ref.read(authProvider.notifier).setVendorProfile(vendor);
    } catch (_) {
      final userVendor = ref.read(authProvider).user?.vendor;
      if (userVendor != null) {
        state = userVendor['brandName']?.toString() ?? userVendor['storeName']?.toString() ?? state;
      }
    }
  }

  Future<void> update(String name, {String? logoUrl}) async {
    final response = await ref.read(apiClientProvider).patch(
      ApiEndpoints.vendorMe,
      data: {
        'brandName': name.trim(),
        'storeName': name.trim(),
        if (logoUrl != null && logoUrl.trim().isNotEmpty) 'storeLogo': logoUrl.trim(),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? const {};
    final vendor = Map<String, dynamic>.from(data['vendor'] as Map? ?? const {});
    state = vendor['brandName']?.toString() ?? vendor['storeName']?.toString() ?? name.trim();
    await ref.read(authProvider.notifier).setVendorProfile(vendor);
  }
}

final vendorBrandProvider = StateNotifierProvider<VendorBrandNotifier, String>(
  (ref) => VendorBrandNotifier(ref),
);

class VendorProductsNotifier extends StateNotifier<List<ProductModel>> {
  VendorProductsNotifier(this.ref) : super(const []) {
    load();
  }

  final Ref ref;

  Future<FormData> _buildProductFormData(ProductModel product) async {
    final data = <String, dynamic>{
      'name': product.title,
      'description': product.description,
      'price': product.price,
      'categoryName': product.category,
      'stockQuantity': product.stockQuantity,
      'isLimitedOffer': product.isLightningDeal,
    };

    if (product.imageUrl.isNotEmpty) {
      data['imageUrls'] = [product.imageUrl];
    }
    if (product.discountPrice != null) {
      data['discountPrice'] = product.discountPrice;
    }
    if (product.offerStartsAt != null) {
      data['offerStartsAt'] = product.offerStartsAt!.toIso8601String();
    }
    if (product.offerEndsAt != null) {
      data['offerEndsAt'] = product.offerEndsAt!.toIso8601String();
    }
    if (product.imageBytes != null) {
      data['images'] = [
        MultipartFile.fromBytes(
          product.imageBytes!,
          filename: '${product.title.toLowerCase().replaceAll(' ', '_')}.jpg',
        ),
      ];
    }

    return FormData.fromMap(data);
  }

  Future<void> load() async {
    try {
      final response = await ref.read(apiClientProvider).get(ApiEndpoints.vendorProducts);
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final products = (data['products'] as List<dynamic>? ?? const [])
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = products;
    } catch (_) {
      state = const [];
    }
  }

  Future<void> addProduct(ProductModel product) async {
    await ref.read(apiClientProvider).post(
      ApiEndpoints.products,
      data: await _buildProductFormData(product),
    );
    await load();
    ref.invalidate(customerProductsProvider);
    ref.invalidate(vendorAnalyticsProvider);
  }

  Future<void> updateProduct(ProductModel product) async {
    await ref.read(apiClientProvider).patch(
      '${ApiEndpoints.products}/${product.id}',
      data: await _buildProductFormData(product),
    );
    await load();
    ref.invalidate(customerProductsProvider);
    ref.invalidate(vendorAnalyticsProvider);
  }

  Future<void> deleteProduct(String productId) async {
    await ref.read(apiClientProvider).delete('${ApiEndpoints.products}/$productId');
    state = state.where((product) => product.id != productId).toList();
    ref.invalidate(customerProductsProvider);
    ref.invalidate(vendorAnalyticsProvider);
  }

  Future<void> approveProduct(String productId) async {
    await ref.read(apiClientProvider).patch(
      '${ApiEndpoints.productApproval}/$productId/approval',
      data: {'approvalStatus': 'APPROVED'},
    );
    await load();
    ref.invalidate(customerProductsProvider);
    ref.invalidate(vendorAnalyticsProvider);
  }

  Future<void> rejectProduct(String productId) async {
    await ref.read(apiClientProvider).patch(
      '${ApiEndpoints.productApproval}/$productId/approval',
      data: {'approvalStatus': 'REJECTED'},
    );
    await load();
    ref.invalidate(customerProductsProvider);
    ref.invalidate(vendorAnalyticsProvider);
  }
}

final vendorProductsProvider =
    StateNotifierProvider<VendorProductsNotifier, List<ProductModel>>(
  (ref) {
    final notifier = VendorProductsNotifier(ref);
    ref.listen<String?>(
      authProvider.select((state) {
        final user = state.user;
        return user == null ? null : '${user.id}:${user.role}:${user.vendorStatus}';
      }),
      (_, __) {
        notifier.load();
      },
    );
    return notifier;
  },
);

final customerProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final response = await ref.read(apiClientProvider).get(ApiEndpoints.products);
  final data = response.data['data'] as Map<String, dynamic>? ?? const {};
  final products = data['products'] as List<dynamic>? ?? const [];
  return products
      .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

final vendorAnalyticsProvider = FutureProvider<VendorAnalyticsModel>((ref) async {
  final response = await ref.read(apiClientProvider).get(ApiEndpoints.vendorAnalytics);
  final data = response.data['data'] as Map<String, dynamic>? ?? const {};
  return VendorAnalyticsModel.fromJson(data);
});
