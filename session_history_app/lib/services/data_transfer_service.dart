import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';

class ImportResult {
  final int imported;
  final int failed;
  ImportResult({required this.imported, required this.failed});
}

/// Représente un fichier d'export trouvé sur l'appareil (pour l'écran d'import).
class ExportFile {
  final File file;
  final String name;
  final DateTime modifiedAt;
  ExportFile({
    required this.file,
    required this.name,
    required this.modifiedAt,
  });
}

/// Gère l'export/import des sessions au format JSON, en écrivant/lisant de
/// VRAIS fichiers sur l'appareil — sans passer par un sélecteur système
/// (file_picker) ni un partage natif (share_plus), tous deux responsables
/// de conflits de compilation Android récurrents dans ce projet.
///
/// Les fichiers sont stockés dans un dossier propre à l'app, visible via
/// une application de gestion de fichiers (voir exportFolderPath), et
/// l'écran "Import" liste directement ces fichiers dans l'app : aucun
/// sélecteur externe n'est nécessaire.
class DataTransferService {
  DataTransferService._();
  static final DataTransferService instance = DataTransferService._();

  static const _localSessionsKey = 'local_sessions_cache';

  Future<Directory> _exportDirectory() async {
    // Sur Android : dossier externe propre à l'app, visible via un
    // gestionnaire de fichiers (Android/data/<package>/files/exports).
    // Sur iOS/autres : dossier documents de l'app (visible dans l'app
    // Fichiers si le partage de fichiers est activé côté natif).
    final base = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${(base ?? await getApplicationDocumentsDirectory()).path}/exports',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Chemin lisible du dossier d'export, à afficher à l'utilisateur.
  Future<String> exportFolderPath() async => (await _exportDirectory()).path;

  String _buildExportJson(List<SessionModel> sessions) {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'sessionsCount': sessions.length,
      'sessions': sessions.map(_sessionToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, dynamic> _sessionToJson(SessionModel session) => {
    'id': session.id,
    'title': session.title,
    'category': session.category,
    'date': session.date.toIso8601String(),
    'time': session.time,
    'content': session.content,
    'tags': session.tags,
    'isFavorite': session.isFavorite,
    'createdAt': session.createdAt.toIso8601String(),
    'updatedAt': session.updatedAt.toIso8601String(),
    'autoSummary': session.autoSummary,
    'autoKeywords': session.autoKeywords ?? [],
  };

  Future<void> saveLocalSessions(List<SessionModel> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localSessionsKey,
      jsonEncode(sessions.map(_sessionToJson).toList()),
    );
  }

  Future<List<SessionModel>> loadLocalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_localSessionsKey);
    if (value == null || value.isEmpty) return [];

    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (item) => SessionModel.fromApiJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Version publique utilisée par l'UI pour obtenir le JSON d'export
  /// sans écrire de fichier sur le disque.
  String buildExportJson(List<SessionModel> sessions) =>
      _buildExportJson(sessions);

  /// Écrit automatiquement un fichier JSON sur l'appareil et renvoie son
  /// chemin complet. C'est la nouvelle action déclenchée par le bouton
  /// "Export Data (JSON)".
  Future<File> exportSessionsToFile(List<SessionModel> sessions) async {
    final dir = await _exportDirectory();
    final fileName =
        'session_history_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(_buildExportJson(sessions));
    await saveLocalSessions(sessions);
    return file;
  }

  /// Ouvre le menu système pour enregistrer l'export dans Fichiers,
  /// Downloads, Google Drive ou une autre application installée.
  Future<ShareResult> shareSessions(List<SessionModel> sessions) async {
    final file = await exportSessionsToFile(sessions);
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Export Session History',
        text: 'Données de mes sessions Session History',
      ),
    );
  }

  /// Liste tous les fichiers d'export déjà présents sur l'appareil, du
  /// plus récent au plus ancien (utilisé par l'écran "Import").
  Future<List<ExportFile>> listExportFiles() async {
    final dir = await _exportDirectory();
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final result = <ExportFile>[];
    for (final f in files) {
      final stat = await f.stat();
      result.add(
        ExportFile(
          file: f,
          name: f.uri.pathSegments.last,
          modifiedAt: stat.modified,
        ),
      );
    }
    result.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return result;
  }

  /// Importe les sessions contenues dans un fichier déjà présent sur
  /// l'appareil (sélectionné dans la liste de listExportFiles()).
  Future<ImportResult> importSessionsFromFile(File file) async {
    final content = await file.readAsString();
    return importSessionsFromJsonString(content);
  }

  /// Ouvre le sélecteur de fichiers du téléphone et importe le JSON choisi.
  Future<ImportResult?> pickAndImportSessions() async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (selected == null || selected.path == null) return null;
    return importSessionsFromFile(File(selected.path!));
  }

  /// Importe des sessions à partir d'un texte JSON brut (conservé pour
  /// compatibilité / cas d'usage avancé : coller un JSON manuellement).
  Future<ImportResult> importSessionsFromJsonString(String jsonText) async {
    final decoded = jsonDecode(jsonText);

    final List<dynamic> rawSessions = decoded is Map<String, dynamic>
        ? (decoded['sessions'] as List<dynamic>)
        : (decoded as List<dynamic>);

    int imported = 0;
    int failed = 0;
    final existing = await loadLocalSessions();
    final sessionsById = <String, Map<String, dynamic>>{
      for (final session in existing) session.id: _sessionToJson(session),
    };

    for (final raw in rawSessions) {
      try {
        final map = Map<String, dynamic>.from(raw as Map);
        final now = DateTime.now();
        final id = (map['id'] as String?)?.trim().isNotEmpty == true
            ? map['id'] as String
            : 'import-${now.microsecondsSinceEpoch}-$imported';
        sessionsById[id] = {
          'id': id,
          'title': map['title'] ?? 'Sans titre',
          'category': map['category'] ?? 'others',
          'date': map['date'] ?? now.toIso8601String(),
          'time': map['time'] ?? '',
          'content': map['content'] ?? '',
          'tags': (map['tags'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
          'isFavorite': map['isFavorite'] ?? false,
          'createdAt': map['createdAt'] ?? now.toIso8601String(),
          'updatedAt': map['updatedAt'] ?? now.toIso8601String(),
          'autoSummary': map['autoSummary'],
          'autoKeywords': (map['autoKeywords'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
        };
        imported++;
      } catch (_) {
        failed++;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localSessionsKey,
      jsonEncode(sessionsById.values.toList()),
    );

    return ImportResult(imported: imported, failed: failed);
  }
}
