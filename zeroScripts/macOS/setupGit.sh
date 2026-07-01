#!/bin/bash
# =============================================================================
# Script Name  : setupGit.sh (macOS)
# Description  : Installs git via Homebrew and configures the global git
#                user.name and user.email. macOS-only; the Ubuntu equivalent
#                lives in zeroScripts/ubuntu/setupGit.sh.
# Prerequisites: macOS (Darwin) with Homebrew installed. Run
#                zeroScripts/macOS/setupXcodeAndBrew.sh first to ensure the
#                Command Line Tools and Homebrew are present.
# Side Effects : Installs the git package; writes to ~/.gitconfig
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

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
  read -rp "Enter your Git user name [${name_hint}]: " git_user_name
  read -rp "Enter your Git email [${email_hint}]: " git_user_email

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

# Sanity guard: this variant is Homebrew-based and macOS-only.
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This is the macOS variant (Homebrew) but a non-Darwin OS was detected."
  echo "   On Ubuntu run zeroScripts/ubuntu/setupGit.sh instead. Exiting."
  exit 1
fi

# Homebrew must already be installed (see setupXcodeAndBrew.sh).
if ! command -v brew &>/dev/null; then
  echo "❌ Homebrew is not installed. Run zeroScripts/macOS/setupXcodeAndBrew.sh"
  echo "   first, or install it manually: https://brew.sh/  Exiting."
  exit 1
fi

brew install git

git --version

set_git_config
