// lib/widgets/security/security_score_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'dart:math' as math;

class SecurityScoreWidget extends StatelessWidget {
  final double score;
  final String? label;
  final double size;
  final double strokeWidth;
  final bool showLabel;
  final Color? backgroundColor;
  final bool animateOnAppear;

  const SecurityScoreWidget({
    Key? key,
    required this.score,
    this.label,
    this.size = 120,
    this.strokeWidth = 12,
    this.showLabel = true,
    this.backgroundColor,
    this.animateOnAppear = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(score);

    return AppCard(
      backgroundColor: backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabel && label != null) ...[
              Text(
                label!,
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSpacing.medium),
            ],
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: strokeWidth,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
                    ),
                  ),
                  // Score indicator
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: score / 100),
                    duration: animateOnAppear
                        ? const Duration(milliseconds: 1500)
                        : const Duration(milliseconds: 0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return SizedBox(
                        width: size,
                        height: size,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: strokeWidth,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      );
                    },
                  ),
                  // Score text
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: score),
                    duration: animateOnAppear
                        ? const Duration(milliseconds: 1500)
                        : const Duration(milliseconds: 0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: size / 3,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            'out of 100',
                            style: TextStyle(
                              fontSize: size / 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              _getScoreLabel(score),
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.riskLow;
    if (score >= 70) return AppColors.riskMedium;
    if (score >= 50) return AppColors.riskHigh;
    return AppColors.riskCritical;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Critical';
  }
}