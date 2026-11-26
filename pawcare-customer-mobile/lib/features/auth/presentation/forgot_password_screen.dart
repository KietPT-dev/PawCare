import 'package:flutter/material.dart';

import '../../../core/network/api_messages.dart';
import '../../../core/network/pawcare_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen(
      {super.key, this.initialEmail = '', required this.api});
  final String initialEmail;
  final PawCareApi? api;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _busy = false;
  bool _sent = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (!(_formKey.currentState?.validate() ?? false) || widget.api == null)
      return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api!.requestPasswordReset(_email.text.trim());
      if (mounted)
        setState(() {
          _busy = false;
          _sent = true;
        });
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
            title: const Text('Quên mật khẩu')),
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
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.lock_reset_rounded,
                              size: 48, color: AppColors.teal),
                          const SizedBox(height: 16),
                          Text(_sent ? 'Kiểm tra hộp thư' : 'Đặt lại mật khẩu',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Text(
                              _sent
                                  ? 'Nếu email tồn tại, PawCare đã gửi hướng dẫn đặt lại mật khẩu.'
                                  : 'Nhập email đăng ký. Chúng tôi sẽ gửi liên kết đặt lại mật khẩu nếu tài khoản tồn tại.',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 22),
                          TextFormField(
                              key: const ValueKey('reset-email'),
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined)),
                              validator: (value) =>
                                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(value?.trim() ?? '')
                                      ? null
                                      : 'Nhập email hợp lệ.'),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: AppColors.coral))
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: _busy ? null : _request,
                              child: _busy
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text(_sent
                                      ? 'Gửi lại email'
                                      : 'Gửi hướng dẫn')),
                          if (_sent)
                            const Padding(
                                padding: EdgeInsets.only(top: 14),
                                child: Text(
                                    'Mở liên kết trong email trên thiết bị này để tạo mật khẩu mới.',
                                    textAlign: TextAlign.center)),
                        ])),
              )),
        )))),
      );
}
