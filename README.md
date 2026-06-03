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
- Lightweight SwiftUI `MenuBarExtra` app — no Dock icon, no window clutter.

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9+ toolchain (Xcode 15+ or Swift command-line tools)
- An active Claude subscription signed in at [claude.ai](https://claude.ai)

## Build & Run

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

## Setup

CCMonitor reads your usage from the authoritative claude.ai API, which requires your `sessionKey` cookie. On first launch the popover shows a setup screen until a key is provided.

1. Open [claude.ai](https://claude.ai) in your browser, signed in.
2. Open DevTools → **Application** → **Cookies** → `https://claude.ai`.
3. Copy the value of the **`sessionKey`** cookie (it starts with `sk-ant-`).
4. Save it to one of the following locations:

   ```bash
   echo 'sk-ant-...' > ~/.claude/.ccmonitor-session-key
   ```

5. Relaunch CCMonitor (or wait for the next refresh).

### Session key lookup order

CCMonitor checks these sources in order and uses the first one found:

1. The `CCMONITOR_SESSION_KEY` environment variable
2. `~/.config/ccmonitor/session_key`
3. `~/.claude/.ccmonitor-session-key`

Each source may contain the raw `sk-ant-…` value, a `sessionKey=…` line, or a full `Cookie` header — CCMonitor extracts the key either way.

> **Note:** Your session key is a credential. It stays on your machine, is read only to call the usage API, and is never logged or transmitted anywhere else.

## How it works

- **Percentages** come from `GET https://claude.ai/api/organizations/{orgId}/usage`, which returns Anthropic's own `five_hour`, `seven_day`, and `seven_day_sonnet` utilization values. This is the source of truth — no estimation.
- **Token breakdowns** are parsed locally from Claude Code's JSONL logs under `~/.claude/projects/`, deduplicated by request ID (Claude Code logs each request multiple times). These supplement the API data with per-session detail.

## Project structure

```
Sources/CCMonitor/
├── App/         # App entry point, menu bar label, app delegate
├── Models/      # API wire types, JSONL records, pricing, aggregation
├── Services/    # claude.ai API client, session key lookup, log parsing, observable store
└── Views/       # Menu bar popover, session/week cards, setup screen
```

## License

MIT
