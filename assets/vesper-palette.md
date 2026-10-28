# Vesper — shared design language

One palette + one font, applied across **Ghostty · VSCode · Fork · Helium**.
Ghostty is the reference implementation; everything else matches it.

## Tokens (single source of truth)

| Token   | Hex       | Role                                          |
|---------|-----------|-----------------------------------------------|
| `bg`    | `#101010` | base background                               |
| `bg_alt`| `#161616` | titlebar / active surfaces                    |
| `fg`    | `#e0e0e0` | primary text                                  |
| `white` | `#ffffff` | max contrast                                  |
| `amber` | `#ffc799` | **the accent** — cursor, active tab, links    |
| `mint`  | `#99ffe4` | secondary — strings, success, git-added       |
| `red`   | `#ff8080` | errors / git-deleted only                     |
| `gray`  | `#8b8b8b` | comments, inactive                            |
| `dim`   | `#535353` | borders, disabled                             |
| `sel`   | `#2a2a2a` | selection / hover surface                     |

**Font everywhere:** JetBrains Mono (Nerd Font where glyphs are needed),
ligatures on, Geist Mono fallback.

## Coverage by app

| App     | Mechanism                          | Match    |
|---------|------------------------------------|----------|
| Ghostty | `ghostty/.config/ghostty/config` (stow) | reference |
| VSCode  | `vscode/.../settings.json` (stow) — `Vesper` theme + chrome lock | near-pixel |
| Fork    | `defaults` (dark) + manual font/diff | as-far-as-Fork-allows |
| Helium  | `helium/noir-theme/` (load unpacked) | manual    |

---

## Fork — manual steps

`theme = dark` is already set via `defaults`. **Quit and relaunch Fork** for it
to take (Fork can rewrite the pref on quit if it's open).

Then in **Fork → Settings**:

1. **General → Appearance:** Dark (confirm it didn't revert to System).
2. **Fonts:** set the monospace/diff font to **JetBrains Mono**, size ~12.5.
3. **Diff / Syntax highlighting:** pick the darkest available scheme so diff
   backgrounds read `#101010`-ish. Map mentally to the tokens:
   - added → mint `#99ffe4`
   - deleted → red `#ff8080`
   - Fork has no background/accent override — this is the ceiling. Good enough
     for cohesion, not a pixel match.

## Reproduce on a fresh machine

```sh
cd ~/Development/personal/dotfiles
stow ghostty vscode
defaults write com.DanPristupov.Fork theme -string dark
# VSCode: install the one theme — code --install-extension raunofreiberg.vesper
# Then do the Fork manual steps above and load the Helium theme below.
```

---

## Noir — wallpaper-derived override

Sampled from `assets/wallpaper-noir.png` (Kai Notebook NOIR Desktop). Strictly
grayscale; replaces the Vesper amber/mint/red accents in Starship, VSCode and
iTerm2.

| Token | Hex       | Role                          |
|-------|-----------|-------------------------------|
| `bg`  | `#090909` | base background               |
| `alt` | `#0e0e0e` | raised surfaces               |
| `sel` | `#242424` | selection, borders, hover     |
| `dim` | `#4e4e4e` | comments, inactive            |
| `mid` | `#6a6a6a` | ANSI mid step (interpolated)  |
| `gray`| `#8b8b8b` | secondary text, strings       |
| `fg`  | `#aaaaaa` | primary text                  |
| `hi`  | `#afafaf` | cursor, keywords, active tab  |

Applied via: `~/.config/starship.toml` (`noir` palette), `iterm2/DynamicProfiles/vesper.json`
(live-reloads, no plist edit), `ghostty/.config/ghostty/config` (primary terminal, stow), VSCode `workbench.colorCustomizations` +
`editor.tokenColorCustomizations` under `[Vesper]`, `helium/noir-theme/` (Chrome theme manifest).

### Helium — load once per profile

Not stowed; Chromium loads it from the repo path, so edits apply on reload.

1. `helium://extensions` → enable **Developer mode** → **Load unpacked** →
   `~/Development/personal/dotfiles/helium/noir-theme`.
2. Repeat in every profile (theme is per-profile). It replaces the
   "Customize" grey user color.
3. After editing `manifest.json`: hit **Reload** on the extension card.

Mapping: frame/inactive tabs `bg`, toolbar + active tab `alt`, omnibox inset
`bg`, active tab text `hi`, inactive tab text `dim`, icons/bookmarks `gray`.
