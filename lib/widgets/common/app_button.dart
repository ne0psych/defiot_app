import 'package:flutter/material.dart';

/// A customized button widget for consistent styling across the app
class AppButton extends StatelessWidget {
  /// The callback function when the button is pressed
  final VoidCallback onPressed;

  /// Button text label
  final String label;

  /// Optional icon to display before the text
  final IconData? icon;

  /// Optional loading state
  final bool isLoading;

  /// Optional button color
  final Color? color;

  /// Optional text color
  final Color? textColor;

  /// Optional expanded width
  final bool expanded;

  /// Creates an AppButton
  const AppButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.expanded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidget = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: textColor ?? Colors.white,
          strokeWidth: 2,
        ),
      )
          : _buildButtonContent(),
    );

    // Return either a full-width button or a normal button based on expanded flag
    return expanded
        ? SizedBox(
      width: double.infinity,
      height: 50,
      child: buttonWidget,
    )
        : buttonWidget;
  }

  /// Builds the content of the button (icon + text or just text)
  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      return Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}

/// A text button variant with consistent styling
class AppTextButton extends StatelessWidget {
  /// The callback function when the button is pressed
  final VoidCallback onPressed;

  /// Button text label
  final String label;

  /// Optional icon to display before the text
  final IconData? icon;

  /// Optional color
  final Color? color;

  /// Creates an AppTextButton
  const AppTextButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// An outlined button variant with consistent styling
class AppOutlinedButton extends StatelessWidget {
  /// The callback function when the button is pressed
  final VoidCallback onPressed;

  /// Button text label
  final String label;

  /// Optional icon to display before the text
  final IconData? icon;

  /// Optional color
  final Color? color;

  /// Optional expanded width
  final bool expanded;

  /// Creates an AppOutlinedButton
  const AppOutlinedButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.color,
    this.expanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidget = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? Theme.of(context).primaryColor,
        side: BorderSide(color: color ?? Theme.of(context).primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    return expanded
        ? SizedBox(
      width: double.infinity,
      height: 50,
      child: buttonWidget,
    )
        : buttonWidget;
  }
}

/// A floating action button variant with consistent styling
class AppFloatingActionButton extends StatelessWidget {
  /// The callback function when the button is pressed
  final VoidCallback onPressed;

  /// Icon to display
  final IconData icon;

  /// Optional tooltip text
  final String? tooltip;

  /// Optional color
  final Color? color;

  /// Optional label for extended FAB
  final String? label;

  /// Creates an AppFloatingActionButton
  const AppFloatingActionButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? Theme.of(context).primaryColor;

    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      tooltip: tooltip,
      child: Icon(icon, color: Colors.white),
    );
  }
}