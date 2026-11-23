#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREW=/home/linuxbrew/.linuxbrew

sudo apt-get update
sudo apt-get install -y build-essential curl file git procps

if [ ! -x "$BREW/bin/brew" ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$BREW/bin/brew" shellenv)"
brew bundle install --file="$DOTFILES/wsl/Brewfile"

cd "$DOTFILES"
mkdir -p "$HOME/.config" "$HOME/.ssh"
stow -t "$HOME" git starship
[ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
[ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.pre-dotfiles"
sed "s#/opt/homebrew#$BREW#g" "$DOTFILES/shell/.zshrc" > "$HOME/.zshrc"

if [ ! -x "$HOME/.local/bin/claude" ]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
for profile in "$HOME/.claude" "$HOME/.claude-obraxray" "$HOME/.claude-work"; do
  mkdir -p "$profile/themes"
  ln -sfn "$DOTFILES/claude/themes/noir.json" "$profile/themes/noir.json"
done
mkdir -p "$HOME/.claude-obraxray" "$HOME/.claude-work"
"$DOTFILES/claude/kit/link-profile" "$HOME/.claude-obraxray" "$HOME/.claude-work"

ZSH_BIN="$BREW/bin/zsh"
grep -qx "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
[ "$SHELL" = "$ZSH_BIN" ] || chsh -s "$ZSH_BIN"

cat <<'MSG'

Done. Next:
  1. Windows: run wsl/windows-setup.ps1 in PowerShell (light mode + white wallpaper).
  2. Windows Terminal: paste wsl/windows-terminal-noir.json into settings.json "schemes",
     set the WSL profile colorScheme to "Noir" and font to "JetBrainsMono Nerd Font".
  3. Copy SSH keys or generate new ones (see DEVENV.md), then `claude` to log in.
  4. Run `bin/claude-mods-sync` once the Claude profiles exist.
MSG
