#!/usr/bin/env bash

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Dotfiles.."

rm -rf "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/ghostty"
ln -sfn "$DOTFILES/config.ghostty" "$HOME/.config/ghostty/config"

echo "ghostty installed"

rm -rf "$HOME/.config/zsh"
rm -rf "$HOME/.zshrc"

for file in "$DOTFILES"/zsh/*; do
	ln -sfn "$file" "$HOME/.config/zsh/$(basename "$file")"
done

echo "zsh installed"


rm -rf "$HOME/.config/nvim"
mkdir -p "$HOME/.config/nvim"
for file in "$DOTFILES"/nvim/*; do
	ln -sfn "$file" "$HOME/.config/nvim/$(basename "$file")"
done

echo "nvim installed"



