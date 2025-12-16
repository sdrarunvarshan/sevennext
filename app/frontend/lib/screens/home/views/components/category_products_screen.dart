import 'package:flutter/material.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/api_service.dart';
import '/screens/helpers/user_helper.dart';
import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ProductModel>> _productsFuture;
  String? _userType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      print('Showing products for category: ${widget.categoryName}');
      await _loadUserType();
      await _loadProducts();
    } catch (e) {
      print('Error initializing screen: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadUserType() async {
    try {
      final fetchedUserType = await UserHelper.getUserType();
      print('Fetched user type: $fetchedUserType');

      setState(() {
        _userType = fetchedUserType;
      });
    } catch (e) {
      print('Error loading user type: $e');
      setState(() {
        _userType = 'b2c';
      });
    }
  }

  Future<void> _loadProducts({String? userType}) async {
    final effectiveUserType = userType ?? _userType ?? 'b2c';

    print('Loading products for category: ${widget.categoryName} with user type: $effectiveUserType');

    try {
      setState(() {
        _productsFuture = _apiService.getProductsByCategory(
          widget.categoryName,
          '',
          userType: effectiveUserType,
        );
      });
    } catch (e) {
      print('Error setting products future: $e');
      setState(() {
        _productsFuture = Future.value(<ProductModel>[]);
      });
    }
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh products',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(
              'Error loading products',
              errorDetails: snapshot.error.toString(),
              onRetry: _refreshProducts,
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyScreen();
          }

          final products = snapshot.data!;
          return _buildProductsGrid(products);
        },
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no products in "${widget.categoryName}" category',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshProducts,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return Column(
      children: [
        // User type indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: _userType == 'b2b'
              ? Colors.blue.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _userType == 'b2b' ? Icons.business : Icons.person,
                size: 16,
                color: _userType == 'b2b' ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                '${_userType?.toUpperCase() ?? "B2C"} VIEW',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _userType == 'b2b' ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${products.length} products)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        // Products grid with improved layout
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate cross axis count based on screen width
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(defaultPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.62, // Better aspect ratio for product cards
                  crossAxisSpacing: defaultPadding,
                  mainAxisSpacing: defaultPadding,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          productDetailsScreenRoute,
          arguments: product,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image Container
            Container(
              height: 140, // Fixed height for consistency
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: product.image.isNotEmpty
                    ? Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Name
                  if (product.brandName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        product.brandName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Product Title
                  SizedBox(
                    height: 36, // Fixed height for title (2 lines)
                    child: Text(
                      product.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Discount Badge
                          if (product.discountPercent != null &&
                              product.discountPercent! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product.discountPercent}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Original Price (if discounted)
                      if (product.priceAfterDiscount != null &&
                          product.priceAfterDiscount! > product.price)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            '\$${product.priceAfterDiscount!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Rating Section
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '(${product.reviews} reviews)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor,),
          SizedBox(height: 16),
          Text('Loading products...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(
      String message, {
        String? errorDetails,
        VoidCallback? onRetry,
      }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorDetails != null) ...[
              SizedBox(height: 8),
              Text(
                errorDetails,
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: Text('Try Again'),
              ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}