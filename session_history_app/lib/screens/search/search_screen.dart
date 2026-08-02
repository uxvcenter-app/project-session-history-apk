import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../widgets/session_card.dart';
import '../sessions/session_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

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
    final sessions = context.watch<SessionProvider>();
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              onChanged: (v) => context.read<SessionProvider>().setSearchQuery(v),
              decoration: InputDecoration(
                hintText: 'Search sessions, tags, keywords...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          context.read<SessionProvider>().setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: !hasQuery
                ? Center(
                    child: Text('Tapez pour rechercher une session',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : sessions.sessions.isEmpty
                    ? Center(
                        child: Text('Aucun résultat', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: sessions.sessions.length,
                        itemBuilder: (context, i) {
                          final s = sessions.sessions[i];
                          return SessionCard(
                            session: s,
                            onTap: () => Navigator.of(context).push(
                              AppRoute(SessionDetailScreen(session: s)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
