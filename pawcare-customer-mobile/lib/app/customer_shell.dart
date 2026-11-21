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
    final activeIcons = [
      Icons.home_rounded,
      Icons.explore_rounded,
      Icons.calendar_month_rounded,
      Icons.person_rounded,
    ];
    final inactiveIcons = [
      Icons.home_outlined,
      Icons.explore_outlined,
      Icons.calendar_month_outlined,
      Icons.person_outline_rounded,
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: LiquidAmbientBackground(
        child: Stack(children: [
          IndexedStack(index: index, children: pages),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: LiquidGlassCard(
                radius: 36,
                blur: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                    children: List.generate(
                        4,
                        (i) => Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: () => setState(() => index = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                      color: i == index
                                          ? AppColors.teal.withValues(
                                              alpha: isDark ? .24 : .14)
                                          : Colors.transparent,
                                      border: i == index
                                          ? Border.all(
                                              color: AppColors.teal.withValues(
                                                  alpha: isDark ? .35 : .22),
                                              width: 1)
                                          : null,
                                      borderRadius: BorderRadius.circular(26)),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              i == index
                                                  ? activeIcons[i]
                                                  : inactiveIcons[i],
                                              size: 24,
                                              color: i == index
                                                  ? AppColors.teal
                                                  : (isDark
                                                      ? const Color(0xFF9CBAC3)
                                                      : const Color(
                                                          0xFF466571)),
                                            ),
                                            if (i == 3 && _unread > 0)
                                              Positioned(
                                                right: -4,
                                                top: -2,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.coral,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(labels[i],
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: i == index
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: i == index
                                                    ? AppColors.teal
                                                    : (isDark
                                                        ? const Color(
                                                            0xFF9CBAC3)
                                                        : const Color(
                                                            0xFF466571)))),
                                      ]),
                                ),
                              ),
                            ))),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
