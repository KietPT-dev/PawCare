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

  @override
  void initState() {
    super.initState();
    _providers = widget.api.list('/providers');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Khám phá dịch vụ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 14),
              TextField(
                  onChanged: (value) =>
                      setState(() => query = value.toLowerCase().trim()),
                  decoration: const InputDecoration(
                      hintText: 'Tìm dịch vụ, đối tác, khu vực',
                      prefixIcon: Icon(Icons.search))),
            ]),
          ),
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
              if (providers.isEmpty)
                return const Center(
                    child: Text('Không tìm thấy đối tác phù hợp.'));
              return RefreshIndicator(
                onRefresh: () async =>
                    setState(() => _providers = widget.api.list('/providers')),
                child: ListView.separated(
                    padding: const EdgeInsets.all(20),
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
                                          MapEntry(
                                              key, value?.toString() ?? ''))))),
                          child: Row(children: [
                            Container(
                                width: 64,
                                height: 64,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(18)),
                                child: const Icon(Icons.storefront_outlined,
                                    color: AppColors.teal, size: 30)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${provider['name']}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(
                                      '${provider['service_area'] ?? provider['address'] ?? 'Đang cập nhật khu vực'}'),
                                  const SizedBox(height: 7),
                                  Text('⭐ $rating · Xem dịch vụ',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ])),
                            const Icon(Icons.chevron_right),
                          ]));
                    }),
              );
            },
          )),
        ]),
      );
}
