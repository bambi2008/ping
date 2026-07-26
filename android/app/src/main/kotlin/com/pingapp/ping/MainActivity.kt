package com.pingapp.ping

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ping/notifications"
    private val permissionRequestCode = 9017
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler(::handleNotificationCall)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ping/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, call.argument<String>("text").orEmpty())
                    putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject").orEmpty())
                }
                startActivity(Intent.createChooser(intent, null))
                result.success(null)
            }
        createNotificationChannel()
    }

    private fun handleNotificationCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> requestNotificationPermission(result)
            "schedule" -> {
                schedule(
                    call.argument<Int>("id") ?: 0,
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("body").orEmpty(),
                    call.argument<Number>("epochMillis")?.toLong() ?: 0L,
                )
                result.success(null)
            }
            "cancel" -> {
                cancel(call.argument<Int>("id") ?: 0)
                result.success(null)
            }
            "cancelAll" -> {
                cancelAll()
                result.success(null)
            }
            "showNow" -> {
                NotificationReceiver.show(
                    this,
                    call.argument<Int>("id") ?: 0,
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("body").orEmpty(),
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            permissionRequestCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    private fun schedule(id: Int, title: String, body: String, epochMillis: Long) {
        if (epochMillis <= System.currentTimeMillis()) return
        val intent = NotificationReceiver.intent(this, id, title, body)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            epochMillis,
            pendingIntent,
        )
        scheduledIds().edit().putBoolean(id.toString(), true).apply()
    }

    private fun cancel(id: Int) {
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            NotificationReceiver.intent(this, id, "", ""),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (pendingIntent != null) {
            (getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pendingIntent)
            pendingIntent.cancel()
        }
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id)
        scheduledIds().edit().remove(id.toString()).apply()
    }

    private fun cancelAll() {
        val ids = scheduledIds().all.keys.mapNotNull(String::toIntOrNull)
        ids.forEach(::cancel)
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancelAll()
        scheduledIds().edit().clear().apply()
    }

    private fun scheduledIds() =
        getSharedPreferences("ping_notification_ids", Context.MODE_PRIVATE)

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                NotificationReceiver.channelId,
                "Bill reminders",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Upcoming subscription renewal alerts"
            },
        )
    }
}
