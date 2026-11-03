import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../activity/presentation/activity_screen.dart';

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
                    child: TextButton(
                        onPressed: _refresh, child: Text('${snapshot.error}')));
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
                        subtitle: Text('${item['content'] ?? ''}'),
                        onTap: () async {
                          if (unread)
                            await widget.api
                                .put('/notifications/${item['id']}/read', {});
                          widget.onChanged();
                          if (!context.mounted) return;
                          if ('${item['reference_type']}' == 'BOOKING') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ActivityScreen(api: widget.api)));
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
