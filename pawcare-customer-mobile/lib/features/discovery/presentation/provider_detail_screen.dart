import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
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
  late Future<List<dynamic>> _data;
  int get _providerId => int.tryParse(widget.provider['id'] ?? '') ?? 0;
  @override
  void initState() {
    super.initState();
    _data = Future.wait([
      widget.api.list('/services?providerId=$_providerId'),
      widget.api.list('/reviews?providerId=$_providerId')
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: FutureBuilder<List<dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            final services = snapshot.hasData
                ? snapshot.data![0] as List<Map<String, dynamic>>
                : <Map<String, dynamic>>[];
            final reviews = snapshot.hasData
                ? snapshot.data![1] as List<Map<String, dynamic>>
                : <Map<String, dynamic>>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(28)),
                            child: const Icon(Icons.storefront_outlined,
                                color: AppColors.teal, size: 52))),
                    const SizedBox(height: 16),
                    Text(
                        widget.provider['name']?.isNotEmpty == true
                            ? widget.provider['name']!
                            : 'Đối tác PawCare',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                    Text(widget.provider['service_area']?.isNotEmpty == true
                        ? widget.provider['service_area']!
                        : (widget.provider['address'] ??
                            'Đang cập nhật khu vực')),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(
                          ' ${widget.provider['average_rating']?.isNotEmpty == true ? widget.provider['average_rating'] : 'Mới'} · ${reviews.length} đánh giá')
                    ]),
                    const SectionTitle('Giới thiệu'),
                    Text(widget.provider['description']?.isNotEmpty == true
                        ? widget.provider['description']!
                        : 'Đối tác chăm sóc thú cưng thuộc hệ thống PawCare.'),
                    const SectionTitle('Dịch vụ'),
                    if (snapshot.connectionState != ConnectionState.done)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator())),
                    if (snapshot.hasError) Text(snapshot.error.toString()),
                    if (snapshot.hasData && services.isEmpty)
                      const InfoCard(
                          child: Text('Provider chưa có dịch vụ khả dụng.')),
                    ...services.map((service) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InfoCard(
                            child: Row(children: [
                          const Icon(Icons.pets, color: AppColors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('${service['name']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                Text(
                                    '${service['duration_minutes']} phút · ${service['price']}đ')
                              ])),
                        ])))),
                    const SectionTitle('Đánh giá'),
                    if (reviews.isEmpty && snapshot.hasData)
                      const InfoCard(child: Text('Chưa có đánh giá nào.')),
                    ...reviews.take(3).map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InfoCard(
                            child: Text(
                                '⭐ ${review['rating']} · ${review['comment'] ?? 'Không có nhận xét'}')))),
                    const SizedBox(height: 22),
                    SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.coral),
                          onPressed: services.isEmpty
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => BookingScreen(
                                          api: widget.api,
                                          providerId: _providerId,
                                          providerName:
                                              widget.provider['name'] ??
                                                  'Đối tác PawCare'))),
                          child: const Text('Đặt lịch ngay'),
                        )),
                  ]),
            );
          },
        ),
      );
}
