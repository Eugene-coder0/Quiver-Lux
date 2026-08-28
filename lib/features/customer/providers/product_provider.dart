import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');
final maxPriceFilterProvider =
    StateProvider<double>((ref) => 3000000.0); // Default ₦3,000,000

final categoriesProvider = Provider<List<CategoryModel>>((ref) {
  return const [
    CategoryModel(id: '1', name: 'Furniture', icon: 'chair'),
    CategoryModel(id: '2', name: 'Lighting', icon: 'light'),
    CategoryModel(id: '3', name: 'Drapes', icon: 'curtains'),
    CategoryModel(id: '4', name: 'Kitchen', icon: 'kitchen'),
    CategoryModel(id: '5', name: 'Decor', icon: 'decor'),
  ];
});

final mockProducts = [
  ProductModel(
    id: '1',
    title: 'Silk Cashmere Overcoat',
    vendorName: 'Maison Aurelia',
    price: 850000.00,
    imageUrl:
        'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=500',
    category: 'Apparel',
    description: 'Tailored luxury wool and cashmere blend overcoat.',
  ),
  ProductModel(
    id: '2',
    title: 'Minimalist Gold Chronograph',
    vendorName: 'Vance & Co.',
    price: 1650000.00,
    imageUrl:
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
    category: 'Watches',
    description: 'Swiss movement with 18k champagne gold casing.',
  ),
  ProductModel(
    id: '3',
    title: 'Handcrafted Ceramic Vase',
    vendorName: 'Atelier Noir',
    price: 220000.00,
    imageUrl:
        'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=500',
    category: 'Home & Living',
    description: 'Matte black architectural ceramic vessel.',
  ),
  ProductModel(
    id: '4',
    title: 'Structured Leather Tote',
    vendorName: 'Maison Aurelia',
    price: 580000.00,
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=500',
    category: 'Apparel',
    description: 'Full-grain Italian calfskin leather tote bag.',
  ),
];

final productsProvider = Provider<List<ProductModel>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final maxPrice = ref.watch(maxPriceFilterProvider);

  return mockProducts.where((product) {
    final matchesCategory = category == 'All' || product.category == category;
    final matchesSearch = product.title.toLowerCase().contains(searchQuery) ||
        product.vendorName.toLowerCase().contains(searchQuery);
    final matchesPrice = product.price <= maxPrice;

    return matchesCategory && matchesSearch && matchesPrice;
  }).toList();
});
