import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A graceful, consistent presentation for remote, picked, and missing images.
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final Uint8List? imageBytes;
  final BoxFit fit;
  final IconData placeholderIcon;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.imageBytes,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.chair_alt_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) return Image.memory(imageBytes!, fit: fit);
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => _Placeholder(icon: placeholderIcon),
      );
    }
    return _Placeholder(icon: placeholderIcon);
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  const _Placeholder({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF1EEE9),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.champagneGold),
            const SizedBox(height: 6),
            const Text('QUIVER LUX',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.6,
                    color: AppColors.textMuted)),
          ],
        ),
      );
}
