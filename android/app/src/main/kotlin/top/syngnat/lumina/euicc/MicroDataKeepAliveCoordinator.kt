package top.syngnat.lumina.euicc

import java.io.InputStream
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext

internal data class MicroDataProbeResult(
    val httpStatus: Int,
    val responseBodyBytes: Int,
)

internal data class MicroDataKeepAliveOutcome(
    val probeResult: MicroDataProbeResult?,
    val failure: Exception?,
    val failureStage: String?,
    val targetActivationAttempted: Boolean,
    val restored: Boolean,
    val restoreFailure: Exception?,
)

internal class MicroDataKeepAliveCancelledException(
    val restored: Boolean,
    cause: CancellationException,
) : CancellationException("Micro-data operation was cancelled") {
    init {
        initCause(cause)
    }
}

/**
 * Runs the reversible profile-switch transaction around one bounded network
 * probe. Restoration is deliberately non-cancellable once Lumina has changed
 * the active profile.
 */
internal class MicroDataKeepAliveCoordinator {
    suspend fun run(
        targetInitiallyEnabled: Boolean,
        previousEnabledProfileExists: Boolean,
        activateTarget: suspend () -> Unit,
        probe: suspend () -> MicroDataProbeResult,
        restorePrevious: suspend () -> Unit,
        disableTarget: suspend () -> Unit,
    ): MicroDataKeepAliveOutcome {
        var targetActivationAttempted = false
        var activationCompleted = targetInitiallyEnabled
        var probeResult: MicroDataProbeResult? = null
        var failure: Exception? = null
        var failureStage: String? = null
        var cancellation: CancellationException? = null
        var restored = true
        var restoreFailure: Exception? = null

        try {
            if (!targetInitiallyEnabled) {
                targetActivationAttempted = true
                activateTarget()
                activationCompleted = true
            }
            probeResult = probe()
        } catch (cancelled: CancellationException) {
            cancellation = cancelled
        } catch (error: Exception) {
            failure = error
            failureStage = if (targetActivationAttempted && !activationCompleted) {
                "activation"
            } else {
                "network"
            }
        } finally {
            if (targetActivationAttempted) {
                withContext(NonCancellable) {
                    try {
                        if (previousEnabledProfileExists) {
                            restorePrevious()
                        } else {
                            disableTarget()
                        }
                    } catch (error: Exception) {
                        restored = false
                        restoreFailure = error
                    }
                }
            }
        }

        cancellation?.let {
            throw MicroDataKeepAliveCancelledException(restored, it)
        }
        return MicroDataKeepAliveOutcome(
            probeResult = probeResult,
            failure = failure,
            failureStage = failureStage,
            targetActivationAttempted = targetActivationAttempted,
            restored = restored,
            restoreFailure = restoreFailure,
        )
    }
}

internal data class LimitedResponseRead(
    val bytesRead: Int,
    val limitExceeded: Boolean,
)

internal data class MicroDataSubscriptionCandidate(
    val slotId: Int,
    val portId: Int,
    val subscriptionId: Int,
)

internal fun selectMicroDataSubscription(
    candidates: List<MicroDataSubscriptionCandidate>,
    targetSlotId: Int,
    targetPortId: Int,
    excludedSubscriptionId: Int?,
    matchPort: Boolean,
): MicroDataSubscriptionCandidate? = candidates.firstOrNull { candidate ->
    candidate.slotId == targetSlotId &&
        (!matchPort || candidate.portId == targetPortId) &&
        candidate.subscriptionId != excludedSubscriptionId
}

/** Reads at most [maxBytes] plus one sentinel byte, without retaining payload. */
internal fun readResponseBodyWithinLimit(
    input: InputStream,
    maxBytes: Int,
): LimitedResponseRead {
    require(maxBytes > 0) { "maxBytes must be positive" }
    var total = 0
    val buffer = ByteArray(minOf(256, maxBytes + 1))
    while (total <= maxBytes) {
        val remaining = maxBytes + 1 - total
        val read = input.read(buffer, 0, minOf(buffer.size, remaining))
        if (read < 0) break
        total += read
    }
    return LimitedResponseRead(
        bytesRead = minOf(total, maxBytes),
        limitExceeded = total > maxBytes,
    )
}
