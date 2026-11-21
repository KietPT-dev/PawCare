import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {super.key, required this.darkMode, required this.onThemeChanged});
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool darkMode = widget.darkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: canPop
            ? Center(
                child: GlassIconButton(
                  size: 38,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        title: Text(
          'Cài đặt',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
      ),
      body: LiquidAmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            const SectionTitle('Giao diện'),
            LiquidGlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile.adaptive(
                secondary: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dark_mode_outlined,
                      color: Color(0xFF6366F1), size: 20),
                ),
                title: Text(
                  'Chế độ tối',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: onSurface,
                  ),
                ),
                subtitle: Text(
                  'Bật giao diện Liquid Glass nền tối',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                activeTrackColor: AppColors.teal,
                value: darkMode,
                onChanged: (value) {
                  setState(() => darkMode = value);
                  widget.onThemeChanged(value);
                },
              ),
            ),
            const SizedBox(height: 10),
            const SectionTitle('Thông báo'),
            LiquidGlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    secondary: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Color(0xFFF59E0B), size: 20),
                    ),
                    title: Text(
                      'Thông báo ứng dụng',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Nhận cập nhật về lịch hẹn và ưu đãi',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    activeTrackColor: AppColors.teal,
                    value: true,
                    onChanged: null,
                  ),
                  const Divider(indent: 68, endIndent: 16),
                  SwitchListTile.adaptive(
                    secondary: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.alarm_outlined,
                          color: AppColors.teal, size: 20),
                    ),
                    title: Text(
                      'Nhắc lịch chăm sóc',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Nhắc nhở trước giờ hẹn 1 tiếng',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    activeTrackColor: AppColors.teal,
                    value: true,
                    onChanged: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const SectionTitle('Ứng dụng'),
            LiquidGlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.language_outlined,
                          color: Color(0xFF0284C7), size: 20),
                    ),
                    title: Text(
                      'Ngôn ngữ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: onSurface,
                      ),
                    ),
                    trailing: const Text(
                      'Tiếng Việt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const Divider(indent: 68, endIndent: 16),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF64748B), size: 20),
                    ),
                    title: Text(
                      'Phiên bản ứng dụng',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: onSurface,
                      ),
                    ),
                    trailing: const Text(
                      'PawCare v1.0.0',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
