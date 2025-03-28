#!/bin/bash

# Detect operating system type
OS="$(grep -Ei 'debian|buntu|mint' /etc/*release)"

#check if zsh is installed
if command -v zsh &>/dev/null; then
    echo "zsh is already installed. Skipping..."
else
    echo "zsh is not installed. Proceeding with installation..."
    # Install zsh
    if [[ ! -z "$OS" ]]; then
        echo "Detected Ubuntu/Debian-based system. Installing zsh..."
        sudo apt-get update && sudo apt-get install -y zsh
    else
        echo "Detected CentOS-based system. Installing zsh..."
        sudo yum install -y zsh
    fi
fi


# Set default shell
echo "Setting zsh as the default shell...,please enter your password"
chsh -s $(which zsh)

# Check and install git and curl
if ! command -v git &>/dev/null; then
    echo "Installing git..."
    sudo apt-get install -y git || sudo yum install -y git
fi
if ! command -v curl &>/dev/null; then
    echo "Installing curl..."
    sudo apt-get install -y curl || sudo yum install -y curl
fi

#Detect connection to GitHub 
CONNECT_STATUS="true"
if curl -s --connect-timeout 5 https://github.com > /dev/null; then
    CONNECT_STATUS="true"
else
    CONNECT_STATUS="false"
fi

# Choose installation source
if [ "$CONNECT_STATUS" = "false" ]; then
    echo "Using Gitee mirror to install Oh My Zsh..."
    export REMOTE=gitee.com/mirrors/oh-my
    sh -c "$(wget -O- gitee.com/pocmon/mirror)"
else
    echo "Using GitHub to install Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# Install plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

echo "Installing zsh-syntax-highlighting plugin..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    if [ "$CONNECT_STATUS" = "false" ]; then
        git clone https://gitee.com/mirror-luyi/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    fi
else
    echo "zsh-syntax-highlighting plugin already exists. Skipping..."
fi

echo "Installing zsh-autosuggestions plugin..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    if [ "$CONNECT_STATUS" = "false" ]; then
        git clone https://gitee.com/mirror-luyi/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    fi
else
    echo "zsh-autosuggestions plugin already exists. Skipping..."
fi

# Set up .zshrc
echo "Setting up .zshrc..."
if OS="$(grep -Ei 'debian|buntu|mint' /etc/*release)"; then
    sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/g' ~/.zshrc
    echo "alias cls='clear'" >> ~/.zshrc
else
    sed -i '' 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/g' ~/.zshrc
    echo "alias cls='clear'" >> ~/.zshrc
fi

# Restart shell
echo "Oh My Zsh installation completed! Please restart your terminal or run 'zsh' to enter the new shell."