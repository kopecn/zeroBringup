#!/bin/bash
set -e  # Exit on any error

set_git_config() {
  # Hardcoded defaults
  local default_name="kopecn"
  local default_email="nicholas.bergantz@gmail.com"

  # Prompt with hardcoded defaults shown in brackets
  read -rp "Enter your Git user name [${default_name}]: " git_user_name
  read -rp "Enter your Git email [${default_email}]: " git_user_email

  # Use defaults if input empty
  git_user_name="${git_user_name:-$default_name}"
  git_user_email="${git_user_email:-$default_email}"

  # Trim leading/trailing whitespace
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

# Detect OS
OS=""
if [[ "$(uname)" == "Darwin" ]]; then
  OS="darwin"
elif grep -qi '^ID=ubuntu' /etc/os-release 2>/dev/null; then
  OS="ubuntu"
else
  echo "Unsupported OS. This script supports only Ubuntu or macOS (Darwin). Exiting."
  exit 1
fi

echo "Detected OS: $OS"

if [[ "$OS" == "ubuntu" ]]; then
  sudo apt update
  sudo apt install -y git
elif [[ "$OS" == "darwin" ]]; then
  # Check if Homebrew is installed
  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
    exit 1
  fi
  brew install git
fi

git --version

set_git_config
