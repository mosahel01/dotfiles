#!/usr/bin/env bash

set -eo pipefail

declare -a __archlinux_deps=(
    "starship"
    "bat"
    "eza"
    "git"
    "tmux"
    "which"
    "zsh"
    "zsh-syntax-highlighting"
    "zsh-autosuggestions"
)

declare -a __debian_deps=(
    "starship"
    "bat"
    "git"
    "tmux"
    "which"
    "zsh"
    "zsh-syntax-highlighting"
    "zsh-autosuggestions"
)

declare -a __plugins=(
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
)

DISTRO=""

function install() {
    log INFO "Setting up ZSH with syntax highlighting & autosuggestions"

    detect_distro

    install_arch_deps
    # install_debian_deps
    clone_plugins
    symlink_zshrc
    set_default_shell

    log INFO "All dependencies have been processed."
    log SUCCESS "ZSH is ready to rock!"
}

# ----------------
# HELPER FUNCTIONS
# ----------------

function detect_distro() {
    log INFO "Detecting Linux distribution..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO="$ID"
        log INFO "Detected distribution: $NAME ($DISTRO)"
    else
        log ERROR "Cannot detect distribution. /etc/os-release not found."
        exit 1
    fi
}

function install_arch_deps() {
    log INFO "Installing Arch Linux dependencies..."
    sudo pacman -Syu --needed "${__archlinux_deps[@]}"
    if [[ $? -eq 0 ]]; then
        log SUCCESS "Arch Linux dependencies are installed."
    else
        log ERROR "Error installing Arch Linux dependencies. Exiting."
        exit 1
    fi
}

function install_debian_deps() {
    log INFO "Installing Debian Linux dependencies..."
    sudo apt update
    sudo apt install -y "${__debian_deps[@]}"
    if [[ $? -eq 0 ]]; then
        log SUCCESS "Debian dependencies are installed."
    else
        log ERROR "Error installing Debian dependencies. Exiting."
        exit 1
    fi

    # Debian installs bat as 'batcat'. Create a symlink so 'bat' works.
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        log INFO "Creating symlink for batcat -> bat..."
        sudo ln -s /usr/bin/batcat /usr/local/bin/bat
    fi

    # eza might not be available on older Debian stable releases via apt
    if ! command -v eza &> /dev/null; then
        log WARN "eza is not available in standard apt repositories for this release. You can install it via cargo or download the binary manually."
    fi
}

function clone_plugins() {
    local plugins_dir="$HOME/.config/zsh/.plugins"
    log INFO "Cloning ZSH plugins into $plugins_dir..."
    mkdir -p "$plugins_dir"

    for plugin_url in "${__plugins[@]}"; do
        local plugin_name=$(basename "$plugin_url" .git)
        local target_path="$plugins_dir/$plugin_name"

        if [[ -d "$target_path" ]]; then
            log WARN "Skipping $plugin_name as it already exists at $target_path."
        else
            log INFO "Cloning $plugin_name..."
            git clone "$plugin_url" "$target_path"
        fi
    done
    log SUCCESS "Plugins verified and cloned successfully."
}

function symlink_zshrc() {
    local source_zshrc=".zshrc"
    local target_zshrc="$HOME/.zshrc"

    log INFO "Setting up .zshrc symlink..."

    if [[ ! -f "$source_zshrc" ]]; then
        log ERROR ".zshrc file not found in current directory. Skipping symlink creation."
        return 1
    fi

    if [[ -e "$target_zshrc" ]]; then
        if [[ -L "$target_zshrc" ]]; then
            local existing_target=$(readlink "$target_zshrc")
            local source_abs_path=$(realpath "$source_zshrc")
            if [[ "$existing_target" == "$source_abs_path" ]]; then
                log INFO ".zshrc is already correctly symlinked."
                return 0
            else
                log WARN "Existing .zshrc symlink points to different file: $existing_target"
                log INFO "Updating symlink to point to current .zshrc..."
                rm "$target_zshrc"
            fi
        else
            local backup_file="${target_zshrc}.backup.$(date +%Y%m%d_%H%M%S)"
            log WARN "Backing up existing .zshrc to $backup_file"
            mv "$target_zshrc" "$backup_file"
        fi
    fi

    ln -s "$(realpath "$source_zshrc")" "$target_zshrc"
    log SUCCESS ".zshrc symlinked successfully: $target_zshrc -> $(realpath "$source_zshrc")"
}

function set_default_shell() {
    local zsh_path=$(which zsh)
    local current_shell="$SHELL"

    log INFO "Setting ZSH as default shell..."

    if [[ -z "$zsh_path" ]]; then
        log ERROR "ZSH not found in PATH. Cannot set as default shell."
        return 1
    fi

    if [[ "$current_shell" == "$zsh_path" ]]; then
        log INFO "ZSH is already the default shell."
        return 0
    fi

    if ! grep -q "^$zsh_path$" /etc/shells; then
        log WARN "ZSH path ($zsh_path) not found in /etc/shells. Adding it..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        log SUCCESS "Added $zsh_path to /etc/shells"
    fi

    log INFO "Changing default shell to ZSH..."
    if chsh -s "$zsh_path"; then
        log SUCCESS "Default shell changed to ZSH: $zsh_path"
        log INFO "Please log out and log back in (or restart your terminal) for the change to take effect."
    else
        log ERROR "Failed to change default shell to ZSH."
        log INFO "You can manually change it later with: chsh -s $zsh_path"
        return 1
    fi
}

# Log color codes
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[0;37m'
COLOR_NC='\033[0m'

function log() {
    local level="$1"
    local message="$2"
    local color=''

    case "$level" in
    SUCCESS) color="${COLOR_GREEN}" ;;
    INFO) color="${COLOR_CYAN}" ;;
    WARN) color="${COLOR_YELLOW}" ;;
    ERROR) color="${COLOR_RED}" ;;
    DEBUG) color="${COLOR_BLUE}" ;;
    *) level="INFO"; color="${COLOR_CYAN}" ;;
    esac

    echo -e "${color}[${level}] ${message}${COLOR_NC}"
}

install















# #!/usr/bin/env bash
#
# set -eo pipefail
#
# declare -a __archlinux_deps=(
#     "starship" # important
#     "bat"
#     "eza"
#     "git"
#     "tmux"
#     "which"
#     "zsh"
#     "zsh-syntax-highlighting" # Added for cool syntax highlighting out-of-the-box
#     "zsh-autosuggestions"     # Added for fish-like history completions
# )
#
# declare -a __plugins=(
#     "https://github.com/zsh-users/zsh-autosuggestions"
#     "https://github.com/zsh-users/zsh-syntax-highlighting"
# )
#
# function install() {
#     log INFO "Setting up ZSH with syntax highlighting & autosuggestions"
#     log INFO "Starting dependency installation..."
#
#     install_arch_deps
#     clone_plugins
#     symlink_zshrc
#     set_default_shell
#
#     log INFO "All dependencies have been processed."
#     log SUCCESS "ZSH is ready to rock!"
# }
#
# # ----------------
# # HELPER FUNCTIONS
# # ----------------
#
# function install_arch_deps() {
#     log INFO "Installing Arch Linux dependencies..."
#     sudo pacman -Syu --needed "${__archlinux_deps[@]}"
#     if [[ $? -eq 0 ]]; then
#         log SUCCESS "Arch Linux dependencies are installed."
#     else
#         log ERROR "Error installing Arch Linux dependencies. Exiting."
#         exit 1
#     fi
# }
#
# function install_debian_deps() {
#     log INFO "Installing Debian Linux dependencies..."
#     sudo pacman -Syu --needed "${__archlinux_deps[@]}"
#     if [[ $? -eq 0 ]]; then
#         log SUCCESS "Arch Linux dependencies are installed."
#     else
#         log ERROR "Error installing Arch Linux dependencies. Exiting."
#         exit 1
#     fi
# }
#
# function clone_plugins() {
#     local plugins_dir="$HOME/.config/zsh/.plugins"
#     log INFO "Cloning ZSH plugins into $plugins_dir..."
#     mkdir -p "$plugins_dir"
#
#     for plugin_url in "${__plugins[@]}"; do
#         local plugin_name=$(basename "$plugin_url" .git)
#         local target_path="$plugins_dir/$plugin_name"
#
#         if [[ -d "$target_path" ]]; then
#             log WARN "Skipping $plugin_name as it already exists at $target_path."
#         else
#             log INFO "Cloning $plugin_name..."
#             git clone "$plugin_url" "$target_path"
#         fi
#     done
#     log SUCCESS "Plugins verified and cloned successfully."
# }
#
# function symlink_zshrc() {
#     local source_zshrc=".zshrc"
#     local target_zshrc="$HOME/.zshrc"
#
#     log INFO "Setting up .zshrc symlink..."
#
#     if [[ ! -f "$source_zshrc" ]]; then
#         log ERROR ".zshrc file not found in current directory. Skipping symlink creation."
#         return 1
#     fi
#
#     # Check if target already exists
#     if [[ -e "$target_zshrc" ]]; then
#         if [[ -L "$target_zshrc" ]]; then
#             # It's already a symlink
#             local existing_target=$(readlink "$target_zshrc")
#             local source_abs_path=$(realpath "$source_zshrc")
#             if [[ "$existing_target" == "$source_abs_path" ]]; then
#                 log INFO ".zshrc is already correctly symlinked."
#                 return 0
#             else
#                 log WARN "Existing .zshrc symlink points to different file: $existing_target"
#                 log INFO "Updating symlink to point to current .zshrc..."
#                 rm "$target_zshrc"
#             fi
#         else
#             # It's a regular file, back it up
#             local backup_file="${target_zshrc}.backup.$(date +%Y%m%d_%H%M%S)"
#             log WARN "Backing up existing .zshrc to $backup_file"
#             mv "$target_zshrc" "$backup_file"
#         fi
#     fi
#
#     # Create the symlink
#     ln -s "$(realpath "$source_zshrc")" "$target_zshrc"
#     log SUCCESS ".zshrc symlinked successfully: $target_zshrc -> $(realpath "$source_zshrc")"
# }
#
# function set_default_shell() {
#     local zsh_path=$(which zsh)
#     local current_shell="$SHELL"
#
#     log INFO "Setting ZSH as default shell..."
#
#     if [[ -z "$zsh_path" ]]; then
#         log ERROR "ZSH not found in PATH. Cannot set as default shell."
#         return 1
#     fi
#
#     # Check if ZSH is already the default shell
#     if [[ "$current_shell" == "$zsh_path" ]]; then
#         log INFO "ZSH is already the default shell."
#         return 0
#     fi
#
#     # Check if ZSH is in /etc/shells
#     if ! grep -q "^$zsh_path$" /etc/shells; then
#         log WARN "ZSH path ($zsh_path) not found in /etc/shells. Adding it..."
#         echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
#         log SUCCESS "Added $zsh_path to /etc/shells"
#     fi
#
#     # Change the default shell
#     log INFO "Changing default shell to ZSH..."
#     if chsh -s "$zsh_path"; then
#         log SUCCESS "Default shell changed to ZSH: $zsh_path"
#         log INFO "Please log out and log back in (or restart your terminal) for the change to take effect."
#     else
#         log ERROR "Failed to change default shell to ZSH."
#         log INFO "You can manually change it later with: chsh -s $zsh_path"
#         return 1
#     fi
# }
#
# # Log color codes
# COLOR_RED='\033[0;31m'
# COLOR_GREEN='\033[0;32m'
# COLOR_YELLOW='\033[0;33m'
# COLOR_BLUE='\033[0;34m'
# COLOR_CYAN='\033[0;36m'
# COLOR_WHITE='\033[0;37m'
# COLOR_NC='\033[0m' # No Color
#
# function log() {
#     local level="$1"
#     local message="$2"
#     local color=''
#
#     case "$level" in
#     SUCCESS)
#         color="${COLOR_GREEN}"
#         ;;
#     INFO)
#         color="${COLOR_CYAN}"
#         ;;
#     WARN)
#         color="${COLOR_YELLOW}"
#         ;;
#     ERROR)
#         color="${COLOR_RED}"
#         ;;
#     DEBUG)
#         color="${COLOR_BLUE}"
#         ;;
#     *)
#         # Default to INFO if level is not recognized
#         level="INFO"
#         color="${COLOR_CYAN}"
#         ;;
#     esac
#
#     echo -e "${color}[${level}] ${message}${COLOR_NC}"
# }
#
# install
#
