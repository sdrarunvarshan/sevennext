import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/search/views/components/search_form.dart';
import 'components/expansion_category.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SearchForm(
                readOnly: true, // Make it read-only
                onTap: () {
                  // Navigate to SearchScreen when tapped
                  Navigator.pushNamed(context, searchScreenRoute);
                },
              ),
            ),
            // Rest of your code remains the same...
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding / 2),
              child: Text(
                "Categories",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: demoCategories.length,
                itemBuilder: (context, index) => ExpansionCategory(
                  svgSrc: demoCategories[index].svgSrc ?? "assets/icons/Category.svg",
                  title: demoCategories[index].name,
                  onCategoryTap: () {
                    print('DEBUG: Tapping category: ${demoCategories[index].name}');
                    print('DEBUG: Category route: ${demoCategories[index].route}');

                    final routeName = demoCategories[index].route ?? categoryProductsScreen;

                    final arguments = routeName == gadgetsScreenRoute
                        ? true
                        : demoCategories[index].name;

                    Navigator.pushNamed(
                      context,
                      routeName,
                      arguments: arguments,
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}