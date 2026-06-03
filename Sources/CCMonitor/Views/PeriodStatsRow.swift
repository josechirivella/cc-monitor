import SwiftUI

/// A single row showing a period label (Today / All Time) with the total token count.
/// Cost is intentionally omitted — only the authoritative API percentages and raw
/// token counts are surfaced; estimated USD from JSONL is not.
struct PeriodStatsRow: View {
    let label: String
    let stats: UsageStats

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            if stats.recordCount == 0 {
                Text("—")
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundStyle(.tertiary)
            } else {
                Text("\(stats.totalTokens.tokenFormatted) tokens")
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
