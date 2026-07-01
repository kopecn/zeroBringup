#!/bin/bash
# =============================================================================
# Script Name  : pullBashTools.sh
# Description  : Clones the user's bashTools repository into a standard
#                location under $HOME. Skips the clone if it already exists
#                (idempotent).
# Prerequisites: SSH/GitHub authentication must be configured (run
#                setupSSHandGithub.sh first); git must be installed
# Side Effects : Creates $HOME/.environment/bashTools and clones the repo.
# Arguments    : $1 = GitHub project/owner that hosts bashTools (used here)
#                $2 = GitHub user running the bootstrap (accepted, unused)
#                Both are forwarded by zeroBringup.sh; defaults let this run
#                standalone.
# =============================================================================
set -euo pipefail

# --- Positional contract (forwarded by zeroBringup.sh to every sub-script) ----
GITHUB_PROJECT="${1:-kopecn}"   # account that OWNS the repos being cloned
GITHUB_USER="${2:-kopecn}"      # identity of the person running the bootstrap

REPO_URL="git@github.com:$GITHUB_PROJECT/bashTools.git"
TARGET_DIR="$HOME/.environment/bashTools"

if [ -d "$TARGET_DIR/.git" ]; then
  echo "Repository already exists at $TARGET_DIR. Skipping..."
else
  echo "Cloning $REPO_URL into $TARGET_DIR..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi
