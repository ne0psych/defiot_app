import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'app_button.dart';

/// A reusable widget to display empty states with an optional action button
class EmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Title text
  final String title;

  /// Description message
  final String message;

  /// Optional button text
  final String? buttonText;

  /// Optional callback when button is pressed
  final VoidCallback? onButtonPressed;

  /// Optional color for the icon
  final Color? iconColor;

  /// Optional image asset path instead of an icon
  final String? imagePath;

  /// Optional color for the button
  final Color? buttonColor;

  /// Creates an EmptyState
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.imagePath,
    this.buttonColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 120,
                height: 120,
              )
            else
              Icon(
                icon,
                size: 80,
                color: iconColor ?? Colors.grey[400],
              ),
            const SizedBox(height: 20),
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
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              AppButton(
                onPressed: onButtonPressed!,
                label: buttonText!,
                icon: icon,
                color: buttonColor,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state specifically for when there are no devices
class NoDevicesEmptyState extends StatelessWidget {
  /// Callback when Add Device button is pressed
  final VoidCallback onAddDevice;

  /// Creates a NoDevicesEmptyState
  const NoDevicesEmptyState({
    Key? key,
    required this.onAddDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.devices,
      title: 'No Devices Found',
      message: 'You haven\'t added any IoT devices yet. Add your first device to start securing it!',
      buttonText: 'Add Device',
      onButtonPressed: onAddDevice,
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

/// Empty state specifically for when there are no scans
class NoScansEmptyState extends StatelessWidget {
  /// Callback when Start Scan button is pressed
  final VoidCallback onStartScan;

  /// Creates a NoScansEmptyState
  const NoScansEmptyState({
    Key? key,
    required this.onStartScan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.security,
      title: 'No Scans Found',
      message: 'You haven\'t performed any security scans yet. Start a scan to check for vulnerabilities!',
      buttonText: 'Start Scan',
      onButtonPressed: onStartScan,
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

/// Empty state specifically for when there are no reports
class NoReportsEmptyState extends StatelessWidget {
  /// Callback when Generate Report button is pressed
  final VoidCallback onGenerateReport;

  /// Creates a NoReportsEmptyState
  const NoReportsEmptyState({
    Key? key,
    required this.onGenerateReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.description,
      title: 'No Reports Found',
      message: 'You haven\'t generated any security reports yet. Generate a report to get an overview of your device security!',
      buttonText: 'Generate Report',
      onButtonPressed: onGenerateReport,
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

/// Empty state specifically for when there are no vulnerabilities
class NoVulnerabilitiesEmptyState extends StatelessWidget {
  /// Creates a NoVulnerabilitiesEmptyState
  const NoVulnerabilitiesEmptyState({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.verified_user,
      title: 'No Vulnerabilities Found',
      message: 'Good news! No vulnerabilities were detected on this device. Your device appears to be secure.',
      iconColor: Colors.green,
    );
  }
}

/// Empty state specifically for when search results are empty
class EmptySearchResultsState extends StatelessWidget {
  /// The search query that was used
  final String searchQuery;

  /// Callback when Clear button is pressed
  final VoidCallback onClear;

  /// Creates an EmptySearchResultsState
  const EmptySearchResultsState({
    Key? key,
    required this.searchQuery,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'No matches found for "$searchQuery". Try a different search term.',
      buttonText: 'Clear Search',
      onButtonPressed: onClear,
    );
  }
}

/// Empty state for network connectivity issues
class OfflineEmptyState extends StatelessWidget {
  /// Callback when Retry button is pressed
  final VoidCallback onRetry;

  /// Creates an OfflineEmptyState
  const OfflineEmptyState({
    Key? key,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'You\'re Offline',
      message: 'Please check your internet connection and try again.',
      buttonText: 'Retry',
      onButtonPressed: onRetry,
      iconColor: Colors.orange,
    );
  }
}