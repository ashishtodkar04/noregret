import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'timetable_screen.dart';
import '../screens/ai_screen.dart';
import 'stats_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int index = 0;

  final pages = [
    const DashboardScreen(),
    const TimetableScreen(),
    const AIScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: IndexedStack(
        index: index,
        children: pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i){
          setState(() {
            index = i;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.white38,
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: "Plan",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_rounded),
            label: "AI",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Stats",
          ),
        ],
      ),
    );
  }
}