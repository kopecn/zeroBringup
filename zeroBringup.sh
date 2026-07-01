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

# Configuration
SUPPORTED_OS=(Darwin Linux)
SUPPORTED_LINUX=(ubuntu fedora)

# 1. Detect base OS
UNAME=$(uname)
if [[ " ${SUPPORTED_OS[@]} " =~ " ${UNAME} " ]]; then
    OS_TYPE="$UNAME"
else
    echo "❌ Unsupported OS. Supported: ${SUPPORTED_OS[*]}"; exit 1
fi

# 2. Refine if Linux
if [[ "$OS_TYPE" == "Linux" ]]; then
    # shellcheck source=/dev/null
    [[ -f /etc/os-release ]] && . /etc/os-release

    if [[ " ${SUPPORTED_LINUX[*]} " =~ " ${ID:-} " ]]; then
        OS_TYPE="$ID"
    else
        echo "❌ Unsupported Linux distro. Supported: ${SUPPORTED_LINUX[*]}"; exit 1
    fi
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
if [[ "$OS_TYPE" == "Darwin" ]]; then
    scripts=(
        "macOS/setupXcodeAndBrew.sh"
        "macOS/setupGit.sh"
        "common/setupSSHandGithub.sh"
        "common/setupEnvironment.sh"
        "common/linkBashTools.sh"
    )
elif [[ "$OS_TYPE" == "ubuntu" ]]; then
    scripts=(
        "ubuntu/setupGit.sh"
        "common/setupSSHandGithub.sh"
        "common/setupEnvironment.sh"
        "common/linkBashTools.sh"
    )
else
    echo "❌ No scripts defined for OS: $OS_TYPE"
    exit 1
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
