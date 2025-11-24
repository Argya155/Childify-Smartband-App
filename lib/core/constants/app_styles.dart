import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // 1. Header Besar (Tulisan "Childify" di atas)
  static TextStyle headerTitle = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // 2. Nama Anak ("Name")
  static TextStyle childName = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // 3. Tanggal Kecil (Di atas nama)
  static TextStyle dateText = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white70,
  );

  // 4. Label Judul Sensor ("Distance")
  static TextStyle sensorLabel = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.successGreen.withOpacity(0.8),
  );

  // 5. Nilai Sensor Utama ("< 5 meter")
  static TextStyle sensorValue = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // 6. Teks Status di dalam Kotak Hijau ("Dekat", "Aman")
  static TextStyle statusChip = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // 7. Angka Besar BPM ("82")
  static TextStyle bpmNumber = GoogleFonts.poppins(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF64B5F6), // Biru muda sesuai desain
  );

  // 8. Label Kecil BPM ("BPM")
  static TextStyle bpmLabel = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF64B5F6),
  );

  // 9. Teks Toast Bawah ("Connected to Device!")
  static TextStyle bottomStatus = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.black87
  );
}