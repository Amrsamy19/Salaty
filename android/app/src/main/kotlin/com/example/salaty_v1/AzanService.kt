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
import kotlin.math.roundToInt

class AzanService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var previousAlarmVolume: Int? = null
    private var previousMusicVolume: Int? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private fun applySystemVolume(userLevel01: Float) {
        try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            val clamped = userLevel01.coerceIn(0.0f, 1.0f)

            if (previousAlarmVolume == null) previousAlarmVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            if (previousMusicVolume == null) previousMusicVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)

            fun target(stream: Int): Int {
                val max = audioManager.getStreamMaxVolume(stream).coerceAtLeast(1)
                if (clamped >= 0.99f) return max
                return (clamped * max).roundToInt().coerceIn(1, max)
            }

            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, target(AudioManager.STREAM_ALARM), 0)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, target(AudioManager.STREAM_MUSIC), 0)
        } catch (e: Exception) {
            Log.w("AzanService", "Failed to set system volume: $e")
        }
    }

    private fun requestAudioFocus(): Boolean {
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val playbackAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(playbackAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener { focusChange ->
                    if (focusChange == AudioManager.AUDIOFOCUS_LOSS || focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                        mediaPlayer?.pause()
                    } else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
                        mediaPlayer?.start()
                    }
                }
                .build()
            audioManager.requestAudioFocus(audioFocusRequest!!) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonAudioFocus() {
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
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
        val soundName = intent?.getStringExtra("sound") ?: "makah"
        val prayerName = intent?.getStringExtra("prayerName") ?: "الصلاة"

        // 1. Start Foreground immediately (matching ID 1001 from AzanReceiver)
        val notification = createNotification(prayerName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(1001, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(1001, notification)
        }

        if (intent?.action == "STOP_AZAN") {
            Log.d("AzanService", "Stopping Azan per user request")
            stopSelf()
            return START_NOT_STICKY
        }

        // Retrieve Current Volume
        val fallbackVolume = intent?.getFloatExtra("volume", 1.0f) ?: 1.0f
        val salatyPrefs = getSharedPreferences("salaty_prefs", Context.MODE_PRIVATE)
        var currentVolume: Float? = if (salatyPrefs.contains("azan_volume")) salatyPrefs.getFloat("azan_volume", fallbackVolume) else null

        if (currentVolume == null) {
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

        applySystemVolume(resolvedVolume)

        // 2. Acquire WakeLock
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Salaty:AzanWakeLock")
        wakeLock?.acquire(10 * 60 * 1000L /*10 minutes max*/)

        // 3. Audio Focus
        requestAudioFocus()

        val resId = resources.getIdentifier(soundName, "raw", packageName)
        if (resId != 0) {
            mediaPlayer = MediaPlayer.create(this, resId)
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            
            mediaPlayer?.setAudioAttributes(audioAttributes)
            mediaPlayer?.setVolume(resolvedVolume, resolvedVolume)
            mediaPlayer?.isLooping = false
            mediaPlayer?.start()

            mediaPlayer?.setOnCompletionListener {
                Log.d("AzanService", "Playback complete, stopping service")
                stopSelf()
            }
            mediaPlayer?.setOnErrorListener { _, what, extra ->
                Log.e("AzanService", "MediaPlayer error: $what, $extra")
                stopSelf()
                true
            }
        } else {
            Log.e("AzanService", "Resource not found for sound: $soundName")
            stopSelf()
        }

        return START_STICKY
    }

    private fun createNotification(prayerName: String): Notification {
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

        val mainPageIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("full_screen_azan", true)
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this, 101, mainPageIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, AzanService::class.java).apply {
            action = "STOP_AZAN"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 102, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("حان الآن موعد الصلاة")
            .setContentText("الأذان: $prayerName (جاري التشغيل)")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentPendingIntent)
            .setFullScreenIntent(contentPendingIntent, true)
            .setStyle(NotificationCompat.BigTextStyle().bigText("حان الآن موعد الصلاة - جاري تشغيل الأذان ($prayerName)"))
            .addAction(android.R.drawable.ic_notification_clear_all, "إيقاف الأذان", stopPendingIntent)
            .build()
    }

    override fun onDestroy() {
        Log.d("AzanService", "AzanService destroying")
        restoreSystemVolume()
        abandonAudioFocus()
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
