import 'package:flutter/material.dart';
import 'package:panal_flutter_app/utils/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Define the color scheme based on the primary color
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBase,
        primary: AppColors.primaryBase,
        secondary: AppColors.secondaryBase,
        surface: AppColors.contentBackground, // Body background
        error: AppColors.dangerBase,
      ),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.contentBackground,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.textBase, // Text color on AppBar
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textBase),
      ),

      // Navigation Bar Theme (Bottom Menu)
      // Note: User requested #menu { --bg-header: #111C43; } which implies a Dark Navy menu.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.menuBackground,
        indicatorColor: AppColors.primaryBase.withOpacity(
          0.2,
        ), // Light primary for selection
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(color: Colors.white70);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(
              color: Colors.white,
            ); // Icon when selected
          }
          return const IconThemeData(
            color: Colors.white70,
          ); // Icon when unselected
        }),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBase,
        foregroundColor: Colors.white,
      ),

      // Text Theme Base
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textBase),
        bodyMedium: TextStyle(color: AppColors.textBase),
        titleLarge: TextStyle(
          color: AppColors.textBase,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
