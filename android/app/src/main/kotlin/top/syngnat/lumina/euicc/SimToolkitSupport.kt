package top.syngnat.lumina.euicc

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log

internal object SimToolkitCandidates {
    val componentNames = listOf(
        // Prefer a system-provided slot selector when one exists.
        "com.android.stk/.StkMain",
        "com.android.stk/.StkMainHide",
        "com.android.stk/.StkListActivity",
        "com.android.stk/.StkLauncherListActivity",
        "com.android.stk/.StkSelectionActivity",
        // Slot 1 variants used by AOSP and common OEM builds.
        "com.android.stk/.StkMain1",
        "com.android.stk/.PrimaryStkMain",
        "com.android.stk/.StkLauncherActivity",
        "com.android.stk/.StkLauncherActivity_Chn",
        "com.android.stk/.StkLauncherActivity1",
        "com.android.stk/.StkLauncherActivityI",
        "com.android.stk/.OppoStkLauncherActivity1",
        "com.android.stk/.OplusStkLauncherActivity1",
        "com.android.stk/.mtk.StkLauncherActivityI",
        // Slot 2 variants.
        "com.android.stk/.StkMain2",
        "com.android.stk/.SecondaryStkMain",
        "com.android.stk/.StkLauncherActivity2",
        "com.android.stk/.StkLauncherActivityII",
        "com.android.stk/.OppoStkLauncherActivity2",
        "com.android.stk/.OplusStkLauncherActivity2",
        "com.android.stk/.mtk.StkLauncherActivityII",
        "com.android.stk1/.StkLauncherActivity",
        "com.android.stk2/.StkLauncherActivity",
        "com.android.stk2/.StkLauncherActivity_Chn",
        "com.android.stk2/.StkLauncherActivity2",
    )

    val packageNames = componentNames
        .map { it.substringBefore('/') }
        .distinct()
}

internal class SimToolkitSupport {
    companion object {
        private const val TAG = "LuminaSimToolkit"
    }

    @Suppress("DEPRECATION")
    fun open(activity: Activity?): Boolean {
        if (activity == null) return false
        val packageManager = activity.packageManager

        for (flattenedName in SimToolkitCandidates.componentNames) {
            val component = ComponentName.unflattenFromString(flattenedName) ?: continue
            val intent = Intent.makeMainActivity(component)
            val info = intent.resolveActivityInfo(
                packageManager,
                PackageManager.MATCH_DISABLED_COMPONENTS,
            ) ?: continue
            if (!info.exported || !info.enabled || !info.applicationInfo.enabled) continue
            if (start(activity, intent, flattenedName)) return true
        }

        for (packageName in SimToolkitCandidates.packageNames) {
            val intent = packageManager.getLaunchIntentForPackage(packageName) ?: continue
            if (start(activity, intent, packageName)) return true
        }
        return false
    }

    private fun start(activity: Activity, intent: Intent, target: String): Boolean = try {
        activity.startActivity(intent)
        Log.i(TAG, "Opened system SIM Toolkit target=$target")
        true
    } catch (error: Exception) {
        Log.w(TAG, "Unable to open system SIM Toolkit target=$target type=${error.javaClass.simpleName}")
        false
    }
}
