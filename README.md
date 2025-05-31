# PantaniZz – Sistem Monitoring & Otomatisasi Hidroponik Kekinian

**PantaniZz** adalah sistem monitoring dan otomatisasi hidroponik berbasis IoT yang membantu kamu **pantau tani secara real-time, kapan saja, di mana saja — bahkan sambil tidur!** Dengan teknologi sensor canggih dan aplikasi mobile berbasis Flutter, PantaniZz memudahkan pengelolaan hidroponik secara otomatis, efisien, dan modern.

---

## Filosofi Nama PantaniZz

* **Pan** = *Pantau* — Fokus pada pemantauan kondisi tanaman dan lingkungan secara real-time.
* **Tani** = *Tani* — Merujuk pada pertanian, khususnya hidroponik modern.
* **zz** = *zzz* (tidur) — Menandakan sistem yang bekerja otomatis, sehingga kamu bisa tenang dan istirahat tanpa harus cek manual terus-menerus.

Tagline:

> *Pantau Tani Sambil Tidur*

---

## Fitur Utama

* **Monitoring real-time** parameter hidroponik:

  * Suhu udara & kelembaban (DHT22)
  * Suhu air (DS18B20)
  * TDS (Total Dissolved Solids) untuk konsentrasi nutrisi
  * pH larutan nutrisi
  * Intensitas cahaya (LDR)
* **Otomatisasi cerdas berbasis data sensor**:

  * Pompa air bersih menyala otomatis saat TDS > 1200 ppm (pengenceran larutan)
  * Pompa nutrisi menyala otomatis saat TDS < 650 ppm (penambahan nutrisi)
  * Lampu grow light otomatis aktif saat intensitas cahaya < 1500 lux
* **Aplikasi Flutter multi-platform** dengan:

  * Visualisasi grafik tren data waktu nyata
  * Indikator status parameter dengan kode warna intuitif
  * Kontrol dan monitoring perangkat secara mudah dan responsif
* **Arsitektur IoT modern**:

  * ESP32 sebagai sensor dan pengontrol utama
  * MQTT broker untuk komunikasi cepat dan andal
  * Backend Golang untuk pengolahan data dan penyedia REST API
  * Flutter front-end yang responsif untuk mobile dan web

---

## Struktur Repo

* `/hydroponic_controller` - Firmware ESP32
  * `src/main.cpp` - Program utama untuk membaca sensor dan kontrol relay
  * Menggunakan PlatformIO untuk manajemen dependensi dan upload firmware
  
* `/golang_backend` - Server backend Golang
  * `main.go` - Server Go untuk MQTT client dan REST API
  * Menggunakan library paho.mqtt untuk komunikasi broker MQTT
  
* `/flutter_app` - Aplikasi mobile/web Flutter
  * `lib/main.dart` - Aplikasi untuk visualisasi data dan monitor status
  * `assets/logo.png` - Logo PantaniZz
  * Menggunakan fl_chart untuk visualisasi grafik

---

## Cara Menjalankan

### 1. Firmware ESP32

* Hubungkan sensor dan relay sesuai konfigurasi pin berikut:
  * DHT22 (Temp & humidity): Pin 23
  * DS18B20 (Water temp): Pin 25
  * TDS Sensor: Pin 33
  * pH Sensor: Pin 34
  * LDR Sensor: Pin 32
  * Relay Air Bersih: Pin 19
  * Relay Nutrisi: Pin 18
  * Relay Lampu: Pin 5

* Sesuaikan kredensial WiFi dan MQTT di kode:
  ```cpp
  const char* ssid = "nama_wifi_anda";
  const char* password = "password_wifi_anda";
  const char* mqttServer = "broker.emqx.io";
  ```

* Upload firmware dengan PlatformIO atau Arduino IDE:

  ```bash
  cd hydroponic_controller
  pio run --target upload
  ```

### 2. Backend Golang

* Pastikan Go sudah terinstal (v1.16 atau lebih baru).
* Download dependensi dan jalankan server:

  ```bash
  cd golang_backend
  go mod tidy
  go run main.go
  ```

* Server berjalan di port 8080 dengan endpoint:
  * GET `/getSensorData` - Mendapatkan data sensor terbaru

### 3. Flutter App

* Pastikan Flutter SDK terpasang (versi 3.0 atau lebih baru).
* Install dependencies dan jalankan aplikasi:

  ```bash
  cd flutter_app
  flutter pub get
  
  # Untuk browser (rekomendasi untuk testing)
  flutter run -d chrome
  
  # Untuk perangkat mobile
  flutter run
  ```

* Aplikasi secara otomatis mengambil data dari backend setiap 10 detik

---

## Tampilan Aplikasi 

<!-- ![Tampilan Aplikasi PantaniZz](https://github.com/user-attachments/assets/5091ad32-4771-4685-b755-3fd2159be740) -->

* **Tab Grafik** - Visualisasi real-time untuk suhu dan TDS dalam bentuk grafik
* **Tab Sensor Data** - Menampilkan data sensor (suhu, kelembaban, TDS, pH, cahaya, suhu air)
* **Tab Control Status** - Monitoring status perangkat (pompa air, pompa nutrisi, lampu grow)
* **Status Panel** - Indikator kualitas nutrisi dengan kode warna intuitif (hijau = baik)

---

## Detail Teknis

### Hardware

| Komponen       | Fungsi                                  |
| -------------- | --------------------------------------- |
| ESP32          | Kontrol utama dan pengirim data MQTT    |
| Sensor DHT22   | Suhu udara dan kelembaban               |
| Sensor DS18B20 | Suhu air                                |
| Sensor TDS     | Konsentrasi nutrisi larutan             |
| Sensor pH      | Tingkat keasaman larutan                |
| Sensor LDR     | Intensitas cahaya                       |
| Relay Module   | Mengendalikan pompa air, nutrisi, lampu |

### Arsitektur Sistem

```
+-------------+      +----------------+      +----------------+
|   ESP32     | ---> |  MQTT Broker   | ---> |  Backend Go    |
+-------------+      +----------------+      +-------+--------+
                                               |
                                               v
                                       +----------------+
                                       |  Flutter App   |
                                       +----------------+
```

### Komunikasi

* MQTT untuk pengiriman data sensor dari ESP32 ke server.
* REST API antara backend dan aplikasi Flutter.

### Data JSON

Data yang dikirim oleh ESP32:
```json
{
  "temperature": 27.9,
  "humidity": 76.2,
  "tds": 850.0,
  "light": 2100,
  "ph": 6.5,
  "water_temp": 25.8,
  "relay_air_bersih": false,
  "relay_nutrisi": false,
  "relay_lampu": true
}
```

Data yang disediakan oleh Backend Golang (dengan timestamp):
```json
{
  "temperature": 27.9,
  "humidity": 76.2,
  "tds": 850.0,
  "light": 2100,
  "ph": 6.5,
  "water_temp": 25.8,
  "relay_air_bersih": false,
  "relay_nutrisi": false,
  "relay_lampu": true,
  "timestamp": "2025-05-31T12:34:56Z"
}
```

---

## Logic Otomasi

| Kondisi TDS / Cahaya     | Aksi Otomatis                        |
| ------------------------ | ------------------------------------ |
| TDS > 1200 ppm           | Pompa air bersih aktif (pengenceran) |
| TDS < 650 ppm            | Pompa nutrisi aktif                  |
| Intensitas cahaya < 1500 | Lampu grow light menyala             |

---

## Tim Pengembang

**Kelompok 4 - Mata Kuliah Internet of Things (IoT)**

* Sifa Imania Nurul Hidayah (2312084)
* Dina Agustina (2303573)
* Hafsah Hamidah (2311474)

---

## Pengembangan Selanjutnya

* **Notifikasi push/email** untuk alert parameter kritis
* **Database historis** untuk analisis jangka panjang
* **Manual override** lewat aplikasi
* **Machine learning** untuk prediksi dan optimasi nutrisi
* **Integrasi kamera** untuk monitoring visual tanaman
* **Multi-sistem** untuk pengelolaan banyak hidroponik sekaligus

---

## Referensi

* [ESP32 Arduino Core](https://docs.espressif.com/projects/arduino-esp32/)
* [MQTT Protocol](https://mqtt.org/mqtt-specification/)
* [Flutter](https://docs.flutter.dev/)
* [Golang](https://golang.org/doc/)

---

## Lisensi

MIT License © 2025 Kelompok 4 IoT
