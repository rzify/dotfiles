# Global instructions

Top-level rules. Override anything in lower-scoped `claude-context/CLAUDE.md` files only when explicitly stated.

## Identity

- User: **rz** (RzLabs). Operates three git identities on this machine — personal (RzLabs, `~/Development/rzlabs` and `~/Development/keybind-studios`), work (Hypnotic, `~/Development/hypnotic`), and ObraXRAY (`~/Development/obraxray`) — auto-selected by directory via `includeIf` in `~/.gitconfig`, each SSH-signed. Base config uses `useConfigOnly` so git refuses to commit outside a known context. Full blueprint: `~/Development/rzlabs/dotfiles/DEVENV.md`.
- Primary language for the user: pt-PT (native). Code, commits, and documentation: **English** unless the project explicitly uses Portuguese.
- Today's date is dynamically supplied each session; never hardcode dates in generated content.

## Stack (defaults when no project preference is declared)

- **Framework:** Next.js (App Router) + React 19+
- **Language:** TypeScript strict, avoid `any`
- **Styling:** Tailwind + shadcn/ui
- **Runtime/package manager:** `pnpm`
- **Deployment:** Vercel
- **CMS:** Sanity (content-heavy) or WordPress (commerce / Cattleya)

A project's own conventions and lockfile win over these defaults. If a repo uses npm, use npm. If it uses spaces, use spaces.

## Principles

- **Optimize what compounds, eliminate what doesn't.** Architecture, tooling, and habits that pay back daily beat one-off cleverness.
- **No over-engineering, no speculative abstractions.** Three similar lines beats a premature helper. No backwards-compat shims unless asked.
- **Edit existing > create new.** Modify files in place rather than spinning up new ones. Default to fewer files, not more.
- **No comments in code.** Don't write code comments — the code should speak for itself. Only add one if I explicitly ask for it.
- **No async IIFE inside `useEffect`.** Extract the async logic into a named function (e.g. a `useCallback`) and have the effect just guard and call it. The inline `(async () => {…})()` structure reads poorly and buries intent.
- **Don't be a yes-man.** Debate me when you disagree. Say "I think you're wrong because…" with specifics. Push back on decisions that hurt the product, the architecture, or the user. After the discussion, if I still want to proceed, execute fully — no passive-aggressive comments in the code.

## Conventions

- **Commits:** conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `perf:`). Subject line only by default — no body unless I ask. **Never add AI-attribution trailers** (`Co-Authored-By: Claude…`, `Generated with Claude Code`, etc.) to commits or PRs.
- **Branches:** `feat/<slug>`, `fix/<slug>`.
- **PRs:** title <70 chars, body with `## Summary` + `## Test plan`. No AI-attribution footer.
- **Never `--no-verify`** on commits unless explicitly asked. Hook failure → fix the root cause, don't bypass.
- **Never push directly to `main`/`master`.** Always via PR unless explicitly asked.

## Project instructions convention

Project- and parent-folder-level rules live in `claude-context/*.md`, not in root-level `CLAUDE.md` files. A SessionStart hook at `~/.claude/hooks/claude-context-loader.sh` walks `$PWD` → `$HOME` and auto-injects every `claude-context/*.md` it finds.

- To add persistent rules for a folder: create `claude-context/` in it and drop `.md` files inside.
- `~/Development/claude-context/skills.md` carries auto-apply skill hints — different file, different purpose.
- In-repo `CLAUDE.md` files (e.g. inside specific projects) are project-team decisions, not user config — respect them, don't auto-rewrite them.

## Lean setup (since 2026-11-11)

One owner per capability, identical in the Claude app, Orca and the terminal profiles: superpowers (workflow), built-in `/code-review` and `/security-review`, `claude-security` (full scans), `frontend-design` + `antiwebslop`, vendor plugins (vercel, supabase, sanity), playwright, typescript-lsp, obsidian, and the mods from `bin/claude-mods-sync`. No ECC rules, agents, commands or hooks. Removed items are in `~/Archive/claude-setup-backup-2026-11-11/`. Don't add a skill, plugin or mod that duplicates one of these.


## Local environment (this machine)

Minimal, keyboard-driven setup with a black-and-white Noir look. Machine manifest + bootstrap live in `~/Development/rzlabs/dotfiles` (Brewfile, `install.sh`, stow packages, `DEVENV.md`); keep them in sync after any install/uninstall.

- **Terminal:** Ghostty (stock defaults except Noir colors in `~/.config/ghostty/config` → dotfiles symlink, 2026-11-10; iTerm2 kept as fallback and for the `cc-status` Claude Code hook) + pure Zsh + Starship — **no Oh My Zsh / powerlevel10k**.
- **Editor:** VS Code, Vesper theme with a Noir (black & white) color override in `settings.json`.
- **Window manager:** Rectangle (floating snaps — tried AeroSpace tiling, didn't stick).
- **Launcher + clipboard:** Raycast (clipboard history on `⌘⇧M`) — replaced Maccy/Spotlight.
- Ice, Stats, Superwhisper, Bruno, TablePlus, Fathom desktop, Caffeine, OpenClip, Hand Mirror, WezTerm, BlueStacks and Autenticação.gov were uninstalled on 2026-10-28; don't assume them.
- **Containers:** OrbStack (replaces Docker Desktop) — it ships the `docker`/`docker-compose` CLIs; no Homebrew Docker, MySQL or Postgres servers. Run databases in OrbStack.
- **Browser:** Helium (Arc removed 2026-10-28) + Chrome for DevTools. **Git GUI:** Fork (GitFork).
- **Node:** nvm only (no Homebrew `node`); `.zshrc` puts the newest nvm version's `bin` on PATH at startup so `#!/usr/bin/env node` tools (pnpm, yarn) work before lazy-load. Vercel CLI is the `vercel` cask (native binary).
- Aesthetic: Noir v2 (since 2026-11-10, replacing ObraXRAY, Sunset, Vesper amber) — pure black `#000000` backgrounds, `#e6e6e6`/white text, grays for hierarchy, red `#e5534b` only for errors/deletions. Dark appearance, Graphite accent + highlight, Tinted dark icons, black wallpaper `dotfiles/assets/wallpaper-black.png`. Palette tokens in `dotfiles/assets/noir-palette.md`.

Don't suggest the replaced tools (Postman, pgAdmin, AeroSpace, Oh My Zsh, Maccy, WezTerm).

- **Per-context accounts (wrappers in `dotfiles/bin`, first on PATH via `~/.zshrc`, also picked up by Orca):** `claude` sets `CLAUDE_CONFIG_DIR` to `~/.claude-work` (fabio.fernandes@hypnotic.pt) inside `~/Development/hypnotic` (by `$PWD` or git common dir, so Orca worktrees count), else `~/.claude-obraxray` (fabio@tryobraxray.com). `gh`: global active account is `rzify`; inside Hypnotic the wrapper injects `GH_TOKEN` for `fabiomiguelmfernandes`. Orca per-project gh binding: ObraXRAY → rzify, Yetify → fabiomiguelmfernandes.

- **Default model:** `opusplan` (set in `~/.claude/settings.json`) — Opus for plan mode, Sonnet for execution. Override per-session with `/model opus` for heavy refactors or complex debugging; override per-project with a `.claude/settings.json` containing `"model": "opus"`.

- **nvm caveat (non-interactive shells):** `node`/`npm`/`npx` are nvm lazy-load shims that fail in the agent's non-interactive bash with `command not found: _load_nvm` (and can hit `maximum nested function level reached`). Workaround: call the real binary by absolute path — resolve it once with `ls -d ~/.nvm/versions/node/*/bin | tail -1` and prepend to `PATH`, or run scripts directly (e.g. `~/.nvm/versions/node/<ver>/bin/node --experimental-strip-types script.ts`). Run TS that imports project deps from inside the repo so module resolution works.

- **iTerm2 prefs caveat (app running):** While iTerm2 is running, it holds its preferences in memory and periodically rewrites `~/Library/Preferences/com.googlecode.iterm2.plist` from that in-memory state. Editing the plist directly (e.g. via `PlistBuddy`) while iTerm2 is open gets silently reverted, even after a `cfprefsd` cache flush. To change a running profile's settings (e.g. Vesper colors), use the GUI (Settings ⌘, → Profiles) — it updates the in-memory state first, so the write sticks.


- **Home Assistant SSH (this machine):** always connect via the `homeassistant` alias from `~/.ssh/config` (→ 192.168.1.138:22222, root, key `~/.ssh/ha_homeassistant`). Plain `ssh -p 22222 root@192.168.1.138` fails with "Permission denied (publickey)" because the global `IdentitiesOnly yes` pins keys per host alias.
