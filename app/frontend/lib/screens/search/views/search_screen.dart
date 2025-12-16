import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/api_service.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/helpers/user_helper.dart';
import 'package:shop/screens/search/views/components/search_form.dart'; // Import SearchForm

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _searchController;
  late Future<List<ProductModel>> _productsFuture;
  String? _userType;
  String _currentSearchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _productsFuture = Future.value([]); // Initialize with an empty list
    _initializeUserType();
  }

  Future<void> _initializeUserType() async {
    try {
      final fetchedUserType = await UserHelper.getUserType();
      setState(() {
        _userType = fetchedUserType;
      });
    } catch (e) {
      print('Error loading user type: $e');
      setState(() {
        _userType = 'b2c'; // Default to b2c if error
      });
    }
  }

  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      setState(() {
        _productsFuture = Future.value([]);
        _currentSearchQuery = '';
      });
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentSearchQuery = trimmedQuery;
    });

    try {
      print('=== SEARCH DEBUG INFO ===');
      print('Search query: "$trimmedQuery"');
      print('User type: $_userType');

      // First, try to search without category to get all results
      List<ProductModel> products = await _apiService.searchProducts(
        trimmedQuery,
        userType: _userType,
      );

      // Debug logging
      print('Number of products returned: ${products.length}');
      for (var product in products) {
        print('Product: ${product.title}, Category: ${product.category}');
      }
      print('=== END DEBUG INFO ===');

      // Filter for exact matches (case insensitive)
      final exactMatches = products.where((product) {
        final productTitle = product.title.toLowerCase().trim();
        final searchQuery = trimmedQuery.toLowerCase().trim();

        // Check for exact match
        return productTitle == searchQuery;
      }).toList();

      // If we found exact matches, display only those
      if (exactMatches.isNotEmpty) {
        setState(() {
          _productsFuture = Future.value(exactMatches);
        });
      } else {
        // If no exact matches, display all products that contain the search query
        final partialMatches = products.where((product) {
          final productTitle = product.title.toLowerCase();
          final searchQuery = trimmedQuery.toLowerCase();

          // Check if product title contains the search query
          return productTitle.contains(searchQuery);
        }).toList();

        setState(() {
          _productsFuture = Future.value(partialMatches.isNotEmpty ? partialMatches : products);
        });
      }

    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _productsFuture = Future.error('Failed to load products: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSearch() async {
    await _performSearch(_currentSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: SearchForm(
              autofocus: true,
              controller: _searchController, // Pass the controller
              onFieldSubmitted: (value) {
                _performSearch(value ?? '');
              },
              onChanged: (value) {
                // Optionally trigger search on change after a delay
                // or just update internal state if needed.
                // For now, only onFieldSubmitted will trigger search.
              }, readOnly: false,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshSearch,
      child: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            return _buildLoadingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(
              'Error loading products',
              errorDetails: snapshot.error.toString(),
              onRetry: _refreshSearch,
            );
          }

          if (snapshot.connectionState == ConnectionState.done &&
              (!snapshot.hasData || snapshot.data!.isEmpty)) {
            if (_currentSearchQuery.isEmpty) {
              return _buildInitialSearchScreen();
            } else {
              return _buildEmptyScreen();
            }
          }

          final products = snapshot.data!;
          return _buildProductsGrid(products);
        },
      ),
    );
  }

  Widget _buildInitialSearchScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Start searching for products!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a keyword in the search bar above.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found for "${_currentSearchQuery}"!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or check for typos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshSearch,
            child: const Text('Refresh Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return Column(
      children: [
        if (_userType != null)
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
                  '(${products.length} products found)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.builder(
                padding: const EdgeInsets.all(defaultPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: defaultPadding,
                  mainAxisSpacing: defaultPadding,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    image: product.image,
                    brandName: product.brandName,
                    title: product.title,
                    price: product.price,
                    priceAfetDiscount: product.priceAfterDiscount,
                    dicountpercent: product.discountPercent,
                    press: () {
                      Navigator.pushNamed(
                        context,
                        productDetailsScreenRoute,
                        arguments: product,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          SizedBox(height: 16),
          Text('Searching products...'),
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
