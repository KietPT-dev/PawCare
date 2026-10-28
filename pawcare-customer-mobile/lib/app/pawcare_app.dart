import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../core/network/pawcare_api.dart';
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

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PawCareApi();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawCare',
      theme: buildTheme(dark: _darkMode),
      home: _session != null
          ? CustomerShell(
              api: _api,
              session: _session!,
              darkMode: _darkMode,
              onThemeChanged: (value) => setState(() => _darkMode = value),
              onProfileUpdated: _profileUpdated,
              onLogout: _logout)
          : AuthScreen(onAuthenticated: _authenticated));

  Future<void> _authenticated(AuthForm form, bool register) async {
    final session = register
        ? await _api.registerCustomer(
            fullName: form.fullName, email: form.email, password: form.password)
        : await _api.login(email: form.email, password: form.password);
    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<void> _logout() async {
    final session = _session;
    if (session != null) {
      try {
        await _api.logout(session.refreshToken);
      } catch (_) {}
    }
    if (mounted) setState(() => _session = null);
  }

  void _profileUpdated(Map<String, dynamic> profile) {
    final current = _session;
    if (current == null) return;
    setState(() => _session = AuthSession(
        accessToken: current.accessToken,
        refreshToken: current.refreshToken,
        profile: profile));
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }
}
