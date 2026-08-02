import '../models/category_model.dart';

/// Service d'intelligence artificielle "légère", 100% local, sans appel réseau.
/// Fournit : extraction de mots-clés, résumé automatique et
/// classification automatique de catégorie, basés sur des heuristiques
/// simples (fréquence de mots, longueur de phrases, dictionnaire de
/// mots-clés pondérés). Peut être remplacé plus tard par un vrai modèle
/// NLP / API distante.
class AiService {
  AiService._();

  static const Set<String> _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'is', 'are', 'was', 'were', 'be', 'been', 'this', 'that',
    'it', 'we', 'i', 'you', 'they', 'he', 'she', 'as', 'by', 'from', 'our',
    'le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'de', 'du', 'en',
    'au', 'aux', 'ce', 'ces', 'nous', 'vous', 'ils', 'elles', 'pour',
    'avec', 'dans', 'sur', 'est', 'sont', 'j', 'l', 'ai', 'jai',
    'que', 'qui', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 'son', 'sa',
  };

  /// Extrait les N mots les plus significatifs du contenu.
  static List<String> extractKeywords(String content, {int max = 5}) {
    final words = content
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sàâäéèêëïîôöùûüç]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !_stopWords.contains(w));

    final frequency = <String, int>{};
    for (final w in words) {
      frequency[w] = (frequency[w] ?? 0) + 1;
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(max).map((e) => e.key).toList();
  }

  /// Génère un résumé condensé du contenu.
  /// - Si le texte est déjà court (peu de phrases / peu de mots), on
  ///   considère qu'un "résumé" séparé n'apporte rien : on renvoie null
  ///   plutôt que de dupliquer le contenu tel quel.
  /// - Sinon, on sélectionne les phrases les plus "informatives" (celles
  ///   qui contiennent le plus de mots-clés fréquents) puis on les
  ///   recompose dans leur ordre d'origine.
  static String? generateSummary(String content, {int maxSentences = 2}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    final sentences = trimmed
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 5)
        .toList();

    final wordCount = trimmed.split(RegExp(r'\s+')).length;

    // Contenu déjà court : pas besoin d'un résumé séparé.
    if (sentences.length <= 1 && wordCount <= 25) {
      return null;
    }

    if (sentences.length <= maxSentences) {
      // Peu de phrases mais texte un peu long (pas de ponctuation par ex) :
      // on tronque proprement pour obtenir un vrai résumé plus court que
      // l'original, avec des points de suspension.
      final joined = sentences.join(' ');
      const maxChars = 160;
      if (joined.length <= maxChars) return joined;
      final cut = joined.substring(0, maxChars);
      final lastSpace = cut.lastIndexOf(' ');
      return '${cut.substring(0, lastSpace > 0 ? lastSpace : cut.length)}…';
    }

    final keywords = extractKeywords(content, max: 10);
    final scored = sentences.map((s) {
      final lower = s.toLowerCase();
      final score = keywords.where((k) => lower.contains(k)).length;
      return MapEntry(s, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = scored.take(maxSentences).map((e) => e.key).toList();
    // Ré-ordonner selon l'ordre d'apparition original
    top.sort((a, b) => sentences.indexOf(a).compareTo(sentences.indexOf(b)));
    return top.join(' ');
  }

  /// Règles de classification par mots-clés, pondérées par catégorie.
  /// Chaque catégorie a une liste de mots-clés (FR/EN) représentatifs.
  static final Map<String, List<String>> _categoryRules = {
    'development': [
      'code', 'coding', 'bug', 'fix', 'refactor', 'développement', 'develop',
      'programmation', 'programming', 'flutter', 'dart', 'api', 'backend',
      'frontend', 'fonction', 'function', 'classe', 'class', 'compil',
      'build', 'deploy', 'déploiement', 'git', 'repository', 'application',
      'app', 'widget', 'framework', 'librairie', 'library', 'package',
      'installation', 'install', 'setup', 'configuration', 'sdk',
    ],
    'debug': [
      'bug', 'erreur', 'error', 'crash', 'exception', 'debug', 'debogage',
      'correction', 'fix', 'résolu', 'resolved', 'problème', 'problem',
      'plante', 'échec', 'failure', 'stacktrace', 'trace',
    ],
    'formation': [
      'formation', 'cours', 'course', 'apprendre', 'learn', 'apprentissage',
      'training', 'tutorial', 'tutoriel', 'lesson', 'leçon', 'exercice',
      'exercise', 'certification', 'workshop', 'atelier', 'enseignement',
      'exam', 'examen', 'étude', 'study',
    ],
    'laboratory': [
      'laboratoire', 'laboratory', 'analyse', 'analysis', 'échantillon',
      'sample', 'expérience', 'experiment', 'microbiologique', 'microbiology',
      'bactérie', 'bacteria', 'culture', 'test', 'résultat', 'result',
      'protocole', 'protocol', 'réactif', 'reagent', 'microscope',
    ],
    'meeting': [
      'meeting', 'réunion', 'call', 'appel', 'discussion', 'sync',
      'entretien', 'rendez-vous', 'rdv', 'conference', 'brief', 'debrief',
    ],
    'work': [
      'projet', 'project', 'client', 'deadline', 'tâche', 'task', 'office',
      'travail', 'work', 'rapport', 'report', 'presentation', 'présentation',
      'budget', 'planning',
    ],
    'personal': [
      'journal', 'personnel', 'personal', 'famille', 'family', 'santé',
      'health', 'sport', 'loisir', 'hobby', 'voyage', 'travel',
    ],
    'ideas': [
      'idée', 'idea', 'concept', 'brainstorm', 'innovation', 'astuce', 'tip',
      'inspiration', 'créativité', 'creativity',
    ],
  };

  /// Détecte automatiquement la catégorie la plus probable à partir du
  /// titre et du contenu. Retourne 'others' si aucun mot-clé ne correspond
  /// clairement (score nul).
  static String suggestCategory(String title, String content) {
    final text = '$title $content'.toLowerCase();

    String bestCategory = 'others';
    int bestScore = 0;

    for (final entry in _categoryRules.entries) {
      final score = entry.value.where((k) => text.contains(k)).length;
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }
    return bestCategory;
  }

  static CategoryModel suggestCategoryModel(String title, String content) {
    return CategoryModel.byId(suggestCategory(title, content));
  }
}
