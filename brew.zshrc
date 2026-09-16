if [[ ! -f /opt/homebrew/bin/brew ]]; then
    echo "Installing Brew"
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

touch ~/.zprofile

if ! grep -Fxq 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Format is "command:package". Detection is by command name on $PATH
# (via `command -v`), not a hardcoded path, so brew prefix / Cellar version
# / cask-vs-formula changes can't trigger phantom reinstalls.
brew_binaries=(
    "docker:docker"
    "az:azure-cli"
    "hx:helix"
    "helm:helm"
    "jq:jq"
    "kubectl:kubernetes-cli"
    "kubectx:kubectx"
    "kubetail:johanhaleby/kubetail/kubetail"
    "kubelogin:Azure/kubelogin/kubelogin"
    "watch:watch"
    "node:node"
    "npm:npm"
    "yq:yq"
    "pwsh:powershell"
    "octo:octopusdeploy/taps/octopuscli"
    "kubeshark:kubeshark/kubeshark/kubeshark"
    "sig:ynqa/tap/sigrs"
    "fx:fx"
    "mongosh:mongosh"
    "herdr:herdr"
)

fpath=($fpath $(brew --prefix)/share/zsh/site-functions)

# Cache the formula list on disk so `brew list` only runs once a day
last_brew_list_file=~/.cache/brew_list
mkdir -p ~/.cache

for i in "${brew_binaries[@]}"; do
    cmd="${i%%:*}"
    pkg="${i##*:}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        brew install $pkg
        rm -f $last_brew_list_file
    fi
done

# If the cache doesn't exist or is older than 24 hours, refresh it
if [[ ! -f $last_brew_list_file ]] || [[ -n $(find $last_brew_list_file -mmin +1440 -print) ]]; then
    brew list --formula > $last_brew_list_file
fi

# Read from the file instead of running `brew list --formula`
for pkg in $(cat $last_brew_list_file); do
    if [[ -d $(brew --prefix $pkg)/share/zsh/site-functions ]]; then
        fpath=($fpath $(brew --prefix $pkg)/share/zsh/site-functions)
    fi
done
