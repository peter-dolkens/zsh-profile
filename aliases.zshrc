
alias cf=flarectl
alias k=kubectl
alias kns=kubens
alias ktx=kubectx

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
