import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/activities/data/activity_repository.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ActivityRepository()..load(),
      child: const ChiaCpdApp(),
    ),
  );
}
