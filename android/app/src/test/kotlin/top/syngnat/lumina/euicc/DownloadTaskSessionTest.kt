package top.syngnat.lumina.euicc

import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import net.typeblog.lpac_jni.ProfileDownloadState
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DownloadTaskSessionTest {
    private val executor = Executors.newFixedThreadPool(2)

    @After
    fun tearDown() {
        executor.shutdownNow()
    }

    @Test
    fun rejectingConfirmationStopsLpaAndEmitsOneCancelledTerminalEvent() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val confirmationShown = CountDownLatch(1)
        val session = DownloadTaskSession(
            emit = {
                events += it
                if (it["phase"] == "confirming") confirmationShown.countDown()
            },
            confirmationTimeoutMillis = 1_000,
            taskId = "task-reject",
        )

        val callbackResult = executor.submit<Boolean> {
            session.onLpaState(ProfileDownloadState.ConfirmingDownload(null))
        }

        assertTrue(confirmationShown.await(1, TimeUnit.SECONDS))
        assertTrue(session.respondToConfirmation(continueDownload = false))
        assertFalse(callbackResult.get(1, TimeUnit.SECONDS))

        // lpac-jni converts callback=false into ProfileDownloadException.
        session.completeFailure(IllegalStateException("lpac aborted"))
        session.completeSuccess()

        assertEquals(listOf("confirming", "cancelled"), events.map { it["phase"] })
        assertTrue(events.all { it["taskId"] == "task-reject" })
        assertEquals(1, events.count { it["done"] == true || it["error"] != null })
    }

    @Test
    fun acceptingConfirmationLetsLpaContinueAndEmitsDone() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val confirmationShown = CountDownLatch(1)
        val session = DownloadTaskSession(
            emit = {
                events += it
                if (it["phase"] == "confirming") confirmationShown.countDown()
            },
            confirmationTimeoutMillis = 1_000,
            taskId = "task-accept",
        )

        val callbackResult = executor.submit<Boolean> {
            session.onLpaState(ProfileDownloadState.ConfirmingDownload(null))
        }

        assertTrue(confirmationShown.await(1, TimeUnit.SECONDS))
        assertTrue(session.respondToConfirmation(continueDownload = true))
        assertTrue(callbackResult.get(1, TimeUnit.SECONDS))
        session.completeSuccess()

        assertEquals(listOf("confirming", "done"), events.map { it["phase"] })
        assertTrue(events.all { it["taskId"] == "task-accept" })
    }

    @Test
    fun cancellingWhileConfirmationIsPendingUnblocksTheLpaCallback() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val confirmationShown = CountDownLatch(1)
        val session = DownloadTaskSession(
            emit = {
                events += it
                if (it["phase"] == "confirming") confirmationShown.countDown()
            },
            confirmationTimeoutMillis = 10_000,
        )

        val callbackResult = executor.submit<Boolean> {
            session.onLpaState(ProfileDownloadState.ConfirmingDownload(null))
        }

        assertTrue(confirmationShown.await(1, TimeUnit.SECONDS))
        assertTrue(session.cancel())
        assertFalse(callbackResult.get(1, TimeUnit.SECONDS))
        session.completeFailure(IllegalStateException("lpac aborted"))

        assertEquals(listOf("confirming", "cancelling", "cancelled"), events.map { it["phase"] })
    }

    @Test
    fun cancellingAnActiveDownloadStopsAtNextCallbackAndEmitsOneCancelledTerminalEvent() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val session = DownloadTaskSession(events::add)

        assertTrue(session.onLpaState(ProfileDownloadState.Preparing()))
        assertTrue(session.cancel())
        assertFalse(session.onLpaState(ProfileDownloadState.Connecting()))

        session.completeFailure(IllegalStateException("lpac aborted"))
        session.completeFailure(IllegalStateException("duplicate"))

        assertEquals(listOf("preparing", "cancelling", "cancelled"), events.map { it["phase"] })
        assertEquals(1, events.count { it["done"] == true || it["error"] != null })
    }

    @Test
    fun concurrentTooLateCancellationCannotEmitCancellingAfterDone() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val cancellingEmissionStarted = CountDownLatch(1)
        val allowCancellingEmission = CountDownLatch(1)
        val completionStarted = CountDownLatch(1)
        val doneEmitted = CountDownLatch(1)
        val session = DownloadTaskSession(
            emit = { event ->
                if (event["phase"] == "cancelling") {
                    cancellingEmissionStarted.countDown()
                    check(allowCancellingEmission.await(1, TimeUnit.SECONDS))
                }
                events += event
                if (event["phase"] == "done") doneEmitted.countDown()
            },
        )

        val cancellation = executor.submit<Boolean> { session.cancel() }
        assertTrue(cancellingEmissionStarted.await(1, TimeUnit.SECONDS))
        val completion = executor.submit<Unit> {
            completionStarted.countDown()
            session.completeSuccess()
        }
        assertTrue(completionStarted.await(1, TimeUnit.SECONDS))

        try {
            assertFalse(doneEmitted.await(100, TimeUnit.MILLISECONDS))
        } finally {
            allowCancellingEmission.countDown()
        }
        assertTrue(cancellation.get(1, TimeUnit.SECONDS))
        completion.get(1, TimeUnit.SECONDS)

        assertEquals(listOf("cancelling", "done"), events.map { it["phase"] })
    }

    @Test
    fun cancellationCannotOvertakeAnInFlightProgressEmission() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val progressEmissionStarted = CountDownLatch(1)
        val allowProgressEmission = CountDownLatch(1)
        val cancellationReturned = CountDownLatch(1)
        val session = DownloadTaskSession(
            emit = { event ->
                if (event["phase"] == "preparing") {
                    progressEmissionStarted.countDown()
                    check(allowProgressEmission.await(1, TimeUnit.SECONDS))
                }
                events += event
            },
        )

        val progress = executor.submit<Boolean> {
            session.onLpaState(ProfileDownloadState.Preparing())
        }
        assertTrue(progressEmissionStarted.await(1, TimeUnit.SECONDS))
        val cancellation = executor.submit<Boolean> {
            session.cancel().also { cancellationReturned.countDown() }
        }

        try {
            assertFalse(cancellationReturned.await(100, TimeUnit.MILLISECONDS))
        } finally {
            allowProgressEmission.countDown()
        }
        assertTrue(progress.get(1, TimeUnit.SECONDS))
        assertTrue(cancellation.get(1, TimeUnit.SECONDS))

        session.completeSuccess()
        assertEquals(listOf("preparing", "cancelling", "done"), events.map { it["phase"] })
    }

    @Test
    fun cancellationAfterTerminalIsRejectedWithoutAnotherEvent() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val session = DownloadTaskSession(events::add)

        session.completeSuccess()

        assertFalse(session.cancel())
        assertEquals(listOf("done"), events.map { it["phase"] })
    }

    @Test
    fun cancellationDuringAnUninterruptibleTailReportsTheLpaSuccessTruthfully() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val session = DownloadTaskSession(events::add)

        assertTrue(session.cancel())
        session.completeSuccess()
        session.completeFailure(IllegalStateException("late error"))

        assertEquals(listOf("cancelling", "done"), events.map { it["phase"] })
        assertEquals(1, events.count { it["done"] == true || it["error"] != null })
    }

    @Test
    fun cancellationDuringAnUninterruptibleTailReportsTheLpaFailureTruthfully() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val session = DownloadTaskSession(events::add)

        assertTrue(session.cancel())
        session.completeFailure(IllegalStateException("native failure"))
        session.completeSuccess()

        assertEquals(listOf("cancelling", "error"), events.map { it["phase"] })
        assertEquals("native failure", events.last()["error"])
        assertEquals(1, events.count { it["done"] == true || it["error"] != null })
    }

    @Test
    fun confirmationTimeoutStopsLpaAndRejectsLateResponses() {
        val events = CopyOnWriteArrayList<Map<String, Any?>>()
        val session = DownloadTaskSession(
            emit = events::add,
            confirmationTimeoutMillis = 10,
        )

        assertFalse(session.onLpaState(ProfileDownloadState.ConfirmingDownload(null)))
        assertFalse(session.respondToConfirmation(continueDownload = true))
        session.completeFailure(IllegalStateException("lpac aborted"))

        assertEquals(listOf("confirming", "cancelled"), events.map { it["phase"] })
    }
}
