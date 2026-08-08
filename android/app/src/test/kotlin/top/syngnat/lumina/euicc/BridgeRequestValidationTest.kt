package top.syngnat.lumina.euicc

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class BridgeRequestValidationTest {
    @Test
    fun intArgumentsRejectLongOverflowInsteadOfWrappingIntoTheMockSentinel() {
        val error = assertThrows(IllegalArgumentException::class.java) {
            requireIntArgument("slotId", Int.MAX_VALUE.toLong() + 1)
        }

        assertEquals("slotId must be a 32-bit integer", error.message)
    }

    @Test
    fun intArgumentsAcceptOnlyLosslessIntegerValues() {
        assertEquals(7, requireIntArgument("slotId", 7))
        assertEquals(7, requireIntArgument("slotId", 7L))
        assertThrows(IllegalArgumentException::class.java) {
            requireIntArgument("slotId", 7.0)
        }
    }

    @Test
    fun longArgumentsRejectMissingAndFractionalValues() {
        val missing = assertThrows(IllegalArgumentException::class.java) {
            requireLongArgument("seq", null)
        }
        val fractional = assertThrows(IllegalArgumentException::class.java) {
            requireLongArgument("seq", 1.5)
        }

        assertEquals("seq required", missing.message)
        assertEquals("seq must be an integer", fractional.message)
    }

    @Test
    fun mockDownloadRequestsStillRequireAValidActivationCode() {
        val request = validateDownloadRequest(
            slotId = MOCK_CHANNEL_SLOT_ID,
            portId = 0,
            seId = "0",
            activationCode = "LPA:1\$smdp.example.com\$matching-id",
            confirmationCode = null,
            imei = null,
        )

        assertEquals("smdp.example.com", request.address)
        assertEquals("matching-id", request.matchingId)
        assertThrows(IllegalArgumentException::class.java) {
            validateDownloadRequest(
                slotId = MOCK_CHANNEL_SLOT_ID,
                portId = 0,
                seId = "0",
                activationCode = "not-an-activation-code",
                confirmationCode = null,
                imei = null,
            )
        }
    }

    @Test
    fun booleanArgumentsRejectMissingValuesInsteadOfDefaultingToFalse() {
        val error = assertThrows(IllegalArgumentException::class.java) {
            requireBooleanArgument("continue", null)
        }

        assertEquals("continue required and must be a boolean", error.message)
    }
}
