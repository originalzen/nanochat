#!/bin/bash

bash -lc '
set -euo pipefail

# ════════════════════════════════════════════════════════════
# 0. SSH Setup (Required for SCP/SFTP - No Password Provided)
# ════════════════════════════════════════════════════════════
# Runpod pods have no root password; only SSH key authentication works.
# PUBLIC_KEY env var is auto-injected from Runpod account settings.

echo "==> Setting up SSH/SCP access..."
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q openssh-server

# Create SSH directory with secure permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Configure SSH key authentication (bypasses password requirement)
if [ -n "${PUBLIC_KEY}" ]; then
  echo "$PUBLIC_KEY" > ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  echo "==> SSH public key configured"
else
  echo "==> WARNING: PUBLIC_KEY not set - SSH key auth will not work"
fi

# Start SSH daemon for SCP/SFTP access
service ssh start
echo "==> SSH daemon started - SCP/SFTP now available"

# ═══════════════════════════════
# 1. Environment Variables Setup
# ═══════════════════════════════

export PIP_ROOT_USER_ACTION=ignore

# HuggingFace token (required for dataset & checkpoint upload)
export HF_TOKEN="${HF_TOKEN:-}"
export HUGGING_FACE_HUB_TOKEN="${HF_TOKEN:-}"  # Alias for compatibility

# Weights & Biases (recommended for real-time training monitoring)
export WANDB_API_KEY="${WANDB_API_KEY:-}"

# Git configuration
GIT_USERNAME="${GIT_USERNAME:-originalzen}"  # GitHub username
GIT_USER_NAME="${GIT_USER_NAME:-}"           # Git author name
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"         # Git author email
GITHUB_PAT="${GITHUB_PAT:-}"                 # Your token for private repos

# ════════════════════════════════════
# 2. System Dependencies Installation
# ════════════════════════════════════

echo "==> Installing system dependencies..."
# Using -q (not -qq) option to suppress progress bars while preserving package names and errors for debugging
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  git nano screen vim ninja-build build-essential \
  python3-dev python3-venv libnuma1 libnuma-dev \
  pkg-config curl ca-certificates wget unzip

# ═════════════════════════════════════════
# 3. Git Identity Configuration (Optional)
# ═════════════════════════════════════════

if [ -n "${GIT_USER_NAME}" ]; then
  git config --global user.name "$GIT_USER_NAME"
  echo "==> Git user.name set to: $GIT_USER_NAME"
fi

if [ -n "${GIT_USER_EMAIL}" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
  echo "==> Git user.email set to: $GIT_USER_EMAIL"
fi

# ══════════════════════
# 4. Repository Cloning
# ══════════════════════

cd /workspace
REPO_URL="https://github.com/${GIT_USERNAME}/nanochat.git"

if [ -d nanochat/.git ]; then
  echo "==> Repository exists, pulling latest..."
  git -C nanochat pull --ff-only
else
  echo "==> Cloning nanochat from ${REPO_URL}..."
  if [ -n "${GITHUB_PAT}" ]; then
    # Authenticated clone (required for private repositories)
    git clone "https://${GITHUB_PAT}@github.com/${GIT_USERNAME}/nanochat.git"
  else
    # Unauthenticated clone (public repositories)
    git clone "${REPO_URL}"
  fi
fi

cd nanochat

exec /start.sh
'
