import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../../discovery/presentation/discovery_screen.dart';
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ──
          Row(children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.cyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: .24),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.mint,
                child: Icon(Icons.pets_rounded, color: AppColors.teal, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('Xin chào',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Text('👋', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(_firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: onSurface)),
                ],
              ),
            ),
            GlassIconButton(
              icon: const Icon(Icons.edit_note_rounded,
                  color: AppColors.teal, size: 22),
              tooltip: 'Ghi chú nhanh',
              onPressed: _openCareNotes,
            ),
            const SizedBox(width: 8),
            GlassIconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              tooltip: 'Thông báo',
              badge: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      width: 1.5),
                ),
              ),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => _Notifications(api: widget.api),
              ),
            ),
          ]),

          const SizedBox(height: 18),

          // ── Hero Liquid Glass Banner ──
          LiquidGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teal.withValues(alpha: isDark ? .28 : .15),
                AppColors.cyan.withValues(alpha: isDark ? .12 : .06),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.teal.withValues(alpha: .28)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 13, color: AppColors.teal),
                          SizedBox(width: 4),
                          Text('PawCare Care+',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal)),
                        ],
                      ),
                    ),
                    const Icon(Icons.favorite_rounded,
                        size: 18, color: AppColors.coral),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Chăm sóc bé yêu trọn vẹn 🐾',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: onSurface)),
                const SizedBox(height: 6),
                Text(
                  'Đặt lịch spa, làm đẹp hoặc phòng khám thú y uy tín chỉ trong vài thao tác.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.38,
                      color: isDark
                          ? const Color(0xFFC6DFE5)
                          : const Color(0xFF466571)),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DiscoveryScreen(api: widget.api)),
                  ),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Khám phá dịch vụ'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 42),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Thanh tìm kiếm Liquid Glass ──
          LiquidGlassCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: TextField(
              readOnly: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _SearchPage())),
              decoration: InputDecoration(
                hintText: 'Tìm dịch vụ, đối tác, khu vực...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.teal, size: 22),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      size: 18, color: AppColors.teal),
                ),
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Lối tắt dịch vụ (Categories) theo quy ước J8 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ServiceCategoryItem(
                icon: Icons.bathtub_outlined,
                label: 'Tắm & Spa',
                color: AppColors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DiscoveryScreen(api: widget.api)),
                ),
              ),
              _ServiceCategoryItem(
                icon: Icons.content_cut_outlined,
                label: 'Cắt tỉa lông',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DiscoveryScreen(api: widget.api)),
                ),
              ),
              _ServiceCategoryItem(
                icon: Icons.medical_services_outlined,
                label: 'Khám thú y',
                color: AppColors.coral,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DiscoveryScreen(api: widget.api)),
                ),
              ),
              _ServiceCategoryItem(
                icon: Icons.hotel_outlined,
                label: 'Khách sạn',
                color: const Color(0xFFD97706),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DiscoveryScreen(api: widget.api)),
                ),
              ),
            ],
          ),

          // ── Việc cần làm ──
          const SectionTitle('Việc cần làm'),
          Row(children: [
            Expanded(
              child: InfoCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PetsScreen(api: widget.api)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pets,
                          color: AppColors.coral, size: 20),
                    ),
                    const SizedBox(height: 12),
                    const Text('Hồ sơ thú cưng',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Xem, thêm và cập nhật',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF9CBAC3)
                                : const Color(0xFF6B8791))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: AppColors.teal, size: 20),
                    ),
                    const SizedBox(height: 12),
                    const Text('Lịch hẹn tới',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Thứ Bảy, 09:00',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF9CBAC3)
                                : const Color(0xFF6B8791))),
                  ],
                ),
              ),
            ),
          ]),

          // ── Gợi ý cho bạn ──
          SectionTitle(
            'Gợi ý cho bạn',
            action: 'Xem tất cả',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DiscoveryScreen(api: widget.api)),
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _providers,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()));
              }
              final providers = snapshot.data ?? [];
              if (providers.isEmpty) {
                return const InfoCard(
                    child: Text('Chưa có đối tác phù hợp. Hãy quay lại sau.'));
              }
              return SizedBox(
                height: 224,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return SizedBox(
                      width: 280,
                      child: InfoCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderDetailScreen(
                              api: widget.api,
                              provider: provider.map((key, value) => MapEntry(
                                  key, value?.toString() ?? '')),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      AppColors.teal.withValues(alpha: .14),
                                  child: const Icon(
                                      Icons.storefront_rounded,
                                      color: AppColors.teal,
                                      size: 24),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFFF4B740).withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFF4B740), size: 16),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${provider['average_rating'] ?? 'Mới'}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '${provider['name'] ?? 'Đối tác PawCare'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: isDark
                                        ? const Color(0xFF9CBAC3)
                                        : const Color(0xFF6B8791)),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    '${provider['service_area'] ?? provider['address'] ?? 'Đang cập nhật khu vực'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? const Color(0xFF9CBAC3)
                                            : const Color(0xFF6B8791)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, children: [
                              _MiniChip(label: 'Grooming'),
                              _MiniChip(label: 'Spa'),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // ── Chăm sóc hôm nay ──
          const SectionTitle('Chăm sóc hôm nay'),
          InfoCard(
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ghi chú chăm sóc',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Lưu lại điều bé cần được quan tâm',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openCareNotes,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.teal.withValues(alpha: .12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _careNotes.isEmpty ? 'Ghi chú' : '${_careNotes.length} ghi chú',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                      fontSize: 13),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ServiceCategoryItem extends StatelessWidget {
  const _ServiceCategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            LiquidGlassCard(
              radius: 18,
              padding: const EdgeInsets.all(14),
              blur: 16,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFC6DFE5) : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini chip tag for provider cards ──
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.teal)),
      );
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
