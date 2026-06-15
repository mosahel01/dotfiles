#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Dotfiles..."

# ghostty
mkdir -p "$HOME/.config/ghostty"
ln -sfn "$DOTFILES/config.ghostty" "$HOME/.config/ghostty/config"

# zsh
ln -sfn "$DOTFILES/zsh" "$HOME/.config/zsh"

# neovim
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"

echo "Done."
