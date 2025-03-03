// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';
import 'services/auth_service.dart';
import 'services/device_service.dart';
import 'services/scan_service.dart';
import 'services/report_service.dart';
import 'services/settings_service.dart';
import 'services/http/api_client.dart';
import 'services/http/token_interceptor.dart';
import 'services/http/logging_interceptor.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/devices/device_screen.dart';
import 'screens/devices/device_details_screen.dart';
import 'screens/devices/add_device_screen.dart';
import 'screens/scans/scan_screen.dart';
import 'screens/scans/scan_results_screen.dart';
import 'screens/reports/report_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/navigation/navigation_bar_widget.dart';

void main() {
  // Initialize app configuration
  AppConfig.init(Environment.development);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: MaterialApp(
        title: 'DEFIoT',
        theme: createAppTheme(),
        onGenerateRoute: _generateRoute,
        initialRoute: AppRoutes.splash,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  List<SingleChildWidget> _buildProviders() {
    // Create shared services
    final tokenInterceptor = TokenInterceptor();
    final loggingInterceptor = LoggingInterceptor();
    final apiClient = ApiClient(
      tokenInterceptor: tokenInterceptor,
      loggingInterceptor: loggingInterceptor,
    );

    // Create service instances
    final authService = AuthService(
      apiClient: apiClient,
      tokenInterceptor: tokenInterceptor,
    );

    final deviceService = DeviceService(apiClient: apiClient);
    final scanService = ScanService(apiClient: apiClient);
    final reportService = ReportService(apiClient: apiClient);
    final settingsService = SettingsService(apiClient: apiClient);

    // Create providers in the correct order of dependencies
    return [
      // Auth provider (no dependencies)
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(
          authService: authService,
          tokenInterceptor: tokenInterceptor,
        ),
      ),

      // Providers that depend on AuthProvider
      ChangeNotifierProxyProvider<AuthProvider, DeviceProvider>(
        create: (context) => DeviceProvider(
          deviceService: deviceService,
        ),
        update: (context, auth, previous) => previous!,
      ),

      ChangeNotifierProxyProvider<AuthProvider, ReportProvider>(
        create: (context) => ReportProvider(
          reportService: reportService,
        ),
        update: (context, auth, previous) => previous!,
      ),

      // ScanProvider depends on ReportProvider
      ChangeNotifierProxyProvider2<AuthProvider, ReportProvider, ScanProvider>(
        create: (context) => ScanProvider(
          scanService: scanService,
          reportProvider: Provider.of<ReportProvider>(context, listen: false),
        ),
        update: (context, auth, reportProvider, previous) => previous!,
      ),

      // SettingsProvider depends on AuthProvider
      ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
        create: (context) => SettingsProvider(
          settingsService: settingsService,
          authProvider: Provider.of<AuthProvider>(context, listen: false),
        ),
        update: (context, auth, previous) => previous!,
      ),
    ];
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    // Extract route arguments if available
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const NavigationBarWidget());

      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case AppRoutes.devices:
        return MaterialPageRoute(builder: (_) => const DeviceScreen());

      case AppRoutes.deviceDetails:
        if (args is int) {
          return MaterialPageRoute(builder: (_) => DeviceDetailsScreen(deviceId: args));
        }
        return _errorRoute('Missing device ID');

      case AppRoutes.addDevice:
        return MaterialPageRoute(builder: (_) => const AddDeviceScreen());

      case AppRoutes.scan:
        return MaterialPageRoute(builder: (_) => const ScanScreen());

      case AppRoutes.scanResults:
        if (args is int) {
          return MaterialPageRoute(builder: (_) => ScanResultsScreen(deviceId: args));
        }
        return _errorRoute('Missing device ID');

      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return _errorRoute('Route not found');
    }
  }

  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}