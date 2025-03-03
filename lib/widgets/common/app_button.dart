// lib/widgets/common/app_button.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum AppButtonType {
  primary,
  secondary,
  outlined,
  error, icon, text
}
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final Color? color;

  const AppButton({
    Key? key,
    this.text,
    this.icon,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.color, required String label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define button styling based on type and size
    late final ButtonStyle buttonStyle;
    late final double height;
    late final EdgeInsetsGeometry padding;
    late final double fontSize;

    switch (size) {
      case AppButtonSize.small:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        fontSize = 14;
        break;
      case AppButtonSize.medium:
        height = 44;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        fontSize = 16;
        break;
      case AppButtonSize.large:
        height = 56;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
        fontSize = 18;
        break;
    }

    switch (type) {
      case AppButtonType.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: AppColors.textLight,
          elevation: 2,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        );
        break;
      case AppButtonType.secondary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: color?.withOpacity(0.1) ?? AppColors.primary.withOpacity(0.1),
          foregroundColor: color ?? AppColors.primary,
          elevation: 0,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        );
        break;
      case AppButtonType.text:
        buttonStyle = TextButton.styleFrom(
          foregroundColor: color ?? AppColors.primary,
          padding: padding,
        );
        break;
      case AppButtonType.outlined:
        buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: color ?? AppColors.primary,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          side: BorderSide(color: color ?? AppColors.primary),
        );
        break;
      case AppButtonType.icon:
        buttonStyle = IconButton.styleFrom(
          foregroundColor: color ?? AppColors.primary,
          padding: padding,
        );
        break;
      case AppButtonType.error:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    // Create button content
    Widget buttonContent;

    if (isLoading) {
      buttonContent = SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: type == AppButtonType.primary ? Colors.white : (color ?? AppColors.primary),
          strokeWidth: 2,
        ),
      );
    } else if (icon != null && text != null) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(
            text!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (icon != null) {
      buttonContent = Icon(icon);
    } else if (text != null) {
      buttonContent = Text(
        text!,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      buttonContent = const SizedBox();
    }

    // Apply fullWidth setting
    Widget button;

    switch (type) {
      case AppButtonType.icon:
        button = IconButton(
          onPressed: isLoading ? null : onPressed,
          icon: buttonContent,
          style: buttonStyle,
        );
        break;
      case AppButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
        break;
      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
        break;
      default:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
    }

    if (fullWidth && type != AppButtonType.icon) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    }

    return button;
  }
}