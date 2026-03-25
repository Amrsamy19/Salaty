package com.example.salaty_v1

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AzanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync() // Tell Android "I need more time"
        
        try {
            val serviceIntent = Intent(context, AzanService::class.java).apply {
                putExtra("sound", intent.getStringExtra("sound"))
                putExtra("volume", intent.getFloatExtra("volume", 1.0f))
                putExtra("prayerName", intent.getStringExtra("prayerName"))
            }

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } finally {
            pendingResult.finish()
        }
    }
}
