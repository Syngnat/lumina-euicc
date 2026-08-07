package im.angry.openeuicc.ui

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import im.angry.openeuicc.common.R
import im.angry.openeuicc.core.EuiccChannelManager
import im.angry.openeuicc.util.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * A fragment to handle USB reader-specific permission flow. If/after
 * permission is granted, this fragment simply calls back to MainActivity
 * to instantiate the corresponding EuiccManagementFragment(s) for the USB
 * reader.
 *
 * Having this fragment allows MainActivity to be (mostly) agnostic
 * of the underlying implementation of different types of channels.
 * When permission is granted, this fragment will simply load
 * EuiccManagementFragment using its own childFragmentManager.
 *
 * Note that for now we assume there will only be one USB card reader
 * device. This is also an implicit assumption in EuiccChannelManager.
 */
class UsbCcidReaderPermissionFragment : Fragment(), OpenEuiccContextMarker {
    companion object {
        const val ACTION_USB_PERMISSION = "im.angry.openeuicc.USB_PERMISSION"
    }

    private val euiccChannelManager: EuiccChannelManager by lazy {
        (requireActivity() as MainActivity).euiccChannelManager
    }

    private val usbManager: UsbManager by lazy {
        requireContext().getSystemService(Context.USB_SERVICE) as UsbManager
    }

    private val usbPermissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_USB_PERMISSION) {
                if (usbDevice != null && usbManager.hasPermission(usbDevice)) {
                    lifecycleScope.launch(Dispatchers.Main) {
                        tryLoadUsbChannel()
                    }
                }
            }
        }
    }

    private lateinit var usbPendingIntent: PendingIntent

    private lateinit var text: TextView
    private lateinit var permissionButton: Button
    private lateinit var loadingProgress: View

    private var usbDevice: UsbDevice? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_usb_ccid_reader, container, false)

        text = view.requireViewById(R.id.usb_reader_text)
        permissionButton = view.requireViewById(R.id.usb_grant_permission)
        loadingProgress = view.requireViewById(R.id.loading)

        permissionButton.setOnClickListener {
            usbManager.requestPermission(usbDevice, usbPendingIntent)
        }

        return view
    }

    @SuppressLint("UnspecifiedRegisterReceiverFlag", "WrongConstant")
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        usbPendingIntent = PendingIntent.getBroadcast(
            requireContext(), 0,
            Intent(ACTION_USB_PERMISSION), PendingIntent.FLAG_IMMUTABLE
        )
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requireContext().registerReceiver(
                usbPermissionReceiver,
                filter,
                Context.RECEIVER_EXPORTED
            )
        } else {
            requireContext().registerReceiver(usbPermissionReceiver, filter)
        }

        lifecycleScope.launch(Dispatchers.Main) {
            tryLoadUsbChannel()
        }
    }

    override fun onDetach() {
        super.onDetach()
        try {
            requireContext().unregisterReceiver(usbPermissionReceiver)
        } catch (_: Exception) {
            // ignore
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            requireContext().unregisterReceiver(usbPermissionReceiver)
        } catch (_: Exception) {
            // ignore
        }
    }

    private suspend fun tryLoadUsbChannel() {
        text.visibility = View.GONE
        permissionButton.visibility = View.GONE
        loadingProgress.visibility = View.VISIBLE

        val (device, canOpen) = withContext(Dispatchers.IO) {
            euiccChannelManager.tryOpenUsbEuiccChannel()
        }

        usbDevice = device

        if (device != null && !canOpen && !usbManager.hasPermission(device)) {
            loadingProgress.visibility = View.GONE
            text.text = getString(R.string.usb_permission_needed)
            text.visibility = View.VISIBLE
            permissionButton.visibility = View.VISIBLE
        } else if (device != null && canOpen) {
            val seIds = withContext(Dispatchers.IO) {
                euiccChannelManager.flowEuiccSecureElements(EuiccChannelManager.USB_CHANNEL_ID, 0).toList()
            }
            (requireActivity() as MainActivity).instantiateUsbTabs(seIds)
        } else {
            loadingProgress.visibility = View.GONE
            text.text = getString(R.string.usb_failed)
            text.visibility = View.VISIBLE
            permissionButton.visibility = View.GONE
        }
    }
}
