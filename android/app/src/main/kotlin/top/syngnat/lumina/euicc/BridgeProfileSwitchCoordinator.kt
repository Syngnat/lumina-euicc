package top.syngnat.lumina.euicc

import kotlinx.coroutines.delay as coroutineDelay

internal data class BridgeProfileSwitchOutcome(
    val switched: Boolean,
    val refreshed: Boolean,
)

/**
 * Keeps a profile switch and the modem-triggered channel reconnect in one
 * observable operation. A successful refresh invalidates the current OMAPI
 * channel, so callers must not expose success until the replacement channel is
 * available again.
 */
internal class BridgeProfileSwitchCoordinator(
    private val reconnectTimeoutMillis: Long = 30_000,
    private val reconnectDelayMillis: Long = reconnectTimeoutMillis / 10,
    private val delay: suspend (Long) -> Unit = { coroutineDelay(it) },
) {
    init {
        require(reconnectTimeoutMillis > 0)
        require(reconnectDelayMillis in 0 until reconnectTimeoutMillis)
    }

    suspend fun switchAndReconnect(
        performSwitch: suspend (refresh: Boolean) -> Boolean,
        waitForReconnect: suspend (timeoutMillis: Long) -> Unit,
    ): BridgeProfileSwitchOutcome {
        if (performSwitch(true)) {
            delay(reconnectDelayMillis)
            waitForReconnect(reconnectTimeoutMillis - reconnectDelayMillis)
            return BridgeProfileSwitchOutcome(switched = true, refreshed = true)
        }

        return BridgeProfileSwitchOutcome(
            switched = performSwitch(false),
            refreshed = false,
        )
    }
}
