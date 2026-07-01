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
#                already present; appends `autoload -Uz compinit && compinit`
#                to ~/.zshrc to initialize the zsh completion system;
#                creates either file if it does not exist
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# Absolute path to the directory that will be added to PATH.
TARGET_DIR="$HOME/__Workspaces__/bashWorkspaces/bashTools/hostScripts"

# -----------------------------------------------------------------------------
# add_to_shell_config
#   Appends a line to a shell config file if it is not already present.
#   Idempotent: uses grep -Fxq to check for an exact match before appending,
#   so running this function twice will not create duplicate entries.
#
# Arguments:
#   $1  shell_config — absolute path to the shell config file (e.g. ~/.bashrc)
#   $2  line         — the exact line to append
#
# Side Effects : Creates the file if it does not exist; appends one line if the
#                entry is not already present
# -----------------------------------------------------------------------------
add_to_shell_config() {
    local shell_config="$1"
    local line="$2"

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

# Add bashTools/hostScripts to PATH in both Bash and Zsh
add_to_shell_config "$HOME/.bashrc" "export PATH=\"\$PATH:$TARGET_DIR\""
add_to_shell_config "$HOME/.zshrc"  "export PATH=\"\$PATH:$TARGET_DIR\""

# Initialize zsh completion system — required for tab-completion to work
add_to_shell_config "$HOME/.zshrc" "autoload -Uz compinit && compinit"

echo "Please manually Reload your shell by running both:"
echo "    source ~/.bashrc"
echo "    source ~/.zshrc"

