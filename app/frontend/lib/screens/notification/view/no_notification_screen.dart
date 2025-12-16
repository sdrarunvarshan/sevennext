import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class NoNotificationScreen extends StatelessWidget {
  const NoNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/screens/No notification.png", // Use the provided asset
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
              const SizedBox(height: defaultPadding * 2),
              // Optionally, add a button to go back or refresh
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              //   child: const Text("Go Back"),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
