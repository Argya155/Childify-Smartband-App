import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartband_app/core/constants/app_styles.dart';
import '../core/constants/app_colors.dart';
import '../widgets/custom_curve.dart';
import '../widgets/stat_card.dart';
import '../widgets/control_button.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- KONFIGURASI BLE ---
  final String TARGET_DEVICE_NAME = "ESP32-Childify";
  final String SERVICE_UUID = "180D";
  final String CHARACTERISTIC_UUID = "2A37";

  // --- VARIABEL NOTIFIKASI ---
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  DateTime? _lastNotificationTime;

  // --- VARIABEL STATE UI ---
  bool _isStatusVisible = false;
  Timer? _statusTimer;
  String? _tempMessage;
  bool _isAlarmActive = false;

  // --- VARIABEL STATE BLE ---
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _valueSubscription;
  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _connectionStateSubscription;

  bool _isScanning = false;
  bool _isConnected = false;

  bool _isManualDisconnect = false;

  // Data Sensor
  int _heartRate = 0;
  String _distanceStr = "-";
  String _distanceStatus = "-";

  // Variabel Moving Average Filter RSSI
  final List<int> _rssiBuffer = [];
  final int _rssiWindowSize = 10;

  // Data Pengguna & Pengaturan
  String _childName = "Name";
  File? _profileImage;
  double _bpmThreshold = 120.0;
  double _distanceLevel = 0.0;
  bool _isNotificationOn = true;
  bool _isVibrationOn = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initBluetoothState();
    _initNotifications();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _scanSubscription?.cancel();
    _valueSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // FUNGSI NOTIFIKASI
  Future<void> _showLocalNotification(String title, String body) async {
    if (!_isNotificationOn) return;
    String channelId = _isVibrationOn ? 'childify_alert_vib' : 'childify_alert_silent';
    String channelName = _isVibrationOn ? 'Childify Alerts (Vibrate)' : 'Childify Alerts (Silent)';

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifikasi peringatan untuk detak jantung dan jarak',
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.dangerRed,
      playSound: true,
      enableVibration: _isVibrationOn,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, notificationDetails);
  }

  void _initBluetoothState() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        if (_isConnected || _isScanning) {
          if (mounted) {
            _handleDeviceDisconnect(customMessage: "Bluetooth HP Mati");
          }
        }
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _childName = prefs.getString('child_name') ?? "Name";
      String? imagePath = prefs.getString('profile_image_path');
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      } else {
        _profileImage = null;
      }
      _bpmThreshold = prefs.getDouble('bpm_threshold') ?? 120.0;
      _distanceLevel = prefs.getDouble('distance_level') ?? 0.0;
      _isNotificationOn = prefs.getBool('notification_on') ?? true;
      _isVibrationOn = prefs.getBool('vibration_on') ?? true;
    });
  }

  // --- LOGIKA UTAMA BLE ---

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.notification,
      ].request();

      if (statuses[Permission.notification]!.isPermanentlyDenied) {
        print("Izin notifikasi ditolak");
      }

      if (statuses[Permission.location]!.isPermanentlyDenied ||
          statuses[Permission.bluetoothScan]!.isPermanentlyDenied ||
          statuses[Permission.bluetoothConnect]!.isPermanentlyDenied) {
        _showSettingsDialog();
        return false;
      }

      return statuses[Permission.bluetoothScan]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted;
    }
    return true;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Izin Dibutuhkan"),
        content: const Text("Aplikasi membutuhkan izin Bluetooth, Lokasi, dan Notifikasi. Mohon aktifkan di Pengaturan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text("Buka Pengaturan"),
          ),
        ],
      ),
    );
  }

  Future<void> _startScanAndConnect() async {
    setState(() {
      _isManualDisconnect = false;
    });

    bool permGranted = await _checkPermissions();
    if (!permGranted) {
      _showStatusMessage(message: "Izin Ditolak!");
      return;
    }

    try {
      if (Platform.isAndroid) {
        var state = await FlutterBluePlus.adapterState.first;
        if (state != BluetoothAdapterState.on) {
          _showStatusMessage(message: "Menyalakan Bluetooth...");
          await FlutterBluePlus.turnOn();
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      _showStatusMessage(message: "Gagal akses Bluetooth");
      return;
    }

    setState(() => _isScanning = true);
    _showStatusMessage(message: "Mencari Perangkat...");

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      setState(() => _isScanning = false);
      _showStatusMessage(message: "Error Scanning");
      return;
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == TARGET_DEVICE_NAME || r.advertisementData.localName == TARGET_DEVICE_NAME) {
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          break;
        }
      }
    });

    Future.delayed(const Duration(seconds: 11), () {
      if (_isConnected == false && _isScanning) {
        if (mounted) {
          setState(() => _isScanning = false);
          _showStatusMessage(message: "Tidak Ditemukan");
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _showStatusMessage(message: "Menghubungkan...");

      await device.connect(autoConnect: false);

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _isScanning = false;
        _isManualDisconnect = false;
      });

      _showStatusMessage(message: "Terhubung!");

      _rssiBuffer.clear();

      _connectionStateSubscription = device.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDeviceDisconnect(customMessage: "Device Disconnected!");
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase().contains(SERVICE_UUID)) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString().toUpperCase().contains(CHARACTERISTIC_UUID)) {

              _targetCharacteristic = c;

              await c.setNotifyValue(true);
              _valueSubscription = c.lastValueStream.listen((value) {
                _parseHeartRate(value);
              });
              _startRssiStream();
            }
          }
        }
      }

    } catch (e) {
      print("Error Connecting: $e");
      _handleDeviceDisconnect(customMessage: "Gagal Terhubung");
    }
  }

  void _handleDeviceDisconnect({String? customMessage}) {
    _connectionStateSubscription?.cancel();
    _valueSubscription?.cancel();

    _rssiBuffer.clear();

    if (mounted) {
      bool wasManual = _isManualDisconnect;

      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _targetCharacteristic = null;
        _heartRate = 0;
        _distanceStr = "-";
        _distanceStatus = "-";
        _isScanning = false;
        _isAlarmActive = false;
        _isManualDisconnect = false;
      });

      if (wasManual) {
        _showStatusMessage(message: "Terputus (Manual)");
      } else {
        _showStatusMessage(message: customMessage ?? "Terputus. Mencari kembali...");

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isConnected && !_isScanning) {
            print("DEBUG: Auto-reconnect triggered");
            _startScanAndConnect();
          }
        });
      }
    }
  }

  Future<void> _disconnectDevice() async {
    await _connectedDevice?.disconnect();
  }

  void _parseHeartRate(List<int> value) {
    if (value.isNotEmpty) {
      int flag = value[0];
      int bpm = 0;
      if ((flag & 0x01) == 0) {
        bpm = value[1];
      } else {
        bpm = (value[2] << 8) + value[1];
      }

      if (mounted) {
        setState(() {
          _heartRate = bpm;
        });
      }

      if (bpm > _bpmThreshold) {
        if (_lastNotificationTime == null || DateTime.now().difference(_lastNotificationTime!) > const Duration(seconds: 10)) {

          _showLocalNotification(
              "PERINGATAN BAHAYA!",
              "Detak jantung anak tinggi: $bpm BPM"
          );
          _lastNotificationTime = DateTime.now();
        }
      }
    }
  }

  void _startRssiStream() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isConnected || _connectedDevice == null) {
        timer.cancel();
        return;
      }
      try {
        int rssi = await _connectedDevice!.readRssi();
        _updateSmoothedDistance(rssi);
      } catch (e) { }
    });
  }

  void _updateSmoothedDistance(int rawRssi) {
    _rssiBuffer.add(rawRssi);

    if (_rssiBuffer.length > _rssiWindowSize) {
      _rssiBuffer.removeAt(0);
    }

    double avgRssi = _rssiBuffer.reduce((a, b) => a + b) / _rssiBuffer.length;

    int txPower = -75;
    double n = 2.5;

    double distance = pow(10, ((txPower - avgRssi) / (10 * n))).toDouble();

    //if (avgRssi < -90) {
      //distance = 20.0; // Paksa set ke jarak jauh (di luar batas aman)
    //}

    double limitMeters = 5.0;
    if (_distanceLevel == 1.0) limitMeters = 10.0;
    if (_distanceLevel >= 2.0) limitMeters = 15.0;

    if (mounted) {
      setState(() {
        if (distance < 1.0) {
          _distanceStr = "< 1 m";
          _distanceStatus = "Sangat Dekat";
        } else {
          _distanceStr = "${distance.toStringAsFixed(1)} m";

          if (distance <= limitMeters) {
            _distanceStatus = "Aman";
          } else {
            _distanceStatus = "Terlalu Jauh!";

            if (_lastNotificationTime == null || DateTime.now().difference(_lastNotificationTime!) > const Duration(seconds: 10)) {

              _showLocalNotification(
                  "PERINGATAN JARAK!",
                  "Anak menjauh: ${distance.toStringAsFixed(1)}meter"
              );
              _lastNotificationTime = DateTime.now();
            }
          }
        }
      });
    }
  }

  // --- UI HELPER ---

  void _showStatusMessage({String? message}) {
    _statusTimer?.cancel();
    if (mounted) {
      setState(() {
        _tempMessage = message;
        _isStatusVisible = true;
      });
    }
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isStatusVisible = false);
    });
  }

  void _onBluetoothPressed() {
    if (_isConnected) {
      setState(() {
        _isManualDisconnect = true;
      });
      _disconnectDevice();
    } else {
      if (_isScanning) {
        setState(() {
          _isManualDisconnect = true;
        });
        FlutterBluePlus.stopScan();
        setState(() => _isScanning = false);
        _showStatusMessage(message: "Pencarian Dihentikan");
      } else {
        _startScanAndConnect();
      }
    }
  }

  void _toggleAlarm() async {
    if (_targetCharacteristic == null) {
      if (!_isConnected) {
        _showStatusMessage(message: "Hubungkan Bluetooth Terlebih Dahulu!");
      } else {
        _showStatusMessage(message: "Sedang memuat fitur, coba lagi...");
      }
      return;
    }

    if (!_targetCharacteristic!.properties.write) {
      print("DEBUG: Properti WRITE tidak ditemukan! Coba restart Bluetooth HP.");
      _showStatusMessage(message: "Error: Refresh Bluetooth HP Anda!");
      return;
    }

    setState(() {
      _isAlarmActive = !_isAlarmActive;
    });

    String message = _isAlarmActive ? "Alarm ON!" : "Alarm OFF!";
    _showStatusMessage(message: message);

    try {
      String command = _isAlarmActive ? "1" : "0";
      await _targetCharacteristic!.write(command.codeUnits);
      print("Perintah Buzzer dikirim: $command");
    } catch (e) {
      print("Gagal mengirim perintah ke ESP32: $e");
      setState(() => _isAlarmActive = !_isAlarmActive);
      _showStatusMessage(message: "Gagal Kirim: Restart BT HP");
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMMM d', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Text("Childify", style: AppStyles.headerTitle),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedDate, style: AppStyles.dateText),
                        Text(_childName, style: AppStyles.childName),
                      ],
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person_outline, size: 32, color: Colors.white)
                          : null,
                    )
                  ],
                ),
              ],
            ),
          ),

          // --- BODY ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  DistanceCard(
                    isConnected: _isConnected,
                    distanceValue: _distanceStr,
                    statusText: _distanceStatus,
                  ),
                  const SizedBox(height: 70),
                  HeartRateCard(
                    isConnected: _isConnected,
                    bpmValue: _heartRate,
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM CONTROL ---
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipPath(
                clipper: BottomCurveClipper(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.mainGradient,
                  ),
                ),
              ),

              Positioned(
                bottom: 80,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. TOMBOL BLUETOOTH
                    ControlButton(
                      icon: _isConnected
                          ? Icons.bluetooth_connected
                          : (_isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled),
                      iconColor: _isScanning
                          ? Colors.orange
                          : (_isConnected ? Colors.green : Colors.grey),
                      onTap: _onBluetoothPressed,
                    ),
                    const SizedBox(width: 40),

                    // 2. TOMBOL SIRINE (BUZZER)
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: ControlButton(
                        assetPath: 'assets/icons/siren_icon.svg',
                        iconColor: _isAlarmActive
                            ? const Color(0xFFEA3323) // Merah (Aktif)
                            : AppColors.inactiveGrey, // Abu-abu (Mati)
                        isProminent: true,
                        isSvg: true,
                        onTap: _toggleAlarm,
                      ),
                    ),

                    const SizedBox(width: 40),

                    // 3. TOMBOL SETTING
                    ControlButton(
                      icon: Icons.settings_outlined,
                      iconColor: Colors.grey,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                        _loadPreferences();
                      },
                    ),
                  ],
                ),
              ),

              // --- STATUS BAR ---
              Positioned(
                bottom: 30,
                child: AnimatedOpacity(
                  opacity: _isStatusVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: Text(
                      _getStatusText(),
                      style: AppStyles.bottomStatus,
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_tempMessage != null) return _tempMessage!;
    if (_isScanning) return "Mencari Perangkat...";
    if (_isConnected) return "Terhubung ke Childify!";
    return "Bluetooth Terputus";
  }
}