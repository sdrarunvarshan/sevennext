import 'dart:js_interop';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../components/order_process.dart';
import '/models/order_model.dart';
import 'package:shop/route/api_service.dart';
import 'package:http/http.dart' as http;

class OrdersRepository {
  static const String _ordersKey = 'user_orders';

  // Get all orders - FROM BACKEND IF LOGGED IN, OTHERWISE LOCAL
  static Future<List<Order>> getOrders() async {
    try {
      // Check if user is logged in
      final isGuest = await _isGuestUser();

      if (!isGuest) {
        // User is logged in - fetch from backend
        final backendOrders = await _fetchOrdersFromBackend();

        if (backendOrders.isNotEmpty) {
          // Save backend orders to local storage for offline access
          await _saveOrdersLocally(backendOrders);
          return backendOrders;
        }
      }

      // Fallback to local storage (for guests or when backend fails)
      return await _getOrdersFromLocal();
    } catch (e) {
      print('Error getting orders: $e');
      return await _getOrdersFromLocal();
    }
  }

  // Check if user is guest
  static Future<bool> _isGuestUser() async {
    try {
      final authBox = Hive.box('auth');
      final isGuest = authBox.get('is_guest', defaultValue: true);
      return isGuest == true;
    } catch (e) {
      return true; // Default to guest on error
    }
  }

  // Get user email from Hive
  static Future<String> _getUserEmail() async {
    try {
      final authBox = Hive.box('auth');
      // Check for 'email' key, as 'user_email' might be the one that's missing/empty
      final email = authBox.get('user_email', defaultValue: '');
      return email;
    } catch (e) {
      print('Error getting user email: $e');
      return '';
    }
  }

  // Fetch orders from backend API for logged-in user
  static Future<List<Order>> _fetchOrdersFromBackend() async {
    try {
      final userEmail = await _getUserEmail();
      
      if (userEmail.isEmpty) {
        print('User email not found in Hive during order fetch. Skipping backend call.');
        return [];
      }

      print('Fetching orders from backend for email: $userEmail');

      // Call backend API, passing the user email
      final Map<String, dynamic> response =
      await ApiService.getUserOrders(userEmail);

      // Check if response contains success flag
      if (response.containsKey('success') && response['success'] == true) {
        List<Order> orders = [];

        // Check if response has 'orders' array
        if (response.containsKey('orders') && response['orders'] is List) {
          for (var orderData in response['orders']) {
            try {
              final order = await _parseOrderFromBackend(orderData);
              if (order != null) {
                orders.add(order);
              }
            } catch (e) {
              print('Error parsing order: $e');
            }
          }
        }

        print('Fetched ${orders.length} orders from backend');
        return orders;
      } else {
        print('Failed to fetch orders from backend. Response: $response');
        return [];
      }
    } catch (e) {
      print('Error fetching from backend: $e');
      return [];
    }
  }


  // Parse backend order data to Order model
  // In orders_repository.dart, update _parseOrderFromBackend method:
  static Future<Order?> _parseOrderFromBackend(Map<String, dynamic> orderData) async {
    try {
      // Parse date
      DateTime placedOn = DateTime.now();
      if (orderData['date'] != null) {
        if (orderData['date'] is DateTime) {
          placedOn = orderData['date'];
        } else if (orderData['date'] is String) {
          try {
            placedOn = DateTime.parse(orderData['date']);
          } catch (e) {
            print('Error parsing date string: ${orderData['date']}');
          }
        }
      }

      // Parse products
      final products = await _parseProductsFromBackend(orderData);

      // Get status from backend
      final backendStatus = orderData['status']?.toString().toLowerCase() ?? 'processing';

      // Map backend status to your app's statuses
      final Map<String, List<OrderProcessStatus>> statusMapping = {
        'processing': [
          OrderProcessStatus.processing,
          OrderProcessStatus.notDoneYeat,
          OrderProcessStatus.notDoneYeat,
          OrderProcessStatus.notDoneYeat,
        ],
        'packed': [
          OrderProcessStatus.processing,
          OrderProcessStatus.packed,
          OrderProcessStatus.notDoneYeat,
          OrderProcessStatus.notDoneYeat,
        ],
        'shipped': [
          OrderProcessStatus.processing,
          OrderProcessStatus.packed,
          OrderProcessStatus.shipped,
          OrderProcessStatus.notDoneYeat,
        ],
        'delivered': [
          OrderProcessStatus.processing,
          OrderProcessStatus.packed,
          OrderProcessStatus.shipped,
          OrderProcessStatus.delivered,
        ],
        'canceled': [
          OrderProcessStatus.canceled,
          OrderProcessStatus.canceled,
          OrderProcessStatus.canceled,
          OrderProcessStatus.canceled,
        ],
      };

      final statuses = statusMapping[backendStatus] ?? statusMapping['processing']!;

      return Order(
        id: orderData['id'].toString(),
        placedOn: placedOn,
        orderStatus: statuses[0],
        processingStatus: statuses[1],
        packedStatus: statuses[2],
        shippedStatus: statuses[3],
        deliveredStatus: _getDeliveredStatus(backendStatus),
        products: products,
        totalPrice: _parsePrice(orderData['amount']),
        shippingFee: 0.0,
        customerEmail: orderData['email']?.toString() ?? await _getUserEmail(),
        customerAddressText: orderData['address']?.toString() ?? '',
        paymentMethod: orderData['payment_method']?.toString() ?? 'card',
        paymentStatus: orderData['payment_status']?.toString() ?? 'pending',
      );
    } catch (e) {
      print('Error parsing order from backend: $e');
      return null;
    }
  }

  static OrderProcessStatus _getDeliveredStatus(String backendStatus) {
    switch (backendStatus) {
      case 'delivered':
        return OrderProcessStatus.delivered;
      case 'canceled':
        return OrderProcessStatus.canceled;
      default:
        return OrderProcessStatus.notDoneYeat;
    }
  }

  // Helper method to create an Order with updated statuses
  static Order _updateOrderStatus(Order baseOrder, String backendStatus) {
    // First, check what enum values you actually have
    // Print them to debug:
    print('Available OrderProcessStatus values: ${OrderProcessStatus.values}');

    // Find the actual enum values you have
    // Common values might be: processing, shipped, delivered, canceled

    // Create status enums based on backend status
    final OrderProcessStatus mainStatus = _parseOrderStatus(backendStatus);

    // Determine which statuses should be "completed" based on backend status
    // Since we can't modify final fields, we need to create a new Order
    // Check if your Order class has a copyWith method

    // If Order has copyWith:
    // return baseOrder.copyWith(
    //   orderStatus: mainStatus,
    //   processingStatus: _getProcessingStatus(backendStatus),
    //   packedStatus: _getPackedStatus(backendStatus),
    //   shippedStatus: _getShippedStatus(backendStatus),
    //   deliveredStatus: _getDeliveredStatus(backendStatus),
    // );

    // If no copyWith, you might need to create a new Order
    // But first, let's see what your Order constructor expects

    // For now, just set the main status and return
    // You'll need to adjust this based on your actual Order class

    return baseOrder;
  }

  // Parse price from backend
  static double _parsePrice(dynamic amount) {
    if (amount == null) return 0.0;

    if (amount is int) {
      return amount.toDouble();
    } else if (amount is double) {
      return amount;
    } else if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    }

    return 0.0;
  }

  // Parse products from backend data
  static Future<List<OrderedProduct>> _parseProductsFromBackend(Map<String, dynamic> orderData) async {
    try {
      // Try to get products from items field
      if (orderData.containsKey('items') && orderData['items'] is String) {
        final itemsJson = orderData['items'];
        if (itemsJson.isNotEmpty) {
          try {
            final List<dynamic> items = json.decode(itemsJson);
            return items.map((item) {
              return OrderedProduct(
                name: item['name']?.toString() ?? 'Product',
                imageUrl: item['imageUrl']?.toString() ?? '',
                quantity: (item['quantity'] is int)
                    ? item['quantity']
                    : (item['quantity'] is String)
                    ? int.tryParse(item['quantity']) ?? 1
                    : 1,
                colorHex: item['colorHex']?.toString() ?? 'FF000000',
              );
            }).toList();
          } catch (e) {
            print('Error parsing items JSON: $e');
          }
        }
      }

      // If no items found, create a placeholder based on items_count
      final itemsCount = orderData['items_count'] is int
          ? orderData['items_count']
          : (orderData['items_count'] is String)
          ? int.tryParse(orderData['items_count']) ?? 1
          : 1;

      return [
        OrderedProduct(
          name: 'Order Items',
          imageUrl: '',
          quantity: itemsCount,
          colorHex: 'FF000000',
        )
      ];
    } catch (e) {
      print('Error parsing products: $e');
      return [
        OrderedProduct(
          name: 'Product',
          imageUrl: '',
          quantity: 1,
          colorHex: 'FF000000',
        )
      ];
    }
  }

  // Helper to parse status string to enum
  static OrderProcessStatus _parseOrderStatus(String status) {
    // First, let's see what values your enum actually has
    // Check your order_model.dart file

    // Common pattern:
    switch (status.toLowerCase()) {
      case 'processing':
      // Check if 'processing' exists in your enum
        try {
          return OrderProcessStatus.processing;
        } catch (e) {
          // Fallback to first value
          return OrderProcessStatus.values.first;
        }
      case 'shipped':
        try {
          return OrderProcessStatus.shipped;
        } catch (e) {
          return OrderProcessStatus.values.first;
        }
      case 'delivered':
        try {
          return OrderProcessStatus.delivered;
        } catch (e) {
          return OrderProcessStatus.values.first;
        }
      case 'canceled':
      case 'cancelled':
        try {
          return OrderProcessStatus.canceled;
        } catch (e) {
          return OrderProcessStatus.values.first;
        }
      default:
        return OrderProcessStatus.values.first;
    }
  }

  // Get orders from local storage
  static Future<List<Order>> _getOrdersFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey);

      if (ordersJson == null || ordersJson.isEmpty) {
        return [];
      }

      final List<dynamic> ordersList = json.decode(ordersJson);
      return ordersList.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('Error getting local orders: $e');
      return [];
    }
  }

  // Save orders to local storage
  static Future<void> _saveOrdersLocally(List<Order> orders) async {
    try {
      final List<Map<String, dynamic>> ordersJson =
      orders.map((order) => order.toJson()).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ordersKey, json.encode(ordersJson));
    } catch (e) {
      print('Error saving orders locally: $e');
    }
  }

  // Add a new order - SAVES TO BOTH LOCAL AND BACKEND
  // Add a new order - SAVES TO BOTH LOCAL AND BACKEND
  static Future<void> addOrder(Order newOrder) async {
    try {
      final isGuest = await _isGuestUser();

      // If user is logged in, save to backend
      if (!isGuest) {
        final userEmail = await _getUserEmail(); // Get email first
        await _saveOrderToBackend(newOrder, userEmail); // Pass both arguments
      }

      // Always save locally
      final List<Order> currentOrders = await _getOrdersFromLocal();
      currentOrders.insert(0, newOrder); // Add at beginning
      await _saveOrdersLocally(currentOrders);

      print('Order saved successfully');
    } catch (e) {
      print('Error saving order: $e');
      // Even if backend fails, save locally
      final List<Order> currentOrders = await _getOrdersFromLocal();
      currentOrders.insert(0, newOrder);
      await _saveOrdersLocally(currentOrders);
    }
  }

  // Helper method to save order to backend
  static Future<void> _saveOrderToBackend(Order order, String userEmailFromHive) async {
    try {
      // Get user info from Hive
      final userEmail = await _getUserEmail();
      final userType = await _getUserType();
      // Determine the email to send. Prioritize email from Hive.
      String emailToSend = userEmailFromHive;
      if (emailToSend.isEmpty) {
        // If not found in Hive, try to get it from the Order object itself
        // This assumes order.customerEmail was populated when the Order object was created
        emailToSend = order.customerEmail;
        if (emailToSend.isEmpty) {
          // If still empty, log a warning and potentially throw an error
          print('WARNING: Customer email is empty in both Hive and Order object. Cannot save to backend.');
          // Depending on requirements, you might want to throw an exception here
          // throw Exception("Customer email is missing. Cannot place order.");
        }
      } 
      // Convert Order model to the format expected by FastAPI
      final orderData = {
        'order_id': order.id,
        'placed_on': _formatDateForBackend(order.placedOn),
        'order_status': order.orderStatus.toString().split('.').last, // Get enum value name
        'processing_status': order.processingStatus.toString().split('.').last,
        'packed_status': order.packedStatus.toString().split('.').last,
        'shipped_status': order.shippedStatus.toString().split('.').last,
        'delivered_status': order.deliveredStatus.toString().split('.').last,
        'products': order.products.map((product) => {
          'name': product.name,
          'imageUrl': product.imageUrl,
          'quantity': product.quantity,
          'colorHex': product.colorHex,
        }).toList(),
        'total_price': order.totalPrice,
        'shipping_fee': order.shippingFee,
        'customer_email': userEmail.isNotEmpty ? userEmail : order.customerEmail,
        'customer_address_text': order.customerAddressText,
        'user_type': userType,
      };

      // Send to backend
      final response = await ApiService.placeOrder(orderData);
      print('Backend response: $response');
    } catch (e) {
      print('Failed to save order to backend: $e');
      rethrow;
    }
  }

  // Get user type from Hive
  static Future<String> _getUserType() async {
    try {
      final userTypeBox = Hive.box('user_settings');
      return userTypeBox.get('user_type', defaultValue: 'b2c');
    } catch (e) {
      return 'b2c';
    }
  }

  // Helper to format date for backend (DD/MM/YYYY format)
  static String _formatDateForBackend(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  // Delete an order by ID
  static Future<bool> deleteOrder(String orderId) async {
    try {
      final isGuest = await _isGuestUser();

      // If logged in, delete from backend
      if (!isGuest) {
        // TODO: Implement backend deletion
        // await ApiService.delete('/orders/$orderId');
      }

      // Delete from local storage
      final List<Order> currentOrders = await _getOrdersFromLocal();
      final initialLength = currentOrders.length;

      currentOrders.removeWhere((order) => order.id == orderId);

      if (currentOrders.length < initialLength) {
        await _saveOrdersLocally(currentOrders);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  // Clear all orders
  static Future<void> clearOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ordersKey);
  }

  // Force refresh from backend (ignores local cache)
  static Future<List<Order>> refreshOrders() async {
    try {
      final isGuest = await _isGuestUser();

      if (!isGuest) {
        final backendOrders = await _fetchOrdersFromBackend();
        if (backendOrders.isNotEmpty) {
          await _saveOrdersLocally(backendOrders);
        }
        return backendOrders;
      }

      return await _getOrdersFromLocal();
    } catch (e) {
      print('Error refreshing orders: $e');
      return await _getOrdersFromLocal();
    }
  }
}