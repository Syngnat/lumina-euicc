package top.syngnat.lumina.euicc

import java.util.concurrent.CancellationException
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class BridgeChannelRoutingTest {
    @Test
    fun discoveryProbesAgainAfterAnEmptyResultAndRecoversARealChannel() = runBlocking {
        val probeCount = AtomicInteger(0)
        val realChannel = mapOf<String, Any>(
            "slotId" to 0,
            "portId" to 0,
            "seId" to "0",
            "label" to "Real eUICC",
            "type" to "omapi",
        )
        val discovery = BridgeChannelDiscovery(
            discoverRealChannels = {
                if (probeCount.incrementAndGet() == 1) emptyList() else listOf(realChannel)
            },
            allowMock = true,
        )

        val first = discovery.listChannels()
        val second = discovery.listChannels()

        assertEquals(2, probeCount.get())
        assertEquals("mock", first["mode"])
        assertEquals(MOCK_CHANNEL_SLOT_ID, first.channels().single()["slotId"])
        assertEquals("real", second["mode"])
        assertEquals(listOf(realChannel), second.channels())
    }

    @Test
    fun discoveryProbesAgainAfterAnErrorAndPreservesTheFallbackReason() = runBlocking {
        val probeCount = AtomicInteger(0)
        val realChannel = mapOf<String, Any>("slotId" to 1)
        val discovery = BridgeChannelDiscovery(
            discoverRealChannels = {
                if (probeCount.incrementAndGet() == 1) {
                    throw IllegalStateException("probe failed")
                }
                listOf(realChannel)
            },
            allowMock = true,
        )

        val first = discovery.listChannels()
        val second = discovery.listChannels()

        assertEquals(2, probeCount.get())
        assertEquals("mock", first["mode"])
        assertEquals("IllegalStateException", first["fallbackReason"])
        assertEquals("real", second["mode"])
    }

    @Test
    fun onlyTheSentinelChannelRoutesToMock() {
        assertTrue(isMockChannel(MOCK_CHANNEL_SLOT_ID))
        assertFalse(isMockChannel(0))
        assertFalse(isMockChannel(99))
    }

    @Test
    fun aRealChannelFailureIsPropagatedInsteadOfReturningMockData() {
        var mockCalled = false
        val expected = IllegalStateException("real profile query failed")

        val thrown = assertThrows(IllegalStateException::class.java) {
            runBlocking {
                routeChannel(
                    slotId = 0,
                    mock = {
                        mockCalled = true
                        "mock profiles"
                    },
                    real = { throw expected },
                )
            }
        }

        assertEquals(expected, thrown)
        assertFalse(mockCalled)
    }

    @Test
    fun discoveryPropagatesCoroutineCancellationInsteadOfReturningMockData() {
        val expected = CancellationException("cancelled")
        val discovery = BridgeChannelDiscovery(
            discoverRealChannels = { throw expected },
            allowMock = true,
        )

        val thrown = assertThrows(CancellationException::class.java) {
            runBlocking { discovery.listChannels() }
        }

        assertSame(expected, thrown)
    }

    @Test
    fun productionDiscoveryDoesNotInventAChannelWhenNoRealChannelExists() = runBlocking {
        val discovery = BridgeChannelDiscovery(
            discoverRealChannels = { emptyList() },
            allowMock = false,
        )

        val response = discovery.listChannels()

        assertEquals("unavailable", response["mode"])
        assertTrue(response.channels().isEmpty())
    }

    @Test
    fun productionDiscoveryPreservesProbeFailureWithoutReturningMockData() = runBlocking {
        val discovery = BridgeChannelDiscovery(
            discoverRealChannels = { throw IllegalStateException("ARA-M denied") },
            allowMock = false,
        )

        val response = discovery.listChannels()

        assertEquals("unavailable", response["mode"])
        assertEquals("IllegalStateException", response["fallbackReason"])
        assertTrue(response.channels().isEmpty())
    }

    @Suppress("UNCHECKED_CAST")
    private fun Map<String, Any>.channels(): List<Map<String, Any>> =
        getValue("channels") as List<Map<String, Any>>
}
