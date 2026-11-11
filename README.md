# dotfiles

Configuration for macOS dev environment. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```
dotfiles/
├── install.sh          # bootstrap a fresh Mac
├── shell/              # zsh
│   └── .zshrc
├── git/                # global git config + per-identity includes
│   ├── .gitconfig
│   ├── .gitconfig-personal
│   └── .gitconfig-work
├── ssh/                # SSH config (keys are NEVER tracked)
│   └── .ssh/config
└── brew/
    └── Brewfile        # all brew formulae, casks, mas apps
```

## Install on a fresh Mac

```sh
git clone git@github.com:<you>/dotfiles.git ~/Development/personal/dotfiles
cd ~/Development/personal/dotfiles
./install.sh
```

The script installs Homebrew → brew packages → runs `stow` to symlink everything into `$HOME` → sets zsh as default shell. Then it prints manual steps for SSH keys.

## Updating

Because every tracked file in `$HOME` is a symlink into this repo, just edit normally and commit:

```sh
cd ~/Development/personal/dotfiles
git add -u
git commit -m "update zshrc"
git push
```

## Updating the Brewfile

After installing new brew packages, capture them:

```sh
cd ~/Development/personal/dotfiles
brew bundle dump --file=brew/Brewfile --force
```

## Adding a new file to the repo

1. Move the file into the right package: `mv ~/.newconfig shell/.newconfig`
2. Re-stow: `stow -t "$HOME" shell`
3. Commit.

## What is NOT tracked (intentionally)

- SSH private keys (`~/.ssh/personal`, `~/.ssh/work`) — regenerate per machine
- Anything with credentials (`.env`, `.claude.json`, `.npmrc` with tokens)
- Shell history, caches, compiled completions
