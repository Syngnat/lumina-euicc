package top.syngnat.lumina.euicc

import java.security.MessageDigest

internal data class ValidatedProfileReminder(
    val id: String,
    val profileName: String,
    val triggerAtMillis: Long,
)

internal fun stableProfileReminderId(iccid: String): String {
    val normalized = iccid.trim()
    require(normalized.isNotEmpty()) { "Profile identity is required" }
    return MessageDigest.getInstance("SHA-256")
        .digest(normalized.toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it) }
}

internal fun validateProfileReminderRequest(
    iccid: String,
    profileName: String,
    triggerAtMillis: Long,
    nowMillis: Long = System.currentTimeMillis(),
): ValidatedProfileReminder {
    val name = profileName.trim()
    require(name.isNotEmpty()) { "Profile name is required" }
    require(name.length <= 128) { "Profile name is too long" }
    require(triggerAtMillis > nowMillis) { "Reminder must be in the future" }
    return ValidatedProfileReminder(
        id = stableProfileReminderId(iccid),
        profileName = name,
        triggerAtMillis = triggerAtMillis,
    )
}
