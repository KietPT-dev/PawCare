import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/ui.dart';
import '../../pets/presentation/pets_screen.dart';
import 'booking_checkout_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.api,
    required this.providerId,
    required this.providerName,
  });
  final PawCareApi api;
  final int providerId;
  final String providerName;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int step = 0;
  late Future<_BookingData> _data;
  Map<String, dynamic>? service;
  Map<String, dynamic>? pet;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  String slot = '09:00';
  final note = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _data = _loadBookingData();

  Future<_BookingData> _loadBookingData() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      widget.api.list('/services?providerId=${widget.providerId}'),
      widget.api.list('/pets'),
    ]);
    return _BookingData(services: results[0], pets: results[1]);
  }

  void _retry() => setState(_load);

  @override
  void dispose() {
    note.dispose();
    super.dispose();
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
          'Tạo booking',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
      ),
      body: LiquidAmbientBackground(
        child: FutureBuilder<_BookingData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _BookingMessage(
                icon: Icons.calendar_month_outlined,
                title: 'Đang chuẩn bị lịch hẹn',
                message: 'Đang tải dịch vụ và hồ sơ thú cưng của bạn…',
                loading: true,
              );
            }
            if (snapshot.hasError) {
              return _BookingMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Chưa thể tải biểu mẫu đặt lịch',
                message: _friendlyError(snapshot.error),
                actionLabel: 'Thử lại',
                onAction: _retry,
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return _BookingMessage(
                icon: Icons.error_outline,
                title: 'Không có dữ liệu booking',
                message: 'Hãy thử tải lại biểu mẫu đặt lịch.',
                actionLabel: 'Tải lại',
                onAction: _retry,
              );
            }
            final services = data.services;
            final pets = data.pets;
            if (services.isEmpty || pets.isEmpty) {
              return _BookingMessage(
                icon: services.isEmpty
                    ? Icons.storefront_outlined
                    : Icons.pets_outlined,
                title: services.isEmpty
                    ? 'Provider chưa có dịch vụ khả dụng'
                    : 'Bạn chưa có thú cưng',
                message: services.isEmpty
                    ? 'Hãy thử một Provider khác hoặc quay lại sau.'
                    : 'Thêm hồ sơ thú cưng trước khi tạo booking.',
                actionLabel:
                    services.isEmpty ? 'Tải lại' : 'Quản lý thú cưng',
                onAction: services.isEmpty
                    ? _retry
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PetsScreen(api: widget.api))),
              );
            }
            service ??= services.first;
            pet ??= pets.first;
            final pages = [
              _chooseService(services, pets, isDark, onSurface),
              _chooseTime(isDark, onSurface),
              _confirm(isDark, onSurface)
            ];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh tiến trình Stepper
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (step + 1) / 3,
                        minHeight: 6,
                        backgroundColor: AppColors.teal.withValues(alpha: .15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.teal),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      [
                        'Chọn dịch vụ',
                        'Chọn ngày giờ',
                        'Xác nhận & thanh toán'
                      ][step],
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 15, color: AppColors.teal),
                        const SizedBox(width: 4),
                        Text(
                          widget.providerName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(child: pages[step]),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (step > 0) ...[
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(100, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => setState(() => step--),
                            child: const Text('Quay lại'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(120, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: saving
                                ? null
                                : () => step < 2
                                    ? setState(() => step++)
                                    : _submit(),
                            child: Text(
                              saving
                                  ? 'Đang gửi...'
                                  : step == 2
                                      ? 'Đi đến thanh toán'
                                      : 'Tiếp tục',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _friendlyError(Object? error) {
    final message = error?.toString() ?? '';
    if (message.contains('401') || message.contains('đăng nhập')) {
      return 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại rồi thử lại.';
    }
    return message.isEmpty
        ? 'Không thể kết nối dữ liệu booking. Hãy kiểm tra kết nối và thử lại.'
        : message;
  }

  // ── Step 1: Chọn dịch vụ & Thú cưng ──
  Widget _chooseService(
    List<Map<String, dynamic>> services,
    List<Map<String, dynamic>> pets,
    bool isDark,
    Color onSurface,
  ) =>
      ListView(
        children: [
          const SectionTitle('Dịch vụ'),
          ...services.map((item) {
            final isSelected = service == item;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LiquidGlassCard(
                radius: 18,
                padding: const EdgeInsets.all(14),
                borderWidth: isSelected ? 2 : 1.2,
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.teal
                              .withValues(alpha: isDark ? .28 : .14),
                          AppColors.cyan
                              .withValues(alpha: isDark ? .14 : .06),
                        ],
                      )
                    : null,
                onTap: () => setState(() => service = item),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.teal.withValues(alpha: .22)
                            : AppColors.teal.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets_rounded,
                          color: AppColors.teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['name']}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['duration_minutes']} phút · ${AppFormatters.money(item['price'])}',
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
                        color:
                            isSelected ? AppColors.teal : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.teal
                              : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1)),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          const SectionTitle('Thú cưng'),
          ...pets.map((item) {
            final isSelected = pet == item;
            final species =
                (item['species'] ?? '').toString().toLowerCase();
            final emoji =
                species.contains('mèo') || species.contains('cat')
                    ? '🐱'
                    : '🐶';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LiquidGlassCard(
                radius: 18,
                padding: const EdgeInsets.all(14),
                borderWidth: isSelected ? 2 : 1.2,
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.teal
                              .withValues(alpha: isDark ? .28 : .14),
                          AppColors.cyan
                              .withValues(alpha: isDark ? .14 : .06),
                        ],
                      )
                    : null,
                onTap: () => setState(() => pet = item),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.teal.withValues(alpha: .22)
                            : AppColors.teal.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['name']}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [item['species'], item['breed']]
                                .where((v) =>
                                    v != null &&
                                    v.toString().trim().isNotEmpty)
                                .join(' · '),
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
                        color:
                            isSelected ? AppColors.teal : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.teal
                              : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1)),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );

  // ── Step 2: Chọn ngày giờ ──
  Widget _chooseTime(bool isDark, Color onSurface) => ListView(
        children: [
          const SectionTitle('Ngày hẹn'),
          LiquidGlassCard(
            radius: 18,
            padding: const EdgeInsets.all(16),
            onTap: _pickDate,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: AppColors.teal, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ngày đã chọn',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_calendar_rounded,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionTitle('Khung giờ khả dụng'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['08:00', '09:00', '10:30', '13:00', '15:00'].map(
              (value) {
                final isSelected = slot == value;
                return InkWell(
                  onTap: () => setState(() => slot = value),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.teal
                          : (isDark
                              ? AppColors.darkSurface
                              : Colors.white.withValues(alpha: .8)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.teal
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          value,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ).toList(),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Ghi chú đặc biệt'),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú cho Provider (ví dụ: Bé sợ tắm, bé vừa tiêm vaccine…)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      );

  // ── Step 3: Xác nhận tóm tắt ──
  Widget _confirm(bool isDark, Color onSurface) => ListView(
        children: [
          LiquidGlassCard(
            radius: 22,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(
                  icon: Icons.pets_rounded,
                  iconColor: AppColors.teal,
                  label: 'Thú cưng',
                  value: '${pet?['name']} · ${pet?['species']}',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.content_cut_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: 'Dịch vụ',
                  value:
                      '${service?['name']} (${service?['duration_minutes']} phút)',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  label: 'Thời gian hẹn',
                  value:
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} lúc $slot',
                ),
                if (note.text.trim().isNotEmpty) ...[
                  const Divider(height: 24),
                  _SummaryRow(
                    icon: Icons.notes_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Ghi chú',
                    value: note.text.trim(),
                  ),
                ],
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: .22),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 20, color: AppColors.teal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Thanh toán được bảo vệ bởi Escrow Protection. Tiệm nhận tiền khi dịch vụ hoàn thành.',
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng dự kiến',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      AppFormatters.money(service?['price']),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDate: date,
    );
    if (selected != null) setState(() => date = selected);
  }

  Future<void> _submit() async {
    setState(() => saving = true);
    try {
      final time = slot.split(':');
      final start = DateTime(date.year, date.month, date.day,
          int.parse(time[0]), int.parse(time[1]));
      final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => BookingCheckoutScreen(api: widget.api, booking: {
          'petId': pet!['id'],
          'providerId': widget.providerId,
          'serviceId': service!['id'],
          'bookingStart': start.toIso8601String(),
          'customerNote': note.text.trim(),
          'amount': service!['price'],
          'providerName': widget.providerName,
          'serviceName': service!['name'],
        }),
      ));
      if (!mounted || result != true) return;

      // ── Hộp thoại thông báo Đặt lịch thành công Liquid Glass ──
      await showDialog<void>(
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
                      color: AppColors.success.withValues(alpha: .3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 44),
                ),
                const SizedBox(height: 18),
                Text(
                  'Đặt lịch thành công! 🎉',
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
                  'Lịch hẹn đã được gửi tới ${widget.providerName}. Tiền đang được bảo vệ an toàn qua Escrow Protection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Theme.of(dialogCtx).brightness == Brightness.dark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Xem lịch hẹn của tôi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingData {
  const _BookingData({required this.services, required this.pets});
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> pets;
}

class _BookingMessage extends StatelessWidget {
  const _BookingMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? const CircularProgressIndicator()
                    : Icon(icon, color: AppColors.teal, size: 36),
              ),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (actionLabel != null) ...[
                const SizedBox(height: 22),
                FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh),
                    label: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}
