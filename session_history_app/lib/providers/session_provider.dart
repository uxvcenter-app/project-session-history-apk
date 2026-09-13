import 'package:flutter/material.dart';
import '../core/messaging/app_messenger.dart';
import '../core/theme/app_colors.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';
import '../services/ai_service.dart';
import '../services/data_transfer_service.dart';
import '../services/notification_service.dart';

enum SessionFilter { all, favorites, category }

/// Gère l'état de la liste des sessions en les synchronisant avec le
/// backend ASP.NET Core (au lieu de la base SQLite locale). Les fonctions
/// IA (résumé + mots-clés) restent calculées localement puis envoyées
/// au backend pour être stockées avec la session.
class SessionProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  final _transfer = DataTransferService.instance;
  final _notifications = NotificationService.instance;

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
  String? _aiErrorMessage;
  String? get aiErrorMessage => _aiErrorMessage;
  int get totalCount => _sessions.length;
  int get favoritesCount => _sessions.where((s) => s.isFavorite).length;

  Future<Map<String, dynamic>?> analyzeDraft({
    required String title,
    required String content,
  }) async {
    if (title.trim().isEmpty && content.trim().isEmpty) return null;
    try {
      final result = await _api.analyzeSession(title: title, content: content);
      _aiErrorMessage = null;
      return result;
    } catch (error) {
      _aiErrorMessage = error.toString();
      return null;
    }
  }

  List<SessionModel> get recentSessions =>
      (_sessions.toList()..sort((a, b) => b.date.compareTo(a.date)))
          .take(4)
          .toList();

  Future<void> loadSessions({bool syncReminders = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final json = await _api.getSessions();
      _sessions = json
          .map((e) => SessionModel.fromApiJson(e as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
      _applyFilters();
      try {
        await _transfer.saveLocalSessions(_sessions);
      } catch (_) {}

      // Ne bloque jamais le chargement de l'application si le système
      // de notifications rencontre un problème.
      if (syncReminders) {
        try {
          await _notifications.syncSessionReminders(_sessions);
        } catch (_) {}
      }
    } catch (e) {
      try {
        _sessions = await _transfer.loadLocalSessions();
        _errorMessage = _sessions.isEmpty ? e.toString() : null;
        _applyFilters();
        if (syncReminders && _sessions.isNotEmpty) {
          try {
            await _notifications.syncSessionReminders(_sessions);
          } catch (_) {}
        }
      } catch (_) {
        _errorMessage = e.toString();
      }
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
    final aiResult = await analyzeDraft(title: title, content: content);
    final analyzedCategory = aiResult?['category'] as String?;
    final keywords =
        (aiResult?['keywords'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList() ??
        AiService.extractKeywords(content);
    final summary =
        aiResult?['summary'] as String? ?? AiService.generateSummary(content);

    final draft = SessionModel(
      id: '',
      title: title,
      category: analyzedCategory ?? category,
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
      final createdJson = await _api.createSession(draft.toApiJson());
      final created = SessionModel.fromApiJson(createdJson);

      await loadSessions();

      // Confirmation affichée dans l'application (pas de notification
      // système) : seul le rappel programmé ci-dessous en est une.
      try {
        showAppMessage(
          '« ${created.title} » a été ajoutée avec succès.',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
        );
      } catch (_) {}
      try {
        await _notifications.scheduleSessionReminder(
          created,
          requestExactPermission: true,
        );
      } catch (_) {}

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSession(SessionModel session) async {
    final aiResult = await analyzeDraft(
      title: session.title,
      content: session.content,
    );
    final keywords =
        (aiResult?['keywords'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList() ??
        AiService.extractKeywords(session.content);
    final summary =
        aiResult?['summary'] as String? ??
        AiService.generateSummary(session.content);
    final updated = session.copyWith(
      category: aiResult?['category'] as String? ?? session.category,
      autoKeywords: keywords,
      autoSummary: summary,
    );

    try {
      final updatedJson = await _api.updateSession(
        session.id,
        updated.toApiJson(),
      );
      final saved = SessionModel.fromApiJson(updatedJson);
      await loadSessions();

      try {
        showAppMessage(
          '« ${saved.title} » a été modifiée avec succès.',
          icon: Icons.edit_outlined,
          iconColor: AppColors.primary,
        );
      } catch (_) {}

      // Le même id de notification remplace automatiquement l'ancien rappel.
      try {
        await _notifications.scheduleSessionReminder(
          saved,
          requestExactPermission: true,
        );
      } catch (_) {}

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSession(String id) async {
    SessionModel? deletedSession;
    for (final session in _sessions) {
      if (session.id == id) {
        deletedSession = session;
        break;
      }
    }

    try {
      await _api.deleteSession(id);

      // Le rappel ne doit plus sonner après suppression.
      try {
        await _notifications.cancelSessionReminder(id);
      } catch (_) {}

      // Confirmation affichée dans l'application (pas de notification
      // système).
      if (deletedSession != null) {
        try {
          showAppMessage(
            '« ${deletedSession.title} » a été supprimée.',
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.error,
          );
        } catch (_) {}
      }

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
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      counts[i] = _sessions
          .where(
            (s) =>
                s.date.year == day.year &&
                s.date.month == day.month &&
                s.date.day == day.day,
          )
          .length;
    }
    return counts;
  }
}
