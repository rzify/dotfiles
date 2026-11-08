# ObraXRAY — shared design language

One palette + one font, applied across **Ghostty · Starship · VSCode · Helium · Obsidian · Raycast · macOS**.
Base colors come from the ObraXRAY brand palette
(`~/Development/obraxray/branding/Marca/Paleta/paleta.txt`): Deep Forest background,
Mist text, Emerald selection. The brand is built for light surfaces, so the bright
accents a dark editor needs (`mint`, `sand`, `clay`, `sky`, `red`) are derived from the
brand's Emerald and the app's warning/danger/info tones. Ghostty is the reference implementation.

## Tokens (single source of truth)

| Token    | Hex       | Source                         | Role                                     |
|----------|-----------|--------------------------------|------------------------------------------|
| `night`  | `#08211b` | Deep Forest, darker (derived)  | chrome: sidebars, title bars, frames     |
| `bg`     | `#0d2d25` | Deep Forest                    | base background                          |
| `bg_alt` | `#173f35` | Forest                         | raised surfaces, line highlight, borders |
| `sel`    | `#286b55` | Emerald                        | selection, buttons                       |
| `fg`     | `#dce9df` | Mist                           | primary text                             |
| `bright` | `#f5f7f2` | Off White                      | bold, active tab, headings               |
| `gray`   | `#6e9b83` | Sage                           | comments, inactive text                  |
| `dim`    | `#4a6e60` | Sage on Forest (derived)       | line numbers, disabled                   |
| `light`  | `#a9cbb6` | Light Green                    | cursor, path, strings                    |
| `mint`   | `#7fd1a8` | Emerald, lifted (derived)      | prompt, keywords, badges, success, git added |
| `sand`   | `#e3c58a` | app warning `#8a5a0f`, lifted  | types, warnings, git modified            |
| `clay`   | `#e8a68f` | app danger `#9b2c1a`, softened | numbers, durations                       |
| `sky`    | `#8fbfd0` | app info `#2f5f73`, lifted     | functions, links, git branch             |
| `red`    | `#e0705c` | app danger `#9b2c1a`, lifted   | errors only                              |

**Font everywhere:** JetBrains Mono (Nerd Font where glyphs are needed) — also the
brand's mono face — ligatures on, Geist Mono fallback.

## Coverage by app

| App      | Mechanism                                                              | Match      |
|----------|------------------------------------------------------------------------|------------|
| Ghostty  | `ghostty/.config/ghostty/config` (stow) — 0.85 opacity + blur 30        | reference |
| iTerm2   | `iterm2/DynamicProfiles/vesper.json` (fallback, still Vesper colors)   | not themed |
| Starship | `starship/.config/starship.toml` (stow, `obraxray` palette)            | exact      |
| VSCode   | `vscode/.../settings.json` (stow) — `Vesper` theme + ObraXRAY override | near-pixel |
| Helium   | `helium/noir-theme/` (load unpacked; folder name kept so the loaded path still works) | near-pixel |
| Chrome   | same `helium/noir-theme/` manifest (load unpacked)                     | near-pixel |
| Fork     | `defaults` (dark) + manual font/diff                                   | as-far-as-Fork-allows |
| Obsidian | `obsidian/obraxray.css` → vault `.obsidian/snippets/` (enabled)        | near-pixel |
| Raycast  | `assets/raycast-obraxray-theme.url` (open once, import)                | exact      |
| Slack    | Preferences → Themes → Custom: `#08211B,#286B55,#7FD1A8,#E3C58A`       | sidebar    |
| macOS    | Green accent · Light Green highlight · wallpaper                       | system     |

## Terminal ANSI

Same values in Ghostty and the VS Code integrated terminal. The brand has no magenta,
so ANSI magenta is the soft terracotta `clay`.

| Color   | Normal    | Bright    |
|---------|-----------|-----------|
| black   | `#173f35` | `#4a6e60` |
| red     | `#e0705c` | `#f0907e` |
| green   | `#7fd1a8` | `#a9e6c6` |
| yellow  | `#e3c58a` | `#f0dab0` |
| blue    | `#8fbfd0` | `#b7d8e4` |
| magenta | `#e8a68f` | `#f2c2b2` |
| cyan    | `#a9cbb6` | `#c9e0d1` |
| white   | `#dce9df` | `#f5f7f2` |

## Starship segments

Path `light` · branch `sky` · git status `sand` · Node `mint` · duration
`clay` · `❯` `mint` · `✘` `red`.

## macOS

```sh
defaults write -g AppleAccentColor -int 3
defaults write -g AppleHighlightColor -string "0.662745 0.796078 0.713725 Other"
defaults write -g AppleIconAppearanceTheme -string RegularDark
```

Accent 3 is macOS Green, the closest system accent to Emerald; it tints folders,
sidebar selection and controls. Window backgrounds stay stock dark gray — macOS
exposes no setting for them. Liquid Glass stays on Tinted (`NSGlassDiffusionSetting = 1`).

Wallpaper: `assets/wallpaper-obraxray.png` (3024×1964) and
`assets/wallpaper-obraxray-iphone.png` (1290×2796) — Deep Forest radial gradient,
blueprint grid that fades toward the edges, and a Light Green architectural floor plan
(structural axes A–D/1–3, columns, doors, windows, stairs, dimension lines, room labels),
light Sage grain, no logo. The iPhone version is grid only. Dark bottom third keeps the Dock legible.

## Fork — manual steps

`theme = dark` is already set via `defaults`. **Quit and relaunch Fork** for it
to take (Fork can rewrite the pref on quit if it's open).

Then in **Fork → Settings**:

1. **General → Appearance:** Dark (confirm it didn't revert to System).
2. **Fonts:** set the monospace/diff font to **JetBrains Mono**, size ~12.5.
3. **Diff / Syntax highlighting:** pick the darkest available scheme. Map
   mentally to the tokens: added → `mint`, deleted → `red`. Fork has no
   background/accent override — this is the ceiling.

## Helium — load once per profile

Not stowed; Chromium loads it from the repo path, so edits apply on reload.

1. `helium://extensions` → enable **Developer mode** → **Load unpacked** →
   `~/Development/rzlabs/dotfiles/helium/noir-theme`.
2. Repeat in every profile (theme is per-profile).
3. After editing `manifest.json`: hit **Reload** on the extension card.

Mapping: frame/inactive tabs `night`, toolbar `bg_alt`, omnibox `bg`, active tab
text `bright`, toolbar icons `mint`, text `fg`, inactive tab text `gray`, NTP links `mint`.

## Reproduce on a fresh machine

```sh
cd ~/Development/rzlabs/dotfiles
stow ghostty starship vscode
defaults write com.DanPristupov.Fork theme -string dark
# VSCode: code --install-extension raunofreiberg.vesper
# Then run the macOS block above, set the wallpaper, load the Helium theme,
# copy obsidian/obraxray.css into the vault snippets and open the Raycast URL.
```

---

## Previous palettes

- **Sunset** (2026-10-29 → 2026-11-08): night purple `#2a1652` with amber/coral/pink accents, pixel-art sunset wallpaper.
- **Vesper amber** (2026-10-28): `#101010` background with amber/mint accents.
- **Noir** (retired 2026-10-28): strictly grayscale.

Their configs are in git history; only the Sunset wallpaper is committed.
