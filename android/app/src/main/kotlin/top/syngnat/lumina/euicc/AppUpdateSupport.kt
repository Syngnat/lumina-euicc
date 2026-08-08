package top.syngnat.lumina.euicc

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import java.security.MessageDigest

internal class AppUpdateSupport(private val context: Context) {
    private val packageManager: PackageManager
        get() = context.packageManager

    private val updateDirectory: File
        get() = File(context.cacheDir, "updates")

    fun runtimeInfo(): Map<String, Any> {
        val installed = installedPackageInfo()
        return mapOf(
            "versionName" to (installed.versionName ?: BuildConfig.VERSION_NAME),
            "versionCode" to installed.longVersionCode,
            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
        )
    }

    fun prepareUpdateFile(assetName: String): String {
        val root = updateDirectory.canonicalFile
        check((root.isDirectory || root.mkdirs()) && root.isDirectory) {
            "Update cache is unavailable"
        }
        root.listFiles()
            ?.filter { it.isFile && it.name != assetName }
            ?.forEach { it.delete() }
        val destination = File(root, assetName).canonicalFile
        check(destination.parentFile == root) { "Update destination is invalid" }
        return destination.absolutePath
    }

    fun verifyUpdate(
        path: String,
        expectedSha256: String,
        expectedSize: Long,
        expectedVersionName: String,
    ): File {
        val root = updateDirectory.canonicalFile
        val file = File(path)
        val canonicalFile = file.canonicalFile
        check(canonicalFile.parentFile == root && file.absoluteFile == canonicalFile) {
            "Update file is outside the application cache"
        }
        check(canonicalFile.isFile && canonicalFile.extension == "apk") {
            "Update APK is unavailable"
        }
        check(canonicalFile.length() == expectedSize) { "Update APK size does not match" }
        check(sha256(canonicalFile) == expectedSha256) { "Update APK digest does not match" }

        val archive = archivePackageInfo(canonicalFile)
            ?: error("Update APK metadata is unavailable")
        val installed = installedPackageInfo()
        check(archive.packageName == context.packageName) {
            "Update APK package does not match"
        }
        check(archive.versionName == expectedVersionName) {
            "Update APK version does not match"
        }
        check(archive.longVersionCode > installed.longVersionCode) {
            "Update APK is not newer than the installed app"
        }

        val installedSigners = signerSha256s(installed)
        val archiveSigners = signerSha256s(archive)
        check(installedSigners.isNotEmpty() && installedSigners == archiveSigners) {
            "Update APK signer set does not match"
        }
        return canonicalFile
    }

    fun canRequestPackageInstalls(): Boolean = packageManager.canRequestPackageInstalls()

    fun openInstallPermissionSettings() {
        val packageUri = Uri.parse("package:${context.packageName}")
        val appSettings = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, packageUri)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val intent = if (appSettings.resolveActivity(packageManager) != null) {
            appSettings
        } else {
            Intent(Settings.ACTION_SECURITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun launchInstaller(apk: File) {
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            apk,
        )
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (error: ActivityNotFoundException) {
            throw IllegalStateException("Android package installer is unavailable", error)
        }
    }

    private fun installedPackageInfo(): PackageInfo = if (Build.VERSION.SDK_INT >= 33) {
        packageManager.getPackageInfo(
            context.packageName,
            PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong()),
        )
    } else {
        @Suppress("DEPRECATION")
        packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
    }

    private fun archivePackageInfo(file: File): PackageInfo? = if (Build.VERSION.SDK_INT >= 33) {
        packageManager.getPackageArchiveInfo(
            file.absolutePath,
            PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong()),
        )
    } else {
        @Suppress("DEPRECATION")
        packageManager.getPackageArchiveInfo(
            file.absolutePath,
            PackageManager.GET_SIGNING_CERTIFICATES,
        )
    }

    private fun signerSha256s(packageInfo: PackageInfo): Set<String> =
        packageInfo.signingInfo
            ?.apkContentsSigners
            ?.map { signature ->
                MessageDigest.getInstance("SHA-256")
                    .digest(signature.toByteArray())
                    .toHexString()
            }
            ?.toSet()
            .orEmpty()

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().toHexString()
    }

    private fun ByteArray.toHexString(): String =
        joinToString("") { byte -> (byte.toInt() and 0xff).toString(16).padStart(2, '0') }
}
