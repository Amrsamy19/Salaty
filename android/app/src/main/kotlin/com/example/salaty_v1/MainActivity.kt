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
import org.json.JSONObject

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
                    "stopAzan" -> {
                        stopAzan()
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
        val prefs = getSharedPreferences("salaty_prefs", Context.MODE_PRIVATE)
        val alarmIds = prefs.getStringSet("alarm_ids", emptySet()) ?: emptySet()
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        for (idStr in alarmIds) {
            val requestCode = idStr.toIntOrNull() ?: continue
            val intent = Intent(this, AzanReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this, requestCode, intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntent?.let { alarmManager.cancel(it) }
        }

        prefs.edit().remove("alarm_ids").remove("saved_alarms_json").apply()
    }

    private fun scheduleAzan(time: Long, sound: String, volume: Float, prayerName: String) {
        val requestCode = time.toInt()
        val intent = Intent(this, AzanReceiver::class.java).apply {
            putExtra("sound", sound)
            putExtra("volume", volume)
            putExtra("prayerName", prayerName)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
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

        // Save for cancellation and boot recovery
        val prefs = getSharedPreferences("salaty_prefs", Context.MODE_PRIVATE)
        
        // 1. Save ID for cancellation
        val existingIds = prefs.getStringSet("alarm_ids", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        existingIds.add(requestCode.toString())
        
        // 2. Save full data for BootReceiver
        val alarmData = JSONObject().apply {
            put("time", time)
            put("sound", sound)
            put("volume", volume.toDouble())
            put("prayerName", prayerName)
        }.toString()
        
        val existingAlarms = prefs.getStringSet("saved_alarms_json", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        existingAlarms.add(alarmData)
        
        prefs.edit()
            .putStringSet("alarm_ids", existingIds)
            .putStringSet("saved_alarms_json", existingAlarms)
            .apply()
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
