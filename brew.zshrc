if [[ ! -f /opt/homebrew/bin/brew ]]; then
    echo "Installing Brew"
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

touch ~/.zprofile

if ! grep -Fxq 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew_binaries=(
    "/opt/homebrew/bin/docker:docker"
    "/opt/homebrew/bin/az:azure-cli"
    "/opt/homebrew/bin/hx:helix"
    "/opt/homebrew/bin/helm:helm"
    "/opt/homebrew/bin/jq:jq"
    "/opt/homebrew/bin/kubectl:kubernetes-cli"
    "/opt/homebrew/bin/kubectx:kubectx"
    "/opt/homebrew/bin/kubetail:johanhaleby/kubetail/kubetail"
    "/opt/homebrew/bin/kubelogin:Azure/kubelogin/kubelogin"
    "/opt/homebrew/bin/watch:watch"
    "/opt/homebrew/bin/node:node"
    "/opt/homebrew/bin/npm:npm"
    "/opt/homebrew/bin/yq:yq"
    "/opt/homebrew/bin/pwsh:powershell"
    "/opt/homebrew/bin/octo:octopusdeploy/taps/octopuscli"
    "/opt/homebrew/bin/kubeshark:kubeshark/kubeshark/kubeshark"
    "/opt/homebrew/bin/sig:ynqa/tap/sigrs"
    "/opt/homebrew/bin/fx:fx"
    "/opt/homebrew/bin/mongosh:mongosh"
)

fpath=($fpath $(brew --prefix)/share/zsh/site-functions)

# Cache the formula list on disk so `brew list` only runs once a day
last_brew_list_file=~/.cache/brew_list
mkdir -p ~/.cache

for i in "${brew_binaries[@]}"; do
    bin="${i%%:*}"
    pkg="${i##*:}"
    if [[ ! -f $bin ]]; then
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
