import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/session_provider.dart';
import '../../widgets/session_card.dart';
import '../../widgets/fade_slide_in.dart';
import 'session_detail_screen.dart';

class AllSessionsScreen extends StatefulWidget {
  const AllSessionsScreen({super.key});

  @override
  State<AllSessionsScreen> createState() => _AllSessionsScreenState();
}

class _AllSessionsScreenState extends State<AllSessionsScreen> {
  int _tab = 0; // 0 = All, 1 = Favorites, 2 = Categories
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
    });
  }

  void _applyTab(int tab) {
    setState(() => _tab = tab);
    final provider = context.read<SessionProvider>();
    if (tab == 0) {
      provider.setFilter(SessionFilter.all);
    } else if (tab == 1) {
      provider.setFilter(SessionFilter.favorites);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final sessions = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('All Sessions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _chip('All', 0),
                const SizedBox(width: 8),
                _chip('Favorites', 1),
                const SizedBox(width: 8),
                _chip('Categories', 2),
              ],
            ),
          ),
          if (_tab == 2)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: CategoryModel.defaults.map((c) {
                  final selected = _selectedCategory == c.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      selectedColor: c.color.withOpacity(0.2),
                      onSelected: (_) {
                        setState(() => _selectedCategory = c.id);
                        context.read<SessionProvider>().setFilter(SessionFilter.category, category: c.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: sessions.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sessions.sessions.isEmpty
                    ? Center(child: Text('Aucune session', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: sessions.sessions.length,
                        itemBuilder: (context, i) {
                          final s = sessions.sessions[i];
                          return FadeSlideIn(
                            index: i,
                            child: SessionCard(
                              session: s,
                              onTap: () => Navigator.of(context).push(
                                AppRoute(SessionDetailScreen(session: s)),
                              ),
                              onFavoriteToggle: () => context.read<SessionProvider>().toggleFavorite(s),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int index) {
    final selected = _tab == index;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
      onSelected: (_) => _applyTab(index),
    );
  }
}
