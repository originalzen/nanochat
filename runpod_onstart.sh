#!/bin/bash
#
# RunPod Template Startup Script for NanoChat Training
# Author: originalzen (based on TrelisResearch/nanochat)
# Fork: https://github.com/originalzen/nanochat
# Upstream: https://github.com/karpathy/nanochat
#
# This script automatically configures the RunPod environment for training nanochat.
# It clones the repository, installs dependencies, and sets up environment variables.
#
# Required RunPod Secrets (set in RunPod Console → Secrets):
#   - HF_TOKEN: HuggingFace token with write permissions
#   - WANDB_API_KEY: Weights & Biases API key
#
# Optional RunPod Secrets (for customization):
#   - GIT_USERNAME: GitHub username (defaults to 'originalzen')
#   - GIT_USER_NAME: Your full name for git commits
#   - GIT_USER_EMAIL: Your email for git commits
#   - GITHUB_PAT: GitHub Personal Access Token (only for private forks)
#
# To use with YOUR fork:
#   1. Fork https://github.com/originalzen/nanochat
#   2. Set GIT_USERNAME to your GitHub username in RunPod Secrets
#   3. Deploy RunPod pod with this template
#

bash -lc '
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# 0. Environment Variables
# ──────────────────────────────────────────────────────────────────────────────

export PIP_ROOT_USER_ACTION=ignore

# HuggingFace token (required for training data download)
export HF_TOKEN="${HF_TOKEN:-}"
export HUGGING_FACE_HUB_TOKEN="${HF_TOKEN:-}"  # Alias for compatibility

# Weights & Biases (recommended for training monitoring)
export WANDB_API_KEY="${WANDB_API_KEY:-}"

# Git configuration
GIT_USERNAME="${GIT_USERNAME:-originalzen}"  # Default to originalzen, override in RunPod Secrets
GIT_USER_NAME="${GIT_USER_NAME:-}"           # For git commit author name
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"         # For git commit author email
GITHUB_PAT="${GITHUB_PAT:-}"                 # Only needed for private forks

# ──────────────────────────────────────────────────────────────────────────────
# 1. System Packages
# ──────────────────────────────────────────────────────────────────────────────

echo "==> Installing system dependencies..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  git nano screen vim \
  ninja-build build-essential \
  python3-dev python3-venv \
  libnuma1 libnuma-dev \
  pkg-config curl ca-certificates \
  wget unzip

# ──────────────────────────────────────────────────────────────────────────────
# 2. Git Identity (optional, for making commits)
# ──────────────────────────────────────────────────────────────────────────────

if [ -n "${GIT_USER_NAME}" ]; then
  git config --global user.name "$GIT_USER_NAME"
  echo "==> Git user.name set to: $GIT_USER_NAME"
fi

if [ -n "${GIT_USER_EMAIL}" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
  echo "==> Git user.email set to: $GIT_USER_EMAIL"
fi

# ──────────────────────────────────────────────────────────────────────────────
# 3. Clone Repository
# ──────────────────────────────────────────────────────────────────────────────

cd /workspace

REPO_URL="https://github.com/${GIT_USERNAME}/nanochat.git"

if [ -d nanochat/.git ]; then
  echo "==> Repository already exists, pulling latest changes..."
  git -C nanochat pull --ff-only
else
  echo "==> Cloning nanochat from ${REPO_URL}..."
  if [ -n "${GITHUB_PAT}" ]; then
    # Authenticated clone (required for private repos)
    git clone "https://${GITHUB_PAT}@github.com/${GIT_USERNAME}/nanochat.git"
  else
    # Unauthenticated clone (public repos)
    git clone "${REPO_URL}"
  fi
fi

cd nanochat

# ──────────────────────────────────────────────────────────────────────────────
# 4. Verify Critical Files (Trelis HF scripts should already be in your fork)
# ──────────────────────────────────────────────────────────────────────────────

if [ ! -f "scripts/push_to_hf.py" ] || [ ! -f "scripts/pull_from_hf.py" ]; then
  echo "WARNING: Trelis HF scripts not found!"
  echo "Your fork should include push_to_hf.py and pull_from_hf.py"
  echo "Training will work, but you won't be able to easily push to HuggingFace."
  echo "Run these commands manually after SSH:"
  echo "  curl -o scripts/push_to_hf.py https://raw.githubusercontent.com/TrelisResearch/nanochat/master/scripts/push_to_hf.py"
  echo "  curl -o scripts/pull_from_hf.py https://raw.githubusercontent.com/TrelisResearch/nanochat/master/scripts/pull_from_hf.py"
fi

# ──────────────────────────────────────────────────────────────────────────────
# 5. Environment Summary
# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo "========================================="
echo "NanoChat Environment Ready!"
echo "========================================="
echo "Repository: ${GIT_USERNAME}/nanochat"
echo "Location: /workspace/nanochat"
echo "HF_TOKEN: ${HF_TOKEN:+✅ SET}${HF_TOKEN:-❌ NOT SET}"
echo "WANDB_API_KEY: ${WANDB_API_KEY:+✅ SET}${WANDB_API_KEY:-⚪ NOT SET}"
echo "========================================="
echo ""
echo "To start training, run:"
echo "  cd /workspace/nanochat"
echo "  export WANDB_RUN=my_run_name"
echo "  screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh"
echo ""
echo "To detach from screen: Ctrl+A, then D"
echo "To reattach: screen -r speedrun"
echo "To view logs: tail -f speedrun.log"
echo "========================================="

# Continue with standard RunPod startup
exec /start.sh
'

