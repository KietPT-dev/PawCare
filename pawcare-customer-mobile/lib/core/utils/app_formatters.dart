import 'package:flutter/material.dart';

class AppFormatters {
  const AppFormatters._();

  static String money(dynamic value) {
    final number = value is num ? value : num.tryParse('$value') ?? 0;
    final raw = number.round().abs().toString();
    final parts = <String>[];
    for (var end = raw.length; end > 0; end -= 3) {
      parts.insert(0, raw.substring(end > 3 ? end - 3 : 0, end));
    }
    return '${number < 0 ? '-' : ''}${parts.join('.')} ₫';
  }

  static String formatVnd(num? amount) => money(amount);

  static String formatBookingStatusVi(String status) => switch (status) {
        'PENDING' || 'PENDING_PAYMENT' => 'Chờ thanh toán',
        'PENDING_APPROVAL' => 'Chờ xác nhận',
        'CONFIRMED' => 'Đã xác nhận',
        'CHECKED_IN' => 'Đã tiếp nhận bé',
        'IN_SERVICE' || 'IN_PROGRESS' => 'Đang chăm sóc',
        'COMPLETED' => 'Hoàn thành',
        'CANCELLED' => 'Đã hủy',
        _ => status,
      };

  static String replaceRawStatusInNotification(String text) {
    var result = text;
    for (final value in [
      'IN_SERVICE',
      'CHECKED_IN',
      'CONFIRMED',
      'COMPLETED',
      'CANCELLED'
    ]) {
      result = result.replaceAll(value, formatBookingStatusVi(value));
    }
    return result;
  }

  static DateTime? date(dynamic value) =>
      value == null ? null : DateTime.tryParse('$value'.replaceFirst(' ', 'T'));
  static String dateTime(dynamic value) {
    final valueDate = date(value);
    if (valueDate == null) return 'Đang cập nhật';
    return '${valueDate.hour.toString().padLeft(2, '0')}:${valueDate.minute.toString().padLeft(2, '0')} • ${valueDate.day.toString().padLeft(2, '0')}/${valueDate.month.toString().padLeft(2, '0')}/${valueDate.year}';
  }

  static String relativeTime(dynamic value) {
    final time = date(value);
    if (time == null) return '';
    final gap = DateTime.now().difference(time);
    if (gap.inMinutes < 1) return 'Vừa xong';
    if (gap.inHours < 1) return '${gap.inMinutes} phút trước';
    if (gap.inDays < 1) return '${gap.inHours} giờ trước';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  static StatusVisual status(String raw) => switch (raw) {
        'PENDING_PAYMENT' => const StatusVisual(
            'Chờ thanh toán', Icons.payments_outlined, Color(0xFFB45309)),
        'PENDING_APPROVAL' || 'PENDING' => const StatusVisual(
            'Chờ tiệm duyệt', Icons.hourglass_top_outlined, Color(0xFFB45309)),
        'CONFIRMED' => const StatusVisual(
            'Đã xác nhận', Icons.check_circle_outline, Color(0xFF007A8C)),
        'CHECKED_IN' || 'IN_SERVICE' || 'IN_PROGRESS' => const StatusVisual(
            'Đang thực hiện', Icons.pets_outlined, Color(0xFF7C3AED)),
        'SERVICE_DONE' => const StatusVisual(
            'Chờ bạn xác nhận', Icons.task_alt_outlined, Color(0xFF007A8C)),
        'DISPUTED' => const StatusVisual('Đang tranh chấp',
            Icons.report_problem_outlined, Color(0xFFC2410C)),
        'COMPLETED' => const StatusVisual(
            'Hoàn thành', Icons.verified_outlined, Color(0xFF059669)),
        'REFUNDED' => const StatusVisual(
            'Đã hoàn tiền', Icons.replay_outlined, Color(0xFF7C3AED)),
        'CANCELLED' || 'REJECTED' => const StatusVisual(
            'Đã hủy', Icons.cancel_outlined, Color(0xFFDC2626)),
        _ => StatusVisual(raw.replaceAll('_', ' '), Icons.info_outline,
            const Color(0xFF64748B)),
      };
}

class StatusVisual {
  const StatusVisual(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}
