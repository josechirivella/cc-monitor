import Foundation

/// Locates the user's claude.ai sessionKey cookie.
/// Lookup order:
///   1. `CCMONITOR_SESSION_KEY` environment variable
///   2. `~/.config/ccmonitor/session_key` file
///   3. `~/.claude/.ccmonitor-session-key` file
/// File contents may be the raw value, a `sessionKey=...` line, or a full Cookie header.
struct SessionKeyProvider {

    enum LookupError: LocalizedError {
        case notConfigured

        var errorDescription: String? {
            "Claude.ai session key not configured. See setup instructions."
        }
    }

    func sessionKey() throws -> String {
        if let env = ProcessInfo.processInfo.environment["CCMONITOR_SESSION_KEY"],
           let key = Self.extract(from: env) {
            return key
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            home.appending(path: ".config/ccmonitor/session_key"),
            home.appending(path: ".claude/.ccmonitor-session-key"),
        ]
        for path in candidates {
            if let data = try? Data(contentsOf: path),
               let raw = String(data: data, encoding: .utf8),
               let key = Self.extract(from: raw) {
                return key
            }
        }
        throw LookupError.notConfigured
    }

    /// Extract the `sk-ant-*` value from a raw string. Accepts the raw key,
    /// `sessionKey=...` form, or a Cookie header.
    static func extract(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("sk-ant-") { return trimmed }

        // Find sessionKey=... within a cookie header / line.
        let pattern = #"(?i)(?:^|[;\s])sessionKey\s*=\s*([^;\s'"]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, range: range),
              match.numberOfRanges >= 2,
              let captureRange = Range(match.range(at: 1), in: trimmed) else {
            return nil
        }
        let value = String(trimmed[captureRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.hasPrefix("sk-ant-") ? value : nil
    }
}
