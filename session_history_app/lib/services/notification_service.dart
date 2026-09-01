import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/session_model.dart';

/// Notifications locales de l'application :
/// - rappel automatique à la date et à l'heure de la session ;
/// - annulation/reprogrammation du rappel quand la session change ;
/// - confirmation après un export ou un import de sessions.
///
/// L'ajout et la suppression d'une session n'affichent volontairement plus
/// de notification système : ils affichent un simple message dans
/// l'application (voir `showAppMessage` dans `SessionProvider`). Le rappel
/// de session reste la seule notification système déclenchée ici.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _exactPermissionAskedThisRun = false;

  static const NotificationDetails _actionDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'session_actions',
      'Session actions',
      channelDescription: 'Notifications après ajout ou suppression de session',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const NotificationDetails _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'session_reminders',
      'Session reminders',
      channelDescription: 'Rappels programmés pour les sessions à venir',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // tz.local reste sur la valeur par défaut si le fuseau n'est pas trouvé.
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(settings: initializationSettings);

    // Android 13+ demande une permission runtime pour afficher les notifications.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Notification affichée après un export réussi, avec le nom du fichier
  /// créé automatiquement sur l'appareil.
  Future<void> showExportCompleted({
    required int sessionsCount,
    required String fileName,
  }) async {
    await _ensureInitialized();
    await _plugin.show(
      id: _nextActionId(),
      title: 'Export terminé',
      body: '$sessionsCount session(s) enregistrée(s) dans $fileName.',
      notificationDetails: _actionDetails,
    );
  }

  /// Notification affichée après un import, avec le résultat détaillé.
  Future<void> showImportCompleted({
    required int imported,
    required int failed,
    required String fileName,
  }) async {
    await _ensureInitialized();
    final body = failed > 0
        ? '$imported session(s) importée(s) depuis $fileName, $failed échouée(s).'
        : '$imported session(s) importée(s) depuis $fileName.';
    await _plugin.show(
      id: _nextActionId(),
      title: 'Import terminé',
      body: body,
      notificationDetails: _actionDetails,
    );
  }

  /// Programme le rappel pour une session future.
  ///
  /// Quand [requestExactPermission] vaut true (après un ajout/modification),
  /// Android peut demander l'autorisation "Alarmes et rappels" afin d'essayer
  /// de déclencher exactement à l'heure choisie. Si elle n'est pas accordée,
  /// l'application utilise automatiquement un rappel inexact comme secours.
  Future<bool> scheduleSessionReminder(
    SessionModel session, {
    bool requestExactPermission = false,
  }) async {
    await _ensureInitialized();

    final scheduledDate = _scheduledDateFor(session);
    final id = _reminderId(session.id);

    // Supprime une ancienne programmation éventuelle avant de la recréer.
    await _plugin.cancel(id: id);

    if (scheduledDate == null ||
        !scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      return false;
    }

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      var canUseExact = await android.canScheduleExactNotifications();

      if (requestExactPermission &&
          canUseExact == false &&
          !_exactPermissionAskedThisRun) {
        _exactPermissionAskedThisRun = true;
        await android.requestExactAlarmsPermission();
        canUseExact = await android.canScheduleExactNotifications();
      }

      if (canUseExact != false) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Rappel de session',
        body: 'C’est l’heure de votre session « ${session.title} ».',
        scheduledDate: scheduledDate,
        notificationDetails: _reminderDetails,
        androidScheduleMode: scheduleMode,
        payload: 'session:${session.id}',
      );
    } catch (_) {
      // Secours si Android refuse finalement une alarme exacte.
      await _plugin.zonedSchedule(
        id: id,
        title: 'Rappel de session',
        body: 'C’est l’heure de votre session « ${session.title} ».',
        scheduledDate: scheduledDate,
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'session:${session.id}',
      );
    }

    return true;
  }

  Future<void> cancelSessionReminder(String sessionId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: _reminderId(sessionId));
  }

  /// Reprogramme les sessions futures récupérées depuis le backend.
  /// Utile après reconnexion ou réinstallation sur un autre appareil.
  Future<void> syncSessionReminders(List<SessionModel> sessions) async {
    await _ensureInitialized();
    for (final session in sessions) {
      try {
        await scheduleSessionReminder(session);
      } catch (_) {
        // Une erreur de notification ne doit jamais empêcher le chargement
        // normal des sessions depuis le serveur.
      }
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  tz.TZDateTime? _scheduledDateFor(SessionModel session) {
    final parsed = _parseHourMinute(session.time);
    if (parsed == null) return null;

    return tz.TZDateTime(
      tz.local,
      session.date.year,
      session.date.month,
      session.date.day,
      parsed.$1,
      parsed.$2,
    );
  }

  /// Accepte les formats usuels générés par TimeOfDay.format :
  /// 14:30, 9:05, 2:30 PM, 02:30 pm.
  (int, int)? _parseHourMinute(String value) {
    final raw = value.trim().toUpperCase();

    final twelveHour =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(raw);
    if (twelveHour != null) {
      var hour = int.tryParse(twelveHour.group(1)!);
      final minute = int.tryParse(twelveHour.group(2)!);
      final period = twelveHour.group(3)!;
      if (hour == null || minute == null || hour < 1 || hour > 12 || minute > 59) {
        return null;
      }
      if (period == 'AM' && hour == 12) hour = 0;
      if (period == 'PM' && hour != 12) hour += 12;
      return (hour, minute);
    }

    final twentyFourHour = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
    if (twentyFourHour != null) {
      final hour = int.tryParse(twentyFourHour.group(1)!);
      final minute = int.tryParse(twentyFourHour.group(2)!);
      if (hour == null || minute == null || hour > 23 || minute > 59) {
        return null;
      }
      return (hour, minute);
    }

    return null;
  }

  /// Hash FNV-1a stable : contrairement à String.hashCode, cet identifiant
  /// reste le même après redémarrage et permet donc d'annuler le bon rappel.
  int _reminderId(String sessionId) {
    var hash = 0x811C9DC5;
    for (final codeUnit in sessionId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    if (hash == 0) return 1;
    return hash;
  }

  int _nextActionId() {
    const base = 1_000_000_000;
    final suffix =
        DateTime.now().microsecondsSinceEpoch.remainder(1_000_000_000);
    return base + suffix;
  }
}
