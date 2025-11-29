#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "esp_bt.h" // Library untuk kontrol power bluetooth

// --- KONFIGURASI PIN ---
#define PULSE_PIN  1      // Sensor Detak Jantung
#define LED_PIN    2      // LED Indikator
#define BUZZER_PIN 3      // Buzzer Alarm

// --- KONFIGURASI SENSOR ---
#define THRESHOLD 2500    

// --- KONFIGURASI BLE ---
#define SERVICE_UUID        "180D"
#define CHARACTERISTIC_UUID "2A37"

// Variabel Global
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Variabel BPM
int myBPM = 0;
unsigned long lastBeatTime = 0; 
bool isSystole = false;         
unsigned long lastReportTime = 0;

bool isAlarmActive = false;       // Status apakah alarm harus bunyi
unsigned long lastBuzzerTime = 0; // Timer untuk interval beep
bool buzzerState = LOW;           // Status On/Off sementara untuk efek beep
const int BUZZER_INTERVAL = 300;  // Durasi beep (500ms bunyi, 500ms diam)

// --- CALLBACK BLE (Terima Data dari HP) ---
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue();
      if (value.length() > 0) {
        if (value[0] == '1') {
          Serial.println("ALARM AKTIF (Mode Beep)");
          isAlarmActive = true; // Aktifkan flag, logika bunyi ada di loop()
        } else {
          Serial.println("ALARM MATI");
          isAlarmActive = false;
          digitalWrite(BUZZER_PIN, LOW); // Matikan paksa segera
        }
      }
    }
};

// --- CALLBACK KONEKSI ---
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Smartphone Terhubung!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Smartphone Terputus!");
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Memulai Childify...");

  // 1. Konfigurasi Pin
  pinMode(PULSE_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  
  // Resolusi ADC 12-bit (0-4095)
  analogReadResolution(12); 

  // Kondisi Awal: LED Nyala, Buzzer Mati
  digitalWrite(LED_PIN, HIGH); 
  digitalWrite(BUZZER_PIN, LOW);

  // 2. Inisialisasi BLE
  BLEDevice::init("ESP32-Childify");

  // Maksimalkan Power TX (+9dBm)
  esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_ADV, ESP_PWR_LVL_P9); 
  esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_CONN_HDL0, ESP_PWR_LVL_P9); 
  esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_DEFAULT, ESP_PWR_LVL_P9);
  
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_WRITE  
                    );

  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("Sistem Siap. Menunggu Koneksi...");
}

void loop() {
  unsigned long currentTime = millis();
  // ============================================================
  // BAGIAN 1: LOGIKA ALARM BERKEDIP (PULSING)
  // ============================================================
  if (isAlarmActive) {
    // Cek apakah sudah waktunya ganti status (Beep -> Diam -> Beep)
    if (currentTime - lastBuzzerTime > BUZZER_INTERVAL) {
      buzzerState = !buzzerState; // Balik status (HIGH jadi LOW, LOW jadi HIGH)
      digitalWrite(BUZZER_PIN, buzzerState);
      lastBuzzerTime = currentTime;
    }
  } else {
    // Pastikan mati jika tidak aktif
    // (Kita panggil di sini juga untuk safety double-check)
    digitalWrite(BUZZER_PIN, LOW);
  }
  // ============================================================
  // BAGIAN 2: PEMBACAAN SENSOR (JALAN TERUS MENERUS)
  // ============================================================
  int signalAnalog = analogRead(PULSE_PIN);

  // Deteksi Fase SISTOL (Puncak Gelombang)
  if (signalAnalog > THRESHOLD && isSystole == false) {
      // Debounce 300ms (Max ~200 BPM)
      if (currentTime - lastBeatTime > 300) {
          isSystole = true; 
          unsigned long delta = currentTime - lastBeatTime;
          lastBeatTime = currentTime;

          int rawBPM = 60000 / delta;
          
          // Filter BPM tidak masuk akal
          if (rawBPM > 40 && rawBPM < 220) {
             // Smoothing (Rata-rata bergerak)
             if (myBPM == 0) myBPM = rawBPM; 
             else myBPM = (myBPM * 0.7) + (rawBPM * 0.3);
             
             Serial.print("♥ Detak: "); 
             Serial.println(myBPM);
          }
      }
  }

  // Deteksi Fase DIASTOL (Lembah Gelombang)
  if (signalAnalog < (THRESHOLD - 100) && isSystole == true) {
      isSystole = false; 
  }

  // ============================================================
  // BAGIAN 3: KIRIM DATA BLE (SETIAP 1 DETIK)
  // ============================================================
  if (deviceConnected) {
      if (currentTime - lastReportTime > 1000) {
          uint8_t bpmPacket[2];
          bpmPacket[0] = 0b00000000; // Flag UINT8
          bpmPacket[1] = (uint8_t)myBPM; 

          pCharacteristic->setValue(bpmPacket, 2);
          pCharacteristic->notify(); 
          
          Serial.print(">> Data Terkirim: ");
          Serial.println(myBPM);
          
          lastReportTime = currentTime;
      }
  }

  // ============================================================
  // BAGIAN 4: RECONNECT LOGIC
  // ============================================================
  if (!deviceConnected && oldDeviceConnected) {
      delay(500); 
      pServer->startAdvertising(); 
      Serial.println("Koneksi putus. Advertising kembali...");
      oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
      oldDeviceConnected = deviceConnected;
  }
  
  delay(20); // Delay kecil untuk stabilitas
}