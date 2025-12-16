import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
// Import your Notification model and any state management/API service

// Dummy Notification model
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String svgIconSrc; // e.g., "assets/icons/Discount.svg"

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.svgIconSrc,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Dummy data - replace with actual data fetching
  List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'n1',
      title: "Special Offer!",
      body: "Get 20% off on all dresses. Shop now!",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      svgIconSrc: "assets/icons/Discount.svg",
    ),
    NotificationItem(
      id: 'n2',
      title: "Order Update",
      body: "Your order #12345 has been shipped.",
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      svgIconSrc: "assets/icons/Order.svg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        actions: [
          // Optional: Action to mark all as read or clear
          IconButton(
            onPressed: () {
              // Implement logic to clear all notifications
              setState(() {
                _notifications.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            icon: const Icon(Icons.clear_all),
          )
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/screens/No notification.png", // Use the illustration for empty state
              height: MediaQuery.of(context).size.height * 0.3,
            ),
            const SizedBox(height: defaultPadding * 2),
            Text(
              "No new notifications",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: defaultPadding / 2),
            const Text(
              "You'll see here all the latest news and updates from us.",
              textAlign: TextAlign.center,
              style: TextStyle(color: greyColor),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(defaultPadding),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: defaultPadding),
            child: ListTile(
              leading: SvgPicture.asset(
                notification.svgIconSrc,
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).iconTheme.color!, BlendMode.srcIn),
              ),
              title: Text(notification.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.body),
                  const SizedBox(height: defaultPadding / 4),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: greyColor),
                  ),
                ],
              ),
              onTap: () {
                // Handle notification tap - navigate to relevant screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on ${notification.title}')),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    // Simple formatting, you might want a more robust date formatting library
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
