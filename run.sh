#!/usr/bin/env bash
#
# Oh My Zsh bootstrap script for Debian/Ubuntu.
# - Installs zsh, git, curl (if missing)
# - Installs Oh My Zsh for the current user
# - Installs common plugins
# - Configures ~/.zshrc in an idempotent way
#
# This script operates on the *current user* (id -un), whether root or non-root.

set -euo pipefail

########################################
# 0. Basic environment and OS checks
########################################

if [ ! -r /etc/os-release ]; then
    echo "ERROR: /etc/os-release not found. This script supports Debian/Ubuntu only."
    exit 1
fi

# Source OS identification data
# shellcheck disable=SC1091
. /etc/os-release

OS_ID_LIKE="${ID_LIKE:-}"
OS_ID="${ID:-}"

if [[ "$OS_ID_LIKE" != *"debian"* && "$OS_ID_LIKE" != *"ubuntu"* && "$OS_ID" != *"debian"* && "$OS_ID" != *"ubuntu"* ]]; then
    echo "ERROR: Detected non-Debian/Ubuntu system (ID=$OS_ID, ID_LIKE=$OS_ID_LIKE)."
    echo "       This script is intended for Debian/Ubuntu only."
    exit 1
fi

USER_NAME="$(id -un)"
HOME_DIR="$HOME"

IS_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=true
fi

HAS_SUDO=false
if ! $IS_ROOT && command -v sudo >/dev/null 2>&1; then
    # Do not fail the script if sudo -n fails; we only use this as a hint.
    if sudo -n true >/dev/null 2>&1 || true; then
        HAS_SUDO=true
    fi
fi

APT_UPDATED=false

########################################
# 1. Helper for apt-based package install
########################################

apt_install_if_missing() {
    local pkg="$1"
    if command -v "$pkg" >/dev/null 2>&1; then
        echo "Package '$pkg' already present. Skipping installation."
        return 0
    fi

    if $IS_ROOT; then
        echo "Installing '$pkg' via apt (running as root)..."
        if [ "$APT_UPDATED" = false ]; then
            apt-get update -y
            APT_UPDATED=true
        fi
        apt-get install -y "$pkg"
    elif $HAS_SUDO; then
        echo "Installing '$pkg' via sudo apt..."
        if [ "$APT_UPDATED" = false ]; then
            sudo apt-get update -y
            APT_UPDATED=true
        fi
        sudo apt-get install -y "$pkg"
    else
        echo "ERROR: '$pkg' is not installed and no root/sudo privileges are available."
        echo "       Please install '$pkg' manually and re-run this script."
        exit 1
    fi
}

########################################
# 2. Ensure required packages: zsh, git, curl
########################################

echo "Ensuring required packages are installed (zsh, git, curl)..."
apt_install_if_missing zsh
apt_install_if_missing git
apt_install_if_missing curl

ZSH_BIN="$(command -v zsh)"
if [ -z "$ZSH_BIN" ]; then
    echo "ERROR: zsh is not available even after installation attempt."
    exit 1
fi

########################################
# 3. Set default shell to zsh for current user
########################################

# Read current login shell from /etc/passwd, which is more reliable than $SHELL
CURRENT_SHELL_PASSWD="$(getent passwd "$USER_NAME" | cut -d: -f7 || true)"

if [ "$CURRENT_SHELL_PASSWD" != "$ZSH_BIN" ]; then
    echo "Changing default shell to zsh for user '$USER_NAME'..."
    if $IS_ROOT; then
        chsh -s "$ZSH_BIN" "$USER_NAME" || {
            echo "WARNING: Failed to change shell for '$USER_NAME'. You may need to run:"
            echo "         chsh -s $ZSH_BIN $USER_NAME"
        }
    else
        chsh -s "$ZSH_BIN" || {
            echo "WARNING: Failed to change shell for '$USER_NAME'. You may need to run:"
            echo "         chsh -s $ZSH_BIN"
        }
    fi
else
    echo "Default shell for '$USER_NAME' is already zsh. Skipping chsh."
fi

########################################
# 4. Check connectivity to GitHub
########################################

echo "Checking connectivity to GitHub..."
GITHUB_OK=false
if curl -fsSL --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    GITHUB_OK=true
    echo "GitHub is reachable."
else
    echo "WARNING: GitHub is not reachable. Oh My Zsh and plugins cannot be fetched."
fi

########################################
# 5. Install Oh My Zsh for current user
########################################

OMZ_DIR="$HOME_DIR/.oh-my-zsh"

if [ -d "$OMZ_DIR" ]; then
    echo "Oh My Zsh already installed at '$OMZ_DIR'. Skipping installation."
else
    if ! $GITHUB_OK; then
        echo "ERROR: Cannot reach GitHub, and Oh My Zsh is not installed."
        echo "       Please ensure network access to GitHub and re-run this script."
        exit 1
    fi

    echo "Installing Oh My Zsh for user '$USER_NAME'..."
    # Non-interactive installation
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    if [ ! -d "$OMZ_DIR" ]; then
        echo "ERROR: Oh My Zsh installation did not create '$OMZ_DIR'."
        exit 1
    fi
fi

########################################
# 6. Install plugins (zsh-syntax-highlighting, zsh-autosuggestions)
########################################

ZSH_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

install_plugin() {
    local name="$1"
    local repo="$2"
    local dest="$ZSH_CUSTOM/plugins/$name"

    if [ -d "$dest" ]; then
        echo "Plugin '$name' already exists at '$dest'. Skipping."
        return 0
    fi

    if ! $GITHUB_OK; then
        echo "WARNING: GitHub is not reachable. Cannot install plugin '$name'."
        return 0
    fi

    echo "Cloning plugin '$name' from '$repo'..."
    git clone "$repo" "$dest"
}

install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "zsh-autosuggestions"    "https://github.com/zsh-users/zsh-autosuggestions.git"

########################################
# 7. Configure ~/.zshrc in an idempotent way
########################################

ZSHRC="$HOME_DIR/.zshrc"

# Ensure ~/.zshrc exists; if not, create a minimal one
if [ ! -f "$ZSHRC" ]; then
    echo "Creating a minimal ~/.zshrc for user '$USER_NAME'..."
    cat > "$ZSHRC" <<EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source \$ZSH/oh-my-zsh.sh

alias cls='clear'
EOF
else
    echo "Updating existing ~/.zshrc for user '$USER_NAME'..."

    # Ensure plugins line is present and updated
    if grep -q "^plugins=" "$ZSHRC"; then
        # Replace the entire plugins line
        sed -i 's/^plugins=.*/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/' "$ZSHRC"
    else
        # Append plugins line if not present
        echo 'plugins=(git zsh-syntax-highlighting zsh-autosuggestions)' >> "$ZSHRC"
    fi

    # Add alias only if not already present
    if ! grep -q "alias cls='clear'" "$ZSHRC"; then
        echo "alias cls='clear'" >> "$ZSHRC"
    fi
fi

########################################
# 8. Final message
########################################

echo
echo "======================================================"
echo "Oh My Zsh setup completed for user: $USER_NAME"
echo "  - Shell binary : $ZSH_BIN"
echo "  - Oh My Zsh    : $OMZ_DIR"
echo "  - Config file  : $ZSHRC"
echo
echo "Please log out and log back in, or start zsh manually:"
echo "    zsh"
echo "======================================================"