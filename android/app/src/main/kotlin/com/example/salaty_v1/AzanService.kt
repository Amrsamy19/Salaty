package com.example.salaty_v1

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import android.util.Log
import org.json.JSONObject

class AzanService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var previousAlarmVolume: Int? = null
    private var previousMusicVolume: Int? = null

    private fun applySystemVolume(userLevel01: Float) {
        try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            val clamped = userLevel01.coerceIn(0.0f, 1.0f)

            // Save current volumes once (first time we apply).
            if (previousAlarmVolume == null) previousAlarmVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            if (previousMusicVolume == null) previousMusicVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)

            // Map 0..1 -> 1..max (avoid 0 so it doesn't become silent unintentionally).
            fun target(stream: Int): Int {
                val max = audioManager.getStreamMaxVolume(stream).coerceAtLeast(1)
                val t = (clamped * max).toInt().coerceIn(1, max)
                return t
            }

            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, target(AudioManager.STREAM_ALARM), 0)
            // Some devices route MediaPlayer alarms through MUSIC; set both for consistency.
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, target(AudioManager.STREAM_MUSIC), 0)
        } catch (e: Exception) {
            Log.w("AzanService", "Failed to set system volume: $e")
        }
    }

    private fun restoreSystemVolume() {
        try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            previousAlarmVolume?.let { audioManager.setStreamVolume(AudioManager.STREAM_ALARM, it, 0) }
            previousMusicVolume?.let { audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, it, 0) }
        } catch (e: Exception) {
            Log.w("AzanService", "Failed to restore system volume: $e")
        } finally {
            previousAlarmVolume = null
            previousMusicVolume = null
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Start Foreground immediately to satisfy Android's 5-second rule
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(1001, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(1001, createNotification())
        }

        if (intent?.action == "STOP_AZAN") {
            Log.d("AzanService", "Stopping Azan per user request")
            restoreSystemVolume()
            stopSelf()
            return START_NOT_STICKY
        }

        val soundName = intent?.getStringExtra("sound") ?: "makah"
        val prayerName = intent?.getStringExtra("prayerName") ?: "الصلاة"

        // Retrieve Current Volume (single source of truth: settings slider).
        // Prefer the dedicated native pref written via method channel, but also fall back to Flutter SharedPreferences.
        val fallbackVolume = intent?.getFloatExtra("volume", 1.0f) ?: 1.0f
        val salatyPrefs = getSharedPreferences("salaty_prefs", Context.MODE_PRIVATE)
        var currentVolume: Float? = if (salatyPrefs.contains("azan_volume")) salatyPrefs.getFloat("azan_volume", fallbackVolume) else null

        if (currentVolume == null) {
            // Flutter's shared_preferences stores in "FlutterSharedPreferences" with "flutter." prefix.
            try {
                val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val settingsJson = flutterPrefs.getString("flutter.app_settings", null)
                if (!settingsJson.isNullOrBlank()) {
                    val obj = JSONObject(settingsJson)
                    val v = obj.optDouble("azanVolume", Double.NaN)
                    if (!v.isNaN()) currentVolume = v.toFloat()
                }
            } catch (e: Exception) {
                Log.w("AzanService", "Failed reading volume from Flutter prefs: $e")
            }
        }

        val resolvedVolume = (currentVolume ?: fallbackVolume).coerceIn(0.0f, 1.0f)
        
        Log.d("AzanService", "Azan triggered. Sound: $soundName, User Volume: $resolvedVolume, Prayer: $prayerName")

        // Set phone system volume to the user's azan level.
        applySystemVolume(resolvedVolume)

        // 2. Acquire WakeLock to ensure system doesn't sleep during playback
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Salaty:AzanWakeLock")
        wakeLock?.acquire(5 * 60 * 1000L /*5 minutes max*/)

        val resId = resources.getIdentifier(soundName, "raw", packageName)
        
        if (resId != 0) {
            mediaPlayer = MediaPlayer.create(this, resId)
            
            // 2. Configure Audio Attributes (Alarm stream)
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            
            mediaPlayer?.setAudioAttributes(audioAttributes)
            mediaPlayer?.setVolume(resolvedVolume, resolvedVolume)
            mediaPlayer?.isLooping = false
            mediaPlayer?.start()

            // Stop service when done
            mediaPlayer?.setOnCompletionListener {
                Log.d("AzanService", "Playback complete, stopping service")
                restoreSystemVolume()
                stopSelf()
            }
        } else {
            Log.e("AzanService", "Resource not found for sound: $soundName")
            restoreSystemVolume()
            stopSelf()
        }

        return START_STICKY
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
            .addAction(android.R.drawable.ic_notification_clear_all, "إيقاف الأذان", stopPendingIntent)
            .build()
    }

    override fun onDestroy() {
        Log.d("AzanService", "AzanService destroyed")
        restoreSystemVolume()
        mediaPlayer?.release()
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
