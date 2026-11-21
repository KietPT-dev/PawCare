import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../../discovery/presentation/discovery_screen.dart';
import '../../discovery/presentation/provider_detail_screen.dart';

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
      backgroundColor: Colors.transparent,
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
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
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

          // ── Chăm sóc hôm nay ──
          const SectionTitle('Chăm sóc hôm nay'),
          LiquidGlassCard(
            radius: 20,
            padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ghi chú chăm sóc',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: onSurface)),
                    const SizedBox(height: 3),
                    Text(
                      'Lưu lại điều bé cần được quan tâm',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openCareNotes,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.teal.withValues(alpha: .12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ghi chú chăm sóc'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'Ví dụ: Uống thuốc sau ăn')),
          const SizedBox(height: 12),
          TextField(
              controller: _contentController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Điều cần lưu ý cho bé…')),
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return LiquidModalSheet(
      title: 'Ghi chú chăm sóc',
      subtitle: 'Lưu ý nhanh cho thú cưng của bạn.',
      headerAction: IconButton(
        onPressed: _addNote,
        tooltip: 'Thêm ghi chú',
        icon: const Icon(Icons.add_circle_outline, color: AppColors.teal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.coral.withValues(alpha: .3)),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: AppColors.coral,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          Expanded(
            child: widget.notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lightbulb_outline_rounded,
                              color: AppColors.teal, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text('Chưa có ghi chú nào.',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: onSurface)),
                        const SizedBox(height: 6),
                        Text(
                          'Nhấn dấu + để thêm điều cần quan tâm cho bé.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: widget.notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final note = widget.notes[index];
                      return LiquidGlassCard(
                        radius: 18,
                        padding: const EdgeInsets.all(14),
                        blur: 10,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: .12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lightbulb_rounded,
                                  color: AppColors.teal, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: onSurface),
                                  ),
                                  if (note.content.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      note.content,
                                      style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF475569)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xóa ghi chú',
                              onPressed:
                                  _saving ? null : () => _deleteNote(note),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.coral, size: 20),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _addNote,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Thêm ghi chú'),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return LiquidModalSheet(
      title: 'Thông báo',
      subtitle: 'Cập nhật lịch hẹn & dịch vụ chăm sóc',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Text(snapshot.error.toString(),
                    textAlign: TextAlign.center),
              ),
            );
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 36, color: AppColors.teal),
                  ),
                  const SizedBox(height: 12),
                  const Text('Bạn chưa có thông báo nào.',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Các cập nhật đơn và lịch hẹn sẽ hiển thị tại đây.',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = rows[index];
              final isRead = item['is_read'] == true || item['is_read'] == 1;
              return LiquidGlassCard(
                padding: const EdgeInsets.all(14),
                radius: 18,
                blur: 10,
                onTap: () async {
                  try {
                    await widget.api
                        .put('/notifications/${item['id']}/read', {});
                    reload();
                  } catch (_) {}
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isRead
                            ? (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9))
                            : AppColors.teal.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRead
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_rounded,
                        color: isRead
                            ? (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B))
                            : AppColors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['title'] ?? 'Thông báo PawCare'}',
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14.5,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item['content'] ?? item['message'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        margin: const EdgeInsets.only(top: 4, left: 6),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
