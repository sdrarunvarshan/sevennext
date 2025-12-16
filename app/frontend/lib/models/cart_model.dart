import 'package:shop/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  final String colorHex;

  CartItem({required this.product, required this.colorHex, this.quantity = 1});
}

class Cart {
  static final Cart _instance = Cart._internal();

  factory Cart() {
    return _instance;
  }

  Cart._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addItem(ProductModel product, String colorHex) {
    // Check if item with same product ID AND same colorHex already exists
    for (var item in _items) {
      if (item.product.id == product.id && item.colorHex == colorHex) {
        item.quantity++;
        return;
      }
    }
    // If not found, add new item with the colorHex
    _items.add(CartItem(product: product, colorHex: colorHex));
  }

  void removeItem(CartItem item) {
    _items.remove(item);
  }

  void clearCart() {
    _items.clear();
  }

  double get subtotal {
    return _items.fold(0, (total, item) => total + (item.product.price * item.quantity));
  }
}