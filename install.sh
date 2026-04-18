#!/usr/bin/env bash
# Bootstrap a fresh macOS machine from this dotfiles repo.
# Run from the repo root: ./install.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "→ Dotfiles root: $DOTFILES"

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "→ Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Brew packages
echo "→ brew bundle"
brew bundle install --file="$DOTFILES/brew/Brewfile"

# 3. Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "→ Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 4. Stow packages (symlink dotfiles into $HOME)
echo "→ stow"
cd "$DOTFILES"
mkdir -p "$HOME/.ssh"
stow -t "$HOME" shell git ssh

# 5. Default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo "→ Setting zsh as default shell"
  chsh -s "$(command -v zsh)"
fi

cat <<'EOF'

✔ Dotfiles installed.

Next steps (manual):
  1. Generate SSH keys:
       ssh-keygen -t ed25519 -C "github@rzlabs.me"        -f ~/.ssh/personal
       ssh-keygen -t ed25519 -C "fabio.fernandes@hypnotic.pt" -f ~/.ssh/work
  2. Add ~/.ssh/personal.pub to personal GitHub
  3. Add ~/.ssh/work.pub to work GitHub + work GitLab
  4. Load keys into keychain:
       ssh-add --apple-use-keychain ~/.ssh/personal ~/.ssh/work
  5. Restart terminal.

EOF
