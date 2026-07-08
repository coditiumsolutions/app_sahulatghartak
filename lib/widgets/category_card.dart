import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/category.dart';
import '../screens/service_request_form_screen.dart';
import '../utils/category_icons.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final Color? backgroundColor;
  const CategoryCard({Key? key, required this.category, this.backgroundColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(ServiceRequestFormScreen.routeName, arguments: category),
      child: Animate(
        effects: const [ScaleEffect(duration: Duration(milliseconds: 300)), FadeEffect()],
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: (backgroundColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),
                child: Icon(getCategoryIcon(category.name), size: 36, color: backgroundColor ?? Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 12),
              Text(category.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
