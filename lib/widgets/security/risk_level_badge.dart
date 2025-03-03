// lib/widgets/security/risk_level_badge.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/device_model.dart';

class RiskLevelBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool showLabel;
  final bool large;

  const RiskLevelBadge({
    Key? key,
    required this.riskLevel,
    this.showLabel = true,
    this.large = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine risk level display
    String label;
    Color color;

    switch (riskLevel) {
      case RiskLevel.critical:
        label = "Critical";
        color = AppColors.riskCritical;
        break;
      case RiskLevel.high:
        label = "High";
        color = AppColors.riskHigh;
        break;
      case RiskLevel.medium:
        label = "Medium";
        color = AppColors.riskMedium;
        break;
      case RiskLevel.low:
      default:
        label = "Low";
        color = AppColors.riskLow;
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8,
          vertical: large ? 6 : 4
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 12 : 8,
            height: large ? 12 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: large ? 8 : 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: large ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}