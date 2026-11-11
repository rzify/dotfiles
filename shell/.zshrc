typeset -U path fpath
path=($HOME/Development/rzlabs/dotfiles/bin $HOME/.local/bin /opt/homebrew/bin /opt/homebrew/sbin $path)
fpath=(/opt/homebrew/share/zsh-completions /opt/homebrew/share/zsh/site-functions $fpath)

export EDITOR=vim VISUAL="code --wait"
export LESS='-R -F -i -M --mouse --incsearch'
export MANPAGER="sh -c 'col -bx | bat -plman'"
export BAT_THEME=ansi
export CLICOLOR=1 LS_COLORS='di=1;37:ln=3;37:ex=4;37:or=31:mi=31'
export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_BUNDLE_FILE=$HOME/Development/rzlabs/dotfiles/brew/Brewfile

autoload -Uz compinit
() {
  setopt local_options extended_glob
  local dump=${ZDOTDIR:-$HOME}/.zcompdump
  local -a fresh=($dump(N.mh-24))
  if (( $#fresh )); then
    compinit -C -d $dump
  else
    compinit -i -d $dump
    touch $dump
  fi
  [[ $dump.zwc -nt $dump ]] || zcompile -R -- $dump.zwc $dump
}
_comp_options+=(globdots)

zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache
zstyle ':completion:*' rehash true
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:*:*:users' ignored-patterns '_*'
zstyle ':completion:*:functions' ignored-patterns '_*'

HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_FCNTL_LOCK HIST_VERIFY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT INTERACTIVE_COMMENTS NO_BEEP NO_FLOW_CONTROL
DIRSTACKSIZE=20
WORDCHARS='*?_-[]~&;!#$%^(){}<>'

bindkey -e
bindkey ' ' magic-space
bindkey '^[[H' beginning-of-line '^[[F' end-of-line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
_fg_toggle() {
  if [[ -z $BUFFER ]]; then
    BUFFER=fg
    zle accept-line
  else
    zle push-input
  fi
}
zle -N _fg_toggle
bindkey '^Z' _fg_toggle

_cached_init() {
  local name=$1 bin=${commands[$2]}
  shift 2
  [[ -n $bin ]] || return
  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init
  local f=$dir/$name-${${bin:A}//[^[:alnum:].]/_}.zsh
  if [[ ! -s $f ]]; then
    mkdir -p $dir
    rm -f $dir/$name-*.zsh(N) $dir/$name-*.zsh.zwc(N)
    "$@" >| $f || { rm -f $f; return 1 }
    zcompile -R -- $f.zwc $f
  fi
  source $f
}

export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
_fzf_noir_colors="fg:#b3b3b3,bg:-1,hl:#ffffff,fg+:#ffffff,bg+:#0f0f0f,hl+:#ffffff,info:#555555,prompt:#ffffff,pointer:#ffffff,marker:#e6e6e6,spinner:#555555,header:#888888,border:#1a1a1a"
export FZF_DEFAULT_OPTS="--height 40% --layout reverse --border none --info inline --color $_fzf_noir_colors"
FZF_ALT_C_COMMAND=

_cached_init starship starship sh -c 'starship init zsh --print-full-init | grep -Ev "^(RPROMPT|PROMPT2)="'
PROMPT2='%F{8}∙%f '
_cached_init zoxide zoxide zoxide init zsh
_cached_init fzf fzf fzf --zsh
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"

source /opt/homebrew/share/fzf-tab/fzf-tab.zsh
zstyle ':fzf-tab:*' fzf-flags --color "$_fzf_noir_colors"
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath'

AUTOPAIR_SPC_WIDGET=magic-space
AUTOPAIR_BKSPC_WIDGET=backward-delete-char
source /opt/homebrew/share/zsh-autopair/autopair.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#555555"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

cc() { claude --dangerously-skip-permissions "$@"; }

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#ffffff'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ffffff'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#ffffff'
ZSH_HIGHLIGHT_STYLES[function]='fg=#ffffff'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#ffffff,underline'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#b3b3b3'
ZSH_HIGHLIGHT_STYLES[path]='fg=#e6e6e6,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#b3b3b3'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#b3b3b3'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#888888'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#888888'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#555555'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#e5534b'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=#ffffff,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=#e5534b'

_load_highlighting() {
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
  _zsh_autosuggest_bind_widgets
}

source $HOME/.local/share/zsh-defer/zsh-defer.plugin.zsh
zsh-defer _load_highlighting

