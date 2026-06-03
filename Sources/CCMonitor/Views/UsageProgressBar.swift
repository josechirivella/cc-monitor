import SwiftUI

/// A flat, capsule-style progress bar tinted by fill level.
/// Used as the lead visual on the Current Session and This Week cards.
struct UsageProgressBar: View {
    let fraction: Double  // 0...1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: max(2, geo.size.width * fraction))
            }
        }
        .frame(height: 6)
    }

    private var tint: Color {
        switch fraction {
        case ..<0.5:  return .green
        case ..<0.8:  return .yellow
        case ..<1.0:  return .orange
        default:      return .red
        }
    }
}
