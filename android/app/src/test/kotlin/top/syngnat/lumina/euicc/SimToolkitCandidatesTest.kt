package top.syngnat.lumina.euicc

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SimToolkitCandidatesTest {
    @Test
    fun `generic selector candidates are tried before slot-specific activities`() {
        assertEquals("com.android.stk/.StkMain", SimToolkitCandidates.componentNames.first())
        val firstSlotSpecific = SimToolkitCandidates.componentNames.indexOf(
            "com.android.stk/.StkMain1",
        )
        assertTrue(firstSlotSpecific >= 5)
    }

    @Test
    fun `catalog includes Oppo and Oplus activities for both slots`() {
        val candidates = SimToolkitCandidates.componentNames
        assertTrue("com.android.stk/.OppoStkLauncherActivity1" in candidates)
        assertTrue("com.android.stk/.OppoStkLauncherActivity2" in candidates)
        assertTrue("com.android.stk/.OplusStkLauncherActivity1" in candidates)
        assertTrue("com.android.stk/.OplusStkLauncherActivity2" in candidates)
    }

    @Test
    fun `fallback package catalog is deduplicated and restricted`() {
        assertEquals(
            listOf("com.android.stk", "com.android.stk1", "com.android.stk2"),
            SimToolkitCandidates.packageNames,
        )
    }
}
