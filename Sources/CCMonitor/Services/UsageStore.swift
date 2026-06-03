import Foundation
import Observation

/// Observable state container for Claude Code usage data.
/// Owned by AppDelegate; injected into SwiftUI views via @Environment.
/// Uses a structured-concurrency Task loop (not Timer) for 30-second refreshes,
/// avoiding the Swift async/Timer bridge and ensuring no overlapping parses.
@Observable
@MainActor
final class UsageStore {
    var stats: AggregatedStats?
    var isLoading = false
    var lastError: String?
    /// True when the session-key lookup returned no key — used to drive the
    /// "Setup required" view path.
    var needsSetup: Bool = false

    private var refreshTask: Task<Void, Never>?
    private let jsonl = UsageService()
    private let api = ClaudeAPIClient()
    private let keys = SessionKeyProvider()

    /// Current-session utilization as an integer percent for the menu bar.
    /// Uses authoritative API data when available; falls back to "—" otherwise.
    func menuBarPercentText() -> String {
        guard let pct = stats?.apiUsage?.session.utilization else { return "—" }
        return "\(Int(pct.rounded()))%"
    }

    func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Try the authoritative API first.
        var apiUsage: APIUsage? = nil
        var apiError: String? = nil
        do {
            let key = try keys.sessionKey()
            needsSetup = false
            apiUsage = try await api.fetchUsage(sessionKey: key)
        } catch SessionKeyProvider.LookupError.notConfigured {
            needsSetup = true
            apiError = "Setup required"
        } catch let err as ClaudeAPIError {
            apiError = err.errorDescription
        } catch {
            apiError = error.localizedDescription
        }

        // JSONL parsing is independent and provides token-breakdown detail.
        do {
            let local = try await Task.detached { [jsonl] in
                try await jsonl.load()
            }.value

            stats = AggregatedStats(
                currentSession: local.currentSession,
                today: local.today,
                thisWeek: local.thisWeek,
                allTime: local.allTime,
                lastUpdated: Date(),
                truncatedFilesCount: local.truncatedFilesCount,
                apiUsage: apiUsage,
                apiError: apiError
            )
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
