package top.syngnat.lumina.euicc

import java.util.concurrent.CancellationException

internal const val MOCK_CHANNEL_SLOT_ID: Int = Int.MIN_VALUE

internal fun isMockChannel(slotId: Int): Boolean = slotId == MOCK_CHANNEL_SLOT_ID

internal suspend fun <T> routeChannel(
    slotId: Int,
    mock: suspend () -> T,
    real: suspend () -> T,
): T = if (isMockChannel(slotId)) mock() else real()

/** Performs a fresh real-channel probe for every request. Mock data is debug-only. */
internal class BridgeChannelDiscovery(
    private val discoverRealChannels: suspend () -> List<Map<String, Any>>,
    private val allowMock: Boolean,
    private val onProbeError: (Exception) -> Unit = {},
) {
    suspend fun listChannels(): Map<String, Any> = try {
        val channels = discoverRealChannels()
        if (channels.isEmpty()) fallbackResponse() else mapOf("channels" to channels, "mode" to "real")
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (error: Exception) {
        onProbeError(error)
        fallbackResponse(safeFailureType(error))
    }

    private fun fallbackResponse(fallbackReason: String? = null): Map<String, Any> {
        if (allowMock) return mockResponse(fallbackReason)

        val response = mutableMapOf<String, Any>(
            "channels" to emptyList<Map<String, Any>>(),
            "mode" to "unavailable",
        )
        if (fallbackReason != null) response["fallbackReason"] = fallbackReason
        return response
    }

    private fun mockResponse(fallbackReason: String? = null): Map<String, Any> {
        val response = mutableMapOf<String, Any>(
            "channels" to listOf(
                mapOf(
                    "slotId" to MOCK_CHANNEL_SLOT_ID,
                    "portId" to 0,
                    "seId" to "0",
                    "label" to "Removable eUICC (mock)",
                    "type" to "mock",
                )
            ),
            "mode" to "mock",
        )
        if (fallbackReason != null) response["fallbackReason"] = fallbackReason
        return response
    }
}
