import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';

import '../../../route/api_service.dart';
import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "Guest";
  String _email = "Sign in to unlock features";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authBox = Hive.box('auth');

    final isGuest = authBox.get('is_guest', defaultValue: true);
    final token = authBox.get('token');

    String tempName;
    String tempEmail;

    // Guest or no token → show default
    if (isGuest || token == null) {
      tempName = "Guest";
      tempEmail = "Sign in to unlock features";

      // Only update if changed
      if (_name != tempName || _email != tempEmail) {
        setState(() {
          _name = tempName;
          _email = tempEmail;
        });
      }
      return;
    }

    // USER LOGGED IN → Call backend
    try {
      final profile = await ApiService.getUserProfile();

      tempName = profile["full_name"] ?? "User";
      tempEmail = profile["email"] ?? "";

      // Save for future use
      authBox.put("user_name", tempName);
      authBox.put("user_email", tempEmail);

      // Update state only if changed
      if (_name != tempName || _email != tempEmail) {
        setState(() {
          _name = tempName;
          _email = tempEmail;
        });
      }
    } catch (e) {
      print("Failed to load profile: $e");

      // On error fallback to stored data
      final storedName = authBox.get('user_name', defaultValue: "User");
      final storedEmail = authBox.get('user_email', defaultValue: "");

      if (_name != storedName || _email != storedEmail) {
        setState(() {
          _name = storedName;
          _email = storedEmail;
        });
      }
    }
  }

  // Helper function to get initials from a name
  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else if (nameParts.length >= 2) {
      return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1)).toUpperCase();
    } else {
      return ""; // Should not happen for valid names
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ProfileCard(
            name: _name,
            email: _email,
            // Use CircleAvatar to display initials
            profileImageWidget: CircleAvatar(
              radius: 30, // Adjust radius as needed
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                _getInitials(_name),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            press: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserInfoScreen()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Text(
              "Account",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          ProfileMenuListTile(
            text: "Orders",
            svgSrc: "assets/icons/Order.svg",
            press: () {
              Navigator.pushNamed(context, ordersScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Returns",
            svgSrc: "assets/icons/Return.svg",
            press: () {
              Navigator.pushNamed(context, productReturnsScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Wishlist",
            svgSrc: "assets/icons/Wishlist.svg",
            press: () {
              Navigator.pushNamed(context, cartScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Addresses",
            svgSrc: "assets/icons/Address.svg",
            press: () {
              Navigator.pushNamed(context, addressesScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Payment",
            svgSrc: "assets/icons/card.svg",
            press: () {
              Navigator.pushNamed(context, emptyPaymentScreenRoute);
            },
          ),
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: Text(
              "Personalization",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          DividerListTileWithTrilingText(
            svgSrc: "assets/icons/Notification.svg",
            title: "Notification",
            trilingText: "Off",
            press: () {
              Navigator.pushNamed(context, enableNotificationScreenRoute);
            },
          ),
          const SizedBox(height: defaultPadding),
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: Text(
              "Help & Support",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ProfileMenuListTile(
            text: "Get Help",
            svgSrc: "assets/icons/Help.svg",
            press: () {
              Navigator.pushNamed(context, getHelpScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "FAQ",
            svgSrc: "assets/icons/FAQ.svg",
            press: () {
             Navigator.pushNamed(context, faqScreenRoute);

            },
          ),
          const SizedBox(height: defaultPadding),

          // Log Out
          ListTile(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            minLeadingWidth: 24,
            leading: SvgPicture.asset(
              "assets/icons/Logout.svg",
              height: 24,
              width: 24,
              colorFilter: const ColorFilter.mode(
                errorColor,
                BlendMode.srcIn,
              ),
            ),
            title: const Text(
              "Log Out",
              style: TextStyle(color: errorColor, fontSize: 14, height: 1),
            ),
          )
        ],
      ),
    );
  }
}
