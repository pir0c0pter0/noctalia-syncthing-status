# Publishing to the Noctalia Plugin Registry

To make this plugin available in the official Noctalia plugin list for all users:

## 1. Fork the official registry

```bash
gh repo fork noctalia-dev/noctalia-plugins --clone=false
```

## 2. Clone your fork

```bash
gh repo clone YOUR_USER/noctalia-plugins /tmp/noctalia-plugins-fork
```

## 3. Sync fork with upstream

```bash
cd /tmp/noctalia-plugins-fork
git fetch upstream main
git reset --hard upstream/main
```

> If `gh repo sync` fails due to workflow scope, the fetch + reset approach above works.

## 4. Create a branch

```bash
git checkout -b add-noctalia-syncthing-status
```

## 5. Copy plugin files

```bash
mkdir -p /tmp/noctalia-plugins-fork/noctalia-syncthing-status

cp manifest.json Main.qml BarWidget.qml Panel.qml Settings.qml \
   syncthing-status.py README.md LICENSE \
   /tmp/noctalia-plugins-fork/noctalia-syncthing-status/
```

## 6. Update manifest.json repository field

In the **copy** inside `noctalia-plugins-fork/noctalia-syncthing-status/manifest.json`, change the `repository` field to point to the official registry:

```json
"repository": "https://github.com/noctalia-dev/noctalia-plugins"
```

## 7. Commit and push

```bash
cd /tmp/noctalia-plugins-fork
git add noctalia-syncthing-status/
git commit -m "feat: add noctalia-syncthing-status plugin"
git push -u origin add-noctalia-syncthing-status
```

## 8. Create the pull request

```bash
gh pr create --repo noctalia-dev/noctalia-plugins \
  --head YOUR_USER:add-noctalia-syncthing-status \
  --base main \
  --title "Add noctalia-syncthing-status plugin" \
  --body "Theme-aware Syncthing status plugin for Noctalia on Niri with bar and panel integration.

## Features
- Bar widget with status dot, badge count, and context menu
- Expandable panel with device/folder stats, recent errors, and connection details
- Settings page with language selection, folder filtering, and poll interval
- Python helper that queries Syncthing REST API (always exits 0, errors in JSON)
- Bilingual: English and Portuguese (auto-detected from system locale)

## Plugin structure
- Main.qml — Central state manager and process spawner
- BarWidget.qml — Compact bar capsule with tooltip
- Panel.qml — Detailed status panel
- Settings.qml — Full configuration form
- syncthing-status.py — Standalone CLI tool (stdlib only, no dependencies)"
```

## 9. Wait for merge

- The `assign-reviewers` GitHub Action runs automatically on PR creation
- Once merged, `registry.json` is updated automatically by GitHub Actions
- The plugin then appears in **Noctalia Settings > Plugins** for all users

## Plugin directory structure (required by noctalia-plugins)

```
noctalia-syncthing-status/
├── manifest.json         # Plugin metadata (required)
├── Main.qml              # State manager and process spawner
├── BarWidget.qml         # Bar capsule widget
├── Panel.qml             # Expandable status panel
├── Settings.qml          # Settings form
├── syncthing-status.py   # Python helper (stdlib only)
├── LICENSE               # MIT
└── README.md             # User-facing docs
```

## Quick reference

| Item | Value |
|------|-------|
| Plugin ID | `noctalia-syncthing-status` |
| Official repo | `noctalia-dev/noctalia-plugins` |
| Standalone repo | `pir0c0pter0/noctalia-syncthing-status` |
| Auto Tile PR (reference) | #282 (merged 2026-02-19) |

> **Note:** The `registry.json` does not need to be edited manually — it is maintained automatically by GitHub Actions when `manifest.json` files are added or modified.
