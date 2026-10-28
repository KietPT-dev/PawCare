import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.api});
  final PawCareApi api;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int tab = 0;
  late Future<List<Map<String, dynamic>>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = widget.api.list('/bookings');
  }

  void _reload() => setState(() => _bookings = widget.api.list('/bookings'));

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(
                  child: Text('Lịch hẹn của tôi',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface))),
              IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
            ])),
        Padding(
            padding: const EdgeInsets.all(20),
            child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Sắp tới')),
                  ButtonSegment(value: 1, label: Text('Lịch sử'))
                ],
                selected: {
                  tab
                },
                onSelectionChanged: (value) =>
                    setState(() => tab = value.first))),
        Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _bookings,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError)
                    return _Message(
                        icon: Icons.cloud_off_outlined,
                        text: snapshot.error.toString(),
                        action: _reload);
                  final history = {'COMPLETED', 'REJECTED', 'CANCELLED'};
                  final rows = (snapshot.data ?? [])
                      .where((row) => tab == 0
                          ? !history.contains('${row['status']}')
                          : history.contains('${row['status']}'))
                      .toList();
                  if (rows.isEmpty)
                    return _Message(
                        icon: Icons.calendar_month_outlined,
                        text: tab == 0
                            ? 'Bạn chưa có lịch hẹn sắp tới.'
                            : 'Chưa có lịch sử booking.',
                        action: _reload);
                  return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => _BookingCard(
                              booking: rows[index],
                              onCancel: () => _cancel(rows[index]),
                              onReview: () => _review(rows[index]))));
                }))
      ]));

  Future<void> _cancel(Map<String, dynamic> booking) async {
    final reason = TextEditingController();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Hủy booking?'),
              content: TextField(
                  controller: reason,
                  decoration: const InputDecoration(
                      labelText: 'Lý do hủy (không bắt buộc)')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Quay lại')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Xác nhận hủy'))
              ],
            ));
    if (accepted == true) {
      try {
        await widget.api.put('/bookings/${booking['id']}/status',
            {'status': 'CANCELLED', 'cancelReason': reason.text.trim()});
        _reload();
      } catch (error) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
    reason.dispose();
  }

  Future<void> _review(Map<String, dynamic> booking) async {
    var rating = 5;
    final comment = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (sheetContext, setSheetState) => Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24,
                      24 + MediaQuery.of(sheetContext).viewInsets.bottom),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Đánh giá dịch vụ',
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    DropdownButton<int>(
                        value: rating,
                        isExpanded: true,
                        items: [1, 2, 3, 4, 5]
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text('$value sao')))
                            .toList(),
                        onChanged: (value) =>
                            setSheetState(() => rating = value!)),
                    TextField(
                        controller: comment,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Nhận xét')),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Gửi đánh giá')),
                  ]),
                )));
    if (sent == true) {
      try {
        await widget.api.post('/reviews', {
          'bookingId': booking['id'],
          'rating': rating,
          'comment': comment.text.trim()
        });
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá.')));
      } catch (error) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
    comment.dispose();
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard(
      {required this.booking, required this.onCancel, required this.onReview});
  final Map<String, dynamic> booking;
  final VoidCallback onCancel;
  final VoidCallback onReview;
  @override
  Widget build(BuildContext context) {
    final status = '${booking['status'] ?? 'PENDING'}';
    final cancellable = {'PENDING', 'CONFIRMED', 'CHECKED_IN'}.contains(status);
    return InfoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${booking['booking_start'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        StatusChip(_label(status), color: _color(status))
      ]),
      const SizedBox(height: 10),
      Text('${booking['service_name'] ?? 'Dịch vụ'}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      Text(
          '${booking['provider_name'] ?? 'Provider'} · ${booking['estimated_price'] ?? 0}đ'),
      if (cancellable || status == 'COMPLETED') ...[
        const SizedBox(height: 8),
        Row(children: [
          if (cancellable)
            TextButton(
                onPressed: onCancel,
                child: const Text('Hủy lịch',
                    style: TextStyle(color: Colors.red))),
          if (status == 'COMPLETED')
            TextButton(onPressed: onReview, child: const Text('Đánh giá'))
        ])
      ]
    ]));
  }

  String _label(String value) =>
      {
        'PENDING': 'Chờ xác nhận',
        'CONFIRMED': 'Đã xác nhận',
        'CHECKED_IN': 'Đã check-in',
        'IN_SERVICE': 'Đang thực hiện',
        'COMPLETED': 'Hoàn thành',
        'CANCELLED': 'Đã hủy',
        'REJECTED': 'Bị từ chối'
      }[value] ??
      value;
  Color _color(String value) => value == 'COMPLETED' || value == 'CONFIRMED'
      ? AppColors.teal
      : value == 'CANCELLED' || value == 'REJECTED'
          ? Colors.red
          : AppColors.coral;
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon, required this.text, required this.action});
  final IconData icon;
  final String text;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
        TextButton(onPressed: action, child: const Text('Tải lại'))
      ]));
}
