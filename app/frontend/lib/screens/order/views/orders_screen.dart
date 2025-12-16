import 'package:flutter/material.dart';
import 'package:shop/components/order_status_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/screen_export.dart';
import '../../../models/order_model.dart';
import '../views/orders_repository.dart';
import '../../../components/order_process.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await OrdersRepository.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  // ADD THIS METHOD - it was missing
  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Force fetch from backend (not from cache)
      final orders = await OrdersRepository.refreshOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orders refreshed successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error refreshing orders: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh orders: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }



  // Refresh orders when screen comes into focus
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)!.isCurrent) {
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Orders"),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
        actions: [ // Add this actions property
          IconButton(
            onPressed: _refreshOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: _orders.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                Theme.of(context).brightness == Brightness.light
                    ? "assets/Illustration/EmptyState_lightTheme.png"
                    : "assets/Illustration/EmptyState_darkTheme.png",
                width: MediaQuery.of(context).size.width * 0.5,
              ),
              const SizedBox(height: defaultPadding),
              Text(
                "No Orders Yet",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: defaultPadding / 2),
              const Text(
                "You haven't placed any orders yet. Let's find something for you.",
                textAlign: TextAlign.center,
                style: TextStyle(color: greyColor),
              ),
              const SizedBox(height: defaultPadding * 2),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, entryPointScreenRoute);
                },
                child: const Text("Start Shopping"),
              ),
            ],
          ),
        )

        : RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.builder(
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];

              List<Widget> productWidgets =
              order.products.map((product) {
                String imageUrl = product.imageUrl;

                // Convert colorHex back to Color object for display
                final Color color = Color(int.parse(
                    '0x${product.colorHex.padLeft(8, '0')}'));

                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: defaultPadding / 4),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          // Color swatch background
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: color,
                              border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1),
                            ),
                          ),
                          // Image overlay (if available)
                          if (imageUrl.startsWith('http'))
                            Image.network(
                              imageUrl,
                              height: 30,
                              width: 30,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  size: 30),
                            )
                          else if (imageUrl.isNotEmpty)
                            Image.asset(
                              imageUrl,
                              height: 30,
                              width: 30,
                              fit: BoxFit.cover,
                            ),
                        ],
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      Expanded(
                        child: Text(
                          "${product.name} (x${product.quantity})",
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();

              return Padding(
                padding:
                const EdgeInsets.only(bottom: defaultPadding),
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: double.infinity),
                  child: OrderStatusCard(
                    orderId: order.id,
                    placedOn: DateFormat('dd/MM/yyyy')
                        .format(order.placedOn), // Format DateTime to String
                    orderStatus: order.orderStatus,
                    processingStatus: order.processingStatus,
                    packedStatus: order.packedStatus,
                    shippedStatus: order.shippedStatus,
                    deliveredStatus: order.deliveredStatus,
                    isCancled: order.deliveredStatus ==
                        OrderProcessStatus.canceled,
                    products: productWidgets,
                    press: () {
                      Navigator.pushNamed(
                          context, orderDetailsScreenRoute,
                          arguments: order.id);
                    },
                    // onDelete: () => _deleteSingleOrder(order.id, index), // Uncomment if you want to enable delete functionality
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}