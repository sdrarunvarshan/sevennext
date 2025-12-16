import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../banner_discount_tag.dart';
import 'banner_m.dart';
import '../../../constants.dart';

class BannerMStyle2 extends StatelessWidget {
  const BannerMStyle2({
    super.key,
    this.image = "https://i.imgur.com/cTY9uJO.jpeg",
    required this.title,
    required this.press,
    this.subtitle,
    required this.discountParcent,
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
        // -------------------------------------------------
        // 1. Stack → absolute positioning for the tag
        // -------------------------------------------------
        Stack(
          children: [
            // -------------------------------------------------
            // 2. Main content (title, subtitle, button)
            // -------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text column – aligned to the **start**
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: defaultPadding / 2), // reserve space for the tag
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: grandisExtendedFont,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: defaultPadding / 4),
                          Text(
                            subtitle!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              height: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: defaultPadding),
                  // Arrow button
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: press,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.white,
                      ),
                      child: SvgPicture.asset(
                        "assets/icons/Arrow - Right.svg",
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------------------------------
            // 3. Discount tag – **center horizontally**, **top**
            // -------------------------------------------------
            Positioned(
              top: 0,               // same padding as the Row
              left: 0,
              right: 0,
              child: Center(
                child: BannerDiscountTag(percentage: discountParcent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}