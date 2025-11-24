import 'dart:io'; // Untuk akses File
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:path_provider/path_provider.dart'; // Import Path Provider
import 'package:shared_preferences/shared_preferences.dart'; // Import Shared Preferences
import 'package:path/path.dart' as path; // Helper untuk nama file
import '../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- VARIABEL STATE ---
  bool _isNotificationOn = true;
  bool _isVibrationOn = true;
  double _distanceLevel = 0.0;
  double _bpmThreshold = 120.0; // Default 120 BPM

  // Variabel untuk Profil
  String _childName = "Nama Anak";
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load semua data saat layar dibuka
  }

  // --- FUNGSI LOGIKA ---

  // 1. Load Data (Nama, Foto, DAN PENGATURAN LAINNYA)
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load Profil
      _childName = prefs.getString('child_name') ?? "Nama Anak";
      String? imagePath = prefs.getString('profile_image_path');
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      }
      _distanceLevel = prefs.getDouble('distance_level') ?? 0.0;
      _bpmThreshold = prefs.getDouble('bpm_threshold') ?? 120.0;
      _isNotificationOn = prefs.getBool('notification_on') ?? true;
      _isVibrationOn = prefs.getBool('vibration_on') ?? true;
    });
  }

  // 2. Fungsi Simpan Semua Pengaturan (Dipanggil tombol bawah)
  Future<void> _saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan nilai slider dan switch ke penyimpanan HP
    await prefs.setDouble('distance_level', _distanceLevel);
    await prefs.setDouble('bpm_threshold', _bpmThreshold);
    await prefs.setBool('notification_on', _isNotificationOn);
    await prefs.setBool('vibration_on', _isVibrationOn);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua pengaturan berhasil disimpan!"),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(pickedFile.path);
        final File localImage = await File(pickedFile.path).copy('${directory.path}/$fileName');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', localImage.path);

        setState(() {
          _profileImage = localImage;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Foto profil berhasil diperbarui!")),
          );
        }
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(text: _childName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ubah Nama", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Masukkan nama anak"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('child_name', nameController.text);

                setState(() {
                  _childName = nameController.text;
                });

                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- FUNGSI HELPER UI ---
  String _getDistanceLabel(double value) {
    if (value == 0) return "Dekat";
    if (value == 1) return "Waspada";
    return "Terlalu Jauh";
  }

  Color _getDistanceColor(double value) {
    if (value == 0) return AppColors.successGreen;
    if (value == 1) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Pengaturan",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- BAGIAN 1: PROFIL ---
          _buildSectionTitle("Profil Anak"),
          _buildProfileCard(),

          const SizedBox(height: 20),

          // --- BAGIAN 2: PARAMETER KEAMANAN ---
          _buildSectionTitle("Parameter Keamanan"),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === SLIDER 1: JARAK AMAN ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Batas Jarak Aman", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text(
                        _getDistanceLabel(_distanceLevel),
                        style: GoogleFonts.poppins(
                            color: _getDistanceColor(_distanceLevel),
                            fontWeight: FontWeight.bold
                        )
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Slider(
                  value: _distanceLevel,
                  min: 0,
                  max: 2,
                  divisions: 2,
                  activeColor: _getDistanceColor(_distanceLevel),
                  label: _getDistanceLabel(_distanceLevel),
                  onChanged: (value) {
                    setState(() {
                      _distanceLevel = value;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("5m", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                      Text("10m", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                      Text(">15m", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),

                const SizedBox(height: 5),
                Text(
                  "Peringatan akan muncul jika jarak anak melebihi batas ini.",
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),

                const Divider(thickness: 1, height: 20),
                const SizedBox(height: 10),

                // === SLIDER 2: BATAS BPM ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Batas Detak Jantung", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text(
                          "${_bpmThreshold.toInt()}",
                          style: GoogleFonts.poppins(
                              color: AppColors.dangerRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                          ),
                        ),
                        Text(" BPM", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    )
                  ],
                ),
                Slider(
                  value: _bpmThreshold,
                  min: 80,
                  max: 160,
                  divisions: 8,
                  activeColor: AppColors.dangerRed,
                  label: "${_bpmThreshold.toInt()} BPM",
                  onChanged: (value) {
                    setState(() {
                      _bpmThreshold = value;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("80 BPM", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                      Text("160 BPM", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Peringatan akan muncul jika detak jantung anak melebihi batas ini.",
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- BAGIAN 3: PREFERENSI ---
          _buildSectionTitle("Notifikasi & Alarm"),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: "Notifikasi Aplikasi",
                  value: _isNotificationOn,
                  onChanged: (val) => setState(() => _isNotificationOn = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.vibration,
                  title: "Getar",
                  value: _isVibrationOn,
                  onChanged: (val) => setState(() => _isVibrationOn = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- TOMBOL SIMPAN (YANG DIMODIFIKASI) ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAllSettings, // <--- Memanggil fungsi simpan baru
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF448AFF),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Simpan Pengaturan", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_childName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Ketuk icon pensil untuk ubah nama", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),

          IconButton(
            onPressed: _showEditNameDialog,
            icon: const Icon(Icons.edit, color: Colors.grey),
            tooltip: "Ubah Nama",
          )
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      activeColor: AppColors.successGreen,
      value: value,
      onChanged: onChanged,
    );
  }
}