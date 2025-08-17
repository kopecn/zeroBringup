#!/bin/bash

set -euo pipefail

# === CONFIGURATION ===
HOSTNAME_ID=$(hostname)
KEY_NAME="id_rsa_github_${HOSTNAME_ID}"
KEY_FILE="$HOME/.ssh/$KEY_NAME"
EMAIL=$(git config --get user.email || echo "")
SSH_CONFIG="$HOME/.ssh/config"
GITHUB_SSH_URL="https://github.com/settings/ssh/new"

# === FUNCTIONS ===

generate_ssh_key() {
    echo "🔐 Generating new SSH key..."
    read -p "Enter email for SSH key [${EMAIL}]: " input_email
    EMAIL="${input_email:-$EMAIL}"

    if [[ -z "$EMAIL" ]]; then
        echo "❌ Email is required. Aborting."
        exit 1
    fi

    ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$KEY_FILE" -N ""
    echo "✅ SSH key generated at $KEY_FILE"
}

start_ssh_agent() {
    echo "🚀 Starting ssh-agent..."
    eval "$(ssh-agent -s)"
    ssh-add "$KEY_FILE"
}

update_ssh_config() {
    echo "🛠️  Updating SSH config for github.com..."

    mkdir -p "$HOME/.ssh"
    touch "$SSH_CONFIG"

    if ! grep -Fq "$KEY_FILE" "$SSH_CONFIG"; then
        {
            echo ""
            echo "Host github.com"
            echo "  HostName github.com"
            echo "  User git"
            echo "  IdentityFile $KEY_FILE"
            echo "  IdentitiesOnly yes"
        } >> "$SSH_CONFIG"
        chmod 600 "$SSH_CONFIG"
        echo "✅ SSH config updated."
    else
        echo "ℹ️  SSH config already contains GitHub entry."
    fi
}

show_public_key() {
    echo ""
    echo "📋 Title: $KEY_NAME"
    echo "📋 Public Key:"
    echo "-----------------------------"
    cat "$KEY_FILE.pub"
    echo "-----------------------------"
}

open_github_ssh_page() {
    echo "🌐 Opening GitHub SSH key settings page..."
    if command -v xdg-open &>/dev/null; then
        xdg-open "$GITHUB_SSH_URL"
    elif command -v open &>/dev/null; then
        open "$GITHUB_SSH_URL"
    else
        echo "🔗 Please open this URL manually: $GITHUB_SSH_URL"
    fi
}

test_github_connection() {
    echo "🔌 Testing SSH connection to GitHub..."

    # Suppress host key prompt by adding github.com to known_hosts if missing
    ssh-keygen -F github.com >/dev/null || ssh-keyscan github.com >> "$HOME/.ssh/known_hosts"

    OUTPUT=$(ssh -T git@github.com 2>&1 || true)

    echo "$OUTPUT"

    if echo "$OUTPUT" | grep -q "successfully authenticated"; then
        echo "✅ SSH connection to GitHub is working!"
        return 0
    else
        echo "❌ SSH connection failed. Check your key or SSH config."
        return 1
    fi
}

# === MAIN EXECUTION ===

echo "📁 SSH Key path: $KEY_FILE"

if [[ -f "$KEY_FILE" ]]; then
    echo "⚠️ SSH key file already exists."

    start_ssh_agent

    if test_github_connection; then
        echo "🎉 Existing SSH key works for GitHub. No need to generate a new key."
        exit 0
    else
        echo "❗ Existing SSH key does not authenticate with GitHub."
        read -rp "Do you want to overwrite it and generate a new SSH key? (y/N): " yn
        case "$yn" in
            [Yy]* )
                rm -f "$KEY_FILE" "$KEY_FILE.pub"
                ;;
            * )
                echo "Aborting."
                exit 1
                ;;
        esac
    fi
fi

# If we reached here, no key exists or user wants to generate new key
generate_ssh_key
start_ssh_agent
update_ssh_config
show_public_key
open_github_ssh_page

read -p "⏳ Press ENTER after you've added the SSH key to GitHub..."

test_github_connection
