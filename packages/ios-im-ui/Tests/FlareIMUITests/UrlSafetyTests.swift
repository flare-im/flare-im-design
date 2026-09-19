import XCTest
@testable import FlareIMUI

/// DoD 32 — the vector table of spec/security-boundary.json. Every hostile entry
/// is something an attacker can put in a message; the four platforms run the same
/// ids and tooling/check-security-boundary.mjs fails when one stops.
final class UrlSafetyTests: XCTestCase {
    private let hostile: [(String, String)] = [
        ("javascript.plain", "javascript:alert(1)"),
        ("javascript.uppercase", "JaVaScRiPt:alert(1)"),
        ("javascript.leadingSpace", "   javascript:alert(1)"),
        ("javascript.embeddedTab", "java\tscript:alert(1)"),
        ("javascript.embeddedNewline", "java\nscript:alert(1)"),
        ("data.html", "data:text/html,<script>alert(1)</script>"),
        ("data.base64", "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="),
        ("vbscript", "vbscript:msgbox(1)"),
        ("file", "file:///etc/passwd"),
        ("blob", "blob:https://evil.example/9b2d"),
        ("about", "about:blank"),
        ("empty", ""),
        ("whitespace", "   "),
        ("notAUrl", "just some text"),
    ]

    private let allowed: [(String, String)] = [
        ("http", "http://example.com/path?q=1"),
        ("https", "https://example.com/path#anchor"),
        ("schemeless", "example.com/path"),
        ("schemelessWithPort", "example.com:8443/path"),
    ]

    func testRefusesEveryHostileVector() {
        for (id, input) in hostile {
            XCTAssertNil(safeExternalURL(input), id)
            XCTAssertFalse(isSafeExternalURL(input), id)
        }
    }

    func testAllowsPlainWebAddresses() {
        for (id, input) in allowed {
            XCTAssertTrue(isSafeExternalURL(input), id)
        }
    }

    func testReadsASchemeLessStringAsHttpsAndNeverRescuesOneThatHasAScheme() {
        XCTAssertEqual(safeExternalURL("example.com"), "https://example.com")
        XCTAssertNil(safeExternalURL("javascript:alert(1)"))
    }

    func testRefusesNilWithoutThrowing() {
        XCTAssertNil(safeExternalURL(nil))
        XCTAssertFalse(isSafeExternalURL(nil))
    }
}
