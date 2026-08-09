package top.syngnat.lumina.euicc

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class MicroDataKeepAliveCoordinatorTest {
    @Test
    fun disabledTargetIsActivatedThenPreviousProfileIsRestored() = runBlocking {
        val events = mutableListOf<String>()
        val coordinator = MicroDataKeepAliveCoordinator()

        val outcome = coordinator.run(
            targetInitiallyEnabled = false,
            previousEnabledProfileExists = true,
            activateTarget = { events += "activate" },
            probe = {
                events += "probe"
                MicroDataProbeResult(httpStatus = 204, responseBodyBytes = 0)
            },
            restorePrevious = { events += "restore" },
            disableTarget = { events += "disable" },
        )

        assertEquals(listOf("activate", "probe", "restore"), events)
        assertTrue(outcome.targetActivationAttempted)
        assertTrue(outcome.restored)
        assertEquals(204, outcome.probeResult?.httpStatus)
        assertNull(outcome.failure)
        assertNull(outcome.restoreFailure)
    }

    @Test
    fun disabledTargetWithoutPreviousProfileIsDisabledAfterProbe() = runBlocking {
        val events = mutableListOf<String>()
        val coordinator = MicroDataKeepAliveCoordinator()

        val outcome = coordinator.run(
            targetInitiallyEnabled = false,
            previousEnabledProfileExists = false,
            activateTarget = { events += "activate" },
            probe = {
                events += "probe"
                MicroDataProbeResult(httpStatus = 200, responseBodyBytes = 0)
            },
            restorePrevious = { events += "restore" },
            disableTarget = { events += "disable" },
        )

        assertEquals(listOf("activate", "probe", "disable"), events)
        assertTrue(outcome.restored)
    }

    @Test
    fun alreadyEnabledTargetIsNeverSwitchedOrRestored() = runBlocking {
        val events = mutableListOf<String>()
        val coordinator = MicroDataKeepAliveCoordinator()

        val outcome = coordinator.run(
            targetInitiallyEnabled = true,
            previousEnabledProfileExists = false,
            activateTarget = { events += "activate" },
            probe = {
                events += "probe"
                MicroDataProbeResult(httpStatus = 200, responseBodyBytes = 0)
            },
            restorePrevious = { events += "restore" },
            disableTarget = { events += "disable" },
        )

        assertEquals(listOf("probe"), events)
        assertFalse(outcome.targetActivationAttempted)
        assertTrue(outcome.restored)
    }

    @Test
    fun probeFailureStillRestoresPreviousProfile() = runBlocking {
        val events = mutableListOf<String>()
        val failure = IllegalStateException("network unavailable")
        val coordinator = MicroDataKeepAliveCoordinator()

        val outcome = coordinator.run(
            targetInitiallyEnabled = false,
            previousEnabledProfileExists = true,
            activateTarget = { events += "activate" },
            probe = {
                events += "probe"
                throw failure
            },
            restorePrevious = { events += "restore" },
            disableTarget = { events += "disable" },
        )

        assertEquals(listOf("activate", "probe", "restore"), events)
        assertSame(failure, outcome.failure)
        assertTrue(outcome.restored)
        assertNull(outcome.probeResult)
    }

    @Test
    fun restoreFailureIsReportedSeparatelyFromSuccessfulProbe() = runBlocking {
        val restoreFailure = IllegalStateException("restore failed")
        val coordinator = MicroDataKeepAliveCoordinator()

        val outcome = coordinator.run(
            targetInitiallyEnabled = false,
            previousEnabledProfileExists = true,
            activateTarget = {},
            probe = { MicroDataProbeResult(httpStatus = 200, responseBodyBytes = 0) },
            restorePrevious = { throw restoreFailure },
            disableTarget = {},
        )

        assertFalse(outcome.restored)
        assertSame(restoreFailure, outcome.restoreFailure)
        assertEquals(200, outcome.probeResult?.httpStatus)
    }

    @Test
    fun cancellationStillRestoresThenPropagates() = runBlocking {
        val events = mutableListOf<String>()
        val coordinator = MicroDataKeepAliveCoordinator()
        var cancelled = false

        try {
            coordinator.run(
                targetInitiallyEnabled = false,
                previousEnabledProfileExists = true,
                activateTarget = { events += "activate" },
                probe = {
                    events += "probe"
                    throw CancellationException("cancelled")
                },
                restorePrevious = { events += "restore" },
                disableTarget = { events += "disable" },
            )
        } catch (error: MicroDataKeepAliveCancelledException) {
            cancelled = true
            assertTrue(error.restored)
        }

        assertTrue(cancelled)
        assertEquals(listOf("activate", "probe", "restore"), events)
    }

    @Test
    fun activationFailureSkipsProbeButRestoresBecauseTheMutationIsUncertain() = runBlocking {
        val events = mutableListOf<String>()
        val activationFailure = IllegalStateException("activation failed")
        val coordinator = MicroDataKeepAliveCoordinator()

        val outcome = coordinator.run(
            targetInitiallyEnabled = false,
            previousEnabledProfileExists = true,
            activateTarget = {
                events += "activate"
                throw activationFailure
            },
            probe = {
                events += "probe"
                MicroDataProbeResult(httpStatus = 200, responseBodyBytes = 0)
            },
            restorePrevious = { events += "restore" },
            disableTarget = { events += "disable" },
        )

        assertEquals(listOf("activate", "restore"), events)
        assertSame(activationFailure, outcome.failure)
        assertEquals("activation", outcome.failureStage)
        assertTrue(outcome.targetActivationAttempted)
        assertTrue(outcome.restored)
    }
}
