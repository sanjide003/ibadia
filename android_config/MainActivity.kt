package com.quranapp.malayalam.quran_malayalam_app

import android.Manifest
import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
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
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val UPDATER_CHANNEL = "com.quranapp.malayalam/app_updater"
        private const val ALARM_CHANNEL = "com.quranapp.malayalam/prayer_alarm"
        private const val REQ_POST_NOTIF = 4102
    }

    private var alarmChannel: MethodChannel? = null

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
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        notifyFlutterActiveAlarm()
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

class PrayerBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        PrayerAlarmController.rescheduleStoredAlarms(context.applicationContext)
    }
}
