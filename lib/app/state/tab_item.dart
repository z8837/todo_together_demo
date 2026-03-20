import 'package:flutter/material.dart';

enum TabItem {
  projects(
    label: '프로젝트',
    icon: Icons.view_list_outlined,
    activeIcon: Icons.view_list_rounded,
  ),
  schedule(
    label: '일정',
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
  );

  const TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  NavigationDestination toDestination() {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(activeIcon),
      label: label,
    );
  }

  NavigationRailDestination toRailDestination() {
    return NavigationRailDestination(
      icon: Icon(icon),
      selectedIcon: Icon(activeIcon),
      label: Text(label),
    );
  }
}
