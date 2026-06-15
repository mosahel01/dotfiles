#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Dotfiles..."

# ghostty
mkdir -p "$HOME/.config/ghostty"
ln -sfn "$DOTFILES/config.ghostty" "$HOME/.config/ghostty/config"
echo "✓ symlinked ghostty"

# zsh
ln -sfn "$DOTFILES/zsh" "$HOME/.config/zsh"
echo "✓ symlinked zsh"

# neovim
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"
echo "✓ symlinked neovim"

# fonts
mkdir -p "$HOME/.config/fontconfig"
ln -sfn "$DOTFILES/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
echo "✓ symlinked fontconfig"

echo "✓ dotfiles installed"
