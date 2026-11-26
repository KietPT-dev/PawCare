import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/auth_deep_link.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../core/network/pawcare_api.dart';
import '../core/storage/session_store.dart';
import 'customer_shell.dart';

class PawCareApp extends StatefulWidget {
  const PawCareApp({super.key, this.api});
  final PawCareApi? api;
  @override
  State<PawCareApp> createState() => _PawCareAppState();
}

class _PawCareAppState extends State<PawCareApp> {
  late PawCareApi _api;
  AuthSession? _session;
  bool _darkMode = false;
  bool _ready = false;
  final _store = SessionStore();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  AuthDeepLink? _pendingLink;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PawCareApi();
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen(_receiveLink);
    _restore();
    _readInitialLink();
  }

  Future<void> _readInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _receiveLink(uri);
  }

  void _receiveLink(Uri uri) {
    final link = AuthDeepLink.parse(uri);
    if (link == null)
      return _showMessage('Liên kết không hợp lệ hoặc đã thiếu thông tin.');
    _pendingLink = link;
    _openPendingLink();
  }

  Future<void> _openPendingLink() async {
    if (!_ready || _pendingLink == null) return;
    final link = _pendingLink!;
    _pendingLink = null;
    if (link.kind == AuthDeepLinkKind.resetPassword) {
      final result = await _navigatorKey.currentState?.push<bool>(
          MaterialPageRoute(
              builder: (_) =>
                  ResetPasswordScreen(api: _api, token: link.token)));
      if (result == true)
        _showMessage('Đặt lại mật khẩu thành công. Hãy đăng nhập.');
      return;
    }
    if (_session == null)
      return _showMessage('Hãy đăng nhập để xác minh email của bạn.');
    try {
      await _api.confirmEmailVerification(link.token);
      _profileUpdated(
          Map<String, dynamic>.from(await _api.get('/auth/me') as Map));
      _showMessage('Email của bạn đã được xác minh.');
    } catch (_) {
      _showMessage('Liên kết xác minh không hợp lệ hoặc đã hết hạn.');
    }
  }

  void _showMessage(String message) {
    final context = _navigatorKey.currentContext;
    if (context != null)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restore() async {
    try {
      final dark = await _store.readDarkMode();
      final savedUrl = await _store.readApiUrl();
      if (savedUrl != null && widget.api == null) _api.useBaseUrl(savedUrl);
      final saved = await _store.readSession();
      AuthSession? renewed;
      if (saved != null) renewed = await _api.refresh(saved.refreshToken);
      if (!mounted) return;
      setState(() {
        _darkMode = dark;
        _session = renewed;
        _ready = true;
      });
      if (renewed != null) await _store.saveSession(renewed, _api.baseUrl);
      _openPendingLink();
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PawCare',
      theme: buildTheme(dark: _darkMode),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _session != null
              ? CustomerShell(
                  api: _api,
                  session: _session!,
                  darkMode: _darkMode,
                  onThemeChanged: _setTheme,
                  onProfileUpdated: _profileUpdated,
                  onLogout: _logout)
              : AuthScreen(api: _api, onAuthenticated: _authenticated));

  Future<void> _authenticated(AuthForm form, bool register) async {
    final session = register
        ? await _api.registerCustomer(
            fullName: form.fullName, email: form.email, password: form.password)
        : await _api.login(email: form.email, password: form.password);
    if (!mounted) return;
    setState(() => _session = session);
    await _store.saveSession(session, _api.baseUrl);
  }

  Future<void> _logout() async {
    final session = _session;
    if (session != null) {
      try {
        await _api.logout(session.refreshToken);
      } catch (_) {}
    }
    if (mounted) setState(() => _session = null);
    _api.useToken(null);
    await _store.clearSession();
  }

  void _profileUpdated(Map<String, dynamic> profile) {
    final current = _session;
    if (current == null) return;
    setState(() => _session = AuthSession(
        accessToken: current.accessToken,
        refreshToken: current.refreshToken,
        profile: profile));
    _store.saveSession(_session!, _api.baseUrl);
  }

  void _setTheme(bool value) {
    setState(() => _darkMode = value);
    _store.saveDarkMode(value);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _api.close();
    super.dispose();
  }
}
