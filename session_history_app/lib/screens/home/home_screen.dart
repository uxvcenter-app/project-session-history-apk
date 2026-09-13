import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';
import '../../widgets/session_card.dart';
import '../../widgets/fade_slide_in.dart';
import '../sessions/all_sessions_screen.dart';
import '../sessions/session_detail_screen.dart';
import '../settings/settings_screen.dart';

/// Dashboard principal ("Session History") — version design pro :
/// header avec avatar, cartes de stats avec icônes/ombres,
/// sessions récentes limitées à 4 éléments.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Nombre max de sessions récentes affichées sur le dashboard
  static const int _recentSessionsLimit = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final sessions = context.watch<SessionProvider>();
    final firstName = auth.currentUser?.fullName.split(' ').first ?? 'there';

    // On limite l'affichage à _recentSessionsLimit sessions sur le dashboard
    final recent = sessions.recentSessions.take(_recentSessionsLimit).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: sessions.loadSessions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              _header(firstName, sessions.allSessions),
              const SizedBox(height: 24),

              // Grille de statistiques
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.3,
                children: [
                  _statCard(
                    icon: Icons.folder_copy_rounded,
                    value: '${sessions.totalCount}',
                    label: 'Total Sessions',
                    color: AppColors.primary,
                  ),
                  _statCard(
                    icon: Icons.calendar_month_rounded,
                    value: '${sessions.thisMonthCount()}',
                    label: 'This Month',
                    color: AppColors.study,
                  ),
                  _statCard(
                    icon: Icons.category_rounded,
                    value: '${sessions.categoryCounts().length}',
                    label: 'Categories',
                    color: AppColors.meeting,
                  ),
                  _statCard(
                    icon: Icons.star_rounded,
                    value: '${sessions.favoritesCount}',
                    label: 'Favorites',
                    color: AppColors.ideas,
                  ),
                ],
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Sessions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).push(AppRoute(const AllSessionsScreen())),
                    icon: const Text(
                      'View all',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    label: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                    ),
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (sessions.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (recent.isEmpty)
                _emptyState()
              else
                ...recent.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FadeSlideIn(
                      index: entry.key,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SessionCard(
                          session: entry.value,
                          onTap: () => Navigator.of(context).push(
                            AppRoute(SessionDetailScreen(session: entry.value)),
                          ),
                        ),
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

  Widget _header(String firstName, List<SessionModel> sessions) {
    final topPadding = MediaQuery.of(context).padding.top;
    final upcoming = _upcomingSessions(sessions);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session History',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${_greeting()}, $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Voici un aperçu de vos sessions',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
            ),
          ),
          _notificationButton(upcoming),
          const SizedBox(width: 10),
          _avatar(firstName),
        ],
      ),
    );
  }

  Widget _avatar(String firstName) {
    return Semantics(
      button: true,
      label: 'Ouvrir le profil utilisateur',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            Navigator.of(context).push(AppRoute(const SettingsScreen())),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationButton(List<SessionModel> upcoming) {
    return SizedBox(
      width: 46,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withOpacity(0.18),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => _showNotifications(upcoming),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          if (upcoming.isNotEmpty)
            Positioned(
              top: 1,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${upcoming.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<SessionModel> _upcomingSessions(List<SessionModel> sessions) {
    final now = DateTime.now();
    final upcoming = sessions.where((session) {
      final time = _parseTime(session.time);
      if (time == null) return false;
      final scheduled = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
        time.$1,
        time.$2,
      );
      return scheduled.isAfter(now);
    }).toList();
    upcoming.sort((a, b) => _sessionDateTime(a).compareTo(_sessionDateTime(b)));
    return upcoming;
  }

  DateTime _sessionDateTime(SessionModel session) {
    final time = _parseTime(session.time) ?? (0, 0);
    return DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
      time.$1,
      time.$2,
    );
  }

  (int, int)? _parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  Future<void> _showNotifications(List<SessionModel> upcoming) async {
    final homeContext = context;
    await showModalBottomSheet<void>(
      context: homeContext,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: upcoming.isEmpty
              ? const SizedBox(
                  height: 150,
                  child: Center(child: Text('Aucun rappel à venir.')),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...upcoming
                        .take(5)
                        .map(
                          (session) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              Navigator.of(homeContext).push(
                                AppRoute(SessionDetailScreen(session: session)),
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(
                                Icons.notifications_active_outlined,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${session.date.day.toString().padLeft(2, '0')}/${session.date.month.toString().padLeft(2, '0')} à ${session.time}',
                            ),
                          ),
                        ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.inbox_outlined,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune session pour le moment',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Appuyez sur + pour ajouter votre première session',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
