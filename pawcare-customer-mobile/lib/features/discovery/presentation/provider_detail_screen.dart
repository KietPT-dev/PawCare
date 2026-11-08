import 'package:flutter/material.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/ui.dart';
import '../../booking/presentation/booking_screen.dart';

class ProviderDetailScreen extends StatefulWidget {
  const ProviderDetailScreen(
      {super.key, required this.provider, required this.api});
  final Map<String, String> provider;
  final PawCareApi api;
  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  late Future<List<Map<String, dynamic>>> _services;
  Map<String, dynamic>? selected;
  int get id => int.tryParse(widget.provider['id'] ?? '') ?? 0;
  @override
  void initState() {
    super.initState();
    _services = widget.api.list('/services?providerId=$id');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _services,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final services = snapshot.data ?? [];
            return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  LiquidGlassCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDFA),
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Color(0xFF0D9488))),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    widget.provider['name'] ??
                                        'Đối tác PawCare',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    '📍 ${widget.provider['address'] ?? widget.provider['service_area'] ?? 'Đang cập nhật'}')
                              ]))
                        ]),
                        const Divider(height: 28),
                        const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _Metric('★ 5.0', 'Đánh giá'),
                              _Metric('100%', 'Bảo vệ Escrow')
                            ])
                      ])),
                  const SectionTitle('Dịch vụ'),
                  ...services.map(_service)
                ]);
          }),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                  height: 52,
                  child: FilledButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookingScreen(
                                  api: widget.api,
                                  providerId: id,
                                  providerName: widget.provider['name'] ??
                                      'Đối tác PawCare'))),
                      child: const Text('Đặt lịch ngay'))))));
  Widget _service(Map<String, dynamic> x) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
          onTap: () => setState(() => selected = x),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: selected == x
                          ? const Color(0xFF0D9488)
                          : const Color(0xFFE2E8F0),
                      width: selected == x ? 1.5 : 1)),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.pets_rounded,
                        color: Color(0xFF0D9488))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${x['name']}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('⏱ ${x['duration_minutes']} phút',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)))
                    ])),
                Text(AppFormatters.money(x['price']),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF0D9488)))
              ]))));
}

class _Metric extends StatelessWidget {
  const _Metric(this.a, this.b);
  final String a, b;
  @override
  Widget build(BuildContext c) => Column(children: [
        Text(a, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(b, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
      ]);
}
