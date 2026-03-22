#!/bin/bash
# =============================================================================
# Script Name  : linkBashTools.sh
# Description  : Appends the bashTools/hostScripts directory to PATH in both
#                ~/.bashrc and ~/.zshrc so custom host scripts are available
#                in any new shell session.
# Prerequisites: The bashTools repo should be cloned at
#                $HOME/__Workspaces__/bashWorkspaces/bashTools (done by
#                setupEnvironment.sh) before sourcing the updated shell config
# Side Effects : Appends an export PATH line to ~/.bashrc and ~/.zshrc if not
#                already present; creates either file if it does not exist
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# Absolute path to the directory that will be added to PATH.
TARGET_DIR="$HOME/__Workspaces__/bashWorkspaces/bashTools/hostScripts"

# -----------------------------------------------------------------------------
# add_to_shell_config
#   Appends an `export PATH` line for TARGET_DIR to a shell config file.
#   Idempotent: uses grep -Fxq to check for an exact match before appending,
#   so running this function twice will not create duplicate PATH entries.
#
# Arguments:
#   $1  shell_config — absolute path to the shell config file (e.g. ~/.bashrc)
#
# Side Effects : Creates the file if it does not exist; appends one line if the
#                PATH entry is not already present
# -----------------------------------------------------------------------------
add_to_shell_config() {
    local shell_config="$1"
    local line="export PATH=\"\$PATH:$TARGET_DIR\""

    if [ ! -f "$shell_config" ]; then
        touch "$shell_config"
    fi

    if ! grep -Fxq "$line" "$shell_config"; then
        echo "$line" >> "$shell_config"
        echo "✅ Added to $shell_config"
    else
        echo "⚠️ Already present in $shell_config"
    fi
}

# Update both Bash and Zsh config files
add_to_shell_config "$HOME/.bashrc"
add_to_shell_config "$HOME/.zshrc"

echo "Please manually Reload your shell by running both:"
echo "    source ~/.bashrc"
echo "    source ~/.zshrc"

