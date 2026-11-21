import 'package:flutter/material.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import 'provider_detail_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key, required this.api});
  final PawCareApi api;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late Future<List<Map<String, dynamic>>> _providers;
  String query = '';
  int _selectedFilter = 0;

  static const _filters = ['Tất cả', 'Gần tôi', 'Đánh giá cao', 'Mới'];

  @override
  void initState() {
    super.initState();
    _providers = widget.api.list('/providers');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      body: LiquidAmbientBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (canPop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GlassIconButton(
                        size: 38,
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        tooltip: 'Quay lại',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                Text('Khám phá dịch vụ',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: onSurface)),
                const SizedBox(height: 4),
                Text('Tìm spa, bác sĩ và khách sạn tốt nhất cho bé',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
            LiquidGlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: TextField(
                onChanged: (value) =>
                    setState(() => query = value.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'Tìm dịch vụ, đối tác, khu vực...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.teal, size: 22),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        size: 18, color: AppColors.teal),
                  ),
                  filled: false,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),

        // ── Filter chips (Liquid Glass) ──
        SizedBox(
          height: 42,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_filters.length, (index) {
                final selected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedFilter = index),
                    child: LiquidGlassCard(
                      radius: 14,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      tintColor: selected
                          ? AppColors.teal.withValues(alpha: isDark ? .30 : .16)
                          : null,
                      borderWidth: selected ? 1.5 : 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            const Icon(Icons.check_rounded,
                                size: 14, color: AppColors.teal),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _filters[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected
                                  ? AppColors.teal
                                  : (isDark
                                      ? const Color(0xFFC6DFE5)
                                      : AppColors.navy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // ── Provider list ──
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _providers,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text(snapshot.error.toString(),
                        textAlign: TextAlign.center));
              }
              final providers = (snapshot.data ?? []).where((provider) {
                final text =
                    '${provider['name']} ${provider['service_area']} ${provider['address']}'
                        .toLowerCase();
                return text.contains(query);
              }).toList();
              if (providers.isEmpty) {
                return const Center(
                    child: Text('Không tìm thấy đối tác phù hợp.'));
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    setState(() => _providers = widget.api.list('/providers')),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    final rating = provider['average_rating'] ?? 'Mới';
                    return InfoCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderDetailScreen(
                            api: widget.api,
                            provider: provider.map((key, value) =>
                                MapEntry(key, value?.toString() ?? '')),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                AppColors.teal.withValues(alpha: .14),
                            child: const Icon(Icons.storefront_rounded,
                                color: AppColors.teal, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${provider['name']}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4B740)
                                            .withValues(alpha: .14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: Color(0xFFF4B740),
                                              size: 14),
                                          const SizedBox(width: 2),
                                          Text('$rating',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 13,
                                        color: isDark
                                            ? const Color(0xFF9CBAC3)
                                            : const Color(0xFF6B8791)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        '${provider['service_area'] ?? provider['address'] ?? 'Đang cập nhật khu vực'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xFF9CBAC3)
                                              : const Color(0xFF6B8791),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(spacing: 6, children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: AppColors.teal
                                            .withValues(alpha: .12),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Grooming',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.teal)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Spa',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.teal)),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded,
                              color: isDark
                                  ? const Color(0xFF9CBAC3)
                                  : const Color(0xFF6B8791)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
