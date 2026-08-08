package top.syngnat.lumina.euicc

private const val MAXIMUM_UPDATE_APK_BYTES = 200L * 1024L * 1024L
private val UPDATE_ASSET_NAME = Regex(
    "^lumina-euicc-\\d+\\.\\d+\\.\\d+-\\d+-(universal|arm64-v8a|armeabi-v7a|x86_64)\\.apk$",
)
private val UPDATE_SHA256 = Regex("^[0-9a-f]{64}$")
private val UPDATE_VERSION_NAME = Regex("^\\d+\\.\\d+\\.\\d+$")

internal fun requireUpdateAssetName(value: Any?): String {
    val name = value as? String
        ?: throw IllegalArgumentException("assetName required")
    require(UPDATE_ASSET_NAME.matches(name)) { "assetName is invalid" }
    return name
}

internal fun requireUpdateSha256(value: Any?): String {
    val digest = (value as? String)
        ?.lowercase()
        ?: throw IllegalArgumentException("expectedSha256 required")
    require(UPDATE_SHA256.matches(digest)) { "expectedSha256 is invalid" }
    return digest
}

internal fun requireUpdateSize(value: Any?): Long {
    val size = when (value) {
        is Byte -> value.toLong()
        is Short -> value.toLong()
        is Int -> value.toLong()
        is Long -> value
        else -> throw IllegalArgumentException("expectedSize must be an integer")
    }
    require(size in 1..MAXIMUM_UPDATE_APK_BYTES) { "expectedSize is invalid" }
    return size
}

internal fun requireUpdateVersionName(value: Any?): String {
    val versionName = value as? String
        ?: throw IllegalArgumentException("expectedVersionName required")
    require(UPDATE_VERSION_NAME.matches(versionName)) { "expectedVersionName is invalid" }
    return versionName
}
