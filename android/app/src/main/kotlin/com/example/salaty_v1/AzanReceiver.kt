package com.example.salaty_v1

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AzanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, AzanService::class.java)
        serviceIntent.putExtra("sound", intent.getStringExtra("sound"))

        context.startForegroundService(serviceIntent)
    }
}
