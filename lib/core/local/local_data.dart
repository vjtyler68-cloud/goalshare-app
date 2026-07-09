import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sensitive keys (token, payment token) → secure storage (device vault)
// Non-sensitive keys (name, email, role, etc.) → shared preferences
class LocalService {
  static const String _keyEmail = 'user_email';
  static const String _keyPhoneNumber = 'user_phone';
  static const String _keyCountry = 'user_country';
  static const String _keyRole = 'role';
  static const String _keyName = 'user_name';
  static const String _keyImagePath = 'user_image_path';
  static const String _keyToken = 'token';
  static const String _paymentToken = 'payment_token';
  static const String _userId = 'userId';
  static const String _planStatus = 'status';
  static const String _userAction = 'actions';
  static const String _onBoarding = 'onBoarding';
  static const String _schoolId = 'school_id';

  final _secure = const FlutterSecureStorage();

  // ── Secure: tokens ──────────────────────────────────────────────────────────

  Future<void> setToken(String token) async {
    await _secure.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return _secure.read(key: _keyToken);
  }

  Future<void> setPaymentKey(String paymentToken) async {
    await _secure.write(key: _paymentToken, value: paymentToken);
  }

  Future<String?> getPaymentToken() async {
    return _secure.read(key: _paymentToken);
  }

  // ── Non-sensitive: regular prefs ────────────────────────────────────────────

  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userId, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userId);
  }

  Future<void> setUID(String userId) => setUserId(userId);
  Future<String?> getUID() => getUserId();

  Future<void> setOnboarding(bool onBoarding) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onBoarding, onBoarding);
  }

  Future<bool?> getOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onBoarding);
  }

  Future<void> setPlanStatus(String planStatus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planStatus, planStatus);
  }

  Future<String?> getPlanStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_planStatus);
  }

  Future<void> setUserAction(String userAction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userAction, userAction);
  }

  Future<String?> getUserAction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAction);
  }

  Future<void> setSchoolId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schoolId, id);
  }

  Future<String?> getSelectedSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_schoolId);
  }

  Future<void> setEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<void> setPhoneNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhoneNumber, phone);
  }

  Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoneNumber);
  }

  Future<void> setCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCountry, country);
  }

  Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  Future<void> setImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImagePath, path);
  }

  Future<String?> getImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyImagePath);
  }

  Future<void> clearUserData() async {
    // Clear secure storage
    await _secure.delete(key: _keyToken);
    await _secure.delete(key: _paymentToken);

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhoneNumber);
    await prefs.remove(_keyCountry);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyImagePath);
    await prefs.remove(_userId);
    await prefs.remove(_schoolId);
  }
}
