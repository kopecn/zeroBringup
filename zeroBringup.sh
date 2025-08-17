#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

GITHUB_BASE_URL="https://raw.githubusercontent.com/kopecn/zeroBringup/refs/heads/main/zeroScripts"

# Detect OS
OS_TYPE=""
if [[ "$(uname)" == "Darwin" ]]; then
    OS_TYPE="macOS"
elif [[ -f /etc/os-release ]]; then
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
