import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/widgets/product_image.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/review_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final dynamic product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  // Safely extract properties across different product model types
  String get _title => product.title ?? 'Product';
  double get _price => (product.price as num?)?.toDouble() ?? 0.0;
  String get _imageUrl => (product.imageUrl as String?) ?? '';
  String get _vendorName {
    try {
      return product.vendorName ?? 'QUIVER LUX';
    } catch (_) {
      return 'QUIVER LUX';
    }
  }

  String get _description {
    try {
      return product.description ?? 'Curated luxury item for your home.';
    } catch (_) {
      return 'Curated luxury item for your home.';
    }
  }

  // Converts dynamic object to ProductModel for Cart state
  ProductModel _toProductModel() {
    if (product is ProductModel) return product as ProductModel;
    return ProductModel(
      id: product.id.toString(),
      title: _title,
      price: _price,
      category: product.category ?? 'General',
      imageUrl: _imageUrl,
      description: _description,
      vendorName: _vendorName,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetProductModel = _toProductModel();
    final customerRatings = ref.watch(productReviewProvider);
    final customerRating = customerRatings[targetProductModel.id];

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.matteBlack),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.softGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ProductImage(
                        imageUrl: _imageUrl,
                        imageBytes: targetProductModel.imageBytes,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _vendorName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.matteBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatNaira(_price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.champagneGold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('YOUR RATING', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Row(children: List.generate(5, (index) => IconButton(
                    tooltip: 'Rate ${index + 1} stars',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34),
                    onPressed: () => ref.read(productReviewProvider.notifier).setRating(targetProductModel.id, index + 1),
                    icon: Icon(index < (customerRating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.champagneGold),
                  ))),
                  Text(customerRating == null ? 'Tell other shoppers what you think.' : 'You rated this $customerRating out of 5.', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.matteBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.matteBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(cartProvider.notifier)
                        .addToCart(targetProductModel);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$_title added to bag'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'ADD TO BAG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
