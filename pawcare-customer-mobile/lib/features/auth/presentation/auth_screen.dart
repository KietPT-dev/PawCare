import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthForm {
  const AuthForm(
      {required this.fullName, required this.email, required this.password});
  final String fullName;
  final String email;
  final String password;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});
  final Future<void> Function(AuthForm form, bool register) onAuthenticated;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _register = false, _hide = true, _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE6F9FA), Color(0xFFF8FCFC)])),
          child: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AutofillGroup(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Center(
                          child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                      colors: [AppColors.teal, AppColors.cyan]),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppColors.teal
                                            .withValues(alpha: .22),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12))
                                  ]),
                              child: const Icon(Icons.pets_rounded,
                                  color: Colors.white, size: 52))),
                      const SizedBox(height: 26),
                      Text('PawCare',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .3)),
                      const SizedBox(height: 10),
                      Text(
                          _register
                              ? 'Tạo tài khoản\ncho bé yêu'
                              : 'Mọi nhu cầu của bé,\nmột nơi',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700, height: 1.12)),
                      const SizedBox(height: 12),
                      Text(
                          _register
                              ? 'Bắt đầu hành trình chăm sóc bé thật dễ dàng.'
                              : 'Đăng nhập để quản lý thú cưng, lịch hẹn và ví PawCare.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.45)),
                      const SizedBox(height: 28),
                      Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .92),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x1200343E),
                                    blurRadius: 24,
                                    offset: Offset(0, 10))
                              ]),
                          child: Form(
                              key: _form,
                              child: Column(children: [
                                if (_register) ...[
                                  _InputField(
                                      controller: _name,
                                      label: 'Họ và tên',
                                      icon: Icons.person_outline,
                                      autofillHints: const [AutofillHints.name],
                                      textInputAction: TextInputAction.next,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Nhập họ tên'
                                              : null),
                                  const SizedBox(height: 14)
                                ],
                                _InputField(
                                    key: const ValueKey('auth-email'),
                                    controller: _email,
                                    focusNode: _emailFocus,
                                    label: 'Email',
                                    icon: Icons.mail_outline,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
                                    validator: (v) =>
                                        v != null && v.trim().contains('@')
                                            ? null
                                            : 'Email chưa hợp lệ'),
                                const SizedBox(height: 14),
                                _InputField(
                                    key: const ValueKey('auth-password'),
                                    controller: _password,
                                    focusNode: _passwordFocus,
                                    label: 'Mật khẩu',
                                    icon: Icons.lock_outline,
                                    obscureText: _hide,
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) =>
                                        _busy ? null : _submit(),
                                    suffix: IconButton(
                                        onPressed: () =>
                                            setState(() => _hide = !_hide),
                                        icon: Icon(_hide
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined)),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Nhập mật khẩu';
                                      if (_register &&
                                          (v.length < 10 ||
                                              !RegExp(r'[A-Za-z]')
                                                  .hasMatch(v) ||
                                              !RegExp(r'\d').hasMatch(v)))
                                        return 'Ít nhất 10 ký tự, gồm chữ và số';
                                      return null;
                                    }),
                                const SizedBox(height: 20),
                                SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: FilledButton(
                                        onPressed: _busy ? null : _submit,
                                        style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.teal,
                                            elevation: 3),
                                        child: _busy
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5))
                                            : Text(_register
                                                ? 'Tạo tài khoản'
                                                : 'Đăng nhập'))),
                              ]))),
                      if (_error != null)
                        Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFE9E6),
                                borderRadius: BorderRadius.circular(16)),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    fontWeight: FontWeight.w600))),
                      const SizedBox(height: 18),
                      TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _register = !_register;
                                    _error = null;
                                  }),
                          child: Text(_register
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký ngay')),
                    ]))),
          ))),
        ),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onAuthenticated(
          AuthForm(
              fullName: _name.text.trim(),
              email: _email.text.trim(),
              password: _password.text),
          _register);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}

class _InputField extends StatefulWidget {
  const _InputField(
      {super.key,
      required this.controller,
      this.focusNode,
      required this.label,
      required this.icon,
      this.keyboardType,
      this.autofillHints,
      this.textInputAction,
      this.onSubmitted,
      this.validator,
      this.obscureText = false,
      this.suffix});
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;
  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _ownsFocus = false;
  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.focusNode == null;
    _focus.addListener(_focused);
  }

  void _focused() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: _focus.hasFocus
              ? [
                  BoxShadow(
                      color: AppColors.teal.withValues(alpha: .12),
                      blurRadius: 16)
                ]
              : const []),
      child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          obscureText: widget.obscureText,
          enableSuggestions: !widget.obscureText,
          autocorrect: !widget.obscureText,
          decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(widget.icon),
              suffixIcon: widget.suffix)));
  @override
  void dispose() {
    _focus.removeListener(_focused);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }
}
