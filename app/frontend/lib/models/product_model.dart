import 'dart:convert';
import 'dart:ui';

class ProductModel {
  final String id;
  final String image;
  final String brandName;
  final String title;
  final double price;
  final double? priceAfterDiscount; // Fixed typo
  final int? discountPercent;
  final List<String>? images;
  final bool isAvailable;
  final String? description;
  final double rating;
  final int reviews;
  final int? quantity;
  final String? category;
  final DateTime? createdAt;

  // New fields for B2B/B2C pricing
  final double? b2cPrice;
  final double? b2bPrice;
  final double? b2cOfferPrice;
  final double? b2bOfferPrice;
  final double? currentPrice;
  final double? originalPrice;
  final List<String>? tags; // For better search
  final List<String>? searchKeywords; // Specific search keywords
  ProductModel({
    required this.id,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
    this.images,
    this.isAvailable = true,
    this.description,
    this.rating = 0.0,
    this.reviews = 0,
    this.quantity,
    this.category,
    this.createdAt,
    this.b2cPrice,
    this.b2bPrice,
    this.b2cOfferPrice,
    this.b2bOfferPrice,
    this.currentPrice,
    this.originalPrice,
    this.tags,
    this.searchKeywords,
  });

  // Factory constructor for creating a ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse images from various formats
    List<String>? parseImages(dynamic imagesData) {
      if (imagesData == null) return null;

      if (imagesData is List) {
        return List<String>.from(imagesData.map((x) => x.toString()));
      } else if (imagesData is String) {
        try {
          // Try to parse as JSON array string
          final parsed = jsonDecode(imagesData) as List<dynamic>;
          return List<String>.from(parsed.map((x) => x.toString()));
        } catch (e) {
          // If it's a single string, return as list with one item
          return [imagesData];
        }
      }
      return null;
    }

    // Parse date if available
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }

    // Calculate price fields based on API response
    final priceValue = (json['price'] as num?)?.toDouble() ??
        (json['current_price'] as num?)?.toDouble() ?? 0.0;

    final priceAfterDiscountValue = (json['priceAfetDiscount'] as num?)?.toDouble() ??
        (json['priceAfterDiscount'] as num?)?.toDouble() ??
        (json['original_price'] as num?)?.toDouble();

    // Calculate discount percentage if not provided
    int? discountPercentValue;
    if (json['discountPercent'] != null) {
      discountPercentValue = (json['discountPercent'] as num).toInt();
    } else if (json['discount_percentage'] != null) {
      discountPercentValue = (json['discount_percentage'] as num).toInt();
    } else if (json['dicountpercent'] != null) {
      discountPercentValue = (json['dicountpercent'] as num).toInt();
    } else if (priceValue > 0 && priceAfterDiscountValue != null && priceAfterDiscountValue > 0) {
      // Calculate discount percentage if we have both prices
      discountPercentValue = ((priceAfterDiscountValue - priceValue) / priceAfterDiscountValue * 100).round();
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      brandName: json['brand']?.toString() ??
          json['brandName']?.toString() ??
          'Brand',
      title: json['title']?.toString() ??
          json['name']?.toString() ??
          '',
      price: priceValue,
      priceAfterDiscount: priceAfterDiscountValue,
      discountPercent: discountPercentValue,
      images: parseImages(json['images'] ?? json['image']),
      isAvailable: json['isAvailable'] ??
          ((json['stock'] as num?)?.toInt() ?? 0) > 0 ??
          true,
      description: json['description']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ??
          (json['stock'] as num?)?.toInt(),
      category: json['category']?.toString(),
      createdAt: parseDate(json['created_at']?.toString()),
      b2cPrice: (json['b2c_price'] as num?)?.toDouble(),
      b2bPrice: (json['b2b_price'] as num?)?.toDouble(),
      b2cOfferPrice: (json['b2c_offer_price'] as num?)?.toDouble(),
      b2bOfferPrice: (json['b2b_offer_price'] as num?)?.toDouble(),
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'brandName': brandName,
      'title': title,
      'price': price,
      'priceAfterDiscount': priceAfterDiscount,
      'discountPercent': discountPercent,
      'images': images,
      'isAvailable': isAvailable,
      'description': description,
      'rating': rating,
      'reviews': reviews,
      'quantity': quantity,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
      'b2c_price': b2cPrice,
      'b2b_price': b2bPrice,
      'b2c_offer_price': b2cOfferPrice,
      'b2b_offer_price': b2bOfferPrice,
      'current_price': currentPrice,
      'original_price': originalPrice,
    };
  }

  ProductModel copyWith({
    String? id,
    String? image,
    String? brandName,
    String? title,
    double? price,
    double? priceAfterDiscount,
    int? discountPercent,
    List<String>? images,
    bool? isAvailable,
    String? description,
    double? rating,
    int? reviews,
    int? quantity,
    String? category,
    DateTime? createdAt,
    double? b2cPrice,
    double? b2bPrice,
    double? b2cOfferPrice,
    double? b2bOfferPrice,
    double? currentPrice,
    double? originalPrice, Color? color,
  }) {
    return ProductModel(
      id: id ?? this.id,
      image: image ?? this.image,
      brandName: brandName ?? this.brandName,
      title: title ?? this.title,
      price: price ?? this.price,
      priceAfterDiscount: priceAfterDiscount ?? this.priceAfterDiscount,
      discountPercent: discountPercent ?? this.discountPercent,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      b2cPrice: b2cPrice ?? this.b2cPrice,
      b2bPrice: b2bPrice ?? this.b2bPrice,
      b2cOfferPrice: b2cOfferPrice ?? this.b2cOfferPrice,
      b2bOfferPrice: b2bOfferPrice ?? this.b2bOfferPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      originalPrice: originalPrice ?? this.originalPrice,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, title: $title, price: $price, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.title == title &&
        other.price == price;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ price.hashCode;
  }

  get specifications => null;
}

// Helper function to parse product lists from API response
List<ProductModel> parseProductsFromResponse(dynamic responseData) {
  if (responseData is Map<String, dynamic>) {
    // Check different possible response structures
    if (responseData['products'] != null) {
      final data = responseData['products'] as List<dynamic>;
      return data
          .map<ProductModel>((json) => ProductModel.fromJson(json))
          .toList();
    } else if (responseData['results'] != null) {
      final data = responseData['results'] as List<dynamic>;
      return data
          .map<ProductModel>((json) => ProductModel.fromJson(json))
          .toList();
    } else if (responseData['data'] != null) {
      final data = responseData['data'] as List<dynamic>;
      return data
          .map<ProductModel>((json) => ProductModel.fromJson(json))
          .toList();
    }
    // If response is a single product
    return [ProductModel.fromJson(responseData)];
  } else if (responseData is List<dynamic>) {
    return responseData
        .map<ProductModel>((json) => ProductModel.fromJson(json))
        .toList();
  }
  return [];
}