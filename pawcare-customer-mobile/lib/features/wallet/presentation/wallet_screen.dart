import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/network/api_messages.dart';

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ví PawCare'),
          actions: [
            IconButton(
                onPressed: () => setState(_reload),
                icon: const Icon(Icons.refresh))
          ],
        ),
        body: FutureBuilder<_WalletData>(
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    _BalanceCard(wallet: data.wallet),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                        onPressed: () => _showTopUp(context),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Nạp tiền'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton.icon(
                        onPressed: () => _withdraw(context),
                        icon: const Icon(Icons.account_balance_outlined),
                        label: const Text('Rút tiền'),
                      )),
                    ]),
                    SectionTitle('Lịch sử biến động',
                        action: _filter,
                        onAction: () => _chooseFilter(context)),
                    if (_filtered(data.transactions).isEmpty)
                      const InfoCard(
                          child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: Text('Chưa có giao dịch nào.')),
                      ))
                    else
                      ..._filtered(data.transactions)
                          .map((item) => _TransactionRow(item: item)),
                  ]),
            );
          },
        ),
      );

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> items) =>
      _filter == 'Tất cả'
          ? items
          : items.where((x) => '${x['type']}' == _filter).toList();
  Future<void> _chooseFilter(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => ListView(
            shrinkWrap: true,
            children: [
              'Tất cả',
              'DEPOSIT',
              'ESCROW_HOLD',
              'ESCROW_RELEASE',
              'WITHDRAWAL'
            ]
                .map((x) => ListTile(
                    title: Text(x == 'Tất cả' ? x : x.replaceAll('_', ' ')),
                    onTap: () => Navigator.pop(context, x)))
                .toList()));
    if (value != null && mounted) setState(() => _filter = value);
  }

  Future<void> _showTopUp(BuildContext context) async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, 24 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Yêu cầu rút tiền',
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Số tiền muốn rút (VNĐ)')),
          const SizedBox(height: 10),
          TextField(
              controller: bank,
              decoration: const InputDecoration(labelText: 'Ngân hàng')),
          const SizedBox(height: 10),
          TextField(
              controller: account,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tài khoản')),
          const SizedBox(height: 10),
          TextField(
              controller: name,
              textCapitalization: TextCapitalization.characters,
              decoration:
                  const InputDecoration(labelText: 'Tên chủ tài khoản')),
          const SizedBox(height: 18),
          FilledButton(
              onPressed: () async {
                final value = num.tryParse(
                    amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Nhập số tiền hợp lệ.')));
                  return;
                }
                try {
                  await widget.api.requestWithdrawal(
                      amount: value,
                      bankName: bank.text.trim(),
                      bankAccountNo: account.text.trim(),
                      bankAccountName: name.text.trim());
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  setState(_reload);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Đã gửi yêu cầu rút tiền.')));
                } catch (error) {
                  if (sheetContext.mounted)
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text(ApiMessages.friendly(error))));
                }
              },
              child: const Text('Gửi yêu cầu')),
        ])),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [AppColors.navy, AppColors.teal]),
            borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text('VÍ PAWCARE',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800))
          ]),
          const SizedBox(height: 24),
          const Text('Số dư khả dụng',
              style: TextStyle(color: Color(0xFFD7F8FF))),
          Text(_money(wallet['availableBalance']),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 31)),
          const SizedBox(height: 14),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.lock_clock_outlined, color: Color(0xFFD7F8FF)),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Đang tạm giữ',
                          style: TextStyle(
                              color: Color(0xFFD7F8FF), fontSize: 12)),
                      Text(
                          '${_money(wallet['lockedBalance'])} · chờ tiệm duyệt/đang thực hiện',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ])),
              ])),
        ]),
      );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final type = '${item['type'] ?? ''}';
    final amount = _number(item['amount']);
    final refund = type == 'ESCROW_RELEASE' && amount > 0;
    final color = refund
        ? Colors.deepPurple
        : amount >= 0
            ? AppColors.success
            : AppColors.coral;
    final icon = refund
        ? Icons.replay_circle_filled_outlined
        : amount >= 0
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;
    return Card(
        child: ListTile(
      leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color)),
      title: Text('${item['description'] ?? type}',
          maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(_date(item['created_at'] ?? item['createdAt'])),
      trailing: Text('${amount >= 0 ? '+' : '-'}${_money(amount.abs())}',
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    ));
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: AppColors.teal),
            const SizedBox(height: 12),
            const Text('Chưa thể tải Ví PawCare',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
            const SizedBox(height: 8),
            Text(ApiMessages.friendly(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ])));
}

num _number(dynamic value) =>
    value is num ? value : num.tryParse('$value') ?? 0;
String _money(dynamic value) =>
    '${_number(value).round().toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}đ';
String _date(dynamic value) {
  final parsed = DateTime.tryParse('$value');
  return parsed == null
      ? ''
      : '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.api});
  final PawCareApi api;
  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amount = TextEditingController();
  Map<String, dynamic>? _deposit;
  Timer? _poll;
  bool _loading = false;

  @override
  void dispose() {
    _poll?.cancel();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final amount =
        num.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nhập số tiền hợp lệ.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final deposit = await widget.api.createWalletTopUp(amount);
      if (!mounted) return;
      setState(() => _deposit = deposit);
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _check() async {
    final id = _deposit?['paymentDepositId'];
    if (id == null) return;
    try {
      final fresh = await widget.api.walletTopUpStatus((id as num).toInt());
      if (fresh['status'] == 'PAID' && mounted) {
        _poll?.cancel();
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Continue polling after a transient network failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final deposit = _deposit;
    if (deposit == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            24, 8, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.qr_code_2, size: 52, color: AppColors.teal),
          const SizedBox(height: 8),
          const Text('Nạp tiền vào ví',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Số tiền nạp (VNĐ)')),
          const SizedBox(height: 14),
          FilledButton(
              onPressed: _loading ? null : _create,
              child: Text(_loading ? 'Đang tạo mã...' : 'Tạo mã VietQR')),
        ]),
      );
    }
    final qr = '${deposit['qrUrl'] ?? ''}';
    final code = '${deposit['paymentCode']}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Quét VietQR để nạp tiền',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        if (qr.isNotEmpty)
          Image.network(qr,
              height: 220,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, size: 100))
        else
          const Icon(Icons.qr_code_2, size: 150),
        const SizedBox(height: 10),
        Text('Nội dung: $code',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Đã sao chép nội dung chuyển khoản.')));
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Sao chép nội dung')),
        const Text('Số dư sẽ tự cập nhật ngay sau khi ngân hàng xác nhận.',
            textAlign: TextAlign.center),
        TextButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.refresh),
            label: const Text('Kiểm tra ngay')),
      ]),
    );
  }
}
