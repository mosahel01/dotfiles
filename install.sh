#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Dotfiles..."

# alacritty
ln -sfn "$DOTFILES/alacritty/" "$HOME/.config/"
echo "✓ symlinked alacritty"

# hypr
ln -sfn "$DOTFILES/hypr" "$HOME/.config/hypr"
echo "✓ symlinked hyprland"

# fonts
mkdir -p "$HOME/.config/fontconfig"
ln -sfn "$DOTFILES/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
echo "✓ symlinked fontconfig"

# i3
# ln -sfn "$DOTFILES/i3" "$HOME/.config/i3"
# echo "✓ symlinked i3"

# layout
# ln -sfn "$DOTFILES/xorg-layout.sh" "$HOME/.screenlayout/xorg-layout.sh"
# echo "✓ symlinked xorg-layout"

# niri
ln -sfn "$DOTFILES/niri" "$HOME/.config/niri"
echo "✓ symlinked niri"

# nvim
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"
echo "✓ symlinked nvim"

# quickshell
ln -sfn "$DOTFILES/quickshell" "$HOME/.config/quickshell"
echo "✓ symlinked quickshell"

# zsh
ln -sfn "$DOTFILES/zsh" "$HOME/.config/zsh"
echo "✓ symlinked zsh"

# tmux
# ln -sfn "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"
# echo "✓ symlinked tmux"

echo "✓ dotfiles installed"
