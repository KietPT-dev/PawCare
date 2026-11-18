import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
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
          'Chi tiết lịch hẹn',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
      ),
      body: LiquidAmbientBackground(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _booking,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.coral),
                    const SizedBox(height: 12),
                    const Text('Không tìm thấy thông tin lịch hẹn.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              );
            }
            final b = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(_reload);
                await _booking;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  LiquidGlassCard(
                    radius: 24,
                    padding: const EdgeInsets.all(20),
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
                                color: AppColors.teal.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '#${b['id'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                            BookingStatusChip('${b['status']}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${b['service_name'] ?? 'Dịch vụ'}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 16, color: AppColors.teal),
                            const SizedBox(width: 6),
                            Text(
                              AppFormatters.dateTime(b['booking_start']),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded,
                                size: 16, color: AppColors.cyan),
                            const SizedBox(width: 6),
                            Text(
                              'Provider: ${b['provider_name'] ?? 'PawCare'}',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng chi phí:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              AppFormatters.money(b['estimated_price']),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                        if ('${b['customer_note'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155).withValues(alpha: .5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.notes_rounded,
                                    size: 16, color: AppColors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ghi chú của bạn: ${b['customer_note']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if ('${b['provider_note'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.store_rounded,
                                    size: 16, color: AppColors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lời nhắn từ tiệm: ${b['provider_note']}',
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.navy),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
