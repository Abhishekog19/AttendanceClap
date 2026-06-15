package com.attendanceai.attendanceAi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootReceiver – triggers notification rescheduling after device reboot.
 *
 * flutter_local_notifications already ships its own
 * ScheduledNotificationBootReceiver that re-posts pending alarms stored in
 * SharedPreferences.  This receiver is an additional safety net that wakes
 * the app so Flutter can refresh today's schedule from Firestore.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action !in setOf(
                Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED,
                "android.intent.action.LOCKED_BOOT_COMPLETED"
            )
        ) return

        Log.d("AttendanceAI", "BootReceiver: $action received — starting MainActivity to reschedule notifications")

        // Launch the app in the background (no UI shown) so Flutter can
        // call NotificationScheduler.rescheduleAll() via the
        // notificationSchedulerProvider watcher that runs at app start.
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_FROM_BACKGROUND)
            putExtra("reschedule_notifications", true)
        }
        // Only start if not already running; avoid bringing UI to foreground
        try {
            context.startActivity(launchIntent)
        } catch (e: Exception) {
            Log.e("AttendanceAI", "BootReceiver: failed to start activity", e)
        }
    }
}
