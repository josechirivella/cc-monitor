import Foundation

/// Decoded representation of a `type=assistant` JSONL line written by Claude Code.
/// Failable — records that aren't `type=assistant` or lack usage data are nil.
struct SessionRecord {
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let outputTokens: Int
    /// Identifier used to dedupe — Claude Code logs the same request multiple times in JSONL
    /// (typically 2-4x per request), so summing without deduping overstates usage by ~3x.
    let dedupeKey: String

    // MARK: - Decodable containers

    private struct Root: Decodable {
        let type: String
        let timestamp: Date
        let requestId: String?
        let message: Message?

        struct Message: Decodable {
            let id: String?
            let model: String?
            let usage: Usage?

            struct Usage: Decodable {
                let inputTokens: Int
                let cacheCreationInputTokens: Int
                let cacheReadInputTokens: Int
                let outputTokens: Int

                enum CodingKeys: String, CodingKey {
                    case inputTokens = "input_tokens"
                    case cacheCreationInputTokens = "cache_creation_input_tokens"
                    case cacheReadInputTokens = "cache_read_input_tokens"
                    case outputTokens = "output_tokens"
                }
            }
        }
    }

    // MARK: - Failable init from raw JSON data

    init?(data: Data, decoder: JSONDecoder) {
        guard let root = try? decoder.decode(Root.self, from: data),
              root.type == "assistant",
              let message = root.message,
              let usage = message.usage else {
            return nil
        }
        self.timestamp = root.timestamp
        self.model = message.model ?? "<unknown>"
        self.inputTokens = usage.inputTokens
        self.cacheCreationTokens = usage.cacheCreationInputTokens
        self.cacheReadTokens = usage.cacheReadInputTokens
        self.outputTokens = usage.outputTokens
        // Prefer requestId (top-level on the JSONL line); fall back to message.id.
        // If neither is present, the record is unique by definition — synthesize a key
        // from timestamp + tokens so two identical-looking records still collide.
        self.dedupeKey = root.requestId ?? message.id ?? "\(root.timestamp.timeIntervalSince1970)-\(usage.inputTokens)-\(usage.outputTokens)"
    }
}
