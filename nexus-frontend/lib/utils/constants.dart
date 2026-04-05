/// NexusChat – App-wide constants
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────────────────────
  // Replace with your Azure App Service URL after deployment
  static const String baseUrl = 'https://nexuschat-api.azurewebsites.net/api';
  static const String socketUrl = 'https://nexuschat-api.azurewebsites.net';

  // ── Shared Preferences Keys ────────────────────────────────────────────────
  static const String tokenKey = 'nexus_token';
  static const String userKey = 'nexus_user';
  static const String themeKey = 'nexus_theme';

  // ── App Info ───────────────────────────────────────────────────────────────
  static const String appName = 'NexusChat';
  static const String appVersion = '1.0.0';

  // ── Pagination ─────────────────────────────────────────────────────────────
  static const int messagesPageSize = 30;
}
