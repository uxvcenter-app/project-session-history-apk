import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import '../../core/messaging/app_messenger.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Supprimer la session ?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final provider = context.read<SessionProvider>();
    final success = await provider.deleteSession(session.id);
    if (!context.mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      showAppMessage(
        provider.errorMessage ?? 'Impossible de supprimer la session',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<SessionProvider>();
    final currentSession = provider.allSessions.firstWhere(
      (item) => item.id == session.id,
      orElse: () => session,
    );
    final category = CategoryModel.byId(currentSession.category);
    final dateStr = DateFormat('dd MMM yyyy').format(currentSession.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Session Detail',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          _appBarIconButton(
            icon: Icons.edit_outlined,
            onPressed: () => Navigator.of(
              context,
            ).push(AppRoute(EditSessionScreen(session: currentSession))),
          ),
          _appBarIconButton(
            icon: Icons.delete_outline_rounded,
            onPressed: () => _confirmDelete(context),
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        currentSession.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => provider.toggleFavorite(currentSession),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              (currentSession.isFavorite
                                      ? AppColors.star
                                      : AppColors.textSecondary)
                                  .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          currentSession.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 19,
                          color: currentSession.isFavorite
                              ? AppColors.star
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: category.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$dateStr · ${currentSession.time}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (currentSession.autoSummary != null &&
              currentSession.autoSummary!.trim().isNotEmpty) ...[
            _sectionTitle(
              'Résumé automatique (IA)',
              icon: Icons.auto_awesome_rounded,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                currentSession.autoSummary!,
                style: const TextStyle(height: 1.5, fontSize: 13.5),
              ),
            ),
            const SizedBox(height: 22),
          ],
          _sectionTitle('Content'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              currentSession.content,
              style: const TextStyle(height: 1.6, fontSize: 14),
            ),
          ),
          const SizedBox(height: 22),
          if (currentSession.tags.isNotEmpty) ...[
            _sectionTitle('Tags', icon: Icons.label_outline_rounded),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentSession.tags
                  .map((tag) => _tagChip(tag))
                  .toList(),
            ),
            const SizedBox(height: 22),
          ],
          if (currentSession.autoKeywords != null &&
              currentSession.autoKeywords!.isNotEmpty) ...[
            _sectionTitle(
              'Mots-clés détectés (IA)',
              icon: Icons.auto_awesome_rounded,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentSession.autoKeywords!
                  .map((keyword) => _tagChip(keyword, tint: AppColors.primary))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _appBarIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Icon(icon, size: 21, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Widget _sectionTitle(String text, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
      ],
    ),
  );

  Widget _tagChip(String label, {Color? tint}) {
    final color = tint ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: tint != null ? color.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tint != null
              ? color.withOpacity(0.2)
              : AppColors.textSecondary.withOpacity(0.15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tint != null ? color : Colors.black87,
        ),
      ),
    );
  }
}
