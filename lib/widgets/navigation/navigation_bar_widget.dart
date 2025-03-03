// lib/widgets/navigation/navigation_bar_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/devices/device_screen.dart';
import '../../screens/scans/scan_screen.dart';
import '../../screens/reports/report_screen.dart';
import '../../screens/settings/settings_screen.dart';

class NavigationBarWidget extends StatefulWidget {
  final int initialIndex;

  const NavigationBarWidget({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<NavigationBarWidget> createState() => _NavigationBarWidgetState();
}

class _NavigationBarWidgetState extends State<NavigationBarWidget> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DeviceScreen(),
    const ScanScreen(),
    const ReportScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
    ),// lib/widgets/navigation/navigation_bar_widget.dart (continued)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black12,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 2 ? FloatingActionButton(
        onPressed: () {
          // Start new scan
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScanScreen(startNewScan: true),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.play_arrow),
      ) : null,
    );
  }
}