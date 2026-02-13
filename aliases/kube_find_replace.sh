# kfr: Kubernetes Find & Replace (ConfigMaps + Secrets, partial match)
# Usage: kfr <find> <replace> [--yes] [--namespace <ns>] [--context <ctx>]
kfr() {
  set -euo pipefail

  # ---- args & flags ----
  if [[ $# -lt 2 ]]; then
    echo "Usage: kfr <find> <replace> [--yes] [--namespace <ns>] [--context <ctx>]" >&2
    return 2
  fi
  local FIND="$1"; shift
  local REPL="$1"; shift

  local AUTO_YES="0"
  local NS_OPT="-A"
  local CTX_OPT=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes) AUTO_YES="1"; shift ;;
      --namespace|-n) NS_OPT="-n"; NS_VAL="$2"; shift 2 ;;
      --context) CTX_OPT=(--context "$2"); shift 2 ;;
      *) echo "Unknown flag: $1" >&2; return 2 ;;
    esac
  done
  [[ -n "${NS_VAL:-}" ]] && NS_OPT="$NS_OPT $NS_VAL"

  # ---- deps ----
  for bin in kubectl jq base64; do
    command -v "$bin" >/dev/null 2>&1 || { echo "Missing dependency: $bin" >&2; return 127; }
  done

  # ---- fetch all cm+secrets ----
  # We pull once to avoid tons of API calls. Adjust if your cluster is huge.
  local RES_JSON
  if [[ "$NS_OPT" == "-A" ]]; then
    RES_JSON="$(kubectl "${CTX_OPT[@]}" get configmaps,secrets -A -o json)"
  else
    RES_JSON="$(kubectl "${CTX_OPT[@]}" get configmaps,secrets $NS_OPT -o json)"
  fi

  # ---- build a list of candidate edits (TSV) ----
  # Fields: kind  ns  name  key  is_secret  before  after
  # We restrict to printable-ish text for safety on secrets.
  local IFS=$'\n'
  local CANDIDATES
  CANDIDATES=($(jq -r --arg find "$FIND" --arg repl "$REPL" '
    def esc(s): s|gsub("([\\.^$|()\\[\\]{}*+?\\\\])"; "\\\\\\1");
    def rx: esc($find);
    def is_text: test("^[\\x09\\x0A\\x0D\\x20-\\x7E]*$");
    .items[]
    | {kind, ns:.metadata.namespace, name:.metadata.name, data:(.data // {}), is_secret: (.kind=="Secret")}
    | . as $it
    | ($it.data|to_entries[])?
    | if $it.is_secret
        then (.value|@base64d) as $orig
        | select($orig|is_text)
        | ($orig|gsub(rx; $repl)) as $new
        | select($new != $orig)
        | [$it.kind, $it.ns, $it.name, .key, "true", $orig, $new]
      else
        (.value) as $orig
        | ($orig|gsub(rx; $repl)) as $new
        | select($new != $orig)
        | [$it.kind, $it.ns, $it.name, .key, "false", $orig, $new]
      end
    | @tsv
  ' <<<"$RES_JSON"))

  if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    echo "No matches found for '$FIND'." >&2
    return 0
  fi

  # ---- helpers ----
  _json_quote() {
    # Safely quote a string for JSON using jq
    jq -Rn --arg s "$1" '$s'
  }
  _ptr_escape() {
    # JSON Pointer escape (not used with merge patch, kept for reference)
    local s="$1"
    s="${s//~/~0}"; s="${s////~1}"
    printf '%s' "$s"
  }

  # ---- iterate & patch ----
  local line kind ns name key is_secret before after
  for line in "${CANDIDATES[@]}"; do
    IFS=$'\t' read -r kind ns name key is_secret before after <<<"$line"

    echo "------------------------------------------------------------"
    echo "$kind/$name  (ns: $ns, key: $key)"
    echo "Before: $before"
    echo "After : $after"

    local DO_IT="n"
    if [[ "$AUTO_YES" == "1" ]]; then
      DO_IT="y"
    else
      vared -p "Apply this change? [y/N] " -c DO_IT
      DO_IT="${DO_IT:l}"
    fi
    if [[ "$DO_IT" != "y" ]]; then
      echo "Skipped."
      continue
    fi

    # Build a merge patch: {"data": {"key": "value"}}
    local value new_b64 patch kind_lc
    if [[ "$is_secret" == "true" ]]; then
      new_b64=$(printf '%s' "$after" | base64 | tr -d '\n')
      # Note: Secrets expect base64-encoded values in .data
      patch=$(jq -n --arg k "$key" --arg v "$new_b64" '{data: {($k): $v}}')
      kind_lc="secret"
    else
      patch=$(jq -n --arg k "$key" --arg v "$after" '{data: {($k): $v}}')
      kind_lc="configmap"
    fi

    # Apply patch & show a quick verify of the single field post-change
    if kubectl "${CTX_OPT[@]}" patch "$kind_lc" "$name" -n "$ns" --type=merge -p "$patch" >/dev/null; then
      # Verify:
      if [[ "$is_secret" == "true" ]]; then
        local post
        post="$(kubectl "${CTX_OPT[@]}" get secret "$name" -n "$ns" -o json \
          | jq -r --arg k "$key" '.data[$k] // ""' \
          | base64 --decode 2>/dev/null || true)"
        echo "Patched ✓  (post-value: $post)"
      else
        local post
        post="$(kubectl "${CTX_OPT[@]}" get configmap "$name" -n "$ns" -o json \
          | jq -r --arg k "$key" '.data[$k] // ""')"
        echo "Patched ✓  (post-value: $post)"
      fi
    else
      echo "Patch failed ✗"
    fi
  done
}

