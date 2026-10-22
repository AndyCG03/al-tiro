package mx.sidarta.al_tiro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
