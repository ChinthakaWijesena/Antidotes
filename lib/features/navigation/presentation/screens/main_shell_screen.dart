import 'package:flutter/material.dart';
import 'package:antidotes/features/junk_cleaner/presentation/screens/junk_cleaner_screen.dart';
import 'package:antidotes/features/startup_manager/presentation/screens/startup_manager_screen.dart';
import '../widgets/app_sidebar.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedNavIndex = 0;

  final List<Widget> _screens = const [
    JunkCleanerScreen(),
    StartupManagerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar Navigation
          AppSidebar(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
          ),

          // Main View Content
          Expanded(
            child: IndexedStack(
              index: _selectedNavIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
