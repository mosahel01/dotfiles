eval "$(starship init bash)"
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


alias ps="sudo pacman -S "
alias pss="pacman -Ss "


alias ps="sudo pacman -S "
alias pss="pacman -Ss "


alias ls="eza --icons"
alias ll="eza -al --icons"
alias la="eza -a --icons"

alias c="clear"
alias e="exit"


alias N="cd ~/.config/nvim && nvim"
alias H="cd ~/.config/hypr && nvim"
alias C="cd ~/Code/Email-Validator/ && nvim"

