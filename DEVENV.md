# Dev Machine Blueprint — multi-identity, signed, isolated

The clean-dev-machine spec for this Mac (Apple Silicon, macOS 26). Three
identities that are **structurally impossible to confuse**, SSH commit signing
on every commit, and a dotfiles repo that reproduces the whole thing.

---

## A. Problems this setup kills

| Problem | Old behaviour | Now |
|---|---|---|
| Wrong-identity commits outside project trees | Repos in `~/Desktop`, `~/code`, etc. silently inherited the **work** identity + work key (global `core.sshCommand = ssh -i ~/.ssh/work`) | `useConfigOnly` → git **refuses** to commit until you're in a known context |
| Identity lived in fragile per-repo `.git/config` | A fresh clone forgot its identity until manually set | Identity is decided by **directory**, centrally |
| `-F /dev/null` killed Keychain/agent | passphrases re-typed, agent unused | dropped; `-i key -o IdentitiesOnly=yes` keeps it foolproof *and* uses Keychain |
| No cryptographic identity proof | nothing signed | every commit/tag **SSH-signed**, GitHub/GitLab show *Verified* |
| Only 2 contexts for 3 businesses | ObraXRAY squatted under `personal/` | ObraXRAY is a first-class top-level context |

---

## B. File-system architecture

Keep the established `~/Development` root (it's wired into includeIf, dotfiles,
and tooling — no `~/Projects` reinvention). One tree **per identity**:

```
~/Development/
├── personal/          # identity: github@rzlabs.me   key: personal
│   ├── <apps>             active personal projects (dotfiles, rzlabs, …)
│   ├── experiments/      throwaway prototypes (no identity ceremony)
│   ├── oss/              forks / 3rd-party collabs (e.g. orgamind)
│   └── archive/          dormant — never deleted, just demoted
├── enterprise/        # identity: fabio.fernandes@hypnotic.pt   key: work
│   └── <client/product repos>
├── obraxray/          # identity: obraxray@gmail.com   key: obra
│   ├── app/                  public SaaS product (Next.js+Express+SDK; was obra-segura)
│   ├── app-ghabump/          git worktree of app
│   ├── hq/                   internal ops app (was obraxray-hq)
│   ├── experiments/
│   └── archive/
├── claude-context/    # auto-injected CLAUDE rules (walked by SessionStart hook)
└── .config/
```

**Rule of placement:** *which tree a repo lives in is the single source of truth
for its identity.* Put it in the right tree and you can forget about config.

**Repo naming:** `kebab-case`, no owner prefixes, match the remote slug where
sane. Worktrees: `<repo>-<purpose>` siblings (e.g. `obra-segura-ghabump`).

---

## C. Git multi-account config  (`dotfiles/git/`)

`~/.gitconfig` (base, identity-less + guard):

```ini
[user]
    name = Fábio Fernandes
    useConfigOnly = true            # no guessed email — must be in a context
[includeIf "gitdir:~/Development/personal/"]   { path = ~/.gitconfig-personal }
[includeIf "gitdir:~/Development/enterprise/"]  { path = ~/.gitconfig-work }
[includeIf "gitdir:~/Development/obraxray/"]     { path = ~/.gitconfig-obra }
[gpg]        { format = ssh }
[gpg "ssh"]  { allowedSignersFile = ~/.config/git/allowed_signers }
[commit]     { gpgsign = true }
[tag]        { gpgsign = true }
[push]       { autoSetupRemote = true }
[fetch]      { prune = true }
```

Per-context (email + signing key + forced push key). Example `~/.gitconfig-obra`:

```ini
[user]
    name = ObraXRAY
    email = obraxray@gmail.com
    signingkey = ~/.ssh/obra.pub
[core]
    sshCommand = ssh -i ~/.ssh/obra -o IdentitiesOnly=yes
```

`personal` → `github@rzlabs.me` / `~/.ssh/personal`;
`work` → `fabio.fernandes@hypnotic.pt` / `~/.ssh/work`.

`~/.config/git/allowed_signers` maps email → public key so
`git log --show-signature` verifies locally.

---

## D. SSH architecture  (`dotfiles/ssh/.ssh/config`, perms 600)

One key per identity, ed25519. Host aliases pin the **key**; the directory
pins the **identity**. URLs are self-documenting.

```sshconfig
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentitiesOnly yes
  ServerAliveInterval 60

Host github.com github-personal   { IdentityFile ~/.ssh/personal }  # acct: rzify
Host github-obra                   { IdentityFile ~/.ssh/obra }      # acct: obraxray
Host github-work                   { IdentityFile ~/.ssh/work }      # rzify (redundant)
Host gitlab.com gitlab-work        { IdentityFile ~/.ssh/work }      # acct: fabiomiguelmfernandes
Host gitlab-personal               { IdentityFile ~/.ssh/personal }
Host obraxray-vps    { HostName 178.104.103.183  User root  IdentityFile ~/.ssh/obra }
Host homeassistant   { HostName 192.168.1.138  Port 22222  User root  IdentityFile ~/.ssh/ha_homeassistant }
```

Clone with the alias that names the identity:
`git clone git@github-obra:obraxray/repo.git`.

**Account topology (verified by `ssh -T` per key):**
- GitHub `rzify` — personal + work keys both land here (one personal account).
- GitHub `obraxray` — obra key. The real, clean separation.
- GitLab `fabiomiguelmfernandes` — hosts work *and* `rzlabs.me`.

---

## E. Dotfiles system

`~/Development/personal/dotfiles` → `git@github-personal:rzify/dotfiles.git`,
GNU-stow style. `~/.gitconfig*` and `~/.ssh/config` are **symlinks** into it,
so every config change is version-controlled automatically.

```
dotfiles/
├── git/    .gitconfig .gitconfig-{personal,work,obra} allowed_signers
├── ssh/.ssh/config
├── shell/  .zshrc .zprofile
├── starship/.config/starship.toml
├── claude/themes/noir.json   # linked into every Claude profile
├── agent-skills/  handoff brain-dump reflect   # bin/agent-skills-sync
├── brew/   Brewfile
└── install.sh   # symlinks + brew bundle on a fresh machine
```

New machine: `git clone … && ./install.sh && brew bundle` → identical setup.

---

## F. Environment separation

- **Identity:** by directory (above). Zero overlap.
- **Secrets:** never in dotfiles. `.env` per repo, git-ignored; commit
  `.env.example`. Machine-wide secrets in macOS Keychain. SSH passphrases in
  Keychain (`UseKeychain yes`).
- **Node:** `fnm` (switches version on `cd`, reads `.nvmrc`); real binaries on PATH, no lazy-load shims.
- **Claude Code:** per-directory profile via the `bin/claude` wrapper that sets
  `CLAUDE_CONFIG_DIR` by `$PWD` or git common dir (no native `includeIf` exists).
  `~/.claude-work` (Hypnotic) inside `~/Development/hypnotic`;
  `~/.claude-obraxray` (ObraXRAY, also used for personal) everywhere else.
  `~/.claude` holds the shared commands/hooks/plugins (symlinked into both
  profiles) and is not a login profile. `cc` = `claude --dangerously-skip-permissions`.
  UI: `custom:noir` theme, `bin/claude-statusline` (model · ctx · 5h · 7d · branch;
  also forwards to Orca's status hook), Ghostty notifications, focus view.
- **Agent skills:** `agent-skills/` holds plain `SKILL.md` versions of the
  handoff, brain-dump and reflect mods for agents without mods. `bin/agent-skills-sync`
  symlinks them into `~/.agents/skills` (Codex and others) and `~/.cursor/skills`;
  `--claude-code` adds the Claude Code profiles (off by default, the mods already
  cover them); `--zip` builds `~/Downloads/agent-skills/*.zip` for claude.ai
  (Settings → Capabilities → Skills, re-upload after each edit).
- **Containers:** per-project `docker-compose.yml`; never share a global stack
  across contexts.

---

## G. Security

- ed25519 keys, `600` private / `644` public, `~/.ssh` `700`, config `600`.
- `IdentitiesOnly yes` everywhere → a key is only ever offered where intended
  (no agent leakage between accounts).
- Every commit + tag SSH-signed; `allowed_signers` enables local verify.
- `useConfigOnly` blocks accidental wrong-identity commits.
- Passphrases in Keychain; private keys never leave the machine, never in git.

---

## H. Productivity rules

- **New repo:** create inside the correct identity tree, then
  `git clone git@<alias>:owner/repo.git`. Identity/signing are automatic.
- **Naming:** kebab-case, match remote slug.
- **Archive:** move to `<context>/archive/` — demote, don't delete.
- **Abandoned:** archive after ~90 days idle; keep the git history.
- **Anti-clutter:** active repos live one level under a context; prototypes go
  in `experiments/` and are expected to die.

---

## I. Migration — done vs. your remaining manual steps

**Applied automatically:**
- Created `~/Development/obraxray/`, moved + renamed the repos: `obra-segura`→`app`
  (+ its worktree `app-ghabump`, repaired) and `obraxray-hq`→`hq`; re-pointed
  remotes to `github-obra` (remote slugs unchanged: ObraXRAY.git, obraxray-hq.git).
- Rewrote 612 stale absolute-path references inside the moved repos.
- Rewrote base + per-context gitconfig, added obra context, signing,
  `allowed_signers`, and a clean ssh config. Committed to dotfiles (signed).

**You still need to (web UI / one-time):**
1. Add each **public key as a *Signing* key** so remotes show *Verified*:
   - `~/.ssh/personal.pub` → GitHub `rzify` + GitLab
   - `~/.ssh/obra.pub` → GitHub `obraxray`
   - `~/.ssh/work.pub` → GitLab (+ GitHub if work commits land there)
2. Verify `rzlabs` GitLab push once (`git -C ~/Development/personal/rzlabs push`)
   — auth was confirmed but GitLab was throttling test probes.
3. Re-accept the Claude Code trust dialog when you open the moved repos at their
   new paths (old `~/.claude.json` project entries were left untouched on
   purpose; historical transcripts are immutable history).

---

## J. Clean-machine blueprint (one screen)

```
Identity   = f(directory)            personal | enterprise | obraxray
Key        = f(directory)            forced via core.sshCommand -i, IdentitiesOnly
Signing    = on, per-identity ssh key, Verified on remotes
Guard      = useConfigOnly → no commit outside a context
Aliases    = github-{personal,obra,work} · gitlab-{personal,work}
Dotfiles   = symlinked, signed, one repo, install.sh reproduces everything
Secrets    = Keychain + per-repo .env (git-ignored); never in dotfiles
Rule       = put the repo in the right tree and forget about it
```
```

> Verify the whole chain at any time:
> `git -C <repo> config user.email && git -C <repo> log -1 --show-signature`
```
