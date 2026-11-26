bool isValidPassword(String value) =>
    value.length >= 10 &&
    RegExp(r'[A-Za-z]').hasMatch(value) &&
    RegExp(r'\d').hasMatch(value);

String? passwordValidationMessage(String? value) {
  if (!isValidPassword(value ?? '')) {
    return 'Mật khẩu cần ít nhất 10 ký tự, gồm chữ và số.';
  }
  return null;
}
