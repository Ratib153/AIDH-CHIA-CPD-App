class RecertificationCycle {
  const RecertificationCycle({
    this.id,
    required this.cycleName,
    required this.startDate,
    required this.endDate,
    required this.targetPoints,
    required this.isActive,
    required this.createdAt,
  });

  final int? id;
  final String cycleName;
  final String startDate;
  final String endDate;
  final double targetPoints;
  final bool isActive;
  final String createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycle_name': cycleName,
      'start_date': startDate,
      'end_date': endDate,
      'target_points': targetPoints,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory RecertificationCycle.fromMap(Map<String, dynamic> map) {
    return RecertificationCycle(
      id: map['id'] as int?,
      cycleName: map['cycle_name'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      targetPoints: (map['target_points'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  RecertificationCycle copyWith({
    int? id,
    String? cycleName,
    String? startDate,
    String? endDate,
    double? targetPoints,
    bool? isActive,
    String? createdAt,
  }) {
    return RecertificationCycle(
      id: id ?? this.id,
      cycleName: cycleName ?? this.cycleName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetPoints: targetPoints ?? this.targetPoints,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
