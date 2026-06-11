import AppKit
import WebKit

/// Window controller for Claude.ai login authentication.
/// Displays WKWebView loading claude.ai, observes cookies, captures sessionKey,
/// saves to Keychain, and posts notification on success.
final class LoginWindowController: NSWindowController, WKHTTPCookieStoreObserver {
    static let shared = LoginWindowController()

    private let webView: WKWebView
    private var hasRegisteredObserver = false

    /// Set by clearSession() so the next showAndLoad() reloads claude.ai
    /// instead of showing the previous (logged-out) page.
    private var needsFreshLoad = false

    private init() {
        // Create the web view with persistent data store
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()

        let tempWebView = WKWebView(frame: .zero, configuration: config)
        tempWebView.translatesAutoresizingMaskIntoConstraints = false
        // Present a real Safari user agent. The default WKWebView UA is treated as
        // an embedded/non-browser client by claude.ai's auth backend and rejected
        // with a generic "There was an error logging you in" message.
        tempWebView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15"
        webView = tempWebView

        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 680),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Sign in to Claude"
        window.isReleasedWhenClosed = false

        super.init(window: window)

        // Add webView to window content view
        if let contentView = window.contentView {
            contentView.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: contentView.topAnchor),
                webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }

        // Center window on screen
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if hasRegisteredObserver {
            webView.configuration.websiteDataStore.httpCookieStore.remove(self)
        }
    }

    /// Show the login window and begin loading claude.ai
    func showAndLoad() {
        guard let window = window else { return }

        // Register observer only once
        if !hasRegisteredObserver {
            webView.configuration.websiteDataStore.httpCookieStore.add(self)
            hasRegisteredObserver = true
        }

        // Load claude.ai on first show, or reload after a logout cleared the session.
        if webView.url == nil || needsFreshLoad {
            if let url = URL(string: "https://claude.ai") {
                webView.load(URLRequest(url: url))
                needsFreshLoad = false
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Remove claude.ai website data (cookies, local/session storage) so the
    /// next sign-in shows a fresh login form instead of re-capturing the old
    /// session cookie.
    func clearSession() {
        needsFreshLoad = true

        let dataStore = webView.configuration.websiteDataStore
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { records in
            let claudeRecords = records.filter { $0.displayName.contains("claude.ai") }
            guard !claudeRecords.isEmpty else { return }
            dataStore.removeData(ofTypes: types, for: claudeRecords) {}
        }
    }

    // MARK: - WKHTTPCookieStoreObserver

    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieStore.getAllCookies { [weak self] cookies in
            DispatchQueue.main.async {
                self?.processedCookies(cookies)
            }
        }
    }

    private func processedCookies(_ cookies: [HTTPCookie]) {
        // Look for a cookie named "sessionKey" with domain containing "claude.ai"
        for cookie in cookies {
            if cookie.name == "sessionKey" {
                if cookie.domain.contains("claude.ai") {
                    if let key = SessionKeyProvider.extract(from: cookie.value) {
                        handleValidSessionKey(key)
                        return
                    }
                }
            }
        }
    }

    private func handleValidSessionKey(_ key: String) {
        // Save to Keychain
        do {
            try KeychainStore().save(key)
        } catch {
            NSLog("Failed to save session key to Keychain: \(error)")
            return
        }

        // Post notification
        NotificationCenter.default.post(name: .sessionKeyUpdated, object: nil)

        // Close window
        window?.close()
    }
}
