#!/usr/bin/env bash
# Apply rz's monochrome, distraction-free macOS system defaults.
# Idempotent — safe to re-run. Companion to DEVENV.md.
# Usage: ./bin/macos-setup.sh

set -euo pipefail

echo "→ Applying macOS system defaults (monochrome / minimal)"

# ── Appearance ──────────────────────────────────────────────────────────────
# Note: Dark mode, Graphite accent/highlight, and Tinted icons are set in
# System Settings → Appearance (no reliable defaults key on Tahoe). This script
# covers everything that IS scriptable.

# ── Dock ──────────────────────────────────────────────────────────────────────
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock static-only -bool true
defaults write com.apple.dock mru-spaces -bool false   # don't reorder spaces

# ── Desktop / Finder ───────────────────────────────────────────────────────────
defaults write com.apple.finder CreateDesktop -bool false          # hide all desktop icons
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" # list view default
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf" # search current folder
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true        # show dotfiles
# Don't write .DS_Store on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Input / speed ──────────────────────────────────────────────────────────────
defaults write NSGlobalDomain KeyRepeat -int 2          # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false  # repeat over accents
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ── Screenshots → dedicated folder, no shadow, png ──────────────────────────────
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ── Misc QoL ────────────────────────────────────────────────────────────────────
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001       # instant window resize
defaults write com.apple.universalaccess reduceMotion -bool true     # snappier, less animation
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

killall Dock Finder SystemUIServer 2>/dev/null || true

cat <<'EOF'

✔ macOS defaults applied.

Manual (System Settings → Appearance — not scriptable on Tahoe):
  • Appearance:           Dark
  • Accent color:         Graphite
  • Highlight color:      Graphite      ← kills blue selection highlight
  • Icon & widget style:  Tinted (neutral graphite)   ← near-monochrome app icons
  • Wallpaper:            solid #000000 (Wallpaper → Color → custom)

EOF
