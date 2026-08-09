package top.syngnat.lumina.euicc

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.TelephonyNetworkSpecifier
import android.os.Build
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout

internal class MicroDataKeepAliveException(
    val failureCode: String,
    cause: Throwable? = null,
) : Exception(failureCode, cause)

/**
 * Requests a cellular Network for one exact active subscription and performs
 * one bodyless HTTPS request through that Network. It never changes the
 * device-wide default data subscription or global mobile-data setting.
 */
internal class MicroDataNetworkSupport(
    private val context: Context,
) {
    companion object {
        const val MAX_RESPONSE_BODY_BYTES = 1_024
        private const val SUBSCRIPTION_WAIT_TIMEOUT_MILLIS = 30_000L
        private const val NETWORK_REQUEST_TIMEOUT_MILLIS = 30_000
        private const val HTTP_TIMEOUT_MILLIS = 15_000
        private const val SUBSCRIPTION_POLL_MILLIS = 500L
        private const val PROBE_URL = "https://github.com/Syngnat/lumina-euicc"
    }

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val subscriptionManager =
        context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager

    fun hasPhoneStatePermission(): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) ==
            PackageManager.PERMISSION_GRANTED

    fun activeSubscriptionId(slotId: Int, portId: Int): Int? {
        if (!hasPhoneStatePermission()) return null
        return selectSubscription(activeSubscriptions(), slotId, portId, excludedSubscriptionId = null)
            ?.subscriptionId
    }

    suspend fun probe(
        slotId: Int,
        portId: Int,
        excludedSubscriptionId: Int?,
    ): MicroDataProbeResult {
        if (!hasPhoneStatePermission()) {
            throw MicroDataKeepAliveException("permissionDenied")
        }
        val subscription = waitForSubscription(slotId, portId, excludedSubscriptionId)
        val lease = requestCellularNetwork(subscription.subscriptionId)
        try {
            return performHeadRequest(lease.network)
        } finally {
            lease.close()
        }
    }

    private suspend fun waitForSubscription(
        slotId: Int,
        portId: Int,
        excludedSubscriptionId: Int?,
    ): SubscriptionInfo =
        try {
            withTimeout(SUBSCRIPTION_WAIT_TIMEOUT_MILLIS) {
                while (true) {
                    val match = selectSubscription(
                        activeSubscriptions(),
                        slotId,
                        portId,
                        excludedSubscriptionId,
                    )
                    if (match != null) return@withTimeout match
                    delay(SUBSCRIPTION_POLL_MILLIS)
                }
                error("unreachable")
            }
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: SecurityException) {
            throw MicroDataKeepAliveException("permissionDenied", error)
        } catch (error: Exception) {
            throw MicroDataKeepAliveException("subscriptionUnavailable", error)
        }

    private fun activeSubscriptions(): List<SubscriptionInfo> =
        subscriptionManager.activeSubscriptionInfoList.orEmpty()

    private fun selectSubscription(
        subscriptions: List<SubscriptionInfo>,
        slotId: Int,
        portId: Int,
        excludedSubscriptionId: Int?,
    ): SubscriptionInfo? {
        val byId = subscriptions.associateBy { it.subscriptionId }
        val selected = selectMicroDataSubscription(
            candidates = subscriptions.map { info ->
                MicroDataSubscriptionCandidate(
                    slotId = info.simSlotIndex,
                    portId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        info.portIndex
                    } else {
                        0
                    },
                    subscriptionId = info.subscriptionId,
                )
            },
            targetSlotId = slotId,
            targetPortId = portId,
            excludedSubscriptionId = excludedSubscriptionId,
            matchPort = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU,
        )
        return selected?.subscriptionId?.let(byId::get)
    }

    private suspend fun requestCellularNetwork(subscriptionId: Int): NetworkLease {
        val builder = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            builder.setNetworkSpecifier(
                TelephonyNetworkSpecifier.Builder()
                    .setSubscriptionId(subscriptionId)
                    .build(),
            )
        } else {
            @Suppress("DEPRECATION")
            builder.setNetworkSpecifier(subscriptionId.toString())
        }
        val request = builder.build()

        return try {
            suspendCancellableCoroutine { continuation ->
                val released = AtomicBoolean(false)
                lateinit var callback: ConnectivityManager.NetworkCallback

                fun releaseCallback() {
                    if (released.compareAndSet(false, true)) {
                        try {
                            connectivityManager.unregisterNetworkCallback(callback)
                        } catch (_: IllegalArgumentException) {
                        }
                    }
                }

                callback = object : ConnectivityManager.NetworkCallback() {
                    override fun onAvailable(network: Network) {
                        if (!continuation.isActive) {
                            releaseCallback()
                            return
                        }
                        continuation.resume(NetworkLease(network, ::releaseCallback))
                    }

                    override fun onUnavailable() {
                        if (continuation.isActive) {
                            continuation.resumeWithException(
                                MicroDataKeepAliveException("cellularNetworkUnavailable"),
                            )
                        }
                        releaseCallback()
                    }
                }
                continuation.invokeOnCancellation { releaseCallback() }
                try {
                    connectivityManager.requestNetwork(
                        request,
                        callback,
                        NETWORK_REQUEST_TIMEOUT_MILLIS,
                    )
                } catch (error: Exception) {
                    releaseCallback()
                    if (continuation.isActive) {
                        continuation.resumeWithException(error)
                    }
                }
            }
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: MicroDataKeepAliveException) {
            throw error
        } catch (error: Exception) {
            throw MicroDataKeepAliveException("cellularNetworkUnavailable", error)
        }
    }

    private fun performHeadRequest(network: Network): MicroDataProbeResult {
        val connection = try {
            network.openConnection(URL(PROBE_URL)) as HttpURLConnection
        } catch (error: Exception) {
            throw MicroDataKeepAliveException("connectionFailed", error)
        }
        return try {
            connection.requestMethod = "HEAD"
            connection.instanceFollowRedirects = false
            connection.useCaches = false
            connection.connectTimeout = HTTP_TIMEOUT_MILLIS
            connection.readTimeout = HTTP_TIMEOUT_MILLIS
            connection.setRequestProperty("Accept-Encoding", "identity")
            val status = connection.responseCode
            if (status !in 100..599) {
                throw MicroDataKeepAliveException("invalidHttpResponse")
            }
            val responseStream = if (status >= 400) {
                connection.errorStream
            } else {
                connection.inputStream
            }
            val body = responseStream?.use {
                readResponseBodyWithinLimit(it, MAX_RESPONSE_BODY_BYTES)
            } ?: LimitedResponseRead(bytesRead = 0, limitExceeded = false)
            if (body.limitExceeded) {
                throw MicroDataKeepAliveException("responseLimitExceeded")
            }
            MicroDataProbeResult(
                httpStatus = status,
                responseBodyBytes = body.bytesRead,
            )
        } catch (error: MicroDataKeepAliveException) {
            throw error
        } catch (error: Exception) {
            throw MicroDataKeepAliveException("connectionFailed", error)
        } finally {
            connection.disconnect()
        }
    }

    private class NetworkLease(
        val network: Network,
        private val release: () -> Unit,
    ) : AutoCloseable {
        override fun close() = release()
    }
}
