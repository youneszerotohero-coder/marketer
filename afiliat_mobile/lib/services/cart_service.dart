import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';

class CartService {
  static final CartService instance = CartService._internal();

  CartService._internal();

  final ValueNotifier<List<CartItemModel>> cartNotifier = ValueNotifier([]);

  List<CartItemModel> get items => cartNotifier.value;

  void addToCart(CartItemModel item) {
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    final index = currentList.indexWhere((i) => i.id == item.id && i.variantSku == item.variantSku);

    if (index >= 0) {
      currentList[index].quantity += item.quantity;
    } else {
      currentList.add(item);
    }

    cartNotifier.value = currentList;
  }

  void incrementQuantity(int index) {
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    currentList[index].quantity++;
    cartNotifier.value = currentList;
  }

  void decrementQuantity(int index) {
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    if (currentList[index].quantity > 1) {
      currentList[index].quantity--;
      cartNotifier.value = currentList;
    }
  }

  void removeItem(int index) {
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    currentList.removeAt(index);
    cartNotifier.value = currentList;
  }

  void clearCart() {
    cartNotifier.value = [];
  }

  void updateItem(int index, CartItemModel newItem) {
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    currentList[index] = newItem;
    cartNotifier.value = currentList;
  }

  double get subtotal => cartNotifier.value.fold(0, (total, item) => total + (item.price * item.quantity));
  double get shippingCost => cartNotifier.value.isEmpty ? 0 : 500.0;
  double get total => subtotal + shippingCost;
}
