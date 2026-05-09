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
}
