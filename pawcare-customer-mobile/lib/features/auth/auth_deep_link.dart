enum AuthDeepLinkKind { verifyEmail, resetPassword }

class AuthDeepLink {
  const AuthDeepLink(this.kind, this.token);
  final AuthDeepLinkKind kind;
  final String token;

  static AuthDeepLink? parse(Uri uri) {
    if (uri.scheme != 'pawcare' || uri.host != 'auth') return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return switch (uri.path) {
      '/verify-email' => AuthDeepLink(AuthDeepLinkKind.verifyEmail, token),
      '/reset-password' => AuthDeepLink(AuthDeepLinkKind.resetPassword, token),
      _ => null,
    };
  }
}
