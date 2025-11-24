import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// UBAH KE STATEFULWIDGET AGAR BISA ANIMASI
class ControlButton extends StatefulWidget {
  final IconData? icon;
  final String? assetPath;
  final VoidCallback onTap;
  final Color iconColor;
  final bool isProminent;
  final bool isSvg;

  const ControlButton({
    super.key,
    this.icon,
    this.assetPath,
    required this.onTap,
    this.iconColor = Colors.grey,
    this.isProminent = false,
    this.isSvg = false,
  }) : assert(icon != null || assetPath != null,
  'Either icon or assetPath must be provided.');

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  // Variabel untuk mengatur skala animasi
  double _scale = 1.0;

  // Fungsi saat tombol ditekan (Mengecil)
  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.9; // Mengecil jadi 90% ukurannya
    });
  }

  // Fungsi saat tombol dilepas (Kembali Normal)
  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
    // Jalankan fungsi onTap asli
    widget.onTap();
  }

  // Fungsi saat jari digeser keluar tombol (Batal tekan)
  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- PENGATURAN UKURAN (Sesuai request sebelumnya) ---
    double iconSize = widget.isProminent ? 60.0 : 35.0;
    double paddingSize = widget.isProminent ? 20.0 : 16.0;
    // -----------------------------------------------------

    Widget iconWidget;
    if (widget.assetPath != null) {
      if (widget.isSvg) {
        iconWidget = SvgPicture.asset(
          widget.assetPath!,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(widget.iconColor, BlendMode.srcIn),
        );
      } else {
        iconWidget = Image.asset(
          widget.assetPath!,
          width: iconSize,
          height: iconSize,
          color: widget.iconColor,
        );
      }
    } else {
      iconWidget = Icon(
        widget.icon,
        size: iconSize,
        color: widget.iconColor,
      );
    }

    // --- WIDGET UTAMA DENGAN DETEKSI GESTURE & ANIMASI ---
    return GestureDetector(
      // Mengganti onTap biasa dengan logika TapDown & TapUp
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,

      child: AnimatedScale(
        scale: _scale, // Skala berubah sesuai state
        duration: const Duration(milliseconds: 100), // Kecepatan animasi (cepat/snappy)
        curve: Curves.easeInOut, // Efek gerakan halus

        child: Container(
          padding: EdgeInsets.all(paddingSize),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, // Putih Solid (Sesuai request terakhir)
            boxShadow: widget.isProminent
                ? [
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              )
            ]
                : [
              // Shadow tipis untuk tombol kecil (biar cantik di atas background putih solid)
              const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2)
              )
            ],
          ),
          child: iconWidget,
        ),
      ),
    );
  }
}