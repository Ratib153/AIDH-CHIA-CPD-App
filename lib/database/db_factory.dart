import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web and desktop (Windows/Linux/macOS) use sqflite FFI. Android and iOS must
/// use the default embedded [sqflite] factory — FFI on mobile fails with
/// `unable to open database file` (sqlite 14).
Future<void> initDatabaseFactory() async {
  if (kIsWeb) {
    databaseFactory = createDatabaseFactoryFfiWeb(noWebWorker: true);
    return;
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return;
  }
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
