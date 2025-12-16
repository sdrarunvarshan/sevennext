import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'banner_m.dart';
import '../../../constants.dart';

class BannerMStyle4 extends StatelessWidget {
  const BannerMStyle4({
    super.key,
    this.image = "https://i.imgur.com/UPVBysL.jpeg",
    required this.title,
    required this.press,
    required this.discountParcent,
    this.subtitle,
  });
  final String? image;
  final String title;
  final String? subtitle;
  final int discountParcent;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return BannerM(
      image: image!,
      press: press,
      children: [
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // Changed to end to align with bottom
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultPadding / 2,
                          vertical: defaultPadding / 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(4), // Added slight rounding
                        ),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: defaultPadding / 4),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: grandisExtendedFont,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1, // Slightly increased for better readability
                      ),
                    ),
                    const SizedBox(height: defaultPadding / 8),
                    Text(
                      "UP TO $discountParcent% OFF",
                      style: const TextStyle(
                        fontFamily: grandisExtendedFont,
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: defaultPadding),
              Align(
                alignment: Alignment.bottomCenter, // Ensures button aligns with bottom content
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: press,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero, // Remove default padding
                    ),
                    child: SvgPicture.asset(
                      "assets/icons/Arrow - Right.svg",
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                      width: 20, // Specify icon size
                      height: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}