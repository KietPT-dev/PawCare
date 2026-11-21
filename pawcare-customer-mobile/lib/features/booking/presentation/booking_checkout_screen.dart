import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

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
          'Thanh toán đặt lịch',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
      ),
      body: LiquidAmbientBackground(
        child: _payment == null
            ? _methodChooser(isDark, onSurface)
            : _vietQrPayment(isDark, onSurface),
      ),
    );
  }

  Widget _methodChooser(bool isDark, Color onSurface) =>
      FutureBuilder<Map<String, dynamic>>(
        future: _wallet,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () => setState(() => _wallet = widget.api.wallet()),
                child: const Text('Tải lại số dư'),
              ),
            );
          }
          final balance = _num(snapshot.data?['availableBalance']);
          final enough = balance >= _amount;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _summary(isDark, onSurface),
              const SizedBox(height: 18),
              const SectionTitle('Chọn phương thức'),
              _MethodCard(
                selected: _method == 'WALLET',
                enabled: enough,
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF0284C7),
                title: 'Thanh toán bằng Ví PawCare',
                subtitle: enough
                    ? 'Số dư khả dụng: ${_money(balance)}'
                    : 'Số dư ${_money(balance)} chưa đủ để thanh toán',
                onTap: () => setState(() => _method = 'WALLET'),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                selected: _method == 'VIETQR',
                enabled: true,
                icon: Icons.qr_code_2_rounded,
                iconColor: AppColors.teal,
                title: 'Chuyển khoản ngân hàng',
                subtitle: 'VietQR tự động · xác nhận trong vài giây',
                onTap: () => setState(() => _method = 'VIETQR'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _paying || (_method == 'WALLET' && !enough)
                    ? null
                    : _startPayment,
                icon: Icon(
                  _method == 'WALLET'
                      ? Icons.lock_outline_rounded
                      : Icons.qr_code_rounded,
                  size: 20,
                ),
                label: Text(
                  _paying
                      ? 'Đang xử lý...'
                      : _method == 'WALLET'
                          ? 'Thanh toán ${_money(_amount)}'
                          : 'Tạo mã VietQR chuyển khoản',
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: .2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 20, color: AppColors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Một chạm để giữ tiền an toàn qua Escrow. Tiệm sẽ duyệt và nhận tiền sau khi hoàn tất dịch vụ.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );

  Widget _summary(bool isDark, Color onSurface) => LiquidGlassCard(
        radius: 24,
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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'TỔNG THANH TOÁN',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _money(_amount),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30,
                letterSpacing: -0.5,
                color: onSurface,
              ),
            ),
            if (widget.booking['providerName'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '${widget.booking['providerName']} · ${widget.booking['serviceName'] ?? ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      );

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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
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
      // Giữ QR hoạt động ngay cả khi có lỗi mạng tạm thời
    } finally {
      _checking = false;
    }
  }

  // ── Hộp thoại thông báo Thanh toán thành công (Redesigned) ──
  void _success() {
    _timer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: LiquidGlassCard(
          radius: 28,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: .32),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 18),
              Text(
                'Thanh toán thành công! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Theme.of(dialogCtx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tiền đã được bảo lưu an toàn qua hệ thống Escrow Protection. Tiệm sẽ sớm duyệt lịch hẹn của bé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: Theme.of(dialogCtx).brightness == Brightness.dark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Số tiền đã giữ:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _money(_amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Hoàn tất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Màn hình chuyển khoản VietQR ──
  Widget _vietQrPayment(bool isDark, Color onSurface) {
    final payment = _payment!;
    final code = '${payment['paymentCode']}';
    final qr = '${payment['qrUrl'] ?? ''}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // Đồng hồ đếm ngược
        LiquidGlassCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined,
                    color: AppColors.coral, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _clock(_remaining),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.coral,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Hoàn tất chuyển khoản trong 15 phút',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Khung mã QR VietQR
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .4 : .1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: qr.isEmpty
              ? const Column(
                  children: [
                    Icon(Icons.qr_code_2, size: 160, color: AppColors.navy),
                    SizedBox(height: 10),
                    Text(
                      'Mã QR đang được tạo bởi hệ thống…',
                      style: TextStyle(color: AppColors.navy),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    qr,
                    height: 240,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'Không thể tải ảnh mã QR. Hãy chuyển khoản theo thông tin bên dưới.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.navy),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Thông tin chuyển khoản
        LiquidGlassCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TransferLine(
                label: 'Số tiền chuyển khoản',
                value: _money(payment['amount'] ?? _amount),
                isAmount: true,
                copy: false,
              ),
              const Divider(height: 18),
              _TransferLine(
                label: 'Nội dung chuyển khoản (bắt buộc đúng)',
                value: code,
                isAmount: false,
                copy: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Hệ thống tự động kiểm tra giao dịch liên tục qua VietQR. Bạn không cần chụp màn hình biên lai.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: TextButton.icon(
            onPressed: _checking ? null : _checkPayment,
            icon: _checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_checking ? 'Đang kiểm tra...' : 'Kiểm tra ngay'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teal,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected, enabled;
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Opacity(
      opacity: enabled ? 1 : .55,
      child: LiquidGlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        borderWidth: selected ? 2 : 1.2,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withValues(alpha: isDark ? .28 : .14),
                  AppColors.cyan.withValues(alpha: isDark ? .12 : .06),
                ],
              )
            : null,
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.teal.withValues(alpha: .22)
                    : iconColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: selected ? AppColors.teal : iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.teal : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.teal
                      : (isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferLine extends StatelessWidget {
  const _TransferLine({
    required this.label,
    required this.value,
    required this.copy,
    this.isAmount = false,
  });

  final String label, value;
  final bool copy;
  final bool isAmount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isAmount ? 18 : 16,
                  color: isAmount ? AppColors.teal : onSurface,
                  letterSpacing: isAmount ? 0 : 0.5,
                ),
              ),
            ],
          ),
        ),
        if (copy)
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đã sao chép nội dung chuyển khoản.')),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: AppColors.teal),
            tooltip: 'Sao chép',
          ),
      ],
    );
  }
}

num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
String _money(dynamic value) =>
    '${_num(value).round().toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}đ';
String _clock(Duration value) =>
    '${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
