import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing authentication tokens
class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  /// Save authentication token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Save token expiry timestamp
  Future<void> saveTokenExpiry(DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenExpiryKey, expiry.millisecondsSinceEpoch);
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTimestamp = prefs.getInt(_tokenExpiryKey);

    if (expiryTimestamp == null) return true;

    final expiryDate =
        DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    return DateTime.now().isAfter(expiryDate);
  }

  /// Check if user has valid token
  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    return !(await isTokenExpired());
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  /// Clear all authentication data
  Future<void> clearAll() async {
    await clearTokens();
    // Add any other auth-related data cleanup here
  }
}
