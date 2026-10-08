import 'package:shared_preferences/shared_preferences.dart';

/// Riwayat bukaan otomatis: daftar ID shortcut, paling baru di depan.
/// Terisi sendiri setiap user membuka sebuah pintasan — nol usaha ngatur.
class RecentsService {
  RecentsService._();
  static final RecentsService instance = RecentsService._();

  static const _key = 'recent_shortcut_ids';
  static const maxCount = 8;

  Future<List<String>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> recordOpen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(id);
    list.insert(0, id);
    await prefs.setStringList(_key, list.take(maxCount).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
