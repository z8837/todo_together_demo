import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/state/tab_item.dart';
import '../../../../core/ui/app_tokens.dart';
import '../../../../core/ui/breakpoints.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final useRail = AppBreakpoints.useNavigationRail(context);
    final useExtendedRail = AppBreakpoints.useExtendedRail(context);

    return Scaffold(
      backgroundColor: AppTokens.surface,
      body: Row(
        children: [
          if (useRail)
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              extended: useExtendedRail,
              backgroundColor: AppTokens.surface,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: TabItem.values
                  .map((item) => item.toRailDestination())
                  .toList(growable: false),
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: TabItem.values
                  .map((item) => item.toDestination())
                  .toList(growable: false),
            ),
    );
  }
}
