import 'package:flutter/material.dart';

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height); // Ke pojok kiri bawah
    path.lineTo(size.width, size.height); // Ke pojok kanan bawah
    path.lineTo(size.width, 100); // Ke sisi kanan, agak turun

    // Membuat lengkungan bukit
    var firstControlPoint = Offset(size.width / 2, -50); // Titik tarikan kurva ke atas
    var firstEndPoint = Offset(0, 100); // Titik akhir kurva di kiri

    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}