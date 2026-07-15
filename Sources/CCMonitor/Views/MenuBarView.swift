import SwiftUI

/// Root content view rendered inside the MenuBarExtra popover.
/// Leads with API-sourced authoritative percentages; falls back to setup
/// instructions when no session key is configured.
@MainActor
struct MenuBarView: View {
    @Environment(UsageStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 300)
        .background(.regularMaterial)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text("CCMonitor")
                .font(.system(.callout, design: .rounded))
                .fontWeight(.semibold)
            Spacer()
            if store.isLoading {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.needsSetup {
                SetupView()
            } else {
                SessionStatsView(
                    utilization: store.stats?.apiUsage?.session.utilization,
                    resetsAt: store.stats?.apiUsage?.session.resetsAt,
                    tokens: store.stats?.currentSession
                )
                WeekStatsView(
                    utilization: store.stats?.apiUsage?.week.utilization,
                    resetsAt: store.stats?.apiUsage?.week.resetsAt,
                    sonnet: store.stats?.apiUsage?.weekSonnet
                )
            }

            VStack(spacing: 4) {
                PeriodStatsRow(label: "Today",    stats: store.stats?.today   ?? .zero)
                PeriodStatsRow(label: "All Time", stats: store.stats?.allTime ?? .zero)
            }
            .padding(.horizontal, 4)

            if let apiError = store.stats?.apiError, !store.needsSetup {
                Label(apiError, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
    }

    private var footer: some View {
        HStack {
            if let last = store.stats?.lastUpdated {
                Text("Updated \(last.relativeAgo())")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            } else {
                Text("Loading…")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if !store.needsSetup {
                Button("Sign Out") {
                    store.logout()
                }
                .buttonStyle(.plain)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Sign out of Claude")
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}
