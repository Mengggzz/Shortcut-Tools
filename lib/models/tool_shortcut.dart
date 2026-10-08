import 'package:flutter/material.dart';

/// Satu pintasan ke sebuah halaman pengaturan sistem Android.
///
/// Cara kerja: aplikasi mengirim [action] (sebuah intent action seperti
/// `android.settings.WIFI_SETTINGS`) ke sisi native lewat MethodChannel.
/// Sisi native mencoba membukanya; kalau gagal (tidak ada activity yang
/// menangani, beda ROM/OEM), ia mencoba [fallbacks] satu per satu, terakhir
/// halaman Settings utama.
class ToolShortcut {
  /// ID unik, mis. "private_dns".
  final String id;

  /// Nama yang tampil, mis. "Private DNS".
  final String title;

  /// Penjelasan singkat untuk user.
  final String description;

  /// Kategori untuk pengelompokan, mis. "Jaringan".
  final String category;

  final IconData icon;

  /// Intent action utama. Boleh konstanta publik SDK
  /// (`android.settings.WIFI_SETTINGS`) atau string undocumented
  /// (`android.settings.PRIVATE_DNS_SETTINGS`).
  final String action;

  /// Rantai cadangan bila [action] tidak didukung di perangkat.
  final List<String> fallbacks;

  /// Data URI opsional untuk intent. Nilai khusus "package:self"
  /// di-resolve ke package aplikasi ini di sisi native.
  /// Contoh: "package:self" untuk APPLICATION_DETAILS_SETTINGS.
  final String? dataUri;

  /// API level minimum. Hanya dokumentasi di scaffold ini.
  final int minSdk;

  /// Kunci Settings.Global opsional untuk menampilkan status live
  /// tanpa permission khusus, mis. "private_dns_mode".
  final String? globalKey;

  /// Kata kunci alias untuk pencarian, mis. ["internet", "wlan"].
  final List<String> keywords;

  const ToolShortcut({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.action,
    this.fallbacks = const [],
    this.dataUri,
    this.minSdk = 1,
    this.globalKey,
    this.keywords = const [],
  });
}
