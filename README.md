# AYOSEHAT — Rencana Olahraga Kamu

Aplikasi Flutter untuk mahasiswa yang mau olahraga rutin tapi jadwalnya sering berubah mendadak.
Saat agenda kuliah, rapat, atau tugas bentrok dengan sesi olahraga, AYOSEHAT memindahkan sesi itu ke slot kosong terdekat.

## Fitur versi 0.1

**1. Jadwal + pindah sesi otomatis**
- Agenda kuliah / organisasi / tugas (sekali atau tiap minggu).
- Sesi olahraga (bisa diulang 4 minggu), dengan cek bentrok saat dibuat.
- Saat agenda ditambah atau jamnya diubah, sesi yang bentrok otomatis dipindah:
  hari yang sama dulu (sedekat mungkin dengan jam semula), lalu maksimal 2 hari berikutnya,
  antara 05.30–21.30, dengan jeda 15 menit dari agenda lain.
- Kalau tidak bisa dipindah otomatis: kartu "Jadwal bentrok" di Beranda + pilihan slot manual.
- Tandai sesi selesai / dilewati, statistik minggu ini.

**2. Paywall Pro + trial 14 hari** (sesuai Startup Sustainability Blueprint v1)
- Gratis: pindah otomatis **2x per minggu**, pindah manual tanpa batas.
- Pro: pindah otomatis **tanpa batas**, **Rp35.000 / semester** (berlaku 6 bulan).
- Trial Pro gratis 14 hari; setelah habis kembali ke Gratis.
- Pembayaran QRIS masih **mode demo** (belum terhubung payment gateway).

**3. Latihan terpandu (tab Latihan)**
- 6 latihan tanpa alat: Ringan, Sedang, Berat × 15 dan 30 menit.
- Thumbnail asli video YouTube, dan video diputar langsung di dalam aplikasi
  (package `youtube_player_iframe`), plus tombol "Buka di aplikasi YouTube".
- Daftar video ada di `lib/workouts.dart` (ganti `videoId` untuk memakai video lain).

**Mode demo (tab Profil)**: isi contoh jadwal maba & simulasi "rapat mendadak" untuk presentasi.

Data tersimpan lokal di HP (shared_preferences), belum ada akun/server.

## Cara menjalankan

Butuh [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.16 ke atas).

```bash
cd ayosehat
# 1. Buat folder platform (android/ios). File yang sudah ada TIDAK ditimpa.
flutter create --project-name ayosehat --org id.ayosehat --platforms android,ios .
# 2. Ambil dependency
flutter pub get
# 3. Tes logika inti
flutter test
# 4. Jalankan di HP (USB debugging) atau emulator
flutter run
```

Membuat APK untuk dibagikan ke peserta uji coba:

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

Wajib untuk video & thumbnail: tambahkan izin internet di
`android/app/src/main/AndroidManifest.xml`, tepat di atas `<application`:
`<uses-permission android:name="android.permission.INTERNET"/>`
(GitHub Actions di `.github/workflows/build-apk.yml` sudah melakukannya otomatis.)

Opsional: ganti nama aplikasi di HP menjadi "AYOSEHAT" lewat
`android/app/src/main/AndroidManifest.xml` → `android:label="AYOSEHAT"`.

## Struktur kode

```
lib/
  main.dart              # app, tema, navigasi bawah
  app_state.dart         # data + aturan bisnis (trial, kuota, pindah otomatis)
  scheduler.dart         # algoritma cari slot kosong
  models.dart            # Agenda, Session
  screens/               # Beranda, Jadwal, Pro, Profil, form
  widgets/               # kartu sesi, aksi sesi, komponen umum
assets/logo.png          # logo AYOSEHAT
test/widget_test.dart    # tes logika inti
```

## Belum ada di versi ini
- Notifikasi pengingat, squad teman, program latihan 15 menit.
- Pembayaran sungguhan (QRIS via payment gateway) dan akun pengguna.
