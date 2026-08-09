package top.syngnat.lumina.euicc

import java.io.ByteArrayInputStream
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MicroDataResponseLimitTest {
    @Test
    fun selectsTheRequestedPortAndExcludesThePreviousSubscription() {
        val candidates = listOf(
            MicroDataSubscriptionCandidate(slotId = 1, portId = 0, subscriptionId = 10),
            MicroDataSubscriptionCandidate(slotId = 1, portId = 1, subscriptionId = 11),
            MicroDataSubscriptionCandidate(slotId = 1, portId = 1, subscriptionId = 12),
        )

        val selected = selectMicroDataSubscription(
            candidates = candidates,
            targetSlotId = 1,
            targetPortId = 1,
            excludedSubscriptionId = 11,
            matchPort = true,
        )

        assertEquals(12, selected?.subscriptionId)
    }

    @Test
    fun preAndroid13SelectionUsesTheSlotButStillExcludesThePreviousSubscription() {
        val selected = selectMicroDataSubscription(
            candidates = listOf(
                MicroDataSubscriptionCandidate(slotId = 0, portId = 7, subscriptionId = 20),
                MicroDataSubscriptionCandidate(slotId = 0, portId = 8, subscriptionId = 21),
            ),
            targetSlotId = 0,
            targetPortId = 0,
            excludedSubscriptionId = 20,
            matchPort = false,
        )

        assertEquals(21, selected?.subscriptionId)
    }

    @Test
    fun acceptsAResponseAtTheConfiguredLimit() {
        val result = readResponseBodyWithinLimit(
            ByteArrayInputStream(ByteArray(1_024)),
            maxBytes = 1_024,
        )

        assertEquals(1_024, result.bytesRead)
        assertFalse(result.limitExceeded)
    }

    @Test
    fun detectsOneByteBeyondTheConfiguredLimit() {
        val result = readResponseBodyWithinLimit(
            ByteArrayInputStream(ByteArray(1_025)),
            maxBytes = 1_024,
        )

        assertEquals(1_024, result.bytesRead)
        assertTrue(result.limitExceeded)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsANonPositiveLimit() {
        readResponseBodyWithinLimit(ByteArrayInputStream(byteArrayOf()), maxBytes = 0)
    }
}
