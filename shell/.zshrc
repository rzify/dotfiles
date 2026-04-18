export ZSH="$HOME/.oh-my-zsh"

# zsh-completions
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

plugins=(
  git
  node
  npm
  yarn
  sudo
  extract
  z
  history
  command-not-found
  vscode
  alias-finder
  fzf
)

source $ZSH/oh-my-zsh.sh

# External plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# Atalhos do history-substring-search
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# Starship prompt
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh

alias ai-styles="~/Development/personal/dev-tools/install-ai-style.sh"
# Claude Code
alias cc="claude --dangerously-skip-permissions"
alias explain="claude --print 'explica este código'"
alias review="claude --print 'review este código, foca em bugs e segurança'"
alias fix="claude --print 'corrige os erros neste código'"

# Scaffold a new project inside ~/Development (use instead of `git init` for auto-setup)
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

. "$HOME/.local/bin/env"
