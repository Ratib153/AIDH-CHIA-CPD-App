import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Installs the correct sqflite factory per-platform.
///
/// - **Web** → `sqflite_common_ffi_web` (no shared-worker mode).
/// - **Desktop** (Windows / macOS / Linux) → `sqflite_common_ffi` (native FFI).
/// - **Mobile** (Android / iOS) → leave the default `sqflite` factory in place,
///   which uses the platform's native SQLite via method channels.
///   Forcing FFI on Android causes `SqliteException(14): unable to open
///   database file` because the FFI factory cannot resolve the app's
///   private files directory the way the platform-channel plugin does.
Future<void> initDatabaseFactory() async {
  if (kIsWeb) {
    databaseFactory = createDatabaseFactoryFfiWeb(noWebWorker: true);
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      break;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      // Use the default sqflite factory shipped by the `sqflite` plugin.
      break;
  }
}
