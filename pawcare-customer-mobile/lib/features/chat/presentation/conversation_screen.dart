import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen(
      {super.key, required this.api, required this.conversation});
  final PawCareApi api;
  final Map<String, dynamic> conversation;
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _pending = <Map<String, dynamic>>[];
  Timer? _poll;
  late Future<List<Map<String, dynamic>>> _messages;
  bool _sending = false;
  int? _meId;
  int get _id => int.tryParse('${widget.conversation['id']}') ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    _startPolling();
    widget.api.get('/auth/me').then((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      if (mounted)
        setState(
            () => _meId = int.tryParse('${map['id'] ?? map['profileId']}'));
    }).catchError((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      _startPolling();
    else
      _poll?.cancel();
  }

  void _reload() =>
      _messages = widget.api.list('/conversations/$_id/messages?size=50');
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _refresh(silent: true);
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(_reload);
    try {
      final fresh =
          await widget.api.list('/conversations/$_id/messages?size=50');
      if (!mounted) return;
      setState(() => _messages = Future.value(fresh));
      await widget.api.post('/conversations/$_id/read', {});
    } catch (_) {}
  }

  Future<void> _send([Map<String, dynamic>? retry]) async {
    final content = '${retry?['content'] ?? _text.text}'.trim();
    if (content.isEmpty || _sending) return;
    final row = retry ??
        {
          'clientMessageId':
              '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}',
          'content': content,
          'sender_profile_id': _meId,
        };
    if (retry == null) {
      _text.clear();
      setState(() => _pending.add(row));
    }
    setState(() {
      _sending = true;
      row['sending'] = true;
      row['failed'] = false;
    });
    try {
      await widget.api.post('/conversations/$_id/messages',
          {'content': content, 'clientMessageId': row['clientMessageId']});
      if (!mounted) return;
      setState(() => _pending.remove(row));
      await _refresh(silent: true);
    } catch (_) {
      if (mounted)
        setState(() {
          row['sending'] = false;
          row['failed'] = true;
        });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        '${widget.conversation['provider_name'] ?? widget.conversation['other_participant_name'] ?? 'Cơ sở PawCare'}';
    return Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Column(children: [
          Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _messages,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return Center(
                          child: TextButton(
                              onPressed: _refresh,
                              child:
                                  Text(ApiMessages.friendly(snapshot.error))));
                    final rows = [...(snapshot.data ?? []), ..._pending];
                    return RefreshIndicator(
                        onRefresh: _refresh,
                        child: rows.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                    SizedBox(height: 160),
                                    Center(
                                        child: Text(
                                            'Hãy bắt đầu trao đổi với cơ sở.'))
                                  ])
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: rows.length,
                                itemBuilder: (_, index) => _Bubble(
                                    message: rows[index],
                                    mine:
                                        '${rows[index]['sender_profile_id']}' ==
                                            '$_meId',
                                    retry: () => _send(rows[index]))));
                  })),
          SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 4,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                                hintText: 'Nhắn tin…',
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      _text.text += '😊';
                                      _text.selection = TextSelection.collapsed(
                                          offset: _text.text.length);
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                        Icons.emoji_emotions_outlined))))),
                    const SizedBox(width: 8),
                    FilledButton(
                        onPressed: _sending || _text.text.trim().isEmpty
                            ? null
                            : _send,
                        child: const Icon(Icons.send_rounded)),
                  ]))),
        ]));
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(
      {required this.message, required this.mine, required this.retry});
  final Map<String, dynamic> message;
  final bool mine;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(11),
          constraints: const BoxConstraints(maxWidth: 290),
          decoration: BoxDecoration(
              color: mine
                  ? AppColors.teal
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${message['content']}',
                style: TextStyle(color: mine ? Colors.white : null)),
            const SizedBox(height: 3),
            Text(
                message['failed'] == true
                    ? 'Không gửi được'
                    : message['sending'] == true
                        ? 'Đang gửi…'
                        : AppFormatters.relativeTime(message['sent_at']),
                style: TextStyle(
                    fontSize: 10, color: mine ? Colors.white70 : Colors.grey)),
            if (message['failed'] == true)
              TextButton(onPressed: retry, child: const Text('Gửi lại'))
          ])));
}
