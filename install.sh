#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Dotfiles..."

# # ghostty
# mkdir -p "$HOME/.config/ghostty"
# ln -sfn "$DOTFILES/config.ghostty" "$HOME/.config/ghostty/config"
# echo "✓ symlinked ghostty"

# # alacritty
# mkdir -p "$HOME/.config/alacritty"
# ln -sfn "$DOTFILES/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
# echo "✓ symlinked alacritty"

# # niri
# mkdir -p "$HOME/.config/niri"
# ln -sfn "$DOTFILES/config.niri" "$HOME/.config/niri/config.kdl"
# echo "✓ symlinked niri"

# # zsh
# ln -sfn "$DOTFILES/zsh" "$HOME/.config/zsh"
# echo "✓ symlinked zsh"

# # neovim
# ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"
# echo "✓ symlinked neovim"

# neovim
ln -sfn "$DOTFILES/zed" "$HOME/.config/zed"
echo "✓ symlinked zed editor"

# fonts
mkdir -p "$HOME/.config/fontconfig"
ln -sfn "$DOTFILES/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
echo "✓ symlinked fontconfig"

echo "✓ dotfiles installed"
