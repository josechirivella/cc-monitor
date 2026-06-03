import Foundation

extension Int {
    /// Formats a raw token count for compact display: 1_500_000 → "1.5M", 45_200 → "45.2K", 800 → "800".
    var tokenFormatted: String {
        switch self {
        case 1_000_000...:
            return String(format: "%.1fM", Double(self) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", Double(self) / 1_000)
        default:
            return "\(self)"
        }
    }
}

extension Date {
    /// Returns a short "X ago" string for a last-updated timestamp.
    /// Under 60 seconds → "< 1m ago"; otherwise "Xm ago" or "Xh ago".
    func relativeAgo(from now: Date = Date()) -> String {
        let seconds = Int(now.timeIntervalSince(self))
        if seconds < 60 { return "< 1m ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }

    /// Returns a compact "in 2h 15m" string for an upcoming reset timestamp.
    /// Returns "now" when the date is in the past or imminent.
    var relativeFromNow: String {
        let seconds = Int(timeIntervalSinceNow)
        if seconds <= 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "in \(minutes)m" }
        let hours = minutes / 60
        let remMin = minutes % 60
        if hours < 24 {
            return remMin > 0 ? "in \(hours)h \(remMin)m" : "in \(hours)h"
        }
        let days = hours / 24
        let remHours = hours % 24
        return remHours > 0 ? "in \(days)d \(remHours)h" : "in \(days)d"
    }
}
