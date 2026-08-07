package top.syngnat.lumina.euicc

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Thin native bridge for Lumina eUICC.
 *
 * Current implementation ships a **functional mock** so Flutter UI can be developed
 * without a physical eUICC. To reach EasyEUICC parity on device, replace the mock
 * store with OpenEUICC app-common / EuiccChannelManagerService (GPL-3).
 *
 * Channel: top.syngnat.lumina.euicc/bridge
 * Events:  top.syngnat.lumina.euicc/task_events
 */
class EuiccBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private val downloadCancelled = AtomicBoolean(false)
    private var pendingConfirm: ((Boolean) -> Unit)? = null

    // ---- Mock in-memory profile store (dev preview) ----
    private val mockProfiles = mutableListOf(
        hashMapOf<String, Any>(
            "iccid" to "8986000000000000001",
            "name" to "Travel Data",
            "provider" to "ExampleCarrier",
            "enabled" to true,
            "profileClass" to "operational",
            "seq" to 1,
        ),
        hashMapOf(
            "iccid" to "8986000000000000002",
            "name" to "Work SIM",
            "provider" to "CorpMobile",
            "enabled" to false,
            "profileClass" to "operational",
            "seq" to 2,
        ),
    )

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "top.syngnat.lumina.euicc/bridge")
        eventChannel = EventChannel(binding.binaryMessenger, "top.syngnat.lumina.euicc/task_events")
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        io.shutdownNow()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listChannels" -> result.success(
                mapOf(
                    "channels" to listOf(
                        mapOf(
                            "slotId" to 0,
                            "portId" to 0,
                            "seId" to "mock-se",
                            "label" to "Removable eUICC (mock)",
                            "type" to "omapi",
                        )
                    )
                )
            )

            "listProfiles" -> result.success(mapOf("profiles" to mockProfiles.toList()))

            "switchProfile" -> {
                val iccid = call.argument<String>("iccid")
                val enable = call.argument<Boolean>("enable") ?: false
                mockProfiles.forEach { p ->
                    if (enable) {
                        p["enabled"] = p["iccid"] == iccid
                    } else if (p["iccid"] == iccid) {
                        p["enabled"] = false
                    }
                }
                result.success(mapOf("ok" to true))
            }

            "deleteProfile" -> {
                val iccid = call.argument<String>("iccid")
                mockProfiles.removeAll { it["iccid"] == iccid }
                result.success(mapOf("ok" to true))
            }

            "renameProfile" -> {
                val iccid = call.argument<String>("iccid")
                val name = call.argument<String>("name") ?: return result.error("bad_args", "name required", null)
                mockProfiles.find { it["iccid"] == iccid }?.put("name", name)
                result.success(mapOf("ok" to true))
            }

            "downloadProfile" -> {
                val activationCode = call.argument<String>("activationCode")
                    ?: return result.error("bad_args", "activationCode required", null)
                downloadCancelled.set(false)
                io.execute { runMockDownload(activationCode) }
                result.success(mapOf("ok" to true, "started" to true))
            }

            "confirmDownload" -> {
                val cont = call.argument<Boolean>("continue") ?: false
                pendingConfirm?.invoke(cont)
                pendingConfirm = null
                result.success(mapOf("ok" to true))
            }

            "cancelDownload" -> {
                downloadCancelled.set(true)
                pendingConfirm?.invoke(false)
                pendingConfirm = null
                emit(mapOf("phase" to "cancelled", "done" to false, "error" to "cancelled"))
                result.success(mapOf("ok" to true))
            }

            "runCompatibilityCheck" -> result.success(
                mapOf(
                    "items" to listOf(
                        mapOf(
                            "title" to "OMAPI available",
                            "ok" to true,
                            "detail" to "Mock mode: OMAPI not probed on this build",
                        ),
                        mapOf(
                            "title" to "Removable eUICC channel",
                            "ok" to true,
                            "detail" to "Mock channel present for UI development",
                        ),
                        mapOf(
                            "title" to "ARA-M allowlist",
                            "ok" to false,
                            "detail" to "Wire real LPA + vendor ARA-M for production cards",
                        ),
                    )
                )
            )

            "getEuiccInfo" -> result.success(
                mapOf(
                    "eid" to "89049032000000000000000000000000",
                    "freeNonVolatileMemory" to 65536,
                    "freeVolatileMemory" to 8192,
                    "mock" to true,
                )
            )

            "memoryReset" -> {
                mockProfiles.clear()
                result.success(mapOf("ok" to true))
            }

            "listNotifications" -> result.success(
                mapOf(
                    "notifications" to listOf(
                        mapOf(
                            "title" to "Install complete (mock)",
                            "detail" to "No real notifications in mock mode",
                            "seq" to 1,
                        )
                    )
                )
            )

            "processNotification", "deleteNotification" -> result.success(mapOf("ok" to true))

            else -> result.notImplemented()
        }
    }

    private fun runMockDownload(activationCode: String) {
        emit(mapOf("phase" to "resolving", "progress" to 0.05))
        Thread.sleep(400)
        if (downloadCancelled.get()) return
        emit(
            mapOf(
                "phase" to "metadata",
                "progress" to 0.2,
                "provider" to "Mock SM-DP+",
                "name" to "Downloaded Profile",
                "needConfirmation" to true,
            )
        )
        val confirmed = waitForConfirm()
        if (!confirmed || downloadCancelled.get()) {
            emit(mapOf("phase" to "cancelled", "error" to "user_cancelled", "done" to false))
            return
        }
        for (p in listOf(0.4, 0.65, 0.85, 1.0)) {
            if (downloadCancelled.get()) {
                emit(mapOf("phase" to "cancelled", "error" to "cancelled", "done" to false))
                return
            }
            Thread.sleep(350)
            emit(mapOf("phase" to "downloading", "progress" to p, "provider" to "Mock SM-DP+", "name" to "Downloaded Profile"))
        }
        val iccid = "8986${System.currentTimeMillis().toString().takeLast(12)}"
        mockProfiles.add(
            hashMapOf(
                "iccid" to iccid,
                "name" to "Downloaded Profile",
                "provider" to "Mock SM-DP+",
                "enabled" to false,
                "profileClass" to "operational",
                "seq" to (mockProfiles.size + 1),
            )
        )
        emit(
            mapOf(
                "phase" to "done",
                "progress" to 1.0,
                "provider" to "Mock SM-DP+",
                "name" to "Downloaded Profile",
                "done" to true,
                "activationCode" to activationCode,
            )
        )
    }

    private fun waitForConfirm(): Boolean {
        val latch = java.util.concurrent.CountDownLatch(1)
        var value = false
        pendingConfirm = {
            value = it
            latch.countDown()
        }
        latch.await()
        return value
    }

    private fun emit(payload: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(payload) }
    }
}
