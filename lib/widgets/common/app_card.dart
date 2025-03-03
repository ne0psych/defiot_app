import 'package:flutter/material.dart';

/// A customized card widget for consistent styling across the app
class AppCard extends StatelessWidget {
  /// Title of the card
  final String title;

  /// Content of the card
  final Widget content;

  /// Optional icon to display with the title
  final IconData? icon;

  /// Optional actions to display in the header
  final List<Widget>? actions;

  /// Optional padding for the content
  final EdgeInsets contentPadding;

  /// Optional padding for the card
  final EdgeInsets padding;

  /// Optional margin for the card
  final EdgeInsets margin;

  /// Optional elevation for the card
  final double elevation;

  /// Optional border radius for the card
  final double borderRadius;

  /// Whether to show a divider between header and content
  final bool showDivider;

  /// Optional background color
  final Color? backgroundColor;

  /// Optional center the title
  final bool centerTitle;

  /// Creates an AppCard
  const AppCard({
    Key? key,
    required this.title,
    required this.content,
    this.icon,
    this.actions,
    this.contentPadding = const EdgeInsets.all(16),
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.elevation = 1,
    this.borderRadius = 12,
    this.showDivider = true,
    this.backgroundColor,
    this.centerTitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (showDivider) const Divider(height: 1),
            Padding(
              padding: contentPadding,
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header section of the card
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// A card for device information display
class DeviceCard extends StatelessWidget {
  /// Device name
  final String deviceName;

  /// Device type
  final String deviceType;

  /// Status of the device (online/offline)
  final bool isOnline;

  /// Risk level of the device
  final String riskLevel;

  /// IP address of the device
  final String? ipAddress;

  /// MAC address of the device
  final String macAddress;

  /// Number of vulnerabilities
  final int vulnerabilitiesCount;

  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Optional callback when edit button is tapped
  final VoidCallback? onEdit;

  /// Optional callback when delete button is tapped
  final VoidCallback? onDelete;

  /// Creates a DeviceCard
  const DeviceCard({
    Key? key,
    required this.deviceName,
    required this.deviceType,
    required this.isOnline,
    required this.riskLevel,
    this.ipAddress,
    required this.macAddress,
    required this.vulnerabilitiesCount,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildDeviceTypeIcon(),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deviceType,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ipAddress != null) ...[
                        _buildInfoRow(Icons.language, ipAddress!),
                        const SizedBox(height: 4),
                      ],
                      _buildInfoRow(Icons.wifi, macAddress),
                    ],
                  ),
                  _buildRiskLevelBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$vulnerabilitiesCount ${vulnerabilitiesCount == 1 ? 'Vulnerability' : 'Vulnerabilities'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getVulnerabilityColor(),
                    ),
                  ),
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: onEdit,
                          tooltip: 'Edit Device',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: onDelete,
                          tooltip: 'Delete Device',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an icon representing the device type
  Widget _buildDeviceTypeIcon() {
    IconData iconData;
    Color color;

    switch (deviceType.toLowerCase()) {
      case 'camera':
      case 'smart camera':
        iconData = Icons.camera_alt;
        color = Colors.blue;
        break;
      case 'lock':
      case 'smart lock':
        iconData = Icons.lock;
        color = Colors.purple;
        break;
      case 'thermostat':
        iconData = Icons.thermostat;
        color = Colors.orange;
        break;
      case 'light':
      case 'smart light':
        iconData = Icons.lightbulb;
        color = Colors.amber;
        break;
      case 'speaker':
      case 'smart speaker':
        iconData = Icons.speaker;
        color = Colors.red;
        break;
      case 'router':
      case 'gateway':
        iconData = Icons.router;
        color = Colors.green;
        break;
      default:
        iconData = Icons.devices_other;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  /// Builds a badge showing the device's online status
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row with an icon and text
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Builds a badge showing the device's risk level
  Widget _buildRiskLevelBadge() {
    Color color;

    switch (riskLevel.toLowerCase()) {
      case 'critical':
        color = Colors.purple;
        break;
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Gets color based on vulnerability count
  Color _getVulnerabilityColor() {
    if (vulnerabilitiesCount == 0) {
      return Colors.green;
    } else if (vulnerabilitiesCount < 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// A simple status card showing a metric with an icon
class StatusCard extends StatelessWidget {
  /// Title of the card
  final String title;

  /// Value to display (can be a number or status)
  final String value;

  /// Icon to display
  final IconData icon;

  /// Color for the card
  final Color color;

  /// Optional trend indicator value (positive number = up, negative = down)
  final double? trend;

  /// Optional callback when card is tapped
  final VoidCallback? onTap;

  /// Creates a StatusCard
  const StatusCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: color,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      trend! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: trend! > 0 ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend!.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trend! > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}