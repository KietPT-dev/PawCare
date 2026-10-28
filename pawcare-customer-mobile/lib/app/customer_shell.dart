import 'package:flutter/material.dart';
import '../core/network/pawcare_api.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/discovery/presentation/discovery_screen.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell(
      {super.key,
      required this.api,
      required this.session,
      required this.darkMode,
      required this.onThemeChanged,
      required this.onProfileUpdated,
      required this.onLogout});
  final PawCareApi api;
  final AuthSession session;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<Map<String, dynamic>> onProfileUpdated;
  final VoidCallback onLogout;
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(profile: widget.session.profile, api: widget.api),
      DiscoveryScreen(api: widget.api),
      ActivityScreen(api: widget.api),
      ProfileScreen(
          profile: widget.session.profile,
          api: widget.api,
          darkMode: widget.darkMode,
          onThemeChanged: widget.onThemeChanged,
          onProfileUpdated: widget.onProfileUpdated,
          onLogout: widget.onLogout),
    ];
    return Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Trang chủ'),
              NavigationDestination(
                  icon: Icon(Icons.search), label: 'Khám phá'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Đơn lịch'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Tài khoản')
            ]));
  }
}
