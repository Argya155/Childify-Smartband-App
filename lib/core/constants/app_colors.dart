import 'package:flutter/material.dart';

class AppColors {
  // Gradasi Utama (Background)
  static const Color primaryGreen = Color(0xFF76C597); // Hijau cerah
  static const Color primaryBlue = Color(0xFF5796D2);  // Biru cerah
  static const Color background = Color(0xFFF5F5F5);
  static const Color primaryOrange = Color(0xFFFF9100);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF76C597), Color(0xFF5796D2)], // Sesuaikan tone di sini
  );

  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textWhite = Colors.white;
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF66BB6A);
  static const Color inactiveGrey = Color(0xFFBDBDBD);
}