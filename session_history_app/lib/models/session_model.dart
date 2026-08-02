class SessionModel {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final String time;
  final String content;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? autoSummary;
  final List<String>? autoKeywords;

  const SessionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.content,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.autoSummary,
    this.autoKeywords,
  });

  SessionModel copyWith({
    String? title,
    String? category,
    DateTime? date,
    String? time,
    String? content,
    List<String>? tags,
    bool? isFavorite,
    DateTime? updatedAt,
    String? autoSummary,
    List<String>? autoKeywords,
  }) {
    return SessionModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      autoSummary: autoSummary ?? this.autoSummary,
      autoKeywords: autoKeywords ?? this.autoKeywords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'time': time,
      'content': content,
      'tags': tags.join(','),
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'autoSummary': autoSummary,
      'autoKeywords': (autoKeywords ?? []).join(','),
    };
  }

  /// Conversion vers le JSON attendu par l'API ASP.NET Core (CreateSessionRequest).
  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'time': time,
      'content': content,
      'tags': tags,
      'isFavorite': isFavorite,
      'autoSummary': autoSummary,
      'autoKeywords': autoKeywords ?? [],
    };
  }

  /// Construction depuis le JSON renvoyé par l'API (SessionDto côté backend).
  factory SessionModel.fromApiJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return SessionModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'others',
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : now,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : now,
      autoSummary: json['autoSummary'] as String?,
      autoKeywords: (json['autoKeywords'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String,
      content: map['content'] as String,
      tags: (map['tags'] as String? ?? '')
          .split(',')
          .where((t) => t.trim().isNotEmpty)
          .toList(),
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      autoSummary: map['autoSummary'] as String?,
      autoKeywords: (map['autoKeywords'] as String? ?? '')
          .split(',')
          .where((t) => t.trim().isNotEmpty)
          .toList(),
    );
  }
}
