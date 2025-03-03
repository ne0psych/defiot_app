// lib/widgets/security/port_info_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/scan_model.dart';
import '../common/app_card.dart';

class PortInfoList extends StatelessWidget {
  final List<PortInfo> ports;
  final VoidCallback? onViewAll;
  final bool showViewAll;
  final bool compact;

  const PortInfoList({
    Key? key,
    required this.ports,
    this.onViewAll,
    this.showViewAll = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No open ports found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showViewAll && ports.length > 3) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Open Ports (${ports.length})',
                  style: AppTextStyles.subtitle,
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: compact && ports.length > 3 && showViewAll
              ? 3
              : ports.length,
          itemBuilder: (context, index) {
            final port = ports[index];
            return PortInfoItem(
              port: port,
              compact: compact,
            );
          },
        ),
      ],
    );
  }
}

class PortInfoItem extends StatelessWidget {
  final PortInfo port;
  final bool compact;

  const PortInfoItem({
    Key? key,
    required this.port,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSecure = port.service?.isSecure ?? false;
    final color = isSecure ? AppColors.riskLow : AppColors.riskHigh;

    return AppCard(
      padding: const EdgeInsets.all(12),
      elevation: 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.router,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Port ${port.portNumber} (${port.protocol.toUpperCase()})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSecure ? 'SECURE' : 'INSECURE',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  port.service?.name ?? 'Unknown Service',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                if (!compact && port.service != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Version: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        port.service!.version ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  if (port.service!.knownVulnerabilities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Known Vulnerabilities',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...port.service!.knownVulnerabilities.map((vuln) => Text(
                      '• $vuln',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    )),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}