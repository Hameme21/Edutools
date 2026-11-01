package com.example.educal

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object ReminderScheduler {
    private const val PREFS = "edutools_reminders"
    private val channels = mapOf("classes" to "Classes", "events" to "Events", "semester_fees" to "Semester fees", "exams" to "Exams", "holidays" to "Holidays")
    fun channels(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) channels.forEach { (id, name) ->
            manager.createNotificationChannel(NotificationChannel(id, name, NotificationManager.IMPORTANCE_DEFAULT))
        }
    }
    private fun pending(context: Context) = PendingIntent.getBroadcast(context, 7101,
        Intent(context, ReminderReceiver::class.java).setAction("com.example.educal.REMINDER"),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun replace(context: Context, items: JSONArray) {
        context.getSharedPreferences(PREFS, 0).edit().putString("items", items.toString()).apply()
        scheduleNext(context)
    }
    fun scheduleNext(context: Context) {
        channels(context)
        val alarms = context.getSystemService(AlarmManager::class.java)
        alarms.cancel(pending(context))
        val items = JSONArray(context.getSharedPreferences(PREFS, 0).getString("items", "[]"))
        var next = Long.MAX_VALUE
        for (i in 0 until items.length()) {
            val at = items.getJSONObject(i).optLong("at")
            if (at > System.currentTimeMillis() && at < next) next = at
        }
        if (next == Long.MAX_VALUE) return
        if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pending(context))
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pending(context))
        }
    }
    fun fire(context: Context) {
        channels(context)
        val prefs = context.getSharedPreferences(PREFS, 0)
        val items = JSONArray(prefs.getString("items", "[]"))
        val remaining = JSONArray()
        val now = System.currentTimeMillis()
        val allowed = Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        for (i in 0 until items.length()) {
            val item = items.getJSONObject(i)
            if (item.optLong("at") > now) { remaining.put(item); continue }
            if (!allowed || now - item.optLong("at") > 15 * 60 * 1000) continue
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: continue
            val tap = PendingIntent.getActivity(context, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val channel = item.optString("channel", "events")
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channel) else Notification.Builder(context)
            val notification = builder.setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(item.optString("title")).setContentText(item.optString("body"))
                .setStyle(Notification.BigTextStyle().bigText(item.optString("body")))
                .setContentIntent(tap).setAutoCancel(true).setCategory(Notification.CATEGORY_REMINDER).build()
            context.getSystemService(NotificationManager::class.java).notify(item.optString("id").hashCode(), notification)
        }
        prefs.edit().putString("items", remaining.toString()).apply()
        scheduleNext(context)
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.educal.REMINDER") ReminderScheduler.fire(context)
        else ReminderScheduler.scheduleNext(context)
    }
}
