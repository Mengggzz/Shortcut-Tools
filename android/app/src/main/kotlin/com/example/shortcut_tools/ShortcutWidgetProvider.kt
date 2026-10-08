package com.example.shortcut_tools

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

/**
 * Home Screen Widget: menampilkan hingga 4 pintasan favorit sebagai tombol.
 * Tap tombol → WidgetLaunchActivity langsung membuka halaman Settings-nya
 * tanpa membuka aplikasi (ringan, tanpa Flutter engine).
 *
 * Data favorit dibaca dari SharedPreferences milik Flutter
 * ("FlutterSharedPreferences", key "flutter.favorite_shortcut_ids" +
 * "flutter.fav_data_<id>").
 */
class ShortcutWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        mgr: AppWidgetManager,
        ids: IntArray,
    ) {
        for (id in ids) updateOne(context, mgr, id)
    }

    private data class Fav(
        val title: String,
        val action: String,
        val fallbacks: List<String>,
        val dataUri: String?,
    )

    private fun updateOne(context: Context, mgr: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_shortcuts)
        val favs = readFavs(context)

        if (favs.isEmpty()) {
            for (b in BTN_IDS) views.setViewVisibility(b, View.GONE)
            views.setViewVisibility(R.id.wempty, View.VISIBLE)
            val openApp = PendingIntent.getActivity(
                context,
                widgetId,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.wempty, openApp)
        } else {
            views.setViewVisibility(R.id.wempty, View.GONE)
            for (i in BTN_IDS.indices) {
                if (i < favs.size) {
                    val f = favs[i]
                    views.setViewVisibility(BTN_IDS[i], View.VISIBLE)
                    views.setTextViewText(BTN_IDS[i], f.title)
                    val intent = Intent(context, WidgetLaunchActivity::class.java).apply {
                        putExtra(MainActivity.EXTRA_ACTION, f.action)
                        putStringArrayListExtra(
                            MainActivity.EXTRA_FALLBACKS, ArrayList(f.fallbacks))
                        if (f.dataUri != null) {
                            putExtra(MainActivity.EXTRA_DATA_URI, f.dataUri)
                        }
                    }
                    val pi = PendingIntent.getActivity(
                        context,
                        widgetId * 10 + i,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    views.setOnClickPendingIntent(BTN_IDS[i], pi)
                } else {
                    views.setViewVisibility(BTN_IDS[i], View.GONE)
                }
            }
        }
        mgr.updateAppWidget(widgetId, views)
    }

    companion object {
        private const val PREFS = "FlutterSharedPreferences"
        private const val KEY_FAVS = "flutter.favorite_shortcut_ids"
        private const val MAX = 4
        private val BTN_IDS = intArrayOf(
            R.id.wbtn0, R.id.wbtn1, R.id.wbtn2, R.id.wbtn3)

        /** Refresh semua instance widget. Dipanggil aplikasi setelah favorit berubah. */
        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, ShortcutWidgetProvider::class.java))
            val provider = ShortcutWidgetProvider()
            for (id in ids) provider.updateOne(context, mgr, id)
        }

        private fun readFavs(context: Context): List<Fav> {
            val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw = sp.getString(KEY_FAVS, null) ?: return emptyList()
            val out = mutableListOf<Fav>()
            try {
                val arr = JSONArray(raw)
                for (i in 0 until minOf(arr.length(), MAX)) {
                    val id = arr.getString(i)
                    val dataRaw = sp.getString("flutter.fav_data_$id", null)
                        ?: continue
                    val o = JSONObject(dataRaw)
                    val fb = mutableListOf<String>()
                    val fba = o.optJSONArray("fallbacks")
                    if (fba != null) {
                        for (j in 0 until fba.length()) fb.add(fba.getString(j))
                    }
                    val uri = o.optString("dataUri", "").takeIf { it.isNotEmpty() }
                    out.add(Fav(o.optString("title", id), o.optString("action", ""), fb, uri))
                }
            } catch (_: Exception) {
                // Preferensi korup → widget tampil kosong.
            }
            return out
        }
    }
}
