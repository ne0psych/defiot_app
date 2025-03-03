import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Class to manage all shared preferences operations
class SharedPrefs {
  static SharedPreferences? _preferences;

  // Keys for shared preferences
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user_data';
  static const String keySettings = 'app_settings';
  static const String keyTheme = 'app_theme';
  static const String keyLanguage = 'app_language';
  static const String keyLastScan = 'last_scan_timestamp';
  static const String keyDeviceCache = 'device_cache';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyNotificationSettings = 'notification_settings';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyLastBackup = 'last_backup';

  /// Initialize shared preferences
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Check if SharedPreferences is initialized
  static bool get isInitialized => _preferences != null;

  /// Get the SharedPreferences instance
  static SharedPreferences get instance {
    if (_preferences == null) {
      throw Exception('SharedPrefs not initialized. Call init() first.');
    }
    return _preferences!;
  }

  /// Set a string value
  static Future<bool> setString(String key, String value) async {
    return await instance.setString(key, value);
  }

  /// Get a string value
  static String? getString(String key) {
    return instance.getString(key);
  }

  /// Set a boolean value
  static Future<bool> setBool(String key, bool value) async {
    return await instance.setBool(key, value);
  }

  /// Get a boolean value with default
  static bool getBool(String key, {bool defaultValue = false}) {
    return instance.getBool(key) ?? defaultValue;
  }

  /// Set an integer value
  static Future<bool> setInt(String key, int value) async {
    return await instance.setInt(key, value);
  }

  /// Get an integer value with default
  static int getInt(String key, {int defaultValue = 0}) {
    return instance.getInt(key) ?? defaultValue;
  }

  /// Set a double value
  static Future<bool> setDouble(String key, double value) async {
    return await instance.setDouble(key, value);
  }

  /// Get a double value with default
  static double getDouble(String key, {double defaultValue = 0.0}) {
    return instance.getDouble(key) ?? defaultValue;
  }

  /// Set a list of strings
  static Future<bool> setStringList(String key, List<String> value) async {
    return await instance.setStringList(key, value);
  }

  /// Get a list of strings
  static List<String> getStringList(String key) {
    return instance.getStringList(key) ?? [];
  }

  /// Set an object (will be serialized to JSON)
  static Future<bool> setObject(String key, Object value) async {
    return await instance.setString(key, jsonEncode(value));
  }

  /// Get an object (will be deserialized from JSON)
  static T? getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final jsonString = instance.getString(key);
    if (jsonString == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return fromJson(json);
    } catch (e) {
      print('Error parsing JSON for key $key: $e');
      return null;
    }
  }

  /// Clear a specific key
  static Future<bool> remove(String key) async {
    return await instance.remove(key);
  }

  /// Clear all shared preferences
  static Future<bool> clear() async {
    return await instance.clear();
  }

  /// Check if a key exists
  static bool containsKey(String key) {
    return instance.containsKey(key);
  }

  // Auth specific methods

  /// Save authentication tokens
  static Future<void> saveAuthData(String token, String refreshToken) async {
    await setString(keyAuthToken, token);
    await setString(keyRefreshToken, refreshToken);
  }

  /// Get the auth token
  static String? getAuthToken() {
    return getString(keyAuthToken);
  }

  /// Get the refresh token
  static String? getRefreshToken() {
    return getString(keyRefreshToken);
  }

  /// Clear auth data (for logout)
  static Future<void> clearAuthData() async {
    await remove(keyAuthToken);
    await remove(keyRefreshToken);
    await remove(keyUser);
  }

  /// Save user data
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    return await setString(keyUser, jsonEncode(userData));
  }

  /// Get user data
  static Map<String, dynamic>? getUserData() {
    final data = getString(keyUser);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  // Settings specific methods

  /// Save app settings
  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    return await setString(keySettings, jsonEncode(settings));
  }

  /// Get app settings
  static Map<String, dynamic> getSettings() {
    final data = getString(keySettings);
    if (data == null) return {};
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing settings: $e');
      return {};
    }
  }

  /// Save app theme
  static Future<bool> saveTheme(String theme) async {
    return await setString(keyTheme, theme);
  }

  /// Get app theme
  static String getTheme({String defaultTheme = 'system'}) {
    return getString(keyTheme) ?? defaultTheme;
  }

  /// Save app language
  static Future<bool> saveLanguage(String language) async {
    return await setString(keyLanguage, language);
  }

  /// Get app language
  static String getLanguage({String defaultLanguage = 'english'}) {
    return getString(keyLanguage) ?? defaultLanguage;
  }

  // Cache specific methods

  /// Save last scan timestamp
  static Future<bool> saveLastScanTime(int deviceId, DateTime timestamp) async {
    final scanTimes = getObject<Map<String, dynamic>>(
      keyLastScan,
          (json) => json,
    ) ?? {};

    scanTimes[deviceId.toString()] = timestamp.millisecondsSinceEpoch;
    return await setString(keyLastScan, jsonEncode(scanTimes));
  }

  /// Get last scan timestamp for a device
  static DateTime? getLastScanTime(int deviceId) {
    final scanTimes = getObject<Map<String, dynamic>>(
      keyLastScan,
          (json) => json,
    );

    if (scanTimes == null) return null;

    final timestamp = scanTimes[deviceId.toString()];
    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp as int);
  }

  /// Cache devices list
  static Future<bool> cacheDevices(List<dynamic> devices) async {
    return await setString(keyDeviceCache, jsonEncode(devices));
  }

  /// Get cached devices
  static List<dynamic>? getCachedDevices() {
    final data = getString(keyDeviceCache);
    if (data == null) return null;
    try {
      return jsonDecode(data) as List<dynamic>;
    } catch (e) {
      print('Error parsing device cache: $e');
      return null;
    }
  }

  /// Save onboarding status
  static Future<bool> setOnboardingComplete(bool complete) async {
    return await setBool(keyOnboardingComplete, complete);
  }

  /// Check if onboarding is complete
  static bool isOnboardingComplete() {
    return getBool(keyOnboardingComplete, defaultValue: false);
  }

  /// Save notification settings
  static Future<bool> saveNotificationSettings(Map<String, dynamic> settings) async {
    return await setString(keyNotificationSettings, jsonEncode(settings));
  }

  /// Get notification settings
  static Map<String, dynamic> getNotificationSettings() {
    final data = getString(keyNotificationSettings);
    if (data == null) return {};
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing notification settings: $e');
      return {};
    }
  }

  /// Set first launch flag
  static Future<bool> setFirstLaunch(bool isFirstLaunch) async {
    return await setBool(keyFirstLaunch, isFirstLaunch);
  }

  /// Check if this is the first launch
  static bool isFirstLaunch() {
    return getBool(keyFirstLaunch, defaultValue: true);
  }

  /// Record last backup time
  static Future<bool> saveLastBackupTime(DateTime timestamp) async {
    return await setInt(keyLastBackup, timestamp.millisecondsSinceEpoch);
  }

  /// Get last backup time
  static DateTime? getLastBackupTime() {
    final timestamp = getInt(keyLastBackup);
    if (timestamp == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}