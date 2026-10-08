import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_shortcut.dart';

/// Favorit user: daftar ID shortcut, disimpan di SharedPreferences.
/// Urutan mengikuti urutan penambahan.
///
/// Selain daftar ID, tiap favorit juga menyimpan data intent-nya
/// (`fav_data_<id>`) agar Home Screen Widget (native) bisa membangun
/// PendingIntent tanpa menduplikasi katalog di sisi Kotlin.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'favorite_shortcut_ids';
  static const _dataPrefix = 'fav_data_';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<bool> isFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).contains(id);
  }

  /// Toggle favorit. Mengembalikan true bila sekarang menjadi favorit.
  Future<bool> toggleFavorite(ToolShortcut s) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final bool nowFav;
    if (list.contains(s.id)) {
      list.remove(s.id);
      await prefs.remove('$_dataPrefix${s.id}');
      nowFav = false;
    } else {
      list.add(s.id);
      await prefs.setString(
        '$_dataPrefix${s.id}',
        jsonEncode({
          'title': s.title,
          'action': s.action,
          'fallbacks': s.fallbacks,
          'dataUri': s.dataUri,
        }),
      );
      nowFav = true;
    }
    await prefs.setStringList(_key, list);
    return nowFav;
  }
}
