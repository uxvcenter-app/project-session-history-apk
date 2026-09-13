import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/session_provider.dart';
import '../../widgets/session_card.dart';
import '../sessions/session_detail_screen.dart';

class AllSessionsScreen extends StatefulWidget {
  const AllSessionsScreen({super.key});

  @override
  State<AllSessionsScreen> createState() => _AllSessionsScreenState();
}

class _AllSessionsScreenState extends State<AllSessionsScreen> {
  SessionFilter _filter = SessionFilter.all;
  String? _category;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SessionProvider>();
      provider.setSearchQuery('');
      provider.setFilter(SessionFilter.all);
      provider.loadSessions();
    });
  }

  @override
  void dispose() {
    context.read<SessionProvider>().setSearchQuery('');
    context.read<SessionProvider>().setFilter(SessionFilter.all);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final sessions = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      // Pas d'AppBar classique : on utilise un header en dégradé,
      // comme sur la page Réglages.
      body: Column(
        children: [
          _buildHeader(context),
          _filterBar(),
          Expanded(
            child: sessions.isLoading && sessions.sessions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : sessions.sessions.isEmpty
                ? _placeholderState(
                    icon: Icons.inbox_outlined,
                    title: 'Aucune session',
                    subtitle: 'Ajoutez votre première session depuis Home.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: sessions.sessions.length,
                    itemBuilder: (context, i) {
                      final s = sessions.sessions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
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
                            session: s,
                            onTap: () => Navigator.of(
                              context,
                            ).push(AppRoute(SessionDetailScreen(session: s))),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: _filterTab(
                  'All',
                  Icons.grid_view_rounded,
                  SessionFilter.all,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterTab(
                  'Favorites',
                  Icons.star_rounded,
                  SessionFilter.favorites,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterTab(
                  'Categories',
                  Icons.category_outlined,
                  SessionFilter.category,
                ),
              ),
            ],
          ),
        ),
        if (_filter == SessionFilter.category)
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              scrollDirection: Axis.horizontal,
              itemCount: CategoryModel.defaults.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = CategoryModel.defaults[index];
                final selected = _category == category.id;
                return ChoiceChip(
                  selected: selected,
                  label: Text(category.name),
                  avatar: Icon(
                    category.icon,
                    size: 16,
                    color: selected ? Colors.white : category.color,
                  ),
                  selectedColor: category.color,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => _category = category.id);
                    context.read<SessionProvider>().setFilter(
                      SessionFilter.category,
                      category: category.id,
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _filterTab(String label, IconData icon, SessionFilter filter) {
    final selected = _filter == filter;
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _filter = filter;
            if (filter != SessionFilter.category) _category = null;
          });
          context.read<SessionProvider>().setFilter(
            filter,
            category: filter == SessionFilter.category ? _category : null,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header en dégradé violet avec coins arrondis en bas,
  /// dans le même esprit que le header de la page Réglages.
  /// La barre de recherche est intégrée en bas du header,
  /// à cheval sur le fond violet et le fond clair (comme l'avatar
  /// des Réglages qui déborde légèrement du bandeau).
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    const headerRadius = BorderRadius.only(
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );

    return Container(
      // Ce calque externe ne porte QUE l'ombre. Comme il partage exactement
      // la même forme (borderRadius) que le contenu, l'ombre suit fidèlement
      // la courbe des coins au lieu de déborder en carré derrière eux.
      decoration: BoxDecoration(
        borderRadius: headerRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        // Le clip garantit qu'aucun pixel (dégradé, ombre de la barre de
        // recherche, etc.) ne dépasse la forme arrondie : plus de décalage
        // visible au niveau des coins.
        borderRadius: headerRadius,
        child: Container(
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                HSLColor.fromColor(AppColors.primary)
                    .withLightness(
                      (HSLColor.fromColor(AppColors.primary).lightness - 0.14)
                          .clamp(0.0, 1.0),
                    )
                    .toColor(),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Retour',
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'All Sessions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
