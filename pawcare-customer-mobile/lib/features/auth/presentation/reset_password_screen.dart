import 'package:flutter/material.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../password_validation.dart';
import 'forgot_password_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen(
      {super.key, required this.api, required this.token});
  final PawCareApi api;
  final String token;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.resetPassword(widget.token, _password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = ApiMessages.friendly(error);
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Đặt lại mật khẩu')),
      body: LiquidAmbientBackground(
          child: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: LiquidGlassCard(
                              radius: 28,
                              padding: const EdgeInsets.all(22),
                              child: Form(
                                  key: _form,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Icon(Icons.lock_reset_rounded,
                                            color: AppColors.teal, size: 48),
                                        const SizedBox(height: 16),
                                        Text('Tạo mật khẩu mới',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800)),
                                        const SizedBox(height: 8),
                                        const Text(
                                            'Dùng ít nhất 10 ký tự, gồm cả chữ và số.',
                                            textAlign: TextAlign.center),
                                        const SizedBox(height: 22),
                                        TextFormField(
                                            controller: _password,
                                            obscureText: true,
                                            enabled: !_busy,
                                            decoration: const InputDecoration(
                                                labelText: 'Mật khẩu mới',
                                                prefixIcon:
                                                    Icon(Icons.lock_outline)),
                                            validator:
                                                passwordValidationMessage),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                            controller: _confirm,
                                            obscureText: true,
                                            enabled: !_busy,
                                            decoration: const InputDecoration(
                                                labelText: 'Xác nhận mật khẩu',
                                                prefixIcon:
                                                    Icon(Icons.lock_outline)),
                                            validator: (value) => value ==
                                                    _password.text
                                                ? null
                                                : 'Mật khẩu xác nhận chưa khớp.'),
                                        if (_error != null) ...[
                                          const SizedBox(height: 12),
                                          Text(_error!,
                                              style: const TextStyle(
                                                  color: AppColors.coral))
                                        ],
                                        const SizedBox(height: 20),
                                        FilledButton(
                                            onPressed: _busy ? null : _submit,
                                            child: _busy
                                                ? const SizedBox.square(
                                                    dimension: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))
                                                : const Text(
                                                    'Đặt lại mật khẩu')),
                                        TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            ForgotPasswordScreen(
                                                                api: widget
                                                                    .api))),
                                            child: const Text('Gửi lại email')),
                                      ])))))))));
}
