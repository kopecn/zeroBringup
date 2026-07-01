#!/bin/bash
# =============================================================================
# Script Name  : zeroBringup.sh
# Description  : Bootstraps a new macOS or Ubuntu development environment by
#                downloading and running each setup script in sequence.
# Usage        : bash -c "$(curl -fsSL https://raw.githubusercontent.com/kopecn/zeroBringup/refs/heads/main/zeroBringup.sh)"
# Prerequisites: macOS (Darwin) or Ubuntu; internet access to reach GitHub
# Side Effects : Delegates all side effects to the sub-scripts below. Scripts
#                live in per-OS folders (zeroScripts/{macOS,ubuntu}) plus a
#                shared zeroScripts/common folder:
#                  [macOS]  setupXcodeAndBrew.sh — Xcode CLT + Homebrew
#                  [OS]     setupGit.sh          — installs git, sets user config
#                  [common] setupSSHandGithub.sh — SSH key, configures GitHub
#                  [common] setupEnvironment.sh  — clones personal repositories
#                  [common] linkBashTools.sh     — adds hostScripts to PATH
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# Base URL for raw script content on the main branch of this repository.
# Each sub-script is fetched and piped directly into bash at runtime.
GITHUB_BASE_URL="https://raw.githubusercontent.com/kopecn/zeroBringup/refs/heads/main/zeroScripts"
DEFAULT_GITHUB_USER="kopecn"

# Detect OS
OS_TYPE=""
if [[ "$(uname)" == "Darwin" ]]; then
    OS_TYPE="macOS"
elif [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        OS_TYPE="ubuntu"
    fi
fi

if [[ -z "$OS_TYPE" ]]; then
    echo "❌ Unsupported OS. This script supports only Ubuntu and macOS."
    exit 1
fi

echo "Detected OS: $OS_TYPE"

# Resolve the GitHub username once, here, and export it so each sub-script
# inherits it (they each run in their own piped `bash -c`). Honors a value
# passed via the environment (e.g. `GITHUB_USER=foo bash -c "$(curl ...)"`)
# and only prompts when unset; defaults to "kopecn" when left blank.
# Intentionally does NOT read the value from `git config github.user`.
if [[ -z "${GITHUB_USER:-}" ]]; then
    read -rp "Enter your GitHub username [${DEFAULT_GITHUB_USER}]: " GITHUB_USER
fi
GITHUB_USER="${GITHUB_USER:-$DEFAULT_GITHUB_USER}"
export GITHUB_USER
echo "Using GitHub username: $GITHUB_USER"

# Ordered list of sub-scripts to execute. Scripts are split into per-OS batches
# (zeroScripts/macOS, zeroScripts/ubuntu) and a shared batch (zeroScripts/common).
# The OS-specific batch runs first (it installs the prerequisites the common
# batch depends on), then the common batch. Each entry is a path relative to
# GITHUB_BASE_URL and is downloaded and piped into bash individually so that
# interactive prompts (read -rp) work correctly.
#
# macOS OS batch:
#   1. macOS/setupXcodeAndBrew.sh — install Xcode CLT + Homebrew (prereqs)
#   2. macOS/setupGit.sh          — brew install git, set user.name / user.email
# ubuntu OS batch:
#   1. ubuntu/setupGit.sh         — apt install git, set user.name / user.email
# common batch (both OSes):
#   1. common/setupSSHandGithub.sh — generate ED25519 SSH key, configure GitHub
#   2. common/setupEnvironment.sh  — clone personal repos to standard layout
#   3. common/linkBashTools.sh     — append bashTools/hostScripts to PATH
if [[ "$OS_TYPE" == "macOS" ]]; then
    scripts=(
        "macOS/setupXcodeAndBrew.sh"
        "macOS/setupGit.sh"
        "common/setupSSHandGithub.sh"
        "common/setupEnvironment.sh"
        "common/linkBashTools.sh"
    )
else
    scripts=(
        "ubuntu/setupGit.sh"
        "common/setupSSHandGithub.sh"
        "common/setupEnvironment.sh"
        "common/linkBashTools.sh"
    )
fi

# Run scripts. Fetch and execute as two steps: a command substitution swallows
# curl's exit status, so download into a variable first (the assignment carries
# curl's status) and only run the body if the download succeeded.
for script in "${scripts[@]}"; do
    echo "▶️ Running $script ..."

    if ! script_body="$(curl -fsSL "${GITHUB_BASE_URL}/${script}")"; then
        echo "❌ Failed to download $script from ${GITHUB_BASE_URL}/${script}"
        exit 1
    fi

    if ! /bin/bash -c "$script_body"; then
        echo "❌ Error running $script"
        exit 1
    fi
done

echo "✅ All scripts executed successfully."
