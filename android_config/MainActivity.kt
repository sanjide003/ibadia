package com.quranapp.malayalam.quran_malayalam_app

import android.Manifest
import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.view.WindowManager
import android.widget.RemoteViews
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val UPDATER_CHANNEL = "com.quranapp.malayalam/app_updater"
        private const val ALARM_CHANNEL = "com.quranapp.malayalam/prayer_alarm"
        private const val REQ_POST_NOTIF = 4102
    }

    private var alarmChannel: MethodChannel? = null
    private var pendingLaunchAction: Map<String, Any>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            km?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        PrayerAlarmController.ensureNotificationChannel(this)
        PrayerAlarmController.ensureKahfNotificationChannel(this)
        PrayerAlarmController.reconcileActiveDndState(applicationContext)
        pendingLaunchAction = extractLaunchAction(intent)
    }

    override fun onResume() {
        super.onResume()
        PrayerAlarmController.reconcileActiveDndState(applicationContext)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        notifyFlutterActiveAlarm()
        val action = extractLaunchAction(intent)
        if (action != null) {
            if (alarmChannel != null) {
                alarmChannel?.invokeMethod("onLaunchAction", action)
            } else {
                pendingLaunchAction = action
            }
        }
    }

    private fun extractLaunchAction(intent: Intent?): Map<String, Any>? {
        if (intent == null) return null
        val surah = intent.getIntExtra("openSurahNumber", 0)
        val openPrayer = intent.getBooleanExtra("openPrayerTab", false)
        if (surah <= 0 && !openPrayer) return null
        intent.removeExtra("openSurahNumber")
        intent.removeExtra("openPrayerTab")
        val map = mutableMapOf<String, Any>()
        if (surah > 0) map["openSurah"] = surah
        if (openPrayer) map["openPrayerTab"] = true
        return map
    }

    private fun notifyFlutterActiveAlarm() {
        val active = PrayerAlarmController.getActiveRingingInfo(this) ?: return
        alarmChannel?.invokeMethod("onAlarmRinging", active)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppVersionInfo" -> {
                        try {
                            val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getPackageInfo(
                                    packageName,
                                    PackageManager.PackageInfoFlags.of(0)
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, 0)
                            }
                            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                pkgInfo.longVersionCode
                            } else {
                                @Suppress("DEPRECATION")
                                pkgInfo.versionCode.toLong()
                            }
                            result.success(
                                mapOf(
                                    "versionName" to (pkgInfo.versionName ?: "1.0.0"),
                                    "versionCode" to versionCode
                                )
                            )
                        } catch (e: Exception) {
                            result.error("VERSION_ERROR", e.message, null)
                        }
                    }

                    "getUpdateCacheDir" -> {
                        val dir = File(cacheDir, "updates")
                        if (!dir.exists()) {
                            dir.mkdirs()
                        }
                        result.success(dir.absolutePath)
                    }

                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath.isNullOrBlank()) {
                            result.error("INVALID_PATH", "APK path is empty", null)
                            return@setMethodCallHandler
                        }
                        val apkFile = File(filePath)
                        if (!apkFile.exists()) {
                            result.error("MISSING_FILE", "APK file not found", null)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            !packageManager.canRequestPackageInstalls()
                        ) {
                            val settingsIntent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(settingsIntent)
                            result.success("permission_required")
                            return@setMethodCallHandler
                        }

                        try {
                            val contentUri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                apkFile
                            )
                            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(
                                    contentUri,
                                    "application/vnd.android.package-archive"
                                )
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(installIntent)
                            result.success("started")
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    }

                    "openExternalUrl" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
        alarmChannel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAdhanCacheDir" -> {
                    val dir = File(cacheDir, "adhans")
                    if (!dir.exists()) {
                        dir.mkdirs()
                    }
                    result.success(dir.absolutePath)
                }

                "requestAlarmPermissions" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                REQ_POST_NOTIF
                            )
                        }
                    }
                    result.success(true)
                }

                "schedulePrayerAlarms" -> {
                    try {
                        val rawList = call.argument<List<Map<String, Any?>>>("alarms") ?: emptyList()
                        val soundType = call.argument<String>("soundType") ?: "adhan_alafasy"
                        val soundFilePath = call.argument<String>("soundFilePath")
                        val volume = (call.argument<Number>("volume")?.toDouble() ?: 0.85).toFloat()
                        val vibrate = call.argument<Boolean>("vibrate") ?: true

                        PrayerAlarmController.saveAndScheduleAll(
                            context = applicationContext,
                            alarms = rawList,
                            soundType = soundType,
                            soundFilePath = soundFilePath,
                            volume = volume,
                            vibrate = vibrate
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }

                "previewAlarmSound" -> {
                    val soundType = call.argument<String>("soundType") ?: "adhan_alafasy"
                    val soundFilePath = call.argument<String>("soundFilePath")
                    val volume = (call.argument<Number>("volume")?.toDouble() ?: 0.85).toFloat()
                    val vibrate = call.argument<Boolean>("vibrate") ?: false
                    PrayerAlarmController.startSoundAndVibration(
                        context = applicationContext,
                        soundType = soundType,
                        soundFilePath = soundFilePath,
                        volume = volume,
                        vibrate = vibrate,
                        loop = false
                    )
                    result.success(true)
                }

                "stopAlarmSound" -> {
                    PrayerAlarmController.stopSoundAndVibration()
                    result.success(true)
                }

                "dismissActiveAlarm" -> {
                    val dateKey = call.argument<String>("dateKey")
                    val prayerKey = call.argument<String>("prayerKey")
                    PrayerAlarmController.dismissActive(applicationContext, dateKey, prayerKey)
                    result.success(true)
                }

                "getActiveRingingAlarm" -> {
                    result.success(PrayerAlarmController.getActiveRingingInfo(applicationContext))
                }

                "getDismissedKeysForDate" -> {
                    val dateKey = call.argument<String>("dateKey") ?: PrayerAlarmController.todayDateKey()
                    result.success(PrayerAlarmController.getDismissedKeysForDate(applicationContext, dateKey))
                }

                "scheduleKahfReminders" -> {
                    try {
                        val thuEnabled = call.argument<Boolean>("thuEnabled") ?: true
                        val friEnabled = call.argument<Boolean>("friEnabled") ?: true
                        val thuHour = call.argument<Number>("thuHour")?.toInt() ?: 19
                        val thuMinute = call.argument<Number>("thuMinute")?.toInt() ?: 0
                        val friHour = call.argument<Number>("friHour")?.toInt() ?: 8
                        val friMinute = call.argument<Number>("friMinute")?.toInt() ?: 0
                        val title = call.argument<String>("title") ?: "Surah Al-Kahf Reminder"
                        val body = call.argument<String>("body") ?: "Tap to read Surah Al-Kahf"
                        PrayerAlarmController.saveAndScheduleKahf(
                            context = applicationContext,
                            thuEnabled = thuEnabled,
                            friEnabled = friEnabled,
                            thuHour = thuHour,
                            thuMinute = thuMinute,
                            friHour = friHour,
                            friMinute = friMinute,
                            title = title,
                            body = body
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("KAHF_SCHEDULE_ERROR", e.message, null)
                    }
                }

                "testKahfNotification" -> {
                    val title = call.argument<String>("title") ?: "Surah Al-Kahf Reminder"
                    val body = call.argument<String>("body") ?: "Tap to read Surah Al-Kahf"
                    PrayerAlarmController.showKahfNotification(applicationContext, title, body)
                    result.success(true)
                }

                "getInitialLaunchAction" -> {
                    val act = pendingLaunchAction ?: extractLaunchAction(intent)
                    pendingLaunchAction = null
                    result.success(act)
                }

                "isDndPolicyAccessGranted" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        nm.isNotificationPolicyAccessGranted
                    } else {
                        true
                    }
                    result.success(granted)
                }

                "openDndPolicySettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val dndIntent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(dndIntent)
                        }
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }

                "schedulePrayerDndWindows" -> {
                    try {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val windows = call.argument<List<Map<String, Any?>>>("windows") ?: emptyList()
                        PrayerAlarmController.saveAndScheduleDnd(
                            context = applicationContext,
                            enabled = enabled,
                            windows = windows
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DND_SCHEDULE_ERROR", e.message, null)
                    }
                }

                "restoreNormalRingerNow" -> {
                    PrayerAlarmController.restoreAndSuppressCurrentWindow(applicationContext)
                    result.success(true)
                }

                "getAutoSilentStatus" -> {
                    PrayerAlarmController.reconcileActiveDndState(applicationContext)
                    result.success(PrayerAlarmController.isDndSessionActive(applicationContext))
                }

                "canScheduleExactAlarms" -> {
                    val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        am.canScheduleExactAlarms()
                    } else {
                        true
                    }
                    result.success(canExact)
                }

                "openExactAlarmSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val exactIntent = Intent(
                                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(exactIntent)
                        }
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}

object PrayerAlarmController {
    private const val PREFS_NAME = "prayer_alarm_native_prefs"
    private const val KEY_SCHEDULE_JSON = "scheduled_alarms_json"
    private const val KEY_SOUND_TYPE = "sound_type"
    private const val KEY_SOUND_FILE = "sound_file_path"
    private const val KEY_VOLUME = "sound_volume"
    private const val KEY_VIBRATE = "sound_vibrate"
    private const val KEY_ACTIVE_PRAYER = "active_ringing_prayer"
    private const val KEY_ACTIVE_TITLE = "active_ringing_title"
    private const val KEY_ACTIVE_TIME = "active_ringing_time"
    private const val KEY_ACTIVE_DATE = "active_ringing_date"
    private const val KEY_DISMISSED_SET = "dismissed_today_set"
    private const val CHANNEL_ID = "prayer_alarm_channel_v1"
    private const val CHANNEL_NAME = "Prayer Time Alarms"
    private const val ALARM_NOTIFICATION_ID = 7701

    private const val KAHF_CHANNEL_ID = "kahf_reminder_channel_v1"
    private const val KAHF_CHANNEL_NAME = "Surah Al-Kahf Reminders"
    private const val KAHF_NOTIFICATION_ID = 7702
    private const val KEY_KAHF_THU_ENABLED = "kahf_thu_enabled"
    private const val KEY_KAHF_FRI_ENABLED = "kahf_fri_enabled"
    private const val KEY_KAHF_THU_HOUR = "kahf_thu_hour"
    private const val KEY_KAHF_THU_MIN = "kahf_thu_min"
    private const val KEY_KAHF_FRI_HOUR = "kahf_fri_hour"
    private const val KEY_KAHF_FRI_MIN = "kahf_fri_min"
    private const val KEY_KAHF_TITLE = "kahf_notif_title"
    private const val KEY_KAHF_BODY = "kahf_notif_body"
    private const val REQ_KAHF_THU = 8201
    private const val REQ_KAHF_FRI = 8202

    private const val DND_CHANNEL_ID = "prayer_dnd_status_v1"
    private const val DND_CHANNEL_NAME = "Prayer Auto-Silent Status"
    private const val DND_NOTIFICATION_ID = 7703
    private const val KEY_DND_ENABLED = "dnd_auto_enabled"
    private const val KEY_DND_WINDOWS_JSON = "dnd_windows_json"
    private const val KEY_DND_ACTIVE = "dnd_session_active"
    private const val KEY_DND_ACTIVE_END_MS = "dnd_session_active_end_ms"
    private const val KEY_DND_SUPPRESSED_END_MS = "dnd_suppressed_end_ms"
    private const val KEY_DND_PREV_FILTER = "dnd_prev_filter"
    private const val KEY_DND_PREV_RINGER = "dnd_prev_ringer"
    private val DND_START_CODES = mapOf(
        "fajr" to 8301,
        "dhuhr" to 8302,
        "asr" to 8303,
        "maghrib" to 8304,
        "isha" to 8305
    )
    private val DND_END_CODES = mapOf(
        "fajr" to 8401,
        "dhuhr" to 8402,
        "asr" to 8403,
        "maghrib" to 8404,
        "isha" to 8405
    )

    private val PRAYER_REQUEST_CODES = mapOf(
        "fajr" to 8101,
        "dhuhr" to 8102,
        "asr" to 8103,
        "maghrib" to 8104,
        "isha" to 8105
    )

    private var mediaPlayer: MediaPlayer? = null
    private var activeVibrator: Vibrator? = null

    fun todayDateKey(millis: Long = System.currentTimeMillis()): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(millis))
    }

    fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = nm.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val ch = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Exact Adhan and Iqamah prayer reminder alarms"
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    enableVibration(false)
                    setSound(null, null) // Sound managed with custom volume/Adhan via MediaPlayer
                    setBypassDnd(true)
                }
                nm.createNotificationChannel(ch)
            }
        }
    }

    fun saveAndScheduleAll(
        context: Context,
        alarms: List<Map<String, Any?>>,
        soundType: String,
        soundFilePath: String?,
        volume: Float,
        vibrate: Boolean
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val arr = JSONArray()
        for (item in alarms) {
            val obj = JSONObject()
            obj.put("prayerKey", item["prayerKey"] ?: "")
            obj.put("title", item["title"] ?: "")
            obj.put("subtitle", item["subtitle"] ?: "")
            obj.put("timeLabel", item["timeLabel"] ?: "")
            obj.put("triggerAtMillis", (item["triggerAtMillis"] as? Number)?.toLong() ?: 0L)
            arr.put(obj)
        }
        prefs.edit()
            .putString(KEY_SCHEDULE_JSON, arr.toString())
            .putString(KEY_SOUND_TYPE, soundType)
            .putString(KEY_SOUND_FILE, soundFilePath)
            .putFloat(KEY_VOLUME, volume.coerceIn(0.05f, 1.0f))
            .putBoolean(KEY_VIBRATE, vibrate)
            .apply()

        rescheduleStoredAlarms(context)
    }

    fun rescheduleStoredAlarms(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Cancel all 5 existing pending intents first
        for ((key, reqCode) in PRAYER_REQUEST_CODES) {
            val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                putExtra("prayerKey", key)
            }
            val pi = PendingIntent.getBroadcast(
                context,
                reqCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pi)
        }

        val raw = prefs.getString(KEY_SCHEDULE_JSON, null) ?: return
        val arr = try {
            JSONArray(raw)
        } catch (_: Exception) {
            return
        }

        val now = System.currentTimeMillis()
        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            val prayerKey = obj.optString("prayerKey", "")
            val reqCode = PRAYER_REQUEST_CODES[prayerKey] ?: continue
            var triggerAt = obj.optLong("triggerAtMillis", 0L)
            if (triggerAt <= 0L) continue

            // If today's alarm is already passed or dismissed for its date, push +24h cleanly
            val triggerDate = todayDateKey(triggerAt)
            val dismissedSet = prefs.getStringSet(KEY_DISMISSED_SET, emptySet()) ?: emptySet()
            if (triggerAt <= now + 1500L || dismissedSet.contains("$triggerDate|$prayerKey")) {
                triggerAt += 24L * 60L * 60L * 1000L
                while (triggerAt <= now + 1500L) {
                    triggerAt += 24L * 60L * 60L * 1000L
                }
            }

            val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                putExtra("prayerKey", prayerKey)
                putExtra("title", obj.optString("title", prayerKey))
                putExtra("subtitle", obj.optString("subtitle", ""))
                putExtra("timeLabel", obj.optString("timeLabel", ""))
                putExtra("triggerDate", todayDateKey(triggerAt))
            }
            val pi = PendingIntent.getBroadcast(
                context,
                reqCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            val showPi = PendingIntent.getActivity(
                context,
                reqCode + 50,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            try {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAt, showPi),
                    pi
                )
            } catch (_: SecurityException) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }
    }

    fun handleAlarmFired(context: Context, intent: Intent) {
        val prayerKey = intent.getStringExtra("prayerKey") ?: return
        val title = intent.getStringExtra("title") ?: prayerKey
        val subtitle = intent.getStringExtra("subtitle") ?: ""
        val timeLabel = intent.getStringExtra("timeLabel") ?: ""
        val triggerDate = intent.getStringExtra("triggerDate") ?: todayDateKey()

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val dismissedSet = prefs.getStringSet(KEY_DISMISSED_SET, emptySet()) ?: emptySet()
        if (dismissedSet.contains("$triggerDate|$prayerKey")) {
            rescheduleStoredAlarms(context)
            return
        }

        // Acquire short wake lock so screen wakes cleanly
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val wl = pm.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                "quranapp:prayer_alarm"
            )
            wl.acquire(15_000L)
        } catch (_: Exception) {}

        prefs.edit()
            .putString(KEY_ACTIVE_PRAYER, prayerKey)
            .putString(KEY_ACTIVE_TITLE, title)
            .putString(KEY_ACTIVE_TIME, timeLabel)
            .putString(KEY_ACTIVE_DATE, triggerDate)
            .apply()

        val soundType = prefs.getString(KEY_SOUND_TYPE, "adhan_alafasy") ?: "adhan_alafasy"
        val soundFilePath = prefs.getString(KEY_SOUND_FILE, null)
        val volume = prefs.getFloat(KEY_VOLUME, 0.85f)
        val vibrate = prefs.getBoolean(KEY_VIBRATE, true)

        startSoundAndVibration(
            context = context,
            soundType = soundType,
            soundFilePath = soundFilePath,
            volume = volume,
            vibrate = vibrate,
            loop = true
        )

        showLockScreenAlarmNotification(
            context = context,
            prayerKey = prayerKey,
            title = title,
            subtitle = subtitle,
            triggerDate = triggerDate
        )

        // Ensure next day's occurrence is queued automatically
        rescheduleStoredAlarms(context)
    }

    @Suppress("DEPRECATION")
    private fun showLockScreenAlarmNotification(
        context: Context,
        prayerKey: String,
        title: String,
        subtitle: String,
        triggerDate: String
    ) {
        ensureNotificationChannel(context)

        val fullScreenIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra("ringingPrayerKey", prayerKey)
            putExtra("ringingTitle", title)
            putExtra("ringingDate", triggerDate)
        }
        val fullScreenPi = PendingIntent.getActivity(
            context,
            9201,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val dismissIntent = Intent(context, PrayerDismissReceiver::class.java).apply {
            putExtra("prayerKey", prayerKey)
            putExtra("triggerDate", triggerDate)
        }
        val dismissPi = PendingIntent.getBroadcast(
            context,
            9202,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }

        // Only Dismiss action (Zero Snooze!)
        val dismissAction = Notification.Action.Builder(
            android.R.drawable.ic_menu_close_clear_cancel,
            "Dismiss",
            dismissPi
        ).build()

        val notif = builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(subtitle.ifEmpty { "Tap Dismiss to stop today's alarm" })
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenPi)
            .setFullScreenIntent(fullScreenPi, true)
            .addAction(dismissAction)
            .build()

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(ALARM_NOTIFICATION_ID, notif)
    }

    fun startSoundAndVibration(
        context: Context,
        soundType: String,
        soundFilePath: String?,
        volume: Float,
        vibrate: Boolean,
        loop: Boolean
    ) {
        stopSoundAndVibration()

        val safeVol = volume.coerceIn(0.05f, 1.0f)
        try {
            val mp = MediaPlayer()
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            mp.setAudioAttributes(attrs)

            var configured = false
            if (soundType != "alarm_tone" && !soundFilePath.isNullOrBlank()) {
                val f = File(soundFilePath)
                if (f.exists() && f.length() > 1024L) {
                    mp.setDataSource(f.absolutePath)
                    configured = true
                }
            }
            if (!configured) {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                mp.setDataSource(context, uri)
            }
            mp.isLooping = loop
            mp.setVolume(safeVol, safeVol)
            mp.setOnCompletionListener { player ->
                if (!loop) {
                    try {
                        player.release()
                    } catch (_: Exception) {}
                    if (mediaPlayer === player) {
                        mediaPlayer = null
                    }
                }
            }
            mp.prepare()
            mp.start()
            mediaPlayer = mp
        } catch (_: Exception) {
            try {
                val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                val mp = MediaPlayer()
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                mp.setDataSource(context, fallbackUri)
                mp.isLooping = loop
                mp.setVolume(safeVol, safeVol)
                mp.prepare()
                mp.start()
                mediaPlayer = mp
            } catch (_: Exception) {}
        }

        if (vibrate) {
            try {
                val vib: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                    vm?.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                }
                if (vib != null && vib.hasVibrator()) {
                    val pattern = longArrayOf(0L, 600L, 400L, 600L, 800L)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vib.vibrate(VibrationEffect.createWaveform(pattern, if (loop) 0 else -1))
                    } else {
                        @Suppress("DEPRECATION")
                        vib.vibrate(pattern, if (loop) 0 else -1)
                    }
                    activeVibrator = vib
                }
            } catch (_: Exception) {}
        }
    }

    fun stopSoundAndVibration() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {}
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {}
        mediaPlayer = null

        try {
            activeVibrator?.cancel()
        } catch (_: Exception) {}
        activeVibrator = null
    }

    fun dismissActive(context: Context, dateKey: String?, prayerKey: String?) {
        stopSoundAndVibration()
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(ALARM_NOTIFICATION_ID)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val activePrayer = prayerKey ?: prefs.getString(KEY_ACTIVE_PRAYER, null)
        val activeDate = dateKey ?: prefs.getString(KEY_ACTIVE_DATE, null) ?: todayDateKey()

        val updatedSet = (prefs.getStringSet(KEY_DISMISSED_SET, emptySet()) ?: emptySet())
            .filter { it.startsWith("$activeDate|") }
            .toMutableSet()
        if (!activePrayer.isNullOrBlank()) {
            updatedSet.add("$activeDate|$activePrayer")
        }

        prefs.edit()
            .remove(KEY_ACTIVE_PRAYER)
            .remove(KEY_ACTIVE_TITLE)
            .remove(KEY_ACTIVE_TIME)
            .remove(KEY_ACTIVE_DATE)
            .putStringSet(KEY_DISMISSED_SET, updatedSet)
            .apply()

        rescheduleStoredAlarms(context)
    }

    fun getActiveRingingInfo(context: Context): Map<String, String>? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = prefs.getString(KEY_ACTIVE_PRAYER, null) ?: return null
        val title = prefs.getString(KEY_ACTIVE_TITLE, key) ?: key
        val timeLabel = prefs.getString(KEY_ACTIVE_TIME, "") ?: ""
        val dateKey = prefs.getString(KEY_ACTIVE_DATE, todayDateKey()) ?: todayDateKey()
        return mapOf(
            "prayerKey" to key,
            "title" to title,
            "timeLabel" to timeLabel,
            "dateKey" to dateKey
        )
    }

    fun getDismissedKeysForDate(context: Context, dateKey: String): List<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val set = prefs.getStringSet(KEY_DISMISSED_SET, emptySet()) ?: emptySet()
        return set.filter { it.startsWith("$dateKey|") }
    }

    fun ensureKahfNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(KAHF_CHANNEL_ID) == null) {
                val ch = NotificationChannel(
                    KAHF_CHANNEL_ID,
                    KAHF_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Thursday evening and Friday morning Surah Al-Kahf reminders"
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    enableVibration(true)
                }
                nm.createNotificationChannel(ch)
            }
        }
    }

    private fun nextWeeklyOccurrenceMillis(dayOfWeek: Int, hour: Int, minute: Int): Long {
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply {
            set(Calendar.DAY_OF_WEEK, dayOfWeek)
            set(Calendar.HOUR_OF_DAY, hour.coerceIn(0, 23))
            set(Calendar.MINUTE, minute.coerceIn(0, 59))
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (target.timeInMillis <= now.timeInMillis + 2000L) {
            target.add(Calendar.WEEK_OF_YEAR, 1)
        }
        return target.timeInMillis
    }

    fun saveAndScheduleKahf(
        context: Context,
        thuEnabled: Boolean,
        friEnabled: Boolean,
        thuHour: Int,
        thuMinute: Int,
        friHour: Int,
        friMinute: Int,
        title: String,
        body: String
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_KAHF_THU_ENABLED, thuEnabled)
            .putBoolean(KEY_KAHF_FRI_ENABLED, friEnabled)
            .putInt(KEY_KAHF_THU_HOUR, thuHour)
            .putInt(KEY_KAHF_THU_MIN, thuMinute)
            .putInt(KEY_KAHF_FRI_HOUR, friHour)
            .putInt(KEY_KAHF_FRI_MIN, friMinute)
            .putString(KEY_KAHF_TITLE, title)
            .putString(KEY_KAHF_BODY, body)
            .apply()
        rescheduleKahfFromPrefs(context)
    }

    fun rescheduleKahfFromPrefs(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val thuEnabled = prefs.getBoolean(KEY_KAHF_THU_ENABLED, true)
        val friEnabled = prefs.getBoolean(KEY_KAHF_FRI_ENABLED, true)
        val thuHour = prefs.getInt(KEY_KAHF_THU_HOUR, 19)
        val thuMin = prefs.getInt(KEY_KAHF_THU_MIN, 0)
        val friHour = prefs.getInt(KEY_KAHF_FRI_HOUR, 8)
        val friMin = prefs.getInt(KEY_KAHF_FRI_MIN, 0)
        val title = prefs.getString(KEY_KAHF_TITLE, "Surah Al-Kahf Reminder") ?: "Surah Al-Kahf Reminder"
        val body = prefs.getString(KEY_KAHF_BODY, "Tap to read Surah Al-Kahf") ?: "Tap to read Surah Al-Kahf"

        fun scheduleSingle(slotTag: String, reqCode: Int, enabled: Boolean, dayOfWeek: Int, hour: Int, min: Int) {
            val intent = Intent(context, PrayerKahfReceiver::class.java).apply {
                putExtra("slotTag", slotTag)
                putExtra("title", title)
                putExtra("body", body)
            }
            val pi = PendingIntent.getBroadcast(
                context,
                reqCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pi)
            if (!enabled) return

            val triggerAt = nextWeeklyOccurrenceMillis(dayOfWeek, hour, min)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
            } catch (_: Exception) {}
        }

        scheduleSingle("thu", REQ_KAHF_THU, thuEnabled, Calendar.THURSDAY, thuHour, thuMin)
        scheduleSingle("fri", REQ_KAHF_FRI, friEnabled, Calendar.FRIDAY, friHour, friMin)
    }

    fun handleKahfFired(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = intent.getStringExtra("title")
            ?: prefs.getString(KEY_KAHF_TITLE, "Surah Al-Kahf Reminder")
            ?: "Surah Al-Kahf Reminder"
        val body = intent.getStringExtra("body")
            ?: prefs.getString(KEY_KAHF_BODY, "Tap to read Surah Al-Kahf")
            ?: "Tap to read Surah Al-Kahf"
        showKahfNotification(context, title, body)
        rescheduleKahfFromPrefs(context)
    }

    @Suppress("DEPRECATION")
    fun showKahfNotification(context: Context, title: String, body: String) {
        ensureKahfNotificationChannel(context)
        val tapIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra("openSurahNumber", 18)
        }
        val tapPi = PendingIntent.getActivity(
            context,
            9301,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, KAHF_CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }

        val notif = builder
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(tapPi)
            .build()

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(KAHF_NOTIFICATION_ID, notif)
    }

    private fun ensureDndNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(DND_CHANNEL_ID) == null) {
                val ch = NotificationChannel(
                    DND_CHANNEL_ID,
                    DND_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Shows when Prayer Auto-Silent (DND) is active"
                    setSound(null, null)
                }
                nm.createNotificationChannel(ch)
            }
        }
    }

    fun isDndSessionActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_DND_ACTIVE, false)
    }

    fun saveAndScheduleDnd(
        context: Context,
        enabled: Boolean,
        windows: List<Map<String, Any?>>
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val wasEnabled = prefs.getBoolean(KEY_DND_ENABLED, false)
        val prevJson = prefs.getString(KEY_DND_WINDOWS_JSON, null)
        val arr = JSONArray()
        for (w in windows) {
            val obj = JSONObject()
            obj.put("prayerKey", w["prayerKey"] ?: "")
            obj.put("prayerName", w["prayerName"] ?: "")
            obj.put("startMillis", (w["startMillis"] as? Number)?.toLong() ?: 0L)
            obj.put("endMillis", (w["endMillis"] as? Number)?.toLong() ?: 0L)
            obj.put("durationMinutes", (w["durationMinutes"] as? Number)?.toInt() ?: 15)
            obj.put("notifTitle", w["notifTitle"] ?: "Prayer Auto-Silent Active")
            obj.put("restoreBtn", w["restoreBtn"] ?: "Restore Sound")
            arr.put(obj)
        }
        val nextJson = arr.toString()
        val editor = prefs.edit()
            .putBoolean(KEY_DND_ENABLED, enabled)
            .putString(KEY_DND_WINDOWS_JSON, nextJson)
        if ((enabled && !wasEnabled) || (prevJson != null && prevJson != nextJson)) {
            editor.remove(KEY_DND_SUPPRESSED_END_MS)
        }
        editor.commit()
        if (!enabled && isDndSessionActive(context)) {
            restoreSavedDndFilter(context)
        }
        rescheduleStoredDndWindows(context)
    }

    private fun scheduleExactAlarm(
        context: Context,
        alarmManager: AlarmManager,
        triggerAt: Long,
        pi: PendingIntent,
        useAlarmClockFallback: Boolean = false,
        preferAlarmClock: Boolean = false,
        showReqCode: Int = 9601
    ) {
        fun buildShowIntent(): PendingIntent {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("openPrayerTab", true)
            }
            return PendingIntent.getActivity(
                context,
                showReqCode,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        try {
            if (preferAlarmClock && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAt, buildShowIntent()),
                    pi
                )
                return
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                if (useAlarmClockFallback) {
                    alarmManager.setAlarmClock(
                        AlarmManager.AlarmClockInfo(triggerAt, buildShowIntent()),
                        pi
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
                return
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        } catch (_: SecurityException) {
            try {
                if ((useAlarmClockFallback || preferAlarmClock) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    alarmManager.setAlarmClock(
                        AlarmManager.AlarmClockInfo(triggerAt, buildShowIntent()),
                        pi
                    )
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
            } catch (_: Exception) {}
        }
    }

    fun reconcileActiveDndState(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_DND_ACTIVE, false)) return

        val now = System.currentTimeMillis()
        val enabled = prefs.getBoolean(KEY_DND_ENABLED, false)
        if (!enabled) {
            restoreSavedDndFilter(context)
            return
        }

        val activeEndMs = prefs.getLong(KEY_DND_ACTIVE_END_MS, 0L)
        if (activeEndMs > 0L && now >= activeEndMs - 500L) {
            restoreSavedDndFilter(context)
            rescheduleStoredDndWindows(context)
            return
        }

        val raw = prefs.getString(KEY_DND_WINDOWS_JSON, null)
        if (raw.isNullOrBlank()) {
            restoreSavedDndFilter(context)
            return
        }
        val arr = try {
            JSONArray(raw)
        } catch (_: Exception) {
            restoreSavedDndFilter(context)
            return
        }

        val dayMs = 24L * 60L * 60L * 1000L
        var insideAnyWindow = false
        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            var startMs = obj.optLong("startMillis", 0L)
            var endMs = obj.optLong("endMillis", 0L)
            if (startMs <= 0L || endMs <= startMs) continue
            while (endMs <= now) {
                startMs += dayMs
                endMs += dayMs
            }
            if (startMs <= now + 1500L && now < endMs) {
                insideAnyWindow = true
                break
            }
        }
        if (!insideAnyWindow) {
            restoreSavedDndFilter(context)
        }
    }

    fun rescheduleStoredDndWindows(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        for ((key, code) in DND_START_CODES) {
            val pi = PendingIntent.getBroadcast(
                context,
                code,
                Intent(context, PrayerDndStartReceiver::class.java).apply { putExtra("prayerKey", key) },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pi)
        }
        for ((key, code) in DND_END_CODES) {
            val pi = PendingIntent.getBroadcast(
                context,
                code,
                Intent(context, PrayerDndEndReceiver::class.java).apply { putExtra("prayerKey", key) },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pi)
        }

        if (!prefs.getBoolean(KEY_DND_ENABLED, false)) {
            if (prefs.getBoolean(KEY_DND_ACTIVE, false)) {
                restoreSavedDndFilter(context)
            }
            return
        }
        val raw = prefs.getString(KEY_DND_WINDOWS_JSON, null)
        if (raw.isNullOrBlank()) {
            if (prefs.getBoolean(KEY_DND_ACTIVE, false)) {
                restoreSavedDndFilter(context)
            }
            return
        }
        val arr = try {
            JSONArray(raw)
        } catch (_: Exception) {
            return
        }

        val now = System.currentTimeMillis()
        val dayMs = 24L * 60L * 60L * 1000L
        val suppressedEndMs = prefs.getLong(KEY_DND_SUPPRESSED_END_MS, 0L)
        if (suppressedEndMs > 0L && now > suppressedEndMs + 10_000L) {
            prefs.edit().remove(KEY_DND_SUPPRESSED_END_MS).apply()
        }
        var anyInsideNow = false

        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            val prayerKey = obj.optString("prayerKey", "")
            val startCode = DND_START_CODES[prayerKey] ?: continue
            val endCode = DND_END_CODES[prayerKey] ?: continue

            var startMs = obj.optLong("startMillis", 0L)
            var endMs = obj.optLong("endMillis", 0L)
            if (startMs <= 0L || endMs <= startMs) continue

            // Roll past fully-expired or already-ended/suppressed windows (+24h)
            while (endMs <= now + 5000L || (suppressedEndMs > 0L && endMs <= suppressedEndMs + 5000L)) {
                startMs += dayMs
                endMs += dayMs
            }

            val title = obj.optString("notifTitle", "Ibadia Auto-Silent Active")
            val restoreBtn = obj.optString("restoreBtn", "Restore Sound")
            val durMin = obj.optInt("durationMinutes", 15)

            // If we are currently inside an active prayer Silent window, activate immediately
            // and schedule its Doze-exempt End alarm + tomorrow's Start alarm.
            val isCurrentlyInsideWindow = startMs <= now + 5000L && now < endMs
            if (isCurrentlyInsideWindow) {
                anyInsideNow = true
                if (!prefs.getBoolean(KEY_DND_ACTIVE, false)) {
                    activateSilentSessionNow(
                        context = context,
                        title = title,
                        restoreBtn = restoreBtn,
                        durMin = durMin,
                        endMillis = endMs
                    )
                } else {
                    prefs.edit().putLong(KEY_DND_ACTIVE_END_MS, endMs).apply()
                }
                startMs += dayMs
            }

            val startIntent = Intent(context, PrayerDndStartReceiver::class.java).apply {
                putExtra("prayerKey", prayerKey)
                putExtra("notifTitle", title)
                putExtra("restoreBtn", restoreBtn)
                putExtra("durationMinutes", durMin)
                putExtra("endMillis", if (isCurrentlyInsideWindow) endMs + dayMs else endMs)
            }
            val startPi = PendingIntent.getBroadcast(
                context,
                startCode,
                startIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val endIntent = Intent(context, PrayerDndEndReceiver::class.java).apply {
                putExtra("prayerKey", prayerKey)
                putExtra("endMillis", endMs)
            }
            val endPi = PendingIntent.getBroadcast(
                context,
                endCode,
                endIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            scheduleExactAlarm(
                context = context,
                alarmManager = alarmManager,
                triggerAt = startMs,
                pi = startPi,
                useAlarmClockFallback = false,
                preferAlarmClock = false,
                showReqCode = 9600 + startCode
            )
            // Use Doze-exempt setAlarmClock when DND is active (and as fallback) so DND always turns OFF on time
            scheduleExactAlarm(
                context = context,
                alarmManager = alarmManager,
                triggerAt = endMs,
                pi = endPi,
                useAlarmClockFallback = true,
                preferAlarmClock = isCurrentlyInsideWindow,
                showReqCode = 9600 + endCode
            )
        }

        if (!anyInsideNow && prefs.getBoolean(KEY_DND_ACTIVE, false)) {
            val activeEndMs = prefs.getLong(KEY_DND_ACTIVE_END_MS, 0L)
            if (activeEndMs <= 0L || now >= activeEndMs - 500L) {
                restoreSavedDndFilter(context)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun activateSilentSessionNow(
        context: Context,
        title: String,
        restoreBtn: String,
        durMin: Int,
        endMillis: Long = System.currentTimeMillis() + durMin * 60_000L
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (!nm.isNotificationPolicyAccessGranted) return

        val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_DND_ACTIVE, false)) {
            prefs.edit()
                .putInt(KEY_DND_PREV_FILTER, nm.currentInterruptionFilter)
                .putInt(KEY_DND_PREV_RINGER, am.ringerMode)
                .putBoolean(KEY_DND_ACTIVE, true)
                .putLong(KEY_DND_ACTIVE_END_MS, endMillis)
                .commit()
        } else {
            prefs.edit().putLong(KEY_DND_ACTIVE_END_MS, endMillis).commit()
        }

        // Apply Silent Mode: silence calls/messages/notifications via INTERRUPTION_FILTER_ALARMS
        // and explicitly force Android ringer to RINGER_MODE_SILENT while keeping alarms working.
        try {
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
        } catch (_: Exception) {}
        try {
            am.ringerMode = AudioManager.RINGER_MODE_SILENT
        } catch (_: Exception) {}

        ensureDndNotificationChannel(context)
        val restoreIntent = Intent(context, PrayerDndRestoreReceiver::class.java)
        val restorePi = PendingIntent.getBroadcast(
            context,
            9501,
            restoreIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, DND_CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }
        val notif = builder
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
            .setContentTitle(title)
            .setContentText("Silent Mode active ($durMin min)")
            .setOngoing(true)
            .addAction(Notification.Action.Builder(0, restoreBtn, restorePi).build())
            .build()
        nm.notify(DND_NOTIFICATION_ID, notif)
    }

    fun handleDndStartFired(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        var wl: PowerManager.WakeLock? = null
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ibadia:dnd_start")
            wl.acquire(10_000L)
        } catch (_: Exception) {}

        try {
            val title = intent.getStringExtra("notifTitle") ?: "Ibadia Auto-Silent Active"
            val restoreBtn = intent.getStringExtra("restoreBtn") ?: "Restore Sound"
            val durMin = intent.getIntExtra("durationMinutes", 15)
            val now = System.currentTimeMillis()
            val endMillis = intent.getLongExtra(
                "endMillis",
                now + durMin * 60_000L
            )

            if (now >= endMillis - 1000L) {
                if (isDndSessionActive(context)) {
                    restoreSavedDndFilter(context)
                }
                rescheduleStoredDndWindows(context)
                return
            }

            activateSilentSessionNow(
                context = context,
                title = title,
                restoreBtn = restoreBtn,
                durMin = durMin,
                endMillis = endMillis
            )
            rescheduleStoredDndWindows(context)
        } finally {
            try {
                if (wl?.isHeld == true) wl.release()
            } catch (_: Exception) {}
        }
    }

    fun handleDndEndFired(context: Context, intent: Intent? = null) {
        var wl: PowerManager.WakeLock? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ibadia:dnd_end")
                wl.acquire(10_000L)
            } catch (_: Exception) {}
        }

        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val activeEndMs = prefs.getLong(KEY_DND_ACTIVE_END_MS, 0L)
            val intentEndMs = intent?.getLongExtra("endMillis", 0L) ?: 0L
            val suppressUntil = maxOf(activeEndMs, intentEndMs, System.currentTimeMillis() + 15_000L)
            prefs.edit().putLong(KEY_DND_SUPPRESSED_END_MS, suppressUntil).commit()

            restoreSavedDndFilter(context)
            rescheduleStoredDndWindows(context)
        } finally {
            try {
                if (wl?.isHeld == true) wl.release()
            } catch (_: Exception) {}
        }
    }

    fun restoreAndSuppressCurrentWindow(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val activeEndMs = prefs.getLong(KEY_DND_ACTIVE_END_MS, 0L)
        val suppressUntil = maxOf(activeEndMs, System.currentTimeMillis() + 15_000L)
        prefs.edit().putLong(KEY_DND_SUPPRESSED_END_MS, suppressUntil).commit()
        restoreSavedDndFilter(context)
        rescheduleStoredDndWindows(context)
    }

    fun restoreSavedDndFilter(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm.isNotificationPolicyAccessGranted) {
            val rawPrevFilter = prefs.getInt(KEY_DND_PREV_FILTER, NotificationManager.INTERRUPTION_FILTER_ALL)
            val targetFilter = if (
                rawPrevFilter == NotificationManager.INTERRUPTION_FILTER_ALL ||
                rawPrevFilter == NotificationManager.INTERRUPTION_FILTER_PRIORITY
            ) {
                rawPrevFilter
            } else {
                NotificationManager.INTERRUPTION_FILTER_ALL
            }
            val rawPrevRinger = prefs.getInt(KEY_DND_PREV_RINGER, AudioManager.RINGER_MODE_NORMAL)
            val targetRinger = if (
                rawPrevRinger == AudioManager.RINGER_MODE_NORMAL ||
                rawPrevRinger == AudioManager.RINGER_MODE_VIBRATE
            ) {
                rawPrevRinger
            } else if (targetFilter == NotificationManager.INTERRUPTION_FILTER_ALL) {
                AudioManager.RINGER_MODE_NORMAL
            } else {
                rawPrevRinger
            }

            // 1) Exit DND interruption filter first
            try {
                nm.setInterruptionFilter(targetFilter)
            } catch (_: Exception) {}
            // 2) Restore ringer mode when not re-triggering RINGER_MODE_SILENT DND lock
            try {
                if (am.ringerMode != targetRinger) {
                    am.ringerMode = targetRinger
                }
            } catch (_: Exception) {}
            // 3) Re-assert targetFilter & ringer if OEM ZenModeHelper toggled DND when changing ringerMode
            try {
                if (targetFilter == NotificationManager.INTERRUPTION_FILTER_ALL &&
                    nm.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL
                ) {
                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                }
                if (targetFilter == NotificationManager.INTERRUPTION_FILTER_ALL &&
                    am.ringerMode == AudioManager.RINGER_MODE_SILENT
                ) {
                    am.ringerMode = AudioManager.RINGER_MODE_NORMAL
                }
            } catch (_: Exception) {}
        }
        prefs.edit()
            .putBoolean(KEY_DND_ACTIVE, false)
            .remove(KEY_DND_ACTIVE_END_MS)
            .remove(KEY_DND_PREV_FILTER)
            .remove(KEY_DND_PREV_RINGER)
            .commit()
        nm.cancel(DND_NOTIFICATION_ID)
    }
}

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        PrayerAlarmController.handleAlarmFired(context.applicationContext, intent)
    }
}

class PrayerDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerKey = intent.getStringExtra("prayerKey")
        val triggerDate = intent.getStringExtra("triggerDate")
        PrayerAlarmController.dismissActive(context.applicationContext, triggerDate, prayerKey)
    }
}

class PrayerKahfReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        PrayerAlarmController.handleKahfFired(context.applicationContext, intent)
    }
}

class PrayerDndStartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        try {
            PrayerAlarmController.handleDndStartFired(context.applicationContext, intent)
        } finally {
            pendingResult.finish()
        }
    }
}

class PrayerDndEndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        try {
            PrayerAlarmController.handleDndEndFired(context.applicationContext, intent)
        } finally {
            pendingResult.finish()
        }
    }
}

class PrayerDndRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        PrayerAlarmController.restoreAndSuppressCurrentWindow(context.applicationContext)
    }
}

class PrayerBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appCtx = context.applicationContext
        PrayerAlarmController.reconcileActiveDndState(appCtx)
        PrayerAlarmController.rescheduleStoredAlarms(appCtx)
        PrayerAlarmController.rescheduleKahfFromPrefs(appCtx)
        PrayerAlarmController.rescheduleStoredDndWindows(appCtx)
    }
}

class PrayerHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val location = prefs.getString("widget_location", "Kochi, India") ?: "Kochi, India"
        val hijri = prefs.getString("widget_hijri_date", "Ibadia") ?: "Ibadia"
        val nextLabel = prefs.getString("widget_next_label", "Next Prayer") ?: "Next Prayer"
        val prayerName = prefs.getString("widget_prayer_name", "Fajr") ?: "Fajr"
        val adhanTime = prefs.getString("widget_adhan_time", "--:--") ?: "--:--"
        val iqamahTime = prefs.getString("widget_iqamah_time", "") ?: ""

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_home_widget)
            views.setTextViewText(R.id.widget_location, location)
            views.setTextViewText(R.id.widget_hijri_date, hijri)
            views.setTextViewText(R.id.widget_next_label, nextLabel)
            views.setTextViewText(R.id.widget_prayer_name, prayerName)
            views.setTextViewText(R.id.widget_adhan_time, adhanTime)
            views.setTextViewText(R.id.widget_iqamah_time, iqamahTime)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtra("openPrayerTab", true)
            }
            val pi = PendingIntent.getActivity(
                context,
                9401 + appWidgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
