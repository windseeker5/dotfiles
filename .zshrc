# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Zinit Plugin Manager
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Initialize completion system
autoload -Uz compinit
compinit

### Plugins loaded via Zinit
# Powerlevel10k prompt
zinit light romkatv/powerlevel10k


# Zsh autosuggestions - with turbo mode (wait"0")
zinit ice wait"0" lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions


# Zsh syntax highlighting - must be loaded last
zinit ice wait"0" lucid
zinit light zsh-users/zsh-syntax-highlighting

# FZF integration
zinit ice lucid wait"0" from"gh-r" as"program"
zinit light junegunn/fzf
zinit snippet /usr/share/fzf/key-bindings.zsh
zinit snippet /usr/share/fzf/completion.zsh

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias vim='nvim'
alias v='nvim'
alias n='nnn'
alias music='cmus'
alias audio='pulsemixer'
alias cat='bat'
alias himalaya='RUST_LOG=error himalaya'

# nnn configuration
export NNN_PLUG='p:preview-tui;o:fzopen'
export NNN_FIFO=/tmp/nnn.fifo
export NNN_COLORS='4321'
export NNN_TRASH=1

# Key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# FZF colors - Catppuccin Mocha
export FZF_DEFAULT_OPTS='--color=fg:#cdd6f4,bg:#1e1e2e,hl:#89b4fa --color=fg+:#cdd6f4,bg+:#45475a,hl+:#89b4fa'

# Environment variables
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER=pixman
export PATH=~/.npm-global/bin:$PATH

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export NNN_TRASH=0
