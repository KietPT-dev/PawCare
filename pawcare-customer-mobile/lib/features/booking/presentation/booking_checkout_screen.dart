import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen(
      {super.key, required this.api, required this.booking});
  final PawCareApi api;
  final Map<String, dynamic> booking;
  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  late Future<Map<String, dynamic>> _wallet;
  String _method = 'WALLET';
  bool _paying = false;
  Map<String, dynamic>? _payment;
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 15);
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _wallet = widget.api.wallet();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  num get _amount => _num(widget.booking['amount']);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thanh toán đặt lịch')),
        body: _payment == null ? _methodChooser() : _vietQrPayment(),
      );

  Widget _methodChooser() => FutureBuilder<Map<String, dynamic>>(
        future: _wallet,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: FilledButton(
                    onPressed: () =>
                        setState(() => _wallet = widget.api.wallet()),
                    child: const Text('Tải lại số dư')));
          final balance = _num(snapshot.data?['availableBalance']);
          final enough = balance >= _amount;
          return ListView(padding: const EdgeInsets.all(20), children: [
            _summary(),
            const SizedBox(height: 20),
            Text('Chọn phương thức',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _MethodCard(
                selected: _method == 'WALLET',
                enabled: enough,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Thanh toán bằng Ví PawCare',
                subtitle: enough
                    ? 'Số dư khả dụng: ${_money(balance)}'
                    : 'Số dư ${_money(balance)} chưa đủ để thanh toán',
                onTap: () => setState(() => _method = 'WALLET')),
            const SizedBox(height: 12),
            _MethodCard(
                selected: _method == 'VIETQR',
                enabled: true,
                icon: Icons.qr_code_2,
                title: 'Chuyển khoản ngân hàng',
                subtitle: 'VietQR tự động · xác nhận trong vài giây',
                onTap: () => setState(() => _method = 'VIETQR')),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _paying || (_method == 'WALLET' && !enough)
                  ? null
                  : _startPayment,
              icon: Icon(
                  _method == 'WALLET' ? Icons.lock_outline : Icons.qr_code),
              label: Text(_paying
                  ? 'Đang xử lý...'
                  : _method == 'WALLET'
                      ? 'Thanh toán ${_money(_amount)}'
                      : 'Tạo mã VietQR'),
            ),
            if (_method == 'WALLET' && enough)
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                      'Một chạm để giữ tiền trong Ví PawCare. Tiệm sẽ duyệt lịch hẹn sau.',
                      textAlign: TextAlign.center)),
          ]);
        },
      );

  Widget _summary() => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.mint, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TỔNG THANH TOÁN',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 5),
        Text(_money(_amount),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: AppColors.navy)),
        if (widget.booking['providerName'] != null)
          Text(
              '${widget.booking['providerName']} · ${widget.booking['serviceName'] ?? ''}'),
      ]));

  Future<void> _startPayment() async {
    setState(() => _paying = true);
    try {
      final created = Map<String, dynamic>.from(await widget.api.post(
          '/bookings', {...widget.booking, 'paymentMethod': _method}) as Map);
      final payment = Map<String, dynamic>.from(created['payment'] as Map);
      if (!mounted) return;
      if (_method == 'WALLET') {
        _success();
        return;
      }
      setState(() => _payment = payment);
      _startPolling();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= Duration.zero) {
        _timer?.cancel();
        if (mounted) setState(() {});
        return;
      }
      if (mounted) setState(() => _remaining -= const Duration(seconds: 1));
      if (_remaining.inSeconds % 5 == 0) _checkPayment();
    });
  }

  Future<void> _checkPayment() async {
    if (_checking || _payment == null) return;
    _checking = true;
    try {
      final id = _payment!['bookingId'];
      final bookings = await widget.api.list('/bookings');
      final booking = bookings
          .cast<Map<String, dynamic>?>()
          .firstWhere((row) => '${row?['id']}' == '$id', orElse: () => null);
      if (booking?['status'] == 'PENDING_APPROVAL') _success();
    } catch (_) {
      // Keep the QR visible; a transient network error must not interrupt payment.
    } finally {
      _checking = false;
    }
  }

  void _success() {
    _timer?.cancel();
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              icon: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 52),
              title: const Text('Thanh toán thành công'),
              content: const Text(
                  'Tiền đã được tạm giữ an toàn. Tiệm sẽ duyệt lịch hẹn của bạn sớm.'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    child: const Text('Xong'))
              ],
            ));
  }

  Widget _vietQrPayment() {
    final payment = _payment!;
    final code = '${payment['paymentCode']}';
    final qr = '${payment['qrUrl'] ?? ''}';
    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(
          child: Column(children: [
        const Icon(Icons.timer_outlined, color: AppColors.coral),
        Text(_clock(_remaining),
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.coral)),
        const Text('Hoàn tất chuyển khoản trong 15 phút')
      ])),
      const SizedBox(height: 18),
      Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: qr.isEmpty
              ? const Column(children: [
                  Icon(Icons.qr_code_2, size: 160),
                  SizedBox(height: 10),
                  Text('Mã QR đang được cấu hình bởi máy chủ.')
                ])
              : Image.network(qr,
                  height: 230,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 180,
                      child: Center(child: Text('Không thể tải mã QR.'))))),
      const SizedBox(height: 18),
      _TransferLine(
          label: 'Số tiền',
          value: _money(payment['amount'] ?? _amount),
          copy: false),
      _TransferLine(label: 'Nội dung chuyển khoản', value: code, copy: true),
      const SizedBox(height: 10),
      const Text(
          'Hệ thống đang tự động kiểm tra giao dịch. Bạn không cần gửi ảnh biên lai.',
          textAlign: TextAlign.center),
      TextButton.icon(
          onPressed: _checkPayment,
          icon: const Icon(Icons.refresh),
          label: const Text('Kiểm tra ngay')),
    ]);
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard(
      {required this.selected,
      required this.enabled,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final bool selected, enabled;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: enabled ? 1 : .55,
      child: Card(
          child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(icon,
                        color: selected ? AppColors.teal : AppColors.navy,
                        size: 29),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(subtitle)
                        ])),
                    Radio(
                        value: true,
                        groupValue: selected,
                        onChanged: enabled ? (_) => onTap() : null),
                  ])))));
}

class _TransferLine extends StatelessWidget {
  const _TransferLine(
      {required this.label, required this.value, required this.copy});
  final String label, value;
  final bool copy;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))
        ])),
        if (copy)
          IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Đã sao chép nội dung chuyển khoản.')));
              },
              icon: const Icon(Icons.copy_outlined))
      ]));
}

num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
String _money(dynamic value) =>
    '${_num(value).round().toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}đ';
String _clock(Duration value) =>
    '${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
