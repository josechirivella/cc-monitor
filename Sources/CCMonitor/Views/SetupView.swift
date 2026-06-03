import SwiftUI

/// Shown when the user has not configured a claude.ai session key.
/// Walks through the (one-time) setup that unlocks authoritative percentages.
struct SetupView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Setup required", systemImage: "key.fill")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.orange)
                .fontWeight(.semibold)

            Text("CCMonitor needs your claude.ai session key to read authoritative usage data.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                step(1, "Open claude.ai in your browser, signed in.")
                step(2, "Open DevTools → Application → Cookies → claude.ai.")
                step(3, "Copy the value of the sessionKey cookie (starts with sk-ant-).")
                step(4, "Save it to ~/.claude/.ccmonitor-session-key")
            }

            Text("Then quit and relaunch CCMonitor.")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(n).")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 14, alignment: .trailing)
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
