import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/session_card.dart';
import '../../widgets/fade_slide_in.dart';
import '../sessions/all_sessions_screen.dart';
import '../sessions/session_detail_screen.dart';

/// Dashboard principal ("Session History") — reproduit fidèlement
/// la maquette : salutation, cartes de stats, sessions récentes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final sessions = context.watch<SessionProvider>();
    final firstName = auth.currentUser?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: sessions.loadSessions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Text('Hello, $firstName',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Good to see you again!', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Grille de statistiques (comme la maquette)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _statCard('${sessions.totalCount}', 'Total Sessions', AppColors.primary),
                  _statCard('${sessions.thisMonthCount()}', 'This Month', AppColors.study),
                  _statCard('${sessions.categoryCounts().length}', 'Categories', AppColors.meeting),
                  _statCard('${sessions.favoritesCount}', 'Favorites', AppColors.ideas),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      AppRoute(const AllSessionsScreen()),
                    ),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (sessions.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (sessions.recentSessions.isEmpty)
                _emptyState()
              else
                ...sessions.recentSessions.asMap().entries.map(
                  (entry) => FadeSlideIn(
                    index: entry.key,
                    child: SessionCard(
                      session: entry.value,
                      onTap: () => Navigator.of(context).push(
                        AppRoute(SessionDetailScreen(session: entry.value)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('Aucune session pour le moment', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Appuyez sur + pour ajouter votre première session',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}
