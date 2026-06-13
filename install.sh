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

# 3. Stow packages (symlink dotfiles into $HOME)
# Pure Zsh + Starship — no Oh My Zsh, no prompt framework.
echo "→ stow"
cd "$DOTFILES"
mkdir -p "$HOME/.ssh" "$HOME/.config"
stow -t "$HOME" shell git ssh

# 4. Default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo "→ Setting zsh as default shell"
  chsh -s "$(command -v zsh)"
fi

# 5. macOS system defaults (monochrome / minimal)
echo "→ macOS defaults"
"$DOTFILES/bin/macos-setup.sh"

# 6. launchd agents (weekly Downloads cleanup)
echo "→ launchd agents"
mkdir -p "$HOME/Library/LaunchAgents"
ln -sf "$DOTFILES/launchd/com.rz.clean-downloads.plist" "$HOME/Library/LaunchAgents/com.rz.clean-downloads.plist"
launchctl bootout "gui/$(id -u)/com.rz.clean-downloads" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.rz.clean-downloads.plist"

cat <<'EOF'

✔ Dotfiles installed.

Next steps (manual — full reference in DEVENV.md):
  1. Generate the three SSH identity keys:
       ssh-keygen -t ed25519 -C "Fábio Fernandes <obraxray@gmail.com>"        -f ~/.ssh/personal
       ssh-keygen -t ed25519 -C "Fábio Fernandes <fabio.fernandes@hypnotic.pt>" -f ~/.ssh/work
       ssh-keygen -t ed25519 -C "Fábio Fernandes <obraxray@gmail.com>"        -f ~/.ssh/obra
  2. Add each *.pub to the matching host:
       personal → GitHub (RzLabs)
       work     → GitHub + GitLab (Hypnotic)
       obra     → ObraXRAY GitHub
  3. Load keys into the keychain:
       ssh-add --apple-use-keychain ~/.ssh/personal ~/.ssh/work ~/.ssh/obra
  4. Add the three signing pubkeys to GitHub/GitLab for "Verified" badges.
  5. System Settings → Appearance: Dark · Graphite accent · Graphite highlight ·
     Tinted icons · solid #000000 wallpaper (not scriptable on Tahoe).
  6. Grant Rectangle Accessibility permission and launch it.
  7. Restart terminal.

EOF
