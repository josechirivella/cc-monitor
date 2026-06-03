import Foundation

/// Aggregated usage statistics across different time windows.
/// `currentSession`/`today`/`thisWeek`/`allTime` come from local JSONL parsing —
/// useful for token-count detail. The authoritative session/week percentages live
/// on `apiUsage` and come from the claude.ai usage API.
struct AggregatedStats {
    let currentSession: UsageStats
    let today: UsageStats
    let thisWeek: UsageStats
    let allTime: UsageStats
    let lastUpdated: Date
    /// Number of JSONL files skipped because they exceeded the 10 MB size limit.
    let truncatedFilesCount: Int
    /// Authoritative utilization fetched from claude.ai. nil when the API call failed
    /// or the user has not configured a session key.
    let apiUsage: APIUsage?
    /// User-facing message when the API path is unavailable. nil on success.
    let apiError: String?
}

/// Reads Claude Code's local session data and aggregates token usage.
/// Pure struct — all methods are safe to call from any concurrency context.
struct UsageService {

    private static let maxFileSizeBytes = 10 * 1024 * 1024  // 10 MB

    func load() async throws -> AggregatedStats {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".claude", directoryHint: .isDirectory)

        let currentSessionId = detectCurrentSession(claudeDir: claudeDir)
        let now = Date()

        var allTime = UsageStats.zero
        var today = UsageStats.zero
        var thisWeek = UsageStats.zero
        var currentSession = UsageStats.zero
        var truncated = 0

        let decoder = makeDecoder()
        let iso8601 = Calendar(identifier: .iso8601)

        // Claude Code logs the same request 2-4x in the JSONL (initial + retries/streaming).
        // Track seen keys to avoid 3-4x inflation of token totals and costs.
        var seenKeys = Set<String>()

        let projectsDir = claudeDir.appending(path: "projects", directoryHint: .isDirectory)
        let projectDirs = (try? FileManager.default.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles
        )) ?? []

        // Track the most-recently-modified file's stats for fallback current-session detection.
        // Computed inline during the main loop — no second pass needed.
        var latestModDate = Date.distantPast
        var latestFileStats = UsageStats.zero

        for projectDir in projectDirs {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: projectDir.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            let jsonlFiles = (try? FileManager.default.contentsOfDirectory(
                at: projectDir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: .skipsHiddenFiles
            ))?.filter { $0.pathExtension == "jsonl" } ?? []

            for fileURL in jsonlFiles {
                let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                let size = attrs?.fileSize ?? 0
                let modDate = attrs?.contentModificationDate ?? .distantPast

                if size > Self.maxFileSizeBytes {
                    fputs("[CCMonitor] Skipping large file (\(size / 1024)KB): \(fileURL.lastPathComponent)\n", stderr)
                    truncated += 1
                    continue
                }

                let fileSessionId = fileURL.deletingPathExtension().lastPathComponent
                let isCurrentSession = fileSessionId == currentSessionId
                var fileStats = UsageStats.zero

                for try await line in fileURL.lines {
                    guard !line.isEmpty,
                          let data = line.data(using: .utf8),
                          let record = SessionRecord(data: data, decoder: decoder) else { continue }

                    // Dedupe by requestId; skip duplicates (Claude Code logs each request multiple times).
                    guard seenKeys.insert(record.dedupeKey).inserted else { continue }

                    let stats = UsageStats.from(record)
                    allTime = allTime + stats
                    fileStats = fileStats + stats

                    if iso8601.isDateInToday(record.timestamp) {
                        today = today + stats
                    }

                    if isInCurrentWeek(date: record.timestamp, now: now, calendar: iso8601) {
                        thisWeek = thisWeek + stats
                    }

                    if isCurrentSession {
                        currentSession = currentSession + stats
                    }
                }

                if modDate > latestModDate {
                    latestModDate = modDate
                    latestFileStats = fileStats
                }
            }
        }

        // Fallback: if no busy session was detected, use the most-recently-modified file's stats.
        if currentSessionId == nil && currentSession.recordCount == 0 {
            currentSession = latestFileStats
        }

        return AggregatedStats(
            currentSession: currentSession,
            today: today,
            thisWeek: thisWeek,
            allTime: allTime,
            lastUpdated: now,
            truncatedFilesCount: truncated,
            apiUsage: nil,
            apiError: nil
        )
    }

    // MARK: - Helpers

    /// Reads ~/.claude/sessions/*.json and returns the sessionId of the most-recently-updated
    /// entry with `status == "busy"`. Returns nil if none found.
    private func detectCurrentSession(claudeDir: URL) -> String? {
        let sessionsDir = claudeDir.appending(path: "sessions", directoryHint: .isDirectory)

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: sessionsDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        ) else { return nil }

        struct SessionInfo: Decodable {
            let sessionId: String
            let status: String
            let updatedAt: Double?  // milliseconds since epoch
        }

        var bestId = ""
        var bestUpdatedAt: Double = 0

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let info = try? JSONDecoder().decode(SessionInfo.self, from: data),
                  info.status == "busy" else { continue }
            let updated = info.updatedAt ?? 0
            if updated > bestUpdatedAt {
                bestUpdatedAt = updated
                bestId = info.sessionId
            }
        }

        return bestId.isEmpty ? nil : bestId
    }

    private func isInCurrentWeek(date: Date, now: Date, calendar: Calendar) -> Bool {
        calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatterFrac = ISO8601DateFormatter()
        formatterFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            let str = try container.decode(String.self)
            if let d = formatterFrac.date(from: str) { return d }
            if let d = formatter.date(from: str) { return d }
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Cannot parse date: \(str)")
        }
        return decoder
    }
}
