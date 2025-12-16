// screens/payment/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/cart_model.dart';
import 'package:shop/models/order_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/order/views/orders_repository.dart';
import 'package:intl/intl.dart';
import 'package:shop/screens/address/views/addresses_screen.dart';
import 'package:shop/screens/order/views/orders_screen.dart';
import 'package:shop/screens/helpers/user_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../components/order_process.dart';
class PaymentScreen extends StatefulWidget {
  final Address? selectedAddress;
  final double shippingFee;
  final Cart cart;

  const PaymentScreen({
    super.key,
    required this.selectedAddress,
    required this.shippingFee,
    required this.cart,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'card',
      name: 'Credit/Debit Card',
      icon: Icons.credit_card,
      description: 'Pay with your card',
    ),
    PaymentMethod(
      id: 'upi',
      name: 'UPI',
      icon: Icons.payment,
      description: 'Pay using UPI',
    ),
    PaymentMethod(
      id: 'cod',
      name: 'Cash on Delivery',
      icon: Icons.money,
      description: 'Pay when you receive',
    ),
    PaymentMethod(
      id: 'netbanking',
      name: 'Net Banking',
      icon: Icons.account_balance,
      description: 'Internet banking',
    ),
  ];

  Future<void> _placeOrder() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authBox = Hive.box('auth');
      final String currentUserEmail = authBox.get('user_email', defaultValue: '');

      if (currentUserEmail.isEmpty) {
        throw Exception('User email not found');
      }

      // Create address text
      final addressText = widget.selectedAddress != null
          ? '${widget.selectedAddress!.name}\n${widget.selectedAddress!.street}\n'
          '${widget.selectedAddress!.city}, ${widget.selectedAddress!.country} '
          '${widget.selectedAddress!.postalCode}'
          : '';

      // Create order ID and date
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Convert cart items to ordered products
      final List<OrderedProduct> orderedProducts = widget.cart.items.map((cartItem) {
        final String finalColorHex = cartItem.colorHex.isEmpty
            ? 'FFFFFFFF'
            : cartItem.colorHex;

        return OrderedProduct(
          name: cartItem.product.title,
          imageUrl: cartItem.product.image,
          quantity: cartItem.quantity,
          colorHex: finalColorHex,
        );
      }).toList();

      // Get user type
      final String userType = await UserHelper.getUserType();

      // Create order
      final Order newOrder = Order(
        id: orderId,
        placedOn: DateTime.now(),
        orderStatus: OrderProcessStatus.processing,
        processingStatus: OrderProcessStatus.processing,
        packedStatus: OrderProcessStatus.notDoneYeat,
        shippedStatus: OrderProcessStatus.notDoneYeat,
        deliveredStatus: OrderProcessStatus.notDoneYeat,
        products: orderedProducts,
        totalPrice: widget.cart.subtotal + widget.shippingFee,
        shippingFee: widget.shippingFee,
        customerEmail: currentUserEmail,
        customerAddressText: addressText,
        userType: userType,
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: _selectedPaymentMethod == 'cod' ? 'pending' : 'paid',
      );

      // Save order
      await OrdersRepository.addOrder(newOrder);

      // Clear cart
      widget.cart.clearCart();

      // Navigate to order confirmation
      Navigator.pushReplacementNamed(
        context,
        orderConfirmationScreenRoute,
        arguments: orderId,
      );

    } catch (e) {
      print('Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Method"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Summary",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal"),
                        Text("\$${widget.cart.subtotal.toStringAsFixed(2)}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Shipping"),
                        Text("\$${widget.shippingFee.toStringAsFixed(2)}"),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          "\$${(widget.cart.subtotal + widget.shippingFee).toStringAsFixed(2)}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Payment Methods
            Expanded(
              child: ListView.builder(
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: defaultPadding / 2),
                    child: RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(method.icon, color: kPrimaryColor),
                          const SizedBox(width: defaultPadding / 2),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(method.name),
                              Text(
                                method.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: greyColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      value: method.id,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: CartButton(
          price: widget.cart.subtotal + widget.shippingFee,
          title: "Place Order",
          subTitle: "Pay Now",
          press: _placeOrder,
          isLoading: _isProcessing,
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}