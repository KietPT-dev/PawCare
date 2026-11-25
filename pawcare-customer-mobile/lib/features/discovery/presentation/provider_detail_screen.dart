import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/ui.dart';
import '../../booking/presentation/booking_screen.dart';
import '../../chat/presentation/conversation_screen.dart';
import 'discovery_state.dart';

class ProviderDetailScreen extends StatefulWidget {
  const ProviderDetailScreen({
    super.key,
    required this.provider,
    required this.api,
  });
  final Map<String, String> provider;
  final PawCareApi api;

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  late Future<List<Map<String, dynamic>>> _services;
  Map<String, dynamic>? selected;
  int get id => int.tryParse(widget.provider['id'] ?? '') ?? 0;
  ProviderRating get _rating => ProviderRating.fromMap(widget.provider);

  @override
  void initState() {
    super.initState();
    _services = widget.api.list('/services?providerId=$id');
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
          widget.provider['name'] ?? 'Chi tiết đối tác',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
      ),
      body: LiquidAmbientBackground(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _services,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final services = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                // ── Thẻ thông tin đối tác ──
                LiquidGlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.teal.withValues(
                                    alpha: isDark ? .28 : .14,
                                  ),
                                  AppColors.cyan.withValues(
                                    alpha: isDark ? .14 : .06,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: .24),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.teal,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.provider['name'] ?? 'Đối tác PawCare',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.coral,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        widget.provider['address'] ??
                                            widget.provider['service_area'] ??
                                            'Đang cập nhật địa chỉ',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Metric(
                            _rating.label,
                            'Đánh giá',
                            icon: Icons.star_rounded,
                            iconColor: Color(0xFFF59E0B),
                          ),
                          _Metric(
                            '100%',
                            'Bảo vệ Escrow',
                            icon: Icons.shield_rounded,
                            iconColor: AppColors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SectionTitle('Dịch vụ khả dụng'),
                if (services.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Chưa có dịch vụ nào được niêm yết.',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  ...services.map((x) => _service(x, isDark, onSurface)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(children: [
            Expanded(
                child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      api: widget.api,
                      providerId: id,
                      providerName:
                          widget.provider['name'] ?? 'Đối tác PawCare',
                    ),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 20),
                label: const Text('Đặt lịch ngay'),
              ),
            )),
            const SizedBox(width: 10),
            SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () =>
                      openDirectConversation(context, widget.api, id),
                  child: const Icon(Icons.chat_bubble_outline_rounded),
                )),
          ]),
        ),
      ),
    );
  }

  Widget _service(Map<String, dynamic> x, bool isDark, Color onSurface) {
    final isSelected = selected == x;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        borderWidth: isSelected ? 2 : 1.2,
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withValues(alpha: isDark ? .30 : .16),
                  AppColors.cyan.withValues(alpha: isDark ? .16 : .08),
                ],
              )
            : null,
        onTap: () => setState(() => selected = x),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal.withValues(alpha: .22)
                    : AppColors.teal.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppColors.teal,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${x['name']}',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${x['duration_minutes']} phút',
                        style: TextStyle(
                          fontSize: 12.5,
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
            Text(
              AppFormatters.money(x['price']),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.teal : Colors.transparent,
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
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.a, this.b, {this.icon, this.iconColor});
  final String a, b;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? AppColors.teal),
              const SizedBox(width: 4),
            ],
            Text(
              a,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          b,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
