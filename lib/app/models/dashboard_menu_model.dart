import 'package:flutter/material.dart';

class DashboardItem {
  final String id;
  final String title;
  final String icon;
  final String? route;
  final VoidCallback? onTap;

  DashboardItem({
    required this.id,
    required this.title,
    required this.icon,
    this.route,
    this.onTap,
  });
}

class DashboardGroup {
  final String title;
  final List<DashboardItem> items;

  DashboardGroup({
    required this.title,
    required this.items,
  });
}