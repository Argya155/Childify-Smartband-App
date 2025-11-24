# 👶 Childify - Smart Child Monitoring System

Childify adalah aplikasi IoT berbasis Flutter yang terhubung dengan ESP32 Smartband untuk memantau keamanan anak secara real-time menggunakan Bluetooth Low Energy (BLE).

## 📱 Fitur Utama
- **Monitoring Detak Jantung:** Real-time BPM monitoring menggunakan sensor Pulse.
- **Estimasi Jarak:** Menggunakan sinyal RSSI untuk memperkirakan jarak anak.
- **Alarm Bahaya:** Bunyikan buzzer pada gelang anak langsung dari aplikasi.
- **Notifikasi Pintar:** Notifikasi otomatis jika anak terlalu jauh atau detak jantung tidak normal.

## 🛠️ Perangkat Keras (Hardware)
Proyek ini membutuhkan alat yang dirakit sendiri:
1. **Microcontroller:** ESP32-C3 / ESP32 Standard.
2. **Sensor:** Pulse Sensor (Analog Pin 1).
3. **Output:** - LED (Pin 2)
   - Buzzer (Pin 3)

<img width="563" height="407" alt="image" src="https://github.com/user-attachments/assets/11f35caa-8f94-464f-986c-84e7971b6dcc" />


## 🚀 Cara Install Aplikasi
1. Masuk ke menu **[Releases](../../releases)** di repository ini.
2. Download file `Childify-v1.0.apk`.
3. Install di HP Android Anda (Izinkan instalasi dari sumber tidak dikenal).
4. Pastikan Bluetooth dan Lokasi (GPS) aktif saat menggunakan aplikasi.

## 💻 Cara Upload Kode ke ESP32
1. Buka folder `firmware` di repository ini.
2. Buka file `esp32_childify.ino` menggunakan Arduino IDE.
3. Install Library `ESP32 BLE Arduino`.
4. Upload ke board ESP32 Anda.

## 📸 Screenshots

<img width="576" height="1280" alt="image" src="https://github.com/user-attachments/assets/a0fc89d3-727c-4a88-a4ae-734d1f436ebb" />

<img width="576" height="1280" alt="image" src="https://github.com/user-attachments/assets/183fd46a-bc3d-4c5a-aa74-4addf586c57a" />

---
Dibuat dengan ❤️ menggunakan Flutter & ESP32.
