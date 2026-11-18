import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension NavigationExtensions on BuildContext {
  /// Safely pops the current route if possible, or redirects to fallback location
  void safePop([String fallbackLocation = '/dashboard']) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackLocation);
    }
  }
}
