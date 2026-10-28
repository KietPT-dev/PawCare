/// API endpoint selection for PawCare.
///
/// The local development environment deliberately uses one stable endpoint.
/// Customers never see or enter this address. A release build can replace it
/// through `--dart-define=PAWCARE_API_URL=https://api.example.com/api/v1`.
class AppConfig {
  const AppConfig._();

  static const _buildTimeApiUrl = String.fromEnvironment('PAWCARE_API_URL');
  static const _localDevelopmentApiUrl = 'http://127.0.0.1:8081/api/v1';

  static String get apiBaseUrl => _normalize(
      _buildTimeApiUrl.isNotEmpty ? _buildTimeApiUrl : _localDevelopmentApiUrl);

  static String _normalize(String value) =>
      value.trim().replaceFirst(RegExp(r'/+$'), '');
}
