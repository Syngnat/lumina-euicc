package im.angry.openeuicc.util

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.annotation.ArrayRes
import im.angry.easyeuicc.R
import im.angry.openeuicc.core.EuiccChannelManager

class SIMToolkit(private val context: Context) {
    private val slots = buildMap {
        fun getIntents(@ArrayRes id: Int) = context.resources.getStringArray(id)
            .mapNotNull(ComponentName::unflattenFromString)
            .map(Intent::makeMainActivity)
        put(-1, getIntents(R.array.sim_toolkit_slot_selection))
        put(0, getIntents(R.array.sim_toolkit_slot_1))
        put(1, getIntents(R.array.sim_toolkit_slot_2))
    }

    val intents: Iterable<Intent?>
        get() = listOf(get(0), get(1))

    operator fun get(slotId: Int): Intent? {
        if (slotId == -1 || slotId == EuiccChannelManager.USB_CHANNEL_ID) return null
        val intents = (slots[slotId] ?: emptyList()) + slots[-1]!!
        val packageNames = intents.mapNotNull(Intent::getPackage).toSet()
        return getIntent(context.packageManager, intents) // try to find an exported activity first
            ?: getLaunchIntent(context.packageManager, packageNames) // fallback to launch intent
            ?: getDisabledPackageIntent(context.packageManager, packageNames) // app settings if disabled
    }

    fun isSelection(intent: Intent) = intent in slots[-1]!!

    companion object {
        fun getDisabledPackageName(intent: Intent?): String? {
            if (intent?.action != Settings.ACTION_APPLICATION_DETAILS_SETTINGS) return null
            return intent.data!!.schemeSpecificPart
        }
    }
}


private fun getIntent(packageManager: PackageManager, intents: Iterable<Intent>) =
    intents.firstOrNull { it.resolveActivityInfo(packageManager, 0)?.exported ?: false }

private fun getLaunchIntent(packageManager: PackageManager, packageNames: Iterable<String>) =
    packageNames.firstNotNullOfOrNull(packageManager::getLaunchIntentForPackage)

private fun getDisabledPackageIntent(packageManager: PackageManager, packageNames: Iterable<String>): Intent? {
    val packageName = packageNames.firstOrNull(packageManager::isDisabledState) ?: return null
    val uri = Uri.fromParts("package", packageName, null)
    return Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
}

private fun PackageManager.isDisabledState(packageName: String) =
    when (getApplicationEnabledSetting(packageName)) {
        PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> true
        PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER -> true
        else -> false
    }
