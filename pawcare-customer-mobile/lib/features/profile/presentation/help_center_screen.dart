import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Trung tâm trợ giúp')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.teal]),
                borderRadius: BorderRadius.circular(24)),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent, color: Colors.white, size: 34),
                  SizedBox(height: 12),
                  Text('PawCare luôn sẵn sàng hỗ trợ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Tìm nhanh câu trả lời cho những vấn đề thường gặp.',
                      style: TextStyle(color: Colors.white70)),
                ]),
          ),
          const SectionTitle('Câu hỏi thường gặp'),
          InfoCard(
              child: Column(children: const [
            _Faq('Làm sao để tạo lịch hẹn?',
                'Tại trang Khám phá, chọn đối tác và dịch vụ. Sau đó chọn thú cưng, ngày giờ phù hợp rồi gửi yêu cầu đặt lịch.'),
            Divider(),
            _Faq('Tôi có thể đổi hoặc hủy lịch không?',
                'Mở Đơn lịch, chọn lịch hẹn cần xử lý. Bạn có thể hủy lịch khi lịch vẫn đang chờ xác nhận.'),
            Divider(),
            _Faq('Khi nào Provider xác nhận đơn?',
                'Provider sẽ nhận yêu cầu và cập nhật trạng thái. Khi có thay đổi, lịch hẹn hiển thị trạng thái mới trong Đơn lịch.'),
            Divider(),
            _Faq('Thanh toán VNPAY Sandbox là gì?',
                'Đây là môi trường mô phỏng để kiểm thử giao dịch, không phát sinh tiền thật.'),
          ])),
          const SectionTitle('Vẫn cần hỗ trợ?'),
          InfoCard(
              child: ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Gửi yêu cầu hỗ trợ'),
            subtitle: const Text(
                'Chức năng sẽ được kết nối khi API hỗ trợ được triển khai.'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Kênh hỗ trợ đang được thiết lập.'))),
          )),
        ]),
      );
}

class _Faq extends StatelessWidget {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
        children: [Text(answer)],
      );
}
