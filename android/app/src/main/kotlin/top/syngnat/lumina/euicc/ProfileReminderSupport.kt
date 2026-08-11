package top.syngnat.lumina.euicc

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.provider.Settings
import android.util.Log

internal data class StoredProfileReminder(
    val id: String,
    val profileName: String,
    val triggerAtMillis: Long,
    val exact: Boolean,
)

internal class ProfileReminderSupport(private val context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    private val alarmManager = context.getSystemService(AlarmManager::class.java)

    fun get(iccid: String): Map<String, Any>? = getById(stableProfileReminderId(iccid))?.toMap()

    fun schedule(iccid: String, profileName: String, triggerAtMillis: Long): Map<String, Any> {
        val validated = validateProfileReminderRequest(iccid, profileName, triggerAtMillis)
        val reminder = scheduleRecord(
            StoredProfileReminder(
                id = validated.id,
                profileName = validated.profileName,
                triggerAtMillis = validated.triggerAtMillis,
                exact = false,
            ),
        )
        return reminder.toMap()
    }

    fun cancel(iccid: String) {
        remove(stableProfileReminderId(iccid), cancelAlarm = true)
    }

    fun rename(iccid: String, profileName: String) {
        val id = stableProfileReminderId(iccid)
        val current = getById(id) ?: return
        val name = profileName.trim()
        require(name.isNotEmpty() && name.length <= 128) { "Profile name is invalid" }
        persist(current.copy(profileName = name))
    }

    fun canPostNotifications(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    fun canScheduleExactAlarms(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()

    fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        context.startActivity(
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
    }

    fun restoreAll() {
        val now = System.currentTimeMillis()
        for (id in reminderIds()) {
            val reminder = getById(id)
            if (reminder == null) {
                remove(id, cancelAlarm = false)
                continue
            }
            if (reminder.triggerAtMillis <= now) {
                if (canPostNotifications()) {
                    if (ProfileReminderNotifier.show(context, reminder)) {
                        remove(id, cancelAlarm = false)
                    }
                }
            } else {
                try {
                    scheduleRecord(reminder)
                } catch (error: Exception) {
                    Log.w(TAG, "Unable to restore reminder; type=${error.javaClass.simpleName}")
                }
            }
        }
    }

    fun deliver(id: String) {
        val reminder = getById(id) ?: return
        if (!canPostNotifications()) return
        if (ProfileReminderNotifier.show(context, reminder)) {
            remove(id, cancelAlarm = false)
        }
    }

    private fun scheduleRecord(reminder: StoredProfileReminder): StoredProfileReminder {
        ProfileReminderNotifier.ensureChannel(context)
        val exact = canScheduleExactAlarms()
        val alarmIntent = checkNotNull(
            alarmPendingIntent(reminder.id, PendingIntent.FLAG_UPDATE_CURRENT),
        ) { "Unable to create reminder alarm" }
        val scheduledExactly = if (exact) {
            try {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(
                        reminder.triggerAtMillis,
                        profileReminderContentIntent(context, reminder.notificationId),
                    ),
                    alarmIntent,
                )
                true
            } catch (_: SecurityException) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    reminder.triggerAtMillis,
                    alarmIntent,
                )
                false
            }
        } else {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                reminder.triggerAtMillis,
                alarmIntent,
            )
            false
        }
        return reminder.copy(exact = scheduledExactly).also(::persist)
    }

    private fun persist(reminder: StoredProfileReminder) {
        val ids = reminderIds().toMutableSet().apply { add(reminder.id) }
        preferences.edit()
            .putStringSet(KEY_IDS, ids)
            .putLong(keyAt(reminder.id), reminder.triggerAtMillis)
            .putString(keyName(reminder.id), reminder.profileName)
            .putBoolean(keyExact(reminder.id), reminder.exact)
            .apply()
    }

    private fun getById(id: String): StoredProfileReminder? {
        if (!preferences.contains(keyAt(id))) return null
        val name = preferences.getString(keyName(id), null)?.takeIf(String::isNotBlank)
            ?: return null
        val triggerAtMillis = preferences.getLong(keyAt(id), 0L)
        if (triggerAtMillis <= 0L) return null
        return StoredProfileReminder(
            id = id,
            profileName = name,
            triggerAtMillis = triggerAtMillis,
            exact = preferences.getBoolean(keyExact(id), false),
        )
    }

    private fun remove(id: String, cancelAlarm: Boolean) {
        if (cancelAlarm) {
            alarmPendingIntent(id, PendingIntent.FLAG_NO_CREATE)?.let(alarmManager::cancel)
        }
        val ids = reminderIds().toMutableSet().apply { remove(id) }
        preferences.edit()
            .putStringSet(KEY_IDS, ids)
            .remove(keyAt(id))
            .remove(keyName(id))
            .remove(keyExact(id))
            .apply()
    }

    private fun reminderIds(): Set<String> = preferences.getStringSet(KEY_IDS, emptySet())
        ?.filterTo(mutableSetOf()) { it.matches(ID_PATTERN) }
        ?: emptySet()

    private fun alarmPendingIntent(id: String, creationFlag: Int): PendingIntent? {
        val intent = Intent(context, ProfileReminderReceiver::class.java).apply {
            action = ACTION_DELIVER
            data = Uri.Builder()
                .scheme(context.packageName)
                .authority("profile-reminder")
                .appendPath(id)
                .build()
            putExtra(EXTRA_ID, id)
        }
        return PendingIntent.getBroadcast(
            context,
            id.substring(0, 8).toLong(16).toInt(),
            intent,
            creationFlag or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun StoredProfileReminder.toMap(): Map<String, Any> = mapOf(
        "triggerAtMillis" to triggerAtMillis,
        "exact" to exact,
        "notificationPermissionGranted" to canPostNotifications(),
        "exactAlarmPermissionGranted" to canScheduleExactAlarms(),
    )

    companion object {
        private const val PREFERENCES = "profile_reminders"
        private const val TAG = "LuminaProfileReminder"
        private const val KEY_IDS = "reminder_ids"
        internal const val ACTION_DELIVER = "top.syngnat.lumina.euicc.PROFILE_REMINDER"
        internal const val EXTRA_ID = "reminder_id"
        private val ID_PATTERN = Regex("[0-9a-f]{64}")

        private fun keyAt(id: String) = "at:$id"
        private fun keyName(id: String) = "name:$id"
        private fun keyExact(id: String) = "exact:$id"
    }
}

private val StoredProfileReminder.notificationId: Int
    get() = id.substring(0, 8).toLong(16).toInt()

private fun profileReminderContentIntent(context: Context, requestCode: Int): PendingIntent =
    PendingIntent.getActivity(
        context,
        requestCode,
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

class ProfileReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ProfileReminderSupport.ACTION_DELIVER) return
        val id = intent.getStringExtra(ProfileReminderSupport.EXTRA_ID)
            ?.takeIf { it.matches(Regex("[0-9a-f]{64}")) }
            ?: return
        ProfileReminderSupport(context.applicationContext).deliver(id)
    }
}

class ProfileReminderRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (
            intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED
        ) {
            ProfileReminderSupport(context.applicationContext).restoreAll()
        }
    }
}

private object ProfileReminderNotifier {
    // Notification-channel behavior is immutable after first creation. A new ID
    // upgrades existing installs from the old silent reminder channel.
    private const val CHANNEL_ID = "profile_reminder_alarms_v2"
    private val VIBRATION_PATTERN = longArrayOf(0, 700, 250, 700, 250, 1000)

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.profile_reminder_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.profile_reminder_channel_description)
                setSound(alarmSound, audioAttributes)
                enableVibration(true)
                vibrationPattern = VIBRATION_PATTERN
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            },
        )
    }

    fun show(context: Context, reminder: StoredProfileReminder): Boolean = try {
        val manager = context.getSystemService(NotificationManager::class.java)
        ensureChannel(context)
        val contentIntent = profileReminderContentIntent(context, reminder.notificationId)
        val body = context.getString(
            R.string.profile_reminder_notification_body,
            reminder.profileName,
        )
        val notification = android.app.Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_profile_reminder)
            .setContentTitle(context.getString(R.string.profile_reminder_notification_title))
            .setContentText(body)
            .setStyle(android.app.Notification.BigTextStyle().bigText(body))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .build()
        manager.notify(reminder.notificationId, notification)
        true
    } catch (error: Exception) {
        Log.w(
            "LuminaProfileReminder",
            "Unable to show reminder; type=${error.javaClass.simpleName}",
        )
        false
    }
}
