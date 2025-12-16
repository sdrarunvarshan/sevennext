import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants.dart';
import '../../route/route_constants.dart';
import '../screens/home/views/components/categories.dart';
// models/category_model.dart

class CategoryModel {
  final String name;
  final String? svgSrc, route;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.name,
    this.svgSrc,
    this.route,
    this.subCategories= const [],
  });

  // Getter for backward compatibility
  String get displayName => name;
}
// Update demoCategories with correct route
List<CategoryModel> demoCategories = [
  CategoryModel(
    name: "All Gadgets",
    svgSrc: "assets/icons/Product.svg",
    route: gadgetsScreenRoute
  ),
  CategoryModel(
    name: "Mobile & Devices",
    svgSrc: "assets/icons/Phone.svg",
    route: categoryProductsScreen
  ),
  CategoryModel(
    name: "Laptops & PCs",
    svgSrc: "assets/icons/Pc.svg",
    route: categoryProductsScreen
  ),
  CategoryModel(
    name: "Cameras & Photography",
    svgSrc: "assets/icons/Cash.svg",
    route: categoryProductsScreen
  ),
  CategoryModel(
    name: "Wearables",
    svgSrc: "assets/icons/Accessories.svg",
    route: categoryProductsScreen
  ),
  CategoryModel(
    name: "TV & Entertainment",
    svgSrc: "assets/icons/tv.svg",
    route: categoryProductsScreen
  ),
  CategoryModel(
    name: "Networking",
    svgSrc: "assets/icons/network.svg",
    route: categoryProductsScreen
  ),
  CategoryModel(
    name: "Peripherals",
    svgSrc: "assets/icons/Child.svg",
    route: categoryProductsScreen
  ),
];

class Categories extends StatelessWidget {
  const Categories({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(
            demoCategories.length,
                (index) => Padding(
              padding: EdgeInsets.only(
                  left: index == 0 ? defaultPadding : defaultPadding / 2,
                  right: index == demoCategories.length - 1
                      ? defaultPadding
                      : 0),
              child: CategoryBtn(
                category: demoCategories[index].name, // Use name
                svgSrc: demoCategories[index].svgSrc,
                isActive: index == 0,
                press: () {
                  if (demoCategories[index].route != null) {
                    Navigator.pushNamed(
                        context,
                        demoCategories[index].route!,
                        arguments: demoCategories[index].name); // Pass name as argument
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    this.svgSrc,
    required this.isActive,
    required this.press,
  });

  final String category;
  final String? svgSrc;
  final bool isActive;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryColor : Colors.transparent,
          border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : Theme.of(context).dividerColor),
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: Row(
          children: [
            if (svgSrc != null)
              SvgPicture.asset(
                svgSrc!,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.white : Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
              ),
            if (svgSrc != null) const SizedBox(width: defaultPadding / 2),
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
