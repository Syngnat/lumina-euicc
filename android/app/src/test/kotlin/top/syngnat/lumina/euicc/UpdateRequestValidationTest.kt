package top.syngnat.lumina.euicc

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class UpdateRequestValidationTest {
    @Test
    fun acceptsOnlyVersionedLuminaApkAssetNames() {
        assertEquals(
            "lumina-euicc-0.1.3-4-arm64-v8a.apk",
            requireUpdateAssetName("lumina-euicc-0.1.3-4-arm64-v8a.apk"),
        )
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateAssetName("../update.apk")
        }
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateAssetName("another-app-0.1.3.apk")
        }
    }

    @Test
    fun normalizesSha256AndRejectsMalformedDigests() {
        val uppercase = "A".repeat(64)
        assertEquals("a".repeat(64), requireUpdateSha256(uppercase))
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateSha256("a".repeat(63))
        }
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateSha256("z".repeat(64))
        }
    }

    @Test
    fun expectedSizeIsBoundedAndLossless() {
        assertEquals(23_000_000L, requireUpdateSize(23_000_000L))
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateSize(0)
        }
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateSize(200L * 1024L * 1024L + 1L)
        }
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateSize(1.5)
        }
    }

    @Test
    fun versionNameUsesTheStableReleaseContract() {
        assertEquals("0.1.3", requireUpdateVersionName("0.1.3"))
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateVersionName("v0.1.3")
        }
        assertThrows(IllegalArgumentException::class.java) {
            requireUpdateVersionName("0.1.3-beta")
        }
    }
}
