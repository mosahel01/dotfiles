# system and package management
alias update="sudo pacman -Syu"
alias install="sudo pacman -S"
alias search="pacman -Ss"
alias remove="sudo pacman -Rns "
alias list_systemctl="systemctl list-unit-files --state=enabled"
alias mirror="sudo reflector --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist"
alias jc="journalctl -xe"

# appearance toggles
alias dark="gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' "
alias light="gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' "

# window manager and terminal helpers
alias hyprland='start-hyprland'
# alias niri='niri-session -l'
# alias al='nvim $HOME/.config/alacritty/alacritty.toml'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias path='echo $PATH | tr ":" "\n"'

# file listing (eza)
alias ls="eza --icons=always"
alias l="eza -l --group-directories-first --icons=always"
alias la="eza -la --icons=always"
alias lsa="eza -a --icons=always"
alias lt="eza -a --icons=always --tree --level=2"
alias lg="eza -al --icons=always | rg"

# basic file operations
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias decompress="tar -xzf"

# tmux session management
alias ts='tmux ls'               # list sessions
alias tn='tmux new -s '          # new session
alias ta='tmux attach'           # attach latest
alias tt='tmux attach -t '       # attach specific
alias tk='tmux kill-session -t ' # kill by name

# git shortcuts (don't need)
alias gs='echo "Use Lazygit"'
alias ga='echo "Use Lazygit"'
alias gm='echo "Use Lazygit"'
alias gp='echo "Use Lazygit"'

# # golang
# alias gr='go run .'
# alias gb='go build .'
# alias gmod='go mod tidy'

# # docker
# alias d='docker'
# alias dc='docker compose'
# alias dcu='docker compose up -d'
# alias dcd='docker compose down'
# alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# shell utilities
alias c='clear'
alias e='exit'
alias hg="history | rg"
alias copypath="pwd | wl-copy"
alias speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python'

# media (yt-dlp)
alias yt-audio-high='yt-dlp -f "bestaudio[ext=m4a]" '
alias yt-video-high=' yt-dlp -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]"  '
alias yt-video-low='yt-dlp -f "worstvideo+bestaudio" '
alias yt-playlist='yt-dlp -f "bestvideo+bestaudio" '

# xorg specifics
alias caps='xset r rate 200 50; setxkbmap -option caps:swapescape'
