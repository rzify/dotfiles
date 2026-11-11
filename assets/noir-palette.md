# Noir — shared design language

Black backgrounds, white text, grays for hierarchy. The one color is red, used only for
errors and deletions so they never get lost. Applied across
**Ghostty · VS Code · Helium/Chrome · Obsidian · Raycast · iTerm2 · Slack · macOS**.

## Tokens (single source of truth)

| Token    | Hex       | Role                                        |
|----------|-----------|---------------------------------------------|
| `black`  | `#000000` | every background: editor, sidebars, chrome  |
| `raised` | `#0f0f0f` | widgets, inputs, menus, code blocks         |
| `line`   | `#1a1a1a` | borders, dividers                           |
| `sel`    | `#333333` | selection                                   |
| `dim`    | `#555555` | comments, line numbers, inactive tabs       |
| `gray`   | `#888888` | muted text, status bar                      |
| `light`  | `#b3b3b3` | secondary text, warnings, git modified      |
| `fg`     | `#e6e6e6` | primary text                                |
| `white`  | `#ffffff` | active, bold, keywords, buttons, cursor     |
| `red`    | `#e5534b` | errors and deletions only                   |

**Font everywhere:** JetBrains Mono, ligatures on, Geist Mono fallback.

## Terminal ANSI

Same in Ghostty, iTerm2 and the VS Code terminal. Colors become distinct grays,
so prompts and `ls` output still separate visually; only red stays red.

| Color   | Normal    | Bright    |
|---------|-----------|-----------|
| black   | `#1a1a1a` | `#555555` |
| red     | `#e5534b` | `#ff7b72` |
| green   | `#d9d9d9` | `#ffffff` |
| yellow  | `#b3b3b3` | `#d9d9d9` |
| blue    | `#8c8c8c` | `#b3b3b3` |
| magenta | `#a6a6a6` | `#cccccc` |
| cyan    | `#c4c4c4` | `#e6e6e6` |
| white   | `#e6e6e6` | `#ffffff` |

## Coverage by app

| App      | Mechanism                                                                 |
|----------|---------------------------------------------------------------------------|
| macOS    | `bin/macos-setup.sh`: Dark, Graphite accent + highlight, Tinted icons     |
| Wallpaper| `assets/wallpaper-black.png` (pure black)                                 |
| Ghostty  | `ghostty/.config/ghostty/config` (colors only, symlinked)                 |
| VS Code  | `vscode/.../settings.json`: `Vesper` theme + Noir override                |
| Helium   | `helium/noir-theme/` (load unpacked, hit Reload after edits)              |
| Chrome   | same `helium/noir-theme/` (load unpacked)                                 |
| Obsidian | `obsidian/noir.css` → vault `.obsidian/snippets/` (enabled)               |
| Raycast  | `assets/raycast-noir-theme.url` (open once, import)                       |
| iTerm2   | `iterm2/DynamicProfiles/vesper.json` (Noir colors, profile name kept)     |
| Slack    | Preferences → Themes → Custom: `#000000,#333333,#FFFFFF,#E5534B`          |
| Fork     | `defaults` theme dark; Fork exposes no color override                     |
| Others   | Claude, Notion, WhatsApp, Figma follow the system Dark appearance         |

## Previous palettes

- **ObraXRAY** (2026-11-08 → 2026-11-10): Deep Forest `#0d2d25`, Mist text, Emerald accents.
- **Sunset** (2026-10-29 → 2026-11-08): night purple `#2a1652` with amber/coral/pink accents.
- **Vesper amber** (2026-10-28): `#101010` background with amber/mint accents.
- **Noir v1** (retired 2026-10-28): strictly grayscale.

Their configs are in git history.
