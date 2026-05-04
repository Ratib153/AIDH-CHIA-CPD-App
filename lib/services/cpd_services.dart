import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CpdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Add a CPD activity
  Future<void> addActivity({
    required String title,
    required int hours,
  }) async {
    if (userId == null) return;

    await _db.collection('users')
        .doc(userId)
        .collection('activities')
        .add({
      'title': title,
      'hours': hours,
      'createdAt': Timestamp.now(),
    });
  }

  // Get activities stream (real-time updates)
  Stream<QuerySnapshot> getActivities() {
    if (userId == null) {
      return const Stream.empty();
    }

    return _db
        .collection('users')
        .doc(userId)
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}