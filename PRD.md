# PRD — Shortcut Tools

**Product Requirements Document** · v1.1 · 8 Oktober 2026
*(v1.1: + katalog lengkap, spesifikasi layar, edge cases)*

---

## 1. Ringkasan

**Shortcut Tools** adalah aplikasi Android utilitas yang berisi katalog
pintasan sekali-ketuk ke halaman-halaman pengaturan sistem yang biasanya
tersembunyi beberapa level di dalam aplikasi Settings — contoh: Private DNS
yang normalnya harus dibuka lewat Pengaturan → Jaringan → DNS.

Aplikasi **tidak mengubah** pengaturan secara langsung (tidak diizinkan
Android untuk aplikasi biasa); ia **membuka** halaman yang tepat, user
melakukan perubahan di sana.

---

## 2. Latar Belakang & Masalah

- Banyak pengaturan penting Android (Private DNS, Akses Notifikasi, Optimasi
  Baterai per-aplikasi) terkubur 3–5 level di dalam Settings.
- Tiap merek HP (Samsung, Xiaomi, dll.) menata menu berbeda — user makin sulit
  menemukan.
- Solusi yang ada (aplikasi "settings shortcut" generik) biasanya cuma daftar
  link tanpa fallback, tanpa personalisasi, dan berat iklan.

## 3. Tujuan

1. Membuka halaman Settings apapun dalam **≤ 2 ketuk** dari mana saja.
2. Tetap **ringan**: APK < 10 MB per ABI, tanpa permission berbahaya,
   tanpa background service.
3. Bertahan di perbedaan ROM/OEM lewat **rantai fallback intent**.

## 4. Target Pengguna

- Pengguna Android menengah–mahir yang sering utak-atik pengaturan
  (pengembang, teknisi, power user).
- Pengguna awam yang diberi tahu "aktifkan Private DNS" tapi tidak tahu
  letaknya.

## 5. Ruang Lingkup

**Masuk:**
- Katalog pintasan, pencarian + filter, favorit, riwayat otomatis.
- Akses cepat: Pin ke Home Screen, Quick Settings Tile, Home Screen Widget.
- Tema Terang/Gelap/Ikuti sistem, status live, onboarding, haptic.

**Tidak masuk (v1.0):**
- Mengubah setting secara programatik (butuh `WRITE_SECURE_SETTINGS`,
  hanya untuk aplikasi sistem — di luar jangkauan).
- iOS / desktop.
- Sinkronisasi cloud antar-perangkat.

---

## 6. Fitur Fungsional

### F-01 · Katalog pintasan
19 pintasan dalam 4 kategori (Jaringan, Perangkat, Aplikasi, Sistem).
Tiap entri: id, judul, deskripsi, ikon, intent action, daftar fallback,
`dataUri` opsional, `minSdk`, `globalKey` opsional, `keywords`.

**Acceptance criteria:**
- [ ] Semua 19 pintasan tampil dengan ikon & deskripsi yang benar.
- [ ] Menambah pintasan baru hanya butuh satu entri di `shortcuts_catalog.dart`.

### F-02 · Buka halaman Settings + rantai fallback
Tap → MethodChannel `openSettings` → native mencoba `action`, lalu tiap
`fallbacks`, terakhir `ACTION_SETTINGS`. Selalu `resolveActivity` +
try/catch — tidak pernah crash.

**Acceptance criteria:**
- [ ] Di emulator Pixel, tap "Private DNS" membuka halaman Private DNS.
- [ ] Bila action tidak didukung, jatuh ke fallback tanpa crash.
- [ ] `dataUri: "package:self"` ter-resolve ke package aplikasi.

### F-03 · Pencarian, filter kategori, keyword alias
Search field mencocokkan judul, deskripsi, **dan** `keywords`
(mis. "internet" → WiFi; "kuota" → Penggunaan Data). Chip kategori
memfilter grid.

**Acceptance criteria:**
- [ ] Ketik "dns" menampilkan Private DNS di urutan atas.
- [ ] Kombinasi query + chip kategori bekerja bersama.

### F-04 · Favorit
Tahan kartu → "Tambah ke Favorit". Baris horizontal "Favorit" selalu tampil
di atas. Badge bintang kuning. Tersimpan di SharedPreferences.

**Acceptance criteria:**
- [ ] Favorit bertahan setelah aplikasi ditutup & dibuka lagi.
- [ ] Urutan favorit = urutan penambahan.

### F-05 · Terakhir dibuka (otomatis)
Setiap pintasan yang berhasil dibuka tercatat (`RecentsService`, maks 8,
paling baru di depan). Baris "Terakhir dibuka" dengan tombol Hapus.

**Acceptance criteria:**
- [ ] Membuka 3 pintasan berbeda → ketiganya muncul berurutan benar.
- [ ] Membuka ulang pintasan lama → naik ke posisi pertama, tidak duplikat.

### F-06 · Pin ke Home Screen (Android 8+)
`ShortcutManager.requestPinShortcut` → dialog sistem → ikon di home screen.
Ditekan → aplikasi terbuka lalu langsung melompat ke halaman tujuannya
(ekstra intent → `consumePinnedShortcut`).

**Acceptance criteria:**
- [ ] Di launcher yang mendukung, dialog pin muncul.
- [ ] Ikon hasil pin membuka halaman yang benar, bukan halaman utama.

### F-07 · Quick Settings Tile (Android 7+)
`TileService`: satu tap dari notification shade membuka pintasan favorit
pilihan user (`unlockAndRun` + `startActivityAndCollapse`). Pilihan disimpan;
user menambah tile manual via panel Edit tiles.

**Acceptance criteria:**
- [ ] Tile membuka pintasan yang dipilih, shade tertutup otomatis.
- [ ] Mengganti pilihan di aplikasi mengubah perilaku tile.

### F-08 · Home Screen Widget
Widget 2×2 berisi hingga 4 tombol favorit. Tap → `WidgetLaunchActivity`
(transparan, **tanpa** Flutter engine) langsung membuka halamannya.
Data dibaca dari SharedPreferences Flutter; aplikasi memanggil
`refreshWidgets()` tiap favorit berubah. Kondisi kosong: tombol "Buka
aplikasi".

**Acceptance criteria:**
- [ ] Menambah/menghapus favorit me-refresh widget ≤ 2 detik.
- [ ] Tap tombol widget tidak membuka aplikasi (hanya halaman Settings).

### F-09 · Tema Terang / Gelap / Ikuti sistem
Ikon di AppBar → bottom sheet 3 pilihan. Tersimpan, berlaku instan.

**Acceptance criteria:**
- [ ] Pilihan bertahan setelah restart; mode Gelap mewarnai seluruh layar.

### F-10 · Status live
Badge/titik status dari `Settings.Global` tanpa permission
(contoh: `private_dns_mode` → Mati/Otomatis/Hostname kustom).

**Acceptance criteria:**
- [ ] Mengubah Private DNS di Settings lalu kembali → badge terupdate.

### F-11 · Onboarding sekali tampil
Bottom sheet petunjuk gestur (ketuk = buka, tahan = menu) di peluncuran
pertama; tombol "Mengerti".

**Acceptance criteria:**
- [ ] Hanya muncul sekali; tidak muncul di peluncuran kedua.

### F-12 · Haptic feedback
`selectionClick` saat tap kartu, `mediumImpact` saat long-press.

---

## 7. Persyaratan Non-Fungsional

| Aspek | Target |
|---|---|
| Ukuran APK | < 10 MB per ABI (`--split-per-abi`, R8 minify + shrinkResources) |
| Dependensi Dart | Hanya `shared_preferences` |
| Permission berbahaya | Tidak ada (tanpa lokasi/kontak/storage khusus) |
| Background service | Tidak ada |
| Cold start | < 1,5 dtk di perangkat menengah |
| Min SDK | 24 (Android 7.0) — untuk Quick Settings Tile |
| Crash | Tidak ada crash dari intent tak didukung (wajib fallback) |
| Aksesibilitas | Label konten pada tombol; kontras teks ≥ 4.5:1 |

## 8. Arsitektur Teknis

```
lib/
  main.dart                    → ThemeService.init + MaterialApp (themeMode reaktif)
  models/tool_shortcut.dart    → data class (action, fallbacks, keywords, …)
  data/shortcuts_catalog.dart  → 19 entri
  services/
    shortcut_service.dart      → MethodChannel "tools/shortcut"
    favorites_service.dart     → SharedPreferences (+ data JSON per favorit)
    recents_service.dart       → riwayat otomatis (maks 8)
    theme_service.dart         → ChangeNotifier ThemeMode
    onboarding_service.dart    → flag sekali-tampil
  screens/home_screen.dart     → search, chip, strip riwayat/favorit, grid kartu
android/
  MainActivity.kt              → handler channel: openSettings, getGlobalSetting,
                                 pinShortcut, setTileShortcut, consumePinnedShortcut,
                                 refreshWidgets
  ShortcutTileService.kt       → TileService
  ShortcutWidgetProvider.kt    → AppWidgetProvider (baca prefs Flutter)
  WidgetLaunchActivity.kt      → activity transparan untuk tap widget
  res/{layout,drawable,xml,values} → widget_shortcuts, info, adaptive icon
```

**Kontrak MethodChannel** (`tools/shortcut`):

| Method | Argumen | Balikan |
|---|---|---|
| `openSettings` | action, fallbacks, dataUri? | bool |
| `getGlobalSetting` | key | String? |
| `pinShortcut` | id, title, action, fallbacks, dataUri? | bool |
| `setTileShortcut` | id, action, fallbacks, dataUri? | void |
| `getTileShortcutId` | – | String? |
| `consumePinnedShortcut` | – | map? |
| `refreshWidgets` | – | void |

## 9. Izin Android & Batasan Platform

| Hal | Status |
|---|---|
| Membuka halaman Settings | Tanpa permission |
| Baca `Settings.Global` (key readable) | Tanpa permission |
| Pin shortcut | Tanpa permission (dialog sistem) |
| Quick Settings Tile | `BIND_QUICK_SETTINGS_TILE` (untuk service tile) |
| Mengubah setting langsung | **Tidak bisa** — butuh `WRITE_SECURE_SETTINGS` (aplikasi sistem) |
| Action undocumented (mis. Private DNS) | Bisa berubah antar ROM → wajib fallback |
| Menambah tile/widget programatik | **Tidak bisa** — user menambah manual |

## 10. UX

- **Gestur inti**: ketuk = buka langsung; tahan = bottom sheet
  (Buka / Favorit / Pin / Quick Tile).
- **Hierarki layar**: Terakhir dibuka → Favorit → Semua (grid kartu 3 kolom
  berisi ikon + judul + deskripsi).
- **Umpan balik**: haptic + snackbar bila halaman tak dapat dibuka.

## 11. Roadmap

- **MVP (v0.1)** — F-01 s.d. F-05, F-09, F-10, F-11, F-12. *Status: scaffold jadi.*
- **v0.2** — F-06 (Pin), F-07 (Tile). *Status: scaffold jadi.*
- **v0.3** — F-08 (Widget). *Status: scaffold jadi.*
- **v1.0** — Uji di 3+ perangkat (Pixel/AOSP, Samsung, Xiaomi); rapikan
  fallback per OEM; ikon final; rilis GitHub.
- **Ide lanjutan** — urutan favorit bisa di-drag; ekspor/impor daftar
  favorit; statistik pemakaian; pintasan kontribusian komunitas.

## 12. Risiko & Mitigasi

| Risiko | Mitigasi |
|---|---|
| Action undocumented berubah/hilang di ROM tertentu | Rantai fallback + `resolveActivity`; katalog per-OEM bila perlu |
| Samsung/Xiaomi me-rename halaman | Fallback ke halaman induk; terima laporan user |
| Widget tidak update di launcher tertentu | `refreshWidgets()` eksplisit + `updatePeriodMillis=0` |
| Ditolak Play Store | Tidak ada permission berbahaya; deskripsi jujur ("membuka halaman, bukan mengubah") |

## 13. Metrik Sukses

- ≥ 80% sesi membuka halaman dalam ≤ 2 ketuk dari launcher
  (via widget/tile/pin/favorit).
- Rating ≥ 4.5; crash-free sessions ≥ 99.5%.
- Ukuran APK rilis (arm64) < 10 MB.

## 14. Katalog Pintasan Lengkap

19 pintasan bawaan. Kolom *Fallback* dicoba berurutan bila *Action* utama
tidak didukung perangkat.

| # | ID | Judul | Kategori | Action | Fallback | Min SDK | Keywords |
|---|---|---|---|---|---|---|---|
| 1 | `wifi` | WiFi | Jaringan | `android.settings.WIFI_SETTINGS` | – | 1 | internet, wlan, nirkabel, wireless, hotspot |
| 2 | `private_dns` | Private DNS | Jaringan | `android.settings.PRIVATE_DNS_SETTINGS` | `android.settings.WIRELESS_SETTINGS` | 28 | dns, internet, privasi, blokir iklan, adblock, keamanan |
| 3 | `data_usage` | Penggunaan Data | Jaringan | `android.settings.DATA_USAGE_SETTINGS` | – | 19 | kuota, internet, data, paket |
| 4 | `bluetooth` | Bluetooth | Jaringan | `android.settings.BLUETOOTH_SETTINGS` | – | 1 | bt, tws, earphone, speaker |
| 5 | `nfc` | NFC | Jaringan | `android.settings.NFC_SETTINGS` | – | 16 | bayar, tap, pembayaran |
| 6 | `vpn` | VPN | Jaringan | `android.net.vpn.SETTINGS` | `android.settings.WIRELESS_SETTINGS` | 1 | tunnel, privasi |
| 7 | `display` | Layar | Perangkat | `android.settings.DISPLAY_SETTINGS` | – | 1 | brightness, kecerahan, tampilan, wallpaper |
| 8 | `sound` | Suara | Perangkat | `android.settings.SOUND_SETTINGS` | – | 1 | volume, nada dering, ringtone, getar, silent |
| 9 | `battery_saver` | Penghemat Baterai | Perangkat | `android.settings.BATTERY_SAVER_SETTINGS` | – | 22 | baterai, hemat, daya, lowbat |
| 10 | `storage` | Penyimpanan | Perangkat | `android.settings.INTERNAL_STORAGE_SETTINGS` | – | 1 | memori, ruang, penuh, sd card |
| 11 | `apps` | Semua Aplikasi | Aplikasi | `android.settings.APPLICATION_SETTINGS` | – | 1 | app, uninstall, hapus aplikasi |
| 12 | `app_info_self` | Info Aplikasi Ini | Aplikasi | `android.settings.APPLICATION_DETAILS_SETTINGS` | – | 1 | izin, permission, info |
| 13 | `notif_access` | Akses Notifikasi | Aplikasi | `android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS` | – | 22 | notifikasi, pemberitahuan, notification |
| 14 | `cast` | Cast | Aplikasi | `android.settings.CAST_SETTINGS` | – | 21 | tv, chromecast, transmisi, mirror |
| 15 | `location` | Lokasi | Sistem | `android.settings.LOCATION_SOURCE_SETTINGS` | – | 1 | gps, maps, lokasi |
| 16 | `date` | Tanggal & Waktu | Sistem | `android.settings.DATE_SETTINGS` | – | 1 | jam, waktu, timezone, kalender |
| 17 | `language` | Bahasa | Sistem | `android.settings.LOCALE_SETTINGS` | – | 1 | english, indonesia, keyboard |
| 18 | `device_info` | Tentang Ponsel | Sistem | `android.settings.DEVICE_INFO_SETTINGS` | – | 1 | tentang, hp, versi, android, spek |
| 19 | `print` | Pencetakan | Sistem | `android.settings.PRINT_SETTINGS` | – | 1 | cetak, printer |

Catatan:
- `app_info_self` memakai `dataUri: "package:self"` (di-resolve ke package
  aplikasi di sisi native).
- `private_dns` memakai `globalKey: "private_dns_mode"` untuk badge status live.

## 15. Spesifikasi Layar

### L-01 · Beranda (satu-satunya layar utama)
1. **AppBar**: judul "Shortcut Tools" + tombol tema (ikon berubah:
   matahari/bulan/ikuti-sistem).
2. **Search field**: placeholder "Cari pengaturan… (mis. dns)".
3. **Chip kategori**: Semua, Jaringan, Perangkat, Aplikasi, Sistem
   (horizontal scroll).
4. **Strip "Terakhir dibuka"** (bila ada): header + tombol "Hapus" +
   kartu horizontal (maks 8).
5. **Strip "Favorit"** (bila ada): header + kartu horizontal.
6. **Grid "Semua"**: 3 kolom kartu. Tiap kartu: ikon (kontainer 44dp),
   judul (1 baris), deskripsi (2 baris), badge bintang (favorit) /
   badge tile (Quick Tile), titik status live (bila ada `globalKey`).
7. **Gestur**: ketuk kartu = buka langsung (+ haptic ringan, tercatat di
   riwayat); tahan kartu = bottom sheet aksi (+ haptic sedang).
8. **Empty state**: teks "Tidak ada hasil." bila filter/search kosong.

### L-02 · Bottom sheet aksi (long-press kartu)
Daftar: "Buka …", "Tambah/Hapus Favorit" (ikon bintang berubah),
"Pin ke Home Screen", "Jadikan Quick Tile".

### L-03 · Bottom sheet tema (tombol AppBar)
Tiga opsi radio: Terang, Gelap, Ikuti sistem (tanda centang pada yang aktif).

### L-04 · Bottom sheet onboarding (sekali tampil)
Judul "Selamat datang di Shortcut Tools" + 3 baris petunjuk
(ketuk / tahan / riwayat otomatis) + tombol "Mengerti".

### L-05 · Quick Settings Tile (komponen sistem)
Satu tile "Shortcut Favorit"; tap → buka pintasan pilihan via
`unlockAndRun` + `startActivityAndCollapse`.

### L-06 · Home Screen Widget (komponen sistem)
Ukuran 2×2, judul "Shortcut Tools", hingga 4 tombol favorit (2 baris ×
2 kolom). Kondisi kosong: teks ajakan + tap membuka aplikasi.

## 16. Edge Cases

| # | Kondisi | Perilaku yang diharapkan |
|---|---|---|
| E-01 | Action utama tak didukung perangkat | Coba fallback berurutan → terakhir `ACTION_SETTINGS`; tidak crash |
| E-02 | Semua kandidat gagal | Snackbar "Tidak dapat membuka … di perangkat ini" |
| E-03 | Launcher tidak dukung pin shortcut | Snackbar "Perangkat/launcher ini tidak mendukung pin shortcut" |
| E-04 | Widget tanpa favorit | Tampilkan ajakan; tap → buka aplikasi |
| E-05 | Tile diklik sebelum user memilih pintasan | Buka halaman Settings utama |
| E-06 | Perangkat < Android 9 tap Private DNS | Fallback ke Wireless Settings (halaman induk) |
| E-07 | SharedPreferences korup / kosong | Anggap kosong (favorit/riwayat/tema = default) |
| E-08 | Pencarian tanpa hasil | Tampilkan "Tidak ada hasil." |
| E-09 | `dataUri` selain "package:self" | Dipakai apa adanya sebagai `Intent.data` |
| E-10 | Rotasi layar / multi-window | Grid tetap 3 kolom; strip tetap horizontal scroll |
| E-11 | Permission dicabut sistem | Tidak relevan — aplikasi tidak memakai permission berbahaya |

---

*Akhir dokumen v1.1. Lihat `README.md` untuk panduan build & struktur kode.*
