import SwiftUI

/// Featured card showing weekly usage as a percentage of the weekly limit
/// with a reset countdown and Sonnet-specific breakdown when present.
struct WeekStatsView: View {
    let utilization: Double?
    let resetsAt: Date?
    let sonnet: APIUsageLimit?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("This Week", systemImage: "calendar")
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
                    if let sonnet {
                        HStack(spacing: 3) {
                            Text("Sonnet")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.tertiary)
                            Text("\(Int(sonnet.utilization.rounded()))%")
                                .font(.system(.caption, design: .rounded).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
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
