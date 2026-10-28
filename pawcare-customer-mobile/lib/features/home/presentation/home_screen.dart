import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../../discovery/presentation/provider_detail_screen.dart';
import '../../pets/presentation/pets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile, required this.api});
  final Map<String, dynamic> profile;
  final PawCareApi api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _providers;
  final List<_CareNote> _careNotes = [];

  @override
  void initState() {
    super.initState();
    _providers = widget.api.list('/providers');
    _loadCareNotes();
  }

  Future<void> _loadCareNotes() async {
    try {
      final rows = await widget.api.listCareNotes();
      if (!mounted) return;
      setState(() {
        _careNotes
          ..clear()
          ..addAll(rows.map(_CareNote.fromMap));
      });
    } catch (_) {
      // The notes sheet exposes a retryable error when the user opens it.
      // The dashboard remains usable when the API is temporarily offline.
    }
  }

  String get _firstName {
    final name =
        (widget.profile['fullName'] ?? widget.profile['full_name'] ?? '')
            .toString()
            .trim();
    if (name.isEmpty) return 'bạn';
    return name.split(RegExp(r'\s+')).last;
  }

  void _openCareNotes() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _CareNotesSheet(
        notes: _careNotes,
        onAdd: (title, content) async {
          final id =
              await widget.api.createCareNote(title: title, content: content);
          if (!mounted) return;
          setState(() => _careNotes.insert(
              0,
              _CareNote(
                  id: id,
                  title: title,
                  content: content,
                  createdAt: DateTime.now())));
        },
        onDelete: (note) async {
          await widget.api.deleteCareNote(note.id);
          if (!mounted) return;
          setState(() => _careNotes.remove(note));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(17)),
                  child: const Icon(Icons.pets_rounded,
                      color: AppColors.teal, size: 27)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Chào $_firstName',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    const Text('Hôm nay bé Mây thế nào?')
                  ])),
              IconButton(
                  onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => _Notifications(api: widget.api)),
                  icon: const Icon(Icons.notifications_outlined)),
            ]),
            const SizedBox(height: 20),
            TextField(
                readOnly: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _SearchPage())),
                decoration: const InputDecoration(
                    hintText: 'Tìm dịch vụ, đối tác...',
                    prefixIcon: Icon(Icons.search))),
            const SectionTitle('Việc cần làm'),
            Row(children: [
              Expanded(
                  child: InfoCard(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PetsScreen(api: widget.api))),
                      child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.pets, color: AppColors.coral),
                            SizedBox(height: 10),
                            Text('Hồ sơ thú cưng',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            Text('Xem, thêm và cập nhật')
                          ]))),
              const SizedBox(width: 12),
              Expanded(
                  child: InfoCard(
                      child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Icon(Icons.calendar_today, color: AppColors.teal),
                    SizedBox(height: 10),
                    Text('Lịch hẹn tới',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('Thứ Bảy, 09:00')
                  ]))),
            ]),
            const SectionTitle('Gợi ý cho bạn'),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: _providers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                        height: 170,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final providers = snapshot.data ?? [];
                  if (providers.isEmpty) {
                    return const InfoCard(
                        child:
                            Text('Chưa có đối tác phù hợp. Hãy quay lại sau.'));
                  }
                  return SizedBox(
                      height: 188,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: providers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final provider = providers[index];
                            return SizedBox(
                                width: 262,
                                child: InfoCard(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ProviderDetailScreen(
                                                    api: widget.api,
                                                    provider: provider.map((key,
                                                            value) =>
                                                        MapEntry(
                                                            key,
                                                            value?.toString() ??
                                                                ''))))),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  color: AppColors.mint,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          13)),
                                              child: const Icon(
                                                  Icons.storefront_outlined,
                                                  color: AppColors.teal)),
                                          const Spacer(),
                                          Text(
                                              '${provider['name'] ?? 'Đối tác PawCare'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16)),
                                          const SizedBox(height: 3),
                                          Text(
                                              '${provider['service_area'] ?? provider['address'] ?? 'Đang cập nhật khu vực'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            const Icon(Icons.star_rounded,
                                                color: Color(0xFFF4B740),
                                                size: 18),
                                            Text(
                                                ' ${provider['average_rating'] ?? 'Mới'}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800))
                                          ]),
                                        ])));
                          }));
                }),
            const SectionTitle('Chăm sóc hôm nay'),
            InfoCard(
                child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.lightbulb_outline,
                      color: AppColors.teal)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Ghi chú chăm sóc',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('Lưu lại điều bé cần được quan tâm')
                  ])),
              TextButton(
                  onPressed: _openCareNotes,
                  child: Text(_careNotes.isEmpty
                      ? 'Ghi chú'
                      : '${_careNotes.length} ghi chú'))
            ])),
          ])));
}

class _CareNote {
  const _CareNote(
      {required this.id,
      required this.title,
      required this.content,
      required this.createdAt});
  factory _CareNote.fromMap(Map<String, dynamic> row) => _CareNote(
      id: int.parse('${row['id']}'),
      title: '${row['title'] ?? ''}',
      content: '${row['content'] ?? ''}',
      createdAt:
          DateTime.tryParse('${row['created_at'] ?? ''}') ?? DateTime.now());
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
}

class _CareNotesSheet extends StatefulWidget {
  const _CareNotesSheet({
    required this.notes,
    required this.onAdd,
    required this.onDelete,
  });

  final List<_CareNote> notes;
  final Future<void> Function(String title, String content) onAdd;
  final Future<void> Function(_CareNote note) onDelete;

  @override
  State<_CareNotesSheet> createState() => _CareNotesSheetState();
}

class _CareNotesSheetState extends State<_CareNotesSheet> {
  // These controllers must live for the lifetime of the sheet. Disposing
  // controllers immediately after Navigator.pop can race the dialog's exit
  // animation and causes Flutter's `dependents.isEmpty` assertion.
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _addNote() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ghi chú chăm sóc'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'Tiêu đề, ví dụ: Uống thuốc')),
          const SizedBox(height: 12),
          TextField(
              controller: _contentController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Điều cần lưu ý cho bé…')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Lưu ghi chú')),
        ],
      ),
    );
    if (!mounted || created != true) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Hãy nhập tiêu đề ghi chú.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onAdd(title, content);
      if (!mounted) return;
      _titleController.clear();
      _contentController.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteNote(_CareNote note) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onDelete(note);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .62,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('Ghi chú chăm sóc',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800))),
                IconButton(
                    onPressed: _addNote,
                    tooltip: 'Thêm ghi chú',
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.teal)),
              ]),
              Text('Lưu ý nhanh cho thú cưng của bạn.',
                  style: Theme.of(context).textTheme.bodyMedium),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: widget.notes.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lightbulb_outline,
                              color: AppColors.teal, size: 42),
                          const SizedBox(height: 10),
                          Text('Chưa có ghi chú nào.',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          const Text('Nhấn dấu + để thêm điều cần quan tâm.'),
                        ]),
                      )
                    : ListView.separated(
                        itemCount: widget.notes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, index) {
                          final note = widget.notes[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.lightbulb_outline,
                                color: AppColors.teal),
                            title: Text(note.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            subtitle: Text(note.content.isEmpty
                                ? 'Vừa thêm'
                                : note.content),
                            trailing: IconButton(
                                tooltip: 'Xóa ghi chú',
                                onPressed:
                                    _saving ? null : () => _deleteNote(note),
                                icon: const Icon(Icons.delete_outline)),
                          );
                        }),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                  onPressed: _saving ? null : _addNote,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm ghi chú')),
            ]),
          ),
        ),
      );
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const TextField(
                autofocus: true,
                decoration: InputDecoration(
                    hintText: 'Nhập tên dịch vụ hoặc khu vực',
                    prefixIcon: Icon(Icons.search))),
            const SizedBox(height: 20),
            Wrap(
                spacing: 8,
                children: ['Gần tôi', 'Grooming', 'Khám bệnh', 'Pet Hotel']
                    .map((item) => FilterChip(
                        label: Text(item), onSelected: (_) {}, selected: false))
                    .toList())
          ])));
}

class _Notifications extends StatefulWidget {
  const _Notifications({required this.api});
  final PawCareApi api;
  @override
  State<_Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<_Notifications> {
  late Future<List<Map<String, dynamic>>> notifications;
  @override
  void initState() {
    super.initState();
    notifications = widget.api.list('/notifications');
  }

  void reload() =>
      setState(() => notifications = widget.api.list('/notifications'));
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
          future: notifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()));
            if (snapshot.hasError)
              return SizedBox(
                  height: 240,
                  child: Center(
                      child: Text(snapshot.error.toString(),
                          textAlign: TextAlign.center)));
            final rows = snapshot.data ?? [];
            return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông báo',
                          style: Theme.of(context).textTheme.titleLarge),
                      if (rows.isEmpty)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Bạn chưa có thông báo nào.')),
                      ...rows.map((item) => ListTile(
                          leading: Icon(
                              item['is_read'] == true || item['is_read'] == 1
                                  ? Icons.notifications_none
                                  : Icons.notifications,
                              color: AppColors.teal),
                          title:
                              Text('${item['title'] ?? 'Thông báo PawCare'}'),
                          subtitle: Text(
                              '${item['content'] ?? item['message'] ?? ''}'),
                          trailing:
                              item['is_read'] == true || item['is_read'] == 1
                                  ? null
                                  : const Icon(Icons.circle,
                                      size: 10, color: AppColors.coral),
                          onTap: () async {
                            try {
                              await widget.api
                                  .put('/notifications/${item['id']}/read', {});
                              reload();
                            } catch (_) {}
                          })),
                    ]));
          });
}
