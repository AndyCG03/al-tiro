package mx.sidarta.al_tiro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

/**
 * Widget de pantalla de inicio de Al Tiro. Elige entre tres diseños según el
 * tamaño que el usuario le dé en el launcher (compacto, medio y grande).
 * Los datos los publica la app Flutter por el canal `mx.sidarta.al_tiro/widget`.
 */
class AlTiroWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        render(context, manager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, manager, appWidgetId, newOptions)
    }

    companion object {
        private const val PREFS = "al_tiro_widget"
        private val KEYS = listOf("state", "headline", "pill", "plate", "detail", "date")

        fun save(context: Context, data: Map<*, *>) {
            val edit = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            KEYS.forEach { edit.putString(it, data[it]?.toString() ?: "") }
            edit.putLong("validUntil", (data["validUntil"] as? Number)?.toLong() ?: 0L)
            edit.apply()
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, AlTiroWidgetProvider::class.java))
            ids.forEach { render(context, manager, it) }
        }

        private fun layoutFor(widthDp: Int, heightDp: Int): Int = when {
            widthDp >= 250 && heightDp >= 150 -> R.layout.widget_large
            heightDp < 90 || widthDp < 170 -> R.layout.widget_small
            else -> R.layout.widget_medium
        }

        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val options = manager.getAppWidgetOptions(id)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
            val layout = layoutFor(widthDp, heightDp)
            val views = RemoteViews(context.packageName, layout)

            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val validUntil = prefs.getLong("validUntil", 0L)
            val hasData = validUntil > 0L
            val stale = hasData && System.currentTimeMillis() >= validUntil

            val state: String
            val headline: String
            val pill: String
            val plate: String
            val detail: String
            val date: String
            if (!hasData) {
                state = "review"
                headline = context.getString(R.string.widget_placeholder_headline)
                pill = context.getString(R.string.widget_placeholder_pill)
                plate = ""
                detail = ""
                date = ""
            } else if (stale) {
                state = "review"
                headline = context.getString(R.string.widget_stale_headline)
                pill = context.getString(R.string.widget_stale_pill)
                plate = prefs.getString("plate", "") ?: ""
                detail = ""
                date = ""
            } else {
                state = prefs.getString("state", "review") ?: "review"
                headline = prefs.getString("headline", "") ?: ""
                pill = prefs.getString("pill", "") ?: ""
                plate = prefs.getString("plate", "") ?: ""
                detail = prefs.getString("detail", "") ?: ""
                date = prefs.getString("date", "") ?: ""
            }

            // El estado no depende sólo del color: lleva símbolo y texto.
            val symbol = when (state) {
                "allowed" -> "✓ "
                "restricted" -> "✕ "
                else -> "! "
            }
            val pillBg = when (state) {
                "allowed" -> R.drawable.widget_pill_allowed
                "restricted" -> R.drawable.widget_pill_restricted
                else -> R.drawable.widget_pill_review
            }
            val pillColor = if (state == "allowed") R.color.widget_allowed_text else R.color.widget_charcoal

            views.setTextViewText(R.id.w_pill, symbol + pill)
            views.setInt(R.id.w_pill, "setBackgroundResource", pillBg)
            views.setTextColor(R.id.w_pill, context.getColor(pillColor))
            views.setTextViewText(R.id.w_plate, plate)
            views.setViewVisibility(R.id.w_plate, if (plate.isEmpty()) View.GONE else View.VISIBLE)
            if (layout != R.layout.widget_small) {
                views.setTextViewText(R.id.w_headline, headline)
                views.setTextViewText(R.id.w_date, date)
                views.setViewVisibility(R.id.w_date, if (date.isEmpty()) View.GONE else View.VISIBLE)
            }
            if (layout == R.layout.widget_large) {
                views.setTextViewText(R.id.w_detail, detail)
                views.setViewVisibility(R.id.w_detail, if (detail.isEmpty()) View.GONE else View.VISIBLE)
            }
            views.setContentDescription(
                R.id.w_root,
                listOf(headline, plate, detail).filter { it.isNotEmpty() }.joinToString(". "),
            )

            val launch = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            views.setOnClickPendingIntent(
                R.id.w_root,
                PendingIntent.getActivity(
                    context,
                    0,
                    launch,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
            manager.updateAppWidget(id, views)
        }
    }
}
