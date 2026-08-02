package com.ping.widget

import android.content.Context
import android.content.SharedPreferences
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.*
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.color.ColorProvider
import androidx.glance.unit.ColorProvider as ColorProviderUnit

class PingWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Single

    override fun Content() {
        val prefs = LocalContext.current.getSharedPreferences("flutter.subscriptions_v1", Context.MODE_PRIVATE)
        // The data is stored by Flutter's shared_preferences, accessible via "flutter." prefix
        // We read from a simpler key that our WidgetService writes
        val totalMonthly = prefs.getString("ping_widget_total", "€0") ?: "€0"
        val activeCount = prefs.getString("ping_widget_count", "0") ?: "0"

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(day = android.graphics.Color.parseColor("#1A1A2E"), night = android.graphics.Color.parseColor("#0F0F1A")))
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = GlanceModifier.fillMaxSize()
            ) {
                Text(
                    "Monthly Spend",
                    style = TextStyle(
                        color = ColorProvider(day = android.graphics.Color.WHITE, night = android.graphics.Color.WHITE),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
                Spacer(GlanceModifier.height(4.dp))
                Text(
                    totalMonthly,
                    style = TextStyle(
                        color = ColorProvider(day = android.graphics.Color.WHITE, night = android.graphics.Color.WHITE),
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
                Spacer(GlanceModifier.height(4.dp))
                Text(
                    "$activeCount active subscriptions",
                    style = TextStyle(
                        color = ColorProvider(day = android.graphics.Color.parseColor("#8E8E9E"), night = android.graphics.Color.parseColor("#8E8E9E")),
                        fontSize = 11.sp
                    )
                )
            }
        }
    }
}

class PingWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = PingWidget()
}
