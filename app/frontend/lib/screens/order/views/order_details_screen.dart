// screens/orders/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order_model.dart';
import 'package:shop/screens/order/views/orders_repository.dart';
import 'package:intl/intl.dart';

import '../../../components/order_process.dart';
import '../../../route/route_constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      // Get all orders and find the one with matching ID
      final orders = await OrdersRepository.getOrders();
      final order = orders.firstWhere(
            (order) => order.id == widget.orderId,
        orElse: () => Order(
          id: '',
          placedOn: DateTime.now(),
          orderStatus: OrderProcessStatus.notDoneYeat,
          processingStatus: OrderProcessStatus.notDoneYeat,
          packedStatus: OrderProcessStatus.notDoneYeat,
          shippedStatus: OrderProcessStatus.notDoneYeat,
          deliveredStatus: OrderProcessStatus.notDoneYeat,
          products: [],
          totalPrice: 0,
          shippingFee: 0,
          customerEmail: '',
          customerAddressText: '',
          paymentMethod: '',
          paymentStatus: '',
        ),
      );

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading order details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Order Details"),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_order == null || _order!.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Order Details"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: defaultPadding),
              const Text(
                "Order not found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(
                "Order ID: ${widget.orderId}",
                style: const TextStyle(color: greyColor),
              ),
              const SizedBox(height: defaultPadding),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: ListView(
          children: [
            // Order Summary Card
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
                          "Order #${order.id}",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Chip(
                          label: Text(
                            order.orderStatus.toString().split('.').last,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(order.orderStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Text(
                      "Placed on: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.placedOn)}",
                      style: const TextStyle(color: greyColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Delivery Address
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivery Address",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Text(order.customerAddressText),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Order Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Items (${order.products.length})",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    ...order.products.map((product) {
                      final Color color = Color(
                        int.parse('0x${product.colorHex.padLeft(8, '0')}'),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: defaultPadding),
                        child: Row(
                          children: [
                            // Product Image with Color
                            Stack(
                              children: [
                                // Color swatch background
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: color,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                // Image overlay
                                if (product.imageUrl.startsWith('http'))
                                  Image.network(
                                    product.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                else if (product.imageUrl.isNotEmpty)
                                  Image.asset(
                                    product.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                              ],
                            ),
                            const SizedBox(width: defaultPadding / 2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    "Quantity: ${product.quantity}",
                                    style: const TextStyle(color: greyColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Price Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price Breakdown",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    _buildPriceRow("Subtotal", _calculateSubtotal(order)),
                    const SizedBox(height: 8),
                    _buildPriceRow("Shipping", order.shippingFee),
                    const SizedBox(height: 8),
                    _buildPriceRow("Tax", _calculateTax(order)),
                    const Divider(height: 24),
                    _buildPriceRow(
                      "Total",
                      order.totalPrice,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Payment Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Information",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Row(
                      children: [
                        const Icon(Icons.credit_card, size: 20),
                        const SizedBox(width: 8),
                        Text("Payment Method: ${order.paymentMethod}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.payment, size: 20),
                        const SizedBox(width: 8),
                        Text("Payment Status: ${order.paymentStatus}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Order Status Timeline
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Status",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    _buildStatusTimeline(order),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Return Button (only for delivered orders)
            if (order.deliveredStatus == OrderProcessStatus.delivered)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    returnRequestScreenRoute,
                    arguments: order,
                  );
                },
                icon: const Icon(Icons.undo),
                label: const Text("Request Return"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              : null,
        ),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: isTotal
              ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              : null,
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(Order order) {
    final statuses = [
      {
        'title': 'Order Placed',
        'status': true,
        'date': order.placedOn,
      },
      {
        'title': 'Processing',
        'status': order.processingStatus != OrderProcessStatus.notDoneYeat,
        'date': order.placedOn.add(const Duration(days: 1)),
      },
      {
        'title': 'Packed',
        'status': order.packedStatus != OrderProcessStatus.notDoneYeat,
        'date': order.placedOn.add(const Duration(days: 2)),
      },
      {
        'title': 'Shipped',
        'status': order.shippedStatus != OrderProcessStatus.notDoneYeat,
        'date': order.placedOn.add(const Duration(days: 3)),
      },
      {
        'title': 'Delivered',
        'status': order.deliveredStatus == OrderProcessStatus.delivered,
        'date': order.placedOn.add(const Duration(days: 5)),
      },
    ];

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = status['status'] as bool;
        final isLast = index == statuses.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            Column(
              children: [
                // Dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                // Line
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: defaultPadding),
            // Status details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                        .format(status['date'] as DateTime)
                        : 'Pending',
                    style: TextStyle(
                      color: isCompleted ? greyColor : Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getStatusColor(OrderProcessStatus status) {
    switch (status) {
      case OrderProcessStatus.delivered:
        return Colors.green;
      case OrderProcessStatus.shipped:
        return Colors.blue;
      case OrderProcessStatus.processing:
        return Colors.orange;
      case OrderProcessStatus.canceled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _calculateSubtotal(Order order) {
    return order.totalPrice - order.shippingFee;
  }

  double _calculateTax(Order order) {
    // Assuming 10% tax for example
    return (order.totalPrice - order.shippingFee) * 0.1;
  }
}