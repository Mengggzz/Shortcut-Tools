import 'package:flutter/services.dart';
import '../models/tool_shortcut.dart';

/// Jembatan ke kode native Android untuk membuka halaman Settings.
///
/// Channel: "tools/shortcut"
/// - `openSettings` {action, fallbacks, dataUri} -> bool
/// - `getGlobalSetting` {key} -> String? (baca Settings.Global, tanpa permission)
/// - `pinShortcut` {id, title, action, fallbacks, dataUri} -> bool
/// - `setTileShortcut` {id, action, fallbacks, dataUri} -> void
/// - `getTileShortcutId` -> String?
/// - `consumePinnedShortcut` -> {action, fallbacks, dataUri}?
/// - `refreshWidgets` -> void
class ShortcutService {
  ShortcutService._();
  static final ShortcutService instance = ShortcutService._();

  static const _channel = MethodChannel('tools/shortcut');

  /// Buka halaman Settings untuk [shortcut].
  /// Mengembalikan true bila ada activity yang berhasil dibuka
  /// (termasuk lewat rantai fallback di sisi native).
  Future<bool> open(ToolShortcut shortcut) => openRaw(
        action: shortcut.action,
        fallbacks: shortcut.fallbacks,
        dataUri: shortcut.dataUri,
      );

  /// Versi mentah dari [open] untuk aksi yang datang dari pinned shortcut.
  Future<bool> openRaw({
    required String action,
    List<String> fallbacks = const [],
    String? dataUri,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('openSettings', {
        'action': action,
        'fallbacks': fallbacks,
        'dataUri': ?dataUri,
      }).timeout(const Duration(seconds: 2));
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Baca nilai Settings.Global (mis. "private_dns_mode").
  /// Tidak butuh permission khusus untuk key yang readable.
  Future<String?> getGlobalSetting(String key) async {
    try {
      return await _channel
          .invokeMethod<String>('getGlobalSetting', {'key': key})
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      return null;
    }
  }

  /// Minta sistem me-pin [shortcut] ke home screen (Android 8+).
  /// Sistem menampilkan dialog konfirmasi. Mengembalikan false bila
  /// perangkat/launcher tidak mendukung.
  Future<bool> pinToHomeScreen(ToolShortcut shortcut) async {
    try {
      final ok = await _channel.invokeMethod<bool>('pinShortcut', {
        'id': shortcut.id,
        'title': shortcut.title,
        'action': shortcut.action,
        'fallbacks': shortcut.fallbacks,
        if (shortcut.dataUri != null) 'dataUri': shortcut.dataUri,
      }).timeout(const Duration(seconds: 2));
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Jadikan [shortcut] sebagai aksi Quick Settings Tile.
  /// Catatan: user tetap harus menambahkan tile-nya manual lewat
  /// panel "Edit tiles" di notification shade (Android tidak mengizinkan
  /// aplikasi menambah tile secara programatik).
  Future<void> setAsTileShortcut(ToolShortcut shortcut) async {
    try {
      await _channel.invokeMethod('setTileShortcut', {
        'id': shortcut.id,
        'action': shortcut.action,
        'fallbacks': shortcut.fallbacks,
        if (shortcut.dataUri != null) 'dataUri': shortcut.dataUri,
      }).timeout(const Duration(seconds: 1));
    } catch (_) {
      // Abaikan — tile sekadar tidak terupdate.
    }
  }

  /// ID shortcut yang saat ini dipasang sebagai Quick Settings Tile.
  Future<String?> getTileShortcutId() async {
    try {
      return await _channel
          .invokeMethod<String>('getTileShortcutId')
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      return null;
    }
  }

  /// Ambil (sekali pakai) aksi dari pinned shortcut yang meluncurkan aplikasi.
  /// Dipanggil sekali saat aplikasi start; null bila dibuka normal.
  Future<Map<String, dynamic>?> consumePinnedShortcut() async {
    try {
      return await _channel
          .invokeMapMethod<String, dynamic>('consumePinnedShortcut')
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      return null;
    }
  }

  /// Minta semua Home Screen Widget me-refresh tampilannya.
  /// Dipanggil setelah favorit berubah.
  Future<void> refreshWidgets() async {
    try {
      await _channel
          .invokeMethod('refreshWidgets')
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // Abaikan — widget sekadar tidak terupdate.
    }
  }

  /// Ambil info spesifikasi perangkat & status sistem live.
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final map = await _channel
          .invokeMapMethod<String, dynamic>('getSystemInfo')
          .timeout(const Duration(milliseconds: 1200));
      return map ?? {};
    } catch (_) {
      return {};
    }
  }

  /// Ukur latensi ping ke host/DNS dalam milidetik (-1 jika gagal/timeout).
  Future<int> pingHost(String host, {int timeout = 2500}) async {
    try {
      final res = await _channel.invokeMethod<int>('pingHost', {
        'host': host,
        'timeout': timeout,
      }).timeout(Duration(milliseconds: timeout + 1000));
      return res ?? -1;
    } catch (_) {
      return -1;
    }
  }

  /// Terapkan Private DNS secara programatik (memerlukan WRITE_SECURE_SETTINGS).
  Future<Map<String, dynamic>> setPrivateDns({
    required String mode,
    String? hostname,
  }) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'setPrivateDns',
        {
          'mode': mode,
          'hostname': ?hostname,
        },
      ).timeout(const Duration(seconds: 2));
      return res ?? {'success': false, 'error': 'UNKNOWN'};
    } catch (e) {
      return {'success': false, 'error': 'FAILED', 'message': e.toString()};
    }
  }

  /// Label ramah untuk nilai private_dns_mode:
  /// "off" | "opportunistic" | "hostname".
  static String prettyPrivateDnsMode(String? raw) {
    switch (raw) {
      case 'off':
        return 'Mati';
      case 'opportunistic':
        return 'Otomatis';
      case 'hostname':
        return 'Hostname kustom';
      default:
        return '—';
    }
  }
}
