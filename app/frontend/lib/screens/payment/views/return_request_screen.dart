// screens/returns/return_request_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order_model.dart';
import 'package:shop/screens/order/views/orders_repository.dart';

class ReturnRequestScreen extends StatefulWidget {
  final Order order;

  const ReturnRequestScreen({super.key, required this.order});

  @override
  State<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  String _selectedReason = '';
  String _additionalDetails = '';
  List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  final List<String> _returnReasons = [
    'Wrong item delivered',
    'Item damaged',
    'Quality not as expected',
    'Changed my mind',
    'Wrong size',
    'Better price available',
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(image.path);
      });
    }
  }

  Future<void> _submitReturnRequest() async {
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for return'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // In a real app, you would upload images to a server
      // For now, we'll just update the order status locally

      // Update order status to "return requested"
      // You need to implement this method in OrdersRepository
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit return request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Return"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: ListView(
          children: [
            // Order Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${widget.order.id}",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Placed on: ${DateFormat('dd MMM yyyy').format(widget.order.placedOn)}",
                      style: const TextStyle(color: greyColor),
                    ),
                    Text(
                      "Total: \$${widget.order.totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(color: greyColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Reason for Return
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reason for Return",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._returnReasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value!;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Additional Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Additional Details",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe the issue in detail...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _additionalDetails = value;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Upload Images
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Images",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Upload images showing the issue (max 5)",
                      style: const TextStyle(color: greyColor),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._selectedImages.map((imagePath) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(imagePath)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.remove(imagePath);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        if (_selectedImages.length < 5)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: greyColor),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 32,
                                color: greyColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: defaultPadding * 2),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReturnRequest,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: kPrimaryColor)
                  : const Text("Submit Return Request"),
            ),
          ],
        ),
      ),
    );
  }
}