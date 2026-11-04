package mx.sidarta.al_tiro

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val circulationChannelId = "circulation_status"
    private val circulationNotificationId = 105
    private val notificationPermissionRequest = 106
    private var permissionReply: MethodChannel.Result? = null

    private fun notificationsAllowed(): Boolean =
        (Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
            getSystemService(NotificationManager::class.java).areNotificationsEnabled()

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationPermissionRequest) {
            permissionReply?.success(notificationsAllowed())
            permissionReply = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.sidarta.al_tiro/circulation_alerts")
            .setMethodCallHandler { call, result ->
                val manager = getSystemService(NotificationManager::class.java)
                when (call.method) {
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33 &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED &&
                            permissionReply == null
                        ) {
                            permissionReply = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), notificationPermissionRequest)
                        } else {
                            result.success(notificationsAllowed())
                        }
                    }
                    "clear" -> {
                        manager.cancel(circulationNotificationId)
                        result.success(null)
                    }
                    "post" -> {
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        val channelName = call.argument<String>("channelName")
                        val timeout = call.argument<Number>("timeoutMs")?.toLong()
                        if (!notificationsAllowed() || title == null || body == null || channelName == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val builder = if (Build.VERSION.SDK_INT >= 26) {
                            manager.createNotificationChannel(
                                NotificationChannel(circulationChannelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
                            )
                            if (manager.getNotificationChannel(circulationChannelId).importance == NotificationManager.IMPORTANCE_NONE) {
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            Notification.Builder(this, circulationChannelId)
                        } else {
                            @Suppress("DEPRECATION")
                            Notification.Builder(this)
                        }
                        if (Build.VERSION.SDK_INT >= 26 && timeout != null && timeout > 0) {
                            builder.setTimeoutAfter(timeout)
                        }
                        val launch = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val openApp = PendingIntent.getActivity(
                            this, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                        )
                        try {
                            manager.notify(circulationNotificationId, builder
                                .setSmallIcon(R.drawable.ic_circulation_notification)
                                .setContentTitle(title)
                                .setContentText(body)
                                .setContentIntent(openApp)
                                .setVisibility(Notification.VISIBILITY_PRIVATE)
                                .setAutoCancel(true)
                                .build())
                            result.success(true)
                        } catch (_: SecurityException) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
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
