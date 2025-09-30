#!/usr/bin/env zsh
# macOS ZSH Configuration

# === CORE SETUP ===
# Create cache directory for zsh completions
[[ ! -d ~/.cache/zsh ]] && mkdir -p ~/.cache/zsh

# === ZSH CONFIGURATION ===

# Performance optimizations
setopt AUTO_CD                   # cd by typing directory name if it's not a command
setopt CORRECT                   # command auto-correction
setopt COMPLETE_ALIASES          # complete aliases
setopt ALWAYS_TO_END             # cursor to end if word completed
setopt LIST_AMBIGUOUS            # complete as much as possible before showing list
setopt GLOB_COMPLETE             # show autocompletion menu with globs
setopt PUSHD_IGNORE_DUPS         # don't push multiple copies of same dir onto stack
setopt PUSHD_SILENT              # don't print dir stack after pushd/popd

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry
setopt HIST_VERIFY               # Don't execute immediately upon history expansion

# Completion system
autoload -U compinit
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION -i

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Better completion menu
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# Key bindings (emacs mode for better terminal compatibility)
bindkey -e
bindkey '^R' history-incremental-search-backward

# === ENVIRONMENT SETUP ===

# Warp terminal compatibility
warpify_support() {
    # Detect if we're in a Warp-capable environment
    local warp_detected=false

    # Check for Warp terminal program
    [[ "$TERM_PROGRAM" == "WarpTerminal" ]] && warp_detected=true

    # Check for Warp environment variables
    [[ -n "$WARP_IS_LOCAL_SHELL_SESSION" ]] && warp_detected=true

    # Check for SSH with Warp forwarding
    if [[ -n "$SSH_CONNECTION" ]]; then
        # Look for Warp-specific SSH forwarding
        [[ -n "$SSH_TTY" && -n "$WARP_HONOR_PS1" ]] && warp_detected=true

        # Check for forwarded Warp socket
        [[ -S "/tmp/warp-$USER.sock" ]] && warp_detected=true
    fi

    if [[ "$warp_detected" == true ]]; then
        export WARP_ENABLED=1

        # Enhanced remote session support
        if [[ -n "$SSH_CONNECTION" ]]; then
            export WARP_REMOTE_SESSION=1

            # Send Warp initialization hook for remote sessions only
            printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "hostname": "%s", "remote": true}}\x9c' \
                "$HOSTNAME_LC"

            # Configure for optimal remote Warp performance
            export TERM="${TERM:-xterm-256color}"
            stty -ixon  # Disable XON/XOFF flow control for better responsiveness
        fi
    fi
}

# macOS system configuration
macos_profile() {
    # Performance optimization flag
    export MACOS_OPTIMIZED=1
    
    # Homebrew integration
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    fi

    # LM Studio CLI integration
    export PATH="$PATH:/Users/jeffreypidcock/.lmstudio/bin"
    # Rust/Cargo integration
    export PATH="$PATH:/Users/jpdck/.cargo/bin"

    # Bun integration
    export PATH="/Users/jpdck/.bun/bin:$PATH"
    
    # Terminal optimizations
    [[ "$TERM_PROGRAM" == "Apple_Terminal" ]] && export TERM="xterm-256color"
}

# === TOOL INTEGRATIONS ===

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Zoxide (better cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Direnv (automatic environment loading)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Bat configuration (better cat)
if command -v bat >/dev/null 2>&1; then
  export PAGER="bat"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# FZF configuration
if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh

  # Use fd and bat for FZF previews
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi

  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:500 {}" --preview-window=right:50%'
  fi

  if command -v eza >/dev/null 2>&1; then
    export FZF_ALT_C_OPTS='--preview "eza --tree --color=always {} | head -200" --preview-window=right:50%'
  fi
fi

# Conda integration
# if command -v conda >/dev/null 2>&1; then
#   eval "$(conda shell.zsh hook 2>/dev/null)"
# fi

# ZSH plugins from Homebrew
if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
  source /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

if [[ -f /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
    # Bind keys after plugin is loaded
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
  fi

# === ALIASES ===

# Directory Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# File Operations
alias cp='cp -iv'     # interactive, verbose
alias mv='mv -iv'     # interactive, verbose
alias rm='rm -i'      # interactive
alias mkdir='mkdir -pv' # create parent dirs, verbose

# Enhanced File Listing (eza)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lhga --icons --git --color=auto --group-directories-first'
  alias ll='eza -lha --icons --git --color=auto --group-directories-first'
  alias la='eza -la --icons --git --color=auto --group-directories-first'
  alias l='eza -F --icons --git --color=auto --group-directories-first'
  alias tree='eza --tree --icons --color=auto --group-directories-first'
fi

# Enhanced File Viewing (bat)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  alias less='bat'
fi

# Git Shortcuts
alias g='git'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline'
alias gp='git push'
alias gpl='git pull'

# Development Tools
if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit'
fi

if command -v gh >/dev/null 2>&1; then
  alias ghpr='gh pr create'
  alias ghprs='gh pr status'
  alias ghpv='gh pr view'
  alias ghrepo='gh repo view --web'
fi

# TMUX Management
if command -v tmux >/dev/null 2>&1; then
  alias tm='tmux'
  alias tma='tmux attach'
  alias tmls='tmux list-sessions'
  alias tmks='tmux kill-session'
fi

# Docker with Colima
if command -v colima >/dev/null 2>&1; then
  alias docker-start='colima start'
  alias docker-stop='colima stop'
  alias docker-status='colima status'
fi

# macOS Specific
alias plistbuddy="/usr/libexec/PlistBuddy"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
alias free='vm_stat'  # macOS memory equivalent

# Productivity
alias please='sudo'
alias grep='grep --color=auto'
alias df='df -h'      # human readable
alias du='du -h'      # human readable
alias ps='ps aux'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc'

# Quick Editing
alias zshconfig='hx ~/.zshrc'
alias gitconfig='hx ~/.gitconfig'

# === FUNCTIONS ===

# Directory Management
take() { mkdir -p "$1" && cd "$1"; }

# File Finding (avoid fd conflict)
ff() { find . -type f -name "*$1*" 2>/dev/null; }
fdir() { find . -type d -name "*$1*" 2>/dev/null; }

# Process Management
psg() { ps aux | grep -v grep | grep "$@" -i --color=auto; }

# Network Utilities
myip() { curl -s ipinfo.io/ip; echo; }
localip() { ipconfig getifaddr en0; }

# Performance Monitoring (macOS)
cpu() { top -l 1 | grep "CPU usage"; }
meminfo() { vm_stat | head -6; }

# === SECURITY & AUTHENTICATION ===

# SSH Agent Config - 1Password by default, Secretive for specific hosts via SSH config
export SSH_AUTH_SOCK="/Users/jeffreypidcock/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# GPG Configuration
export GPG_TTY=$(tty)
gpgconf --launch gpg-agent

# === INITIALIZATION ===

# Initialize environment setup
warpify_support
macos_profile

# 1Password Service Account Token
if command -v security >/dev/null 2>&1; then
  OP_TOKEN=$(security find-generic-password -a "$USER" -s "op-service-token" -w 2>/dev/null)
  if [[ -n "$OP_TOKEN" ]]; then
    export OP_SERVICE_ACCOUNT_TOKEN="$OP_TOKEN"
  fi
  unset OP_TOKEN
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

