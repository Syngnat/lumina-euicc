package top.syngnat.lumina.euicc

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import java.util.UUID
import net.typeblog.lpac_jni.ProfileDownloadState

/**
 * Owns the synchronous lpac download callback state without depending on Android or Flutter.
 * lpac treats a false callback result as a cooperative abort and reports that abort as an error.
 */
internal class DownloadTaskSession(
    private val emit: (Map<String, Any?>) -> Unit,
    private val confirmationTimeoutMillis: Long = DEFAULT_CONFIRMATION_TIMEOUT_MILLIS,
    val taskId: String = UUID.randomUUID().toString(),
) {
    private enum class Lifecycle {
        ACTIVE,
        CANCEL_REQUESTED,
        TERMINAL,
    }

    private enum class ConfirmationResponse {
        ACCEPTED,
        REJECTED,
    }

    private class PendingConfirmation {
        val response = AtomicReference<ConfirmationResponse?>(null)
        val latch = CountDownLatch(1)

        fun complete(value: Boolean): Boolean {
            val responseValue = if (value) ConfirmationResponse.ACCEPTED else ConfirmationResponse.REJECTED
            if (!response.compareAndSet(null, responseValue)) return false
            latch.countDown()
            return true
        }
    }

    private val lifecycle = AtomicReference(Lifecycle.ACTIVE)
    private val abortObserved = AtomicBoolean(false)
    private val pendingConfirmation = AtomicReference<PendingConfirmation?>(null)
    private val lifecycleEventLock = Any()

    fun onLpaState(state: ProfileDownloadState): Boolean {
        if (!continueWork()) return false

        return when (state) {
            is ProfileDownloadState.Preparing -> emitProgress("preparing", 0.0)
            is ProfileDownloadState.Connecting -> emitProgress("connecting", 0.2)
            is ProfileDownloadState.Authenticating -> emitProgress("authenticating", 0.4)
            is ProfileDownloadState.ConfirmingDownload -> awaitConfirmation(
                mapOf(
                    "phase" to "confirming",
                    "progress" to 0.5,
                    "provider" to (state.metadata?.providerName ?: ""),
                    "name" to (state.metadata?.name ?: ""),
                    "needConfirmation" to true,
                )
            )
            is ProfileDownloadState.Downloading -> emitProgress("downloading", 0.7)
            is ProfileDownloadState.Finalizing -> emitProgress("finalizing", 0.9)
        }
    }

    fun respondToConfirmation(continueDownload: Boolean): Boolean =
        pendingConfirmation.getAndSet(null)?.complete(continueDownload) == true

    fun cancel(): Boolean = synchronized(lifecycleEventLock) {
        if (!lifecycle.compareAndSet(Lifecycle.ACTIVE, Lifecycle.CANCEL_REQUESTED)) {
            return@synchronized false
        }
        pendingConfirmation.getAndSet(null)?.complete(false)
        emitEvent(mapOf("phase" to "cancelling", "done" to false))
        true
    }

    fun continueWork(): Boolean {
        val shouldContinue = lifecycle.get() == Lifecycle.ACTIVE
        if (!shouldContinue) abortObserved.set(true)
        return shouldContinue
    }

    fun emitProgress(payload: Map<String, Any?>): Boolean {
        return emitWhileActive(payload)
    }

    fun completeSuccess() {
        completeTerminal(mapOf("phase" to "done", "progress" to 1.0, "done" to true))
    }

    fun completeFailure(error: Throwable) {
        completeTerminal(
            mapOf(
                "phase" to "error",
                "done" to false,
                "error" to (error.message ?: error.toString()),
            )
        )
    }

    private fun emitProgress(phase: String, progress: Double): Boolean =
        emitProgress(mapOf("phase" to phase, "progress" to progress))

    fun awaitConfirmation(payload: Map<String, Any?>): Boolean {
        val pending = PendingConfirmation()
        check(pendingConfirmation.compareAndSet(null, pending)) {
            "A confirmation request is already pending"
        }

        if (!emitWhileActive(payload)) {
            pendingConfirmation.compareAndSet(pending, null)
            pending.complete(false)
            return false
        }

        val signalled = try {
            pending.latch.await(confirmationTimeoutMillis, TimeUnit.MILLISECONDS)
        } finally {
            pendingConfirmation.compareAndSet(pending, null)
        }
        val accepted = signalled &&
            pending.response.get() == ConfirmationResponse.ACCEPTED &&
            lifecycle.get() == Lifecycle.ACTIVE
        if (!accepted) {
            abortObserved.set(true)
            lifecycle.compareAndSet(Lifecycle.ACTIVE, Lifecycle.CANCEL_REQUESTED)
        }
        return accepted
    }

    private fun completeTerminal(payload: Map<String, Any?>) = synchronized(lifecycleEventLock) {
        if (lifecycle.getAndSet(Lifecycle.TERMINAL) == Lifecycle.TERMINAL) return@synchronized
        pendingConfirmation.getAndSet(null)?.complete(false)
        emitEvent(
            if (abortObserved.get()) {
                mapOf(
                    "phase" to "cancelled",
                    "done" to false,
                    "error" to "cancelled",
                )
            } else {
                payload
            }
        )
    }

    private fun emitWhileActive(payload: Map<String, Any?>): Boolean =
        synchronized(lifecycleEventLock) {
            if (lifecycle.get() != Lifecycle.ACTIVE) {
                abortObserved.set(true)
                return@synchronized false
            }
            emitEvent(payload)
            true
        }

    private fun emitEvent(payload: Map<String, Any?>) {
        emit(payload + ("taskId" to taskId))
    }

    private companion object {
        const val DEFAULT_CONFIRMATION_TIMEOUT_MILLIS = 5 * 60 * 1000L
    }
}
