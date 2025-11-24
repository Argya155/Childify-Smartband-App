import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Pindah ke Home setelah 3 detik
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen())
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // BAGIAN 1: LOGO & TEKS (Posisi: Tengah Layar - Center)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Agar Column hanya setinggi kontennya
              children: [
                // Container Logo
                Container(
                  width: 150,
                  height: 150,

                  child: Image.asset(
                    'assets/images/logo.png', // <--- Sesuaikan nama file Anda
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          // BAGIAN 2: LOADING INDICATOR (Posisi: Bawah - Bottom 30px)
          Positioned(
            bottom: 40, // Jarak 30px dari bawah layar
            left: 0,
            right: 0,   // Trik agar widget rata tengah secara horizontal
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}