import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening system settings

class EnableNotificationScreen extends StatelessWidget {
  const EnableNotificationScreen({super.key});

  // Make this method accessible within the build context
  Future<void> _openNotificationSettings(BuildContext context) async {
    // This is a simplified example. Opening system settings varies by platform.
    // For Android, you might use:
    // final Uri settingsUri = Uri.parse('app-settings:');
    // For iOS, it's more complex and often requires specific packages or platform channels.
    // A common approach is to link to general app settings if direct notification settings are hard to reach.

    // For demonstration, let's try opening a generic settings URI
    const url = 'app-settings:'; // This might open the main app settings page
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback if app-settings URI doesn't work
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open notification settings. Please check your device settings manually.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/screens/Enable notification.png", // Use the provided asset
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const SizedBox(height: defaultPadding * 2),
              Text(
                "Enable Notifications",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: defaultPadding / 2),
              const Text(
                "Stay updated with your orders and exclusive offers by enabling notifications.",
                textAlign: TextAlign.center,
                style: TextStyle(color: greyColor),
              ),
              const Spacer(),
              ElevatedButton(
                // Pass context to the method
                onPressed: () => _openNotificationSettings(context),
                child: const Text("Enable Notifications"),
              ),
              const SizedBox(height: defaultPadding),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back if user doesn't want to enable
                },
                child: const Text("Maybe Later"),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
