#!/bin/bash
# =============================================================================
# Script Name  : setupEnvironment.sh
# Description  : Clones the user's personal GitHub repositories into a
#                standard directory layout under $HOME. Skips any repo that
#                has already been cloned (idempotent).
# Prerequisites: SSH/GitHub authentication must be configured (run
#                setupSSHandGithub.sh first); git must be installed
# Side Effects : Creates directories under $HOME and clones repositories;
#                stores the GitHub username in git config global github.user
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# Resolve the GitHub username — first try the stored git config value so
# the script can run non-interactively after the first execution.
USER_NAME=$(git config --global github.user 2>/dev/null || echo "")

if [[ -z "$USER_NAME" ]]; then
    read -rp "Enter your GitHub username: " USER_NAME
    if [[ -z "$USER_NAME" ]]; then
        echo "❌ GitHub username is required. Aborting."
        exit 1
    fi
    git config --global github.user "$USER_NAME"
fi

# Parallel arrays: REPOS[i] is cloned into $HOME/FOLDERS[i].
# To add a new repository, append one entry to each array (keep them in sync).
REPOS=(
  "git@github.com:$USER_NAME/Environments.git"
  "git@github.com:$USER_NAME/bashTools.git"
  "git@github.com:$USER_NAME/zeroBringup.git"
  "git@github.com:$USER_NAME/productivity-macOS.git"
)

# Target paths are relative to BASE_DIR ($HOME). Must be the same length as REPOS.
FOLDERS=(
  "__Environments__/Environments"
  "__Workspaces__/bashWorkspaces/bashTools"
  "__Workspaces__/bashWorkspaces/zeroBringup"
  "__Workspaces__/productivityWorkspaces/productivity-macOS"
)

# Base directory where all repos will be cloned
BASE_DIR="$HOME"

# Check that both arrays are the same length
if [ "${#REPOS[@]}" -ne "${#FOLDERS[@]}" ]; then
  echo "Error: REPOS and FOLDERS arrays must be the same length."
  exit 1
fi

# Create base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# Loop through both arrays using an index
for i in "${!REPOS[@]}"; do
  REPO_URL="${REPOS[$i]}"
  FOLDER_NAME="${FOLDERS[$i]}"
  TARGET_DIR="$BASE_DIR/$FOLDER_NAME"

  # Clone if not already cloned
  if [ -d "$TARGET_DIR/.git" ]; then
    echo "Repository already exists at $TARGET_DIR. Skipping..."
  else
    echo "Cloning $REPO_URL into $TARGET_DIR..."
    git clone "$REPO_URL" "$TARGET_DIR"
  fi
done

echo "✅ All repositories processed."
