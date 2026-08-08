package top.syngnat.lumina.euicc

internal data class ValidatedDownloadRequest(
    val slotId: Int,
    val portId: Int,
    val seId: Int,
    val address: String,
    val matchingId: String?,
    val confirmationCode: String?,
    val imei: String?,
)

internal fun requireIntArgument(key: String, value: Any?): Int {
    val number = value ?: throw IllegalArgumentException("$key required")
    return when (number) {
        is Byte -> number.toInt()
        is Short -> number.toInt()
        is Int -> number
        is Long -> {
            require(number in Int.MIN_VALUE.toLong()..Int.MAX_VALUE.toLong()) {
                "$key must be a 32-bit integer"
            }
            number.toInt()
        }
        else -> throw IllegalArgumentException("$key must be a 32-bit integer")
    }
}

internal fun requireLongArgument(key: String, value: Any?): Long {
    val number = value ?: throw IllegalArgumentException("$key required")
    return when (number) {
        is Byte -> number.toLong()
        is Short -> number.toLong()
        is Int -> number.toLong()
        is Long -> number
        else -> throw IllegalArgumentException("$key must be an integer")
    }
}

internal fun requireBooleanArgument(key: String, value: Any?): Boolean =
    value as? Boolean ?: throw IllegalArgumentException("$key required and must be a boolean")

internal fun requireStringArgument(key: String, value: Any?): String =
    value as? String ?: throw IllegalArgumentException("$key required and must be a string")

internal fun optionalStringArgument(key: String, value: Any?): String? = when (value) {
    null -> null
    is String -> value
    else -> throw IllegalArgumentException("$key must be a string")
}

internal fun requireSeIdArgument(value: Any?): Int = when (value) {
    is String -> value.toIntOrNull()
        ?: throw IllegalArgumentException("seId must be a 32-bit integer")
    else -> requireIntArgument("seId", value)
}

internal fun validateDownloadRequest(
    slotId: Any?,
    portId: Any?,
    seId: Any?,
    activationCode: Any?,
    confirmationCode: Any?,
    imei: Any?,
): ValidatedDownloadRequest {
    val (address, matchingId) = parseActivationCode(
        requireStringArgument("activationCode", activationCode)
    )
    return ValidatedDownloadRequest(
        slotId = requireIntArgument("slotId", slotId),
        portId = requireIntArgument("portId", portId),
        seId = requireSeIdArgument(seId),
        address = address,
        matchingId = matchingId,
        confirmationCode = optionalStringArgument("confirmationCode", confirmationCode),
        imei = optionalStringArgument("imei", imei),
    )
}

private fun parseActivationCode(raw: String): Pair<String, String?> {
    var token = raw.trim()
    if (token.startsWith("LPA:", ignoreCase = true)) token = token.drop(4)
    val parts = token.split('$').map { it.trim().ifBlank { null } }
    require(parts.getOrNull(0) == "1") { "Invalid activation code format (expect LPA:1\$...)" }
    val address = requireNotNull(parts.getOrNull(1)) { "SM-DP+ address required" }
    return address to parts.getOrNull(2)
}
