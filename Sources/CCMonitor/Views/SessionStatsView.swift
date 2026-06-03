import SwiftUI

/// Featured card showing current-session usage as a percentage of the session limit,
/// followed by reset countdown, model name, and token breakdown.
/// `utilization` comes from the authoritative claude.ai API.
struct SessionStatsView: View {
    let utilization: Double?      // 0...100+, from API
    let resetsAt: Date?           // when the 5h window resets, from API
    let tokens: UsageStats?       // local JSONL detail (token counts, model name)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Current Session", systemImage: "bolt.fill")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
                Spacer()
                if let utilization {
                    Text("\(Int(utilization.rounded()))%")
                        .font(.system(.title3, design: .rounded).monospacedDigit())
                        .fontWeight(.semibold)
                }
            }

            if let utilization {
                UsageProgressBar(fraction: min(max(utilization / 100, 0), 1))

                HStack(spacing: 6) {
                    if let resetsAt {
                        Label("Resets \(resetsAt.relativeFromNow)", systemImage: "clock")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let model = tokens?.primaryModel {
                        Text(model)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                if let tokens, tokens.recordCount > 0 {
                    Divider().padding(.vertical, 2)
                    TokenBreakdownRow(
                        input: tokens.inputTokens,
                        output: tokens.outputTokens,
                        cacheRead: tokens.cacheReadTokens,
                        cacheWrite: tokens.cacheCreationTokens
                    )
                }
            } else {
                Text("No data")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// A compact horizontal row of token counts: input ↑, output ↓, cache.
struct TokenBreakdownRow: View {
    let input: Int
    let output: Int
    let cacheRead: Int
    let cacheWrite: Int

    var body: some View {
        HStack(spacing: 12) {
            stat(symbol: "↑", value: input, label: "in")
            stat(symbol: "↓", value: output, label: "out")
            stat(symbol: "⚡", value: cacheRead + cacheWrite, label: "cache")
            Spacer()
        }
    }

    private func stat(symbol: String, value: Int, label: String) -> some View {
        HStack(spacing: 2) {
            Text(symbol).foregroundStyle(.tertiary)
            Text(value.tokenFormatted)
                .font(.system(.caption, design: .rounded).monospacedDigit())
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
