package top.syngnat.lumina.euicc

import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BridgeProfileSwitchCoordinatorTest {
    @Test
    fun refreshedSwitchWaitsForTheChannelBeforeReturning() = runBlocking {
        val events = mutableListOf<String>()
        val coordinator = BridgeProfileSwitchCoordinator(
            reconnectTimeoutMillis = 30_000,
            reconnectDelayMillis = 3_000,
            delay = { millis -> events += "delay:$millis" },
        )

        val outcome = coordinator.switchAndReconnect(
            performSwitch = { refresh ->
                events += "switch:$refresh"
                true
            },
            waitForReconnect = { timeout -> events += "reconnect:$timeout" },
        )

        assertTrue(outcome.switched)
        assertTrue(outcome.refreshed)
        assertEquals(
            listOf("switch:true", "delay:3000", "reconnect:27000"),
            events,
        )
    }

    @Test
    fun failedRefreshFallsBackWithoutWaitingForAReconnect() = runBlocking {
        val events = mutableListOf<String>()
        val coordinator = BridgeProfileSwitchCoordinator(
            delay = { millis -> events += "delay:$millis" },
        )

        val outcome = coordinator.switchAndReconnect(
            performSwitch = { refresh ->
                events += "switch:$refresh"
                !refresh
            },
            waitForReconnect = { timeout -> events += "reconnect:$timeout" },
        )

        assertTrue(outcome.switched)
        assertFalse(outcome.refreshed)
        assertEquals(listOf("switch:true", "switch:false"), events)
    }

    @Test
    fun failedSwitchDoesNotPretendThatTheChannelRecovered() = runBlocking {
        val events = mutableListOf<String>()
        val coordinator = BridgeProfileSwitchCoordinator(
            delay = { millis -> events += "delay:$millis" },
        )

        val outcome = coordinator.switchAndReconnect(
            performSwitch = { refresh ->
                events += "switch:$refresh"
                false
            },
            waitForReconnect = { timeout -> events += "reconnect:$timeout" },
        )

        assertFalse(outcome.switched)
        assertFalse(outcome.refreshed)
        assertEquals(listOf("switch:true", "switch:false"), events)
    }
}
