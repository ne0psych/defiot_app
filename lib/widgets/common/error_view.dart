import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'app_button.dart';

/// A reusable widget to display errors with a retry option
class ErrorView extends StatelessWidget {
  /// Error message to display
  final String error;

  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Optional icon to display
  final IconData icon;

  /// Optional title for the error
  final String title;

  /// Optional color for the icon
  final Color? iconColor;

  /// Optional retry button text
  final String retryButtonText;

  /// Creates an ErrorView
  const ErrorView({
    Key? key,
    required this.error,
    required this.onRetry,
    this.icon = Icons.error_outline,
    this.title = 'Error Occurred',
    this.iconColor,
    this.retryButtonText = 'Try Again',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorColor = iconColor ?? Colors.red.shade700;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: onRetry,
              label: retryButtonText,
              icon: Icons.refresh,
              expanded: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// A specific error view for network errors
class NetworkErrorView extends StatelessWidget {
  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Optional custom error message
  final String? message;

  /// Creates a NetworkErrorView
  const NetworkErrorView({
    Key? key,
    required this.onRetry,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      icon: Icons.wifi_off,
      title: 'Network Error',
      error: message ?? AppConstants.networkErrorMessage,
      onRetry: onRetry,
    );
  }
}

/// A specific error view for server errors
class ServerErrorView extends StatelessWidget {
  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Optional custom error message
  final String? message;

  /// Creates a ServerErrorView
  const ServerErrorView({
    Key? key,
    required this.onRetry,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      icon: Icons.cloud_off,
      title: 'Server Error',
      error: message ?? AppConstants.serverErrorMessage,
      onRetry: onRetry,
    );
  }
}

/// A specific error view for unauthorized errors
class UnauthorizedErrorView extends StatelessWidget {
  /// Callback when login button is pressed
  final VoidCallback onLogin;

  /// Creates an UnauthorizedErrorView
  const UnauthorizedErrorView({
    Key? key,
    required this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      icon: Icons.lock_outline,
      title: 'Session Expired',
      error: AppConstants.unauthorizedErrorMessage,
      onRetry: onLogin,
      retryButtonText: 'Login Again',
      iconColor: Colors.orange,
    );
  }
}

/// A specific error view for timeout errors
class TimeoutErrorView extends StatelessWidget {
  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Creates a TimeoutErrorView
  const TimeoutErrorView({
    Key? key,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      icon: Icons.timer_off,
      title: 'Connection Timeout',
      error: AppConstants.timeoutErrorMessage,
      onRetry: onRetry,
    );
  }
}

/// A specific error view for device scan errors
class ScanErrorView extends StatelessWidget {
  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Optional custom error message
  final String? message;

  /// Creates a ScanErrorView
  const ScanErrorView({
    Key? key,
    required this.onRetry,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      icon: Icons.security,
      title: 'Scan Error',
      error: message ?? 'Failed to complete the security scan. Please try again.',
      onRetry: onRetry,
      iconColor: Colors.red,
    );
  }
}

/// A specific error view for no device access errors
class DeviceAccessErrorView extends StatelessWidget {
  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Optional device name
  final String? deviceName;

  /// Creates a DeviceAccessErrorView
  const DeviceAccessErrorView({
    Key? key,
    required this.onRetry,
    this.deviceName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceRef = deviceName != null ? ' to $deviceName' : '';

    return ErrorView(
      icon: Icons.device_unknown,
      title: 'Device Access Error',
      error: 'Could not connect$deviceRef. Please check that the device is online and try again.',
      onRetry: onRetry,
      iconColor: Colors.orange,
    );
  }
}