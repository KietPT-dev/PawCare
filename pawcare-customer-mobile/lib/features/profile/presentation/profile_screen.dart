import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/widgets/ui.dart';
import '../../pets/presentation/pets_screen.dart';
import 'help_center_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.api,
    required this.darkMode,
    required this.onThemeChanged,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  final Map<String, dynamic> profile;
  final PawCareApi api;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<Map<String, dynamic>> onProfileUpdated;
  final VoidCallback onLogout;

  String get _name {
    final value =
        profile['fullName'] ?? profile['full_name'] ?? profile['name'];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString().trim()
        : 'Khách hàng PawCare';
  }

  String get _email => (profile['email'] ?? '').toString();

  String get _initials => _name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 43,
                    backgroundColor: AppColors.mint,
                    child: Text(_initials.isEmpty ? 'PC' : _initials,
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 25)),
                  ),
                  const SizedBox(height: 11),
                  Text(_name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 3),
                  Text(_email.isEmpty ? 'Chưa có email' : _email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SectionTitle('Tài khoản'),
            InfoCard(
              child: Column(children: [
                ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Thông tin cá nhân'),
                    subtitle: const Text('Tên và email đăng ký'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _profileInfo(context)),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.pets_outlined),
                    title: const Text('Quản lý thú cưng'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PetsScreen(api: api)))),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Cài đặt'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                                darkMode: darkMode,
                                onThemeChanged: onThemeChanged)))),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Đổi mật khẩu'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _changePassword(context)),
              ]),
            ),
            const SectionTitle('Hỗ trợ'),
            InfoCard(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Thông báo & nhắc lịch'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _unavailable(
                      context, 'Thông báo hiện được hiển thị ở mục Đơn lịch.'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text('Gửi khiếu nại'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _complaint(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Trung tâm trợ giúp'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HelpCenterScreen())),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất')),
          ],
        ),
      );

  void _profileInfo(BuildContext context) {
    final name = TextEditingController(text: _name);
    final email = TextEditingController(text: _email);
    final phone = TextEditingController(text: '${profile['phone'] ?? ''}');
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Thông tin cá nhân',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Họ và tên')),
                const SizedBox(height: 10),
                TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Số điện thoại')),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () async {
                      try {
                        final updated = await api.put('/auth/me', {
                          'fullName': name.text.trim(),
                          'email': email.text.trim(),
                          'phone': phone.text.trim(),
                        });
                        if (!context.mounted) return;
                        onProfileUpdated(updated);
                        Navigator.pop(context);
                        _unavailable(context, 'Đã cập nhật thông tin cá nhân.');
                      } catch (e) {
                        if (context.mounted)
                          _unavailable(context, e.toString());
                      }
                    },
                    child: const Text('Lưu thay đổi')),
              ]),
            ));
  }

  void _unavailable(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  void _changePassword(BuildContext context) {
    final current = TextEditingController();
    final next = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Đổi mật khẩu',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                  controller: current,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Mật khẩu hiện tại')),
              const SizedBox(height: 10),
              TextField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText:
                          'Mật khẩu mới (ít nhất 10 ký tự, gồm chữ và số)')),
              const SizedBox(height: 14),
              FilledButton(
                  onPressed: () async {
                    try {
                      await api.put('/auth/password', {
                        'currentPassword': current.text,
                        'newPassword': next.text
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        _unavailable(context,
                            'Đổi mật khẩu thành công. Hãy đăng nhập lại.');
                      }
                    } catch (e) {
                      if (context.mounted) _unavailable(context, e.toString());
                    }
                  },
                  child: const Text('Cập nhật')),
            ])));
  }

  void _complaint(BuildContext context) {
    final booking = TextEditingController();
    final content = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Gửi khiếu nại',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                  controller: booking,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mã booking')),
              const SizedBox(height: 10),
              TextField(
                  controller: content,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Nội dung khiếu nại')),
              const SizedBox(height: 14),
              FilledButton(
                  onPressed: () async {
                    try {
                      await api.post('/complaints', {
                        'bookingId': int.tryParse(booking.text),
                        'content': content.text.trim()
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        _unavailable(context, 'Đã gửi khiếu nại.');
                      }
                    } catch (e) {
                      if (context.mounted) _unavailable(context, e.toString());
                    }
                  },
                  child: const Text('Gửi khiếu nại')),
            ])));
  }
}
