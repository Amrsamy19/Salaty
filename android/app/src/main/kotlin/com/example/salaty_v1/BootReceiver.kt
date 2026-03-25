package com.example.salaty_v1

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject
import kotlin.math.abs

class BootReceiver : BroadcastReceiver() {
    private fun buildRequestCode(timeMs: Long, prayerName: String): Int {
        val seconds = timeMs / 1000L
        val mixed = seconds xor prayerName.hashCode().toLong()
        val folded = (mixed xor (mixed ushr 32)).toInt()
        val positive = abs(folded.toLong()).toInt()
        return if (positive == 0) 1 else positive
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {

            Log.d("BootReceiver", "Rescheduling alarms after boot/update")

            // Re-read saved alarms from SharedPreferences and reschedule
            val prefs = context.getSharedPreferences("salaty_prefs", Context.MODE_PRIVATE)
            val savedAlarms = prefs.getStringSet("saved_alarms_json", emptySet()) ?: return

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            for (alarmJson in savedAlarms) {
                try {
                    val obj = JSONObject(alarmJson)
                    val time = obj.getLong("time")
                    val sound = obj.getString("sound")
                    val volume = obj.getDouble("volume").toFloat()
                    val prayerName = obj.getString("prayerName")

                    if (time < System.currentTimeMillis()) continue // Skip past alarms

                    val alarmIntent = Intent(context, AzanReceiver::class.java).apply {
                        putExtra("sound", sound)
                        putExtra("volume", volume)
                        putExtra("prayerName", prayerName)
                    }
                    val requestCode = if (obj.has("requestCode")) obj.getInt("requestCode") else buildRequestCode(time, prayerName)
                    val pendingIntent = PendingIntent.getBroadcast(
                        context, requestCode, alarmIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setExactAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP, time, pendingIntent
                            )
                        } else {
                            alarmManager.setExact(
                                AlarmManager.RTC_WAKEUP, time, pendingIntent
                            )
                        }
                    } catch (se: SecurityException) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, pendingIntent)
                        } else {
                            alarmManager.set(AlarmManager.RTC_WAKEUP, time, pendingIntent)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("BootReceiver", "Failed to reschedule alarm: $e")
                }
            }
        }
    }
}
