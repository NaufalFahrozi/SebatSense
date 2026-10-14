<div align="center">

<img src="resources/drawables/launcher_icon.png" alt="SebatSense Logo" width="100" height="100">

# 🚬 SebatSense
### *Cigarette Tracker & Biometric Reality-Slap Telemetry*

**Garmin Connect IQ Watch App** untuk **Forerunner 165**

[![Connect IQ SDK](https://img.shields.io/badge/Connect%20IQ%20SDK-4.2.0%2B-blue?logo=garmin)](https://developer.garmin.com/connect-iq/sdk/)
[![Device](https://img.shields.io/badge/Device-Forerunner%20165-orange)](https://www.garmin.com/en-US/p/735520)
[![API Level](https://img.shields.io/badge/API%20Level-4.2.0-green)](https://developer.garmin.com/connect-iq/api-docs/)
[![Language](https://img.shields.io/badge/Language-Monkey%20C-yellow)](https://developer.garmin.com/connect-iq/monkey-c/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

*"Sekali hisap, realita bicara."*

</div>

---

## ✨ Tentang SebatSense

SebatSense adalah app Garmin yang dirancang dengan filosofi **zero-friction** — catat rokok cukup dengan **1 ketukan**, lalu jam tangan **otomatis tutup sendiri dalam 3 detik**. Tidak ada form, tidak ada konfirmasi. Cepat.

Yang membedakan SebatSense dari tracker biasa: **biometric reality-slap**. Setiap kali kamu catat rokok baru, app menganalisis data sensor jam tangan dari 25 menit setelah rokok *sebelumnya* dan menampilkan dampak nyata ke tubuhmu — berapa HR spike-nya, berapa poin stress naik, berapa detak jantung ekstra yang terpaksa dipompa, dan berapa rupiah yang sudah hangus hari ini.

---

## 📱 Tampilan & Fitur

### 🔭 Glance View (0 Klik)

> Geser ke bawah dari Watch Face → lihat status sekilas.

- **Sisa stok** rokok dalam bungkus (`Sisa: X/Y btg`)
- **Jumlah hari ini** (`Hari ini: Z batang`)
- **Fase pemulihan biologis** dengan progress bar berwarna:
  - 🔴 `0–20 mnt` — HR & Tekanan Darah masih naik
  - 🟠 `20–120 mnt` — CO Darah masih tinggi
  - 🟢 `>120 mnt` — O₂ & HR sudah pulih
- **Waktu sejak rokok terakhir** (`Terakhir: Xj Ym lalu`)
- **Prediksi kehabisan stok** berdasarkan EMA (`Habis: ~HH:MM`)

---

### ⚡ 1-Tap Auto-Log + 3-Detik Auto-Exit

Buka app dari Glance → **langsung tercatat otomatis**, tanpa tombol tambahan.

Selama 3 detik countdown berlangsung, tampilan menunjukkan:

| Elemen | Deskripsi |
|--------|-----------|
| 🔵 **Arc Bezel** | Countdown ring di pinggir layar (360°→240°→120°→exit) |
| 🩸 **Tamparan Realita** | Kartu biometrik dari rokok *sebelumnya*: HR Spike, Peak Stress, Ekstra Detak, Biaya |
| 🟡 **Banner** | Notif bungkus baru / peringatan chain-smoking |
| ✋ **Instruksi** | `"Tap layar / START = Batal & Menu"` |

> **Chain-Smoking Alert** (< 30 menit sejak rokok terakhir): Arc merah berkedip + getaran triple berat.

---

### ↩️ Undo & Dashboard Interaktif (Tap dalam 3 Detik)

Tap layar atau tekan START selama countdown → **log dibatalkan (undo)** + masuk **Dashboard 5 Halaman Minimalis** (geser atas/bawah/kiri/kanan atau gunakan tombol UP/DOWN):

#### 🩺 Halaman 1: Status Tubuh (Biometrics)
- Live Heart Rate (bpm) dari sensor jam tangan
- Status fase pemulihan biologis:
  - 🔴 `HR & Tensi Naik` (< 20 menit)
  - 🟠 `CO Darah Tinggi` (20–120 menit)
  - 🟢 `O2 & HR Pulih` / `Paru Aman` (> 120 menit)
- Countdown pemulihan detak jantung & pembersihan CO

#### 🩸 Halaman 2: Dampak Rokok (Reality-Slap)
- Lonjakan denyut nadi (*HR Spike*) dari rokok terakhir (`+X bpm`)
- Tingkat stres puncak (`X/100`) & akumulasi ekstra detak jantung hari ini
- Estimasi menit waktu kardio yang terbuang
- Status hijau aman dan bersih jika belum merokok hari ini

#### 📦 Halaman 3: Sisa Bungkus & Prediksi Stok
- Sisa batang per bungkus (`X / Y`) dengan indikator warna stok rendah
- Prediksi jam bungkus habis berdasarkan EMA interval konsumsi (`~HH:MM`)
- **START** atau **Tap Pill**: Buka *Menu Aksi Rokok*
  - `Catat 1 Batang Manual`
  - `Buka Bungkus Baru (Reset Stok)`
  - `Kurangi 1 Catatan (-1)`

#### 💸 Halaman 4: Uang Terbakar (Finansial)
- Total uang terbakar hari ini (Rp)
- Jumlah batang yang dikonsumsi hari ini
- Estimasi total pengeluaran rokok bulan berjalan (Rp)

#### ⚙️ Halaman 5: Pengaturan
- Harga per bungkus aktif & harga per batang
- Konfigurasi isi per bungkus: `12 / 16 / 20 batang`
- **START** atau **Tap Pill**: Buka *Menu Pengaturan*
  - Ubah isi bungkus
  - Ubah harga bungkus (`Rp 25.000` s/d `Rp 50.000`)
  - Reset hitungan hari ini

---

## 🧠 Cara Kerja (Teknikal)

### Algoritma Prediksi EMA

Interval antar rokok dihitung dengan **Exponential Moving Average** (α = 0.3):

```
EMA_baru = (EMA_lama × 7 + interval_baru × 3) / 10
```

Interval yang diabaikan (tidak merusak prediksi):
- < 5 menit (kemungkinan bukan rokok baru)
- > 4 jam (gap tidur malam)

### Analisis Retrospektif SensorHistory

Setiap kali app dibuka, sistem menganalisis **25 menit data sensor setelah rokok sebelumnya**:

```
Window analisis: lastSmokeTime → lastSmokeTime + 1500 detik
HR Spike = max(HR dalam window) − HR_baseline
Peak Stress = max(Stress dalam window)
```

Data diambil dari `Toybox.SensorHistory` (HR + Stress). Jika data tidak tersedia (simulator/sensor off), fallback ke nilai realistis minimum.

### Kalkulasi Ekstra Detak

```
Ekstra Detak per rokok = HR_spike × 30 menit × 60 detik/menit
                       = HR_spike × 1800
Namun disederhanakan → spike × 30 (per-rokok unit)
```

---

## 📂 Struktur Proyek

```
SebatSense/
├── manifest.xml                  # Konfigurasi app, target fr165
├── monkey.jungle                 # Build script
├── resources/
│   ├── strings/strings.xml       # String AppName
│   └── drawables/drawables.xml   # Deklarasi ikon launcher
└── source/
    ├── SebatApp.mc               # Entry point AppBase
    ├── SebatDataManager.mc       # [:glance] Data layer murni
    ├── SebatGlanceView.mc        # [:glance] UI strip glance
    ├── SebatView.mc              # View utama: countdown + dashboard
    ├── SebatDelegate.mc          # BehaviorDelegate input handling
    └── SebatMenuDelegate.mc      # Menu2InputDelegate (stock & settings)
```

### Pemisahan Glance vs Full-App Scope

```
(:glance) SebatDataManager   ←── hanya Storage, Time, Gregorian, Lang
(:glance) SebatGlanceView    ←── hanya SebatDataManager + Graphics

SebatView                    ←── + Activity, SensorHistory, Attention, Timer
SebatDelegate                ←── + WatchUi, System
SebatMenuDelegate            ←── + WatchUi
```

> Ini adalah pola arsitektur kritis di Connect IQ — Glance scope memiliki API terbatas dan kompilasi terpisah. Seluruh kode yang dipanggil dari Glance **wajib** dianotasi `(:glance)` dan **tidak boleh** memanggil API non-glance.

---

## 🗄️ Storage Schema

| Key | Tipe | Default | Keterangan |
|-----|------|---------|------------|
| `packSize` | Number | 16 | Batang per bungkus |
| `packPrice` | Number | 36000 | Harga bungkus (IDR) |
| `packLeft` | Number | 16 | Sisa dalam bungkus aktif |
| `todayCount` | Number | 0 | Jumlah rokok hari ini |
| `monthCount` | Number | 0 | Jumlah rokok bulan ini |
| `lastLogDay` | Number | 0 | YYYYMMDD untuk deteksi rollover |
| `lastLogMonth` | Number | 0 | Bulan untuk deteksi rollover |
| `lastSmokeTime` | Number | 0 | Epoch Unix rokok terakhir |
| `lastSmokeBaseHr` | Number | 75 | HR saat rokok terakhir dinyalakan |
| `avgIntervalSec` | Number | 5400 | EMA jeda antar rokok (detik) |
| `lastHrSpike` | Number | 0 | Delta HR peak dari rokok sebelumnya |
| `lastPeakStress` | Number | 0 | Peak stress 0–100 dari rokok sebelumnya |
| `todayExtraBeats` | Number | 0 | Akumulasi ekstra detak jantung hari ini |
| `previousStateSnapshot` | Dictionary | — | Buffer undo 1-tap |

---

## 🔧 Build & Install

### Prasyarat

- [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) versi **4.2.0+**
- JDK 11+
- `monkeyc` tersedia di PATH

### 1. Buat Launcher Icon

```powershell
# Menggunakan ImageMagick
magick -size 70x70 xc:#111111 `
       -fill "#FF6600" -draw "circle 35,35 35,4" `
       -fill white -font "Arial-Bold" -pointsize 13 `
       -gravity center -annotate 0 "SEBAT" `
       resources\drawables\launcher_icon.png
```

### 2. Build

```powershell
monkeyc `
  --output SebatSense.prg `
  --manifest manifest.xml `
  --jungle monkey.jungle `
  --device fr165 `
  --sdk "%GARMIN_HOME%\Devices" `
  --typecheck strict
```

### 3. Test di Simulator

```powershell
monkeybrains --device fr165 --prg SebatSense.prg --sdk "%GARMIN_HOME%"
```

### 4. Sideload via USB

```powershell
# Sambungkan Forerunner 165 via USB, ganti E: dengan drive watch kamu
Copy-Item SebatSense.prg "E:\GARMIN\APPS\SebatSense.prg"
```

---

## 🎯 Target Perangkat

| Properti | Nilai |
|----------|-------|
| **Device ID** | `fr165` |
| **Resolusi** | 390 × 390 px |
| **Layar** | Round AMOLED Touchscreen |
| **API Level** | 4.2.0 |
| **Fitur** | Glance, Touch, SensorHistory |

---

## 🛠️ Troubleshooting

| Masalah | Penyebab & Solusi |
|---------|-------------------|
| `Symbol Not Found` di glance scope | API non-glance dipanggil dari `SebatGlanceView` atau `SebatDataManager`. Pastikan kedua file ini bebas dari `Activity`/`SensorHistory`/`Attention`. |
| NullPointerException pada HR | Normal di simulator. `getCurrentHr()` punya fallback chain Activity → SensorHistory → 75 bpm. |
| SensorHistory selalu kosong | Normal di simulator. `analyzeImpact()` otomatis fallback ke spike=12, stress=35. |
| Arc bezel tidak terlihat | Pastikan `dc.setPenWidth(8)` dipanggil sebelum `drawArc` dan reset ke `1` setelahnya. |
| Icon launcher tidak muncul | Letakkan file PNG 70×70 di `resources/drawables/launcher_icon.png`. |

---

## 🗺️ Roadmap

- [ ] Tambah data visualisasi trend mingguan (bar chart)
- [ ] Notifikasi widget reminder jika terlalu cepat merokok
- [ ] Export data ke Garmin Connect activity note
- [ ] Support multi-device (fr265, Venu 3, Epix)
- [ ] Deteksi otomatis pola merokok (pagi/siang/malam)

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah **MIT License** — lihat file [LICENSE](LICENSE) untuk detail.

---

## 🙏 Acknowledgements

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/) — platform dan dokumentasi
- [Monkey C Language](https://developer.garmin.com/connect-iq/monkey-c/) — runtime bahasa
- Komunitas Garmin Developer Forum atas berbagai snippet dan tips

---

<div align="center">

**Dibuat dengan ☕ dan 🚬 (yang sedang dikurangi)**

*SebatSense — karena kesadaran adalah langkah pertama.*

</div>
