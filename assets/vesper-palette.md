# Vesper — shared design language

One palette + one font, applied across **WezTerm · VSCode · Fork · Arc**.
WezTerm is the reference implementation; everything else matches it.

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
| WezTerm | `wezterm/.wezterm.lua` (stow)      | reference |
| VSCode  | `vscode/.../settings.json` (stow) — `Vesper` theme + chrome lock | near-pixel |
| Fork    | `defaults` (dark) + manual font/diff | as-far-as-Fork-allows |
| Arc     | in-app Space color (manual)        | manual    |

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

## Arc — manual steps

Arc themes live per-Space, set in-app (not file-configurable).

1. Open the Space switcher → **Edit Theme** on the active Space.
2. Choose a **solid color**, paste hex **`#101010`** (or the darkest swatch).
3. Keep it solid — no gradient — for the flat Vesper look.
4. Optional accent: set the Space tint toward amber `#ffc799` if you want the
   accent echoed in Arc's chrome.
5. Settings → minimize chrome: thin/auto-hiding toolbar, hide unused buttons.
6. Repeat per Space you use (theme is per-Space).

---

## Reproduce on a fresh machine

```sh
cd ~/Development/personal/dotfiles
stow wezterm vscode
defaults write com.DanPristupov.Fork theme -string dark
# VSCode: install the one theme — code --install-extension raunofreiberg.vesper
# Then do the Fork + Arc manual steps above.
```
