#!/bin/bash
# =============================================================================
# Script Name  : setupGit.sh (ubuntu)
# Description  : Installs git via apt and configures the global git user.name
#                and user.email. Ubuntu-only; the macOS equivalent lives in
#                zeroScripts/macOS/setupGit.sh.
# Prerequisites: Ubuntu with sudo access
# Side Effects : Installs the git package; writes to ~/.gitconfig
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Positional contract (forwarded by zeroBringup.sh to every sub-script) ----
# $1 = GitHub project/owner, $2 = GitHub user. Accepted for a uniform calling
# convention; this script does not use them.
# shellcheck disable=SC2034
GITHUB_PROJECT="${1:-kopecn}"
# shellcheck disable=SC2034
GITHUB_USER="${2:-kopecn}"

# -----------------------------------------------------------------------------
# set_git_config
#   Prompts the user for a git display name and email, pre-filling with any
#   values already present in the global git config. Trims whitespace from
#   both inputs, confirms with the user, then writes the values to the global
#   git config (git config --global user.name / user.email).
#
# Returns:
#   0 always — skips writing config if the user cancels or leaves fields empty
# -----------------------------------------------------------------------------
set_git_config() {
  # Use any existing git config values as defaults
  local default_name
  local default_email
  default_name=$(git config --global user.name 2>/dev/null || echo "")
  default_email=$(git config --global user.email 2>/dev/null || echo "")

  # Prompt — show existing value in brackets if present, otherwise mark required
  local name_hint="${default_name:-(required)}"
  local email_hint="${default_email:-(required)}"
  read -rp "Setting git user name for this host [${name_hint}]: " git_user_name
  read -rp "Setting git email for this host [${email_hint}]: " git_user_email

  # Use existing config value if user pressed Enter with no input
  git_user_name="${git_user_name:-$default_name}"
  git_user_email="${git_user_email:-$default_email}"

  # Trim leading/trailing whitespace using parameter expansion:
  #   ${var#"${var%%[![:space:]]*}"}  strips leading whitespace
  #   ${var%"${var##*[![:space:]]}"}  strips trailing whitespace
  git_user_name="${git_user_name#"${git_user_name%%[![:space:]]*}"}"
  git_user_name="${git_user_name%"${git_user_name##*[![:space:]]}"}"
  git_user_email="${git_user_email#"${git_user_email%%[![:space:]]*}"}"
  git_user_email="${git_user_email%"${git_user_email##*[![:space:]]}"}"

  if [[ -n "$git_user_name" && -n "$git_user_email" ]]; then
    echo "You entered:"
    echo "  Name: $git_user_name"
    echo "  Email: $git_user_email"
    read -rp "Is this correct? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      git config --global user.name "$git_user_name"
      git config --global user.email "$git_user_email"
      echo "Git user.name and user.email set successfully."
    else
      echo "Git config not set. Please run 'git config' manually later."
    fi
  else
    echo "User name or email was empty. Git config not set."
  fi
}

# Sanity guard: this variant is apt-based and Ubuntu-only.
if ! grep -qi '^ID=ubuntu' /etc/os-release 2>/dev/null; then
  echo "❌ This is the Ubuntu variant (apt) but a non-Ubuntu OS was detected."
  echo "   On macOS run zeroScripts/macOS/setupGit.sh instead. Exiting."
  exit 1
fi

echo "This will run: sudo apt update && sudo apt install -y git"
read -rp "Continue? (y/N): " apt_confirm
if [[ ! "$apt_confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi
sudo apt update
sudo apt install -y git

git --version

set_git_config
