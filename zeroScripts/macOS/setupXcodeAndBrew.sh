#!/bin/bash
# =============================================================================
# Script Name  : setupXcodeAndBrew.sh (macOS)
# Description  : Ensures the Xcode Command Line Tools (CLT) and Homebrew are
#                installed — the prerequisites every later macOS setup script
#                depends on. Idempotent: skips whatever is already present.
# Prerequisites: macOS (Darwin); internet access; an administrator account
#                (the CLT and Homebrew installers prompt for the login password)
# Side Effects : Installs the Command Line Tools via `xcode-select --install`;
#                installs Homebrew via its official install script; appends the
#                `brew shellenv` line to ~/.zprofile on Apple Silicon so brew is
#                on PATH in future shells.
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# Sanity guard: macOS-only.
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script is macOS-only (Xcode CLT + Homebrew). Exiting."
  exit 1
fi

# -----------------------------------------------------------------------------
# ensure_command_line_tools
#   Ensures the Xcode Command Line Tools are installed. `xcode-select -p`
#   succeeds only when an active developer directory is set, so it doubles as
#   the presence check. If missing, triggers the GUI installer and waits for
#   the user to complete it (the installer runs asynchronously in its own
#   window and cannot be driven headlessly).
# -----------------------------------------------------------------------------
ensure_command_line_tools() {
  if xcode-select -p &>/dev/null; then
    echo "ℹ️  Command Line Tools already installed at: $(xcode-select -p)"
    return 0
  fi

  echo "🔧 Installing Xcode Command Line Tools..."
  echo "   A system dialog will open — click \"Install\" and accept the license."
  xcode-select --install || true

  # Block until the CLT are actually present. The installer is async, so poll.
  until xcode-select -p &>/dev/null; do
    read -rp "⏳ Press ENTER once the Command Line Tools install has finished..."
  done
  echo "✅ Command Line Tools installed at: $(xcode-select -p)"
}

# -----------------------------------------------------------------------------
# ensure_homebrew
#   Installs Homebrew if `brew` is not already on PATH, then loads its shell
#   environment for the current session. On Apple Silicon brew lives at
#   /opt/homebrew; on Intel at /usr/local. Persists the shellenv line to
#   ~/.zprofile so future shells find brew without re-running this script.
# -----------------------------------------------------------------------------
ensure_homebrew() {
  if command -v brew &>/dev/null; then
    echo "ℹ️  Homebrew already installed at: $(command -v brew)"
    return 0
  fi

  echo "🍺 Installing Homebrew..."
  # Official installer; also installs the CLT itself if still missing.
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Locate the freshly installed brew (PATH is not yet updated this session).
  local brew_bin=""
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin="/opt/homebrew/bin/brew"       # Apple Silicon
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin="/usr/local/bin/brew"          # Intel
  else
    echo "❌ Homebrew install did not produce a brew binary. Exiting."
    exit 1
  fi

  # Load brew into this session and persist for future zsh login shells.
  eval "$("$brew_bin" shellenv)"
  local shellenv_line="eval \"\$(${brew_bin} shellenv)\""
  if ! grep -Fxq "$shellenv_line" "$HOME/.zprofile" 2>/dev/null; then
    echo "$shellenv_line" >> "$HOME/.zprofile"
    echo "✅ Added Homebrew to PATH in ~/.zprofile"
  fi

  echo "✅ Homebrew installed: $(brew --version | head -n1)"
}

echo "🚀 Bootstrapping macOS prerequisites (Command Line Tools + Homebrew)..."
ensure_command_line_tools
ensure_homebrew
echo "✅ macOS prerequisites ready."
