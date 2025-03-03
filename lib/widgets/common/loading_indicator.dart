// lib/widgets/common/loading_indicator.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum LoadingSize { small, medium, large }

class LoadingIndicator extends StatelessWidget {
  final LoadingSize size;
  final Color? color;
  final String? message;
  final bool overlay;

  const LoadingIndicator({
    Key? key,
    this.size = LoadingSize.medium,
    this.color,
    this.message,
    this.overlay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.primary;
    double indicatorSize;
    double fontSize;

    switch (size) {
      case LoadingSize.small:
        indicatorSize = 16;
        fontSize = 12;
        break;
      case LoadingSize.medium:
        indicatorSize = 24;
        fontSize = 14;
        break;
      case LoadingSize.large:
        indicatorSize = 40;
        fontSize = 16;
        break;
    }

    final loadingWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            color: indicatorColor,
            strokeWidth: size == LoadingSize.small ? 2 : 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: TextStyle(
              color: overlay ? Colors.white : Colors.grey[600],
              fontSize: fontSize,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (overlay) {
      return Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: loadingWidget,
        ),
      );
    }

    return Center(child: loadingWidget);
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;
  final Color backgroundColor;
  final Color indicatorColor;

  const FullScreenLoading({
    Key? key,
    this.message,
    this.backgroundColor = Colors.white,
    this.indicatorColor = AppColors.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: LoadingIndicator(
          size: LoadingSize.large,
          color: indicatorColor,
          message: message,
        ),
      ),
    );
  }
}