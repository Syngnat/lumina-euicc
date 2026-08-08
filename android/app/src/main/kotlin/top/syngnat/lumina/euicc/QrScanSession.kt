package top.syngnat.lumina.euicc

import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicReference

/** Keeps the single outstanding native QR scan result lifecycle-safe. */
internal class QrScanSession {
    private val pending = AtomicReference<MethodChannel.Result?>(null)

    fun begin(result: MethodChannel.Result): Boolean = pending.compareAndSet(null, result)

    fun complete(contents: String?): Boolean {
        val result = pending.getAndSet(null) ?: return false
        result.success(contents)
        return true
    }

    fun fail(code: String, message: String): Boolean {
        val result = pending.getAndSet(null) ?: return false
        result.error(code, message, null)
        return true
    }
}
