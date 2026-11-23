import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import 'discovery_state.dart';
import 'provider_detail_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key, required this.api, required this.state});
  final PawCareApi api;
  final DiscoveryState state;
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late Future<_DiscoveryData> _data;
  late final TextEditingController _search;
  late final FocusNode _focus;
  Timer? _debounce;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.state.query);
    _focus = FocusNode();
    _reload();
    widget.state.addListener(_stateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.state.query.isNotEmpty && mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.state.removeListener(_stateChanged);
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _stateChanged() {
    if (_search.text != widget.state.query) {
      _search.value = TextEditingValue(
        text: widget.state.query,
        selection: TextSelection.collapsed(offset: widget.state.query.length),
      );
    }
    if (mounted) setState(() {});
  }

  void _reload() {
    final token = ++_request;
    _data = _load(token);
  }

  Future<_DiscoveryData> _load(int token) async {
    final values = await Future.wait([
      widget.api.list('/providers'),
      widget.api.list('/services'),
      widget.api.list('/reviews'),
    ]);
    if (token != _request) throw StateError('stale discovery response');
    return _DiscoveryData(values[0], values[1], values[2]);
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _data;
    } catch (_) {}
  }

  void _changedQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) widget.state.setQuery(value);
    });
  }

  void _chooseFilter(DiscoveryFilter value) {
    if (value == DiscoveryFilter.nearby) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có quyền vị trí. Đang hiển thị tất cả đối tác.'),
        ),
      );
      return;
    }
    if (value == DiscoveryFilter.newest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể sắp xếp mới nhất vì API chưa trả ngày duyệt đối tác.'),
        ),
      );
      return;
    }
    widget.state.setFilter(value);
  }

  @override
  Widget build(BuildContext context) {
    final labels = <DiscoveryFilter, String>{
      DiscoveryFilter.all: 'Tất cả',
      DiscoveryFilter.nearby: 'Gần tôi',
      DiscoveryFilter.topRated: 'Đánh giá cao',
      DiscoveryFilter.newest: 'Mới',
    };
    return Scaffold(
      body: LiquidAmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khám phá dịch vụ',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tìm spa, bác sĩ và khách sạn tốt nhất cho bé',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    LiquidGlassCard(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: TextField(
                        key: const ValueKey('discovery-search'),
                        controller: _search,
                        focusNode: _focus,
                        onChanged: _changedQuery,
                        decoration: InputDecoration(
                          hintText: 'Tìm dịch vụ, đối tác, khu vực...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.teal,
                          ),
                          suffixIcon: widget.state.query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    widget.state.setQuery('');
                                  },
                                ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: labels.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(entry.value),
                            selected: widget.state.filter == entry.key,
                            onSelected: (_) => _chooseFilter(entry.key),
                            avatar: entry.key == DiscoveryFilter.nearby
                                ? const Icon(
                                    Icons.location_off_outlined,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (widget.state.hasActiveFilter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _activeText(),
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.state.clear,
                        child: const Text('Xóa lọc'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: FutureBuilder<_DiscoveryData>(
                  future: _data,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return _StateMessage(
                        text: ApiMessages.friendly(snapshot.error),
                        action: _refresh,
                      );
                    final providers = _filtered(snapshot.data!);
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: providers.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 150),
                                Center(
                                  child: Text(
                                    'Không tìm thấy đối tác phù hợp. Hãy xóa bớt bộ lọc.',
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                110,
                              ),
                              itemCount: providers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) => _ProviderCard(
                                provider: providers[index],
                                api: widget.api,
                                reviews: snapshot.data!.reviews,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _activeText() {
    final parts = <String>[];
    if (widget.state.query.isNotEmpty) parts.add('“${widget.state.query}”');
    if (widget.state.category != null) parts.add(widget.state.category!);
    if (widget.state.filter == DiscoveryFilter.topRated)
      parts.add('Đánh giá cao');
    if (widget.state.filter == DiscoveryFilter.newest) parts.add('Mới');
    return 'Đang áp dụng: ${parts.join(' · ')}';
  }

  List<Map<String, dynamic>> _filtered(_DiscoveryData data) {
    final query = widget.state.query.toLowerCase();
    final category = widget.state.category?.toLowerCase();
    final rows = data.providers.where((provider) {
      final services = data.services.where(
        (s) => '${s['provider_id'] ?? s['providerId']}' == '${provider['id']}',
      );
      final text =
          '${provider['name']} ${provider['service_area']} ${provider['address']} ${services.map((s) => '${s['name']} ${s['category_name'] ?? ''}').join(' ')}'
              .toLowerCase();
      return text.contains(query) &&
          (category == null ||
              services.any(
                (s) => '${s['name']} ${s['category_name'] ?? ''}'
                    .toLowerCase()
                    .contains(category),
              ));
    }).toList();
    if (widget.state.filter == DiscoveryFilter.topRated)
      rows.sort(
        (a, b) =>
            (ProviderRating.fromMap(b, reviews: data.reviews).average ?? -1)
                .compareTo(
                  ProviderRating.fromMap(a, reviews: data.reviews).average ??
                      -1,
                ),
      );
    return rows;
  }
}

class _DiscoveryData {
  const _DiscoveryData(this.providers, this.services, this.reviews);
  final List<Map<String, dynamic>> providers, services, reviews;
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.api,
    required this.reviews,
  });
  final Map<String, dynamic> provider;
  final PawCareApi api;
  final List<Map<String, dynamic>> reviews;
  @override
  Widget build(BuildContext context) {
    final rating = ProviderRating.fromMap(provider, reviews: reviews);
    final detail = {
      ...provider,
      'averageRating': rating.average ?? '',
      'reviewCount': rating.count ?? 0,
    };
    return InfoCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProviderDetailScreen(
            api: api,
            provider: detail.map((k, v) => MapEntry(k, '$v')),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.teal.withValues(alpha: .14),
            child: const Icon(Icons.storefront_rounded, color: AppColors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider['name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider['service_area'] ?? provider['address'] ?? 'Đang cập nhật khu vực'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  rating.label,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.text, required this.action});
  final String text;
  final Future<void> Function() action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 44),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
        TextButton(onPressed: action, child: const Text('Thử lại')),
      ],
    ),
  );
}
