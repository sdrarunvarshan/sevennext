import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/cart_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:intl/intl.dart';
import 'package:shop/route/api_service.dart'; // Add this import
import 'package:shop/screens/order/views/orders_screen.dart';
import '../../address/views/addresses_screen.dart';
import '/screens/order/views/orders_repository.dart';
import 'package:shop/models/order_model.dart';
import '../../../components/order_process.dart';
import '../../helpers/user_helper.dart';
// Address Model (same as in addresses_screen.dart)
class Address {
  final String id;
  final String userAddressId;
  final String name;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.userAddressId,
    required this.name,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userAddressId: json['user_address_id'],
      name: json['name'] ?? 'Unnamed',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postal_code'].toString(),
      country: json['country'] ?? '',
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
    );
  }
}
class CartScreen extends StatefulWidget {
  final bool showBackButton;
  const CartScreen({super.key,this.showBackButton = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Cart _cart = Cart();
  final double _shippingFee = 24.00;
  Address? _selectedAddress; // Store the selected address
  bool _isLoadingAddress = true; // Loading state for address

  @override
  void initState() {
    super.initState();
    _fetchDefaultAddress();
  }

  // Fetch the default address from API
  Future<void> _fetchDefaultAddress() async {
    setState(() => _isLoadingAddress = true);

    try {
      final response = await ApiService.get('/users/addresses');
      final List data = response['data'];

      if (data.isNotEmpty) {
        // Find default address or use the first one
        final defaultAddress = data.firstWhere(
              (addr) => addr['is_default'] == 1 || addr['is_default'] == true,
          orElse: () => data.first,
        );

        setState(() {
          _selectedAddress = Address.fromJson(defaultAddress);
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = null;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
      setState(() => _isLoadingAddress = false);
    }
  }

  // Navigate to address selection
  // Replace the _selectAddress method with this:
  Future<void> _selectAddress() async {
    try {
      final response = await ApiService.get('/users/addresses');
      final List<dynamic> addressesList = response['data'];

      if (addressesList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No addresses available')),
          );
        }
        return;
      }

      final addresses = addressesList.map((addr) => Address.fromJson(addr)).toList();

      if (mounted) {
        showModalBottomSheet<Address>(
          context: context,
          builder: (context) => ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return ListTile(
                title: Text(address.name),
                subtitle: Text(
                  '${address.street}, ${address.city}, ${address.country}',
                ),
                trailing: address.isDefault
                    ? const Chip(label: Text('Default'))
                    : null,
                onTap: () {
                  Navigator.pop(context, address);
                },
              );
            },
          ),
        ).then((result) {
          if (result != null) {
            setState(() {
              _selectedAddress = result;
            });
          }
        });
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }
  // Address display widget
  Widget _buildAddressSection() {
    if (_isLoadingAddress) {
      return const Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (_selectedAddress == null) {
      return Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: defaultPadding / 2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  children: [
                    const Text(
                      'No address found',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    ElevatedButton(
                      onPressed: _selectAddress,
                      child: const Text('Add Address'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Address',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge,
              ),
              TextButton(
                onPressed: _selectAddress,
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding / 2),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedAddress!.name,
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      if (_selectedAddress!.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    _selectedAddress!.street,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedAddress!.city}, ${_selectedAddress!
                        .country} ${_selectedAddress!.postalCode}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
          centerTitle: true,
          leading: widget.showBackButton ? const BackButton() : null,

        ),
        body: Column(
          children: [
            // Address Section at the top
            _buildAddressSection(),

            // Cart Items
            Expanded(
              child: _cart.items.isEmpty
                  ? Center(
                child: Text(
                  "Your cart is empty!",
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(defaultPadding / 2),
                itemCount: _cart.items.length,
                itemBuilder: (context, index) {
                  final cartItem = _cart.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: defaultPadding),
                    child: Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(cartItem.product.image),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: defaultPadding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cartItem.product.title,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: defaultPadding / 4),
                                Text(
                                  '\u20B9${cartItem.product.price.toStringAsFixed(
                                      2)}',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: kPrimaryColor),
                                ),
                                const SizedBox(height: defaultPadding / 4),
                                Row(
                                  children: [
                                    Text('Qty: ${cartItem.quantity}'),
                                  ],
                                )
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _cart.removeItem(cartItem);
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Order Summary (only if cart is not empty)
            if (_cart.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('\u20B9${_cart.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: defaultPadding / 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shipping Fee'),
                        Text('\u20B9${_shippingFee.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: defaultPadding * 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\u20B9${(_cart.subtotal + _shippingFee).toStringAsFixed(
                              2)}',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      bottomNavigationBar: _cart.items.isNotEmpty
          ? CartButton(
        price: _cart.subtotal + _shippingFee,
        title: "Proceed to Checkout",
        subTitle: "Total amount",
        press: () async {
          // Check if address is selected
          if (_selectedAddress == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select an address'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          print('CartScreen: Entering checkout process.');

          final authBox = Hive.box('auth');

          if (!authBox.isOpen) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Authentication error. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final String currentUserEmail =
          authBox.get('user_email', defaultValue: '');

          if (currentUserEmail.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'User email missing. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final addressText =
              '${_selectedAddress!.name}\n'
              '${_selectedAddress!.street}\n'
              '${_selectedAddress!.city}, '
              '${_selectedAddress!.country} '
              '${_selectedAddress!.postalCode}';

          final orderId =
          DateTime.now().millisecondsSinceEpoch.toString();

          final orderedProducts = _cart.items.map((cartItem) {
            return OrderedProduct(
              name: cartItem.product.title,
              imageUrl: cartItem.product.image,
              quantity: cartItem.quantity,
              colorHex: cartItem.colorHex.isEmpty
                  ? 'FFFFFFFF'
                  : cartItem.colorHex,
            );
          }).toList();

          final userType = await UserHelper.getUserType();

          final Order newOrder = Order(
            id: orderId,
            placedOn: DateTime.now(),
            orderStatus: OrderProcessStatus.processing,
            processingStatus: OrderProcessStatus.processing,
            packedStatus: OrderProcessStatus.notDoneYeat,
            shippedStatus: OrderProcessStatus.notDoneYeat,
            deliveredStatus: OrderProcessStatus.notDoneYeat,
            products: orderedProducts,
            totalPrice: _cart.subtotal + _shippingFee,
            shippingFee: _shippingFee,
            customerEmail: currentUserEmail,
            customerAddressText: addressText,
            paymentMethod: 'cod',
            paymentStatus: 'paid',
            userType: userType,
          );

          try {
            await OrdersRepository.addOrder(newOrder);
            _cart.clearCart();
            Navigator.pushNamed(context, ordersScreenRoute);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      )
          : null,
    );


  }
}