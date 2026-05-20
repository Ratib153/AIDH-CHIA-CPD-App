// Run: dart pub global run flutterfire_cli:flutterfire configure --project=chia-cpd-tracker -y
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Platform Firebase config; placeholders until FlutterFire CLI generates real values.
class DefaultFirebaseOptions {
  /// True after `flutterfire configure` replaces placeholder API keys.
  static bool get isConfigured =>
      android.apiKey != _placeholder && android.apiKey.isNotEmpty;

  static const String _placeholder = 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE';

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError(
        'Firebase is not configured. Run:\n'
        '  dart pub global run flutterfire_cli:flutterfire configure '
        '--project=chia-cpd-tracker -y',
      );
    }
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAKKJOCqss8CaoCUbEJWsFsYMAdVxACQ7c',
    appId: '1:662044863947:web:2f6c2d6a99517aebd5da4e',
    messagingSenderId: '662044863947',
    projectId: 'chia-cpd-tracker',
    authDomain: 'chia-cpd-tracker.firebaseapp.com',
    storageBucket: 'chia-cpd-tracker.firebasestorage.app',
    measurementId: 'G-8VZJ6Z6H59',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDaZXhJTENQIrX_EBgQkwidj-hRrKLgjcY',
    appId: '1:662044863947:android:5b4af4c19aeee953d5da4e',
    messagingSenderId: '662044863947',
    projectId: 'chia-cpd-tracker',
    storageBucket: 'chia-cpd-tracker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBk_HxsRSNvDzJLwcE2rM9AjovKIcfZObQ',
    appId: '1:662044863947:ios:192b5cee6eab5732d5da4e',
    messagingSenderId: '662044863947',
    projectId: 'chia-cpd-tracker',
    storageBucket: 'chia-cpd-tracker.firebasestorage.app',
    iosBundleId: 'com.example.aidhChiaCpdApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBk_HxsRSNvDzJLwcE2rM9AjovKIcfZObQ',
    appId: '1:662044863947:ios:192b5cee6eab5732d5da4e',
    messagingSenderId: '662044863947',
    projectId: 'chia-cpd-tracker',
    storageBucket: 'chia-cpd-tracker.firebasestorage.app',
    iosBundleId: 'com.example.aidhChiaCpdApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAKKJOCqss8CaoCUbEJWsFsYMAdVxACQ7c',
    appId: '1:662044863947:web:f12c9d764420128ed5da4e',
    messagingSenderId: '662044863947',
    projectId: 'chia-cpd-tracker',
    authDomain: 'chia-cpd-tracker.firebaseapp.com',
    storageBucket: 'chia-cpd-tracker.firebasestorage.app',
    measurementId: 'G-2G7CCWVH5P',
  );

}