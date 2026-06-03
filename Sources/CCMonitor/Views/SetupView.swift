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

            Text("CCMonitor needs access to your Claude.ai account to read authoritative usage data.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                NotificationCenter.default.post(name: .showLogin, object: nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                    Text("Sign in to Claude")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.blue, in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sign in to Claude")
            .accessibilityIdentifier("setupSignInButton")

            Text("Your session key is stored securely in Keychain.")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
