import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../schedule/presentation/schedule_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../roadmap/data/roadmap_local_service.dart';
import '../../settings/presentation/settings_screen.dart';
import 'package:ai_study_planner/features/home/presentation/home_screen.dart';

/// The root scaffold for the application, providing bottom navigation.
class MainNavScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;
  String? _activeSkill;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _loadActiveSkill();
  }

  Future<void> _loadActiveSkill() async {
    final skill = await RoadmapLocalService.instance.getActiveSkill();
    if (mounted) {
      setState(() => _activeSkill = skill);
    }
  }

  List<Widget> get _screens => [
    const HomeScreen(key: ValueKey(0)),
    const ScheduleScreen(key: ValueKey(1)),
    ProgressScreen(
        key: const ValueKey(2), skill: _activeSkill ?? 'Data Structures'),
    const SettingsScreen(key: ValueKey(3)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.01, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          height: 80,
          backgroundColor: cs.surfaceContainerHigh,
          elevation: 0,
          indicatorColor: cs.primary.withAlpha(30),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Symbols.home_rounded, fill: 0, color: cs.onSurfaceVariant),
              selectedIcon: Icon(Symbols.home_rounded, fill: 1, color: cs.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Symbols.calendar_today_rounded, fill: 0, color: cs.onSurfaceVariant),
              selectedIcon: Icon(Symbols.calendar_today_rounded, fill: 1, color: cs.primary),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Symbols.bar_chart_rounded, fill: 0, color: cs.onSurfaceVariant),
              selectedIcon: Icon(Symbols.bar_chart_rounded, fill: 1, color: cs.primary),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Symbols.settings_rounded, fill: 0, color: cs.onSurfaceVariant),
              selectedIcon: Icon(Symbols.settings_rounded, fill: 1, color: cs.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
