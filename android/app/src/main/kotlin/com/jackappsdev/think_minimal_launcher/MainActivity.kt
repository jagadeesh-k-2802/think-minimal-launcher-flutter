package com.jackappsdev.think_minimal_launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.LauncherApps
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.PowerManager
import android.os.UserHandle
import android.os.UserManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val iconPackManager by lazy {
        IconPackManager(this)
    }

    private val powerManager by lazy {
        getSystemService(Context.POWER_SERVICE) as PowerManager
    }

    private var pendingShortcuts = mutableListOf<Map<String, Any>>()
    private var methodChannel: MethodChannel? = null
    private var packageRemovedReceiverRegistered = false
    private val packageRemovedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != Intent.ACTION_PACKAGE_REMOVED) return
            if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return
            val packageName = intent.data?.schemeSpecificPart ?: return
            runOnUiThread {
                methodChannel?.invokeMethod("onPackageRemoved", packageName)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Shortcut channel
        val shortcutChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL_NAME)
        methodChannel = shortcutChannel
        shortcutChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingShortcuts" -> {
                    val list = synchronized(pendingShortcuts) {
                        val temp = pendingShortcuts.toList()
                        pendingShortcuts.clear()
                        temp
                    }
                    result.success(list)
                }
                "launchShortcut" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val shortcutId = call.argument<String>("shortcutId") ?: ""
                    launchShortcut(packageName, shortcutId, result)
                }
                "unpinShortcut" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val shortcutId = call.argument<String>("shortcutId") ?: ""
                    unpinShortcut(packageName, shortcutId, result)
                }
                else -> result.notImplemented()
            }
        }

        // Wake screen channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                WAKE_METHOD -> {
                    val seconds = (call.argument<Int>(WAKE_LOCK_SECONDS_PARAM) ?: 3).coerceIn(1, 10)
                    wakeScreen(seconds)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Launcher status channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                LAUNCHER_IS_DEFAULT_METHOD -> {
                    try {
                        result.success(isDefaultLauncher())
                    } catch (e: Exception) {
                        result.error("LAUNCHER_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Icon pack discovery channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ICON_PACK_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    ICON_PACK_LIST_METHOD_NAME -> {
                        try {
                            val packs = iconPackManager.getAvailableIconPacks()
                            val response = packs.map { pack ->
                                mapOf(
                                    "packageName" to pack.packageName,
                                    "name" to pack.name
                                )
                            }
                            result.success(response)
                        } catch (e: Exception) {
                            result.error(ICON_PACK_ERROR_CODE, e.message, null)
                        }
                    }

                    ICON_PACK_ICON_METHOD_NAME -> {
                        val iconPackPackageName =
                            call.argument<String>(ARG_ICON_PACK_PACKAGE_NAME) ?: ""
                        val appPackageName =
                            call.argument<String>(ARG_APP_PACKAGE_NAME) ?: ""

                        try {
                            val bytes =
                                iconPackManager.getIconForApp(iconPackPackageName, appPackageName)
                            result.success(bytes)
                        } catch (e: Exception) {
                            result.error(ICON_PACK_ICON_ERROR_CODE, e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // Process startup intent if launched to pin a shortcut
        registerPackageRemovedReceiver()
        handleIntent(intent)
    }

    override fun onDestroy() {
        if (packageRemovedReceiverRegistered) {
            try {
                unregisterReceiver(packageRemovedReceiver)
            } catch (_: Exception) {
            }
            packageRemovedReceiverRegistered = false
        }
        methodChannel = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == "android.content.pm.action.CONFIRM_PIN_SHORTCUT") {
            try {
                val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps ?: return
                val pinItemRequest = launcherApps.getPinItemRequest(intent) ?: return
                if (pinItemRequest.requestType == LauncherApps.PinItemRequest.REQUEST_TYPE_SHORTCUT) {
                    val shortcutInfo = pinItemRequest.shortcutInfo ?: return
                    
                    // Accept the request to let the Android system know we've pinned it
                    pinItemRequest.accept()

                    val id = shortcutInfo.id
                    val label = shortcutInfo.shortLabel?.toString() ?: shortcutInfo.id
                    val packageName = shortcutInfo.getPackage()
                    val iconDrawable = launcherApps.getShortcutIconDrawable(shortcutInfo, resources.displayMetrics.densityDpi)
                    val iconBytes = iconDrawableToByteArray(iconDrawable)
                    val sourceAppName = getAppLabel(packageName)
                    val sourceIconBytes = getAppIconBytes(packageName)

                    val shortcutData = mapOf(
                        "id" to id,
                        "packageName" to packageName,
                        "label" to label,
                        "iconBytes" to (iconBytes ?: ByteArray(0)),
                        "sourceAppName" to sourceAppName,
                        "sourceIconBytes" to (sourceIconBytes ?: ByteArray(0))
                    )

                    synchronized(pendingShortcuts) {
                        pendingShortcuts.add(shortcutData)
                    }

                    // Invoke on Flutter side if MethodChannel is registered
                    runOnUiThread {
                        methodChannel?.invokeMethod("onShortcutPinned", shortcutData)
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    private fun launchShortcut(packageName: String, shortcutId: String, result: MethodChannel.Result) {
        try {
            val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps
            if (launcherApps == null) {
                result.error("LAUNCHER_APPS_NOT_AVAILABLE", "LauncherApps service not available", null)
                return
            }
            val profiles = launcherApps.profiles
            var launched = false
            for (user in profiles) {
                val query = LauncherApps.ShortcutQuery().apply {
                    setQueryFlags(LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED)
                    setPackage(packageName)
                }
                val shortcuts = launcherApps.getShortcuts(query, user) ?: continue
                if (shortcuts.any { it.id == shortcutId }) {
                    launcherApps.startShortcut(packageName, shortcutId, null, null, user)
                    launched = true
                    break
                }
            }
            if (launched) {
                result.success(true)
            } else {
                // Check in dynamic or manifest shortcuts as fallback
                for (user in profiles) {
                    val query = LauncherApps.ShortcutQuery().apply {
                        setQueryFlags(LauncherApps.ShortcutQuery.FLAG_MATCH_DYNAMIC or LauncherApps.ShortcutQuery.FLAG_MATCH_MANIFEST)
                        setPackage(packageName)
                    }
                    val shortcuts = launcherApps.getShortcuts(query, user) ?: continue
                    if (shortcuts.any { it.id == shortcutId }) {
                        launcherApps.startShortcut(packageName, shortcutId, null, null, user)
                        launched = true
                        break
                    }
                }
                if (launched) {
                    result.success(true)
                } else {
                    result.error("SHORTCUT_NOT_FOUND", "Shortcut $shortcutId for package $packageName not found", null)
                }
            }
        } catch (e: Exception) {
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun unpinShortcut(packageName: String, shortcutId: String, result: MethodChannel.Result) {
        try {
            val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps
            if (launcherApps == null) {
                result.error("LAUNCHER_APPS_NOT_AVAILABLE", "LauncherApps service not available", null)
                return
            }
            val profiles = launcherApps.profiles
            var unpinned = false
            for (user in profiles) {
                val query = LauncherApps.ShortcutQuery().apply {
                    setQueryFlags(LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED)
                    setPackage(packageName)
                }
                val shortcuts = launcherApps.getShortcuts(query, user) ?: continue
                val target = shortcuts.firstOrNull { it.id == shortcutId }
                if (target != null) {
                    val remainingIds = shortcuts
                        .map { it.id }
                        .filter { it != shortcutId }
                    launcherApps.pinShortcuts(packageName, remainingIds, user)
                    unpinned = true
                }
            }
            result.success(unpinned)
        } catch (e: Exception) {
            result.error("UNPIN_FAILED", e.message, null)
        }
    }

    private fun iconDrawableToByteArray(drawable: Drawable?): ByteArray? {
        if (drawable == null) return null
        try {
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
                val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            return stream.toByteArray()
        } catch (e: Exception) {
            return null
        }
    }

    private fun getAppLabel(packageName: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            packageName
        }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            iconDrawableToByteArray(packageManager.getApplicationIcon(packageName))
        } catch (_: Exception) {
            null
        }
    }

    private fun registerPackageRemovedReceiver() {
        if (packageRemovedReceiverRegistered) return

        val filter = IntentFilter(Intent.ACTION_PACKAGE_REMOVED).apply {
            addDataScheme("package")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(packageRemovedReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(packageRemovedReceiver, filter)
        }
        packageRemovedReceiverRegistered = true
    }

    private fun wakeScreen(seconds: Int) {
        try {
            powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                WAKE_LOCK_TAG
            ).apply {
                acquire((seconds * 1000).toLong())
            }
        } catch (_: Throwable) {
        }
    }

    private fun isDefaultLauncher(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
            }
            val pm = packageManager
            val resolveInfo = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
                ?: return false
            val packageName = resolveInfo.activityInfo?.packageName ?: return false
            packageName == applicationContext.packageName
        } catch (_: Throwable) {
            false
        }
    }

    companion object {
        private const val SHORTCUT_CHANNEL_NAME = "com.jackappsdev.think_minimal_launcher/shortcuts"

        private const val WAKE_CHANNEL = "com.jackappsdev.think_minimal_launcher/wake"
        private const val WAKE_METHOD = "wakeScreen"
        private const val WAKE_LOCK_SECONDS_PARAM = "seconds"
        private const val WAKE_LOCK_TAG = "think_launcher:WakeLock"

        private const val LAUNCHER_CHANNEL = "com.jackappsdev.think_minimal_launcher/launcher"
        private const val LAUNCHER_IS_DEFAULT_METHOD = "isDefaultLauncher"

        private const val ICON_PACK_CHANNEL_NAME = "com.jackappsdev.think_minimal_launcher/icon_packs"
        private const val ICON_PACK_LIST_METHOD_NAME = "getIconPacks"
        private const val ICON_PACK_ICON_METHOD_NAME = "getIconForApp"

        private const val ICON_PACK_ERROR_CODE = "ICON_PACK_ERROR"
        private const val ICON_PACK_ICON_ERROR_CODE = "ICON_PACK_ICON_ERROR"
        private const val ARG_ICON_PACK_PACKAGE_NAME = "iconPackPackageName"
        private const val ARG_APP_PACKAGE_NAME = "appPackageName"
    }
}
