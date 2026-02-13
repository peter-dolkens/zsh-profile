#!/bin/zsh

set -e

# Argument validation
if [ $# -ne 4 ]; then
  echo "Usage: kube_secret_replace <deployment> <key> <old_value> <new_value>"
  exit 1
fi

DEPLOYMENT="$1"
KEY="$2"
OLD="$3"
NEW="$4"

echo " Looking up deployment: $DEPLOYMENT..."

# Step 1: Get Octopus.Deployment.Id label from deployment
LABEL=$(kubectl get deployment "$DEPLOYMENT" -o json | jq -r '.metadata.labels["Octopus.Deployment.Id"]')

if [ -z "$LABEL" ] || [ "$LABEL" = "null" ]; then
  echo " No 'Octopus.Deployment.Id' label found on deployment '$DEPLOYMENT'"
  exit 1
fi

echo " Found label: Octopus.Deployment.Id = $LABEL"

# Step 2: Find matching secrets with the same label
echo " Searching for secrets with label Octopus.Deployment.Id=$LABEL..."
SECRET_NAMES=($(kubectl get secrets -l "Octopus.Deployment.Id=$LABEL" -o json | jq -r '.items[].metadata.name'))

if [ ${#SECRET_NAMES[@]} -eq 0 ]; then
  echo " No secrets found with label Octopus.Deployment.Id=$LABEL"
  exit 1
fi

for SECRET in "${SECRET_NAMES[@]}"; do
  echo " Processing secret: $SECRET"

  # Step 3: Extract and decode the key
  BASE64_ENCODED=$(kubectl get secret "$SECRET" -o json | jq -r --arg key "$KEY" '.data[$key]')

  if [ "$BASE64_ENCODED" = "null" ]; then
    echo "  Key '$KEY' not found in secret $SECRET"
    continue
  fi

  VALUE=$(echo "$BASE64_ENCODED" | base64 -d)

  # Step 4: Check if replacement is necessary
  if [[ "$VALUE" != *"$OLD"* ]]; then
    echo "  No occurrence of '$OLD' found in $KEY of $SECRET"
    continue
  fi

  # Step 5: Show diff and ask for confirmation
  NEW_VALUE="${VALUE//$OLD/$NEW}"

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
    # echo "$PATCH" | kubectl patch secret "$SECRET" --type=merge -p "$(cat)"
    echo " Secret $SECRET updated."
  else
    echo " Skipped $SECRET"
  fi
done

