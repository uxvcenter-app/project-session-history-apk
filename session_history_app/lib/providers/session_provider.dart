import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';
import '../services/ai_service.dart';

enum SessionFilter { all, favorites, category }

/// Gère l'état de la liste des sessions en les synchronisant avec le
/// backend ASP.NET Core (au lieu de la base SQLite locale). Les fonctions
/// IA (résumé + mots-clés) restent calculées localement puis envoyées
/// au backend pour être stockées avec la session.
class SessionProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<SessionModel> _sessions = [];
  List<SessionModel> _filtered = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  SessionFilter _filter = SessionFilter.all;
  String? _selectedCategory;

  List<SessionModel> get sessions => _filtered;
  List<SessionModel> get allSessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _sessions.length;
  int get favoritesCount => _sessions.where((s) => s.isFavorite).length;

  List<SessionModel> get recentSessions => (_sessions.toList()
        ..sort((a, b) => b.date.compareTo(a.date)))
      .take(3)
      .toList();

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final json = await _api.getSessions();
      _sessions = json.map((e) => SessionModel.fromApiJson(e as Map<String, dynamic>)).toList();
      _errorMessage = null;
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSession({
    required String title,
    required String category,
    required DateTime date,
    required String time,
    required String content,
    required List<String> tags,
  }) async {
    final keywords = AiService.extractKeywords(content);
    final summary = AiService.generateSummary(content);

    final draft = SessionModel(
      id: '',
      title: title,
      category: category,
      date: date,
      time: time,
      content: content,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      autoKeywords: keywords,
      autoSummary: summary,
    );

    try {
      await _api.createSession(draft.toApiJson());
      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSession(SessionModel session) async {
    final keywords = AiService.extractKeywords(session.content);
    final summary = AiService.generateSummary(session.content);
    final updated = session.copyWith(autoKeywords: keywords, autoSummary: summary);

    try {
      await _api.updateSession(session.id, updated.toApiJson());
      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSession(String id) async {
    try {
      await _api.deleteSession(id);
      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite(SessionModel session) async {
    final updated = session.copyWith(isFavorite: !session.isFavorite);
    try {
      await _api.updateSession(session.id, updated.toApiJson());
      await loadSessions();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilter(SessionFilter filter, {String? category}) {
    _filter = filter;
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var result = _sessions;

    if (_filter == SessionFilter.favorites) {
      result = result.where((s) => s.isFavorite).toList();
    } else if (_filter == SessionFilter.category && _selectedCategory != null) {
      result = result.where((s) => s.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.content.toLowerCase().contains(q) ||
            s.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    _filtered = result;
  }

  Map<String, int> categoryCounts() {
    final map = <String, int>{};
    for (final s in _sessions) {
      map[s.category] = (map[s.category] ?? 0) + 1;
    }
    return map;
  }

  int thisMonthCount() {
    final now = DateTime.now();
    return _sessions
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .length;
  }

  List<int> lastSevenDaysCounts() {
    final now = DateTime.now();
    final counts = List<int>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      counts[i] = _sessions
          .where((s) =>
              s.date.year == day.year &&
              s.date.month == day.month &&
              s.date.day == day.day)
          .length;
    }
    return counts;
  }
}
