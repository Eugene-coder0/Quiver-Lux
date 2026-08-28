import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  void addToCart(ProductModel product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final updatedItem = state[index].copyWith(
        quantity: state[index].quantity + 1,
      );
      final newState = [...state];
      newState[index] = updatedItem;
      state = newState;
    } else {
      state = [...state, CartItemModel(product: product, quantity: 1)];
    }
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
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
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
