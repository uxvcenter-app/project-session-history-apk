import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/category_model.dart';
import '../models/session_model.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onMore;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onFavoriteToggle,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryModel.byId(session.category);
    final dateStr = DateFormat('dd MMM yyyy').format(session.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr · ${session.time}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (onFavoriteToggle != null)
                IconButton(
                  icon: Icon(
                    session.isFavorite ? Icons.star : Icons.star_border,
                    color: session.isFavorite ? AppColors.star : AppColors.textSecondary,
                  ),
                  onPressed: onFavoriteToggle,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(color: category.color, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              if (onMore != null)
                IconButton(
                  icon: Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                  onPressed: onMore,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
