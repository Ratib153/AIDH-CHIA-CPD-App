import '../models/activity.dart';

const List<String> kActivityCategories = [
  'Educational Events',
  'Structured Education',
  'Mentoring',
  'Publication',
  'Other',
];

class ActivityRepository {
  ActivityRepository._() {
    final now = DateTime.now();
    _items.addAll([
      Activity(
        id: _newId(),
        title: 'AHIMA Conference 2024',
        category: 'Educational Events',
        date: DateTime(2024, 10, 15),
        points: 15,
        notes: 'Sessions on clinical informatics and governance.',
        updatedAt: now,
      ),
      Activity(
        id: _newId(),
        title: 'Health Data Analytics Course',
        category: 'Structured Education',
        date: DateTime(2024, 9, 28),
        points: 10,
        notes: 'Completed online module with assessment.',
        updatedAt: now,
      ),
      Activity(
        id: _newId(),
        title: 'Mentoring Junior Analyst',
        category: 'Mentoring',
        date: DateTime(2024, 7, 16),
        points: 6,
        updatedAt: now,
      ),
    ]);
  }

  static final ActivityRepository instance = ActivityRepository._();

  final List<Activity> _items = [];
  int _idCounter = 0;

  String _newId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  List<Activity> getAll() {
    return _items.where((a) => a.deletedAt == null).toList();
  }

  Activity add({
    required String title,
    required String category,
    required DateTime date,
    required double points,
    String? notes,
  }) {
    final activity = Activity(
      id: _newId(),
      title: title,
      category: category,
      date: date,
      points: points,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    _items.add(activity);
    return activity;
  }

  void update(Activity updated) {
    final index = _items.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    _items[index] = updated.copyWith(updatedAt: DateTime.now());
  }

  void softDelete(String id) {
    final index = _items.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final now = DateTime.now();
    _items[index] = _items[index].copyWith(deletedAt: now, updatedAt: now);
  }
}
