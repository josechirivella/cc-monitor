import AppKit

/// Minimal AppDelegate: sets the accessory activation policy so no Dock icon appears.
/// UsageStore lifecycle is managed by CCMonitorApp via @State.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Programmatic fallback for dev runs (swift run without .app bundle).
        // When running from the .app bundle, Info.plist LSUIElement=YES handles this
        // before the process appears in the Dock, avoiding any icon flash.
        NSApp.setActivationPolicy(.accessory)
    }
}
