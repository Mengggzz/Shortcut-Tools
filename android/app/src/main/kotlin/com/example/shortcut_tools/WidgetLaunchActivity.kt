package com.example.shortcut_tools

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings

/**
 * Activity transparan untuk widget: menerima action dari PendingIntent,
 * langsung membuka halaman Settings yang dituju, lalu finish.
 * Tidak memutar Flutter engine — ringan.
 */
class WidgetLaunchActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val action = intent.getStringExtra(MainActivity.EXTRA_ACTION).orEmpty()
        val fallbacks =
            intent.getStringArrayListExtra(MainActivity.EXTRA_FALLBACKS) ?: arrayListOf()
        var dataUri = intent.getStringExtra(MainActivity.EXTRA_DATA_URI)
        if (dataUri == "package:self") dataUri = "package:$packageName"

        val candidates = (listOf(action) + fallbacks + Settings.ACTION_SETTINGS)
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
        for (a in candidates) {
            try {
                val i = Intent(a).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (dataUri != null) i.data = Uri.parse(dataUri)
                if (i.resolveActivity(packageManager) != null) {
                    startActivity(i)
                    break
                }
            } catch (_: Exception) {
                // Coba kandidat berikutnya.
            }
        }
        finish()
    }
}
