# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Syncthing status plugin for **Noctalia** (a Quickshell-based desktop shell for Niri compositor). It displays Syncthing sync state via a bar widget, expandable panel, and settings page.

- Plugin ID: `noctalia-syncthing-status`
- Min Noctalia version: `4.4.0`
- Languages: en, pt, es, fr, de, it, ru, zh, ja, ko (10 languages via Noctalia i18n framework)

## Architecture

The plugin follows Noctalia's entry-point convention defined in `manifest.json`:

- **`Main.qml`** — Central state manager. Spawns a Python helper process on a timer, parses its JSON output into a `snapshot` property, and exposes derived readonly properties (state, devices, folders, totals) plus helper functions (translations via `pluginApi.tr()`, color mapping, badge logic). All other QML files read from `mainInst` (the Main instance provided by `pluginApi.mainInstance`).

- **`syncthing-status.py`** — Standalone CLI tool that queries the Syncthing REST API and outputs a single JSON snapshot to stdout. It auto-resolves `config.xml` for URL/API key, handles TLS, and classifies overall state (`idle`, `syncing`, `paused`, `disconnected`, `offline`, `unauthorized`, `error`, `unconfigured`). Always exits 0 — errors are encoded in the JSON output for plugin stability.

- **`BarWidget.qml`** — Compact bar capsule with theme-aware icon, numeric badge (pending items), and a small status dot. Right-click context menu for toggle/refresh/settings.

- **`Panel.qml`** — Expandable panel showing device counts, folder list with per-folder state, recent errors, and connection details.

- **`Settings.qml`** — Plugin settings form (URL, API key, config path, TLS, poll interval, folder selection).

### Data Flow

```
Timer (pollIntervalMs) → Main.qml spawns Process → python3 syncthing-status.py [args]
  → stdout JSON → applySnapshot() → snapshot property updates
  → BarWidget/Panel/Settings read from mainInst.*
```

### Translation System (Noctalia i18n)

Translations are in `i18n/*.json` files (one per language). Access via `pluginApi?.tr("section.key")` or with interpolation `pluginApi?.tr("section.key", { "name": value })`. Placeholders in JSON use `{name}` format. Never use `??` fallbacks — the shell handles missing translations. Never concatenate translated strings — use interpolation instead.

## Development

### Testing the Python helper directly

```bash
python3 syncthing-status.py --url http://127.0.0.1:8384 --api-key YOUR_KEY
python3 syncthing-status.py --config-path ~/.config/syncthing/config.xml
python3 syncthing-status.py  # autodetects config.xml from default paths
```

### Running in Noctalia

Symlink the plugin directory and restart Quickshell:

```bash
ln -s /path/to/this-repo ~/.config/noctalia/plugins/noctalia-syncthing-status
quickshell -r  # or restart noctalia
```

### IPC commands (from Quickshell CLI)

```bash
quickshell ipc call plugin:noctalia-syncthing-status refresh
quickshell ipc call plugin:noctalia-syncthing-status toggle
quickshell ipc call plugin:noctalia-syncthing-status status
```

## Key Conventions

- The Python helper must always exit 0 and output valid JSON — never crash or return non-JSON. Error states go in `snapshot.state` and `snapshot.detail`.
- QML files use Noctalia's widget framework: `qs.Commons` (Color, Style, Settings), `qs.Widgets` (NIcon, NText, NPopupContextMenu, etc.), `qs.Services.UI` (PanelService, BarService, TooltipService).
- All UI state derives from `mainInst` — no QML file fetches data independently.
- Settings are persisted via `pluginApi.saveSettings()` which writes to Noctalia's plugin settings store.
- TLS verification is off by default (most Syncthing setups use self-signed certs locally).
