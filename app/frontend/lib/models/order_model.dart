import 'package:flutter/material.dart';
import '../components/order_process.dart';

class OrderedProduct {
  final String name;
  final String imageUrl;
  final int quantity;
  final String colorHex;

  OrderedProduct({
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.colorHex,
  });

  // Convert to Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'colorHex': colorHex,
    };
  }

  // Create from Map (for deserialization)
  factory OrderedProduct.fromJson(Map<String, dynamic> json) {
    return OrderedProduct(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      quantity: json['quantity'] as int,
      colorHex: json['colorHex'] as String,
    );
  }
}

class Order {
  final String id;
  final DateTime placedOn;
  final OrderProcessStatus orderStatus;
  final OrderProcessStatus processingStatus;
  final OrderProcessStatus packedStatus;
  final OrderProcessStatus shippedStatus;
  final OrderProcessStatus deliveredStatus;
  final List<OrderedProduct> products;
  final double totalPrice;
  final double shippingFee;
  final String customerEmail;
  final String customerAddressText;
  final String? userType;
  final String paymentMethod; // Add this
  final String paymentStatus; // Add this

  Order({
    required this.id,
    required this.placedOn,
    required this.orderStatus,
    required this.processingStatus,
    required this.packedStatus,
    required this.shippedStatus,
    required this.deliveredStatus,
    required this.products,
    required this.totalPrice,
    required this.shippingFee,
    required this.customerEmail,
    required this.customerAddressText,
    this.userType,
    required this.paymentMethod, // Add to constructor
    required this.paymentStatus, // Add to constructor
  });

  // Convert to Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placedOn': placedOn.toIso8601String(),
      'orderStatus': orderStatus.index,
      'processingStatus': processingStatus.index,
      'packedStatus': packedStatus.index,
      'shippedStatus': shippedStatus.index,
      'deliveredStatus': deliveredStatus.index,
      'products': products.map((product) => product.toJson()).toList(),
      'totalPrice': totalPrice,
      'shippingFee': shippingFee,
      'customerEmail': customerEmail,
      'customerAddressText': customerAddressText,
      'userType': userType,
    };
  }

  // Create from Map (for deserialization)
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      placedOn: DateTime.parse(json['placedOn'] as String),
      orderStatus: OrderProcessStatus.values[json['orderStatus'] as int],
      processingStatus: OrderProcessStatus.values[json['processingStatus'] as int],
      packedStatus: OrderProcessStatus.values[json['packedStatus'] as int],
      shippedStatus: OrderProcessStatus.values[json['shippedStatus'] as int],
      deliveredStatus: OrderProcessStatus.values[json['deliveredStatus'] as int],
      products: (json['products'] as List)
          .map((item) => OrderedProduct.fromJson(item))
          .toList(),
      totalPrice: json['totalPrice'] as double,
      shippingFee: json['shippingFee'] as double,
      customerEmail: json['customerEmail'] as String,
      customerAddressText: json['customerAddressText'] as String,
      userType: json['userType'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'card', // Add this
      paymentStatus: json['paymentStatus'] as String? ?? 'pending', // Add this
    );
  }
}