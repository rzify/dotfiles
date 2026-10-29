# Sunset — shared design language

One palette + one font, applied across **Ghostty · Starship · VSCode · Helium · macOS**.
Every color is taken from `assets/wallpaper-sunset.png` (pixel-art retro sunset):
night sky for backgrounds, star cream for text, sun and sky bands for accents,
mountain lilac for secondary text. Ghostty is the reference implementation.

## Tokens (single source of truth)

| Token    | Hex       | From the wallpaper   | Role                                   |
|----------|-----------|----------------------|----------------------------------------|
| `night`  | `#1e0f3d` | upper night sky      | chrome: sidebars, title bars, frames   |
| `bg`     | `#2a1652` | night sky            | base background                        |
| `bg_alt` | `#3a2068` | sky purple band      | raised surfaces, line highlight        |
| `sel`    | `#552f8c` | sky violet band      | selection, borders                     |
| `fg`     | `#ffe8c7` | warm stars           | primary text                           |
| `gray`   | `#b07fc0` | lit mountain lilac   | comments, inactive text                |
| `dim`    | `#7a4a8e` | mountain ridge       | line numbers, disabled                 |
| `amber`  | `#ffc799` | horizon glow         | cursor, path, active tab, types        |
| `sun`    | `#ffe0a3` | sun core             | strings, success, git added            |
| `coral`  | `#ff8a5c` | sunset band          | warnings, git modified                 |
| `pink`   | `#ff6f91` | sun base             | prompt, keywords, buttons, badges      |
| `purple` | `#d79be6` | mountain highlight   | functions, durations                   |
| `star`   | `#c6dcff` | blue stars           | numbers, links, git branch             |
| `red`    | `#f0645f` | low sky coral        | errors only                            |

**Font everywhere:** JetBrains Mono (Nerd Font where glyphs are needed),
ligatures on, Geist Mono fallback.

## Coverage by app

| App      | Mechanism                                                              | Match      |
|----------|------------------------------------------------------------------------|------------|
| Ghostty  | `ghostty/.config/ghostty/config` (stow) — 0.8 opacity + blur 30, wallpaper shows through | reference |
| iTerm2   | `iterm2/DynamicProfiles/vesper.json` (fallback)                        | exact      |
| Starship | `starship/.config/starship.toml` (stow, `sunset` palette)              | exact      |
| VSCode   | `vscode/.../settings.json` (stow) — `Vesper` theme + Sunset override   | near-pixel |
| Helium   | `helium/noir-theme/` (load unpacked)                                   | near-pixel |
| Fork     | `defaults` (dark) + manual font/diff                                   | as-far-as-Fork-allows |
| Chrome   | same `helium/noir-theme/` manifest (load unpacked)                     | near-pixel |
| Obsidian | `obsidian/sunset.css` → vault `.obsidian/snippets/` (enabled)          | near-pixel |
| Raycast  | `assets/raycast-sunset-theme.url` (open once, import)                   | exact      |
| Slack    | Preferences → Themes → Custom: `#1E0F3D,#552F8C,#FFE0A3,#FF6F91`        | sidebar    |
| macOS    | Purple accent · pink highlight · colored dark icons · tinted glass · wallpaper | system |

## Terminal ANSI

Same values in Ghostty, iTerm2 and the VS Code integrated terminal. "green" is
the warm sun yellow — the wallpaper has no green, so success/added reads as sunlight.

| Color   | Normal    | Bright    |
|---------|-----------|-----------|
| black   | `#3a2068` | `#7a4a8e` |
| red     | `#f0645f` | `#ff8a7a` |
| green   | `#ffe0a3` | `#fff1c4` |
| yellow  | `#ffc799` | `#ffdcbf` |
| blue    | `#c6dcff` | `#e0ecff` |
| magenta | `#ff6f91` | `#ff9db5` |
| cyan    | `#ffcad8` | `#ffe1ea` |
| white   | `#ffe8c7` | `#ffffff` |

## Starship segments

Path `amber` · branch `star` · git status `coral` · Node `sun` · duration
`purple` · `❯` `pink` · `✘` `red`.

## macOS

```sh
defaults write -g AppleAccentColor -int 5
defaults write -g AppleHighlightColor -string "1.000000 0.678431 0.756863 Other"
defaults write -g AppleIconAppearanceTheme -string RegularDark
killall Dock
```

Finder, System Settings and menus keep the stock dark-gray backgrounds — macOS
exposes no setting for window background color; the purple accent tints folders,
sidebar selection and controls. Liquid Glass stays on Tinted (`NSGlassDiffusionSetting = 1`).

Wallpaper: `assets/wallpaper-sunset.png` — 504×328 pixel art upscaled 6× with
nearest-neighbor to 3024×1964 (night sky with stars, striped sun, four mountain
ridges, dithered water with sun reflection). Dark bottom third keeps the Dock legible.

## Fork — manual steps

`theme = dark` is already set via `defaults`. **Quit and relaunch Fork** for it
to take (Fork can rewrite the pref on quit if it's open).

Then in **Fork → Settings**:

1. **General → Appearance:** Dark (confirm it didn't revert to System).
2. **Fonts:** set the monospace/diff font to **JetBrains Mono**, size ~12.5.
3. **Diff / Syntax highlighting:** pick the darkest available scheme. Map
   mentally to the tokens: added → `sun`, deleted → `red`. Fork has no
   background/accent override — this is the ceiling.

## Helium — load once per profile

Not stowed; Chromium loads it from the repo path, so edits apply on reload.

1. `helium://extensions` → enable **Developer mode** → **Load unpacked** →
   `~/Development/rzlabs/dotfiles/helium/noir-theme`.
2. Repeat in every profile (theme is per-profile).
3. After editing `manifest.json`: hit **Reload** on the extension card.

Mapping: frame/inactive tabs `night`, toolbar `bg_alt`, omnibox `bg`, active tab
text `amber`, toolbar icons `pink`, text `fg`, inactive tab text `gray`, NTP links `amber`.

## Reproduce on a fresh machine

```sh
cd ~/Development/rzlabs/dotfiles
stow ghostty starship vscode
defaults write com.DanPristupov.Fork theme -string dark
# VSCode: code --install-extension raunofreiberg.vesper
# Then run the macOS block above, set the wallpaper, and load the Helium theme.
```

---

## Previous palettes

- **Vesper amber** (2026-10-28): `#101010` background with amber/mint accents.
- **Noir** (retired 2026-10-28): strictly grayscale.

Their configs are in git history; their wallpapers were not committed (size).
