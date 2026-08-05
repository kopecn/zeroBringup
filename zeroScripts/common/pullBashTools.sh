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
#                $3 = detected OS type (accepted, unused)
#                $4 = bashTools branch to check out after clone (defaults to dev)
#                All are forwarded by zeroBringup.sh; defaults let this run
#                standalone.
# =============================================================================
set -euo pipefail

# --- Positional contract (forwarded by zeroBringup.sh to every sub-script) ----
GITHUB_PROJECT="${1:-kopecn}"   # account that OWNS the repos being cloned
# shellcheck disable=SC2034
GITHUB_USER="${2:-kopecn}"      # identity of the person running the bootstrap
# shellcheck disable=SC2034
OS_TYPE="${3:-$(uname)}"        # detected OS (unused here; uniform contract)
TARGET_BRANCH="${4:-dev}"       # bashTools branch to check out after clone

REPO_URL="git@github.com:$GITHUB_PROJECT/bashTools.git"
TARGET_DIR="$HOME/.environment/bashTools"

if [ -d "$TARGET_DIR/.git" ]; then
  echo "Repository already exists at $TARGET_DIR. Skipping..."
else
  echo "Cloning $REPO_URL into $TARGET_DIR..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi

# Ensure we are on the requested branch (fetch first so it exists locally).
echo "Checking out branch '$TARGET_BRANCH' in $TARGET_DIR..."
( cd "$TARGET_DIR" && git fetch origin "$TARGET_BRANCH" && git checkout "$TARGET_BRANCH" )

# Install the tools from the repo root. Run in a subshell so the cd does not
# leak into the caller's working directory.
echo "▶️ Running 'make install-bash-tools' in $TARGET_DIR ..."
( cd "$TARGET_DIR" && make install-bash-tools )
