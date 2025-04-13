import 'package:flutter/material.dart';

const List<BottomNavigationBarItem> defaultBottomNavigationBarItems = [
  BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
  BottomNavigationBarItem(icon: Icon(Icons.edit_calendar), label: ''),
  BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ''),
  BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
];

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final Color? backgroundColor;
  final Color? fixedColor;
  final BottomNavigationBarType? type;
  final double? elevation;
  final IconThemeData? selectedIconTheme;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultBottomNavigationBarItems,
    this.backgroundColor = Colors.transparent,
    this.fixedColor = Colors.white,
    this.type = BottomNavigationBarType.fixed,
    this.elevation = 0,
    this.selectedIconTheme = const IconThemeData(size: 30.0),
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
      backgroundColor: backgroundColor,
      fixedColor: fixedColor,
      type: type,
      elevation: elevation,
      selectedIconTheme: selectedIconTheme,
    );
  }
}