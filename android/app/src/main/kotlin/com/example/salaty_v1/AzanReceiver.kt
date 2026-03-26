package com.example.salaty_v1

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AzanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync() 

        try {
            val soundName = intent.getStringExtra("sound") ?: "makah"
            val prayerName = intent.getStringExtra("prayerName") ?: "الصلاة"
            val volume = intent.getFloatExtra("volume", 1.0f)

            // 1. Acquire WakeLock briefly to ensure service starts
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Salaty:AzanReceiverWake")
            wl.acquire(30_000L)

            try {
                // Post the notification IMMEDIATELY from the receiver.
                // This gives the user instant feedback and satisfies the visually immediate requirement for alarms.
                // We use ID 1001 so the AzanService can "adopt" it via startForeground.
                showPlaceholderNotification(context, prayerName)

                val serviceIntent = Intent(context, AzanService::class.java).apply {
                    putExtra("sound", soundName)
                    putExtra("volume", volume)
                    putExtra("prayerName", prayerName)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } finally {
                if (wl.isHeld) wl.release()
            }
        } finally {
            pendingResult.finish()
        }
    }

    /**
     * Shows a notification that AzanService will later promote to a foreground service notification.
     * Uses ID 1001 and azan_service_channel (which is silent).
     */
    private fun showPlaceholderNotification(context: Context, prayerName: String) {
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_MANAGER_SERVICE) as NotificationManager
            val channelId = "azan_service_channel"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val existing = manager.getNotificationChannel(channelId)
                if (existing == null) {
                    val ch = NotificationChannel(channelId, "Azan Service", NotificationManager.IMPORTANCE_HIGH).apply {
                        description = "تنبيهات الأذان"
                        setSound(null, null) // Silent channel; AzanService plays via MediaPlayer
                        enableVibration(true)
                        lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                    }
                    manager.createNotificationChannel(ch)
                }
            }

            // Simple intent to open app
            val mainIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val contentIntent = PendingIntent.getActivity(
                context, 101, mainIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notif = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("حان الآن موعد الصلاة")
                .setContentText("الأذان: $prayerName")
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true) 
                .setContentIntent(contentIntent)
                .build()

            manager.notify(1001, notif)
        } catch (e: Exception) {
            Log.w("AzanReceiver", "Failed posting placeholder: $e")
        }
    }
}
