#!/bin/zsh

set -e

# Argument validation
if [ $# -lt 4 ]; then
  echo "Usage: kube_secret_replace_direct <secret> <key> <old_value> <new_value> [--namespace <namespace>]"
  exit 1
fi

# Parse arguments
SECRET="$1"
KEY="$2"
OLD="$3"
NEW="$4"

echo " Looking up secret: $SECRET"

# Step 1: Get and decode the key
BASE64_ENCODED=$(kubectl get secret "$SECRET" -o json | jq -r --arg key "$KEY" '.data[$key]')

if [ "$BASE64_ENCODED" = "null" ]; then
  echo " Key '$KEY' not found in secret '$SECRET'"
  exit 1
fi

VALUE=$(echo "$BASE64_ENCODED" | base64 -d)

# Step 2: Check if replacement is needed
if [[ "$VALUE" != *"$OLD"* ]]; then
  echo "  No occurrence of '$OLD' found in $KEY of $SECRET"
  exit 0
fi

NEW_VALUE="${VALUE//$OLD/$NEW}"

# Step 3: Show diff and confirm
echo
echo "  Proposed change in secret: $SECRET"
echo "Key: $KEY"
echo "--- Before ---"
echo "$VALUE"
echo "--- After ----"
echo "$NEW_VALUE"
echo

read "CONFIRM?Apply this change to $SECRET? (y/N): "
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  PATCH=$(jq -n --arg key "$KEY" --arg val "$(echo "$NEW_VALUE" | base64)" \
    '{data: {($key): $val}}')

  echo " Patching secret $SECRET..."
  kubectl patch secret "$SECRET" --type=merge -p "$PATCH"
  echo " Secret $SECRET updated."
else
  echo " Skipped $SECRET"
fi

