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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thú cưng của tôi')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showForm(context),
            label: const Text('Thêm thú cưng'),
            icon: const Icon(Icons.add)),
        body: FutureBuilder<List<Map<String, dynamic>>>(
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: pets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _PetCard(
                      pet: pets[index],
                      onEdit: () => _showForm(context, pet: pets[index]),
                      onDelete: () => _delete(pets[index]))),
            );
          },
        ),
      );

  Future<void> _delete(Map<String, dynamic> pet) async {
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Xóa ${pet['name']}?'),
              content: const Text(
                  'Hồ sơ thú cưng sẽ được lưu trữ và không còn hiện trong danh sách.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Quay lại')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xóa')),
              ],
            ));
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
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text(error.toString())));
                  }
                } finally {
                  if (sheetContext.mounted) setSheetState(() => saving = false);
                }
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24,
                    24 + MediaQuery.of(sheetContext).viewInsets.bottom),
                child: Form(
                  key: form,
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(pet == null ? 'Thêm thú cưng' : 'Cập nhật thú cưng',
                          style: Theme.of(sheetContext).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: name,
                          decoration:
                              const InputDecoration(labelText: 'Tên thú cưng'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Nhập tên thú cưng'
                                  : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: species,
                          decoration: const InputDecoration(
                              labelText: 'Loài (chó, mèo,...)'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Nhập loài thú cưng'
                                  : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: breed,
                          decoration: const InputDecoration(
                              labelText: 'Giống (không bắt buộc)')),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: notes,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: 'Ghi chú sức khỏe')),
                      const SizedBox(height: 18),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: saving ? null : save,
                              child:
                                  Text(saving ? 'Đang lưu...' : 'Lưu hồ sơ'))),
                    ]),
                  ),
                ),
              );
            }));
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
    return InfoCard(
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 42)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${pet['name']}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text([pet['species'], pet['breed']]
              .where((value) => value != null && value.toString().isNotEmpty)
              .join(' · ')),
          if ((pet['medical_notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text('${pet['medical_notes']}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ])
      ]),
    );
  }
}

class _EmptyPets extends StatelessWidget {
  const _EmptyPets();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.pets_outlined, size: 54, color: AppColors.teal),
            SizedBox(height: 14),
            Text('Bạn chưa thêm thú cưng nào.', textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: retry, child: const Text('Thử lại')),
          ]),
        ),
      );
}
