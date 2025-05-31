# HydroSense - Sistem Monitoring & Otomatisasi Hidroponik

HydroSense adalah proyek sistem monitoring dan otomatisasi hidroponik yang menggunakan sensor untuk memantau kondisi larutan nutrisi dan lingkungan seperti suhu, kelembaban, TDS (Total Dissolved Solids), pH, suhu air, dan intensitas cahaya. Data sensor dikirimkan secara real-time menggunakan ESP32 ke broker MQTT, kemudian backend Golang menyediakan REST API untuk aplikasi mobile Flutter yang menampilkan visualisasi data dan status sistem.

Sistem ini dirancang untuk memudahkan pertanian hidroponik dengan otomatisasi berbagai komponen berdasarkan data sensor, seperti mengaktifkan pompa air bersih saat TDS terlalu tinggi, menambahkan nutrisi saat TDS rendah, dan menyalakan lampu grow light saat intensitas cahaya rendah.

---

## Fitur Utama

- Monitoring parameter hidroponik secara real-time:
  - Suhu udara dan kelembaban (DHT22)
  - Suhu air (DS18B20)
  - TDS (Total Dissolved Solids) untuk mengukur konsentrasi nutrisi
  - pH untuk mengukur keasaman larutan
  - Intensitas cahaya (LDR)
- Kontrol otomatis berbasis parameter:
  - Pompa air bersih aktif saat TDS > 1200 ppm (pengenceran)
  - Pompa nutrisi aktif saat TDS < 650 ppm (penambahan nutrisi)
  - Lampu grow light aktif saat intensitas cahaya rendah (< 1500)
- Visualisasi data melalui aplikasi Flutter:
  - Grafik real-time untuk memonitor tren parameter
  - Indikator status parameter dengan kode warna intuitif
  - Tab monitor status perangkat (ON/OFF)
- Arsitektur komunikasi IoT:
  - ESP32 sebagai controller dan publisher MQTT
  - Backend Golang sebagai subscriber MQTT dan penyedia REST API
  - Flutter sebagai aplikasi front-end multi-platform (mobile/web)

---

## Struktur Repo

- `/hydroponic_controller` : Kode program ESP32 (PlatformIO/Arduino) untuk:
  - Pembacaan sensor (DHT22, DS18B20, TDS, pH, LDR)
  - Kontrol relay untuk pompa air, nutrisi, dan lampu
  - Komunikasi dengan broker MQTT (EMQX)
  - Pengambilan keputusan otomasi berdasarkan nilai sensor
  
- `/golang_backend` : Backend server Golang dengan:
  - MQTT client untuk berlangganan topik dari ESP32
  - Pengolahan dan penyimpanan data sensor
  - REST API endpoint untuk aplikasi Flutter
  - Penambahan timestamp pada data untuk visualisasi
  
- `/flutter_app` : Aplikasi monitoring dengan:
  - Dashboard visualisasi data sensor
  - Grafik tren parameter waktu-nyata
  - Status relay dan kondisi sistem
  - UI responsif untuk web dan mobile

---

## Cara Menjalankan

1. **ESP32 Firmware**  
   - Pastikan semua sensor dan relay terhubung dengan benar sesuai dengan pin yang didefinisikan di kode
   - Sesuaikan kredensial WiFi dan broker MQTT di file konfigurasi jika diperlukan
   - Upload kode di folder `/hydroponic_controller` ke ESP32 menggunakan:
     ```bash
     # Menggunakan PlatformIO
     cd hydroponic_controller
     pio run --target upload
     
     # Atau dengan Arduino IDE
     # Buka main.cpp dan upload via Arduino IDE
     ```

2. **Backend Golang**  
   - Pastikan Go (Golang) terinstall di sistem anda
   - Instal dependensi yang diperlukan dan jalankan server:
     ```bash
     cd golang_backend
     go mod tidy
     go run main.go
     ```
   - Server akan berjalan di port 8080 dan mulai menerima data dari broker MQTT
   - Data sensor tersedia di endpoint: `http://localhost:8080/getSensorData`

3. **Flutter App**
   - Pastikan Flutter SDK terinstall dan path sudah dikonfigurasi
   - Jalankan aplikasi di emulator, browser atau perangkat fisik:
     ```bash
     cd flutter_app
     flutter pub get
     
     # Untuk mobile
     flutter run
     
     # Untuk web
     flutter run -d chrome
     ```
   - Pastikan backend Golang berjalan terlebih dahulu agar data dapat diambil

---

## Tampilan Aplikasi 

https://github.com/user-attachments/assets/5091ad32-4771-4685-b755-3fd2159be740

### Fitur UI

- **Tab Grafik**: Menampilkan tren data suhu dan TDS dalam bentuk grafik garis untuk analisis perubahan waktu
- **Tab Sensor Data**: Menampilkan data terkini dari semua sensor dengan indikator visual
- **Tab Control Status**: Menampilkan status perangkat relay (ON/OFF) yang terhubung dengan sistem
- **Status Panel**: Menunjukkan kondisi TDS dengan kode warna (hijau=ideal, merah=terlalu tinggi, kuning=terlalu rendah)

---

## Detail Teknis

### Komponen Hardware
- **ESP32**: Controller utama yang membaca sensor dan mengontrol relay
- **Sensor DHT22**: Mengukur suhu udara dan kelembaban
- **Sensor DS18B20**: Mengukur suhu air (waterproof)
- **Sensor TDS**: Mengukur konsentrasi nutrisi dalam larutan (Total Dissolved Solids)
- **Sensor pH**: Mengukur tingkat keasaman larutan
- **LDR (Light Dependent Resistor)**: Mengukur intensitas cahaya
- **Relay Module**: Mengontrol pompa air bersih, pompa nutrisi, dan lampu grow light

### Arsitektur Sistem
```
+-------------+        +----------------+        +----------------+
|   ESP32     |        |  MQTT Broker   |        |  Golang Server |
| (Publisher) +------->+ (EMQX Public) +------->+  (Subscriber)  |
+-------------+        +----------------+        +-------+--------+
                                                        |
                                                        v
                                                +----------------+
                                                |  Flutter App   |
                                                |  (Frontend)    |
                                                +----------------+
```

### Protokol Komunikasi
- **MQTT**: Digunakan antara ESP32 dan server Golang (topik: /sdh-auto-hydroponic)
- **HTTP**: Digunakan antara server Golang dan aplikasi Flutter (RESTful API)

### Format Data
Data dikirimkan dalam format JSON dengan struktur:
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

### Logic Otomasi
- Jika TDS > 1200 ppm: Aktifkan pompa air bersih untuk pengenceran
- Jika TDS < 650 ppm: Aktifkan pompa nutrisi untuk menambah konsentrasi
- Jika intensitas cahaya < 1500: Aktifkan lampu grow light

---

## Identitas Pembuat

**Kelompok 4 - Mata Kuliah Internet of Things (IoT)**

* **Sifa Imania Nurul Hidayah** (2312084)
* **Dina Agustina** (2303573)
* **Hafsah Hamidah** (2311474)

---

## Pengembangan Masa Depan

Beberapa ide untuk pengembangan sistem di masa mendatang:

- **Notifikasi**: Implementasi sistem notifikasi push/email saat parameter di luar ambang batas yang aman
- **Historis Data**: Penyimpanan data jangka panjang menggunakan database (PostgreSQL/MongoDB) 
- **Control Manual**: Kemampuan untuk override kontrol otomatis dari aplikasi
- **Machine Learning**: Implementasi prediksi pertumbuhan dan optimasi nutrisi berdasarkan data historis
- **Kamera**: Integrasi kamera untuk monitoring visual tanaman
- **Multiple Systems**: Kemampuan untuk mengelola beberapa sistem hidroponik sekaligus

## Referensi

- [ESP32 Arduino Core Documentation](https://docs.espressif.com/projects/arduino-esp32/)
- [MQTT Protocol Documentation](https://mqtt.org/mqtt-specification/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Golang Documentation](https://golang.org/doc/)

---

## Lisensi

MIT License © 2025 Kelompok 4 IoT
