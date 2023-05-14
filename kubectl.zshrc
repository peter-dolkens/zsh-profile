

# Get Kubernetes secrets and decode base64 values, apply additional jq query if provided
function get_kube_secrets() {
  local deployment_name_filter=""

  if [ ! -z "$1" ]; then
    if [ "$1" != "." ]; then
      local deployment_name=$1
      deployment_name_filter=" | select(.\"Octopus.Kubernetes.DeploymentName\" == \"$deployment_name\")"
    fi
    shift
  fi

  kubectl get secret -o json 2>/dev/null |
  jq ".items[] | { 
      metadata: .metadata, 
      data: (.data | select( . != null ) | map_values(@base64d) | to_entries)
    } | { 
      kube_name: .metadata.name, 
      kube_namespace: .metadata.namespace, 
      kube_type: \"secret\"
    } + .data[] + .metadata.labels $deployment_name_filter" -c |
  jq -s $@
}

# Get Kubernetes configmaps, apply additional jq query if provided
function get_kube_configmaps() {
  local deployment_name_filter=""

  if [ ! -z "$1" ]; then
    if [ "$1" != "." ]; then
      local deployment_name=$1
      deployment_name_filter=" | select(.\"Octopus.Kubernetes.DeploymentName\" == \"$deployment_name\")"
    fi
    shift
  fi

  kubectl get configmap -o json 2>/dev/null |
  jq ".items[] | {
      metadata: .metadata,
      data: (.data | select( . != null ) | to_entries)
    } | {
      kube_name: .metadata.name,
      kube_namespace: .metadata.namespace,
      kube_type: \"secret\"
    } + .data[] + .metadata.labels $deployment_name_filter" -c |
  jq -s $@
}

# Get Kubernetes environment vars, apply additional jq query if provided
function get_kube_deployment() {
  local deployment_name_filter=""

  if [ ! -z "$1" ]; then
    if [ "$1" != "." ]; then
      local deployment_name=$1
      deployment_name_filter=" | select(.\"Octopus.Kubernetes.DeploymentName\" == \"$deployment_name\")"
    fi
    shift
  fi

  kubectl get deploy -o json 2>/dev/null |
  jq ".items[] | {
      metadata: .metadata,
      data: [ .spec.template.spec.containers[].env | select( . != null) | .[] | select( .value != null ) | { key: .name, value: .value } ]
    } | {
      kube_name: .metadata.name,
      kube_namespace: .metadata.namespace,
      kube_type: \"deploy\"
    } + .data[] + .metadata.labels $deployment_name_filter" -c |
  jq -s $@
}

# Get Kubernetes data including deployment, configmap, and secret
function get_kube_all() {
  local deployment_name="."

  if [ ! -z "$1" ]; then
    deployment_name=$1
    shift
  fi

  {
    get_kube_deployment $deployment_name '.[]' &&
    get_kube_configmaps $deployment_name '.[]' && 
    get_kube_secrets $deployment_name '.[]'
  } | jq -s -c 'sort_by(.kube_namespace, .kube_name, .key, .kube_type)' | jq $@
}

# Convert filtered Kubernetes data to JSON and apply additional jq query if provided
function get_kube_json() {
  local deployment_name=$1
  shift

  get_kube_all "$deployment_name" "[.[] | {key: .key, value: .value}] | sort_by(.key) | from_entries" | jq $@
}

# Convert filtered Kubernetes data to nested JSON and apply additional jq query if provided
function get_kube_nested() {
  local deployment_name=$1
  shift

  get_kube_json $deployment_name | jq '
  def to_nested_structure(obj):
    reduce
      (obj | to_entries[]) as $entry
      ({}; .[$entry.key | split("__")[0]] = (
        if ($entry.key | contains("__")) then
          ((.[$entry.key | split("__")[0]] // {}) + {($entry.key | split("__")[1:] | join("__")): $entry.value}) | to_nested_structure(.)
        else
          $entry.value
        end)
      );

  to_nested_structure(.)' -c | jq $@
}
