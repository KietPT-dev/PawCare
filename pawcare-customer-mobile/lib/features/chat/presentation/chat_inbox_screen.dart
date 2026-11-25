import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/ui.dart';
import 'conversation_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key, required this.api, this.onChanged});
  final PawCareApi api;
  final VoidCallback? onChanged;
  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _items = widget.api.list('/conversations?page=0&size=20');
  Future<void> _refresh() async {
    setState(_reload);
    await _items;
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tin nhắn với cơ sở')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return _Message(
                    text: ApiMessages.friendly(snapshot.error),
                    retry: _refresh);
              final rows = snapshot.data ?? [];
              return RefreshIndicator(
                  onRefresh: _refresh,
                  child: rows.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                              SizedBox(height: 180),
                              Center(
                                  child: Text('Chưa có cuộc trò chuyện nào.'))
                            ])
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final item = rows[i];
                            final unread =
                                (item['unread_count'] as num?)?.toInt() ??
                                    int.tryParse('${item['unread_count']}') ??
                                    0;
                            return LiquidGlassCard(
                                radius: 18,
                                padding: const EdgeInsets.all(14),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => ConversationScreen(
                                              api: widget.api,
                                              conversation: item)));
                                  if (mounted) _refresh();
                                },
                                child: Row(children: [
                                  CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          AppColors.teal.withValues(alpha: .14),
                                      child: const Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.teal)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            '${item['provider_name'] ?? item['other_participant_name'] ?? 'Cơ sở PawCare'}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 3),
                                        Text(
                                            '${item['last_message'] ?? 'Bắt đầu trao đổi về lịch hẹn'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(
                                            AppFormatters.relativeTime(
                                                item['last_message_at'] ??
                                                    item['created_at']),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey))
                                      ])),
                                  if (unread > 0)
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: const BoxDecoration(
                                            color: AppColors.coral,
                                            shape: BoxShape.circle),
                                        child: Text('$unread',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800))),
                                ]));
                          }));
            }),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.retry});
  final String text;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 44),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
        TextButton(onPressed: retry, child: const Text('Thử lại'))
      ]));
}
