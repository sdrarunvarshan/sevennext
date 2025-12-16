import 'package:flutter/material.dart';
import 'package:shop/entry_point.dart';
import 'package:shop/route/guest_services.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/guest_protect_route.dart';
import 'package:shop/screens/home/views/components/category_products_screen.dart'; // Already imported
import 'package:shop/screens/profile/views/help_screen.dart';
import 'package:shop/screens/profile/views/faq_screen.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../screens/checkout/views/cart_screen.dart';
import '../screens/home/views/gadgets_screen.dart';
import '../screens/payment/views/payment_screen.dart';
import '../screens/payment/views/return_request_screen.dart';
import '../screens/order/views/order_details_screen.dart';
import '../screens/order/views/orders_conformation_screen.dart';
import '../screens/product/views/product_returns_screen.dart';
import 'screen_export.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return MaterialPageRoute(builder: (context) => const OnBordingScreen());
    case entryPointScreenRoute:
      return MaterialPageRoute(builder: (context) => const EntryPoint());
    case logInScreenRoute:
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    case signUpScreenRoute:
      return MaterialPageRoute(builder: (context) => const SignUpScreen());
    case productReturnsScreenRoute:
      return MaterialPageRoute(builder: (context) => const ProductReturnsScreen());
    case orderConfirmationScreenRoute:
      final orderId = settings.arguments as String? ?? '';
      return MaterialPageRoute(builder: (context) => OrderConfirmationScreen(orderId: orderId));
    case paymentScreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        return MaterialPageRoute(
          builder: (context) => PaymentScreen(
            selectedAddress: args['selectedAddress'],
            shippingFee: args['shippingFee'] ?? 0.0,
            cart: args['cart'],
          ),
        );
      }
      return MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Payment information missing'))));
    case productDetailsScreenRoute:
      final product = settings.arguments as ProductModel?;
      return MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product));
    case notificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );
    case noNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NoNotificationScreen(),
      );
    case enableNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EnableNotificationScreen(),
      );
    case notificationOptionsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationOptionsScreen(),
      );
    case faqScreenRoute:
      return MaterialPageRoute(builder: (context) => const FAQScreen());
    case getHelpScreenRoute:
      return MaterialPageRoute(builder: (context) => const HelpScreen());
    case passwordRecoveryScreenRoute:
      return  MaterialPageRoute(builder: (context) => const PasswordRecoveryScreen());
    case categoryProductsScreen:
      final categoryName = settings.arguments as String?;
      return MaterialPageRoute(builder: (context) => CategoryProductsScreen(categoryName: categoryName ?? 'Products'));
    case gadgetsScreenRoute:
      return MaterialPageRoute(builder: (context) => const GadgetsScreen());
    case homeScreenRoute:
      return MaterialPageRoute(builder: (context) => const HomeScreen());
    case searchScreenRoute:
      return MaterialPageRoute(builder: (context) => const SearchScreen());
    case profileScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: profileScreenRoute, child: ProfileScreen()));
    case cartScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: cartScreenRoute, child: CartScreen()));
    case ordersScreenRoute:
      return MaterialPageRoute(builder: (context) => GuestProtectedRoute(routeName: ordersScreenRoute, child: OrdersScreen()));
    case bookmarkScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: bookmarkScreenRoute, child: BookmarkScreen()));
    case addressesScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: addressesScreenRoute, child: AddressesScreen(isSelectingMode: true)));

    case userInfoScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: userInfoScreenRoute, child: UserInfoScreen()));
    case returnRequestScreenRoute:
      final order = settings.arguments as Order? ;
      if (order != null) {
        return MaterialPageRoute(builder: (context) => ReturnRequestScreen(order: order));
      }
      return MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Order information missing'))));
    case orderDetailsScreenRoute:
      final orderId = settings.arguments as String? ?? '';
      return MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: orderId));
    default:
      return MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Page not found'))));
  }
}