package top.syngnat.lumina.euicc

import java.security.MessageDigest

internal data class CompatibilityDiagnosticItem(
    val code: String,
    val title: String,
    val ok: Boolean,
    val detail: String,
    val arguments: Map<String, Any> = emptyMap(),
) {
    fun toMap(): Map<String, Any> = mapOf(
        "code" to code,
        "title" to title,
        "ok" to ok,
        "detail" to detail,
        "arguments" to arguments,
    )
}

internal enum class OmapiSlotProbeStatus {
    AUTHORIZED,
    ACCESS_DENIED,
    ISDR_UNAVAILABLE,
    FAILED,
}

internal data class OmapiSlotProbe(
    val slotId: Int,
    val status: OmapiSlotProbeStatus,
    val failureType: String? = null,
)

internal data class LpaPortProbeFailure(
    val slotId: Int,
    val portId: Int,
    val failureType: String,
)

internal data class CompatibilityDiagnosticsInput(
    val packageName: String,
    val signingCertificateSha1s: List<String>,
    val omapiPresent: Boolean,
    val deviceBrand: String = "",
    val deviceName: String = "",
    val deviceModel: String = "",
    val androidRelease: String = "",
    val androidSdkInt: Int = 0,
    val omapiServiceFailureType: String? = null,
    val slotProbes: List<OmapiSlotProbe> = emptyList(),
    val openPorts: List<Pair<Int, Int>> = emptyList(),
    val lpaPortFailures: List<LpaPortProbeFailure> = emptyList(),
    val lpaProbeFailureType: String? = null,
    val lpaChannelValid: Boolean = false,
)

internal fun certificateSha1(certificateBytes: ByteArray): String =
    MessageDigest.getInstance("SHA-1")
        .digest(certificateBytes)
        .joinToString(":") { byte -> "%02X".format(byte.toInt() and 0xff) }

internal fun safeFailureType(error: Exception): String =
    error.javaClass.simpleName.takeIf(String::isNotBlank) ?: "Exception"

internal fun parseOmapiSlotId(readerName: String, fallback: Int): Int =
    readerName.removePrefix("SIM").toIntOrNull()?.minus(1)?.takeIf { it >= 0 } ?: fallback

internal fun buildCompatibilityDiagnostics(
    input: CompatibilityDiagnosticsInput,
): List<CompatibilityDiagnosticItem> {
    val fingerprints = input.signingCertificateSha1s.joinToString()
    return buildList {
        add(
            CompatibilityDiagnosticItem(
                code = "app_identity",
                title = "App identity for ARA-M",
                ok = fingerprints.isNotEmpty(),
                detail = if (fingerprints.isEmpty()) {
                    "Package ${input.packageName}; signing certificate SHA-1 unavailable."
                } else {
                    "Package ${input.packageName}; signing certificate SHA-1 $fingerprints."
                },
                arguments = mapOf(
                    "packageName" to input.packageName,
                    "signingCertificateSha1s" to input.signingCertificateSha1s,
                ),
            )
        )
        add(
            CompatibilityDiagnosticItem(
                code = "device_info",
                title = "Device and Android",
                ok = true,
                detail = "${input.deviceBrand} ${input.deviceModel} (${input.deviceName}); " +
                    "Android ${input.androidRelease} (API ${input.androidSdkInt}).",
                arguments = mapOf(
                    "brand" to input.deviceBrand,
                    "device" to input.deviceName,
                    "model" to input.deviceModel,
                    "androidRelease" to input.androidRelease,
                    "androidSdkInt" to input.androidSdkInt,
                ),
            )
        )
        input.lpaPortFailures
            .sortedWith(compareBy({ it.slotId }, { it.portId }))
            .forEach { failure ->
                add(
                    CompatibilityDiagnosticItem(
                        code = "lpa_port_failed",
                        title = "LPA slot ${failure.slotId} / port ${failure.portId}",
                        ok = false,
                        detail = "Read-only LPA validation failed (${failure.failureType}).",
                        arguments = mapOf(
                            "slotId" to failure.slotId,
                            "portId" to failure.portId,
                            "failureType" to failure.failureType,
                        ),
                    )
                )
            }
        input.lpaProbeFailureType?.let { failureType ->
            add(
                CompatibilityDiagnosticItem(
                    code = "lpa_probe_failed",
                    title = "LPA probe",
                    ok = false,
                    detail = "Read-only channel discovery failed ($failureType).",
                    arguments = mapOf("failureType" to failureType),
                )
            )
        }
        add(
            CompatibilityDiagnosticItem(
                code = if (input.omapiPresent) "omapi_present" else "omapi_missing",
                title = "OMAPI present",
                ok = input.omapiPresent,
                detail = if (input.omapiPresent) {
                    "android.se.omapi.SEService is available."
                } else {
                    "OMAPI is missing on this device or Android version."
                },
            )
        )
        input.omapiServiceFailureType?.let { failureType ->
            add(
                CompatibilityDiagnosticItem(
                    code = "omapi_service_failed",
                    title = "OMAPI service",
                    ok = false,
                    detail = "Read-only OMAPI service probe failed ($failureType).",
                    arguments = mapOf("failureType" to failureType),
                )
            )
        }
        input.slotProbes.sortedBy(OmapiSlotProbe::slotId).forEach { probe ->
            add(
                CompatibilityDiagnosticItem(
                    code = when (probe.status) {
                        OmapiSlotProbeStatus.AUTHORIZED -> "omapi_slot_authorized"
                        OmapiSlotProbeStatus.ACCESS_DENIED -> "omapi_slot_access_denied"
                        OmapiSlotProbeStatus.ISDR_UNAVAILABLE -> "omapi_slot_isdr_unavailable"
                        OmapiSlotProbeStatus.FAILED -> "omapi_slot_failed"
                    },
                    title = "OMAPI slot ${probe.slotId}",
                    ok = probe.status == OmapiSlotProbeStatus.AUTHORIZED,
                    detail = when (probe.status) {
                        OmapiSlotProbeStatus.AUTHORIZED ->
                            "ISD-R logical channel opened for the current app identity."
                        OmapiSlotProbeStatus.ACCESS_DENIED ->
                            "UICC reader is reachable, but OMAPI access control (normally ARA-M / ARF " +
                                "for UICC) did not authorize the current app identity."
                        OmapiSlotProbeStatus.ISDR_UNAVAILABLE ->
                            "UICC reader is reachable, but none of the configured ISD-R AIDs opened a channel."
                        OmapiSlotProbeStatus.FAILED ->
                            "Read-only OMAPI probe failed (${probe.failureType ?: "unknown error"})."
                    },
                    arguments = buildMap {
                        put("slotId", probe.slotId)
                        probe.failureType?.let { put("failureType", it) }
                    },
                )
            )
        }
        if (input.slotProbes.isEmpty() && input.omapiServiceFailureType == null) {
            add(
                CompatibilityDiagnosticItem(
                    code = "omapi_no_uicc_readers",
                    title = "OMAPI UICC readers",
                    ok = false,
                    detail = "No phone-slot UICC reader was exposed by OMAPI.",
                )
            )
        }
        add(
            CompatibilityDiagnosticItem(
                code = if (input.openPorts.isEmpty()) {
                    "euicc_ports_missing"
                } else {
                    "euicc_ports_found"
                },
                title = "eUICC ports discovered",
                ok = input.openPorts.isNotEmpty(),
                detail = if (input.openPorts.isEmpty()) {
                    "No usable OMAPI or USB eUICC channel was opened."
                } else {
                    input.openPorts.sortedWith(compareBy({ it.first }, { it.second }))
                        .joinToString { (slotId, portId) -> "slot $slotId / port $portId" }
                },
                arguments = mapOf(
                    "ports" to input.openPorts.map { (slotId, portId) ->
                        mapOf("slotId" to slotId, "portId" to portId)
                    }
                ),
            )
        )
        add(
            CompatibilityDiagnosticItem(
                code = if (input.lpaChannelValid) {
                    "lpa_channel_valid"
                } else {
                    "lpa_channel_invalid"
                },
                title = "LPA channel valid",
                ok = input.lpaChannelValid,
                detail = if (input.lpaChannelValid) {
                    "A valid ISD-R / LPA channel opened successfully."
                } else {
                    "No valid LPA channel opened. Check the per-slot result and ARA-M rule."
                },
            )
        )
        add(
            CompatibilityDiagnosticItem(
                code = if (input.lpaChannelValid) {
                    "rootless_access_ready"
                } else {
                    "rootless_ara_m_required"
                },
                title = "Rootless access / ARA-M",
                ok = input.lpaChannelValid,
                detail = if (input.lpaChannelValid) {
                    "No root is used or required; a real LPA channel is available."
                } else {
                    "No root is used or required. For a card in the phone, its access-control rule " +
                        "must match at least one current Lumina signing certificate; if the rule " +
                        "also binds an Android package, it must match Lumina's package. USB CCID " +
                        "uses a separate permission path."
                },
            )
        )
    }
}
