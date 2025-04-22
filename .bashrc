eval "$(starship init bash)"
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# -----------------------------------------------------
# General
# -----------------------------------------------------
alias ps="sudo pacman -S "
alias pss="pacman -Ss "
alias prunsc="sudo pacman -Runsc "
alias ys="yay -S "
alias yss="yay -Ss "
alias yrunsc="yay -Runsc "

alias ls='eza --icons=always'
alias ll='eza -l --icons=always'
alias la='eza -a --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
alias vim='$EDITOR'


alias c="clear"
alias e="exit"

alias yt="yt-dlp -f bestvideo+bestaudio/best"

alias N="cd ~/.config/nvim && nvim"
alias H="cd ~/.config/hypr && nvim"
alias C="cd ~/Code/JS/ && nvim"



# -----------------------------------------------------
# Git
# -----------------------------------------------------
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gfo="git fetch origin"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"
