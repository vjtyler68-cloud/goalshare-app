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

  // ── Notification preferences ────────────────────────────────────────────────
  // Master defaults OFF (opt-in, so we never prompt for permission until asked);
  // individual reminder types default ON once the master is enabled.
  static const String _notifEnabled = 'notif_enabled';
  static const String _notifSpark = 'notif_morning_spark';
  static const String _notifMorning = 'notif_morning_goal';
  static const String _notifEvening = 'notif_evening_streak';
  static const String _notifLeads = 'notif_lead_followup';

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabled, value);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifEnabled) ?? false;
  }

  /// The 6 AM "Morning Motivation" spark (rotating quote + write-your-goals CTA).
  /// Defaults ON so users get it as soon as they enable reminders at all.
  Future<void> setNotifyMorningSpark(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifSpark, value);
  }

  Future<bool> getNotifyMorningSpark() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifSpark) ?? true;
  }

  Future<void> setNotifyMorningGoal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifMorning, value);
  }

  Future<bool> getNotifyMorningGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifMorning) ?? true;
  }

  Future<void> setNotifyEveningStreak(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEvening, value);
  }

  Future<bool> getNotifyEveningStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifEvening) ?? true;
  }

  Future<void> setNotifyLeadFollowup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifLeads, value);
  }

  Future<bool> getNotifyLeadFollowup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifLeads) ?? true;
  }

  // ── Activity feed ────────────────────────────────────────────────────────────
  /// Whether the app auto-shares my wins (achievements, streak milestones) to
  /// the Friends Activity Feed. Defaults ON — the feed is dead without it, and
  /// only friends can see it. Manual "Share a win" posts ignore this flag.
  static const String _feedShareWins = 'feed_share_wins';

  Future<void> setShareWins(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_feedShareWins, value);
  }

  Future<bool> getShareWins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_feedShareWins) ?? true;
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
