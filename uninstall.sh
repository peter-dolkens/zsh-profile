
if grep -Fxq "source ~/.zsh-profile/profile.zshrc" ~/.zshrc; then
    echo "Removing source line from ~/.zshrc..."
    sed -i '' '/source ~\/.zsh-profile\/profile.zshrc/d' ~/.zshrc
fi

if [[ -d ~/.zsh-profile ]]; then
    echo "Removing .zsh-profile directory..."
    rm -rf ~/.zsh-profile
fi
