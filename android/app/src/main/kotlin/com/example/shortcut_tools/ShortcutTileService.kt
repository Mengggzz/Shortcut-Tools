package com.example.shortcut_tools

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.service.quicksettings.TileService

/**
 * Quick Settings Tile: satu tap dari notification shade langsung membuka
 * halaman Settings favorit user.
 *
 * Pintasan mana yang dibuka disimpan di SharedPreferences oleh MainActivity
 * lewat MethodChannel "setTileShortcut". User menambahkan tile ini manual
 * lewat panel Edit tiles (Android tidak mengizinkan aplikasi menambah
 * tile secara programatik).
 */
class ShortcutTileService : TileService() {

    override fun onClick() {
        super.onClick()
        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        val action = prefs.getString(KEY_ACTION, null)
        val fallbacks = prefs.getStringSet(KEY_FALLBACKS, emptySet())?.toList().orEmpty()
        val dataUri = prefs.getString(KEY_DATA_URI, null)

        unlockAndRun {
            val candidates = (listOfNotNull(action) + fallbacks + Settings.ACTION_SETTINGS)
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .distinct()
            for (a in candidates) {
                try {
                    val intent = Intent(a).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    if (dataUri != null) intent.data = Uri.parse(dataUri)
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivityAndCollapse(intent)
                        return@unlockAndRun
                    }
                } catch (_: Exception) {
                    // Coba kandidat berikutnya.
                }
            }
        }
    }

    companion object {
        const val PREFS = "shortcut_tools_tile"
        const val KEY_ACTION = "tile_action"
        const val KEY_FALLBACKS = "tile_fallbacks"
        const val KEY_DATA_URI = "tile_data_uri"
        const val KEY_ID = "tile_id"
    }
}
