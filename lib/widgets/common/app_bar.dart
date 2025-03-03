// lib/widgets/common/app_bar.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppBarConfig {
  final String title;
  final bool centerTitle;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final Widget? flexibleSpace;
  final double? toolbarHeight;
  final PreferredSizeWidget? bottom;

  AppBarConfig({
    required this.title,
    this.centerTitle = true,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showBackButton = true,
    this.onBackPressed,
    this.leading,
    this.flexibleSpace,
    this.toolbarHeight,
    this.bottom,
  });
}

class AppCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppBarConfig config;

  const AppCustomAppBar({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        config.title,
        style: AppTextStyles.heading3.copyWith(
          color: config.foregroundColor ?? AppColors.textLight,
        ),
      ),
      centerTitle: config.centerTitle,
      backgroundColor: config.backgroundColor ?? AppColors.primary,
      foregroundColor: config.foregroundColor ?? AppColors.textLight,
      elevation: config.elevation ?? 0,
      automaticallyImplyLeading: config.showBackButton,
      leading: config.leading ?? (config.showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: config.onBackPressed ?? () => Navigator.of(context).pop(),
      )
          : null),
      actions: config.actions,
      flexibleSpace: config.flexibleSpace,
      toolbarHeight: config.toolbarHeight,
      bottom: config.bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      config.bottom != null
          ? kToolbarHeight + config.bottom!.preferredSize.height
          : config.toolbarHeight ?? kToolbarHeight
  );
}

class AppSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppSearchAppBar({
    Key? key,
    required this.title,
    required this.searchController,
    required this.onSearch,
    this.onClear,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: foregroundColor ?? AppColors.textLight,
        ),
      ),
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.textLight,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            controller: searchController,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search...',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  onSearch('');
                  onClear?.call();
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 70);
}