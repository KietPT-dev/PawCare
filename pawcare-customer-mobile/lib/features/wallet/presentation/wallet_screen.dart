import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.api});
  final PawCareApi api;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<_WalletData> _data;
  String _filter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _data = _load();

  Future<_WalletData> _load() async {
    final values = await Future.wait([
      widget.api.wallet(),
      widget.api.walletTransactions(),
    ]);
    return _WalletData(
      wallet: values[0] as Map<String, dynamic>,
      transactions: values[1] as List<Map<String, dynamic>>,
    );
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
          'Ví PawCare',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LiquidAmbientBackground(
        child: FutureBuilder<_WalletData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _WalletError(
                  error: snapshot.error, onRetry: () => setState(_reload));
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => setState(_reload),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                children: [
                  _BalanceCard(wallet: data.wallet),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showTopUp(context),
                          icon: const Icon(Icons.add_card_rounded, size: 20),
                          label: const Text('Nạp tiền'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(120, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _withdraw(context),
                          icon: const Icon(Icons.account_balance_rounded,
                              size: 20),
                          label: const Text('Rút tiền'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SectionTitle(
                    'Lịch sử biến động',
                    action: _filter,
                    onAction: () => _chooseFilter(context),
                  ),
                  if (_filtered(data.transactions).isEmpty)
                    LiquidGlassCard(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_rounded,
                                size: 38, color: Color(0xFF64748B)),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa có giao dịch nào.',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._filtered(data.transactions)
                        .map((item) => _TransactionRow(item: item)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> items) =>
      _filter == 'Tất cả'
          ? items
          : items.where((x) => '${x['type']}' == _filter).toList();

  Future<void> _chooseFilter(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LiquidModalSheet(
        title: 'Bộ lọc giao dịch',
        child: ListView(
          shrinkWrap: true,
          children: [
            'Tất cả',
            'DEPOSIT',
            'ESCROW_HOLD',
            'ESCROW_RELEASE',
            'WITHDRAWAL'
          ]
              .map(
                (x) => ListTile(
                  title: Text(
                    x == 'Tất cả'
                        ? 'Tất cả giao dịch'
                        : x == 'DEPOSIT'
                            ? 'Nạp tiền vào ví'
                            : x == 'ESCROW_HOLD'
                                ? 'Tạm giữ đặt lịch'
                                : x == 'ESCROW_RELEASE'
                                    ? 'Giải ngân / Hoàn tiền'
                                    : 'Rút tiền về ngân hàng',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: _filter == x
                      ? const Icon(Icons.check_rounded, color: AppColors.teal)
                      : null,
                  onTap: () => Navigator.pop(context, x),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (value != null && mounted) setState(() => _filter = value);
  }

  Future<void> _showTopUp(BuildContext context) async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopUpSheet(api: widget.api),
    );
    if (completed == true && mounted) setState(_reload);
  }

  Future<void> _withdraw(BuildContext context) async {
    final amount = TextEditingController();
    final bank = TextEditingController();
    final account = TextEditingController();
    final name = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LiquidModalSheet(
        title: 'Yêu cầu rút tiền',
        subtitle: 'Tiền sẽ được giải ngân về tài khoản ngân hàng của bạn',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền muốn rút (VNĐ)',
                  prefixIcon: Icon(Icons.attach_money_rounded,
                      color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bank,
                decoration: const InputDecoration(
                  labelText: 'Ngân hàng nhận',
                  hintText: 'Ví dụ: Vietcombank, MBBank, Techcombank...',
                  prefixIcon: Icon(Icons.account_balance_rounded,
                      color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: account,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản',
                  prefixIcon:
                      Icon(Icons.credit_card_rounded, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản (in hoa không dấu)',
                  prefixIcon:
                      Icon(Icons.person_outline_rounded, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final value = num.tryParse(
                      amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
                  if (value == null || value <= 0) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Nhập số tiền hợp lệ.')),
                    );
                    return;
                  }
                  try {
                    await widget.api.requestWithdrawal(
                      amount: value,
                      bankName: bank.text.trim(),
                      bankAccountNo: account.text.trim(),
                      bankAccountName: name.text.trim(),
                    );
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    setState(_reload);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã gửi yêu cầu rút tiền.')),
                    );
                  } catch (error) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text(ApiMessages.friendly(error))),
                      );
                    }
                  }
                },
                child: const Text('Gửi yêu cầu rút tiền'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletData {
  const _WalletData({required this.wallet, required this.transactions});
  final Map<String, dynamic> wallet;
  final List<Map<String, dynamic>> transactions;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});
  final Map<String, dynamic> wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF0284C7)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: .3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'VÍ PAWCARE SECURE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified_user_rounded,
                  color: Color(0xFF5EEAD4), size: 18),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Số dư khả dụng',
            style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 13),
          ),
          const SizedBox(height: 3),
          Text(
            _money(wallet['availableBalance']),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock_rounded,
                    color: Color(0xFF5EEAD4), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đang tạm giữ Escrow',
                        style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 11),
                      ),
                      Text(
                        '${_money(wallet['lockedBalance'])} (chờ duyệt / dịch vụ đang chạy)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final type = '${item['type'] ?? ''}';
    final amount = _number(item['amount']);
    final refund = type == 'ESCROW_RELEASE' && amount > 0;
    final color = refund
        ? const Color(0xFF8B5CF6)
        : amount >= 0
            ? AppColors.success
            : AppColors.coral;
    final icon = refund
        ? Icons.replay_circle_filled_rounded
        : amount >= 0
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LiquidGlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        blur: 10,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['description'] ?? type}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _date(item['created_at'] ?? item['createdAt']),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${amount >= 0 ? '+' : '-'}${_money(amount.abs())}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.api});
  final PawCareApi api;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amount = TextEditingController(text: '100000');
  bool _loading = false;
  Map<String, dynamic>? _payment;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _createTopup() async {
    final value =
        num.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await widget.api.createWalletTopUp(value);
      if (!mounted) return;
      setState(() => _payment = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiMessages.friendly(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidModalSheet(
      title: 'Nạp tiền vào Ví',
      subtitle: 'Nạp tiền nhanh chóng qua VietQR tự động',
      child: _payment == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền nạp (VNĐ)',
                    prefixIcon: Icon(Icons.add_card_rounded,
                        color: AppColors.teal),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [50000, 100000, 200000, 500000].map((v) {
                    return ActionChip(
                      label: Text(_money(v)),
                      onPressed: () => setState(() => _amount.text = '$v'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _createTopup,
                  child: Text(_loading ? 'Đang tạo mã...' : 'Tạo mã VietQR'),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ('${_payment!['qrUrl'] ?? ''}'.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      '${_payment!['qrUrl']}',
                      height: 220,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Nội dung: ${_payment!['paymentCode'] ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xong'),
                ),
              ],
            ),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError({this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: AppColors.teal),
              const SizedBox(height: 12),
              const Text(
                'Chưa thể tải Ví PawCare',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
              ),
              const SizedBox(height: 8),
              Text(ApiMessages.friendly(error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
}

num _number(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
String _money(dynamic value) =>
    '${_number(value).round().toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}đ';
String _date(dynamic value) {
  final d = DateTime.tryParse('$value');
  if (d == null) return '$value';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
