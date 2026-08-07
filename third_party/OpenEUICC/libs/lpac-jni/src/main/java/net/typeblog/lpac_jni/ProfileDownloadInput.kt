package net.typeblog.lpac_jni

data class ProfileDownloadInput(
    val address: String,
    val matchingId: String?,
    val imei: String?,
    val confirmationCode: String?
)
