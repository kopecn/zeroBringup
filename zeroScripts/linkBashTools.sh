#!/bin/bash

# Define the path to add (convert to absolute path)
TARGET_DIR="$HOME/__Workspaces__/bashWorkspaces/bashTools/hostScripts"
ABS_TARGET_DIR="$(realpath "$TARGET_DIR")"

# Function to add line to shell config if not already present
add_to_shell_config() {
    local shell_config="$1"
    local line="export PATH=\"\$PATH:$ABS_TARGET_DIR\""

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

