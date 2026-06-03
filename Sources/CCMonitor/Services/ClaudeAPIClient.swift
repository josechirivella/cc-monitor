import Foundation

/// Errors surfaced by the Claude.ai usage API.
enum ClaudeAPIError: LocalizedError {
    case notConfigured
    case authenticationFailed
    case rateLimited
    case organizationNotFound
    case httpError(Int)
    case decodeFailed(String)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:        return "Session key not configured"
        case .authenticationFailed: return "Session key rejected (401) — re-export from claude.ai"
        case .rateLimited:          return "Rate limited by claude.ai (429)"
        case .organizationNotFound: return "No organization found for this session key"
        case .httpError(let code):  return "claude.ai returned HTTP \(code)"
        case .decodeFailed(let m):  return "Could not decode API response: \(m)"
        case .transport(let e):     return "Network error: \(e.localizedDescription)"
        }
    }
}

/// Minimal HTTP client for the claude.ai usage API.
/// Sends the sessionKey as a Cookie and adds the headers Cloudflare expects
/// from a real browser session, matching the pattern ClaudeMeter uses.
actor ClaudeAPIClient {
    private let session: URLSession
    private let baseURL = "https://claude.ai/api"
    private var cachedOrgId: String?

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 20
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        self.session = URLSession(configuration: config)
    }

    /// Public entry point: fetch usage utilization for session, week, and (optionally) Sonnet weekly.
    func fetchUsage(sessionKey: String) async throws -> APIUsage {
        let orgId = try await resolveOrganizationId(sessionKey: sessionKey)
        let response: UsageAPIResponse = try await get(
            "\(baseURL)/organizations/\(orgId)/usage",
            sessionKey: sessionKey
        )
        return response.toDomain()
    }

    // MARK: - Private

    private func resolveOrganizationId(sessionKey: String) async throws -> String {
        if let cached = cachedOrgId { return cached }
        let orgs: OrganizationListResponse = try await get(
            "\(baseURL)/organizations",
            sessionKey: sessionKey
        )
        guard let first = orgs.organizations.first else {
            throw ClaudeAPIError.organizationNotFound
        }
        cachedOrgId = first.uuid
        return first.uuid
    }

    private func get<T: Decodable>(_ urlString: String, sessionKey: String) async throws -> T {
        guard let url = URL(string: urlString) else { throw ClaudeAPIError.httpError(0) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://claude.ai", forHTTPHeaderField: "Referer")
        request.setValue("claude.ai", forHTTPHeaderField: "Origin")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClaudeAPIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeAPIError.httpError(0)
        }
        switch http.statusCode {
        case 200...299:
            break
        case 401:
            throw ClaudeAPIError.authenticationFailed
        case 429:
            throw ClaudeAPIError.rateLimited
        default:
            throw ClaudeAPIError.httpError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ClaudeAPIError.decodeFailed(error.localizedDescription)
        }
    }
}
