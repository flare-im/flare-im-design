import Foundation

/// Which URLs a chat surface may navigate to.
///
/// Message content is written by other people, so a link in it is a string an
/// attacker chose. `javascript:` and `data:` execute in a web view's origin;
/// `file:` reads local state. The only safe default is: render it as text unless
/// it is plainly a web address.
///
/// The kit itself almost never navigates — components report the URL and the
/// host opens it. This is the rule both sides apply.
public let flareSafeURLSchemes: [String] = ["http", "https"]

/// The URL to navigate to, or nil when the string is not a safe web address.
///
/// A scheme-less string is read as https — that is what a user typing
/// `example.com` means — but only when it carries no scheme at all, so
/// `javascript:alert(1)` is never rescued into `https://javascript:alert(1)`.
public func safeExternalURL(_ raw: String?) -> String? {
    guard let raw else { return nil }
    // Strip only what a URL parser itself ignores — tab, newline, carriage
    // return — so `java\tscript:` normalizes to `javascript:` before the check.
    // Interior spaces must stay: removing them turns a sentence
    // (`just some text`) into a valid host name.
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        .filter { $0 != "\t" && $0 != "\n" && $0 != "\r" }
    guard !trimmed.isEmpty else { return nil }
    let candidate = hasScheme(trimmed) ? trimmed : "https://\(trimmed)"
    guard let parsed = URLComponents(string: candidate),
          let scheme = parsed.scheme?.lowercased(),
          flareSafeURLSchemes.contains(scheme),
          let host = parsed.host, !host.isEmpty,
          let url = parsed.url
    else { return nil }
    return url.absoluteString
}

/// Whether the string is a web address this surface may open.
public func isSafeExternalURL(_ raw: String?) -> Bool { safeExternalURL(raw) != nil }

/// `scheme:` at the start, per RFC 3986 — letters, digits, `+`, `-`, `.`.
///
/// A host and a port look the same to that grammar, so a colon followed by
/// digits is read as a port. Mis-reading that way yields an https URL with an
/// odd host, which is harmless; reading a real scheme as a host is what must not
/// happen.
private func hasScheme(_ value: String) -> Bool {
    guard let range = value.range(of: "^[A-Za-z][A-Za-z0-9+.-]*:", options: .regularExpression) else { return false }
    let rest = value[range.upperBound...]
    return !(rest.first?.isNumber ?? false)
}
