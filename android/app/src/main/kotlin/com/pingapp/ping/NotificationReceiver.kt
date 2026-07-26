package com.pingapp.ping

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat

class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(extraId, 0)
        show(
            context,
            id,
            intent.getStringExtra(extraTitle).orEmpty(),
            intent.getStringExtra(extraBody).orEmpty(),
        )
        context.getSharedPreferences("ping_notification_ids", Context.MODE_PRIVATE)
            .edit()
            .remove(id.toString())
            .apply()
    }

    companion object {
        const val channelId = "bills"
        private const val extraId = "id"
        private const val extraTitle = "title"
        private const val extraBody = "body"

        fun intent(
            context: Context,
            id: Int,
            title: String,
            body: String,
        ) = Intent(context, NotificationReceiver::class.java).apply {
            putExtra(extraId, id)
            putExtra(extraTitle, title)
            putExtra(extraBody, body)
        }

        fun show(context: Context, id: Int, title: String, body: String) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            val launchIntent =
                context.packageManager.getLaunchIntentForPackage(context.packageName)
            val contentIntent = PendingIntent.getActivity(
                context,
                id,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build()
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .notify(id, notification)
        }
    }
}
