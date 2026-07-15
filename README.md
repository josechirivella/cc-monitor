# CCMonitor

A native macOS menu bar app that shows your Claude Code usage at a glance — current session and weekly limits, sourced directly from Anthropic.

CCMonitor lives in your menu bar as a `⚡ 42%` indicator. Click it for a slick popover with your session and weekly utilization, reset countdowns, and a per-session token breakdown.

## Features

- **Always-visible session %** in the menu bar, refreshed every 30 seconds.
- **Authoritative percentages** pulled from claude.ai's own usage API — the same numbers Anthropic's dashboard shows, not local estimates.
- **Session & weekly limits** with tinted progress bars and "resets in 2h 15m" countdowns.
- **Sonnet weekly sub-limit** surfaced when present (Max plans).
- **Token breakdown** (input / output / cache) for the current session, parsed from local Claude Code logs.
- **Today / All Time** token totals.
- **One-click sign-in** — authenticate through a built-in claude.ai window; your session key is captured automatically and stored in the macOS Keychain.
- Lightweight SwiftUI `MenuBarExtra` app — no Dock icon, no window clutter.

## Requirements

- macOS 14 (Sonoma) or later
- An active Claude subscription signed in at [claude.ai](https://claude.ai)

## Install a Release

Download `CCMonitor-vX.Y.Z-macos-universal.zip` from the [releases page](https://github.com/runyan-co/cc-monitor/releases), extract it, and move `CCMonitor.app` to `/Applications`.

The release is unsigned. macOS may warn when opening an app downloaded from GitHub. To open it, control-click `CCMonitor.app`, select **Open**, then confirm. Source builds are not affected by this download warning.

## Build From Source

Building from source requires a Swift 5.9+ toolchain (Xcode 15+ or Swift command-line tools).

```bash
# Build a release binary and wrap it in CCMonitor.app
make build

# Build and launch the app bundle
make run-app

# Install to ~/.local/bin
make install
```

For quick development iteration:

```bash
make run   # swift run (no .app bundle; the Dock icon may flash briefly)
```

To create the same universal archive used for a release:

```bash
make release-archive VERSION=1.0.1 BUILD_NUMBER=1
```

The archive is written to `dist/CCMonitor-v1.0.1-macos-universal.zip`.

## Setup

CCMonitor reads your usage from the authoritative claude.ai API, which requires your `sessionKey` cookie. On first launch the popover shows a setup screen until a key is provided.

### Sign in (recommended)

1. Open the popover and click **Sign in to Claude**.
2. A built-in window loads [claude.ai](https://claude.ai). Sign in as you normally would.
3. Once you're signed in, CCMonitor captures the `sessionKey` cookie automatically, stores it securely in your macOS **Keychain**, and closes the window.

That's it — no DevTools, no manual copying. If your session later expires (a `401` from the API), CCMonitor reopens the sign-in window so you can re-authenticate.

> **Use email login — even if you normally sign in with Google.**
> The sign-in window is an embedded web view, and Google's OAuth policy blocks
> sign-in from embedded web views (you'll get a generic error). Click
> **"Continue with email"** and sign in with your email address instead. This
> works even for accounts that were originally created via Google SSO — it's the
> same account, just a different way in. After signing in once this way, CCMonitor
> has your session key and you won't need to repeat it until it expires.

> **Note:** Your session key is a credential. It stays on your machine, is read only to call the usage API, and is never logged or transmitted anywhere else.

## How it works

- **Percentages** come from `GET https://claude.ai/api/organizations/{orgId}/usage`, which returns Anthropic's own `five_hour`, `seven_day`, and `seven_day_sonnet` utilization values. This is the source of truth — no estimation.
- **Token breakdowns** are parsed locally from Claude Code's JSONL logs under `~/.claude/projects/`, deduplicated by request ID (Claude Code logs each request multiple times). These supplement the API data with per-session detail.

## Project structure

```
Sources/CCMonitor/
├── App/         # App entry point, menu bar label, app delegate, sign-in window
├── Models/      # API wire types, JSONL records, pricing, aggregation
├── Services/    # claude.ai API client, session key lookup, Keychain, log parsing, observable store
└── Views/       # Menu bar popover, session/week cards, setup screen
```

## Releases

Every push to `main` creates a GitHub Release. The workflow builds a universal macOS app, writes `1.0.<GitHub run number>` into its bundle metadata, tags the merge commit, and uploads the ZIP. GitHub automatically provides source ZIP and tarball archives for every release tag.

The release artifact is intentionally unsigned and does not require an Apple Developer account. It can be signed and notarized in a future release workflow if distribution requirements change.

## License

MIT
