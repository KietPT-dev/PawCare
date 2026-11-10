import 'pawcare_api.dart';

class ApiMessages {
  const ApiMessages._();
  static String friendly(Object? error,
      {String fallback = 'Không thể hoàn tất yêu cầu. Vui lòng thử lại.'}) {
    if (error is PawCareApiException) {
      if (error.statusCode == 401)
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      if (error.statusCode == 403)
        return 'Bạn không có quyền thực hiện thao tác này.';
      if (error.statusCode == 409) return error.message;
      return error.message.isEmpty ? fallback : error.message;
    }
    return fallback;
  }
}
