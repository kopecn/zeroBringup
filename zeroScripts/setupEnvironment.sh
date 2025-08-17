#!/bin/bash

USER_NAME=$(git config --global github.user)

# Array of repository URLs
REPOS=(
  "git@github.com:$USER_NAME/Environments.git"
  "git@github.com:$USER_NAME/bashTools.git"
  "git@github.com:$USER_NAME/zeroBringup.git"
)

# Corresponding array of target folder names (must be same length as REPOS)
FOLDERS=(
  "__Environments__/Environments"
  "__Workspaces__/bashWorkspaces/bashTools"
  "__Workspaces__/bashWorkspaces/zeroBringup"
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

echo "All repositories processed."
