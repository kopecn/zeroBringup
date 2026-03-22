#!/bin/bash
# =============================================================================
# Script Name  : zeroBringup.sh
# Description  : Bootstraps a new macOS or Ubuntu development environment by
#                downloading and running each setup script in sequence.
# Usage        : bash -c "$(curl -fsSL https://raw.githubusercontent.com/kopecn/zeroBringup/refs/heads/main/zeroBringup.sh)"
# Prerequisites: macOS (Darwin) or Ubuntu; internet access to reach GitHub
# Side Effects : Delegates all side effects to the sub-scripts below:
#                  1. setupGit.sh        — installs git, sets global user config
#                  2. setupSSHandGithub.sh — generates SSH key, configures GitHub
#                  3. setupEnvironment.sh — clones personal repositories
#                  4. linkBashTools.sh   — adds bashTools/hostScripts to PATH
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# Base URL for raw script content on the main branch of this repository.
# Each sub-script is fetched and piped directly into bash at runtime.
GITHUB_BASE_URL="https://raw.githubusercontent.com/kopecn/zeroBringup/refs/heads/main/zeroScripts"

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

# Ordered list of sub-scripts to execute. Each is downloaded and piped into
# bash individually so that interactive prompts (read -rp) work correctly.
#   1. setupGit.sh          — install git, set global user.name / user.email
#   2. setupSSHandGithub.sh — generate ED25519 SSH key, configure GitHub auth
#   3. setupEnvironment.sh  — clone personal repos to standard directory layout
#   4. linkBashTools.sh     — append bashTools/hostScripts to PATH
scripts=(
    "setupGit.sh"
    "setupSSHandGithub.sh"
    "setupEnvironment.sh"
    "linkBashTools.sh"
)

# Run scripts
for script in "${scripts[@]}"; do
    echo "▶️ Running $script ..."
    
    if ! /bin/bash -c "$(curl -fsSL "${GITHUB_BASE_URL}/${script}")"; then
        echo "❌ Error running $script"
        exit 1
    fi
done

echo "✅ All scripts executed successfully."
