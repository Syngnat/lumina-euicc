package top.syngnat.lumina.euicc

import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class QrScanSessionTest {
    @Test
    fun onlyOneScanCanBeActiveAndItsResultIsDeliveredOnce() {
        val session = QrScanSession()
        val first = RecordingResult()
        val overlapping = RecordingResult()

        assertTrue(session.begin(first))
        assertFalse(session.begin(overlapping))
        assertTrue(session.complete("LPA:1\$scan.example.com\$matching-id"))
        assertFalse(session.complete("duplicate"))

        assertEquals("LPA:1\$scan.example.com\$matching-id", first.successValue)
        assertEquals(1, first.terminalCalls)
        assertNull(overlapping.successValue)
        assertEquals(0, overlapping.terminalCalls)
    }

    @Test
    fun cancellingReturnsNullAndAllowsALaterScan() {
        val session = QrScanSession()
        val cancelled = RecordingResult()
        val later = RecordingResult()

        assertTrue(session.begin(cancelled))
        assertTrue(session.complete(null))
        assertEquals(1, cancelled.terminalCalls)
        assertNull(cancelled.successValue)
        assertTrue(session.begin(later))
        assertTrue(session.complete("next"))
        assertEquals("next", later.successValue)
    }

    @Test
    fun failureIsTerminalAndAResultArrivingAfterwardsIsIgnored() {
        val session = QrScanSession()
        val result = RecordingResult()

        assertTrue(session.begin(result))
        assertTrue(session.fail("qr_scan_interrupted", "QR scan was interrupted"))
        assertFalse(session.complete("late"))

        assertEquals("qr_scan_interrupted", result.errorCode)
        assertEquals("QR scan was interrupted", result.errorMessage)
        assertEquals(1, result.terminalCalls)
        assertNull(result.successValue)
    }
}

private class RecordingResult : MethodChannel.Result {
    var successValue: Any? = null
    var errorCode: String? = null
    var errorMessage: String? = null
    var terminalCalls = 0

    override fun success(result: Any?) {
        successValue = result
        terminalCalls++
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        this.errorCode = errorCode
        this.errorMessage = errorMessage
        terminalCalls++
    }

    override fun notImplemented() {
        terminalCalls++
    }
}
