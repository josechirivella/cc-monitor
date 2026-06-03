import SwiftUI

@main
struct CCMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)

        // Prevents SwiftUI from auto-creating a main window on launch.
        Settings { EmptyView() }
    }
}

/// Dedicated view so @Observable observation wires up correctly for the MenuBarExtra title.
/// Uses the same `bolt.fill` SF Symbol as the Current Session card in the popover.
private struct MenuBarLabel: View {
    let store: UsageStore

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
            Text(store.menuBarPercentText())
        }
        .task { store.start() }
    }
}
