package top.syngnat.lumina.euicc

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.se.omapi.Reader
import android.util.Log
import com.journeyapps.barcodescanner.ScanIntentResult
import com.journeyapps.barcodescanner.ScanOptions
import im.angry.openeuicc.core.DefaultEuiccChannelManager
import im.angry.openeuicc.core.EuiccChannel
import im.angry.openeuicc.core.EuiccChannelManager
import im.angry.openeuicc.di.DefaultAppContainer
import im.angry.openeuicc.util.EUICC_DEFAULT_ISDR_AID
import im.angry.openeuicc.util.connectSEService
import im.angry.openeuicc.util.decodeHex
import im.angry.openeuicc.util.displayName
import im.angry.openeuicc.util.isEnabled
import im.angry.openeuicc.util.operational
import im.angry.openeuicc.util.parseIsdrAidList
import im.angry.openeuicc.util.switchProfile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import net.typeblog.lpac_jni.LocalProfileInfo
import net.typeblog.lpac_jni.ProfileClass
import net.typeblog.lpac_jni.ProfileDownloadCallback
import net.typeblog.lpac_jni.ProfileDownloadInput
import java.util.concurrent.CancellationException
import java.util.concurrent.atomic.AtomicReference

/**
 * Flutter bridge for removable eUICC LPA operations.
 *
 * Prefers the real OpenEUICC / lpac-jni stack. Debug builds can fall back to
 * an in-memory mock; release builds report an unavailable real channel.
 *
 * OpenEUICC is GPL-3 only; this file is part of the same derivative work.
 */
class EuiccBridgePlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.ActivityResultListener {
    companion object {
        private const val TAG = "LuminaEuiccBridge"
        private const val METHOD = "top.syngnat.lumina.euicc/bridge"
        private const val EVENTS = "top.syngnat.lumina.euicc/task_events"
        private const val QR_SCAN_REQUEST_CODE = 0x4C51
    }

    private lateinit var appContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val appContainer by lazy { DefaultAppContainer(appContext) }
    private val appUpdateSupport by lazy { AppUpdateSupport(appContext) }
    private val simToolkitSupport = SimToolkitSupport()
    private val manager: EuiccChannelManager by lazy {
        DefaultEuiccChannelManager(appContainer, appContext)
    }

    private val activeDownload = AtomicReference<DownloadTaskSession?>(null)
    private val qrScanSession = QrScanSession()
    private val channelDiscovery by lazy {
        BridgeChannelDiscovery(
            discoverRealChannels = ::discoverRealChannels,
            allowMock = BuildConfig.DEBUG,
            onProbeError = { Log.e(TAG, "listChannels real probe failed", it) },
        )
    }

    // Mock store for UI/dev when real LPA unavailable
    private val mockProfiles: MutableList<MutableMap<String, Any>> = mutableListOf(
        mutableMapOf<String, Any>(
            "iccid" to "mock-profile-1",
            "name" to "Mock Travel Data",
            "provider" to "Mock carrier",
            "enabled" to true,
            "profileClass" to "operational",
            "seq" to 1,
        ),
        mutableMapOf<String, Any>(
            "iccid" to "mock-profile-2",
            "name" to "Mock Work SIM",
            "provider" to "Mock carrier",
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
        detachActivity(interruptScan = true)
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        activeDownload.getAndSet(null)?.cancel()
        try {
            manager.invalidate()
        } catch (_: Exception) {
        }
        scope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity(interruptScan = false)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity(interruptScan = true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != QR_SCAN_REQUEST_CODE) return false
        val contents = ScanIntentResult.parseActivityResult(resultCode, data)
            .contents
            ?.takeIf(String::isNotBlank)
        qrScanSession.complete(contents)
        return true
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanQr" -> startQrScan(result)
            "openSimToolkit" -> {
                val launched = simToolkitSupport.open(activityBinding?.activity)
                result.success(mapOf("status" to if (launched) "launched" else "unavailable"))
            }
            "getAppRuntimeInfo" -> async(result) { appUpdateSupport.runtimeInfo() }
            "prepareUpdateFile" -> async(result) {
                val assetName = requireUpdateAssetName(call.argument<Any>("assetName"))
                mapOf("path" to appUpdateSupport.prepareUpdateFile(assetName))
            }
            "verifyAndInstallUpdate" -> async(result) {
                verifyAndInstallUpdate(
                    path = requireStringArgument("path", call.argument<Any>("path")),
                    expectedSha256 = requireUpdateSha256(call.argument<Any>("expectedSha256")),
                    expectedSize = requireUpdateSize(call.argument<Any>("expectedSize")),
                    expectedVersionName = requireUpdateVersionName(
                        call.argument<Any>("expectedVersionName"),
                    ),
                )
            }
            "openInstallPermissionSettings" -> {
                try {
                    appUpdateSupport.openInstallPermissionSettings()
                    result.success(mapOf("ok" to true))
                } catch (e: Exception) {
                    Log.e(TAG, "opening install permission settings failed", e)
                    result.error("update_settings_unavailable", "Install settings are unavailable", null)
                }
            }
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
                val request = validated(result) { call.downloadRequest() } ?: return
                val session = DownloadTaskSession(::emit)
                if (!activeDownload.compareAndSet(null, session)) {
                    result.error("download_busy", "A profile download is already running", null)
                    return
                }
                scope.launch(Dispatchers.IO) {
                    try {
                        downloadProfile(request, session)
                        session.completeSuccess()
                    } catch (e: Exception) {
                        Log.e(TAG, "download failed", e)
                        session.completeFailure(e)
                    } finally {
                        activeDownload.compareAndSet(session, null)
                    }
                }
                result.success(mapOf("ok" to true, "started" to true, "taskId" to session.taskId))
            }
            "confirmDownload" -> {
                val args = validated(result) {
                    requireStringArgument("taskId", call.argument<Any>("taskId")) to
                        requireBooleanArgument("continue", call.argument<Any>("continue"))
                } ?: return
                val session = activeDownload.get()
                val handled = session != null && session.taskId == args.first &&
                    session.respondToConfirmation(args.second)
                result.success(mapOf("ok" to handled))
            }
            "cancelDownload" -> {
                val taskId = validated(result) {
                    requireStringArgument("taskId", call.argument<Any>("taskId"))
                } ?: return
                val session = activeDownload.get()
                val handled = session != null && session.taskId == taskId && session.cancel()
                result.success(mapOf("ok" to handled))
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
                    call.long("seq"),
                )
            }
            "deleteNotification" -> async(result) {
                deleteNotification(
                    call.int("slotId"),
                    call.int("portId"),
                    call.seId(),
                    call.long("seq"),
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

    private suspend fun listChannels(): Map<String, Any> = channelDiscovery.listChannels()

    private suspend fun verifyAndInstallUpdate(
        path: String,
        expectedSha256: String,
        expectedSize: Long,
        expectedVersionName: String,
    ): Map<String, Any> {
        val apk = appUpdateSupport.verifyUpdate(
            path = path,
            expectedSha256 = expectedSha256,
            expectedSize = expectedSize,
            expectedVersionName = expectedVersionName,
        )
        if (!appUpdateSupport.canRequestPackageInstalls()) {
            return mapOf("status" to "permissionRequired")
        }
        withContext(Dispatchers.Main) { appUpdateSupport.launchInstaller(apk) }
        return mapOf("status" to "launched")
    }

    private fun shouldUseMockChannel(slotId: Int): Boolean {
        if (!isMockChannel(slotId)) return false
        check(BuildConfig.DEBUG) { "Mock channels are unavailable in release builds" }
        return true
    }

    private suspend fun discoverRealChannels(): List<Map<String, Any>> {
        // flowAllOpenEuiccPorts also probes USB; this first attempt only preserves diagnostic logging.
        try {
            manager.tryOpenUsbEuiccChannel()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (e: Exception) {
            Log.w(TAG, "USB open skipped: ${e.message}")
        }

        val channels = mutableListOf<Map<String, Any>>()
        for ((slotId, portId) in manager.flowAllOpenEuiccPorts().toList()) {
            val secureElements = manager.flowEuiccSecureElements(slotId, portId).toList()
            for (se in secureElements.ifEmpty { listOf(EuiccChannel.SecureElementId.DEFAULT) }) {
                try {
                    manager.withEuiccChannel(slotId, portId, se) { channel ->
                        channels.add(
                            mapOf(
                                "slotId" to slotId,
                                "portId" to portId,
                                "seId" to se.id.toString(),
                                "label" to "${channel.type} slot$slotId/port$portId/se${se.id}",
                                "type" to if (slotId == EuiccChannelManager.USB_CHANNEL_ID) "usb" else "omapi",
                                "logicalSlotId" to channel.logicalSlotId,
                            )
                        )
                    }
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (e: Exception) {
                    Log.w(TAG, "channel open failed slot=$slotId port=$portId: ${e.message}")
                }
            }
        }
        if (channels.isEmpty()) Log.i(TAG, "No real eUICC channel discovered")
        return channels
    }

    private suspend fun listProfiles(slotId: Int, portId: Int, seId: EuiccChannel.SecureElementId): Map<String, Any> {
        return routeChannel(
            slotId = slotId,
            mock = { mapOf("profiles" to mockProfiles.toList(), "mode" to "mock") },
            real = {
                manager.withEuiccChannel(slotId, portId, seId) { ch ->
                    val profiles = ch.lpa.profiles.operational.mapIndexed { index, p -> p.toMap(index + 1) }
                    mapOf("profiles" to profiles, "mode" to "real")
                }
            },
        )
    }

    private suspend fun switchProfile(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        iccid: String,
        enable: Boolean,
    ): Map<String, Any> {
        if (shouldUseMockChannel(slotId)) {
            mockProfiles.forEach { p ->
                if (enable) p["enabled"] = p["iccid"] == iccid else if (p["iccid"] == iccid) p["enabled"] = false
            }
            return mapOf("ok" to true, "mode" to "mock")
        }
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch ->
            ch.lpa.switchProfile(iccid, enable = enable, refresh = true)
        }
        if (!ok) throw IllegalStateException("switchProfile failed")
        return mapOf("ok" to true, "mode" to "real")
    }

    private suspend fun deleteProfile(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        iccid: String,
    ): Map<String, Any> {
        if (shouldUseMockChannel(slotId)) {
            mockProfiles.removeAll { it["iccid"] == iccid }
            return mapOf("ok" to true, "mode" to "mock")
        }
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch -> ch.lpa.deleteProfile(iccid) }
        if (!ok) throw IllegalStateException("deleteProfile failed")
        return mapOf("ok" to true, "mode" to "real")
    }

    private suspend fun renameProfile(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        iccid: String,
        name: String,
    ): Map<String, Any> {
        if (shouldUseMockChannel(slotId)) {
            mockProfiles.find { it["iccid"] == iccid }?.put("name", name)
            return mapOf("ok" to true, "mode" to "mock")
        }
        manager.withEuiccChannel(slotId, portId, seId) { ch ->
            ch.lpa.setNickname(iccid, name)
        }
        return mapOf("ok" to true, "mode" to "real")
    }

    private suspend fun downloadProfile(request: ValidatedDownloadRequest, session: DownloadTaskSession) {
        if (shouldUseMockChannel(request.slotId)) {
            runMockDownload(session)
            return
        }
        val input = ProfileDownloadInput(
            address = request.address,
            matchingId = request.matchingId,
            imei = request.imei,
            confirmationCode = request.confirmationCode,
        )
        manager.withEuiccChannel(
            request.slotId,
            request.portId,
            EuiccChannel.SecureElementId.createFromInt(request.seId),
        ) { ch ->
            ch.lpa.downloadProfile(input, ProfileDownloadCallback { state -> session.onLpaState(state) })
        }
    }

    @Suppress("DEPRECATION")
    private fun startQrScan(result: MethodChannel.Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("qr_scan_unavailable", "QR scanner requires a foreground activity", null)
            return
        }
        if (!qrScanSession.begin(result)) {
            result.error("qr_scan_busy", "A QR scan is already running", null)
            return
        }
        try {
            val options = ScanOptions()
                .setDesiredBarcodeFormats(ScanOptions.QR_CODE)
                .setOrientationLocked(false)
                .setBeepEnabled(false)
                .setBarcodeImageEnabled(false)
            activity.startActivityForResult(
                options.createScanIntent(activity),
                QR_SCAN_REQUEST_CODE,
            )
        } catch (error: Exception) {
            Log.e(TAG, "Unable to start QR scanner", error)
            qrScanSession.fail("qr_scan_failed", "Unable to start QR scanner")
        }
    }

    private fun attachActivity(binding: ActivityPluginBinding) {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    private fun detachActivity(interruptScan: Boolean) {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        if (interruptScan) {
            qrScanSession.fail("qr_scan_interrupted", "QR scan was interrupted")
        }
    }

    private fun runMockDownload(session: DownloadTaskSession) {
        if (!session.emitProgress(mapOf("phase" to "resolving", "progress" to 0.05))) return
        Thread.sleep(300)
        if (!session.continueWork()) return
        if (
            !session.awaitConfirmation(
                mapOf(
                    "phase" to "metadata",
                    "progress" to 0.2,
                    "provider" to "Mock SM-DP+",
                    "name" to "Downloaded Profile",
                    "needConfirmation" to true,
                )
            )
        ) return
        for (p in listOf(0.4, 0.65, 0.85, 1.0)) {
            if (!session.continueWork()) return
            Thread.sleep(250)
            if (!session.emitProgress(
                    mapOf(
                        "phase" to "downloading",
                        "progress" to p,
                        "provider" to "Mock SM-DP+",
                        "name" to "Downloaded Profile",
                    )
                )) return
        }
        if (!session.continueWork()) return
        mockProfiles.add(
            mutableMapOf<String, Any>(
                "iccid" to "mock-${System.currentTimeMillis()}",
                "name" to "Downloaded Profile",
                "provider" to "Mock SM-DP+",
                "enabled" to false,
                "profileClass" to "operational",
                "seq" to (mockProfiles.size + 1),
            )
        )
    }

    private suspend fun runCompatibilityCheck(): Map<String, Any> {
        val omapiPresent = try {
            Class.forName("android.se.omapi.SEService")
            true
        } catch (_: Throwable) {
            false
        }

        var omapiServiceFailureType: String? = null
        val slotProbes = if (omapiPresent) {
            try {
                probeOmapiSlots()
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: Exception) {
                omapiServiceFailureType = safeFailureType(error)
                emptyList()
            }
        } else {
            emptyList()
        }

        var openPorts = emptyList<Pair<Int, Int>>()
        val lpaPortFailures = mutableListOf<LpaPortProbeFailure>()
        var lpaProbeFailureType: String? = null
        var anyValid = false
        try {
            openPorts = manager.flowAllOpenEuiccPorts().toList()
            for ((slotId, portId) in openPorts) {
                val secureElements = manager.flowEuiccSecureElements(slotId, portId).toList()
                for (se in secureElements.ifEmpty { listOf(EuiccChannel.SecureElementId.DEFAULT) }) {
                    try {
                        manager.withEuiccChannel(slotId, portId, se) { channel ->
                            anyValid = anyValid || channel.lpa.valid
                        }
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (error: Exception) {
                        lpaPortFailures.add(
                            LpaPortProbeFailure(slotId, portId, safeFailureType(error))
                        )
                    }
                }
            }
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Exception) {
            lpaProbeFailureType = safeFailureType(error)
        }

        val items = buildCompatibilityDiagnostics(
            CompatibilityDiagnosticsInput(
                packageName = appContext.packageName,
                signingCertificateSha1s = signingCertificateSha1s(),
                omapiPresent = omapiPresent,
                deviceBrand = Build.BRAND,
                deviceName = Build.DEVICE,
                deviceModel = Build.MODEL,
                androidRelease = Build.VERSION.RELEASE,
                androidSdkInt = Build.VERSION.SDK_INT,
                omapiServiceFailureType = omapiServiceFailureType,
                slotProbes = slotProbes,
                openPorts = openPorts,
                lpaPortFailures = lpaPortFailures,
                lpaProbeFailureType = lpaProbeFailureType,
                lpaChannelValid = anyValid,
            )
        )
        val mode = when {
            anyValid -> "real"
            omapiServiceFailureType != null || lpaProbeFailureType != null -> "error"
            else -> "partial"
        }
        return mapOf("items" to items.map(CompatibilityDiagnosticItem::toMap), "mode" to mode)
    }

    private fun signingCertificateSha1s(): List<String> = try {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            appContext.packageManager.getPackageInfo(
                appContext.packageName,
                PackageManager.PackageInfoFlags.of(
                    PackageManager.GET_SIGNING_CERTIFICATES.toLong()
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            appContext.packageManager.getPackageInfo(
                appContext.packageName,
                PackageManager.GET_SIGNING_CERTIFICATES,
            )
        }
        packageInfo.signingInfo?.apkContentsSigners.orEmpty()
            .map { signature -> certificateSha1(signature.toByteArray()) }
            .distinct()
            .sorted()
    } catch (error: Exception) {
        Log.w(TAG, "Unable to read app signing certificate (${safeFailureType(error)})")
        emptyList()
    }

    private suspend fun probeOmapiSlots(): List<OmapiSlotProbe> {
        val service = connectSEService(appContext)
        try {
            check(service.isConnected) { "OMAPI service did not connect" }
            val isdrAids = parseIsdrAidList(
                appContainer.preferenceRepository.isdrAidListFlow.first()
            )
            return service.readers
                .filter { reader -> reader.name.startsWith("SIM") }
                .mapIndexed { index, reader ->
                    probeOmapiReader(
                        reader,
                        parseOmapiSlotId(reader.name, index),
                        isdrAids,
                    )
                }
        } finally {
            service.shutdown()
        }
    }

    private fun probeOmapiReader(
        reader: Reader,
        slotId: Int,
        isdrAids: List<ByteArray>,
    ): OmapiSlotProbe {
        var session: android.se.omapi.Session? = null
        return try {
            session = reader.openSession()
            var accessDenied = false
            var failureType: String? = null
            for (isdrAid in isdrAids.ifEmpty { listOf(EUICC_DEFAULT_ISDR_AID.decodeHex()) }) {
                try {
                    val channel = session.openLogicalChannel(isdrAid) ?: continue
                    try {
                        return OmapiSlotProbe(slotId, OmapiSlotProbeStatus.AUTHORIZED)
                    } finally {
                        channel.close()
                    }
                } catch (_: SecurityException) {
                    accessDenied = true
                } catch (_: NoSuchElementException) {
                    // This candidate AID is not present; continue with known vendor AIDs.
                } catch (error: Exception) {
                    if (failureType == null) failureType = safeFailureType(error)
                }
            }
            when {
                accessDenied -> OmapiSlotProbe(
                    slotId,
                    OmapiSlotProbeStatus.ACCESS_DENIED,
                    "SecurityException",
                )
                failureType != null -> OmapiSlotProbe(
                    slotId,
                    OmapiSlotProbeStatus.FAILED,
                    failureType,
                )
                else -> OmapiSlotProbe(slotId, OmapiSlotProbeStatus.ISDR_UNAVAILABLE)
            }
        } catch (error: Exception) {
            OmapiSlotProbe(
                slotId,
                OmapiSlotProbeStatus.FAILED,
                safeFailureType(error),
            )
        } finally {
            try {
                session?.close()
            } catch (_: Exception) {
            }
        }
    }

    private suspend fun getEuiccInfo(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
    ): Map<String, Any> {
        if (shouldUseMockChannel(slotId)) {
            return mapOf(
                "eid" to "mock",
                "freeNonVolatileMemory" to 0,
                "freeVolatileMemory" to 0,
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
        if (shouldUseMockChannel(slotId)) {
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
        if (shouldUseMockChannel(slotId)) {
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
        if (shouldUseMockChannel(slotId)) return mapOf("ok" to true, "mode" to "mock")
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch -> ch.lpa.handleNotification(seq) }
        return mapOf("ok" to ok, "mode" to "real")
    }

    private suspend fun deleteNotification(
        slotId: Int,
        portId: Int,
        seId: EuiccChannel.SecureElementId,
        seq: Long,
    ): Map<String, Any> {
        if (shouldUseMockChannel(slotId)) return mapOf("ok" to true, "mode" to "mock")
        val ok = manager.withEuiccChannel(slotId, portId, seId) { ch -> ch.lpa.deleteNotification(seq) }
        return mapOf("ok" to ok, "mode" to "real")
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
        requireIntArgument(key, argument<Any>(key))

    private fun MethodCall.long(key: String): Long =
        requireLongArgument(key, argument<Any>(key))

    private fun MethodCall.bool(key: String): Boolean =
        requireBooleanArgument(key, argument<Any>(key))

    private fun MethodCall.str(key: String): String =
        requireStringArgument(key, argument<Any>(key))

    private fun MethodCall.seId(): EuiccChannel.SecureElementId {
        return EuiccChannel.SecureElementId.createFromInt(requireSeIdArgument(argument<Any>("seId")))
    }

    private fun MethodCall.downloadRequest(): ValidatedDownloadRequest = validateDownloadRequest(
        slotId = argument<Any>("slotId"),
        portId = argument<Any>("portId"),
        seId = argument<Any>("seId"),
        activationCode = argument<Any>("activationCode"),
        confirmationCode = argument<Any>("confirmationCode"),
        imei = argument<Any>("imei"),
    )

    private fun <T : Any> validated(result: MethodChannel.Result, block: () -> T): T? = try {
        block()
    } catch (error: IllegalArgumentException) {
        result.error("invalid_arguments", error.message, null)
        null
    }

    private fun emit(payload: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(payload) }
    }
}
