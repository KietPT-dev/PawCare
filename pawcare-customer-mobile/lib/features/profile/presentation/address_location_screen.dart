import 'package:flutter/material.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class AddressLocationScreen extends StatefulWidget {
  const AddressLocationScreen(
      {super.key,
      required this.api,
      required this.profile,
      required this.onUpdated});
  final PawCareApi api;
  final Map<String, dynamic> profile;
  final ValueChanged<Map<String, dynamic>> onUpdated;
  @override
  State<AddressLocationScreen> createState() => _AddressLocationScreenState();
}

class _AddressLocationScreenState extends State<AddressLocationScreen> {
  late final TextEditingController line1, ward, district, province;
  late Map<String, dynamic> profile;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    profile = widget.profile;
    line1 = TextEditingController(text: '${profile['addressLine1'] ?? ''}');
    ward = TextEditingController(text: '${profile['ward'] ?? ''}');
    district = TextEditingController(text: '${profile['district'] ?? ''}');
    province = TextEditingController(text: '${profile['province'] ?? ''}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    line1.dispose();
    ward.dispose();
    district.dispose();
    province.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final raw = await widget.api.get('/auth/me');
      if (mounted) {
        final fresh = Map<String, dynamic>.from(raw as Map);
        setState(() => profile = fresh);
        line1.text = '${fresh['addressLine1'] ?? ''}';
        ward.text = '${fresh['ward'] ?? ''}';
        district.text = '${fresh['district'] ?? ''}';
        province.text = '${fresh['province'] ?? ''}';
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiMessages.friendly(e))));
    }
  }

  Future<void> _save() async {
    if (line1.text.trim().isEmpty || province.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Cần nhập tối thiểu địa chỉ chi tiết và Tỉnh/Thành phố.')));
      return;
    }
    setState(() => saving = true);
    try {
      final raw = await widget.api.put('/auth/me', {
        'addressLine1': line1.text.trim(),
        'ward': ward.text.trim(),
        'district': district.text.trim(),
        'province': province.text.trim()
      });
      final updated = Map<String, dynamic>.from(raw as Map);
      if (mounted) {
        widget.onUpdated(updated);
        setState(() => profile = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã lưu địa chỉ. PawCare đang xác định vị trí.')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiMessages.friendly(e))));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _status() {
    switch ('${profile['geocodeStatus'] ?? ''}') {
      case 'PENDING':
        return 'Đang xác định vị trí từ địa chỉ của bạn…';
      case 'RESOLVED':
        return 'Vị trí đã sẵn sàng — bạn có thể dùng Gần tôi.';
      case 'NOT_CONFIGURED':
        return 'Dịch vụ bản đồ chưa được cấu hình.';
      case 'NOT_FOUND':
        return 'Không tìm thấy địa chỉ; hãy nhập cụ thể hơn.';
      case 'FAILED':
        return 'Chưa thể xác định vị trí, vui lòng thử lại sau.';
      default:
        return 'Chưa thiết lập địa chỉ.';
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Địa chỉ & vị trí')),
      body: LiquidAmbientBackground(
          child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    LiquidGlassCard(
                        radius: 22,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'PawCare dùng địa chỉ này để tìm cơ sở gần bạn.'),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: line1,
                                  decoration: const InputDecoration(
                                      labelText: 'Địa chỉ chi tiết *')),
                              TextField(
                                  controller: ward,
                                  decoration: const InputDecoration(
                                      labelText: 'Phường/Xã')),
                              TextField(
                                  controller: district,
                                  decoration: const InputDecoration(
                                      labelText: 'Quận/Huyện')),
                              TextField(
                                  controller: province,
                                  decoration: const InputDecoration(
                                      labelText: 'Tỉnh/Thành phố *')),
                              const SizedBox(height: 16),
                              Row(children: [
                                const Icon(Icons.location_on_outlined,
                                    color: AppColors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_status(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600))),
                                IconButton(
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh_rounded),
                                    tooltip: 'Kiểm tra lại')
                              ]),
                              const SizedBox(height: 16),
                              FilledButton(
                                  onPressed: saving ? null : _save,
                                  child: Text(
                                      saving ? 'Đang lưu…' : 'Lưu địa chỉ'))
                            ]))
                  ]))));
}
