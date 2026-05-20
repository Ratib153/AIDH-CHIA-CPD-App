import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initDatabaseFactory() async {
  if (kIsWeb) {
    // Avoid requiring `sqflite_sw.js` shared worker on web.
    databaseFactory = createDatabaseFactoryFfiWeb(noWebWorker: true);
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
