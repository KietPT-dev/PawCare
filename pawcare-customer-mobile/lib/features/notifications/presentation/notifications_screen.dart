import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../activity/presentation/booking_detail_screen.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/network/api_messages.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen(
      {super.key, required this.api, required this.onChanged});
  final PawCareApi api;
  final VoidCallback onChanged;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _items = widget.api.list('/notifications');
  Future<void> _refresh() async {
    setState(_reload);
    await _items;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_outlined, size: 44),
                  const SizedBox(height: 10),
                  Text(ApiMessages.friendly(snapshot.error)),
                  TextButton(onPressed: _refresh, child: const Text('Thử lại'))
                ]));
              final items = snapshot.data ?? [];
              if (items.isEmpty)
                return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(children: const [
                      SizedBox(height: 180),
                      Center(child: Text('Bạn chưa có thông báo nào.'))
                    ]));
              return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    itemCount: items.length,
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final unread =
                          item['is_read'] != true && item['is_read'] != 1;
                      return ListTile(
                        tileColor: unread
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        leading: Icon(unread
                            ? Icons.notifications_active
                            : Icons.notifications_none),
                        title: Text('${item['title'] ?? 'Thông báo'}'),
                        subtitle: Text(
                            '${AppFormatters.replaceRawStatusInNotification('${item['content'] ?? ''}')}\n${AppFormatters.relativeTime(item['created_at'] ?? item['createdAt'])}'),
                        isThreeLine: true,
                        onTap: () async {
                          if (unread)
                            await widget.api
                                .put('/notifications/${item['id']}/read', {});
                          widget.onChanged();
                          if (!context.mounted) return;
                          final bookingId =
                              int.tryParse('${item['reference_id']}');
                          if ('${item['reference_type']}' == 'BOOKING' &&
                              bookingId != null) {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                    api: widget.api, bookingId: bookingId)));
                            if (mounted) _refresh();
                          } else {
                            _refresh();
                          }
                        },
                      );
                    },
                  ));
            }),
      );
}
