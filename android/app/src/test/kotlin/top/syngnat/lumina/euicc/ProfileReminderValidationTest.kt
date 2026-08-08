package top.syngnat.lumina.euicc

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ProfileReminderValidationTest {
    @Test
    fun `stable id is deterministic without exposing the ICCID`() {
        val iccid = "8901000000000000001"

        val first = stableProfileReminderId(iccid)
        val second = stableProfileReminderId(iccid)

        assertEquals(first, second)
        assertEquals(64, first.length)
        assertFalse(first.contains(iccid))
        assertNotEquals(first, stableProfileReminderId("8901000000000000002"))
    }

    @Test
    fun `request validation accepts a future local reminder`() {
        val reminder = validateProfileReminderRequest(
            iccid = "8901000000000000001",
            profileName = "Travel line",
            triggerAtMillis = 2_000L,
            nowMillis = 1_000L,
        )

        assertEquals("Travel line", reminder.profileName)
        assertEquals(2_000L, reminder.triggerAtMillis)
        assertTrue(reminder.id.matches(Regex("[0-9a-f]{64}")))
    }

    @Test(expected = IllegalArgumentException::class)
    fun `request validation rejects a past reminder`() {
        validateProfileReminderRequest(
            iccid = "8901000000000000001",
            profileName = "Travel line",
            triggerAtMillis = 999L,
            nowMillis = 1_000L,
        )
    }

    @Test(expected = IllegalArgumentException::class)
    fun `request validation rejects a blank profile identity`() {
        validateProfileReminderRequest(
            iccid = " ",
            profileName = "Travel line",
            triggerAtMillis = 2_000L,
            nowMillis = 1_000L,
        )
    }
}
