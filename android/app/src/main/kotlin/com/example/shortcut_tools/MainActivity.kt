package com.example.shortcut_tools

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.bluetooth.BluetoothManager
import android.location.LocationManager
import android.media.AudioManager
import android.net.wifi.WifiManager
import android.nfc.NfcAdapter
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "tools/shortcut"
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

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
                    "getSystemInfo" -> {
                        result.success(getSystemInfoMap())
                    }
                    "pingHost" -> {
                        val host = call.argument<String>("host").orEmpty()
                        val timeout = call.argument<Int>("timeout") ?: 2500
                        executor.execute {
                            val latency = measurePingLatency(host, timeout)
                            mainHandler.post {
                                result.success(latency)
                            }
                        }
                    }
                    "setPrivateDns" -> {
                        val mode = call.argument<String>("mode").orEmpty()
                        val hostname = call.argument<String>("hostname")
                        val res = applyPrivateDns(mode, hostname)
                        result.success(res)
                    }
                    "getFeatureStates" -> {
                        result.success(getFeatureStatesMap())
                    }
                    "toggleFeature" -> {
                        val id = call.argument<String>("id").orEmpty()
                        result.success(toggleFeatureDirect(id))
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
                val intent = if (a.contains("/")) {
                    val parts = a.split("/")
                    val pkg = parts[0]
                    val cls = if (parts[1].startsWith(".")) pkg + parts[1] else parts[1]
                    Intent().setClassName(pkg, cls).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                } else {
                    Intent(a).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }

                if (action.contains("PRIVATE_DNS", ignoreCase = true) || a.contains("DNS", ignoreCase = true)) {
                    intent.putExtra(":settings:show_fragment", "com.android.settings.network.PrivateDnsSettings")
                    intent.putExtra(":settings:show_fragment_args", "private_dns_settings")
                    intent.putExtra(":settings:fragment_args_key", "private_dns_settings")
                    intent.putExtra("extra_prefs_show_button_bar", true)
                }

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

    // ── System Info & Tools ────────────────────────────────────────────

    private fun getSystemInfoMap(): Map<String, Any?> {
        val bm = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val batteryPct = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
        val isCharging = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val status = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_STATUS) ?: -1
            status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        } else false

        val hasWriteSecure = checkCallingOrSelfPermission(
            Manifest.permission.WRITE_SECURE_SETTINGS
        ) == PackageManager.PERMISSION_GRANTED

        val dnsMode = try {
            Settings.Global.getString(contentResolver, "private_dns_mode") ?: ""
        } catch (_: Exception) { "" }

        val dnsSpecifier = try {
            Settings.Global.getString(contentResolver, "private_dns_specifier") ?: ""
        } catch (_: Exception) { "" }

        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "batteryPercent" to batteryPct,
            "isCharging" to isCharging,
            "hasWriteSecureSettings" to hasWriteSecure,
            "privateDnsMode" to dnsMode,
            "privateDnsSpecifier" to dnsSpecifier,
        )
    }

    private fun measurePingLatency(host: String, timeoutMs: Int): Int {
        val cleanHost = host.trim().removePrefix("https://").removePrefix("http://").split("/")[0]
        if (cleanHost.isEmpty()) return -1
        val start = System.currentTimeMillis()
        return try {
            val inet = InetAddress.getByName(cleanHost)
            if (inet.isReachable(timeoutMs)) {
                (System.currentTimeMillis() - start).toInt()
            } else {
                val socket = Socket()
                val socketAddress = InetSocketAddress(inet, 853)
                socket.connect(socketAddress, timeoutMs)
                socket.close()
                (System.currentTimeMillis() - start).toInt()
            }
        } catch (_: Exception) {
            try {
                val socket = Socket()
                val socketAddress = InetSocketAddress(cleanHost, 443)
                socket.connect(socketAddress, timeoutMs)
                socket.close()
                (System.currentTimeMillis() - start).toInt()
            } catch (_: Exception) {
                -1
            }
        }
    }

    private fun applyPrivateDns(mode: String, hostname: String?): Map<String, Any?> {
        val hasWriteSecure = checkCallingOrSelfPermission(
            Manifest.permission.WRITE_SECURE_SETTINGS
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasWriteSecure) {
            return mapOf(
                "success" to false,
                "error" to "PERMISSION_DENIED",
                "message" to "Membutuhkan izin WRITE_SECURE_SETTINGS."
            )
        }

        return try {
            Settings.Global.putString(contentResolver, "private_dns_mode", mode)
            if (mode == "hostname" && !hostname.isNullOrBlank()) {
                Settings.Global.putString(contentResolver, "private_dns_specifier", hostname.trim())
            }
            mapOf("success" to true)
        } catch (e: Exception) {
            mapOf("success" to false, "error" to e.javaClass.simpleName, "message" to e.message)
        }
    }

    private fun getFeatureStatesMap(): Map<String, Any?> {
        val hasWriteSecure = checkCallingOrSelfPermission(
            Manifest.permission.WRITE_SECURE_SETTINGS
        ) == PackageManager.PERMISSION_GRANTED

        // 1. Private DNS
        val dnsMode = try {
            Settings.Global.getString(contentResolver, "private_dns_mode") ?: ""
        } catch (_: Exception) { "" }
        val dnsSpecifier = try {
            Settings.Global.getString(contentResolver, "private_dns_specifier") ?: ""
        } catch (_: Exception) { "" }
        val dnsActive = dnsMode.isNotEmpty() && dnsMode != "off"

        // 2. WiFi
        val wifiActive = try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            wm?.isWifiEnabled ?: (Settings.Global.getInt(contentResolver, "wifi_on", 0) != 0)
        } catch (_: Exception) { false }

        // 3. Bluetooth
        val btActive = try {
            val bm = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bm?.adapter?.isEnabled ?: false
        } catch (_: Exception) { false }

        // 4. Battery Saver
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
        val batterySaverActive = pm?.isPowerSaveMode ?: false

        // 5. Location (GPS)
        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        val locationActive = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            lm?.isLocationEnabled ?: false
        } else {
            try {
                Settings.Secure.getInt(contentResolver, Settings.Secure.LOCATION_MODE) != Settings.Secure.LOCATION_MODE_OFF
            } catch (_: Exception) { false }
        }

        // 6. NFC
        val nfcAdapter = try { NfcAdapter.getDefaultAdapter(this) } catch (_: Exception) { null }
        val nfcActive = nfcAdapter?.isEnabled ?: false

        // 7. Sound Ringer Mode
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val ringerMode = when (am?.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            else -> "normal"
        }

        return mapOf(
            "hasWriteSecureSettings" to hasWriteSecure,
            "private_dns" to dnsActive,
            "private_dns_mode" to dnsMode,
            "private_dns_specifier" to dnsSpecifier,
            "wifi" to wifiActive,
            "bluetooth" to btActive,
            "battery_saver" to batterySaverActive,
            "location" to locationActive,
            "nfc" to nfcActive,
            "sound" to ringerMode,
        )
    }

    private fun toggleFeatureDirect(id: String): Map<String, Any?> {
        val hasWriteSecure = checkCallingOrSelfPermission(
            Manifest.permission.WRITE_SECURE_SETTINGS
        ) == PackageManager.PERMISSION_GRANTED

        when (id) {
            "private_dns" -> {
                val currentMode = try {
                    Settings.Global.getString(contentResolver, "private_dns_mode") ?: ""
                } catch (_: Exception) { "" }
                val currentSpec = try {
                    Settings.Global.getString(contentResolver, "private_dns_specifier") ?: ""
                } catch (_: Exception) { "" }

                if (hasWriteSecure) {
                    return try {
                        if (currentMode == "off" || currentMode.isEmpty()) {
                            val targetSpec = if (currentSpec.isNotBlank()) currentSpec else "p2.freedns.controld.com"
                            Settings.Global.putString(contentResolver, "private_dns_mode", "hostname")
                            Settings.Global.putString(contentResolver, "private_dns_specifier", targetSpec)
                            mapOf("success" to true, "state" to true, "label" to targetSpec)
                        } else {
                            Settings.Global.putString(contentResolver, "private_dns_mode", "off")
                            mapOf("success" to true, "state" to false, "label" to "Mati")
                        }
                    } catch (e: Exception) {
                        mapOf("success" to false, "error" to e.message)
                    }
                } else {
                    return mapOf("success" to false, "needsPermission" to true)
                }
            }
            "wifi" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val panelIntent = Intent(Settings.Panel.ACTION_WIFI).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    if (panelIntent.resolveActivity(packageManager) != null) {
                        startActivity(panelIntent)
                        return mapOf("success" to true, "panel" to true)
                    }
                }
                openSettingsChain("android.settings.WIFI_SETTINGS", emptyList(), null)
                return mapOf("success" to true)
            }
            "nfc" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val panelIntent = Intent(Settings.Panel.ACTION_NFC).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    if (panelIntent.resolveActivity(packageManager) != null) {
                        startActivity(panelIntent)
                        return mapOf("success" to true, "panel" to true)
                    }
                }
                openSettingsChain("android.settings.NFC_SETTINGS", emptyList(), null)
                return mapOf("success" to true)
            }
            "sound" -> {
                val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                if (am != null) {
                    val nextMode = when (am.ringerMode) {
                        AudioManager.RINGER_MODE_NORMAL -> AudioManager.RINGER_MODE_VIBRATE
                        AudioManager.RINGER_MODE_VIBRATE -> AudioManager.RINGER_MODE_SILENT
                        else -> AudioManager.RINGER_MODE_NORMAL
                    }
                    try {
                        am.ringerMode = nextMode
                        val label = when (nextMode) {
                            AudioManager.RINGER_MODE_SILENT -> "Hening (Silent)"
                            AudioManager.RINGER_MODE_VIBRATE -> "Getar (Vibrate)"
                            else -> "Normal (Suara Aktif)"
                        }
                        return mapOf("success" to true, "label" to label)
                    } catch (_: Exception) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val panelIntent = Intent(Settings.Panel.ACTION_VOLUME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            if (panelIntent.resolveActivity(packageManager) != null) {
                                startActivity(panelIntent)
                                return mapOf("success" to true, "panel" to true)
                            }
                        }
                    }
                }
                openSettingsChain("android.settings.SOUND_SETTINGS", emptyList(), null)
                return mapOf("success" to true)
            }
            "battery_saver" -> {
                if (hasWriteSecure) {
                    val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val isLow = pm?.isPowerSaveMode ?: false
                    try {
                        Settings.Global.putInt(contentResolver, "low_power", if (isLow) 0 else 1)
                        return mapOf("success" to true, "state" to !isLow)
                    } catch (_: Exception) {}
                }
                openSettingsChain("android.settings.BATTERY_SAVER_SETTINGS", emptyList(), null)
                return mapOf("success" to true)
            }
            "location" -> {
                openSettingsChain("android.settings.LOCATION_SOURCE_SETTINGS", emptyList(), null)
                return mapOf("success" to true)
            }
            "bluetooth" -> {
                openSettingsChain("android.settings.BLUETOOTH_SETTINGS", emptyList(), null)
                return mapOf("success" to true)
            }
            else -> {
                return mapOf("success" to false)
            }
        }
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
