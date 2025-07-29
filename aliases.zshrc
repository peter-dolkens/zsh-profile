
alias cf=flarectl
alias k=kubectl
alias kns=kubens
alias ktx=kubectx

alias ksa=search_kube_all

alias kgs=get_kube_secrets
alias kgc=get_kube_configmaps
alias kgd=get_kube_deployment

alias kga=get_kube_all
alias kgj=get_kube_json
alias kgn=get_kube_nested
 
alias ls="ls -laG"
alias cs=csharprepl

alias cls=clear
alias stellate="npx stellate@next"

alias ptop=asitop

alias krp="k get pod -o json | jq '.items[] | select ( .status.containerStatuses[].restartCount > 0 ) | .metadata.name' -r | xargs -I {} kubectl delete pod {}"

watch() {
  local cmd
  cmd=$(printf "%q " "$@")
  command watch "~/.zsh-profile/watch-wrapper.sh $cmd"
}

# watch() {
#   local cmd
#   cmd=$(printf "%q " "$@")
#   command watch "zsh -i -c `$cmd`"
# }

ktop () {
  kubectl get pods -o json | jq --argjson top "$(kubectl top pods --no-headers | awk '{print "{\"pod\":\""$1"\",\"cpu\":\""$2"\",\"memory\":\""$3"\"}"}' | jq -s .)" -r '
  ["POD", "CONTAINER", "CPU_USAGE", "CPU_REQUEST", "CPU_LIMIT", "MEM_USAGE", "MEM_REQUEST", "MEM_LIMIT"],
  ["----", "---------", "---------", "---------", "-----------", "----------", "---------", "---------"],
  (
    .items[] |
    .metadata.name as $pod_name |
    .spec.containers?[]? |
    [
      $pod_name,
      .name,
      ($top[] | select(.pod == $pod_name) | .cpu // "N/A"),
      (.resources.requests.cpu // "0"),
      (.resources.limits.cpu // "0"),
      ($top[] | select(.pod == $pod_name) | .memory // "N/A"),
      (.resources.requests.memory // "0"),
      (.resources.limits.memory // "0")
    ]
  ) | @tsv' | column -t
}

start () {
  open /Applications/$1.app
}
