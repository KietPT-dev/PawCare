import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key, required this.api});
  final PawCareApi api;

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  late Future<List<Map<String, dynamic>>> _pets;

  @override
  void initState() {
    super.initState();
    _pets = widget.api.list('/pets');
  }

  void _reload() => setState(() => _pets = widget.api.list('/pets'));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: canPop
            ? Center(
                child: GlassIconButton(
                  size: 38,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        title: Text(
          'Thú cưng của tôi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Thêm thú cưng',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: LiquidAmbientBackground(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _pets,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _Failure(
                  message: snapshot.error.toString(), retry: _reload);
            }
            final pets = snapshot.data ?? [];
            if (pets.isEmpty) {
              return const _EmptyPets();
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                itemCount: pets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _PetCard(
                  pet: pets[index],
                  onEdit: () => _showForm(context, pet: pets[index]),
                  onDelete: () => _delete(pets[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> pet) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Xóa hồ sơ ${pet['name']}?'),
        content: const Text(
          'Hồ sơ thú cưng sẽ được lưu trữ và không còn hiện trong danh sách.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await widget.api.delete('/pets/${pet['id']}');
      _reload();
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _showForm(BuildContext context,
      {Map<String, dynamic>? pet}) async {
    final name = TextEditingController(text: pet?['name']?.toString());
    final species = TextEditingController(text: pet?['species']?.toString());
    final breed = TextEditingController(text: pet?['breed']?.toString());
    final notes =
        TextEditingController(text: pet?['medical_notes']?.toString());
    final form = GlobalKey<FormState>();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          StatefulBuilder(builder: (sheetContext, setSheetState) {
        Future<void> save() async {
          if (!form.currentState!.validate()) return;
          setSheetState(() => saving = true);
          try {
            final payload = <String, dynamic>{
              'name': name.text.trim(),
              'species': species.text.trim(),
              'breed': breed.text.trim(),
              'medicalNotes': notes.text.trim(),
            };
            if (pet == null) {
              await widget.api.post('/pets', payload);
            } else {
              await widget.api.put('/pets/${pet['id']}', payload);
            }
            if (!sheetContext.mounted) return;
            Navigator.pop(sheetContext);
            _reload();
          } catch (error) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext)
                  .showSnackBar(SnackBar(content: Text(error.toString())));
            }
          } finally {
            if (sheetContext.mounted) setSheetState(() => saving = false);
          }
        }

        return LiquidModalSheet(
          title: pet == null ? 'Thêm thú cưng' : 'Cập nhật thú cưng',
          subtitle: 'Lưu thông tin để thuận tiện khi đặt dịch vụ và chăm sóc',
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tên thú cưng',
                      hintText: 'Ví dụ: Bé Mây, LuLu...',
                      prefixIcon: Icon(Icons.pets_rounded, color: AppColors.teal),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Nhập tên thú cưng'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: species,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Loài',
                      hintText: 'Ví dụ: Chó, Mèo, Hamster...',
                      prefixIcon: Icon(Icons.category_outlined,
                          color: AppColors.teal),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Nhập loài thú cưng'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: breed,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Giống (không bắt buộc)',
                      hintText: 'Ví dụ: Corgi, Poodle, Mèo Anh lông ngắn...',
                      prefixIcon: Icon(Icons.badge_outlined,
                          color: AppColors.teal),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú sức khỏe & dị ứng',
                      hintText: 'Ví dụ: Dị ứng thức ăn có gà, đã tiêm ngừa dại...',
                      prefixIcon: Icon(Icons.medical_services_outlined,
                          color: AppColors.teal),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? 'Đang lưu...' : 'Lưu hồ sơ bé'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
    name.dispose();
    species.dispose();
    breed.dispose();
    notes.dispose();
  }

  void _message(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _PetCard extends StatelessWidget {
  const _PetCard(
      {required this.pet, required this.onEdit, required this.onDelete});
  final Map<String, dynamic> pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final species = (pet['species'] ?? '').toString().toLowerCase();
    final emoji =
        species.contains('mèo') || species.contains('cat') ? '🐱' : '🐶';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return LiquidGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      blur: 14,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withValues(alpha: isDark ? .30 : .16),
                  AppColors.cyan.withValues(alpha: isDark ? .18 : .08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: .28),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet['name'] ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [pet['species'], pet['breed']]
                      .where((v) => v != null && v.toString().trim().isNotEmpty)
                      .join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                if ((pet['medical_notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.coral.withValues(alpha: .24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 12, color: AppColors.coral),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${pet['medical_notes']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.teal),
                    SizedBox(width: 10),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.coral),
                    SizedBox(width: 10),
                    Text('Xóa', style: TextStyle(color: AppColors.coral)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPets extends StatelessWidget {
  const _EmptyPets();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded,
                  size: 48, color: AppColors.teal),
            ),
            const SizedBox(height: 18),
            Text(
              'Chưa có hồ sơ thú cưng nào.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nhấn nút + bên dưới để tạo hồ sơ cho bé yêu của bạn!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.coral),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: retry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
