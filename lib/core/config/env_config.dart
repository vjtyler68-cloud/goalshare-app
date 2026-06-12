/// Environment configuration
/// In production, use flutter_dotenv or flavor-based config
class EnvConfig {
  // API Configuration
  static const String baseUrl =
      String.fromEnvironment('BASE_URL', defaultValue: 'https://goal-share-backend.vercel.app/api/v1');

  // App Configuration
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'GoalShare');
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

  // Feature Flags
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);
  static const bool enableDebugMode = bool.fromEnvironment('ENABLE_DEBUG_MODE', defaultValue: false);

  // Timeout Configuration
  static const int apiTimeoutSeconds = int.fromEnvironment('API_TIMEOUT', defaultValue: 30);
  static const int connectTimeoutSeconds = int.fromEnvironment('CONNECT_TIMEOUT', defaultValue: 15);

  // Get full URL
  static String getUrl(String endpoint) => baseUrl + endpoint;

  // Debug helper
  static void printConfig() {
    if (enableLogging) {
      print('=== Environment Configuration ===');
      print('Base URL: $baseUrl');
      print('App Name: $appName');
      print('App Version: $appVersion');
      print('Debug Mode: $enableDebugMode');
      print('================================');
    }
  }
}
