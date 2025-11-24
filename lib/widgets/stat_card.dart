import 'package:flutter/material.dart';
import '../core/constants/app_styles.dart';
import '../core/constants/app_colors.dart';

// --- WIDGET 1: UNTUK MENAMPILKAN JARAK ---
class DistanceCard extends StatelessWidget {
  final bool isConnected;
  final String distanceValue;
  final String statusText;

  const DistanceCard({
    super.key,
    required this.isConnected,
    required this.distanceValue,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Distance",
          style: AppStyles.sensorLabel,
        ),
        const SizedBox(height: 10),
        Text(
          isConnected ? distanceValue : "-",
          style: AppStyles.sensorValue,
        ),
        const SizedBox(height: 10),

        // --- BAGIAN YANG DIUBAH ---
        Container(
          // Tambahkan padding horizontal agar kotak 'bernafas' (tidak terlalu mepet teks)
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),

          decoration: BoxDecoration(
            color: isConnected
                ? AppColors.successGreen
                : AppColors.successGreen.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12), // Membuat sudut melengkung
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Text( // Hapus widget Center, langsung Text saja
            isConnected ? statusText : "-",
            style: AppStyles.statusChip,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// --- WIDGET 2: UNTUK MENAMPILKAN DETAK JANTUNG (BPM) ---
class HeartRateCard extends StatelessWidget {
  final bool isConnected;
  final int bpmValue; // Misal: 82

  const HeartRateCard({
    super.key,
    required this.isConnected,
    required this.bpmValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isConnected ? bpmValue.toString() : "-",
          style: AppStyles.bpmNumber,
        ),
        const SizedBox(width: 10),
        Column(
          children: [
            const Icon(Icons.favorite, color: AppColors.dangerRed, size: 32),
            Text("BPM",
                style: AppStyles.bpmLabel),
          ],
        )
      ],
    );
  }
}