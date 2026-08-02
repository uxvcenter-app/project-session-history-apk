import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/session_provider.dart';
import '../sessions/all_sessions_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
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
    final counts = context.watch<SessionProvider>().categoryCounts();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: CategoryModel.defaults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = CategoryModel.defaults[i];
          final count = counts[c.id] ?? 0;
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(c.icon, color: c.color),
              ),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('$count sessions', style: TextStyle(color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(AppRoute(const AllSessionsScreen()));
              },
            ),
          );
        },
      ),
    );
  }
}
