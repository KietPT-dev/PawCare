import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/ui.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen(
      {super.key, required this.api, required this.bookingId});
  final PawCareApi api;
  final int bookingId;
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Future<Map<String, dynamic>?> _booking;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _booking = _load();
  Future<Map<String, dynamic>?> _load() async {
    final bookings = await widget.api.list('/bookings');
    for (final booking in bookings) {
      if ('${booking['id']}' == '${widget.bookingId}') return booking;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
      body: FutureBuilder<Map<String, dynamic>?>(
          future: _booking,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || snapshot.data == null)
              return Center(
                  child: FilledButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Tải lại')));
            final b = snapshot.data!;
            return RefreshIndicator(
                onRefresh: () async {
                  setState(_reload);
                  await _booking;
                },
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  InfoCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.calendar_month_outlined),
                              BookingStatusChip('${b['status']}')
                            ]),
                        const SizedBox(height: 16),
                        Text('${b['service_name'] ?? 'Dịch vụ'}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(AppFormatters.dateTime(b['booking_start'])),
                        Text('Provider: ${b['provider_name'] ?? 'PawCare'}'),
                        const Divider(height: 28),
                        Text(AppFormatters.money(b['estimated_price']),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                        if ('${b['customer_note'] ?? ''}'.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text('Ghi chú: ${b['customer_note']}')),
                        if ('${b['provider_note'] ?? ''}'.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                  'Ghi chú từ tiệm: ${b['provider_note']}'))
                      ]))
                ]));
          }));
}
