import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../network/pawcare_api.dart';

class SessionStore {
  static const _access = 'pawcare.access_token';
  static const _refresh = 'pawcare.refresh_token';
  static const _profile = 'pawcare.profile';
  static const _apiUrl = 'pawcare.api_url';
  static const _dark = 'pawcare.dark_mode';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<AuthSession?> readSession() async {
    final prefs = await _prefs;
    final access = prefs.getString(_access);
    final refresh = prefs.getString(_refresh);
    final rawProfile = prefs.getString(_profile);
    if (access == null || refresh == null || rawProfile == null) return null;
    try {
      return AuthSession(
          accessToken: access,
          refreshToken: refresh,
          profile: Map<String, dynamic>.from(jsonDecode(rawProfile) as Map));
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(AuthSession session, String apiUrl) async {
    final prefs = await _prefs;
    await prefs.setString(_access, session.accessToken);
    await prefs.setString(_refresh, session.refreshToken);
    await prefs.setString(_profile, jsonEncode(session.profile));
    await prefs.setString(_apiUrl, apiUrl);
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_access),
      prefs.remove(_refresh),
      prefs.remove(_profile)
    ]);
  }

  Future<bool> readDarkMode() async => (await _prefs).getBool(_dark) ?? false;
  Future<void> saveDarkMode(bool value) async =>
      (await _prefs).setBool(_dark, value);
  Future<String?> readApiUrl() async => (await _prefs).getString(_apiUrl);
}
