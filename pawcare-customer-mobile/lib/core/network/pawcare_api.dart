import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class PawCareApiException implements Exception {
  PawCareApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession(
      {required this.accessToken,
      required this.refreshToken,
      required this.profile});
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> profile;
}

class PawCareApi {
  PawCareApi({String? baseUrl, http.Client? client})
      : baseUrl = (baseUrl ?? AppConfig.apiBaseUrl)
            .trim()
            .replaceFirst(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  String? _accessToken;

  void useToken(String? value) => _accessToken = value;
  void close() => _client.close();

  Future<AuthSession> login(
      {required String email, required String password}) async {
    final data = await post(
        '/auth/login', {'email': email, 'password': password},
        authenticated: false);
    return _session(data);
  }

  Future<AuthSession> registerCustomer(
      {required String fullName,
      required String email,
      required String password}) async {
    final data = await post(
        '/auth/register',
        {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': 'CUSTOMER'
        },
        authenticated: false);
    return _session(data);
  }

  Future<void> logout(String refreshToken) async {
    await post('/auth/logout', {'refreshToken': refreshToken},
        authenticated: false);
    _accessToken = null;
  }

  Future<List<Map<String, dynamic>>> listCareNotes() => list('/care-notes');

  Future<int> createCareNote({
    required String title,
    required String content,
    int? petId,
  }) async {
    final data = await post('/care-notes', {
      'title': title,
      'content': content,
      if (petId != null) 'petId': petId,
    });
    return int.parse('${data['id']}');
  }

  Future<void> deleteCareNote(int id) async {
    await delete('/care-notes/$id');
  }

  Future<List<Map<String, dynamic>>> list(String path) async {
    final data = await get(path);
    if (data is List)
      return data
          .cast<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    final rows = data is Map ? data['data'] : null;
    return rows is List
        ? rows.cast<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
        : [];
  }

  Future<dynamic> get(String path, {bool authenticated = true}) =>
      _request('GET', path, null, authenticated);
  Future<dynamic> post(String path, Map<String, dynamic> body,
          {bool authenticated = true}) =>
      _request('POST', path, body, authenticated);
  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body, true);
  Future<dynamic> delete(String path) => _request('DELETE', path, null, true);

  Future<dynamic> _request(String method, String path,
      Map<String, dynamic>? body, bool authenticated) async {
    if (baseUrl.isEmpty) {
      throw PawCareApiException(
          'Chưa cấu hình PawCare API. Kiểm tra assets/config/api.json.');
    }
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated && _accessToken != null)
      headers['Authorization'] = 'Bearer $_accessToken';
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    try {
      final response =
          await _client.send(request).then(http.Response.fromStream);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? (decoded['error'] ??
                decoded['message'] ??
                'Không thể xử lý yêu cầu')
            : 'Không thể xử lý yêu cầu';
        throw PawCareApiException(message.toString(), response.statusCode);
      }
      return decoded;
    } on PawCareApiException {
      rethrow;
    } catch (_) {
      throw PawCareApiException('Không thể kết nối PawCare API tại $baseUrl.');
    }
  }

  AuthSession _session(dynamic raw) {
    final data = Map<String, dynamic>.from(raw as Map);
    final session = AuthSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        profile: Map<String, dynamic>.from(data['profile'] as Map));
    useToken(session.accessToken);
    return session;
  }
}
