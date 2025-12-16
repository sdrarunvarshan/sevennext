import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import '../../../components/network_image_with_loader.dart';
import '../../../route/api_service.dart';
import 'components/notify_me_card.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import 'components/product_list_tile.dart';
import '../../../components/review_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/screens/product/views/bookmark_manager.dart';
import 'package:shop/models/cart_model.dart';
import 'package:shop/screens/product/views/added_to_cart_message_screen.dart';
import 'package:shop/screens/product/views/components/product_quantity.dart';
import 'package:shop/screens/product/views/components/selected_colors.dart';
import 'package:shop/screens/product/views/components/unit_price.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, this.product, this.userType});

  final ProductModel? product;
  final String? userType;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedColorIndex = 0;
  Color? _selectedColor;
  List<dynamic> _productReviews = [];
  bool _isLoadingReviews = true;

  final List<Color> _availableColors = const [
    Color(0xFFEA6262),
    Color(0xFFB1CC63),
    Color(0xFFFFBF5F),
    Color(0xFF9FE1DD),
    Color(0xFFC482DB),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = _availableColors.first;
    _loadProductReviews();
  }

  Future<void> _loadProductReviews() async {
    if (widget.product == null) {
      setState(() {
        _isLoadingReviews = false;
      });
      return;
    }

    // Simulate loading reviews
    await Future.delayed(Duration(milliseconds: 500));

    // For now, use mock data
    setState(() {
      _productReviews = List.generate(
          5,
              (index) => {
            'id': 'review_$index',
            'userName': 'User ${index + 1}',
            'rating': (index % 5) + 1.0,
            'comment': 'Great product! ${index + 1}',
            'date': DateTime.now().subtract(Duration(days: index * 10)),
          });
      _isLoadingReviews = false;
    });
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _onColorSelected(int index) {
    setState(() {
      _selectedColorIndex = index;
      _selectedColor = _availableColors[index];
    });
  }

  void _addToCart() {
    final ProductModel currentProduct = widget.product ??
        ProductModel(
          image: "https://via.placeholder.com/150",
          brandName: "Unknown Brand",
          title: "Product Not Found",
          price: 0.0,
          images: [],
          isAvailable: false,
          description: "Details for this product are not available.",
          rating: 0.0,
          reviews: 0,
          id: '',
          discountPercent: 0,
        );

    final String colorHex = _selectedColor!
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();

    Cart().addItem(currentProduct, colorHex);

    customModalBottomSheet(
      context,
      isDismissible: false,
      child: const AddedToCartMessageScreen(),
    );
  }

  void _buyNow() {
    final ProductModel currentProduct = widget.product ??
        ProductModel(
          image: "https://via.placeholder.com/150",
          brandName: "Unknown Brand",
          title: "Product Not Found",
          price: 0.0,
          images: [],
          isAvailable: false,
          description: "Details for this product are not available.",
          rating: 0.0,
          reviews: 0,
          id: '',
          discountPercent: 0,
        );

    final String colorHex = _selectedColor!
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();

    Cart().addItem(currentProduct, colorHex);

    Navigator.pushNamed(context, cartScreenRoute);
  }

  Map<String, int> _calculateReviewStats() {
    int fiveStar = 0,
        fourStar = 0,
        threeStar = 0,
        twoStar = 0,
        oneStar = 0;

    for (var review in _productReviews) {
      final rating = review['rating'] ?? 0;
      switch (rating.round()) {
        case 5:
          fiveStar++;
          break;
        case 4:
          fourStar++;
          break;
        case 3:
          threeStar++;
          break;
        case 2:
          twoStar++;
          break;
        case 1:
          oneStar++;
          break;
      }
    }

    return {
      'fiveStar': fiveStar,
      'fourStar': fourStar,
      'threeStar': threeStar,
      'twoStar': twoStar,
      'oneStar': oneStar,
    };
  }

  Widget _buildBottomBar(BuildContext context, ProductModel currentProduct) {
    if (widget.product != null && currentProduct.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          border: Border(
            top: BorderSide(
              color: blackColor20,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                  ),
                ),
                child: const Text("Add to Cart"),
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: ElevatedButton(
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                  ),
                ),
                child: const Text("Buy Now"),
              ),
            ),
          ],
        ),
      );
    } else if (widget.product != null && !currentProduct.isAvailable) {
      return NotifyMeCard(
        isNotify: false,
        onChanged: (value) {
          if (value) {
            print("Subscribed to notifications for ${currentProduct.title}");
          }
        },
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Text(
          "Product information not available",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProductModel currentProduct = widget.product ??
        ProductModel(
          image: "https://via.placeholder.com/150",
          brandName: "Unknown Brand",
          title: "Product Not Found",
          price: 0.0,
          images: [],
          isAvailable: false,
          description: "Details for this product are not available.",
          rating: 0.0,
          reviews: 0,
          id: '',
          discountPercent: 0,
        );

    final List<String> imagesToShow =
    (currentProduct.images != null && currentProduct.images!.isNotEmpty)
        ? currentProduct.images!
        : [currentProduct.image];

    final reviewStats = _calculateReviewStats();
    final totalReviews = _productReviews.length;

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(context, currentProduct),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: kBackgroundColor,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                currentProduct.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              actions: [
                ValueListenableBuilder<List<ProductModel>>(
                  valueListenable: BookmarkManager.instance.bookmarkedProducts,
                  builder: (context, bookmarkedProducts, child) {
                    final bool isBookmarked =
                    BookmarkManager.instance.isBookmarked(currentProduct);
                    return IconButton(
                      onPressed: () {
                        BookmarkManager.instance.toggleBookmark(currentProduct);
                      },
                      icon: SvgPicture.asset(
                        "assets/icons/Bookmark.svg",
                        colorFilter: ColorFilter.mode(
                          isBookmarked ? kPrimaryColor : whileColor60,
                          BlendMode.srcIn,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Product Images - Already a sliver
            ProductImages(images: imagesToShow),

            // Product Info - Already a sliver
            ProductInfo(
              brand: currentProduct.brandName,
              title: currentProduct.title,
              isAvailable: currentProduct.isAvailable,
              description: currentProduct.description ??
                  "No description available.",
              rating: currentProduct.rating,
              numOfReviews: currentProduct.reviews,
            ),

            // Quantity Selector
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: UnitPrice(
                        price: currentProduct.price,
                        priceAfterDiscount: currentProduct.priceAfterDiscount,
                      ),
                    ),
                    ProductQuantity(
                      numOfItem: _quantity,
                      onIncrement: _incrementQuantity,
                      onDecrement: _decrementQuantity,
                    ),
                  ],
                ),
              ),
            ),

            // Color Selection
            SliverToBoxAdapter(
              child: SelectedColors(
                colors: _availableColors,
                selectedColorIndex: _selectedColorIndex,
                press: _onColorSelected,
              ),
            ),

            // Product Details Section
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product Details",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Text(
                      currentProduct.description ??
                          "No detailed description available.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // Reviews Section
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: _isLoadingReviews
                    ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : totalReviews == 0
                    ? Container(
                  padding: const EdgeInsets.all(defaultPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.035),
                    borderRadius:
                    BorderRadius.circular(defaultBorderRadious),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "No reviews yet",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Be the first to review this product!",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
                    : ReviewCard(
                  rating: currentProduct.rating,
                  numOfReviews: totalReviews,
                  numOfFiveStar: reviewStats['fiveStar'] ?? 0,
                  numOfFourStar: reviewStats['fourStar'] ?? 0,
                  numOfThreeStar: reviewStats['threeStar'] ?? 0,
                  numOfTwoStar: reviewStats['twoStar'] ?? 0,
                  numOfOneStar: reviewStats['oneStar'] ?? 0,
                ),
              ),
            ),

            // View All Reviews - ProductListTile is already a sliver, so use it directly
            if (totalReviews > 0)
              ProductListTile(
                svgSrc: "assets/icons/Chat.svg",
                title: "View All Reviews ($totalReviews)",
                isShowBottomBorder: true,
                press: () {
                  Navigator.pushNamed(
                    context,
                    productReviewsScreenRoute,
                    arguments: {
                      'productId': currentProduct.id,
                      'reviews': _productReviews,
                    },
                  );
                },
              ),

            // Write a Review - ProductListTile is already a sliver
            ProductListTile(
              svgSrc: "assets/icons/Edit.svg",
              title: "Write a Review",
              press: () {
                Navigator.pushNamed(
                  context,
                  addReviewsScreenRoute,
                  arguments: {
                    'product': currentProduct,
                  },
                ).then((value) {
                  if (value == true) {
                    _loadProductReviews();
                  }
                });
              },
            ),

            // You may also like Section
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "You may also like",
                          style: Theme.of(context).textTheme.titleSmall!,
                        ),

                      ],
                    ),
                    const SizedBox(height: defaultPadding),
                    // Wrap FutureBuilder in Container with fixed height
                    Container(
                      height: 260, // Give enough height for all states
                      child: FutureBuilder<List<ProductModel>>(
                        future: widget.product != null
                            ? ApiService().getRecommendedProducts(
                          widget.product!.id,
                          widget.userType ?? 'b2c',
                          limit: 10,
                        )
                            : Future.value([]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: kPrimaryColor),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Unable to load recommendations',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        // Retry loading
                                      });
                                    },
                                    child: const Text('Try again'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'No recommendations available',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }

                          final recommendedProducts = snapshot.data!;
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: recommendedProducts.length,
                            separatorBuilder: (context, index) =>
                            const SizedBox(width: defaultPadding),
                            itemBuilder: (context, index) {
                              final p = recommendedProducts[index];
                              return SizedBox(
                                width: 150,
                                child: ProductCard(
                                  image: p.image,
                                  title: p.title,
                                  brandName: p.brandName,
                                  price: p.price,
                                  priceAfetDiscount: p.priceAfterDiscount,
                                  dicountpercent: p.discountPercent,
                                  press: () {
                                    Navigator.pushNamed(
                                      context,
                                      productDetailsScreenRoute,
                                      arguments: p,
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}