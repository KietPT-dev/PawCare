import 'package:flutter/material.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/network/api_messages.dart';
import 'booking_detail_screen.dart';

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
    return _Data(x[0], x[1], x[2]);
  }

  Future<void> _changed() async {
    if (!mounted) return;
    setState(_reload);
    await _data;
  }

  @override
  Widget build(BuildContext c) => SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Lịch hẹn của tôi',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Theo dõi lịch hẹn của bạn',
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(c)
                                .colorScheme
                                .onSurfaceVariant)),
                  ])),
              IconButton(onPressed: _changed, icon: const Icon(Icons.refresh))
            ])),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: LiquidGlassCard(
              radius: 16,
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                _tabButton(0, 'Sắp tới'),
                _tabButton(1, 'Lịch sử'),
              ]),
            )),
        Expanded(
            child: FutureBuilder<_Data>(
                future: _data,
                builder: (c, s) {
                  if (s.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());
                  if (s.hasError || s.data == null)
                    return _Message(ApiMessages.friendly(s.error), _changed);
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
                            return FadeSlideIn(
                                index: i,
                                child: _Card(
                                    b,
                                    find(s.data!.reviews),
                                    find(s.data!.complaints),
                                    widget.api,
                                    _changed));
                          }));
                }))
      ]));

  Widget _tabButton(int value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.darkSurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: .15)
                        : Colors.white.withValues(alpha: .9),
                    width: 1)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFF163832))
                          .withValues(alpha: isDark ? .25 : .08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? AppColors.teal
                    : (isDark
                        ? const Color(0xFF9CBAC3)
                        : const Color(0xFF6B8791)),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    _showWorking(c, 'Đang xác nhận hoàn tất...');
    try {
      await api.post('/bookings/${b['id']}/confirm-completion', {});
      if (c.mounted) Navigator.of(c, rootNavigator: true).pop();
      await changed();
      if (c.mounted) {
        ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
            content:
                Text('Đã xác nhận hoàn tất. Bạn có thể đánh giá dịch vụ.')));
      }
    } catch (e) {
      if (c.mounted) Navigator.of(c, rootNavigator: true).pop();
      if (c.mounted)
        ScaffoldMessenger.of(c)
            .showSnackBar(SnackBar(content: Text(ApiMessages.friendly(e))));
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
      if (!c.mounted) return;
      _showWorking(c, 'Đang gửi khiếu nại...');
      try {
        await api.post(
            '/bookings/${b['id']}/disputes', {'content': text.text.trim()});
        if (c.mounted) Navigator.of(c, rootNavigator: true).pop();
        await changed();
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
              content:
                  Text('Đã gửi khiếu nại. Tiền escrow vẫn được tạm giữ.')));
        }
      } catch (e) {
        if (c.mounted) Navigator.of(c, rootNavigator: true).pop();
        if (c.mounted)
          ScaffoldMessenger.of(c)
              .showSnackBar(SnackBar(content: Text(ApiMessages.friendly(e))));
      }
    }
    text.dispose();
  }

  void _showWorking(BuildContext context, String label) {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
            canPop: false,
            child: AlertDialog(
                content: Row(children: [
              const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator()),
              const SizedBox(width: 16),
              Expanded(child: Text(label)),
            ]))));
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
          ScaffoldMessenger.of(c)
              .showSnackBar(SnackBar(content: Text(ApiMessages.friendly(e))));
      }
    }
    note.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final canCancel = {'PENDING_APPROVAL', 'PENDING', 'CONFIRMED', 'CHECKED_IN'}
        .contains(status);
    return InfoCard(
        onTap: () => Navigator.of(c).push(MaterialPageRoute(
            builder: (_) => BookingDetailScreen(
                api: api, bookingId: int.tryParse('${b['id']}') ?? 0))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: AppColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month,
                  color: AppColors.teal, size: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                AppFormatters.dateTime(b['booking_start']),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(c)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text('${b['service_name'] ?? 'Dịch vụ'}',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800)),
                          ])),
                      Text(AppFormatters.money(b['estimated_price']),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal)),
                    ]),
                const SizedBox(height: 4),
                Text('${b['provider_name'] ?? 'Provider'}',
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(c)
                            .colorScheme
                            .onSurfaceVariant)),
                const SizedBox(height: 8),
                if ({
                  'PENDING_PAYMENT',
                  'PENDING_APPROVAL',
                  'CONFIRMED',
                  'CHECKED_IN',
                  'IN_SERVICE',
                  'SERVICE_DONE',
                  'DISPUTED',
                  'SYSTEM_REVIEW'
                }.contains(status))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                          'Tiền dịch vụ đang được giữ an toàn trong escrow.',
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 11,
                              fontStyle: FontStyle.italic))),
                if (status == 'SERVICE_DONE') ...[
                  const Divider(height: 16),
                  const Text('Provider báo đã hoàn tất',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal,
                          fontSize: 13)),
                  if ('${b['provider_note'] ?? ''}'.isNotEmpty)
                    Text('${b['provider_note']}'),
                  const SizedBox(height: 6),
                  Row(children: [
                    TextButton(
                        onPressed: () => _confirm(c),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            textStyle: const TextStyle(fontSize: 13)),
                        child: const Text('Xác nhận hoàn tất')),
                    const SizedBox(width: 6),
                    TextButton(
                        onPressed: () => _dispute(c),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            foregroundColor: AppColors.coral,
                            textStyle: const TextStyle(fontSize: 13)),
                        child: const Text('Có vấn đề / Khiếu nại')),
                  ]),
                ],
                if (status == 'DISPUTED') ...[
                  const Divider(height: 16),
                  const Text('Đang chờ Admin xử lý tranh chấp',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.coral,
                          fontSize: 13)),
                  if (complaint?['admin_response'] != null)
                    Text('Phản hồi Admin: ${complaint!['admin_response']}')
                ],
                if (status == 'COMPLETED') ...[
                  const Divider(height: 16),
                  if (review != null)
                    Text(
                        'Đánh giá đã gửi: ${review!['rating']}★ · ${review!['comment'] ?? 'Không có nhận xét'}')
                  else
                    TextButton(
                        onPressed: () => _review(c),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            textStyle: const TextStyle(fontSize: 13)),
                        child: const Text('Đánh giá'))
                ],
                const SizedBox(height: 6),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BookingStatusChip(status),
                      if (canCancel)
                        TextButton(
                            onPressed: () async {
                              try {
                                await api.put('/bookings/${b['id']}/status',
                                    {'status': 'CANCELLED'});
                                await changed();
                              } catch (e) {
                                if (c.mounted)
                                  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                                      content:
                                          Text(ApiMessages.friendly(e))));
                              }
                            },
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                foregroundColor: Colors.red,
                                textStyle: const TextStyle(fontSize: 13)),
                            child: const Text('Hủy lịch')),
                    ]),
              ]))
        ]));
  }
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
        Text(ApiMessages.friendly(text), textAlign: TextAlign.center),
        TextButton(onPressed: retry, child: const Text('Tải lại'))
      ]));
}
