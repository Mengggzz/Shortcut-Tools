package com.example.shortcut_tools

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "tools/shortcut"

    // Ekstra intent dari pinned shortcut di home screen.
    private var pendingAction: String? = null
    private var pendingFallbacks: List<String> = emptyList()
    private var pendingDataUri: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openSettings" -> {
                        val action = call.argument<String>("action").orEmpty()
                        @Suppress("UNCHECKED_CAST")
                        val fallbacks = call.argument<List<String>>("fallbacks") ?: emptyList()
                        var dataUri = call.argument<String>("dataUri")
                        if (dataUri == "package:self") dataUri = "package:$packageName"
                        result.success(openSettingsChain(action, fallbacks, dataUri))
                    }
                    "getGlobalSetting" -> {
                        val key = call.argument<String>("key").orEmpty()
                        try {
                            result.success(Settings.Global.getString(contentResolver, key))
                        } catch (e: Exception) {
                            result.error("READ_FAILED", e.message, null)
                        }
                    }
                    "pinShortcut" -> {
                        val id = call.argument<String>("id").orEmpty()
                        val title = call.argument<String>("title").orEmpty()
                        val action = call.argument<String>("action").orEmpty()
                        @Suppress("UNCHECKED_CAST")
                        val fallbacks = call.argument<List<String>>("fallbacks") ?: emptyList()
                        val dataUri = call.argument<String>("dataUri")
                        result.success(pinShortcut(id, title, action, fallbacks, dataUri))
                    }
                    "setTileShortcut" -> {
                        saveTileShortcut(
                            call.argument<String>("id").orEmpty(),
                            call.argument<String>("action").orEmpty(),
                            call.argument<List<String>>("fallbacks") ?: emptyList(),
                            call.argument<String>("dataUri"),
                        )
                        result.success(true)
                    }
                    "getTileShortcutId" -> {
                        val prefs = getSharedPreferences(
                            ShortcutTileService.PREFS, MODE_PRIVATE)
                        result.success(prefs.getString(ShortcutTileService.KEY_ID, null))
                    }
                    "consumePinnedShortcut" -> {
                        result.success(consumePinnedShortcut())
                    }
                    "refreshWidgets" -> {
                        ShortcutWidgetProvider.updateAll(this@MainActivity)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        extractPinnedExtras(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractPinnedExtras(intent)
    }

    // ── Buka halaman Settings ──────────────────────────────────────────

    /**
     * Coba buka [action], lalu tiap [fallbacks], terakhir halaman Settings utama.
     * Mengembalikan true bila ada activity yang berhasil dibuka.
     */
    private fun openSettingsChain(
        action: String,
        fallbacks: List<String>,
        dataUri: String?,
    ): Boolean {
        val candidates = (listOf(action) + fallbacks + Settings.ACTION_SETTINGS)
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
        for (a in candidates) {
            try {
                val intent = Intent(a).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (dataUri != null) intent.data = Uri.parse(dataUri)
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
                // Lanjut ke kandidat berikutnya.
            }
        }
        return false
    }

    // ── Pin to Home Screen (Android 8+) ────────────────────────────────

    /**
     * Minta sistem me-pin shortcut ke home screen. Menampilkan dialog
     * konfirmasi bawaan sistem. Shortcut membuka MainActivity dengan ekstra
     * yang lalu diteruskan ke Dart untuk langsung membuka halaman Settings.
     */
    private fun pinShortcut(
        id: String,
        title: String,
        action: String,
        fallbacks: List<String>,
        dataUri: String?,
    ): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val sm = getSystemService(ShortcutManager::class.java) ?: return false
        if (!sm.isRequestPinShortcutSupported) return false

        var uri = dataUri
        if (uri == "package:self") uri = "package:$packageName"

        val intent = Intent(this, MainActivity::class.java).apply {
            setAction(Intent.ACTION_VIEW)
            putExtra(EXTRA_ACTION, action)
            putStringArrayListExtra(EXTRA_FALLBACKS, ArrayList(fallbacks))
            if (uri != null) putExtra(EXTRA_DATA_URI, uri)
        }
        val info = ShortcutInfo.Builder(this, "pinned_$id")
            .setShortLabel(title.take(10))
            .setLongLabel(title)
            .setIcon(Icon.createWithResource(this, R.mipmap.ic_launcher))
            .setIntent(intent)
            .build()
        sm.requestPinShortcut(info, null)
        return true
    }

    private fun extractPinnedExtras(intent: Intent?) {
        val a = intent?.getStringExtra(EXTRA_ACTION) ?: return
        pendingAction = a
        pendingFallbacks = intent.getStringArrayListExtra(EXTRA_FALLBACKS) ?: arrayListOf()
        pendingDataUri = intent.getStringExtra(EXTRA_DATA_URI)
    }

    /** Ambil sekali lalu hapus — dipanggil Dart sekali saat aplikasi start. */
    private fun consumePinnedShortcut(): Map<String, Any?>? {
        val a = pendingAction ?: return null
        val map = mapOf<String, Any?>(
            "action" to a,
            "fallbacks" to pendingFallbacks,
            "dataUri" to pendingDataUri,
        )
        pendingAction = null
        pendingFallbacks = emptyList()
        pendingDataUri = null
        return map
    }

    // ── Quick Settings Tile ────────────────────────────────────────────

    private fun saveTileShortcut(
        id: String,
        action: String,
        fallbacks: List<String>,
        dataUri: String?,
    ) {
        var uri = dataUri
        if (uri == "package:self") uri = "package:$packageName"
        getSharedPreferences(ShortcutTileService.PREFS, MODE_PRIVATE).edit()
            .putString(ShortcutTileService.KEY_ID, id)
            .putString(ShortcutTileService.KEY_ACTION, action)
            .putStringSet(ShortcutTileService.KEY_FALLBACKS, fallbacks.toSet())
            .putString(ShortcutTileService.KEY_DATA_URI, uri)
            .apply()
    }

    companion object {
        const val EXTRA_ACTION = "open_settings_action"
        const val EXTRA_FALLBACKS = "open_settings_fallbacks"
        const val EXTRA_DATA_URI = "open_settings_data_uri"
    }
}
