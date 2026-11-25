import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/ui.dart';
import '../../booking/presentation/booking_checkout_screen.dart';
import '../../chat/presentation/conversation_screen.dart';

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

  void _showWorking(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .15),
                  blurRadius: 20,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCompletion(Map<String, dynamic> b) async {
    _showWorking('Đang xác nhận hoàn tất...');
    try {
      await widget.api.post('/bookings/${b['id']}/confirm-completion', {});
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận hoàn tất. Bạn có thể đánh giá dịch vụ.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiMessages.friendly(e))),
      );
    }
  }

  Future<void> _disputeBooking(Map<String, dynamic> b) async {
    final text = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yes = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (s) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, 24 + MediaQuery.of(s).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gửi khiếu nại',
                style: Theme.of(s).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mô tả chi tiết vấn đề bạn gặp phải để PawCare hỗ trợ xử lý tranh chấp và bảo vệ tiền Escrow.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: text,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Nội dung khiếu nại *',
                  hintText: 'Nhập lý do hoặc vấn đề của dịch vụ...',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (text.text.trim().isEmpty) {
                    ScaffoldMessenger.of(s).showSnackBar(const SnackBar(
                        content: Text('Nội dung khiếu nại là bắt buộc.')));
                    return;
                  }
                  Navigator.pop(s, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Gửi khiếu nại',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        );
      },
    );

    if (yes == true) {
      if (!mounted) return;
      _showWorking('Đang gửi khiếu nại...');
      try {
        await widget.api.post(
            '/bookings/${b['id']}/disputes', {'content': text.text.trim()});
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        setState(_reload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi khiếu nại. Tiền escrow vẫn được tạm giữ.'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiMessages.friendly(e))),
        );
      }
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lịch hẹn',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Bạn có chắc chắn muốn hủy lịch hẹn #${b['id']} (${b['service_name'] ?? 'dịch vụ'}) không?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      _showWorking('Đang hủy lịch hẹn...');
      try {
        await widget.api
            .put('/bookings/${b['id']}/status', {'status': 'CANCELLED'});
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        setState(_reload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy lịch hẹn thành công.')),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiMessages.friendly(e))),
        );
      }
    }
  }

  Future<void> _openChat(Map<String, dynamic> booking) async {
    try {
      final raw =
          await widget.api.post('/bookings/${booking['id']}/conversation', {});
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationScreen(
              api: widget.api,
              conversation: Map<String, dynamic>.from(raw as Map))));
    } catch (error) {
      if (!mounted) return;
      final message = error is PawCareApiException && error.statusCode == 409
          ? 'Chưa thể nhắn tin: cuộc trò chuyện chỉ mở khi lịch hẹn đã được thanh toán và chưa bị hủy.'
          : ApiMessages.friendly(error);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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
            final status = '${b['status'] ?? 'PENDING'}';
            final canCancel = {
              'PENDING_APPROVAL',
              'PENDING',
              'PENDING_PAYMENT',
              'CONFIRMED',
              'CHECKED_IN'
            }.contains(status);
            final canChat = {
              'PENDING_APPROVAL',
              'CONFIRMED',
              'CHECKED_IN',
              'IN_SERVICE',
              'SERVICE_DONE',
              'COMPLETED',
              'DISPUTED'
            }.contains(status);

            return RefreshIndicator(
              onRefresh: () async {
                setState(_reload);
                await _booking;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  // Thẻ thông tin chi tiết chính
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
                            BookingStatusChip(status),
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
                            Expanded(
                                child: Text(
                              'Provider: ${b['provider_name'] ?? 'PawCare'}',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            )),
                            if (canChat)
                              TextButton.icon(
                                onPressed: () => _openChat(b),
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16),
                                label: const Text('Nhắn tin'),
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
                        if ({
                          'PENDING_PAYMENT',
                          'PENDING_APPROVAL',
                          'CONFIRMED',
                          'CHECKED_IN',
                          'IN_SERVICE',
                          'SERVICE_DONE',
                          'DISPUTED',
                          'SYSTEM_REVIEW'
                        }.contains(status)) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.teal
                                  .withValues(alpha: isDark ? .16 : .08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.teal.withValues(alpha: .25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined,
                                    size: 16, color: AppColors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tiền dịch vụ đang được giữ an toàn trong PawCare Escrow.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF0F766E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if ('${b['customer_note'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                      .withValues(alpha: .5)
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

                  // Khối tác vụ cho trạng thái SERVICE_DONE (Xác nhận hoàn tất & Có vấn đề / Khiếu nại)
                  if (status == 'SERVICE_DONE') ...[
                    const SizedBox(height: 16),
                    LiquidGlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: .15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.task_alt_rounded,
                                    color: AppColors.teal, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Provider báo đã hoàn tất',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Vui lòng xác nhận dịch vụ để giải ngân hoặc gửi khiếu nại nếu có vấn đề.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: () => _confirmCompletion(b),
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 20),
                              label: const Text('Xác nhận hoàn tất',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => _disputeBooking(b),
                              icon: const Icon(Icons.report_problem_outlined,
                                  size: 18),
                              label: const Text('Có vấn đề / Khiếu nại',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.coral,
                                side: BorderSide(
                                    color:
                                        AppColors.coral.withValues(alpha: .5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Nút Thanh toán ngay nếu đang PENDING_PAYMENT
                  if (status == 'PENDING_PAYMENT') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookingCheckoutScreen(
                                api: widget.api,
                                booking: b,
                              ),
                            ),
                          );
                          setState(_reload);
                        },
                        icon: const Icon(Icons.payment_rounded, size: 20),
                        label: const Text('Thanh toán ngay',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],

                  // Nút Hủy lịch hẹn trong trang chi tiết nếu đơn có thể hủy
                  if (canCancel) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelBooking(b),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Hủy lịch hẹn',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coral,
                          side: BorderSide(
                              color: AppColors.coral.withValues(alpha: .4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
