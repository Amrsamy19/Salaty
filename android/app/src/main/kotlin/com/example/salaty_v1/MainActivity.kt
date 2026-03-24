package com.example.salaty_v1

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "azan_channel"
    private var isAzanTriggered = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAzan" -> {
                        val time = call.argument<Long>("time")!!
                        val sound = call.argument<String>("sound")!!
                        val volume = call.argument<Double>("volume") ?: 1.0
                        val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                        scheduleAzan(time, sound, volume.toFloat(), prayerName)
                        result.success(null)
                    }
                    "cancelAllAlarms" -> {
                        cancelAllAlarms()
                        result.success(null)
                    }
                    "checkAzanTrigger" -> {
                        result.success(isAzanTriggered)
                        isAzanTriggered = false // Reset after checking
                    }
                    "setAzanVolume" -> {
                        val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
                        val prefs = getSharedPreferences("salaty_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putFloat("azan_volume", volume).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun stopAzan() {
        val serviceIntent = Intent(this, AzanService::class.java)
        stopService(serviceIntent)
    }

    private fun cancelAllAlarms() {
        // Alarms are identified by time.toInt(). Without storage, we can't easily cancel all.
        // FLAG_UPDATE_CURRENT in scheduleAzan handles single-alarm replacement.
    }

    private fun scheduleAzan(time: Long, sound: String, volume: Float, prayerName: String) {
        val intent = Intent(this, AzanReceiver::class.java).apply {
            putExtra("sound", sound)
            putExtra("volume", volume)
            putExtra("prayerName", prayerName)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            time.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                time,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                time,
                pendingIntent
            )
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        
        // Ensure the app can wake up the screen and show above the lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("full_screen_azan", false) == true) {
            isAzanTriggered = true
        }
    }
}
