import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/widgets/product_image.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reduced aspect ratio container for smaller image display
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                imageUrl: product.imageUrl,
                imageBytes: product.imageBytes,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.vendorName.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.matteBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatNaira(product.price),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.champagneGold,
            ),
          ),
        ],
      ),
    );
  }
}
