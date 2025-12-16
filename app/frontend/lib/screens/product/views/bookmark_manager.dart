import 'package:flutter/foundation.dart';
import 'package:shop/models/product_model.dart';

class BookmarkManager {
  // Singleton pattern
  BookmarkManager._privateConstructor();
  static final BookmarkManager instance = BookmarkManager._privateConstructor();

  final ValueNotifier<List<ProductModel>> _bookmarkedProducts = ValueNotifier([]);

  ValueListenable<List<ProductModel>> get bookmarkedProducts => _bookmarkedProducts;

  bool isBookmarked(ProductModel product) {
    return _bookmarkedProducts.value.any((p) => p.title == product.title && p.image == product.image);
  }

  void toggleBookmark(ProductModel product) {
    List<ProductModel> currentBookmarks = List.from(_bookmarkedProducts.value);
    if (isBookmarked(product)) {
      currentBookmarks.removeWhere((p) => p.title == product.title && p.image == product.image);
    } else {
      currentBookmarks.add(product);
    }
    _bookmarkedProducts.value = currentBookmarks;
  }
}
