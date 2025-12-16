import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoSwitch
import 'package:shop/constants.dart';
// Reuse PreferencesListTile if it fits, or create a similar structure

class NotificationOptionsScreen extends StatefulWidget {
  const NotificationOptionsScreen({super.key});

  @override
  State<NotificationOptionsScreen> createState() => _NotificationOptionsScreenState();
}

class _NotificationOptionsScreenState extends State<NotificationOptionsScreen> {
  // Dummy notification settings - replace with actual user preferences
  bool _promotionsEnabled = true;
  bool _orderUpdatesEnabled = true;
  bool _appNewsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage your notification preferences",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: defaultPadding),
            // Example using CupertinoSwitch within a ListTile
            ListTile(
              title: const Text("Promotions and offers"),
              trailing: CupertinoSwitch(
                value: _promotionsEnabled,
                activeColor: kPrimaryColor,
                onChanged: (value) {
                  setState(() {
                    _promotionsEnabled = value;
                  });
                  // Save preference logic here
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text("Order updates"),
              trailing: CupertinoSwitch(
                value: _orderUpdatesEnabled,
                activeColor: kPrimaryColor,
                onChanged: (value) {
                  setState(() {
                    _orderUpdatesEnabled = value;
                  });
                  // Save preference logic here
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text("App news and tips"),
              trailing: CupertinoSwitch(
                value: _appNewsEnabled,
                activeColor: kPrimaryColor,
                onChanged: (value) {
                  setState(() {
                    _appNewsEnabled = value;
                  });
                  // Save preference logic here
                },
              ),
            ),
            const Divider(height: 1),
            // You can add more options here as needed
            const Spacer(), // Pushes button to bottom if needed
            // Potentially a save button if preferences aren't saved automatically
            // ElevatedButton(
            //   onPressed: () {
            //     // Save all preferences
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text('Preferences saved')),
            //     );
            //     Navigator.pop(context);
            //   },
            //   child: const Text("Save Settings"),
            // ),
          ],
        ),
      ),
    );
  }
}
