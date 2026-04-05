import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_colors.dart';

import '../../schedule/presentation/schedule_screen.dart';
import 'home_screen.dart';

/// The root scaffold for the application, providing bottom navigation.
///
/// Phase 1.7: Added [initialIndex] so other screens can navigate back to a
/// specific tab (e.g. "Change Goal" returns to Home).
class MainNavScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ScheduleScreen(), // S05 - Schedule
    const Scaffold(body: Center(child: Text('Progress (S08)'))),
    const Scaffold(body: Center(child: Text('Resources (S13)'))),
    const Scaffold(body: Center(child: Text('Settings (S14)'))),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        height: 80,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.home_rounded, fill: 0, color: AppColors.onSurfaceVariant),
            selectedIcon: Icon(Symbols.home_rounded, fill: 1, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Symbols.calendar_today_rounded, fill: 0, color: AppColors.onSurfaceVariant),
            selectedIcon: Icon(Symbols.calendar_today_rounded, fill: 1, color: AppColors.primary),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Symbols.bar_chart_rounded, fill: 0, color: AppColors.onSurfaceVariant),
            selectedIcon: Icon(Symbols.bar_chart_rounded, fill: 1, color: AppColors.primary),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Symbols.folder_rounded, fill: 0, color: AppColors.onSurfaceVariant),
            selectedIcon: Icon(Symbols.folder_rounded, fill: 1, color: AppColors.primary),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(Symbols.settings_rounded, fill: 0, color: AppColors.onSurfaceVariant),
            selectedIcon: Icon(Symbols.settings_rounded, fill: 1, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
