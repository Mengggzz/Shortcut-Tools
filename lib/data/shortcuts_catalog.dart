import 'package:flutter/material.dart';
import '../models/tool_shortcut.dart';

/// Katalog semua pintasan. Action memakai string literal
/// "android.settings.*" agar tidak bergantung pada konstanta SDK
/// (beberapa, seperti Private DNS, tidak punya konstanta publik).
const List<ToolShortcut> kShortcuts = [
  // ── Jaringan ────────────────────────────────────────────────
  ToolShortcut(
    id: 'wifi',
    title: 'WiFi',
    description: 'Hubungkan & kelola jaringan WiFi',
    category: 'Jaringan',
    icon: Icons.wifi,
    action: 'android.settings.WIFI_SETTINGS',
    keywords: ['internet', 'wlan', 'nirkabel', 'wireless', 'hotspot'],
  ),
  ToolShortcut(
    id: 'private_dns',
    title: 'Private DNS',
    description: 'DNS terenkripsi (DoT), mis. dns.adguard-dns.com',
    category: 'Jaringan',
    icon: Icons.dns,
    action: 'android.settings.PRIVATE_DNS_SETTINGS',
    fallbacks: [
      'com.android.settings/com.android.settings.Settings\$NetworkDashboardActivity',
      'com.android.settings/com.android.settings.Settings\$ConnectedDeviceDashboardActivity',
      'com.android.settings/com.android.settings.Settings\$TetherSettingsActivity',
      'com.android.settings/com.android.settings.Settings\$WirelessSettingsActivity',
      'android.settings.WIRELESS_SETTINGS',
      'android.settings.NETWORK_PROVIDER_SETTINGS',
    ],
    minSdk: 28,
    globalKey: 'private_dns_mode',
    keywords: [
      'dns',
      'internet',
      'privasi',
      'blokir iklan',
      'adblock',
      'keamanan',
      'controld',
      'adguard',
      'cloudflare',
      'quad9'
    ],
  ),
  ToolShortcut(
    id: 'data_usage',
    title: 'Penggunaan Data',
    description: 'Pantau kuota & pemakaian data seluler',
    category: 'Jaringan',
    icon: Icons.data_usage,
    action: 'android.settings.DATA_USAGE_SETTINGS',
    minSdk: 19,
    keywords: ['kuota', 'internet', 'data', 'paket'],
  ),
  ToolShortcut(
    id: 'bluetooth',
    title: 'Bluetooth',
    description: 'Pairing & kelola perangkat Bluetooth',
    category: 'Jaringan',
    icon: Icons.bluetooth,
    action: 'android.settings.BLUETOOTH_SETTINGS',
    keywords: ['bt', 'tws', 'earphone', 'speaker'],
  ),
  ToolShortcut(
    id: 'nfc',
    title: 'NFC',
    description: 'Aktifkan pembayaran & berbagi via NFC',
    category: 'Jaringan',
    icon: Icons.nfc,
    action: 'android.settings.NFC_SETTINGS',
    minSdk: 16,
    keywords: ['bayar', 'tap', 'pembayaran'],
  ),
  ToolShortcut(
    id: 'vpn',
    title: 'VPN',
    description: 'Kelola profil VPN',
    category: 'Jaringan',
    icon: Icons.vpn_key,
    action: 'android.net.vpn.SETTINGS',
    fallbacks: ['android.settings.WIRELESS_SETTINGS'],
    keywords: ['tunnel', 'privasi'],
  ),

  // ── Perangkat ───────────────────────────────────────────────
  ToolShortcut(
    id: 'display',
    title: 'Layar',
    description: 'Kecerahan, timeout, & tampilan',
    category: 'Perangkat',
    icon: Icons.brightness_6,
    action: 'android.settings.DISPLAY_SETTINGS',
    keywords: ['brightness', 'kecerahan', 'tampilan', 'wallpaper'],
  ),
  ToolShortcut(
    id: 'flashlight',
    title: 'Senter (Flashlight)',
    description: 'Nyalakan/matikan lampu kilat kamera langsung',
    category: 'Perangkat',
    icon: Icons.flashlight_on,
    action: 'android.settings.APPLICATION_SETTINGS',
    keywords: ['senter', 'lampu', 'flash', 'torch'],
  ),
  ToolShortcut(
    id: 'auto_rotate',
    title: 'Rotasi Otomatis',
    description: 'Kunci atau aktifkan putar layar otomatis',
    category: 'Perangkat',
    icon: Icons.screen_rotation,
    action: 'android.settings.DISPLAY_SETTINGS',
    keywords: ['rotasi', 'putar', 'layar', 'landscape', 'portrait'],
  ),
  ToolShortcut(
    id: 'sound',
    title: 'Suara',
    description: 'Volume, nada dering, & getaran',
    category: 'Perangkat',
    icon: Icons.volume_up,
    action: 'android.settings.SOUND_SETTINGS',
    keywords: ['volume', 'nada dering', 'ringtone', 'getar', 'silent'],
  ),
  ToolShortcut(
    id: 'battery_saver',
    title: 'Penghemat Baterai',
    description: 'Mode hemat daya sistem',
    category: 'Perangkat',
    icon: Icons.battery_saver,
    action: 'android.settings.BATTERY_SAVER_SETTINGS',
    minSdk: 22,
    keywords: ['baterai', 'hemat', 'daya', 'lowbat'],
  ),
  ToolShortcut(
    id: 'storage',
    title: 'Penyimpanan',
    description: 'Ruang internal & kartu SD',
    category: 'Perangkat',
    icon: Icons.storage,
    action: 'android.settings.INTERNAL_STORAGE_SETTINGS',
    keywords: ['memori', 'ruang', 'penuh', 'sd card'],
  ),

  // ── Aplikasi ────────────────────────────────────────────────
  ToolShortcut(
    id: 'apps',
    title: 'Semua Aplikasi',
    description: 'Daftar & kelola aplikasi terinstal',
    category: 'Aplikasi',
    icon: Icons.apps,
    action: 'android.settings.APPLICATION_SETTINGS',
    keywords: ['app', 'uninstall', 'hapus aplikasi'],
  ),
  ToolShortcut(
    id: 'app_info_self',
    title: 'Info Aplikasi Ini',
    description: 'Izin, notifikasi, & penyimpanan app ini',
    category: 'Aplikasi',
    icon: Icons.info_outline,
    action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
    dataUri: 'package:self',
    keywords: ['izin', 'permission', 'info'],
  ),
  ToolShortcut(
    id: 'notif_access',
    title: 'Akses Notifikasi',
    description: 'Aplikasi yang boleh membaca notifikasi',
    category: 'Aplikasi',
    icon: Icons.notifications_active,
    action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
    minSdk: 22,
    keywords: ['notifikasi', 'pemberitahuan', 'notification'],
  ),
  ToolShortcut(
    id: 'cast',
    title: 'Cast',
    description: 'Transmisikan layar ke TV/Chromecast',
    category: 'Aplikasi',
    icon: Icons.cast,
    action: 'android.settings.CAST_SETTINGS',
    minSdk: 21,
    keywords: ['tv', 'chromecast', 'transmisi', 'mirror'],
  ),

  // ── Sistem ──────────────────────────────────────────────────
  ToolShortcut(
    id: 'location',
    title: 'Lokasi',
    description: 'GPS & layanan lokasi',
    category: 'Sistem',
    icon: Icons.location_on,
    action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    keywords: ['gps', 'maps', 'lokasi'],
  ),
  ToolShortcut(
    id: 'date',
    title: 'Tanggal & Waktu',
    description: 'Zona waktu & format jam',
    category: 'Sistem',
    icon: Icons.access_time,
    action: 'android.settings.DATE_SETTINGS',
    keywords: ['jam', 'waktu', 'timezone', 'kalender'],
  ),
  ToolShortcut(
    id: 'language',
    title: 'Bahasa',
    description: 'Bahasa sistem & input',
    category: 'Sistem',
    icon: Icons.language,
    action: 'android.settings.LOCALE_SETTINGS',
    keywords: ['english', 'indonesia', 'keyboard'],
  ),
  ToolShortcut(
    id: 'device_info',
    title: 'Tentang Ponsel',
    description: 'Info perangkat & versi Android',
    category: 'Sistem',
    icon: Icons.smartphone,
    action: 'android.settings.DEVICE_INFO_SETTINGS',
    keywords: ['tentang', 'hp', 'versi', 'android', 'spek'],
  ),
  ToolShortcut(
    id: 'print',
    title: 'Pencetakan',
    description: 'Layanan print & printer',
    category: 'Sistem',
    icon: Icons.print,
    action: 'android.settings.PRINT_SETTINGS',
    minSdk: 19,
    keywords: ['cetak', 'printer'],
  ),
];

/// Daftar kategori unik sesuai urutan kemunculan.
List<String> get kCategories {
  final seen = <String>[];
  for (final s in kShortcuts) {
    if (!seen.contains(s.category)) seen.add(s.category);
  }
  return seen;
}
