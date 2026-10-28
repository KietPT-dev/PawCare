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
  bool _register = false;
  bool _hide = true;
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.pets_rounded,
                        color: AppColors.teal, size: 34),
                  ),
                  const SizedBox(height: 26),
                  Text('PawCare',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.teal, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                      _register
                          ? 'Tạo tài khoản\ncho bé yêu'
                          : 'Mọi nhu cầu\ncủa bé, một nơi',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 12),
                  Text(
                      _register
                          ? 'Tìm đối tác uy tín và quản lý lịch hẹn của thú cưng.'
                          : 'Đăng nhập để quản lý thú cưng, lịch hẹn và chăm sóc mỗi ngày.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.45)),
                  const SizedBox(height: 30),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(children: [
                          if (_register) ...[
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                  labelText: 'Họ và tên',
                                  prefixIcon: Icon(Icons.person_outline)),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Nhập họ tên' : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline)),
                            validator: (v) => v != null && v.contains('@')
                                ? null
                                : 'Email chưa hợp lệ',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _hide,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_hide
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _hide = !_hide),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Nhập mật khẩu';
                              if (_register &&
                                  (v.length < 10 ||
                                      !RegExp(r'[A-Za-z]').hasMatch(v) ||
                                      !RegExp(r'\d').hasMatch(v))) {
                                return 'Đăng ký mới cần ít nhất 10 ký tự, gồm chữ và số';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: Text(_busy
                                  ? 'Đang xử lý...'
                                  : (_register ? 'Đăng ký' : 'Đăng nhập')),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFE9E6),
                          borderRadius: BorderRadius.circular(14)),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 22),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _register = !_register;
                                _error = null;
                              }),
                      child: Text(_register
                          ? 'Đã có tài khoản? Đăng nhập'
                          : 'Chưa có tài khoản? Đăng ký ngay'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
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
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
