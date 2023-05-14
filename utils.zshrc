
# Prompt for a keypress to continue. Customise prompt with $*
function pause {
  >/dev/tty printf '%s' "${*:-Press any key to continue... }"
  [[ $ZSH_VERSION ]] && read -krs  # Use -u0 to read from STDIN
  [[ $BASH_VERSION ]] && </dev/tty read -rsn1
  printf '\n'
}

atob () {
  echo "$1" | base64 ; echo
}

btoa () {
  echo "$1" | base64 -d ; echo
}

if [[ ! -d /Library/Apple/usr/share/rosetta ]]; then
    echo "Rosetta 2 is not installed. Prompting for installation..."
    softwareupdate --install-rosetta --agree-to-license
    if [[ $? -ne 0 ]]; then
        echo "Failed to install Rosetta 2. Please install manually."
    fi
fi
