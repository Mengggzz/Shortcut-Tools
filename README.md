# Shortcut Tools

Katalog pintasan sekali-tap ke halaman pengaturan sistem Android yang biasanya
tersembunyi beberapa level dalam — contoh: **Private DNS** yang normalnya harus
dibuka lewat Pengaturan → Jaringan → DNS.

## Cara kerja

Tiap pintasan = sebuah **Intent** ke halaman Settings:

- `models/tool_shortcut.dart` — data class `ToolShortcut`
  (nama, ikon, `action`, rantai `fallbacks`, `dataUri` opsional, `globalKey` opsional).
- `data/shortcuts_catalog.dart` — 19 pintasan siap pakai dalam 4 kategori
  (Jaringan, Perangkat, Aplikasi, Sistem).
- `services/shortcut_service.dart` — MethodChannel `tools/shortcut`:
  - `openSettings` → buka halaman (true/false)
  - `getGlobalSetting` → baca `Settings.Global` tanpa permission
    (dipakai untuk badge status live, mis. mode Private DNS).
- `android/.../MainActivity.kt` — handler native: coba `action`,
  lalu tiap fallback, terakhir `ACTION_SETTINGS`. Selalu aman dari crash
  (`resolveActivity` + try/catch).

Tidak perlu permission khusus di manifest: membuka halaman Settings milik
sistem dan membaca `Settings.Global` tidak memerlukannya.

## Favorit & Terakhir dibuka

- **Terakhir dibuka** (otomatis): baris horizontal paling atas, terisi sendiri
  setiap user membuka pintasan (`RecentsService`, maks 8, ada tombol Hapus).
- **Favorit** (manual): tahan kartu → "Tambah ke Favorit". Selalu tampil
  di bawah baris riwayat.
- Badge bintang kuning = favorit; badge tile = Quick Tile aktif.

## Tema Terang / Gelap

- Ikon di AppBar membuka pilihan: **Terang**, **Gelap**, **Ikuti sistem**.
- Pilihan tersimpan (`ThemeService`) dan berlaku instan tanpa restart.

## Menjalankan

Scaffold ini berisi `lib/` + kode native + resource minimal (tanpa Gradle wrapper).
Cara tercepat:

```bash
flutter create --org com.example --project-name shortcut_tools /tmp/st
# salin isi folder lib/ scaffold ini ke /tmp/st/lib/
# salin MainActivity.kt, ShortcutTileService.kt, ShortcutWidgetProvider.kt,
# WidgetLaunchActivity.kt ke
#   /tmp/st/android/app/src/main/kotlin/com/example/shortcut_tools/
# salin folder res/ (layout, drawable, xml, values, mipmap-anydpi-v26) ke
#   /tmp/st/android/app/src/main/res/
# gabungkan AndroidManifest.xml scaffold ke manifest proyek
cd /tmp/st
flutter run
```

## Build rilis yang ringan

```bash
flutter build apk --split-per-abi --release
```

`--split-per-abi` menghasilkan satu APK per arsitektur CPU (arm64-v8a,
armeabi-v7a, x86_64) — masing-masing jauh lebih kecil dari APK universal.
Contoh konfigurasi `buildTypes` (R8 `minifyEnabled` + `shrinkResources`)
ada di `android/app/build.gradle.contoh` — salin ke build.gradle proyek.

Prinsip "ringan" yang dijaga:
- Dependensi Dart hanya `shared_preferences` — tanpa state management
  berat, tanpa font downloader.
- Widget & tile 100% native tanpa memutar Flutter engine saat dipakai.
- Tanpa background service / permission berbahaya.

## Menambah pintasan baru

Tambahkan satu entri di `kShortcuts`:

```dart
ToolShortcut(
  id: 'hotspot',
  title: 'Hotspot',
  description: 'Berbagi koneksi via hotspot',
  category: 'Jaringan',
  icon: Icons.wifi_tethering,
  action: 'android.settings.TETHER_SETTINGS', // undocumented → wajib fallback
  fallbacks: ['android.settings.WIRELESS_SETTINGS'],
),
```

Aturan main: action yang *undocumented* (tidak ada di `android.provider.Settings`)
wajib punya `fallbacks`, karena tiap OEM (Samsung, Xiaomi, dll.) bisa
memindah atau me-rename halamannya.

## Fitur pembeda

- **Quick Settings Tile** (Android 7+) — satu pintasan favorit bisa diakses
  sekali tap dari notification shade. Pilih lewat menu ⋮ di tiap kartu
  ("Jadikan Quick Tile"), lalu tambahkan tile "Shortcut Favorit" secara manual
  lewat panel *Edit tiles*. Android tidak mengizinkan aplikasi menambah tile
  secara programatik, jadi langkah manual ini wajib.
  Implementasi: `ShortcutTileService.kt` (TileService + `unlockAndRun` +
  `startActivityAndCollapse`), pilihan tersimpan di SharedPreferences.
- **Pin to Home Screen** (Android 8+) — lewat menu ⋮ → "Pin ke Home Screen",
  sistem menampilkan dialog konfirmasi dan membuat ikon beneran di home
  screen. Saat ditekan, aplikasi dibuka lalu langsung melompat ke halaman
  Settings yang dituju (via ekstra intent → `consumePinnedShortcut`).
  Implementasi: `ShortcutManager.requestPinShortcut` di `MainActivity.kt`.
- **Home Screen Widget** — widget 2×2 berisi hingga 4 tombol favorit.
  Tap tombol → `WidgetLaunchActivity` (transparan, tanpa Flutter engine)
  langsung membuka halaman Settings-nya. Data favorit dibaca dari
  SharedPreferences Flutter (`flutter.favorite_shortcut_ids` +
  `flutter.fav_data_<id>`); aplikasi memanggil `refreshWidgets()` setiap
  favorit berubah. Tambahkan widget manual dari daftar widget launcher.

## Fitur pendukung

- **Keyword alias pencarian** — tiap pintasan punya `keywords`
  (mis. "internet" → WiFi, "kuota" → Penggunaan Data).
- **Haptic feedback** — getar ringan saat tap, sedang saat tahan.
- **Onboarding sekali tampil** — petunjuk gestur (ketuk/tahan) di
  peluncuran pertama.

## Ide pengembangan lanjutan

- **Favorit & riwayat**: simpan pintasan yang sering dipakai.
- **Status live** untuk halaman lain yang readable via `Settings.Global`.
