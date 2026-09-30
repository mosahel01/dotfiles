# --- environment & paths ---
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export PATH=$PATH:$HOME/.local/opt/go/bin
export PYTHONDONTWRITEBYTECODE=1
# export GOPATH="$HOME/.go"
# export PATH="$HOME/.go/bin:$PATH"
# export GROFF_NO_SGR=1

# --- xdg & config ---
xdg_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
ZSH_Z_DATA="$HOME/.local/share/zsh/z_data"

# --- prompt ---
export STARSHIP_CONFIG="$xdg_config_dir/starship.toml"
eval "$(starship init zsh)"

# --- history ---
HISTFILE=~/.zsh_history
SAVEHIST=10000
HISTSIZE=10000
setopt append_history
setopt share_history
setopt extended_history
unsetopt prompt_cr
unsetopt prompt_sp

# --- vi mode ---
export KEYTIMEOUT=1
bindkey -v
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]]; then
    printf '\e[1 q' # Steady block cursor for Normal mode
    # RPROMPT='%F{yellow}[NORMAL]%f'
    RPROMPT=''
  else
    printf '\e[5 q' # Steady underline cursor (or bar) for Insert mode
    RPROMPT=''
  fi
  zle reset-prompt
}
zle -N zle-keymap-select

# --- shell options & completion ---
setopt auto_cd
autoload -U compinit && compinit -C

# Load advanced completions if available
zstyle ':completion:*' completer_expand _complete _ignored _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} m:{A-Z}={a-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
bindkey '^[[Z' reverse-menu-complete

# Enable caching for faster completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.local/share/zsh/cache"

# --- plugins & sources ---
source "$xdg_config_dir/aliases.zsh"
source "$xdg_config_dir/functions.zsh"
source "$xdg_config_dir/.plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# # Load syntax-highlighting (Must be sourced AFTER autosuggestions and near the end)
# if [[ -f "$xdg_config_dir/.plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
#     source "$xdg_config_dir/.plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# fi

# # If docker completion isn't loaded by default, you can generate/load it:
# if (( $+commands[docker] )); then
#   source <(docker completion zsh)
# fi

# Generated for envman. Do not edit.
# [ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# For NVM support on zsh.
source /usr/share/nvm/init-nvm.sh
