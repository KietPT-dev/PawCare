import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../../auth/password_validation.dart';
import '../../auth/presentation/forgot_password_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../chat/presentation/chat_inbox_screen.dart';
import '../../pets/presentation/pets_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import 'help_center_screen.dart';
import 'settings_screen.dart';
import 'address_location_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.api,
    required this.darkMode,
    required this.onThemeChanged,
    required this.onProfileUpdated,
    required this.onLogout,
    this.unreadNotifications = 0,
    this.onNotificationsChanged,
  });

  final Map<String, dynamic> profile;
  final PawCareApi api;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<Map<String, dynamic>> onProfileUpdated;
  final VoidCallback onLogout;
  final int unreadNotifications;
  final VoidCallback? onNotificationsChanged;

  String get _name {
    final value =
        profile['fullName'] ?? profile['full_name'] ?? profile['name'];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString().trim()
        : 'Khách hàng PawCare';
  }

  String get _email => (profile['email'] ?? '').toString();
  bool get _emailVerified =>
      profile['emailVerified'] == true || profile['email_verified'] == true;

  String get _initials => _name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidAmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // ── Header Profile Card ──
              LiquidGlassCard(
                radius: 28,
                padding: const EdgeInsets.all(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.teal.withValues(alpha: isDark ? .28 : .14),
                    AppColors.cyan.withValues(alpha: isDark ? .10 : .05),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.teal, AppColors.cyan],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: .24),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.mint,
                        child: Text(
                          _initials.isEmpty ? 'PC' : _initials,
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w900,
                              fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _email.isEmpty ? 'Chưa có email' : _email,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.teal.withValues(alpha: .28)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded,
                              size: 14, color: AppColors.teal),
                          SizedBox(width: 4),
                          Text(
                            'Thành viên PawCare VIP',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Nhóm Tài khoản (Hình 5) ──
              const SectionTitle('Tài khoản'),
              LiquidGlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _ProfileMenuTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.teal,
                      iconBg: AppColors.teal.withValues(alpha: .12),
                      title: 'Thông tin cá nhân',
                      subtitle: 'Tên và email đăng ký',
                      onTap: () => _profileInfo(context),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.coral,
                      iconBg: AppColors.coral.withValues(alpha: .12),
                      title: 'Địa chỉ & vị trí',
                      subtitle:
                          '${profile['address'] ?? profile['addressLine1'] ?? 'Chưa thiết lập địa chỉ'}',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddressLocationScreen(
                                  api: api,
                                  profile: profile,
                                  onUpdated: onProfileUpdated))),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: AppColors.teal,
                      iconBg: AppColors.teal.withValues(alpha: .12),
                      title: 'Tin nhắn với cơ sở',
                      subtitle: 'Trao đổi trực tiếp theo từng lịch hẹn',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatInboxScreen(api: api),
                          )),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFF0284C7).withValues(alpha: .12),
                      title: 'Ví của tôi',
                      subtitle: 'Số dư, nạp/rút tiền và lịch sử',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => WalletScreen(api: api)),
                      ),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.pets_rounded,
                      iconColor: AppColors.coral,
                      iconBg: AppColors.coral.withValues(alpha: .12),
                      title: 'Quản lý thú cưng',
                      subtitle: 'Hồ sơ, chủng ngừa và thói quen',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PetsScreen(api: api)),
                      ),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.settings_outlined,
                      iconColor: const Color(0xFF6366F1),
                      iconBg: const Color(0xFF6366F1).withValues(alpha: .12),
                      title: 'Cài đặt',
                      subtitle: 'Chế độ tối, thông báo và bảo mật',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            darkMode: darkMode,
                            onThemeChanged: onThemeChanged,
                          ),
                        ),
                      ),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBg: const Color(0xFF8B5CF6).withValues(alpha: .12),
                      title: 'Đổi mật khẩu',
                      subtitle: 'Cập nhật mật khẩu bảo mật cao',
                      onTap: () => _changePassword(context),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: _emailVerified
                          ? Icons.verified_rounded
                          : Icons.mark_email_read_outlined,
                      iconColor: AppColors.success,
                      iconBg: AppColors.success.withValues(alpha: .12),
                      title: _emailVerified
                          ? 'Email đã xác minh'
                          : 'Xác minh email',
                      subtitle: _emailVerified
                          ? 'Tài khoản của bạn đã được xác thực'
                          : 'Gửi liên kết xác minh đến email',
                      onTap:
                          _emailVerified ? null : () => _verifyEmail(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Nhóm Hỗ trợ (Hình 5) ──
              const SectionTitle('Hỗ trợ'),
              LiquidGlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _ProfileMenuTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFF59E0B).withValues(alpha: .12),
                      title: 'Thông báo & nhắc lịch',
                      subtitle: 'Xem toàn bộ lịch sử thông báo',
                      badge: unreadNotifications > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadNotifications',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(
                            api: api,
                            onChanged: onNotificationsChanged ?? () {},
                          ),
                        ),
                      ),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.report_problem_outlined,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFEF4444).withValues(alpha: .12),
                      title: 'Gửi khiếu nại',
                      subtitle: 'Bảo vệ quyền lợi khách hàng 24/7',
                      onTap: () => _complaint(context),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      iconBg: const Color(0xFF06B6D4).withValues(alpha: .12),
                      title: 'Trung tâm trợ giúp',
                      subtitle: 'Hướng dẫn sử dụng & câu hỏi thường gặp',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpCenterScreen()),
                      ),
                    ),
                    const _MenuDivider(),
                    _ProfileMenuTile(
                      icon: Icons.key_rounded,
                      iconColor: const Color(0xFF64748B),
                      iconBg: const Color(0xFF64748B).withValues(alpha: .12),
                      title: 'Quên mật khẩu',
                      subtitle: 'Yêu cầu liên kết đặt lại qua email',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                  initialEmail: _email, api: api))),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Nút Đăng xuất ──
              LiquidGlassCard(
                radius: 18,
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: AppColors.coral, size: 20),
                  ),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.coral,
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.coral, size: 20),
                  onTap: onLogout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheet: Thông tin cá nhân (Hình 4) ──
  void _profileInfo(BuildContext context) {
    final name = TextEditingController(text: _name);
    final email = TextEditingController(text: _email);
    final phone = TextEditingController(text: '${profile['phone'] ?? ''}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LiquidModalSheet(
        title: 'Thông tin cá nhân',
        subtitle: 'Cập nhật tên, email và số điện thoại liên hệ',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon:
                      Icon(Icons.person_outline_rounded, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon:
                      Icon(Icons.mail_outline_rounded, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  try {
                    final updated = await api.put('/auth/me', {
                      'fullName': name.text.trim(),
                      'email': email.text.trim(),
                      'phone': phone.text.trim(),
                    });
                    if (!sheetContext.mounted) return;
                    onProfileUpdated(updated);
                    Navigator.pop(sheetContext);
                    _unavailable(
                        context, 'Đã cập nhật thông tin cá nhân thành công.');
                  } catch (e) {
                    if (sheetContext.mounted) {
                      _unavailable(sheetContext, ApiMessages.friendly(e));
                    }
                  }
                },
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _unavailable(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  // ── Sheet: Đổi mật khẩu ──
  void _changePassword(BuildContext context) {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final form = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LiquidModalSheet(
        title: 'Đổi mật khẩu',
        subtitle: 'Bảo vệ tài khoản PawCare an toàn hơn',
        child: SingleChildScrollView(
          child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          color: AppColors.teal),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      hintText: 'Tối thiểu 10 ký tự gồm chữ và số',
                      prefixIcon:
                          Icon(Icons.lock_rounded, color: AppColors.teal),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        prefixIcon:
                            Icon(Icons.lock_rounded, color: AppColors.teal)),
                    validator: (value) => value == next.text
                        ? null
                        : 'Mật khẩu xác nhận chưa khớp.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.teal),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mật khẩu mới cần ít nhất 10 ký tự, bao gồm cả chữ và số.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      if (!(form.currentState?.validate() ?? false) ||
                          !isValidPassword(next.text)) {
                        _unavailable(sheetContext,
                            'Mật khẩu mới cần ít nhất 10 ký tự, gồm chữ và số.');
                        return;
                      }
                      try {
                        await api.put('/auth/password', {
                          'currentPassword': current.text,
                          'newPassword': next.text,
                        });
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                          onLogout();
                          _unavailable(context,
                              'Đổi mật khẩu thành công. Hãy đăng nhập lại.');
                        }
                      } catch (e) {
                        if (sheetContext.mounted) {
                          _unavailable(sheetContext, ApiMessages.friendly(e));
                        }
                      }
                    },
                    child: const Text('Cập nhật mật khẩu'),
                  ),
                ],
              )),
        ),
      ),
    );
  }

  // ── Sheet: Xác minh email ──
  void _verifyEmail(BuildContext context) {
    final code = TextEditingController();
    bool sending = false;
    bool sent = false;
    bool confirming = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
          builder: (sheet, setSheetState) => LiquidModalSheet(
                title: 'Xác minh email',
                subtitle:
                    'Xác thực tài khoản để nhận đầy đủ quyền lợi thành viên',
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read_rounded,
                                color: AppColors.teal, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                sent
                                    ? 'Nhập mã xác minh 6 chữ số vừa được gửi tới email đăng ký của bạn.'
                                    : 'Chúng tôi sẽ gửi mã xác minh 6 chữ số tới email đăng ký của bạn.',
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            TextButton(
                              onPressed: sending || confirming
                                  ? null
                                  : () async {
                                      setSheetState(() => sending = true);
                                      try {
                                        await api.requestEmailVerification();
                                        if (sheet.mounted) {
                                          setSheetState(() => sent = true);
                                        }
                                      } catch (e) {
                                        if (sheet.mounted) {
                                          _unavailable(
                                              sheet, ApiMessages.friendly(e));
                                        }
                                      } finally {
                                        if (sheet.mounted) {
                                          setSheetState(() => sending = false);
                                        }
                                      }
                                    },
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(sending ? 'Đang gửi' : 'Gửi email',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      if (sent) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: code,
                          enabled: !confirming,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Mã xác minh 6 chữ số',
                            hintText: 'Ví dụ: 123456',
                            prefixIcon: Icon(Icons.password_rounded),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: confirming
                              ? null
                              : () async {
                                  final value =
                                      code.text.replaceAll(RegExp(r'\D'), '');
                                  if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                                    _unavailable(
                                        sheet, 'Vui lòng nhập đủ mã 6 chữ số.');
                                    return;
                                  }
                                  setSheetState(() => confirming = true);
                                  try {
                                    await api.confirmEmailVerification(value);
                                    final updated = await api.currentProfile();
                                    onProfileUpdated(updated);
                                    if (sheet.mounted) {
                                      Navigator.of(sheet).pop();
                                    }
                                  } catch (e) {
                                    if (sheet.mounted) {
                                      _unavailable(
                                          sheet, ApiMessages.friendly(e));
                                    }
                                  } finally {
                                    if (sheet.mounted) {
                                      setSheetState(() => confirming = false);
                                    }
                                  }
                                },
                          icon: confirming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.verified_rounded),
                          label: Text(
                              confirming ? 'Đang xác minh' : 'Xác minh email'),
                        ),
                      ],
                    ])),
              )),
    ).whenComplete(code.dispose);
  }

  // ── Sheet: Gửi khiếu nại ──
  void _complaint(BuildContext context) {
    final booking = TextEditingController();
    final content = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LiquidModalSheet(
        title: 'Gửi khiếu nại',
        subtitle: 'PawCare tiếp nhận và xử lý sự cố trong vòng 24h',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.teal.withValues(alpha: .2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: AppColors.teal, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tiền thanh toán được bảo lưu an toàn bởi hệ thống Escrow Protection cho đến khi dịch vụ hoàn tất thoả đáng.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: booking,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mã đơn / Booking ID',
                  hintText: 'Ví dụ: 10',
                  prefixIcon: Icon(Icons.tag_rounded, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: content,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Nội dung khiếu nại',
                  hintText:
                      'Mô tả chi tiết vấn đề phát sinh với bé hoặc dịch vụ...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
                onPressed: () async {
                  try {
                    await api.post('/complaints', {
                      'bookingId': int.tryParse(booking.text),
                      'content': content.text.trim(),
                    });
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                      _unavailable(context,
                          'Đã gửi khiếu nại. PawCare sẽ liên hệ bạn sớm nhất.');
                    }
                  } catch (e) {
                    if (sheetContext.mounted) {
                      _unavailable(sheetContext, e.toString());
                    }
                  }
                },
                child: const Text('Gửi khiếu nại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              badge!,
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: isDark
          ? const Color(0xFF334155).withValues(alpha: .6)
          : const Color(0xFFF1F5F9),
    );
  }
}
