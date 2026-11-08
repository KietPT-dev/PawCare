import 'package:flutter/material.dart';
import '../core/network/pawcare_api.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ui.dart';
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
  int _unread = 0;
  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final items = await widget.api.list('/notifications');
      if (mounted)
        setState(() => _unread = items
            .where((x) => x['is_read'] != true && x['is_read'] != 1)
            .length);
    } catch (_) {}
  }

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
          unreadNotifications: _unread,
          onNotificationsChanged: _loadUnread,
          onLogout: widget.onLogout),
    ];
    const labels = ['Trang chủ', 'Khám phá', 'Đơn lịch', 'Tài khoản'];
    const icons = [
      Icons.home_outlined,
      Icons.search,
      Icons.calendar_month_outlined,
      Icons.person_outline
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        IndexedStack(index: index, children: pages),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: LiquidGlassCard(
              radius: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                  children: List.generate(
                      4,
                      (i) => Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => setState(() => index = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                    color: i == index
                                        ? AppColors.teal.withValues(alpha: .16)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(22)),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icons[i],
                                          color: i == index
                                              ? AppColors.teal
                                              : AppColors.navy),
                                      const SizedBox(height: 3),
                                      Text(labels[i],
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: i == index
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: AppColors.navy)),
                                    ]),
                              ),
                            ),
                          ))),
            ),
          ),
        ),
      ]),
    );
  }
}
