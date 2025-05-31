# Pantanizz – Sistem Monitoring & Otomatisasi Hidroponik Kekinian

**Pantanizz** adalah sistem monitoring dan otomatisasi hidroponik berbasis IoT yang membantu kamu **pantau tani secara real-time, kapan saja, di mana saja — bahkan sambil tidur!** Dengan teknologi sensor canggih dan aplikasi mobile berbasis Flutter, Pantanizz memudahkan pengelolaan hidroponik secara otomatis, efisien, dan modern.

---

## Filosofi Nama Pantanizz

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

* `/hydroponic_controller`
  Firmware ESP32 untuk pembacaan sensor, kontrol relay, dan komunikasi MQTT.
* `/golang_backend`
  Backend Golang yang menerima data MQTT, menyimpan, dan menyediakan REST API untuk aplikasi.
* `/flutter_app`
  Aplikasi mobile/web Flutter untuk monitoring dan kontrol sistem secara real-time.

---

## Cara Menjalankan

### 1. Firmware ESP32

* Hubungkan sensor dan relay sesuai pin konfigurasi.
* Sesuaikan WiFi dan MQTT broker pada file konfigurasi.
* Upload firmware dengan PlatformIO atau Arduino IDE.

```bash
cd hydroponic_controller
pio run --target upload
```

### 2. Backend Golang

* Pastikan Go sudah terinstal.
* Jalankan backend server:

```bash
cd golang_backend
go mod tidy
go run main.go
```

* API tersedia di: `http://localhost:8080/getSensorData`

### 3. Flutter App

* Pastikan Flutter SDK terpasang.
* Install dependencies dan jalankan aplikasi:

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## Tampilan Aplikasi 

https://github.com/user-attachments/assets/5091ad32-4771-4685-b755-3fd2159be740

* Grafik real-time untuk suhu, TDS, dan parameter lainnya
* Status sensor dan perangkat relay dengan warna indikator
* Tab kontrol perangkat (pompa air, pompa nutrisi, lampu)
* UI minimalis, modern, dan mudah digunakan

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
