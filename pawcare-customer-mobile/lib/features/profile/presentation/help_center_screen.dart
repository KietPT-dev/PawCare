import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          'Trung tâm trợ giúp',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
      ),
      body: LiquidAmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            LiquidGlassCard(
              radius: 26,
              padding: const EdgeInsets.all(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withValues(alpha: isDark ? .28 : .14),
                  AppColors.cyan.withValues(alpha: isDark ? .12 : .06),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.support_agent_rounded,
                        color: AppColors.teal, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'PawCare luôn sẵn sàng hỗ trợ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tìm nhanh giải đáp cho các câu hỏi thường gặp hoặc gửi yêu cầu trợ giúp.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const SectionTitle('Câu hỏi thường gặp'),
            LiquidGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: const [
                  _Faq(
                    'Làm sao để tạo lịch hẹn?',
                    'Tại trang Khám phá, chọn đối tác và dịch vụ. Sau đó chọn thú cưng, ngày giờ phù hợp rồi gửi yêu cầu đặt lịch.',
                  ),
                  Divider(height: 1),
                  _Faq(
                    'Tôi có thể đổi hoặc hủy lịch không?',
                    'Mở Đơn lịch, chọn lịch hẹn cần xử lý. Bạn có thể hủy lịch khi lịch vẫn đang chờ xác nhận.',
                  ),
                  Divider(height: 1),
                  _Faq(
                    'Khi nào Provider xác nhận đơn?',
                    'Provider sẽ nhận yêu cầu và cập nhật trạng thái. Khi có thay đổi, lịch hẹn hiển thị trạng thái mới trong Đơn lịch.',
                  ),
                  Divider(height: 1),
                  _Faq(
                    'Thanh toán VietQR và Escrow hoạt động thế nào?',
                    'Bạn quét VietQR để thanh toán. Tiền được giữ an toàn trong Escrow và chỉ giải ngân khi dịch vụ hoàn tất hoặc hoàn lại theo kết quả xử lý.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const SectionTitle('Vẫn cần hỗ trợ?'),
            LiquidGlassCard(
              radius: 20,
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mail_outline_rounded,
                      color: AppColors.teal, size: 20),
                ),
                title: Text(
                  'Gửi yêu cầu hỗ trợ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: onSurface,
                  ),
                ),
                subtitle: const Text(
                  'Đội ngũ PawCare phản hồi trong vòng 24 giờ',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Đội ngũ hỗ trợ đã ghi nhận yêu cầu của bạn.'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: onSurface,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: [
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
