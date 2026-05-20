import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

const List<String> kActivityCategories = [
  'Educational Events',
  'Structured Education',
  'Mentoring',
  'Publication',
  'Other',
];

class ActivityRepository extends ChangeNotifier {
  static const String _prefsKey = 'activities_data';
  List<Activity> _items = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      _items = decoded.map((e) => Activity.fromJson(e)).toList();
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, jsonString);
    notifyListeners();
  }

  List<Activity> getAll() {
    return _items.where((a) => a.deletedAt == null).toList();
  }

  double get totalPoints {
    return getAll().fold(0.0, (sum, item) => sum + item.points);
  }

  String _newId() {
    return '${DateTime.now().microsecondsSinceEpoch}';
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
    _save();
    return activity;
  }

  void update(Activity updated) {
    final index = _items.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    _items[index] = updated.copyWith(updatedAt: DateTime.now());
    _save();
  }

  void softDelete(String id) {
    final index = _items.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final now = DateTime.now();
    _items[index] = _items[index].copyWith(deletedAt: now, updatedAt: now);
    _save();
  }
}
