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
    "/usr/local/bin/pwsh:powershell"
    "/opt/homebrew/bin/octo:octopusdeploy/taps/octopuscli"
    "/opt/homebrew/bin/kubeshark:kubeshark/kubeshark/kubeshark"
    "/opt/homebrew/bin/sig:ynqa/tap/sigrs"
    "/opt/homebrew/bin/fx:fx"
    "/opt/homebrew/bin/mongosh:mongosh"
)

fpath=($fpath $(brew --prefix)/share/zsh/site-functions)

# Create a temporary file in macOS's temporary directory
last_brew_list_file=$(mktemp -t brew_list)

for i in "${brew_binaries[@]}"; do
    bin="${i%%:*}"
    pkg="${i##*:}"
    if [[ ! -f $bin ]]; then
        brew install $pkg
        rm $last_brew_list_file
    fi
done

# If file doesn't exist or it's older than a day, run `brew list --formula`
if [[ ! -f $last_brew_list_file ]] || [[ $(find $last_brew_list_file -mtime +1 -print) ]]; then
    brew list --formula > $last_brew_list_file
fi

# Read from the file instead of running `brew list --formula`
for pkg in $(cat $last_brew_list_file); do
    if [[ -d $(brew --prefix $pkg)/share/zsh/site-functions ]]; then
        fpath=($fpath $(brew --prefix $pkg)/share/zsh/site-functions)
    fi
done
