import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../pets/presentation/pets_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.api,
    required this.providerId,
    required this.providerName,
  });
  final PawCareApi api;
  final int providerId;
  final String providerName;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int step = 0;
  late Future<_BookingData> _data;
  Map<String, dynamic>? service;
  Map<String, dynamic>? pet;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  String slot = '09:00';
  final note = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _data = _loadBookingData();

  Future<_BookingData> _loadBookingData() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      widget.api.list('/services?providerId=${widget.providerId}'),
      widget.api.list('/pets'),
    ]);
    return _BookingData(services: results[0], pets: results[1]);
  }

  void _retry() => setState(_load);

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tạo booking')),
        body: FutureBuilder<_BookingData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _BookingMessage(
                icon: Icons.calendar_month_outlined,
                title: 'Đang chuẩn bị lịch hẹn',
                message: 'Đang tải dịch vụ và hồ sơ thú cưng của bạn…',
                loading: true,
              );
            }
            if (snapshot.hasError) {
              return _BookingMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Chưa thể tải biểu mẫu đặt lịch',
                message: _friendlyError(snapshot.error),
                actionLabel: 'Thử lại',
                onAction: _retry,
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return _BookingMessage(
                icon: Icons.error_outline,
                title: 'Không có dữ liệu booking',
                message: 'Hãy thử tải lại biểu mẫu đặt lịch.',
                actionLabel: 'Tải lại',
                onAction: _retry,
              );
            }
            final services = data.services;
            final pets = data.pets;
            if (services.isEmpty || pets.isEmpty) {
              return _BookingMessage(
                icon: services.isEmpty
                    ? Icons.storefront_outlined
                    : Icons.pets_outlined,
                title: services.isEmpty
                    ? 'Provider chưa có dịch vụ khả dụng'
                    : 'Bạn chưa có thú cưng',
                message: services.isEmpty
                    ? 'Hãy thử một Provider khác hoặc quay lại sau.'
                    : 'Thêm hồ sơ thú cưng trước khi tạo booking.',
                actionLabel: services.isEmpty ? 'Tải lại' : 'Quản lý thú cưng',
                onAction: services.isEmpty
                    ? _retry
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PetsScreen(api: widget.api))),
              );
            }
            service ??= services.first;
            pet ??= pets.first;
            final pages = [
              _chooseService(services, pets),
              _chooseTime(),
              _confirm()
            ];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                          value: (step + 1) / 3,
                          borderRadius: BorderRadius.circular(10)),
                      const SizedBox(height: 18),
                      Text(
                          [
                            'Chọn dịch vụ',
                            'Chọn ngày giờ',
                            'Xác nhận yêu cầu'
                          ][step],
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(widget.providerName),
                      const SizedBox(height: 16),
                      Expanded(child: pages[step]),
                      Row(children: [
                        if (step > 0)
                          TextButton(
                              onPressed: () => setState(() => step--),
                              child: const Text('Quay lại')),
                        const Spacer(),
                        FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.coral),
                            onPressed: saving
                                ? null
                                : () => step < 2
                                    ? setState(() => step++)
                                    : _submit(),
                            child: Text(saving
                                ? 'Đang gửi...'
                                : step == 2
                                    ? 'Gửi yêu cầu'
                                    : 'Tiếp tục')),
                      ])
                    ]),
              ),
            );
          },
        ),
      );

  String _friendlyError(Object? error) {
    final message = error?.toString() ?? '';
    if (message.contains('401') || message.contains('đăng nhập')) {
      return 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại rồi thử lại.';
    }
    return message.isEmpty
        ? 'Không thể kết nối dữ liệu booking. Hãy kiểm tra kết nối và thử lại.'
        : message;
  }

  Widget _chooseService(List<Map<String, dynamic>> services,
          List<Map<String, dynamic>> pets) =>
      ListView(children: [
        const Text('Dịch vụ'),
        ...services.map((item) => RadioListTile<Map<String, dynamic>>(
            value: item,
            groupValue: service,
            onChanged: (value) => setState(() => service = value),
            title: Text('${item['name']}'),
            subtitle:
                Text('${item['duration_minutes']} phút · ${item['price']}đ'))),
        const Divider(),
        const Text('Thú cưng'),
        ...pets.map((item) => RadioListTile<Map<String, dynamic>>(
            value: item,
            groupValue: pet,
            onChanged: (value) => setState(() => pet = value),
            title: Text('${item['name']}'),
            subtitle: Text('${item['species']} ${item['breed'] ?? ''}'))),
      ]);

  Widget _chooseTime() => ListView(children: [
        ListTile(
            title: const Text('Ngày hẹn'),
            subtitle: Text('${date.day}/${date.month}/${date.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate),
        const SizedBox(height: 12),
        const Text('Khung giờ'),
        const SizedBox(height: 10),
        Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['08:00', '09:00', '10:30', '13:00', '15:00']
                .map((value) => ChoiceChip(
                    label: Text(value),
                    selected: slot == value,
                    onSelected: (_) => setState(() => slot = value)))
                .toList()),
        const SizedBox(height: 22),
        TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Ghi chú/yêu cầu cho Provider')),
      ]);

  Widget _confirm() => ListView(children: [
        ListTile(
            title: const Text('Thú cưng'),
            subtitle: Text('${pet?['name']} · ${pet?['species']}')),
        ListTile(
            title: const Text('Dịch vụ'),
            subtitle: Text(
                '${service?['name']} · ${service?['duration_minutes']} phút')),
        ListTile(
            title: const Text('Thời gian'),
            subtitle: Text('${date.day}/${date.month}/${date.year} · $slot')),
        const Divider(),
        ListTile(
            title: const Text('Tổng dự kiến'),
            trailing: Text('${service?['price']}đ',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.coral))),
      ]);

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 180)),
        initialDate: date);
    if (selected != null) setState(() => date = selected);
  }

  Future<void> _submit() async {
    setState(() => saving = true);
    try {
      final time = slot.split(':');
      final start = DateTime(date.year, date.month, date.day,
          int.parse(time[0]), int.parse(time[1]));
      await widget.api.post('/bookings', {
        'petId': pet!['id'],
        'providerId': widget.providerId,
        'serviceId': service!['id'],
        'bookingStart': start.toIso8601String(),
        'customerNote': note.text.trim(),
      });
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (_) =>
              AlertDialog(
                  icon: const Icon(Icons.check_circle,
                      color: AppColors.teal, size: 48),
                  title: const Text('Đã gửi yêu cầu'),
                  content:
                      const Text('Provider sẽ xác nhận lịch hẹn của bạn sớm.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Xong'))
                  ]));
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _BookingData {
  const _BookingData({required this.services, required this.pets});
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> pets;
}

class _BookingMessage extends StatelessWidget {
  const _BookingMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const CircularProgressIndicator()
                  : Icon(icon, color: AppColors.teal, size: 36),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!)),
            ],
          ]),
        ),
      );
}
