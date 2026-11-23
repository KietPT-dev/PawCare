import 'package:flutter/foundation.dart';

enum DiscoveryFilter { all, nearby, topRated, newest }

/// One source of truth for Home shortcuts and the Discover tab.
class DiscoveryState extends ChangeNotifier {
  String _query = '';
  String? _category;
  DiscoveryFilter _filter = DiscoveryFilter.all;

  String get query => _query;
  String? get category => _category;
  DiscoveryFilter get filter => _filter;
  bool get hasActiveFilter =>
      _query.isNotEmpty || _category != null || _filter != DiscoveryFilter.all;

  void setQuery(String value) {
    final next = value.trim();
    if (next == _query) return;
    _query = next;
    notifyListeners();
  }

  void open({String? query, String? category}) {
    if (query != null) _query = query.trim();
    if (category != null) _category = category;
    notifyListeners();
  }

  void setFilter(DiscoveryFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _category = null;
    _filter = DiscoveryFilter.all;
    notifyListeners();
  }
}

class ProviderRating {
  const ProviderRating({this.average, this.count});
  final double? average;
  final int? count;

  factory ProviderRating.fromMap(
    Map<String, dynamic> provider, {
    Iterable<Map<String, dynamic>> reviews = const [],
  }) {
    num? number(dynamic value) => value is num ? value : num.tryParse('$value');
    final average = number(
      provider['averageRating'] ??
          provider['ratingAverage'] ??
          provider['average_rating'],
    );
    final explicitCount = number(
      provider['reviewCount'] ?? provider['review_count'],
    )?.toInt();
    final scoped = reviews
        .where(
          (review) =>
              '${review['provider_id'] ?? review['providerId']}' ==
              '${provider['id']}',
        )
        .toList();
    if (scoped.isEmpty)
      return ProviderRating(average: average?.toDouble(), count: explicitCount);
    final values = scoped
        .map((review) => number(review['rating'])?.toDouble())
        .whereType<double>()
        .toList();
    return ProviderRating(
      average: average?.toDouble() ??
          (values.isEmpty
              ? null
              : values.reduce((a, b) => a + b) / values.length),
      count: explicitCount ?? scoped.length,
    );
  }

  String get label => average == null || (count ?? 0) == 0
      ? 'Chưa có đánh giá'
      : '${average!.toStringAsFixed(1)} (${count ?? 0})';
}
