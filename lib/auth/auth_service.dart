import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication wrapper used across the app.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  /// Username stored on the Firebase user profile ([User.displayName]).
  String? get username {
    final name = currentUser?.displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  void init() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await updateUsername(username);
    return credential;
  }

  Future<void> updateUsername(String username) async {
    final user = currentUser;
    if (user == null) return;
    await user.updateDisplayName(username.trim());
    await user.reload();
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
