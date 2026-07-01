#!/bin/bash
# =============================================================================
# Script Name  : setupSSHandGithub.sh
# Description  : Generates an ED25519 SSH key pair for GitHub authentication,
#                configures the SSH agent and ~/.ssh/config, verifies the
#                GitHub host key fingerprint to guard against MITM attacks,
#                and tests the resulting connection.
# Prerequisites: git must be installed; git config user.email should be set
#                (used as the SSH key comment if no email is provided manually)
# Side Effects : Creates ~/.ssh/id_ed25519_github_<hostname>{,.pub}
#                Appends a Host github.com block to ~/.ssh/config
#                Appends github.com to ~/.ssh/known_hosts (after fingerprint check)
#                Sets permissions: 700 on ~/.ssh, 600 on private files, 644 on *.pub
# =============================================================================

set -euo pipefail

# === CONFIGURATION ===
HOSTNAME_ID=$(hostname)
KEY_NAME="id_ed25519_github_${HOSTNAME_ID}"
KEY_FILE="$HOME/.ssh/$KEY_NAME"
EMAIL=$(git config --get user.email || echo "")
SSH_CONFIG="$HOME/.ssh/config"
GITHUB_SSH_URL="https://github.com/settings/ssh/new"

# === FUNCTIONS ===

# -----------------------------------------------------------------------------
# generate_ssh_key
#   Prompts for an email address (defaults to git config user.email) and
#   generates an ED25519 SSH key pair at KEY_FILE / KEY_FILE.pub.
#
# Side Effects : Writes $KEY_FILE and $KEY_FILE.pub via ssh-keygen
# Returns      : Exits 1 if no email is provided
# -----------------------------------------------------------------------------
generate_ssh_key() {
    echo "🔐 Generating new SSH key..."
    read -rp "Enter email for SSH key [${EMAIL}]: " input_email
    EMAIL="${input_email:-$EMAIL}"

    if [[ -z "$EMAIL" ]]; then
        echo "❌ Email is required. Aborting."
        exit 1
    fi

    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_FILE"
    echo "✅ SSH key generated at $KEY_FILE"
}

# -----------------------------------------------------------------------------
# start_ssh_agent
#   Starts the SSH agent in the current shell environment and adds KEY_FILE
#   so subsequent SSH commands authenticate with the generated key.
#
# Side Effects : Exports SSH_AUTH_SOCK and SSH_AGENT_PID into the environment
# -----------------------------------------------------------------------------
start_ssh_agent() {
    echo "🚀 Starting ssh-agent..."
    eval "$(ssh-agent -s)"
    ssh-add "$KEY_FILE"
}

# -----------------------------------------------------------------------------
# update_ssh_config
#   Appends a GitHub Host block to ~/.ssh/config pointing to KEY_FILE.
#   Idempotent: checks for the presence of KEY_FILE path before appending,
#   so running this function multiple times will not create duplicate entries.
#
# Side Effects : May append to ~/.ssh/config; sets its permissions to 600
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# show_public_key
#   Prints the contents of KEY_FILE.pub to stdout along with the key name,
#   formatted for easy copy-paste into the GitHub SSH key settings page.
# -----------------------------------------------------------------------------
show_public_key() {
    echo ""
    echo "📋 Title: $KEY_NAME"
    echo "📋 Public Key:"
    echo "-----------------------------"
    cat "$KEY_FILE.pub"
    echo "-----------------------------"
}

# -----------------------------------------------------------------------------
# open_github_ssh_page
#   Attempts to open the GitHub SSH key settings URL in the default browser.
#   Uses xdg-open on Linux or open on macOS; falls back to printing the URL
#   if neither command is available.
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# secure_ssh_permissions
#   Enforces standard SSH directory and file permissions required by the
#   SSH client: 700 on ~/.ssh, 600 on all private files, 644 on *.pub.
#   Also ensures ~/.ssh/authorized_keys exists to avoid permission errors.
# -----------------------------------------------------------------------------
secure_ssh_permissions() {
    echo "🔒 Securing SSH directory permissions..."

    touch "$HOME/.ssh/authorized_keys"

    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh"/*
    chmod 644 "$HOME/.ssh"/*.pub 2>/dev/null || true

    echo "✅ SSH permissions secured."
}

# -----------------------------------------------------------------------------
# test_github_connection
#   Verifies the SSH connection to GitHub. Before adding github.com to
#   known_hosts, scans and validates the server's ED25519 fingerprint against
#   GitHub's published value to guard against MITM attacks. Then runs
#   `ssh -T git@github.com` and checks the output for a successful auth message.
#
# Returns:
#   0 if authentication succeeds
#   1 if the connection fails or the fingerprint does not match (exits script)
# -----------------------------------------------------------------------------
test_github_connection() {
    echo "🔌 Testing SSH connection to GitHub..."

    # Add github.com to known_hosts only after verifying its fingerprint matches
    # GitHub's published ED25519 fingerprint (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
    local KNOWN_GITHUB_FINGERPRINT="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"
    if ! ssh-keygen -F github.com >/dev/null 2>&1; then
        echo "🔍 Verifying GitHub host key fingerprint..."
        local SCANNED_KEY
        SCANNED_KEY=$(ssh-keyscan -t ed25519 github.com 2>/dev/null)
        local SCANNED_FINGERPRINT
        SCANNED_FINGERPRINT=$(echo "$SCANNED_KEY" | ssh-keygen -lf /dev/stdin 2>/dev/null | awk '{print $2}')
        if [[ "$SCANNED_FINGERPRINT" != "$KNOWN_GITHUB_FINGERPRINT" ]]; then
            echo "❌ GitHub host key fingerprint mismatch!"
            echo "   Expected: $KNOWN_GITHUB_FINGERPRINT"
            echo "   Got:      $SCANNED_FINGERPRINT"
            echo "   Possible MITM attack. Aborting."
            exit 1
        fi
        echo "$SCANNED_KEY" >> "$HOME/.ssh/known_hosts"
        echo "✅ GitHub host key verified and added to known_hosts."
    fi

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
secure_ssh_permissions
show_public_key
open_github_ssh_page

read -rp "⏳ Press ENTER after you've added the SSH key to GitHub..."

test_github_connection
