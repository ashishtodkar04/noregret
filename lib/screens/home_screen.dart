import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'timetable_screen.dart';
import 'dashboard_screen.dart';
import 'ai_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isGhostMode = false;

  final PageController _pageController =
      PageController(initialPage: 0);

  final List<String> _clinicalTitles = [
    "LOG_MAP",
    "TIMELINE",
    "NEURAL_LINK",
    "ANALYTICS"
  ];

  final List<String> _missionTitles = [
    "MISSION PLAN",
    "OBJECTIVES",
    "COMMAND HUB",
    "MOMENTUM"
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutExpo,
    );
    HapticFeedback.lightImpact();
  }

  void _toggleGhostMode() {
    HapticFeedback.heavyImpact();
    setState(() => _isGhostMode = !_isGhostMode);
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainScaffold();
  }

  Widget _buildMainScaffold() {
    final Color activeColor =
        _isGhostMode ? const Color(0xFF637381) : Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onLongPress: _toggleGhostMode,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _isGhostMode
                  ? _clinicalTitles[_selectedIndex]
                  : _missionTitles[_selectedIndex],
              key: ValueKey('$_selectedIndex$_isGhostMode'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 12,
                color: _isGhostMode
                    ? activeColor
                    : Colors.white70,
                fontFamily:
                    _isGhostMode ? 'monospace' : null,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.hub_outlined,
              color: activeColor.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) =>
            setState(() => _selectedIndex = index),
        children: const [
          DashboardScreen(),
          TimetableScreen(),
          AIScreen(),
          StatsScreen(),
        ],
      ),
      bottomNavigationBar:
          _buildBottomNav(activeColor),
    );
  }

  Widget _buildBottomNav(Color activeColor) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(
                0, Icons.grid_view_rounded, activeColor),
            _navItem(
                1, Icons.checklist_rtl_rounded,
                activeColor),
            _navItem(
                2, Icons.psychology_outlined,
                activeColor),
            _navItem(
                3, Icons.bar_chart_rounded,
                activeColor),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, Color activeColor) {
    final bool isSelected =
        _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? activeColor
              : Colors.white24,
          size: 24,
        ),
      ),
    );
  }
}
