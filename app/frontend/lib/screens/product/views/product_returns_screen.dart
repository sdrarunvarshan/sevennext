import 'package:flutter/material.dart';

import '../../../components/order_process.dart';
import '../../../constants.dart';
import '../../../models/order_model.dart';
import '../../order/views/orders_repository.dart';

// Update your existing ProductReturnsScreen to show user's return requests
class ProductReturnsScreen extends StatefulWidget {
  const ProductReturnsScreen({super.key});

  @override
  State<ProductReturnsScreen> createState() => _ProductReturnsScreenState();
}

class _ProductReturnsScreenState extends State<ProductReturnsScreen> {
  List<Order> _returnOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReturnOrders();
  }

  Future<void> _loadReturnOrders() async {
    try {
      final orders = await OrdersRepository.getOrders();
      setState(() {
        _returnOrders = orders.where((order) =>
        order.orderStatus == OrderProcessStatus.canceled ||
            order.orderStatus == OrderProcessStatus.returned
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading return orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: defaultPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 40,
                    child: BackButton(),
                  ),
                  Text(
                    "My Returns",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : _returnOrders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.undo,
                      size: 80,
                      color: greyColor,
                    ),
                    const SizedBox(height: defaultPadding),
                    Text(
                      "No Return Requests",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: defaultPadding * 2),
                      child: Text(
                        "You haven't requested any returns yet. If you need to return an item, go to your order details and click 'Request Return'.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: greyColor),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(defaultPadding),
                itemCount: _returnOrders.length,
                itemBuilder: (context, index) {
                  final order = _returnOrders[index];
                  return Card(
                    child: ListTile(
                      title: Text("Order #${order.id}"),
                      subtitle: Text(
                        "Status: ${order.orderStatus.toString().split('.').last}",
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to return details
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}