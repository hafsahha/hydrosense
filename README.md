# HydroSense - Sistem Monitoring & Otomatisasi Hidroponik

HydroSense adalah proyek sistem monitoring dan otomatisasi hidroponik yang menggunakan sensor untuk memantau kondisi larutan nutrisi seperti suhu, kelembaban, TDS, pH, dan cahaya. Data sensor dikirimkan secara real-time menggunakan ESP32 ke broker MQTT, kemudian backend Golang menyediakan REST API untuk aplikasi mobile Flutter yang menampilkan visualisasi data dan status sistem.

---

## Fitur Utama

- Monitoring suhu, kelembaban, TDS, pH, dan cahaya secara real-time  
- Kontrol otomatis pompa air bersih dan nutrisi berdasarkan kondisi larutan  
- Visualisasi data menggunakan aplikasi Flutter dengan grafik dan status alert  
- Backend Golang mengelola komunikasi MQTT dan API REST untuk frontend  

---

## Struktur Repo

- `/hydroponic_controller` : Kode program ESP32 untuk sensor dan kontrol pompa  
- `/golang_backend` : Backend server Golang untuk MQTT subscriber dan REST API  
- `/flutter_app` : Aplikasi mobile Flutter untuk monitoring dan visualisasi data  

---

## Cara Menjalankan

1. **ESP32 Firmware**  
   Upload kode di folder `/hydroponic_controller` ke ESP32 dengan Arduino IDE atau PlatformIO.

2. **Backend Golang**  
   Jalankan server backend dengan:  
   ```bash
   cd golang_backend
   go run main.go
   ```

3. **Flutter App**
   Jalankan aplikasi Flutter di emulator atau device dengan:

   ```bash
   cd flutter_app
   flutter run
   ```

---

# Tampilan Aplikasi 

https://github.com/user-attachments/assets/5091ad32-4771-4685-b755-3fd2159be740

---

## Identitas Pembuat

Kelompok 4

* Sifa Imania Nurul Hidayah (2312084)
* Dina Agustina (2303573)
* Hafsah Hamidah (2311474)

---


## Lisensi

MIT License © 2025 Kelompok 4 IoT
