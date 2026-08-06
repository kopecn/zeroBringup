#!/bin/bash
# =============================================================================
# Description  : Bootstraps a new macOS or Ubuntu development environment by
#                downloading and running each setup script in sequence.
# Usage        : bash -c "$(curl -fsSL https://raw.githubusercontent.com/kopecn/zeroBringup/refs/heads/main/zeroBringup.sh)"
#                (Forking? This bootstrap URL is fixed — it's how the shell
#                reaches this file — so edit the owner/repo here to match your
#                fork, then update the DEFAULT_* fork variables below.)
# Prerequisites: macOS (Darwin) or Ubuntu; internet access to reach GitHub
#                (not required with --local)
# Flags        : --local  Source sub-scripts from the sibling zeroScripts/
#                         directory instead of fetching them via curl. Bypasses
#                         raw.githubusercontent.com CDN caching for testing;
#                         used by `make run-local`.
#                --prod   Run against the released branch ($PROD_BRANCH)
#                         instead of the canonical default ($DEFAULT_BRANCH).
#                         Switches BOTH the branch sub-scripts are fetched from
#                         and the branch checked out in every repo installed;
#                         used by `make run-prod`.
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
DEFAULT_BRANCH="dev"
#   canonical branch. ONE knob for the whole chain: it is both the branch this
#   bootstrap fetches its sub-scripts from and the branch checked out in EVERY
#   repo it installs — bashTools here, and (forwarded through bashTools'
#   install.sh) Environment, claude-skills-memory and my-galaxy-playbooks.
PROD_BRANCH="prod"
#   released branch. Opt in with --prod; never the default.
##### --- #####

# MARK: - 0. Parse flags
# --local sources sub-scripts from the sibling zeroScripts/ dir instead of curl,
# so pushed-but-CDN-stale changes can be tested immediately.
# --prod moves the whole chain off the canonical dev branch onto the released
# one; parsed before GITHUB_BASE_URL is built because it selects that URL.
USE_LOCAL=0
INSTALL_BRANCH="$DEFAULT_BRANCH"
for arg in "$@"; do
    case "$arg" in
        --local) USE_LOCAL=1 ;;
        --prod) INSTALL_BRANCH="$PROD_BRANCH" ;;
        *) echo "❌ Unknown argument: $arg (supported: --local, --prod)"; exit 1 ;;
    esac
done

echo "🌿 Branch: $INSTALL_BRANCH"

# Base URL for raw script content on the selected branch of this repository.
# Each sub-script is fetched and piped directly into bash at runtime.
GITHUB_BASE_URL="https://raw.githubusercontent.com/${DEFAULT_GITHUB_PROJECT}/${DEFAULT_LAUNCH_REPO}/refs/heads/${INSTALL_BRANCH}/${DEFAULT_LAUNCH_SCRIPT}"

if [[ "$USE_LOCAL" -eq 1 ]]; then
    # Resolve the local sub-script root relative to this file. Requires running
    # as a real file (bash zeroBringup.sh), not the curl-pipe entrypoint.
    LOCAL_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${DEFAULT_LAUNCH_SCRIPT}"
    echo "🧪 LOCAL mode: sourcing sub-scripts from ${LOCAL_SCRIPTS_DIR} (CDN bypassed)"
fi

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

# MARK: - 3.5 Require a clean slate under $HOME/.environment
# This is a zero-to-working bootstrap: every repo below is meant to be cloned
# fresh. A directory left over from an earlier run shadows that clone — the pull
# sub-scripts skip cloning when a .git is already present — so the bootstrap
# proceeds against whatever stale commit happens to be checked out. Refuse to
# guess at reconciling that; delete on confirmation, or abort.
ENVIRONMENT_ROOT="$HOME/.environment"
# Every repo setupEnvironment.sh clones, EXCEPT zeroBringup itself — this script
# is running from that checkout, so deleting it would saw off the branch we sit
# on. Keep in sync with bashTools' installScripts/common/setupEnvironment.sh.
MANAGED_CLONES=(
    "bashTools"
    "claude-skills-memory"
    "Environment"
    "my-galaxy-playbooks"
    "productivity"
)

EXISTING_CLONES=()
for clone in "${MANAGED_CLONES[@]}"; do
    if [[ -e "${ENVIRONMENT_ROOT}/${clone}" ]]; then
        EXISTING_CLONES+=("${ENVIRONMENT_ROOT}/${clone}")
    fi
done

# Guard the expansion: under `set -u`, "${arr[@]}" on an empty array is an error
# in the bash 3.2 that ships with macOS.
if [[ ${#EXISTING_CLONES[@]} -gt 0 ]]; then
    echo "⚠️  These directories already exist and would shadow a fresh clone:"
    printf '     %s\n' "${EXISTING_CLONES[@]}"
    echo "     Any uncommitted or unpushed work in them will be lost."
    read -rp "Delete them and continue? [y/N]: " CONFIRM_DELETE

    if [[ ! "${CONFIRM_DELETE:-}" =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Remove or relocate the directories above, then re-run."
        exit 1
    fi

    for dir in "${EXISTING_CLONES[@]}"; do
        echo "🗑  Removing $dir"
        rm -rf "$dir"
    done
fi

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

    if [[ "$USE_LOCAL" -eq 1 ]]; then
        local_src="${LOCAL_SCRIPTS_DIR}/${script}"
        if [[ ! -f "$local_src" ]]; then
            echo "❌ Local script not found: $local_src"
            exit 1
        fi
        script_body="$(cat "$local_src")"
    elif ! script_body="$(curl -fsSL "${GITHUB_BASE_URL}/${script}")"; then
        echo "❌ Failed to download $script from ${GITHUB_BASE_URL}/${script}"
        exit 1
    fi

    # Forward the project/user to every sub-script positionally ($0=name,
    # $1=project, $2=user, $3=OS_TYPE, $4=install branch), whether or not
    # that script consumes them.
    if ! /bin/bash -c "$script_body" "$script" "$GITHUB_PROJECT" "$GITHUB_USER" "$OS_TYPE" "$INSTALL_BRANCH"; then
        echo "❌ Error running $script"
        exit 1
    fi
done

echo "✅ All scripts executed successfully."
