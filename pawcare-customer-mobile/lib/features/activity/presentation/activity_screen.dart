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
  int _tab = 0;
  late Future<_Data> _data;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _data = _load();
  Future<_Data> _load() async {
    final x = await Future.wait([
      widget.api.list('/bookings'),
      widget.api.list('/reviews'),
      widget.api.list('/complaints')
    ]);
    return _Data(x[0] as List<Map<String, dynamic>>,
        x[1] as List<Map<String, dynamic>>, x[2] as List<Map<String, dynamic>>);
  }

  Future<void> _changed() async => setState(_reload);
  @override
  Widget build(BuildContext c) => SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(
                  child: Text('Lịch hẹn của tôi',
                      style: Theme.of(c)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800))),
              IconButton(onPressed: _changed, icon: const Icon(Icons.refresh))
            ])),
        Padding(
            padding: const EdgeInsets.all(20),
            child: SegmentedButton<int>(segments: const [
              ButtonSegment(value: 0, label: Text('Sắp tới')),
              ButtonSegment(value: 1, label: Text('Lịch sử'))
            ], selected: {
              _tab
            }, onSelectionChanged: (v) => setState(() => _tab = v.first))),
        Expanded(
            child: FutureBuilder<_Data>(
                future: _data,
                builder: (c, s) {
                  if (s.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());
                  if (s.hasError || s.data == null)
                    return _Message(
                        '${s.error ?? 'Không tải được lịch hẹn.'}', _changed);
                  final ended = {'COMPLETED', 'REJECTED', 'CANCELLED'};
                  final rows = s.data!.bookings
                      .where((b) => _tab == 0
                          ? !ended.contains('${b['status']}')
                          : ended.contains('${b['status']}'))
                      .toList();
                  if (rows.isEmpty)
                    return _Message(
                        _tab == 0
                            ? 'Bạn chưa có lịch hẹn sắp tới.'
                            : 'Chưa có lịch sử booking.',
                        _changed);
                  return RefreshIndicator(
                      onRefresh: _changed,
                      child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final b = rows[i];
                            Map<String, dynamic>? find(
                                    List<Map<String, dynamic>> xs) =>
                                xs.cast<Map<String, dynamic>?>().firstWhere(
                                    (x) =>
                                        '${x?['booking_id'] ?? x?['bookingId']}' ==
                                        '${b['id']}',
                                    orElse: () => null);
                            return _Card(b, find(s.data!.reviews),
                                find(s.data!.complaints), widget.api, _changed);
                          }));
                }))
      ]));
}

class _Data {
  const _Data(this.bookings, this.reviews, this.complaints);
  final List<Map<String, dynamic>> bookings, reviews, complaints;
}

class _Card extends StatelessWidget {
  const _Card(this.b, this.review, this.complaint, this.api, this.changed);
  final Map<String, dynamic> b;
  final Map<String, dynamic>? review, complaint;
  final PawCareApi api;
  final Future<void> Function() changed;
  String get status => '${b['status'] ?? 'PENDING'}';
  Future<void> _confirm(BuildContext c) async {
    try {
      await api.post('/bookings/${b['id']}/confirm-completion', {});
      await changed();
    } catch (e) {
      if (c.mounted)
        ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _dispute(BuildContext c) async {
    final text = TextEditingController();
    final yes = await showModalBottomSheet<bool>(
        context: c,
        isScrollControlled: true,
        builder: (s) {
          return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, 24 + MediaQuery.of(s).viewInsets.bottom),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Gửi khiếu nại', style: Theme.of(s).textTheme.titleLarge),
                TextField(
                    controller: text,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Nội dung khiếu nại *')),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () {
                      if (text.text.trim().isEmpty) {
                        ScaffoldMessenger.of(s).showSnackBar(const SnackBar(
                            content: Text('Nội dung khiếu nại là bắt buộc.')));
                        return;
                      }
                      Navigator.pop(s, true);
                    },
                    child: const Text('Gửi khiếu nại'))
              ]));
        });
    if (yes == true) {
      try {
        await api.post(
            '/bookings/${b['id']}/disputes', {'content': text.text.trim()});
        await changed();
      } catch (e) {
        if (c.mounted)
          ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    text.dispose();
  }

  Future<void> _review(BuildContext c) async {
    var stars = 5;
    final note = TextEditingController();
    final yes = await showModalBottomSheet<bool>(
        context: c,
        isScrollControlled: true,
        builder: (s) {
          return StatefulBuilder(builder: (_, setS) {
            return Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 20, 24, 24 + MediaQuery.of(s).viewInsets.bottom),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Đánh giá dịch vụ',
                      style: Theme.of(s).textTheme.titleLarge),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          5,
                          (i) => IconButton(
                              onPressed: () => setS(() => stars = i + 1),
                              icon: Icon(
                                  i < stars ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 34)))),
                  TextField(
                      controller: note,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Nhận xét')),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: () => Navigator.pop(s, true),
                      child: const Text('Gửi đánh giá'))
                ]));
          });
        });
    if (yes == true) {
      try {
        await api.post('/reviews', {
          'bookingId': b['id'],
          'rating': stars,
          'comment': note.text.trim()
        });
        await changed();
      } catch (e) {
        if (c.mounted)
          ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    note.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final canCancel = {'PENDING_APPROVAL', 'PENDING', 'CONFIRMED', 'CHECKED_IN'}
        .contains(status);
    return InfoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
            child: Text('${b['booking_start'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w800))),
        StatusChip(_label(status), color: _color(status))
      ]),
      const SizedBox(height: 8),
      Text('${b['service_name'] ?? 'Dịch vụ'}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      Text(
          '${b['provider_name'] ?? 'Provider'} · ${b['estimated_price'] ?? 0}đ'),
      if (status == 'SERVICE_DONE') ...[
        const Divider(),
        const Text('Provider báo đã hoàn tất',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal)),
        if ('${b['provider_note'] ?? ''}'.isNotEmpty)
          Text('${b['provider_note']}'),
        FilledButton.icon(
            onPressed: () => _confirm(c),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Xác nhận hoàn tất')),
        TextButton.icon(
            onPressed: () => _dispute(c),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Có vấn đề / Khiếu nại'))
      ],
      if (status == 'DISPUTED') ...[
        const Divider(),
        const Text('Đang chờ Admin xử lý tranh chấp',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: AppColors.coral)),
        if (complaint?['admin_response'] != null)
          Text('Phản hồi Admin: ${complaint!['admin_response']}')
      ],
      if (status == 'COMPLETED') ...[
        const Divider(),
        if (review != null)
          Text(
              'Đánh giá đã gửi: ${review!['rating']}★ · ${review!['comment'] ?? 'Không có nhận xét'}')
        else
          TextButton(onPressed: () => _review(c), child: const Text('Đánh giá'))
      ],
      if (canCancel)
        TextButton(
            onPressed: () async {
              try {
                await api.put(
                    '/bookings/${b['id']}/status', {'status': 'CANCELLED'});
                await changed();
              } catch (e) {
                if (c.mounted)
                  ScaffoldMessenger.of(c)
                      .showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Hủy lịch', style: TextStyle(color: Colors.red)))
    ]));
  }

  String _label(String x) =>
      {
        'PENDING_PAYMENT': 'Chờ thanh toán',
        'PENDING_APPROVAL': 'Chờ tiệm duyệt',
        'PENDING': 'Chờ xác nhận',
        'CONFIRMED': 'Đã xác nhận',
        'CHECKED_IN': 'Đã check-in',
        'IN_SERVICE': 'Đang thực hiện',
        'SERVICE_DONE': 'Chờ bạn xác nhận',
        'DISPUTED': 'Đang tranh chấp',
        'COMPLETED': 'Hoàn thành',
        'CANCELLED': 'Đã hủy',
        'REJECTED': 'Bị từ chối'
      }[x] ??
      x;
  Color _color(String x) => x == 'COMPLETED' || x == 'CONFIRMED'
      ? AppColors.teal
      : x == 'DISPUTED' || x == 'SERVICE_DONE'
          ? AppColors.coral
          : x == 'CANCELLED' || x == 'REJECTED'
              ? Colors.red
              : AppColors.teal;
}

class _Message extends StatelessWidget {
  const _Message(this.text, this.retry);
  final String text;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext c) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 48),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
        TextButton(onPressed: retry, child: const Text('Tải lại'))
      ]));
}
