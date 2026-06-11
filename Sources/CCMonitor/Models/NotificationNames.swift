import Foundation

extension Notification.Name {
    /// Posted when the user taps "Sign in" or when authentication expires.
    /// Triggers presentation of the login/authentication UI.
    static let showLogin = Notification.Name("showLogin")

    /// Posted when the API returns a 401 Unauthorized response.
    /// Indicates that the current session key is invalid or expired.
    static let authExpired = Notification.Name("authExpired")

    /// Posted when a valid sessionKey is captured and stored.
    /// Indicates that authentication succeeded and the session is ready for use.
    static let sessionKeyUpdated = Notification.Name("sessionKeyUpdated")

    /// Posted after the user signs out: the session key has been deleted from
    /// the Keychain and local state reset. Observers clear claude.ai web data.
    static let didLogout = Notification.Name("didLogout")
}
