import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  static const _cartStorageKey = 'quiver_lux_cart_items';

  CartNotifier() : super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_cartStorageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        state = decoded
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Ignore corrupted local cache
    }
  }

  Future<void> _saveToStorage(List<CartItemModel> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (items.isEmpty) {
        await prefs.remove(_cartStorageKey);
      } else {
        final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
        await prefs.setString(_cartStorageKey, encoded);
      }
    } catch (_) {
      // Graceful fallback if storage write fails
    }
  }

  void addToCart(ProductModel product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    List<CartItemModel> newState;
    if (index >= 0) {
      final updatedItem = state[index].copyWith(
        quantity: state[index].quantity + 1,
      );
      newState = [...state];
      newState[index] = updatedItem;
    } else {
      newState = [...state, CartItemModel(product: product, quantity: 1)];
    }
    state = newState;
    _saveToStorage(newState);
  }

  void updateQuantity(String productId, int delta) {
    final newState = <CartItemModel>[];
    for (final item in state) {
      if (item.product.id == productId) {
        final newQty = item.quantity + delta;
        if (newQty > 0) {
          newState.add(item.copyWith(quantity: newQty));
        }
      } else {
        newState.add(item);
      }
    }
    state = newState;
    _saveToStorage(newState);
  }

  void removeFromCart(String productId) {
    final newState =
        state.where((item) => item.product.id != productId).toList();
    state = newState;
    _saveToStorage(newState);
  }

  void clearCart() {
    state = [];
    _saveToStorage([]);
  }

  double get subtotal => state.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get tax => subtotal * 0.075; // VAT estimate

  double get shipping =>
      state.isEmpty ? 0.0 : 5000.0; // Lagos metro delivery estimate

  double get grandTotal => subtotal + tax + shipping;
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  // We need to watch the provider to trigger rebuilds on change
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).grandTotal;
});
