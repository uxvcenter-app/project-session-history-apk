import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// Badge visuel représentant une catégorie détectée automatiquement par
/// l'IA (icône + nom, sur fond teinté de la couleur de la catégorie).
class CategoryBadge extends StatelessWidget {
  final CategoryModel category;
  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: category.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, color: category.color, size: 18),
          const SizedBox(width: 8),
          Text(
            category.name,
            style: TextStyle(color: category.color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(width: 6),
          Icon(Icons.auto_awesome, color: category.color.withValues(alpha: 0.6), size: 14),
        ],
      ),
    );
  }
}
