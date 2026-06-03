import Foundation

struct ModelPricing {
    let inputPerMTok: Double
    let outputPerMTok: Double
    let cacheWritePerMTok: Double
    let cacheReadPerMTok: Double
    /// True when the model string didn't match any known prefix and Sonnet 4 fallback pricing is used.
    let isApproximate: Bool

    /// Look up pricing by model string prefix. Tries known prefixes in order;
    /// falls back to Sonnet 4 pricing (isApproximate = true) for unknown models.
    static func pricing(for model: String) -> ModelPricing {
        if model.hasPrefix("claude-opus-4") {
            return ModelPricing(inputPerMTok: 15.00, outputPerMTok: 75.00,
                                cacheWritePerMTok: 18.75, cacheReadPerMTok: 1.50,
                                isApproximate: false)
        } else if model.hasPrefix("claude-sonnet-4") {
            return ModelPricing(inputPerMTok: 3.00, outputPerMTok: 15.00,
                                cacheWritePerMTok: 3.75, cacheReadPerMTok: 0.30,
                                isApproximate: false)
        } else if model.hasPrefix("claude-haiku-4") {
            return ModelPricing(inputPerMTok: 0.80, outputPerMTok: 4.00,
                                cacheWritePerMTok: 1.00, cacheReadPerMTok: 0.08,
                                isApproximate: false)
        }
        // Fallback: Sonnet 4 pricing, marked approximate.
        return ModelPricing(inputPerMTok: 3.00, outputPerMTok: 15.00,
                            cacheWritePerMTok: 3.75, cacheReadPerMTok: 0.30,
                            isApproximate: true)
    }

    /// Returns cost in USD for a single request's tokens.
    ///
    /// Cache reads are intentionally excluded. The Claude Code subscription limit
    /// (the metric users see in /cost and in the menu bar) does not appear to
    /// charge for cache reads — they are an optimization Anthropic absorbs for
    /// subscribers. Including cache reads would roughly double the reported usage
    /// vs. what the subscription dashboard shows.
    func costUSD(inputTokens: Int, outputTokens: Int,
                 cacheWriteTokens: Int, cacheReadTokens: Int) -> Double {
        let i = Double(inputTokens) * inputPerMTok
        let o = Double(outputTokens) * outputPerMTok
        let w = Double(cacheWriteTokens) * cacheWritePerMTok
        return (i + o + w) / 1_000_000
    }
}
