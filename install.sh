#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Dotfiles..."

# alacritty
ln -sfn "$DOTFILES/alacritty/" "$HOME/.config/"
echo "✓ symlinked alacritty"

# # hypr
# ln -sfn "$DOTFILES/hypr" "$HOME/.config/hypr"
# echo "✓ symlinked hyprland"

# flameshot
ln -sfn "$DOTFILES/flameshot" "$HOME/.config/flameshot"
echo "✓ symlinked flameshot"

# fonts
mkdir -p "$HOME/.config/fontconfig"
ln -sfn "$DOTFILES/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
echo "✓ symlinked fontconfig"

# ghostty
ln -sfn "$DOTFILES/ghostty" "$HOME/.config/ghostty"
echo "✓ symlinked ghostty"

# i3
ln -sfn "$DOTFILES/i3" "$HOME/.config/i3"
echo "✓ symlinked i3"

# kitty
ln -sfn "$DOTFILES/kitty" "$HOME/.config/kitty"
echo "✓ symlinked kitty"

# layout
mkdir -p "$HOME/.screenlayout"
ln -sfn "$DOTFILES/xorg-layout.sh" "$HOME/.screenlayout/xorg-layout.sh"
echo "✓ symlinked xorg-layout"

# # niri
# ln -sfn "$DOTFILES/niri" "$HOME/.config/niri"
# echo "✓ symlinked niri"

# opencode
ln -sfn "$DOTFILES/opencode" "$HOME/.config/opencode"
echo "✓ symlinked opencode"

# rofi
ln -sfn "$DOTFILES/rofi" "$HOME/.config/rofi"
echo "✓ symlinked rofi"

# tmux
ln -sfn "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"
echo "✓ symlinked tmux"

# # quickshell
# ln -sfn "$DOTFILES/quickshell" "$HOME/.config/quickshell"
# echo "✓ symlinked quickshell"

# zsh
ln -sfn "$DOTFILES/zsh" "$HOME/.config/zsh"
echo "✓ symlinked zsh"

echo "✓ dotfiles installed"
