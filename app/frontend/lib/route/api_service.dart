// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '/screens/helpers/user_helper.dart';
import '../models/product_model.dart';

class ApiService {
  // CHANGE ONLY THIS LINE depending on your environment
  static const String baseUrl = "http://127.0.0.1:8000"; // Your PC IP - removed extra space
  // For Android emulator → "http://10.0.2.2:8000"
  // For iOS simulator   → "http://127.0.0.1:8000"
  // For real device     → your PC IPv4 (192.168.x.x)

  // Token stored after login/signup
  static String? token;


  // Helper: Get user type from UserHelper
  static Future<String> get _userType async {
    return await UserHelper.getUserType();
  }

  // Helper: common headers
  static Future<Map<String, String>> get _headers async {
    // DEBUG: Log the token to see if it's being set correctly
    print('ApiService: Creating headers with token: $token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // POST JSON
  static Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      uri,
      headers: await _headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  // POST Multipart (for file uploads – B2B documents, etc.)
  static Future<Map<String, dynamic>> postMultipart(
      String endpoint, {
        required Map<String, String> fields,
        required List<http.MultipartFile> files,
      }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    request.headers.addAll(await _headers);
    request.fields.addAll(fields);
    request.files.addAll(files);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );

    return _handleResponse(response);
  }

  // GET User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('PUT request failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('DELETE request failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/place'),
        headers: await _headers,
        body: json.encode(orderData),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Unified response handler with nice errors
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final int status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Try to parse error message from FastAPI
    String message = 'Unknown error';
    try {
      final errorBody = jsonDecode(response.body);
      message = errorBody['detail'] ?? response.reasonPhrase;
    } catch (_) {
      message = (response.body.isNotEmpty ? response.body : response.reasonPhrase)!;
    }

    // Special case: token expired or invalid
    if (status == 401) {
      token = null; // force re-login
      throw Exception("Session expired. Please login again.");
    }

    throw HttpException("HTTP $status: $message");
  }

  // Optional: clear token on logout
  static void logout() {
    token = null;
  }

  // PRODUCT METHODS ========================================================

  // Get products with filtering
  Future<List<ProductModel>> getProducts({
    String? category,
    String? searchQuery, // Added for search functionality
    double? minPrice,
    double? maxPrice,
    String status = "Published",
    int limit = 50,
    int offset = 0,
    String? userType, // Make optional, will use UserHelper if not provided

  }) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      // Build query string
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'status': status,
        'user_type': currentUserType,
        if (category != null && category.isNotEmpty) 'category': category,
        if (searchQuery != null && searchQuery.isNotEmpty) 'query': searchQuery, // Add search query
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
      };

      final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // The API returns 'products' for getProducts, 'results' for searchProducts
        // We should handle both cases here
        final List<dynamic> productsList = data['products'] ?? data['results'] ?? [];
        return productsList.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading products: $e');
      rethrow;
    }
  }

  // Get single product by ID
  Future<ProductModel> getProductById(String productId, {String? userType}) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId?user_type=$currentUserType'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert integer stock to boolean for isAvailable
        final int stock = (data['stock'] as int?) ?? 0;
        final bool isAvailable = stock > 0;

        // Get price information
        double currentPrice = (data['current_price'] as num?)?.toDouble() ?? 0.0;
        double? originalPrice = (data['original_price'] as num?)?.toDouble();
        int? discountPercent = (data['discount_percentage'] as num?)?.toInt();

        return ProductModel(
          id: data['id']?.toString() ?? '',
          image: data['image']?.toString() ?? '',
          brandName: '', // Your FastAPI doesn't have brand field
          title: data['name']?.toString() ?? '',
          price: currentPrice,
          priceAfterDiscount: originalPrice,
          discountPercent: discountPercent,
          images: data['image']?.toString() != null
              ? [data['image']?.toString() ?? '']
              : [],
          isAvailable: isAvailable,
          description: data['description']?.toString(),
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          reviews: (data['reviews'] as int?) ?? 0,
          quantity: stock,
          category: data['category']?.toString(),
          createdAt: data['created_at'] != null
              ? DateTime.tryParse(data['created_at'].toString())
              : null,
          b2cPrice: (data['b2c_price'] as num?)?.toDouble(),
          b2bPrice: (data['b2b_price'] as num?)?.toDouble(),
          b2cOfferPrice: (data['b2c_offer_price'] as num?)?.toDouble(),
          b2bOfferPrice: (data['b2b_offer_price'] as num?)?.toDouble(),
        );
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading product by ID: $e');
      rethrow;
    }
  }

  // Get new arrivals
  Future<List<ProductModel>> getNewArrivals({
    int limit = 10,
    String? userType,
  }) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      final response = await http.get(
        Uri.parse('$baseUrl/products/section/new_arrivals?user_type=$currentUserType&limit=$limit'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsList = data['products'] ?? [];
        return productsList.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load new arrivals: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading new arrivals: $e');
      rethrow;
    }
  }

  // Get on sale products
  Future<List<ProductModel>> getOnSaleProducts({
    int limit = 10,
    String? userType,
  }) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      final response = await http.get(
        Uri.parse('$baseUrl/products/section/on_sale?user_type=$currentUserType&limit=$limit'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsList = data['products'] ?? [];
        return productsList.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load on sale products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading on sale products: $e');
      rethrow;
    }
  }

  // Add review to product
  Future<Map<String, dynamic>> addReview(
      String productId,
      double rating,
      String? comment,
      ) async {
    try {
      final body = {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/review'),
        headers: await _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  // Get product reviews
  Future<Map<String, dynamic>> getProductReviews(
      String productId, {
        int limit = 10,
        int offset = 0,
      }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/reviews?limit=$limit&offset=$offset'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading reviews: $e');
      rethrow;
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(
      String query, {
        int limit = 50, // Increase limit for better search results
        String? userType,
        String? category,
      }) async {
    try {
      // Debug: Check what's happening
      print('🔍 Starting search for: "$query"');
      print('🔍 Category filter: $category');

      // Call getProducts with searchQuery
      final results = await getProducts(
        searchQuery: query, // This should trigger search
        limit: limit,
        userType: userType,
        category: category, // BUT this might filter out other categories!
      );

      print('🔍 Search returned ${results.length} results');

      // Debug: Check which categories were returned
      final categories = results.map((p) => p.category).toSet().toList();
      print('🔍 Categories in results: $categories');

      return results;
    } catch (e) {
      print('❌ Error searching products: $e');
      rethrow;
    }
  }
  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category, param1, {String? userType}) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      // Use the general products endpoint with category filter
      return getProducts(category: category, userType: currentUserType);
    } catch (e) {
      print('Error loading products by category: $e');
      rethrow;
    }
  }

  // Get categories (Note: Your FastAPI doesn't have this endpoint yet)
  Future<List<String>> getCategories() async {
    try {
      // Since your FastAPI doesn't have a categories endpoint,
      // you could implement this by fetching all products and extracting unique categories
      // Or create the endpoint in FastAPI
      throw UnimplementedError('Categories endpoint not available in current FastAPI');
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  // Get recommended products
  Future<List<ProductModel>> getRecommendedProducts(
      String productId, String s, {
        int limit = 10,
        String? userType,
      }) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      // Since your FastAPI doesn't have a recommendations endpoint,
      // you could return similar category products
      final product = await getProductById(productId, userType: currentUserType);
      if (product.category != null) {
        return getProducts(
          category: product.category!,
          userType: currentUserType,
          limit: limit,
        );
      }
      return [];
    } catch (e) {
      print('Error loading recommended products: $e');
      return [];
    }
  }

  // In ApiService class
  // Get orders for logged-in user
  static Future<Map<String, dynamic>> getUserOrders(String userEmail) async {
    try {
      print('ApiService: Fetching orders for user: $userEmail');

      final response = await http.get(
        Uri.parse('$baseUrl/orders/user/$userEmail'),
        headers: await _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      print('ApiService: Error fetching user orders: $e');
      rethrow;
    }
  }

}