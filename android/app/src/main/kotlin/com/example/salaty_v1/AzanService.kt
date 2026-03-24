package com.example.salaty_v1

import android.app.*
import android.content.Intent
import android.media.MediaPlayer
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log

class AzanService : Service() {

    private var mediaPlayer: MediaPlayer? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_AZAN") {
            Log.d("AzanService", "Stopping Azan per user request")
            stopSelf()
            return START_NOT_STICKY
        }

        val soundName = intent?.getStringExtra("sound") ?: "makah"
        Log.d("AzanService", "Starting Azan service with sound: $soundName")

        val resId = resources.getIdentifier(soundName, "raw", packageName)
        
        if (resId != 0) {
            mediaPlayer = MediaPlayer.create(this, resId)
            // 🔥 IMPORTANT: Alarm stream (bypass silent)
            mediaPlayer?.setAudioStreamType(android.media.AudioManager.STREAM_ALARM)
            mediaPlayer?.isLooping = false
            mediaPlayer?.start()

            // Stop service when done
            mediaPlayer?.setOnCompletionListener {
                Log.d("AzanService", "Playback complete, stopping service")
                stopSelf()
            }
        } else {
            Log.e("AzanService", "Resource not found for sound: $soundName")
            stopSelf()
        }

        startForeground(1001, createNotification())

        return START_NOT_STICKY
    }

    private fun createNotification(): Notification {
        val channelId = "azan_service_channel"
        val manager = getSystemService(NotificationManager::class.java)

        val channel = NotificationChannel(
            channelId,
            "Azan Service",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تضمن تشغيل الأذان في الوقت المحدد"
            setSound(null, null)
            enableVibration(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }

        manager.createNotificationChannel(channel)

        // Intent to open the app (Full-Screen or just click)
        val mainPageIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("full_screen_azan", true)
        }
        
        val contentPendingIntent = PendingIntent.getActivity(
            this, 101, mainPageIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Stop button intent
        val stopIntent = Intent(this, AzanService::class.java).apply {
            action = "STOP_AZAN"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 102, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("حان الآن موعد الصلاة")
            .setContentText("جاري تشغيل الأذان...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentPendingIntent)
            .setFullScreenIntent(contentPendingIntent, true)
            .setStyle(NotificationCompat.BigTextStyle().bigText("حان الآن موعد الصلاة - جاري تشغيل الأذان"))
            .addAction(android.R.drawable.ic_delete, "إيقاف الأذان", stopPendingIntent)
            .build()
    }

    override fun onDestroy() {
        Log.d("AzanService", "AzanService destroyed")
        mediaPlayer?.release()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
