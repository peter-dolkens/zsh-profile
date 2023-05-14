#!/bin/bash

# download/update zsh-profile
if [[ ! -d ~/.zsh-profile ]]; then
    echo "Cloning zsh-profile repository..."
    git clone https://github.com/peter-dolkens/zsh-profile.git ~/.zsh-profile
elif [[ -d ~/.zsh-profile && ! "$(ls -A ~/.zsh-profile)" ]]; then
    echo "The .zsh-profile directory exists but is empty. Cloning zsh-profile repository..."
    git clone https://github.com/peter-dolkens/zsh-profile.git ~/.zsh-profile
else
    pushd ~/.zsh-profile
    git fetch
    git reset --hard origin/HEAD
    popd
    echo "Updating zsh-profile repository..."
fi

# install oh-my-zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# install zsh-profile customizations
if ! grep -Fxq 'source ~/.zsh-profile/profile.zshrc' ~/.zshrc; then
    echo 'source ~/.zsh-profile/profile.zshrc' >> ~/.zshrc
fi

# add docker to the list of plugins if docker command exists
if which docker >/dev/null 2>&1; then
    if ! grep -E -q '^\s*plugins=.*?[( ]docker[ )]' ~/.zshrc; then
        echo "Adding docker to the list of plugins..."
        sed -i.pre-zsh-profile '/^plugins=(/ s/)$/ docker)/' ~/.zshrc
    fi
else
    echo "Docker command not found. Please install Docker before running this script."
fi