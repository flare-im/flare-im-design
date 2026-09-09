package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class UnknownUserPlaceholderTest {
    @Test fun everyKindMapsToItself() {
        for (kind in FlareUnknownUserKind.entries) {
            assertEquals(kind, unknownUserPresentation(kind).kind)
        }
    }

    @Test fun toneAccompaniesTheIcon() {
        assertEquals(FlareUnknownUserTone.Neutral, unknownUserPresentation(FlareUnknownUserKind.Unknown).tone)
        assertEquals(FlareUnknownUserTone.Neutral, unknownUserPresentation(FlareUnknownUserKind.Deactivated).tone)
        assertEquals(FlareUnknownUserTone.Danger, unknownUserPresentation(FlareUnknownUserKind.Blocked).tone)
        assertEquals(FlareUnknownUserTone.Warning, unknownUserPresentation(FlareUnknownUserKind.Unreachable).tone)
    }

    @Test fun absentKindDegradesToUnknown() {
        assertEquals(
            FlareUnknownUserPresentation(FlareUnknownUserKind.Unknown, FlareUnknownUserTone.Neutral),
            unknownUserPresentation(null),
        )
    }

    @Test fun eachKindHasItsOwnIcon() {
        val icons = FlareUnknownUserKind.entries.map { unknownUserIcon(it).name }.toSet()
        assertEquals(FlareUnknownUserKind.entries.size, icons.size)
    }

    @Test fun shortIdsSurviveIntactAndAreTrimmed() {
        assertEquals("u_42", shortenUserId("u_42"))
        assertEquals("u_42", shortenUserId("  u_42  "))
        assertEquals("", shortenUserId(""))
        assertEquals("", shortenUserId(null))
    }

    @Test fun idExactlyAtTheBudgetIsKept() {
        val exact = "0123456789abcdef01234567"
        assertEquals(24, exact.length)
        assertEquals(exact, shortenUserId(exact))
    }

    @Test fun longIdIsMiddleElidedToTheBudget() {
        val out = shortenUserId("2AW1QQ2SKVWFEPJRXN0123456789abcdef")
        assertEquals(24, out.length)
        assertEquals("2AW1QQ2SKVWF…56789abcdef", out)
        assertTrue(out.startsWith("2AW1QQ2SKVWF"))
        assertTrue(out.endsWith("56789abcdef"))
    }

    @Test fun customBudgetIsHonouredAndFloored() {
        assertEquals(10, shortenUserId("abcdefghijklmnop", 10).length)
        assertEquals(8, shortenUserId("abcdefghijklmnop", 2).length)
    }
}
