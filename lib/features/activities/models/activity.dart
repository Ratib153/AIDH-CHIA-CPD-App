class Activity {
  Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.points,
    this.notes,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String category;
  final DateTime date;
  final double points;
  final String? notes;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Activity copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? date,
    double? points,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      points: points ?? this.points,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'points': points,
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      points: (json['points'] as num).toDouble(),
      notes: json['notes'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    );
  }
}
