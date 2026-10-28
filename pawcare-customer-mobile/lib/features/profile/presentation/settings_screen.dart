import 'package:flutter/material.dart';

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
  bool notifications = true;
  bool reminders = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cài đặt')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const SectionTitle('Giao diện'),
          InfoCard(
              child: SwitchListTile.adaptive(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Chế độ tối'),
            subtitle:
                const Text('Điều chỉnh giao diện phù hợp khi dùng buổi tối'),
            value: darkMode,
            onChanged: (value) {
              setState(() => darkMode = value);
              widget.onThemeChanged(value);
            },
          )),
          const SectionTitle('Thông báo'),
          InfoCard(
              child: Column(children: [
            SwitchListTile.adaptive(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Thông báo ứng dụng'),
                subtitle: const Text('Nhận cập nhật về đơn lịch'),
                value: notifications,
                onChanged: (value) => setState(() => notifications = value)),
            const Divider(),
            SwitchListTile.adaptive(
                secondary: const Icon(Icons.alarm_outlined),
                title: const Text('Nhắc lịch chăm sóc'),
                subtitle: const Text('Nhắc trước lịch hẹn của thú cưng'),
                value: reminders,
                onChanged: (value) => setState(() => reminders = value)),
          ])),
          const SectionTitle('Ứng dụng'),
          InfoCard(
              child: const Column(children: [
            ListTile(
                leading: Icon(Icons.language_outlined),
                title: Text('Ngôn ngữ'),
                trailing: Text('Tiếng Việt')),
            Divider(),
            ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Phiên bản ứng dụng'),
                trailing: Text('1.0.0')),
          ])),
        ]),
      );
}
