
source ~/.zsh-profile/utils.zshrc
source ~/.zsh-profile/brew.zshrc
source ~/.zsh-profile/dotnet.zshrc
source ~/.zsh-profile/python.zshrc
source ~/.zsh-profile/kubectl.zshrc
source ~/.zsh-profile/octopus.zshrc
source ~/.zsh-profile/aliases.zshrc

ZSH_THEME_TERM_TAB_TITLE_IDLE="[%M] %~"
ZSH_THEME_TERM_TITLE_IDLE="[%n@%M] %~"

autoload -Uz compinit && compinit
