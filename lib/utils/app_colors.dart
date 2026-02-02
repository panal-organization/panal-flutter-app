import 'package:flutter/material.dart';

class AppColors {
  // --- Layout Colors ---
  static const Color headerBackground = Color(
    0xFFFFFFFF,
  ); // #header { --bg-menu: #FFFFFF }
  static const Color menuBackground = Color(
    0xFF111C43,
  ); // #menu { --bg-header: #111C43 }
  static const Color contentBackground = Color(
    0xFFF7F8FA,
  ); // #content { --bg-content: #F7F8FA }

  // --- Palette ---

  // Primary
  static const Color primaryBase = Color(0xFF9B64FF);
  static const Color primaryBg = Color(0xFFE3CFFF);
  static const Color primaryOn = Colors.white;

  // Secondary
  static const Color secondaryBase = Color(0xFF0072D6);
  static const Color secondaryBg = Color(0xFFD2EAFF);
  static const Color secondaryOn = Colors.white;

  // Success
  static const Color successBase = Color(0xFF26BF94);
  static const Color successBg = Color(0xFFC7FFDA);
  static const Color successOn = Colors.black;

  // Danger
  static const Color dangerBase = Color(0xFFDC3545);
  static const Color dangerBg = Color(0xFFFFC4CD);
  static const Color dangerOn = Colors.white;

  // Warning
  static const Color warningBase = Color(0xFFF5BB49);
  static const Color warningBg = Color(0xFFFFF2CC);
  static const Color warningOn = Colors.black;

  // Info
  static const Color infoBase = Color(0xFF23B7E5);
  static const Color infoBg = Color(0xFFA8DDF1);
  static const Color infoOn = Colors.black;

  // Orange
  static const Color orangeBase = Color(0xFFFF642B);
  static const Color orangeBg = Color(0xFFFFD8CA);
  static const Color orangeOn = Colors.white;

  // Text
  static const Color textBase = Color(0xFF343434);
  static const Color textBg = Color(0xFFE4E4E4);
  static const Color textOn = Colors.white;
}
