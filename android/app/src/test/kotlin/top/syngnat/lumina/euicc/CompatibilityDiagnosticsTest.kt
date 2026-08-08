package top.syngnat.lumina.euicc

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CompatibilityDiagnosticsTest {
    @Test
    fun appIdentityReportsPackageAndColonSeparatedSha1WithoutCardIdentifiers() {
        val sha1 = certificateSha1(byteArrayOf(0x01, 0x23, 0x45, 0x67))
        val diagnostics = buildCompatibilityDiagnostics(
            CompatibilityDiagnosticsInput(
                packageName = "top.syngnat.lumina.euicc",
                signingCertificateSha1s = listOf(sha1),
                omapiPresent = true,
            )
        )

        val identity = diagnostics.first()
        assertEquals("app_identity", identity.code)
        assertEquals("App identity for ARA-M", identity.title)
        assertTrue(identity.ok)
        assertTrue(identity.detail.contains("top.syngnat.lumina.euicc"))
        assertTrue(identity.detail.contains(sha1))
        assertEquals(
            listOf(sha1),
            identity.arguments["signingCertificateSha1s"],
        )
        assertTrue(sha1.matches(Regex("(?:[0-9A-F]{2}:){19}[0-9A-F]{2}")))
        assertFalse(diagnostics.any { it.detail.contains("EID", ignoreCase = true) })
        assertFalse(diagnostics.any { it.detail.contains("ICCID", ignoreCase = true) })
    }

    @Test
    fun araMAccessDenialIsReportedForItsSlotWithoutExceptionMessage() {
        val diagnostics = buildCompatibilityDiagnostics(
            CompatibilityDiagnosticsInput(
                packageName = "top.syngnat.lumina.euicc",
                signingCertificateSha1s = listOf("AA:BB"),
                omapiPresent = true,
                slotProbes = listOf(
                    OmapiSlotProbe(
                        slotId = 1,
                        status = OmapiSlotProbeStatus.ACCESS_DENIED,
                        failureType = "SecurityException",
                    )
                ),
            )
        )

        val slot = diagnostics.single { it.title == "OMAPI slot 1" }
        assertEquals("omapi_slot_access_denied", slot.code)
        assertFalse(slot.ok)
        assertTrue(slot.detail.contains("ARA-M"))
        assertTrue(slot.detail.contains("denied"))
        assertFalse(slot.detail.contains("secret vendor exception text"))
        assertEquals(1, slot.arguments["slotId"])
    }

    @Test
    fun probeFailureUsesOnlyTheExceptionType() {
        val failureType = safeFailureType(
            IllegalStateException("EID=89000000000000000000000000000000")
        )

        assertEquals("IllegalStateException", failureType)
        assertFalse(failureType.contains("8900"))
    }

    @Test
    fun failedRealChannelProbeExplainsRootlessAraMRequirement() {
        val diagnostics = buildCompatibilityDiagnostics(
            CompatibilityDiagnosticsInput(
                packageName = "top.syngnat.lumina.euicc",
                signingCertificateSha1s = listOf("AA:BB"),
                omapiPresent = true,
                slotProbes = listOf(
                    OmapiSlotProbe(0, OmapiSlotProbeStatus.ACCESS_DENIED)
                ),
                openPorts = emptyList(),
                lpaChannelValid = false,
            )
        )

        assertFalse(diagnostics.single { it.title == "eUICC ports discovered" }.ok)
        assertFalse(diagnostics.single { it.title == "LPA channel valid" }.ok)
        val rootless = diagnostics.single { it.title == "Rootless access / ARA-M" }
        assertFalse(rootless.ok)
        assertTrue(rootless.detail.contains("No root"))
        assertTrue(rootless.detail.contains("EasyEUICC-only"))
        assertTrue(rootless.detail.contains("Lumina"))
    }

    @Test
    fun omapiReaderNamesMapToZeroBasedSlotsWithSafeFallback() {
        assertEquals(0, parseOmapiSlotId("SIM1", 7))
        assertEquals(1, parseOmapiSlotId("SIM2", 7))
        assertEquals(7, parseOmapiSlotId("SIM", 7))
        assertEquals(7, parseOmapiSlotId("vendor-uicc", 7))
    }

    @Test
    fun everyOmapiSlotOutcomeHasAStableMachineReadableCode() {
        val diagnostics = buildCompatibilityDiagnostics(
            CompatibilityDiagnosticsInput(
                packageName = "top.syngnat.lumina.euicc",
                signingCertificateSha1s = listOf("AA:BB"),
                omapiPresent = true,
                slotProbes = listOf(
                    OmapiSlotProbe(3, OmapiSlotProbeStatus.FAILED, "IOException"),
                    OmapiSlotProbe(0, OmapiSlotProbeStatus.AUTHORIZED),
                    OmapiSlotProbe(2, OmapiSlotProbeStatus.ISDR_UNAVAILABLE),
                    OmapiSlotProbe(1, OmapiSlotProbeStatus.ACCESS_DENIED),
                ),
            )
        )

        assertEquals(
            listOf(
                "omapi_slot_authorized",
                "omapi_slot_access_denied",
                "omapi_slot_isdr_unavailable",
                "omapi_slot_failed",
            ),
            diagnostics.filter { it.code.startsWith("omapi_slot_") }.map { it.code },
        )
        assertTrue(
            diagnostics.single { it.code == "omapi_slot_failed" }
                .detail.contains("IOException")
        )
    }

    @Test
    fun methodChannelMapKeepsStableCodeAndLocalizationArguments() {
        val item = buildCompatibilityDiagnostics(
            CompatibilityDiagnosticsInput(
                packageName = "top.syngnat.lumina.euicc",
                signingCertificateSha1s = listOf("AA:BB"),
                omapiPresent = true,
                slotProbes = listOf(
                    OmapiSlotProbe(0, OmapiSlotProbeStatus.ACCESS_DENIED)
                ),
            )
        ).single { it.code == "omapi_slot_access_denied" }

        val channelValue = item.toMap()
        assertEquals("omapi_slot_access_denied", channelValue["code"])
        assertEquals(
            0,
            (channelValue["arguments"] as Map<*, *>)["slotId"],
        )
        assertFalse(channelValue.containsKey("eid"))
        assertFalse(channelValue.containsKey("iccid"))
    }
}
