#!/bin/bash
# =============================================================================
# Description  : Bootstraps a new macOS or Ubuntu development environment by
#                downloading and running each setup script in sequence.
# Usage        : bash -c "$(curl -fsSL https://raw.githubusercontent.com/kopecn/zeroBringup/refs/heads/main/zeroBringup.sh)"
#                (Forking? This bootstrap URL is fixed — it's how the shell
#                reaches this file — so edit the owner/repo here to match your
#                fork, then update the DEFAULT_* fork variables below.)
# Prerequisites: macOS (Darwin) or Ubuntu; internet access to reach GitHub
# Side Effects : Delegates all side effects to the sub-scripts below.
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

##### Change these if you decide to fork: #####
DEFAULT_GITHUB_PROJECT="kopecn"
#   GitHub account that OWNS the repos being cloned (prompt
#   default, see MARK 3); also the owner in GITHUB_BASE_URL
DEFAULT_GITHUB_USER="kopecn"
#   GitHub identity of the person RUNNING this bootstrap
#   (prompt default, see MARK 3)
DEFAULT_LAUNCH_REPO="zeroBringup"
#   repo that hosts this bootstrap and its sub-scripts
DEFAULT_LAUNCH_SCRIPT="zeroScripts"
#   sub-directory within LAUNCH_REPO holding the sub-scripts
##### --- #####

# Base URL for raw script content on the main branch of this repository.
# Each sub-script is fetched and piped directly into bash at runtime.
GITHUB_BASE_URL="https://raw.githubusercontent.com/${DEFAULT_GITHUB_PROJECT}/${DEFAULT_LAUNCH_REPO}/refs/heads/main/${DEFAULT_LAUNCH_SCRIPT}"

# MARK: - Configuration
SUPPORTED_OS=(Darwin Linux)
SUPPORTED_LINUX=(ubuntu fedora)

# MARK: - 1. Detect base OS
UNAME=$(uname)
if [[ " ${SUPPORTED_OS[@]} " =~ " ${UNAME} " ]]; then
    OS_TYPE="$UNAME"
else
    echo "❌ Unsupported OS. Supported: ${SUPPORTED_OS[*]}"; exit 1
fi

# MARK: - 2. Refine if Linux
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

# MARK: - 3. Resolve the GitHub project (repo owner) and user (identity)
# Queried once, here, and forwarded as positional args ($1=project, $2=user) to
# every sub-script below. The two are decoupled: the repos can live under one
# account (project) while a different person (user) runs the bootstrap.
if [[ -z "${GITHUB_PROJECT:-}" ]]; then
    read -rp "Enter the GitHub project/owner that hosts the repos [${DEFAULT_GITHUB_PROJECT}]: " GITHUB_PROJECT
fi
GITHUB_PROJECT="${GITHUB_PROJECT:-$DEFAULT_GITHUB_PROJECT}"

if [[ -z "${GITHUB_USER:-}" ]]; then
    read -rp "Enter your GitHub username [${DEFAULT_GITHUB_USER}]: " GITHUB_USER
fi
GITHUB_USER="${GITHUB_USER:-$DEFAULT_GITHUB_USER}"

echo "Using GitHub project: $GITHUB_PROJECT"
echo "Using GitHub user:    $GITHUB_USER"

# MARK: - 4. Ordered list 
# of sub-scripts to execute. 
if [[ "$OS_TYPE" == "Darwin" ]]; then
    scripts=(
        "macOS/setupXcodeAndBrew.sh"
        "macOS/setupGit.sh"
        "common/setupSSHandGithub.sh"
        "common/pullBashTools.sh"
    )
elif [[ "$OS_TYPE" == "ubuntu" ]]; then
    scripts=(
        "ubuntu/setupGit.sh"
        "common/setupSSHandGithub.sh"
        "common/pullBashTools.sh"
    )
else
    echo "❌ No scripts defined for OS: $OS_TYPE"
    exit 1
fi

# MARK: - 5. Run bootstrap scripts. 
# Fetch and execute as two steps: a command substitution swallows
# curl's exit status, so download into a variable first (the assignment carries
# curl's status) and only run the body if the download succeeded.
for script in "${scripts[@]}"; do
    echo "▶️ ==================="
    echo "▶️ Running $script ..."

    if ! script_body="$(curl -fsSL "${GITHUB_BASE_URL}/${script}")"; then
        echo "❌ Failed to download $script from ${GITHUB_BASE_URL}/${script}"
        exit 1
    fi

    # Forward the project/user to every sub-script positionally ($0=name,
    # $1=project, $2=user), whether or not that script consumes them.
    if ! /bin/bash -c "$script_body" "$script" "$GITHUB_PROJECT" "$GITHUB_USER"; then
        echo "❌ Error running $script"
        exit 1
    fi
done

echo "✅ All scripts executed successfully."
