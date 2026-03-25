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
        val pendingResult = goAsync() // Tell Android "I need more time"

        try {
            val soundName = intent.getStringExtra("sound") ?: "makah"
            val prayerName = intent.getStringExtra("prayerName") ?: "الصلاة"
            val volume = intent.getFloatExtra("volume", 1.0f)

            // Keep CPU awake briefly so we can post notification + start service reliably.
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Salaty:AzanReceiverWake")
            wl.acquire(60_000L)

            try {
                // Fallback that works even if FGS start is restricted: play azan as notification sound.
                // (Channel sound is required; per-sound channels avoid channel-sound immutability issues.)
                postAzanAlarmNotification(context, soundName, prayerName)

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

    private fun postAzanAlarmNotification(context: Context, soundName: String, prayerName: String) {
        try {
            val manager = context.getSystemService(NotificationManager::class.java)
            val channelId = "azan_alarm_${soundName}_v1"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val resId = context.resources.getIdentifier(soundName, "raw", context.packageName)
                val soundUri = if (resId != 0) {
                    android.net.Uri.parse("android.resource://${context.packageName}/$resId")
                } else null

                val attrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()

                val existing = manager.getNotificationChannel(channelId)
                if (existing == null) {
                    val ch = NotificationChannel(channelId, "Azan Alarm ($soundName)", NotificationManager.IMPORTANCE_HIGH).apply {
                        description = "Azan alarm fallback notification sound"
                        setSound(soundUri, attrs)
                        enableVibration(true)
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    }
                    manager.createNotificationChannel(ch)
                }
            }

            val notif = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("حان الآن موعد الصلاة")
                .setContentText("الأذان: $prayerName")
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .build()

            // Use a stable ID per prayer name so notifications don't pile up.
            val id = ("azan_alarm_" + prayerName).hashCode()
            manager.notify(id, notif)
        } catch (e: Exception) {
            Log.w("AzanReceiver", "Failed posting azan alarm notification: $e")
        }
    }
}
