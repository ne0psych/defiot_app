// lib/core/config/app_routes.dart
class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String devices = '/devices';
  static const String deviceDetails = '/devices/details';
  static const String addDevice = '/devices/add';
  static const String scan = '/scan';
  static const String scanResults = '/scan/results';
  static const String reports = '/reports';
  static const String reportDetails = '/reports/details';

  // Settings routes
  static const String settings = '/settings';
  static const String profile = '/settings/profile';
  static const String security = '/settings/security';
  static const String notifications = '/settings/notifications';
  static const String appearance = '/settings/appearance';
  static const String apiKeys = '/settings/api-keys';
  static const String about = '/settings/about';
  static const String help = '/settings/help';
}