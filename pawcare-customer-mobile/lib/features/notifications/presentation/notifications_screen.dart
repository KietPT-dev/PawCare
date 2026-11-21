import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/ui.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../activity/presentation/booking_detail_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen(
      {super.key, required this.api, required this.onChanged});
  final PawCareApi api;
  final VoidCallback onChanged;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _items = widget.api.list('/notifications');

  Future<void> _refresh() async {
    setState(_reload);
    await _items;
    widget.onChanged();
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
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teal,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            child: const Text('Đọc tất cả'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LiquidAmbientBackground(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 48, color: AppColors.coral),
                      const SizedBox(height: 12),
                      Text(
                        ApiMessages.friendly(snapshot.error),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: .12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bạn chưa có thông báo nào.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Các cập nhật lịch hẹn và dịch vụ sẽ hiển thị tại đây.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = items[index];
                  final unread =
                      item['is_read'] != true && item['is_read'] != 1;
                  return LiquidGlassCard(
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    blur: 12,
                    onTap: () async {
                      try {
                        if (unread) {
                          await widget.api
                              .put('/notifications/${item['id']}/read', {});
                        }
                        widget.onChanged();
                        if (context.mounted) await _openReference(item);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiMessages.friendly(error))),
                          );
                        }
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: unread
                                ? AppColors.teal.withValues(alpha: .14)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            unread
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            color: unread
                                ? AppColors.teal
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['title'] ?? 'Thông báo'}',
                                style: TextStyle(
                                  fontWeight:
                                      unread ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 14.5,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppFormatters.replaceRawStatusInNotification(
                                    '${item['content'] ?? ''}'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppFormatters.relativeTime(item['created_at'] ??
                                    item['createdAt']),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsets.only(top: 4, left: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.coral,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markAllRead() async {
    try {
      await widget.api.put('/notifications/read-all', {});
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiMessages.friendly(error))));
      }
    }
  }

  Future<void> _openReference(Map<String, dynamic> item) async {
    final type = '${item['reference_type'] ?? ''}'.toUpperCase();
    final id = int.tryParse('${item['reference_id']}');
    if (type == 'BOOKING' && id != null) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookingDetailScreen(api: widget.api, bookingId: id)));
    } else if (type == 'WALLET' || type == 'PAYMENT' || type == 'TOPUP') {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WalletScreen(api: widget.api)));
    } else if (type == 'DISPUTE' || type == 'COMPLAINT') {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActivityScreen(api: widget.api)));
    }
    if (mounted) await _refresh();
  }
}
