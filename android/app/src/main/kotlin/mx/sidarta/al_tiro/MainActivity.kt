package mx.sidarta.al_tiro

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.sidarta.al_tiro/calendar")
            .setMethodCallHandler { call, result ->
                if (call.method != "addEvent") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val title = call.argument<String>("title")
                val start = call.argument<Long>("start")
                val end = call.argument<Long>("end")
                if (title.isNullOrBlank() || start == null || end == null || end <= start) {
                    result.error("bad_args", null, null)
                    return@setMethodCallHandler
                }
                val intent = Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI)
                    .putExtra(CalendarContract.Events.TITLE, title)
                    .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
                    .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
                    .putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, true)
                try {
                    startActivity(intent)
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.success(false)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.sidarta.al_tiro/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "update") {
                    val data = call.arguments as? Map<*, *>
                    if (data == null) {
                        result.error("bad_args", "Se esperaba un mapa", null)
                    } else {
                        AlTiroWidgetProvider.save(applicationContext, data)
                        AlTiroWidgetProvider.refreshAll(applicationContext)
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
