import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';

/// Écran "About App", ouvert depuis Settings.
///
/// Présente le nom, la version et une courte description de
/// l'application, la liste des fonctionnalités principales, et un accès
/// à la page de licences open source fournie nativement par Flutter
/// (showLicensePage) — aucune dépendance supplémentaire nécessaire.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appName = 'Session History App';
  static const _appVersion = '1.0.0';
  static const _description =
      'Session History vous aide à garder une trace de vos sessions de '
      'travail, d\'étude et de développement. Chaque session est classée '
      'automatiquement par catégorie grâce à l\'IA intégrée, avec un résumé, '
      'des mots-clés et un rappel programmé à l\'heure choisie.';

  static const _features = <_Feature>[
    _Feature(Icons.auto_awesome_outlined, 'Catégorisation automatique par IA'),
    _Feature(Icons.summarize_outlined, 'Résumé et mots-clés générés automatiquement'),
    _Feature(Icons.notifications_active_outlined, 'Rappel programmé à l\'heure de la session'),
    _Feature(Icons.swap_horiz, 'Export et import de vos sessions'),
    _Feature(Icons.dark_mode_outlined, 'Mode sombre'),
  ];

  @override
  Widget build(BuildContext context) {
    // Force la reconstruction quand le mode sombre change, comme les
    // autres écrans de l'app (AppColors expose des couleurs dynamiques).
    context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: const Text('About', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.history_edu, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  _appName,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: AppColors.textPrimary, letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $_appVersion',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _softCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _description,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 22),

          _sectionLabel('Fonctionnalités'),
          const SizedBox(height: 10),
          _softCard(
            child: Column(
              children: [
                for (int i = 0; i < _features.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Icon(_features[i].icon, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _features[i].label,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != _features.length - 1)
                    Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.border.withOpacity(0.5)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          _sectionLabel('Informations légales'),
          const SizedBox(height: 10),
          _softCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => showLicensePage(
                context: context,
                applicationName: _appName,
                applicationVersion: _appVersion,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Licences open source', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Center(
            child: Text(
              'Développé avec 💜',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.3),
    ),
  );

  /// Carte au style unifié de l'app : fond blanc, ombre douce, coins arrondis.
  Widget _softCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}