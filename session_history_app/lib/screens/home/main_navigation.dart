import 'package:flutter/material.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_colors.dart';
import '../sessions/add_session_screen.dart';
import '../search/search_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

/// Conteneur principal avec la barre de navigation basse,
/// identique à la maquette (Home / Search / Stats / Settings).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    SearchScreen(onBack: _showHome),
    StatisticsScreen(onBack: _showHome),
    SettingsScreen(onBack: _showHome),
  ];

  void _showHome() {
    if (mounted) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.of(
                context,
              ).push(AppRoute(const AddSessionScreen())),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, Icons.home, 'Home', 0),
              _navItem(Icons.search_outlined, Icons.search, 'Search', 1),
              _navItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Stats', 2),
              _navItem(Icons.settings_outlined, Icons.settings, 'Settings', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData outline, IconData filled, String label, int i) {
    final selected = _index == i;
    return InkWell(
      onTap: () => setState(() => _index = i),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? filled : outline,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
