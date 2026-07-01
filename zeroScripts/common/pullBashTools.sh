#!/bin/bash
# =============================================================================
# Script Name  : pullBashTools.sh
# Description  : Clones the user's bashTools repository into a standard
#                location under $HOME (skips the clone if it already exists,
#                idempotent), then runs its `make install-bash-tools` bootstrap.
# Prerequisites: SSH/GitHub authentication must be configured (run
#                setupSSHandGithub.sh first); git and make must be installed
# Side Effects : Creates $HOME/.environment/bashTools, clones the repo, and
#                runs the repo's install target (which edits shell config).
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

# Install the tools from the repo root. Run in a subshell so the cd does not
# leak into the caller's working directory.
echo "▶️ Running 'make install-bash-tools' in $TARGET_DIR ..."
( cd "$TARGET_DIR" && make install-bash-tools )
