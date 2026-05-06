class CpdActivity {
  CpdActivity({
    this.id,
    required this.cycleId,
    required this.dateLogged,
    required this.categoryId,
    required this.categoryName,
    this.subcategory,
    required this.activityDescription,
    this.providerName,
    this.durationHours,
    required this.pointsClaimed,
    this.competencyDomain,
    this.evidenceNote,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int cycleId;
  final String dateLogged;
  final int categoryId;
  final String categoryName;
  final String? subcategory;
  final String activityDescription;
  final String? providerName;
  final double? durationHours;
  final double pointsClaimed;
  final String? competencyDomain;
  final String? evidenceNote;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  // Backward-compatible aliases for current export UI.
  String get title => activityDescription;
  String get category => categoryName;
  DateTime get date => DateTime.parse(dateLogged);
  int get points => pointsClaimed.round();
  String? get notes => evidenceNote;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycle_id': cycleId,
      'date_logged': dateLogged,
      'category_id': categoryId,
      'category_name': categoryName,
      'subcategory': subcategory,
      'activity_description': activityDescription,
      'provider_name': providerName,
      'duration_hours': durationHours,
      'points_claimed': pointsClaimed,
      'competency_domain': competencyDomain,
      'evidence_note': evidenceNote,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CpdActivity.fromMap(Map<String, dynamic> map) {
    return CpdActivity(
      id: map['id'] as int?,
      cycleId: map['cycle_id'] as int,
      dateLogged: map['date_logged'] as String,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      subcategory: map['subcategory'] as String?,
      activityDescription: map['activity_description'] as String,
      providerName: map['provider_name'] as String?,
      durationHours: (map['duration_hours'] as num?)?.toDouble(),
      pointsClaimed: (map['points_claimed'] as num).toDouble(),
      competencyDomain: map['competency_domain'] as String?,
      evidenceNote: map['evidence_note'] as String?,
      deletedAt: map['deleted_at'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  CpdActivity copyWith({
    int? id,
    int? cycleId,
    String? dateLogged,
    int? categoryId,
    String? categoryName,
    String? subcategory,
    String? activityDescription,
    String? providerName,
    double? durationHours,
    double? pointsClaimed,
    String? competencyDomain,
    String? evidenceNote,
    String? deletedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return CpdActivity(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      dateLogged: dateLogged ?? this.dateLogged,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      activityDescription: activityDescription ?? this.activityDescription,
      providerName: providerName ?? this.providerName,
      durationHours: durationHours ?? this.durationHours,
      pointsClaimed: pointsClaimed ?? this.pointsClaimed,
      competencyDomain: competencyDomain ?? this.competencyDomain,
      evidenceNote: evidenceNote ?? this.evidenceNote,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
