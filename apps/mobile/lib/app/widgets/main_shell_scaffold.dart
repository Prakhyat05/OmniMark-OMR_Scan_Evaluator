import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'academic_nav_bar.dart';

class MainShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AcademicNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        onScanTap: () => context.push('/scan'),
      ),
    );
  }
}
