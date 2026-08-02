import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import 'edit_session_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final SessionModel session;
  const SessionDetailScreen({super.key, required this.session});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la session ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<SessionProvider>().deleteSession(session.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final category = CategoryModel.byId(session.category);
    final dateStr = DateFormat('dd MMM yyyy').format(session.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              AppRoute(EditSessionScreen(session: session)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(session.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              Icon(
                session.isFavorite ? Icons.star : Icons.star_border,
                color: session.isFavorite ? AppColors.star : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(category.name,
                    style: TextStyle(color: category.color, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Text('$dateStr · ${session.time}', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),

          if (session.autoSummary != null && session.autoSummary!.trim().isNotEmpty) ...[
            _sectionTitle('Résumé automatique (IA)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Text(session.autoSummary!, style: const TextStyle(height: 1.4)),
            ),
            const SizedBox(height: 20),
          ],

          _sectionTitle('Content'),
          Text(session.content, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),

          if (session.tags.isNotEmpty) ...[
            _sectionTitle('Tags'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.tags.map((t) => Chip(label: Text(t))).toList(),
            ),
            const SizedBox(height: 20),
          ],

          if (session.autoKeywords != null && session.autoKeywords!.isNotEmpty) ...[
            _sectionTitle('Mots-clés détectés (IA)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.autoKeywords!
                  .map((k) => Chip(
                        label: Text(k),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        labelStyle: const TextStyle(color: AppColors.primary),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );
}
