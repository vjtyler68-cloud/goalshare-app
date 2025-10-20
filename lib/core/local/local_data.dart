import 'package:shared_preferences/shared_preferences.dart';

class LocalService {
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
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

  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userId, userId);
  }

  getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userId);
    return value;
  }

  Future<void> setOnboarding(bool onBoarding) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onBoarding, onBoarding);
  }

  getOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_onBoarding);
    return value;
  }

  Future<void> setPlanStatus(String planStatus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planStatus, planStatus);
  }

  getPlanStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_planStatus);
    return value;
  }

  Future<void> setUserAction(String userAction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userAction, userAction);
  }

  getUserAction() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userAction);
    return value;
  }
  static const String _schoolId = 'school_id';
  Future<void> setSchoolId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schoolId, id);
  }

  getSelectedSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_schoolId);
    return value;
  }

  Future<void> setPaymentKey(String paymentToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paymentToken, paymentToken);
  }

  getPaymentToken() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_paymentToken);
    return value;
  }

  // Set individual fields
  Future<void> setEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyEmail);
    return value;
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, password);
  }

  Future<void> setPhoneNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhoneNumber, phone);
  }

  getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyPhoneNumber);
    return token;
  }

  Future<void> setCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCountry, country);
  }

  Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyRole);
    return token;
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  getName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyName);
    return token;
  }

  Future<void> setUID(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userId, userId);
  }

  getUID() async {
    final prefs = await SharedPreferences.getInstance();
    final uId = prefs.getString(_userId);
    return uId;
  }

  Future<void> setImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImagePath, path);
  }

  getImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_keyImagePath);
    return imagePath;
  }

  getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyPhoneNumber);
    await prefs.remove(_keyCountry);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyImagePath);
    await prefs.remove(_keyToken);
    await prefs.remove(_paymentToken);
    await prefs.remove(_userId);
    await prefs.remove(_schoolId);
  }
}