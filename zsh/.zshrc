# --- environment & paths ---
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export TERM="xterm-256color"
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
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

# --- vi mode ---
export KEYTIMEOUT=1
bindkey -v
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# add this to see the mode printed (useful for debugging)
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]]; then
    echo -ne '\e[1 q'
    # optional: print "normal" in the right corner
    # RPROMPT='%F{yellow}normal%f'
    RPROMPT='%F{yellow}%f'
  else
    echo -ne '\e[5 q'
    RPROMPT=''
  fi
  zle reset-prompt
}
zle -N zle-keymap-select

# --- shell options & completion ---
setopt auto_cd
autoload -U compinit && compinit -C

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} m:{A-Z}={a-z}'
bindkey '^[[Z' reverse-menu-complete

# --- plugins & sources ---
source "$xdg_config_dir/aliases.zsh"
source "$xdg_config_dir/functions.zsh"
source "$xdg_config_dir/.plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# . "$HOME/.local/share/../bin/env" 
