
pip_binaries=(
    "/opt/homebrew/bin/hjson:hjson"
    "/opt/homebrew/bin/asitop:asitop"
)

for i in "${pip_binaries[@]}"; do
    bin="${i%%:*}"
    pkg="${i##*:}"
    if [[ ! -f $bin ]]; then
        pip3 install $pkg
    fi
done
