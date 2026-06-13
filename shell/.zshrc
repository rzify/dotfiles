# ╭──────────────────────────────────────────────────────────────╮
# │  Zsh · lean pure-zsh (no Oh My Zsh)                            │
# │  starship · zoxide · atuin · fzf · lazy nvm · direnv          │
# ╰──────────────────────────────────────────────────────────────╯

# ── Completions ───────────────────────────────────────────────────
fpath=("$(brew --prefix)/share/zsh-completions" $fpath)
autoload -Uz compinit
# Rebuild the dump at most once a day; -C skips the security check otherwise.
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n $_zcompdump(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── History ───────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY EXTENDED_HISTORY

# ── Shell options ─────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS
setopt NO_BEEP GLOB_DOTS

# ── Keybindings ───────────────────────────────────────────────────
bindkey -e  # emacs
autoload -Uz history-beginning-search-backward history-beginning-search-forward
zle -N history-beginning-search-backward
zle -N history-beginning-search-forward
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward

# ── Plugins (syntax-highlighting MUST be sourced last) ────────────
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#535353"   # Vesper dim
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── Tooling ───────────────────────────────────────────────────────
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"                       # z <dir> to jump, zi to pick
eval "$(atuin init zsh --disable-up-arrow)"     # Ctrl+R magic history
source <(fzf --zsh)                             # native fzf keybindings + completion
eval "$(direnv hook zsh)"

# ── Lazy nvm (saves ~200ms; loads on first node/npm/npx/nvm call) ──
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
  unset -f nvm node npm npx 2>/dev/null
  source "/opt/homebrew/opt/nvm/nvm.sh"
  [[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]] && \
    source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}
nvm()  { _load_nvm; nvm "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm "$@"; }
npx()  { _load_nvm; npx "$@"; }

# ── Aliases · modern CLI ──────────────────────────────────────────
alias ls='eza --group-directories-first --icons'
alias ll='eza -lhg --group-directories-first --icons --git'
alias la='eza -lahg --group-directories-first --icons --git'
alias lt='eza --tree --level=2 --icons --group-directories-first'
alias cat='bat'
alias f='fd'
alias reload='exec zsh'

# ── Aliases · git (ported from the OMZ git plugin) ────────────────
alias g='git'
alias gst='git status -sb'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gf='git fetch'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gbd='git branch -d'
alias grb='git rebase'
alias gss='git stash'
alias gsp='git stash pop'
alias glog='git log --oneline --graph --decorate -20'

# ── Aliases · pnpm / npm ──────────────────────────────────────────
alias pn='pnpm'
alias pi='pnpm install'
alias pa='pnpm add'
alias pad='pnpm add -D'
alias prm='pnpm remove'
alias pdev='pnpm dev'
alias pb='pnpm build'
alias pl='pnpm lint'
alias pt='pnpm test'
alias px='pnpm dlx'
alias nr='npm run'

# ── Aliases · docker ──────────────────────────────────────────────
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dps='docker ps'
alias dlog='docker logs -f'

# ── Aliases · Claude / dev tooling (yours) ────────────────────────
alias ai-styles="~/Development/personal/dev-tools/install-ai-style.sh"
alias cc="claude --dangerously-skip-permissions"
alias explain="claude --print 'explica este código'"
alias review="claude --print 'review este código, foca em bugs e segurança'"
alias fix="claude --print 'corrige os erros neste código'"
alias cc-help="cat ~/claude-cheatsheet.md"

# GitHub Copilot CLI — global AGENTS.md
export COPILOT_CUSTOM_INSTRUCTIONS_DIRS="$HOME/.copilot"

# ── extract: one command for any archive (replaces OMZ extract) ───
extract() {
  [[ -f "$1" ]] || { echo "extract: '$1' is not a file"; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.7z)             7z x    "$1" ;;
    *) echo "extract: don't know how to extract '$1'" ; return 1 ;;
  esac
}

# ── gnew: scaffold a new project inside ~/Development ─────────────
gnew() {
  if [[ "$PWD" != "$HOME/Development/"* ]]; then
    echo "gnew: must be run inside ~/Development/"
    return 1
  fi

  command git init
  local project_name="${PWD##*/}"
  local config_dir="$HOME/Development/.config"

  if [[ -f "$config_dir/CLAUDE-TEMPLATE.md" ]] && [[ ! -f "CLAUDE.md" ]]; then
    sed -e "s/{{PROJECT_NAME}}/${project_name}/g" \
        -e "s/{{DATE}}/$(date +%Y-%m-%d)/g" \
        "$config_dir/CLAUDE-TEMPLATE.md" > CLAUDE.md
  fi

  [[ ! -f ".editorconfig" ]] && [[ -f "$config_dir/.editorconfig" ]] && cp "$config_dir/.editorconfig" .editorconfig
  [[ ! -f ".prettierrc" ]] && [[ -f "$config_dir/.prettierrc" ]] && cp "$config_dir/.prettierrc" .prettierrc
  [[ ! -f ".eslintrc.json" ]] && [[ -f "$config_dir/.eslintrc.json" ]] && cp "$config_dir/.eslintrc.json" .eslintrc.json
  [[ ! -f ".gitignore" ]] && [[ -f "$config_dir/gitignore-template" ]] && cp "$config_dir/gitignore-template" .gitignore

  mkdir -p src/{app,components,lib,services,hooks,types,styles} public

  [[ ! -f ".env.example" ]] && cat > .env.example <<'EOF'
# App
NEXT_PUBLIC_SITE_URL=

# Sanity (if used)
NEXT_PUBLIC_SANITY_PROJECT_ID=
NEXT_PUBLIC_SANITY_DATASET=
SANITY_API_TOKEN=

# Supabase (if used)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Stripe (if used)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=

# Sentry (if used)
NEXT_PUBLIC_SENTRY_DSN=
SENTRY_AUTH_TOKEN=
EOF

  echo "✔ Project scaffolded: ${project_name}"
}

# ── Local bin env ─────────────────────────────────────────────────
. "$HOME/.local/bin/env"

# ── Syntax highlighting — keep this the LAST sourced line ─────────
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=#535353'
