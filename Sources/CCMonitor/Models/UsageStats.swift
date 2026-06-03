import Foundation

/// Aggregated token and cost statistics for a time window or session.
struct UsageStats {
    let inputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let outputTokens: Int
    /// Pre-computed sum of per-record costs. Never re-computed from token totals alone.
    let estimatedCostUSD: Double
    /// True if any record in this window used fallback (unknown-model) pricing.
    let isApproximate: Bool
    /// The most frequently seen model string, for display purposes only.
    let primaryModel: String?
    let recordCount: Int

    static let zero = UsageStats(
        inputTokens: 0, cacheCreationTokens: 0, cacheReadTokens: 0,
        outputTokens: 0, estimatedCostUSD: 0, isApproximate: false,
        primaryModel: nil, recordCount: 0
    )

    var totalTokens: Int { inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens }

    /// Create a UsageStats from a single SessionRecord (primary call-site during aggregation).
    static func from(_ record: SessionRecord) -> UsageStats {
        let pricing = ModelPricing.pricing(for: record.model)
        let cost = pricing.costUSD(
            inputTokens: record.inputTokens,
            outputTokens: record.outputTokens,
            cacheWriteTokens: record.cacheCreationTokens,
            cacheReadTokens: record.cacheReadTokens
        )
        return UsageStats(
            inputTokens: record.inputTokens,
            cacheCreationTokens: record.cacheCreationTokens,
            cacheReadTokens: record.cacheReadTokens,
            outputTokens: record.outputTokens,
            estimatedCostUSD: cost,
            isApproximate: pricing.isApproximate,
            primaryModel: record.model,
            recordCount: 1
        )
    }
}

/// Combine two UsageStats by summing token counts and pre-computed costs.
/// Costs are NOT re-computed from token totals — they are simply added.
func + (lhs: UsageStats, rhs: UsageStats) -> UsageStats {
    UsageStats(
        inputTokens: lhs.inputTokens + rhs.inputTokens,
        cacheCreationTokens: lhs.cacheCreationTokens + rhs.cacheCreationTokens,
        cacheReadTokens: lhs.cacheReadTokens + rhs.cacheReadTokens,
        outputTokens: lhs.outputTokens + rhs.outputTokens,
        estimatedCostUSD: lhs.estimatedCostUSD + rhs.estimatedCostUSD,
        isApproximate: lhs.isApproximate || rhs.isApproximate,
        primaryModel: lhs.primaryModel ?? rhs.primaryModel,
        recordCount: lhs.recordCount + rhs.recordCount
    )
}
