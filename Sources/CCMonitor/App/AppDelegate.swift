import AppKit

/// Minimal AppDelegate: sets the accessory activation policy so no Dock icon appears.
/// UsageStore lifecycle is managed by CCMonitorApp via @State.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var loginObserver: NSObjectProtocol?
    private var authExpiredObserver: NSObjectProtocol?
    private var logoutObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Programmatic fallback for dev runs (swift run without .app bundle).
        // When running from the .app bundle, Info.plist LSUIElement=YES handles this
        // before the process appears in the Dock, avoiding any icon flash.
        NSApp.setActivationPolicy(.accessory)

        let nc = NotificationCenter.default

        loginObserver = nc.addObserver(
            forName: .showLogin,
            object: nil,
            queue: .main
        ) { _ in
            LoginWindowController.shared.showAndLoad()
        }

        authExpiredObserver = nc.addObserver(
            forName: .authExpired,
            object: nil,
            queue: .main
        ) { _ in
            LoginWindowController.shared.showAndLoad()
        }

        logoutObserver = nc.addObserver(
            forName: .didLogout,
            object: nil,
            queue: .main
        ) { _ in
            LoginWindowController.shared.clearSession()
        }
    }

    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = authExpiredObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
