#!/usr/bin/env bash

set -euo pipefail

CORE_PACKAGES=(
    git
    zsh
    neovim
    ghostty
    discord
    bitwarden

    fd
    eza
    bat
    ripgrep
    fzf
    zoxide
    jq
    fastfetch
    tree

    tmux
    starship

    zip
    unzip

    yazi
    ffmpeg
    imagemagick

    networkmanager
    network-manager-applet
    openssh

    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pavucontrol
)

HYPRLAND_PACKAGES=(
    hyprland
    hyprlock
    hypridle
    hyprpaper
    hyprpolkitagent

    waybar
    rofi

    wl-clipboard
    cliphist

    grim
    slurp

    brightnessctl
    playerctl

    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
)

DEV_PACKAGES=(
    base-devel

    gcc
    clang
    python

    nodejs
    npm

    rust
    rust-analyzer

    luarocks
    lua-language-server
    bash-language-server
    yaml-language-server

    tree-sitter
    shellcheck
    shfmt
)

AUR_PACKAGES=(
	zen-browser-bin
)

MISSING_PACKAGES=()

install_paru() {
	if command -v paru >/dev/null 2>&1; then
		echo "✓ paru already installed"
		return
	fi

	echo "Installing paru..."

	sudo pacman -S --needed --noconfirm \
		base-devel \
		git \
		debugedit \
		pkgconf \
		fakeroot

	mkdir -p "$HOME/Downloads"

	if [[ ! -d "$HOME/Downloads/paru" ]]; then
		git clone https://aur.archlinux.org/paru.git \
			"$HOME/Downloads/paru"
	fi

	(
		cd "$HOME/Downloads/paru"
		makepkg -si --noconfirm
	)

	echo "✓ paru installed"
}

install_package() {
	local pkg="$1"

	if pacman -Qi "$pkg" >/dev/null 2>&1; then
		echo "✓ $pkg already installed"
		return
	fi

	if pacman -Si "$pkg" >/dev/null 2>&1; then
		sudo pacman -S --needed --noconfirm "$pkg"
		echo "✓ $pkg installed via pacman"
		return
	fi

	if paru -Si "$pkg" >/dev/null 2>&1; then
		paru -S --needed --noconfirm "$pkg"
		echo "✓ $pkg installed via AUR"
		return
	fi

	echo "✗ $pkg not found"
	MISSING_PACKAGES+=("$pkg")
}

install_group() {
	local name="$1"
	shift

	echo
	echo "Installing $name..."

	for pkg in "$@"; do
		install_package "$pkg"
	done
}

main() 
{
	sudo pacman -Sy

	install_paru

	echo
	echo "Installing core packages..."

	for pkg in "${CORE_PACKAGES[@]}"; do
		install_package "$pkg"
	done

	echo
	echo "Installing Hyprland packages..."

	for pkg in "${HYPRLAND_PACKAGES[@]}"; do
	    install_package "$pkg"
	done

	echo
	echo "Installing development packages..."

	for pkg in "${DEV_PACKAGES[@]}"; do
		install_package "$pkg"
	done

	echo
	echo "Installing AUR packages..."

	for pkg in "${AUR_PACKAGES[@]}"; do
		install_package "$pkg"
	done

	echo
	echo "========================"

	if [[ ${#MISSING_PACKAGES[@]} -eq 0 ]]; then
		echo "✓ All packages installed"
	else
		echo "Missing packages:"
		printf '  - %s\n' "${MISSING_PACKAGES[@]}"
	fi
}

main
