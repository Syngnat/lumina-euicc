package top.syngnat.lumina.euicc

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import im.angry.openeuicc.core.DefaultEuiccChannelManager
import im.angry.openeuicc.core.EuiccChannel
import im.angry.openeuicc.core.EuiccChannelManager
import im.angry.openeuicc.di.DefaultAppContainer
import im.angry.openeuicc.util.displayName
import im.angry.openeuicc.util.isEnabled
import im.angry.openeuicc.util.operational
import im.angry.openeuicc.util.switchProfile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import net.typeblog.lpac_jni.LocalProfileInfo
import net.typeblog.lpac_jni.ProfileClass
import net.typeblog.lpac_jni.ProfileDownloadCallback
import net.typeblog.lpac_jni.ProfileDownloadInput
import net.typeblog.lpac_jni.ProfileDownloadState
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Flutter bridge for EasyEUICC-aligned LPA operations.
 *
 * Prefers real OpenEUICC / lpac-jni stack. Falls back to in-memory mock when
 * no eUICC channel can be opened (emulator / no ARA-M card / missing perms).
 *
 * OpenEUICC is GPL-3 only; this file is part of the same derivative work.
 */
class EuiccBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "LuminaEuiccBridge"
        private const val METHOD = "top.syngnat.lumina.euicc/bridge"
        private const val EVENTS = "top.syngnat.lumina.euicc/task_events"
    }

    private lateinit var appContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val appContainer by lazy { DefaultAppContainer(appContext) }
    private val manager: EuiccChannelManager by lazy {
        DefaultEuiccChannelManager(appContainer, appContext)
    }

    private val useMockOnly = AtomicBoolean(false)
    private val downloadCancelled = AtomicBoolean(false)
    private val pendingConfirm = AtomicReference<((Boolean) -> Unit)?>(null)

    // Mock store for UI/dev when real LPA unavailable
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
        appContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD)
        eventChannel = EventChannel(binding.binaryMessenger, EVENTS)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        try {
            manager.invalidate()
        } catch (_: Exception) {
        }
        scope.cancel()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listChannels" -> async(result) { listChannels() }
            "listProfiles" -> async(result) {
                listProfiles(
                    call.int("slotId"),
                    call.int("portId"),
                    call.seId(),
                )
            }
            "switchProfile" -> async(result) {
                switchProfile(
                    call.int("slotId"),
                    call.int("portId"),
                    call.seId(),
                    call.str("iccid"),
                    call.bool("enable"),
                )
            }
            "deleteProfile" -> async(result) {
                deleteProfile(call.int("slotId"), call.int("portId"), call.seId(), call.str("iccid"))
            }
            "renameProfile" -> async(result) {
                renameProfile(
                    call.int("slotId"),
                    call.int("portId"),
                    call.seId(),
                    call.str("iccid"),
                    call.str("name"),
                )
            }
            "downloadProfile" -> {
                // start async download; progress via EventChannel
                downloadCancelled.set(false)
                scope.launch(Dispatchers.IO) {
                    try {
                        downloadProfile(
                            call.int("slotId"),
                            call.int("portId"),
                            call.seId(),
                            call.str("activationCode"),
                            call.argument<String>("confirmationCode"),
                            call.argument<String>("imei"),
                        )
                    } catch (e: Exception) {
                        Log.e(TAG, "download failed", e)
                        emit(
                            mapOf(
                                "phase" to "error",
                                "done" to false,
                                "error" to (e.message ?: e.toString()),
                            )
                        )
                    }
                }
                result.success(mapOf("ok" to true, "started" to true))
            }
            "confirmDownload" -> {
                val cont = call.argument<Boolean>("continue") ?: false
                pendingConfirm.getAndSet(null)?.invoke(cont)
                result.success(mapOf("ok" to true))
            }
            "cancelDownload" -> {
                downloadCancelled.set(true)
                pendingConfirm.getAndSet(null)?.invoke(false)
                emit(mapOf("phase" to "cancelled", "done" to false, "error" to "cancelled"))
                result.success(mapOf("ok" to true))
            }
            "runCompatibilityCheck" -> async(result) { runCompatibilityCheck() }
            "getEuiccInfo" -> async(result) {
                getEuiccInfo(call.int("slotId"), call.int("portId"), call.seId())
            }
            "memoryReset" -> async(result) {
                memoryReset(call.int("slotId"), call.int("portId"), call.seId())
            }
            "listNotifications" -> async(result) {
                listNotifications(call.int("slotId"), call.int("portId"), call.seId())
            }
            "processNotification" -> async(result) {
                processNotification(
                    call.int("slotId"),
                    call.int("portId"),
                    call.seId(),
                    (call.argument<Number>("seq") ?: 0L).toLong(),
                )
            }
            "deleteNotification" -> async(result) {
                deleteNotification(
                    call.int("slotId"),
                    call.int("portId"),
                    call.seId(),
                    (call.argument<Number>("seq") ?: 0L).toLong(),
                )
            }
            else -> result.notImplemented()
        }
    }

    private fun async(result: MethodChannel.Result, block: suspend () -> Any?) {
        scope.launch {
            try {
                val value = withContext(Dispatchers.IO) { block() }
                result.success(value)
            } catch (e: Exception) {
                Log.e(TAG, "method failed", e)
                result.error("euicc_error", e.message, e.toString())
            }
        }
    }

    private suspend fun listChannels(): Map<String, Any> {
        if (useMockOnly.get()) return mockChannels()
        return try {
            // Try USB once so removable readers appear when permitted.
            try {
                manager.tryOpenUsbEuiccChannel()
            } catch (e: Exception) {
                Log.w(TAG, "USB open skipped: ${e.message}")
            }
            val ports = manager.flowAllOpenEuiccPorts().toList()
            val channels = mutableListOf<Map<String, Any>>()
            for ((slotId, portId) in ports) {
                val ses = manager.flowEuiccSecureElements(slotId, portId).toList()
                for (se in ses.ifEmpty { listOf(EuiccChannel.SecureElementId.DEFAULT) }) {
                    try {
                        manager.withEuiccChannel(slotId, portId, se) { ch ->
                            channels.add(
                                mapOf(
                                    "slotId" to slotId,
                                    "portId" to portId,
                                    "seId" to se.id.toString(),
                                    "label" to "${ch.type} slot$slotId/port$portId/se${se.id}",
                                    "type" to if (slotId == EuiccChannelManager.USB_CHANNEL_ID) "usb" else "omapi",
                                    "logicalSlotId" to ch.logicalSlotId,
                                    "eid" to (ch.lpa.eID ?: ""),
                                )
                            )
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "channel open failed slot=$slotId port=$portId: ${e.message}")
                    }
                }
            }
            if (channels.isEmpty()) {
                Log.i(TAG, "No real eUICC channel; using mock")
                useMockOnly.set(true)
                mockChannels() + mapOf("mode" to "mock")
            } else {
                useMockOnly.set(false)
                mapOf("channels" to channels, "mode" to "real")
            }
        } catch (e: Exception) {
            Log.e(TAG, "listChannels real failed, mock fallback", e)
            useMockOnly.set(true)
            mockChannels() + mapOf("mode" to "mock", "fallbackReason" to (e.message ?: "error"))
        }
    }

    private fun mockChannels() = mapOf(
        "channels" to listOf(
            mapOf(
                "slotId" to 0,
                "portId" to 0,
                "seId" to "0",
                "label" to "Removable eUICC (mock)",
                "type" to "omapi",
            )
        )
    )

    private suspend fun listProfiles(slotId: Int, portId: Int, seId: EuiccChannel.SecureElementId): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) {
            return mapOf("profiles" to mockProfiles.toList(), "mode" to "mock")
        }
        return try {
            manager.withEuiccChannel(slotId, portId, seId) { ch ->
                val profiles = ch.lpa.profiles.operational.mapIndexed { index, p -> p.toMap(index + 1) }
                mapOf("profiles" to profiles, "mode" to "real")
            }
        } catch (e: Exception) {
            Log.w(TAG, "listProfiles fallback mock: ${e.message}")
            mapOf("profiles" to mockProfiles.toList(), "mode" to "mock", "fallbackReason" to (e.message ?: ""))
        }
    }

    private suspend fun switchProfile(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        iccid: String,
        enable: Boolean,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) {
            mockProfiles.forEach { p ->
                if (enable) p["enabled"] = p["iccid"] == iccid else if (p["iccid"] == iccid) p["enabled"] = false
            }
            return mapOf("ok" to true, "mode" to "mock")
        }
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch ->
            ch.lpa.switchProfile(iccid, enable = enable, refresh = true)
        }
        if (!ok) throw IllegalStateException("switchProfile failed for $iccid")
        return mapOf("ok" to true, "mode" to "real")
    }

    private suspend fun deleteProfile(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        iccid: String,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) {
            mockProfiles.removeAll { it["iccid"] == iccid }
            return mapOf("ok" to true, "mode" to "mock")
        }
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch -> ch.lpa.deleteProfile(iccid) }
        if (!ok) throw IllegalStateException("deleteProfile failed for $iccid")
        return mapOf("ok" to true, "mode" to "real")
    }

    private suspend fun renameProfile(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        iccid: String,
        name: String,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) {
            mockProfiles.find { it["iccid"] == iccid }?.put("name", name)
            return mapOf("ok" to true, "mode" to "mock")
        }
        manager.withEuiccChannel(slotId, portId, seId) { ch ->
            ch.lpa.setNickname(iccid, name)
        }
        return mapOf("ok" to true, "mode" to "real")
    }

    private suspend fun downloadProfile(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        activationCode: String,
        confirmationCode: String?,
        imei: String?,
    ) {
        if (isMockChannel(slotId, portId, seId)) {
            runMockDownload(activationCode)
            return
        }
        val (address, matchingId) = parseActivationCode(activationCode)
        val input = ProfileDownloadInput(
            address = address,
            matchingId = matchingId,
            imei = imei,
            confirmationCode = confirmationCode,
        )
        manager.withEuiccChannel(slotId, portId, seId) { ch ->
            ch.lpa.downloadProfile(input, ProfileDownloadCallback { state ->
                if (downloadCancelled.get()) return@ProfileDownloadCallback false
                when (state) {
                    is ProfileDownloadState.Preparing -> emit(mapOf("phase" to "preparing", "progress" to 0.0))
                    is ProfileDownloadState.Connecting -> emit(mapOf("phase" to "connecting", "progress" to 0.2))
                    is ProfileDownloadState.Authenticating -> emit(mapOf("phase" to "authenticating", "progress" to 0.4))
                    is ProfileDownloadState.ConfirmingDownload -> {
                        val meta = state.metadata
                        emit(
                            mapOf(
                                "phase" to "confirming",
                                "progress" to 0.5,
                                "provider" to (meta?.providerName ?: ""),
                                "name" to (meta?.name ?: ""),
                                "needConfirmation" to true,
                            )
                        )
                        // Wait for Flutter confirmDownload
                        waitConfirm()
                    }
                    is ProfileDownloadState.Downloading -> emit(mapOf("phase" to "downloading", "progress" to 0.7))
                    is ProfileDownloadState.Finalizing -> emit(mapOf("phase" to "finalizing", "progress" to 0.9))
                }
                !downloadCancelled.get()
            })
        }
        emit(mapOf("phase" to "done", "progress" to 1.0, "done" to true))
    }

    private fun waitConfirm(): Boolean {
        val latch = CountDownLatch(1)
        val value = AtomicBoolean(false)
        pendingConfirm.set {
            value.set(it)
            latch.countDown()
        }
        // 5 minutes max wait for user confirmation
        latch.await(5, TimeUnit.MINUTES)
        return value.get() && !downloadCancelled.get()
    }

    private fun runMockDownload(activationCode: String) {
        emit(mapOf("phase" to "resolving", "progress" to 0.05))
        Thread.sleep(300)
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
        if (!waitConfirm()) {
            emit(mapOf("phase" to "cancelled", "error" to "user_cancelled", "done" to false))
            return
        }
        for (p in listOf(0.4, 0.65, 0.85, 1.0)) {
            if (downloadCancelled.get()) {
                emit(mapOf("phase" to "cancelled", "error" to "cancelled", "done" to false))
                return
            }
            Thread.sleep(250)
            emit(mapOf("phase" to "downloading", "progress" to p, "provider" to "Mock SM-DP+", "name" to "Downloaded Profile"))
        }
        mockProfiles.add(
            hashMapOf(
                "iccid" to "8986${System.currentTimeMillis().toString().takeLast(12)}",
                "name" to "Downloaded Profile",
                "provider" to "Mock SM-DP+",
                "enabled" to false,
                "profileClass" to "operational",
                "seq" to (mockProfiles.size + 1),
            )
        )
        emit(mapOf("phase" to "done", "progress" to 1.0, "done" to true, "activationCode" to activationCode))
    }

    private suspend fun runCompatibilityCheck(): Map<String, Any> {
        val items = mutableListOf<Map<String, Any>>()
        // OMAPI class presence
        val omapiPresent = try {
            Class.forName("android.se.omapi.SEService")
            true
        } catch (_: Throwable) {
            false
        }
        items.add(
            mapOf(
                "title" to "OMAPI present",
                "ok" to omapiPresent,
                "detail" to if (omapiPresent) "android.se.omapi.SEService available" else "OMAPI missing on this device/API",
            )
        )
        return try {
            manager.tryOpenUsbEuiccChannel()
            val ports = manager.flowAllOpenEuiccPorts().toList()
            items.add(
                mapOf(
                    "title" to "eUICC ports discovered",
                    "ok" to ports.isNotEmpty(),
                    "detail" to if (ports.isEmpty()) "No OMAPI/USB eUICC channel opened" else ports.joinToString { "${it.first}/${it.second}" },
                )
            )
            var anyValid = false
            var eid = ""
            for ((slotId, portId) in ports) {
                val ses = manager.flowEuiccSecureElements(slotId, portId).toList()
                for (se in ses.ifEmpty { listOf(EuiccChannel.SecureElementId.DEFAULT) }) {
                    try {
                        manager.withEuiccChannel(slotId, portId, se) { ch ->
                            anyValid = anyValid || ch.lpa.valid
                            if (eid.isEmpty()) eid = ch.lpa.eID ?: ""
                        }
                    } catch (_: Exception) {
                    }
                }
            }
            items.add(
                mapOf(
                    "title" to "LPA channel valid",
                    "ok" to anyValid,
                    "detail" to if (anyValid) "Opened ISD-R successfully (EID=$eid)" else "Could not open a valid LPA channel (need ARA-M allowlisted card or USB reader)",
                )
            )
            items.add(
                mapOf(
                    "title" to "ARA-M / removable eUICC",
                    "ok" to anyValid,
                    "detail" to "EasyEUICC-class apps need the chip to grant ARA-M access (except USB CCID).",
                )
            )
            mapOf("items" to items, "mode" to if (anyValid) "real" else "partial")
        } catch (e: Exception) {
            items.add(
                mapOf(
                    "title" to "Probe error",
                    "ok" to false,
                    "detail" to (e.message ?: e.toString()),
                )
            )
            mapOf("items" to items, "mode" to "error")
        }
    }

    private suspend fun getEuiccInfo(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) {
            return mapOf(
                "eid" to "89049032000000000000000000000000",
                "freeNonVolatileMemory" to 65536,
                "freeVolatileMemory" to 8192,
                "mock" to true,
            )
        }
        return manager.withEuiccChannel(slotId, portId, seId) { ch ->
            val info2 = ch.lpa.euiccInfo2
            mapOf(
                "eid" to (ch.lpa.eID ?: ""),
                "valid" to ch.lpa.valid,
                "euiccInfo2" to (info2?.toString() ?: ""),
                "mock" to false,
            )
        }
    }

    private suspend fun memoryReset(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) {
            mockProfiles.clear()
            return mapOf("ok" to true, "mode" to "mock")
        }
        manager.withEuiccChannel(slotId, portId, seId) { ch -> ch.lpa.euiccMemoryReset() }
        return mapOf("ok" to true, "mode" to "real")
    }

    private suspend fun listNotifications(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) {
            return mapOf(
                "notifications" to listOf(
                    mapOf("title" to "Mock notification", "detail" to "No real LPA channel", "seq" to 1)
                ),
                "mode" to "mock",
            )
        }
        return manager.withEuiccChannel(slotId, portId, seId) { ch ->
            val list = ch.lpa.notifications.map { n ->
                mapOf(
                    "title" to "Notification #${n.seqNumber}",
                    "detail" to (n.profileManagementOperation?.toString() ?: n.toString()),
                    "seq" to n.seqNumber,
                    "iccid" to (n.iccid ?: ""),
                )
            }
            mapOf("notifications" to list, "mode" to "real")
        }
    }

    private suspend fun processNotification(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        seq: Long,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) return mapOf("ok" to true, "mode" to "mock")
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch -> ch.lpa.handleNotification(seq) }
        return mapOf("ok" to ok, "mode" to "real")
    }

    private suspend fun deleteNotification(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        seq: Long,
    ): Map<String, Any> {
        if (isMockChannel(slotId, portId, seId)) return mapOf("ok" to true, "mode" to "mock")
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch -> ch.lpa.deleteNotification(seq) }
        return mapOf("ok" to ok, "mode" to "real")
    }

    /**
     * Prefer real LPA always. Only force mock when the caller explicitly used
     * the synthetic mock channel id from listChannels fallback ("mock").
     * Real ops that fail still fall back to mock inside each method.
     */
    private fun isMockChannel(slotId: Int, portId: Int, seId: EuiccChannel.SecureElementId): Boolean {
        if (useMockOnly.get()) return true
        // listChannels mock uses seId "0" with label containing mock; we mark via useMockOnly
        // after a failed real enumeration. Otherwise always attempt real.
        return false
    }

    private fun parseActivationCode(raw: String): Pair<String, String?> {
        var token = raw.trim()
        if (token.startsWith("LPA:", ignoreCase = true)) token = token.drop(4)
        val parts = token.split('$').map { it.trim().ifBlank { null } }
        require(parts.getOrNull(0) == "1") { "Invalid activation code format (expect LPA:1\$...)" }
        val address = requireNotNull(parts.getOrNull(1)) { "SM-DP+ address required" }
        val matchingId = parts.getOrNull(2)
        return address to matchingId
    }

    private fun LocalProfileInfo.toMap(seq: Int): Map<String, Any> = mapOf(
        "iccid" to iccid,
        "name" to displayName,
        "provider" to providerName,
        "enabled" to isEnabled,
        "profileClass" to when (profileClass) {
            ProfileClass.Testing -> "testing"
            ProfileClass.Provisioning -> "provisioning"
            ProfileClass.Operational -> "operational"
        },
        "seq" to seq,
        "isdpAID" to isdpAID,
    )

    private fun MethodCall.int(key: String): Int =
        (argument<Number>(key) ?: 0).toInt()

    private fun MethodCall.bool(key: String): Boolean =
        argument<Boolean>(key) ?: false

    private fun MethodCall.str(key: String): String =
        argument<String>(key) ?: throw IllegalArgumentException("$key required")

    private fun MethodCall.seId(): EuiccChannel.SecureElementId {
        val raw = argument<Any>("seId")
        val id = when (raw) {
            is Number -> raw.toInt()
            is String -> raw.toIntOrNull() ?: 0
            else -> 0
        }
        return EuiccChannel.SecureElementId.createFromInt(id)
    }

    private fun emit(payload: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(payload) }
    }
}
