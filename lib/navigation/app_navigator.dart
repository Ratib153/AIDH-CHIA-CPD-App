import 'package:flutter/material.dart';

/// Lets child screens switch the main bottom-navigation tab without importing [AppScaffold].
class AppNavigator extends InheritedWidget {
  const AppNavigator({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final void Function(int index) selectTab;

  static AppNavigator? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppNavigator>();
  }

  @override
  bool updateShouldNotify(covariant AppNavigator oldWidget) => false;
}
