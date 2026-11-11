#!/usr/bin/env bash
# Apply rz's monochrome, distraction-free macOS system defaults.
# Idempotent — safe to re-run. Companion to DEVENV.md.
# Usage: ./bin/macos-setup.sh

set -euo pipefail

echo "→ Applying macOS system defaults (monochrome / minimal)"

# ── Appearance (Noir: black & white) ────────────────────────────────────────
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
defaults write NSGlobalDomain AppleAccentColor -int -1
defaults write NSGlobalDomain AppleHighlightColor -string "0.847059 0.847059 0.862745 Graphite"
defaults write NSGlobalDomain AppleIconAppearanceTheme -string TintedDark
defaults write com.DanPristupov.Fork theme -string dark

# ── Dock ──────────────────────────────────────────────────────────────────────
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock static-only -bool false
defaults write com.apple.dock mru-spaces -bool false   # don't reorder spaces
defaults write com.apple.WindowManager StandardHideWidgets -bool false

DOCK_APPS=(
  "/Applications/Helium.app"
  "/Applications/Ghostty.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Fork.app"
  "/Applications/Claude.app"
  "/Applications/Notion.app"
  "/Applications/Obsidian.app"
  "/Applications/Slack.app"
  "/Applications/WhatsApp.app"
)
defaults write com.apple.dock persistent-apps -array
for app in "${DOCK_APPS[@]}"; do
  [ -d "$app" ] || continue
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
done

# ── Desktop / Finder ───────────────────────────────────────────────────────────
defaults write com.apple.finder CreateDesktop -bool true
defaults write com.apple.WindowManager StandardHideDesktopIcons -bool true
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
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
# Note: Reduce Motion lives under com.apple.universalaccess on Tahoe and is
# SIP-protected — toggle manually in System Settings → Accessibility → Display.

killall Dock Finder SystemUIServer 2>/dev/null || true

cat <<'EOF'

✔ macOS defaults applied.

Manual (not scriptable):
  • Wallpaper: assets/wallpaper-black.png (or Wallpaper → Colors → Black)
  • Log out and back in so every app picks up the Graphite accent
  • See assets/noir-palette.md for per-app steps (Helium, Raycast, Slack, Fork)

EOF
