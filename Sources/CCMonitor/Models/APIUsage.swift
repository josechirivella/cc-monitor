import Foundation

/// Authoritative usage data fetched from `claude.ai/api/organizations/{id}/usage`.
/// Utilization values come directly from Anthropic's billing service — the same
/// numbers shown inside Claude.ai and Claude Code's own status display.
struct APIUsage {
    let session: APIUsageLimit
    let week: APIUsageLimit
    let weekSonnet: APIUsageLimit?
    let fetchedAt: Date
}

struct APIUsageLimit {
    /// Percentage utilization, 0...100+ (can exceed 100 if user blew past the limit).
    let utilization: Double
    /// When this rate-limit window resets. nil when API didn't return a reset (e.g., usage is 0).
    let resetsAt: Date?
}

// MARK: - API response wire types

/// GET /api/organizations/{orgId}/usage
struct UsageAPIResponse: Decodable {
    let fiveHour: UsageLimitResponse
    let sevenDay: UsageLimitResponse
    let sevenDaySonnet: UsageLimitResponse?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
    }
}

struct UsageLimitResponse: Decodable {
    let utilization: Double
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    func toDomain() -> APIUsageLimit {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]

        let date: Date? = resetsAt.flatMap { raw in
            parser.date(from: raw) ?? fallback.date(from: raw)
        }
        return APIUsageLimit(utilization: utilization, resetsAt: date)
    }
}

extension UsageAPIResponse {
    func toDomain() -> APIUsage {
        APIUsage(
            session: fiveHour.toDomain(),
            week: sevenDay.toDomain(),
            weekSonnet: sevenDaySonnet?.toDomain(),
            fetchedAt: Date()
        )
    }
}

/// GET /api/organizations — used once to discover the user's organization UUID.
struct OrganizationListResponse: Decodable {
    let organizations: [OrganizationEntry]

    init(from decoder: Decoder) throws {
        // The endpoint returns a bare top-level array, not a wrapping object.
        let container = try decoder.singleValueContainer()
        self.organizations = try container.decode([OrganizationEntry].self)
    }
}

struct OrganizationEntry: Decodable {
    let uuid: String

    enum CodingKeys: String, CodingKey {
        case uuid
    }
}
