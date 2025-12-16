import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class ExpansionCategory extends StatelessWidget {
  const ExpansionCategory({
    super.key,
    required this.title,
    required this.svgSrc,
    this.onCategoryTap,
  });

  final String title, svgSrc;
  final VoidCallback? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ListTile(
        // Completely remove trailing
        // Adjust visual density to reduce space
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.zero,
        // Remove any default padding

        // Main category tap handler - call the provided callback
        // Keep your existing code...
        iconColor: Theme.of(context).textTheme.bodyLarge!.color,
        leading: SvgPicture.asset(
          svgSrc,
          height: 24,
          width: 24,
          colorFilter: ColorFilter.mode(
            Theme.of(context).iconTheme.color!,
            BlendMode.srcIn,
          ),
        ),
        title: GestureDetector(
          onTap: onCategoryTap, // Also allow tap on the title directly
          child: Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        textColor: Theme.of(context).textTheme.bodyLarge!.color,

        // REMOVE THE ENTIRE CHILDREN PROPERTY - This is the fix!
        // Since you don't have subcategories, don't include children at all
      ),
    );
  }
}