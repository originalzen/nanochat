#!/bin/bash
#
# Runpod Template Startup Script for NanoChat Training
#
# This automated setup script is adapted from TrelisResearch/nanochat and configured
# for the originalzen/nanochat fork, which integrates karpathy/nanochat (latest code)
# with TrelisResearch enhancements (HuggingFace utilities, Runpod automation).
#
# Source: https://github.com/TrelisResearch/nanochat/blob/master/runpod_onstart.sh
# Fork: https://github.com/originalzen/nanochat
# Upstream: https://github.com/karpathy/nanochat
#
# USAGE:
#   1. Configure Runpod Secrets (see Environment Variables section below)
#   2. Upload this script as a custom Runpod template startup script
#   3. Deploy 8x H100 pod → Repo auto-clones → Ready to train
#
# REPRODUCIBILITY:
#   To use with your own fork:
#   - Fork this repository on GitHub
#   - Set GIT_USERNAME secret in Runpod to your GitHub username
#   - Deploy pod with this template
#   - Template will clone from YOUR_USERNAME/nanochat automatically
#
# ──────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT VARIABLES (Set in Runpod Console → Secrets)
# ──────────────────────────────────────────────────────────────────────────────
#
# REQUIRED (Training will fail without these):
#   HF_TOKEN              HuggingFace token with write permissions
#                         Get from: https://huggingface.co/settings/tokens
#
# RECOMMENDED (For monitoring and tracking):
#   WANDB_API_KEY         Weights & Biases API key for training dashboards
#                         Get from: https://wandb.ai/authorize
#
# OPTIONAL (For customization):
#   GIT_USERNAME          GitHub username for cloning (default: originalzen)
#   GIT_USER_NAME         Full name for git commit author
#   GIT_USER_EMAIL        Email address for git commit author
#   GITHUB_PAT            Personal Access Token (only needed for private forks)
#
# ──────────────────────────────────────────────────────────────────────────────

bash -lc '
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# 0. Environment Variables Setup
# ──────────────────────────────────────────────────────────────────────────────

export PIP_ROOT_USER_ACTION=ignore

# HuggingFace token (required for dataset download and checkpoint upload)
export HF_TOKEN="${HF_TOKEN:-}"
export HUGGING_FACE_HUB_TOKEN="${HF_TOKEN:-}"  # Alias for compatibility

# Weights & Biases (recommended for real-time training monitoring)
export WANDB_API_KEY="${WANDB_API_KEY:-}"

# Git configuration for repository cloning and commits
GIT_USERNAME="${GIT_USERNAME:-originalzen}"    # GitHub username (defaults to originalzen)
GIT_USER_NAME="${GIT_USER_NAME:-}"             # Git commit author name (optional)
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"           # Git commit author email (optional)
GITHUB_PAT="${GITHUB_PAT:-}"                   # Personal Access Token (only for private forks)

# ──────────────────────────────────────────────────────────────────────────────
# 1. System Dependencies Installation
# ──────────────────────────────────────────────────────────────────────────────

echo "==> Installing system dependencies..."
# Using -q (not -qq) option to suppress progress bars while preserving package names and errors for debugging
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  git nano screen vim \
  ninja-build build-essential \
  python3-dev python3-venv \
  libnuma1 libnuma-dev \
  pkg-config curl ca-certificates \
  wget unzip

# ──────────────────────────────────────────────────────────────────────────────
# 2. Git Identity Configuration (Optional)
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
# 3. Repository Cloning
# ──────────────────────────────────────────────────────────────────────────────

cd /workspace

REPO_URL="https://github.com/${GIT_USERNAME}/nanochat.git"

if [ -d nanochat/.git ]; then
  echo "==> Repository already exists, pulling latest changes..."
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

# ──────────────────────────────────────────────────────────────────────────────
# 4. Verify Critical Files (HuggingFace Scripts from TrelisResearch)
# ──────────────────────────────────────────────────────────────────────────────

if [ ! -f "scripts/push_to_hf.py" ] || [ ! -f "scripts/pull_from_hf.py" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "WARNING: HuggingFace utility scripts not found in repository!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Expected files: scripts/push_to_hf.py, scripts/pull_from_hf.py"
  echo ""
  echo "These scripts enable checkpoint backup to HuggingFace Hub after training."
  echo "Training will complete successfully, but you will need to manually backup"
  echo "checkpoints before terminating the pod."
  echo ""
  echo "To add these scripts manually after SSH:"
  echo "  cd /workspace/nanochat"
  echo "  curl -o scripts/push_to_hf.py https://raw.githubusercontent.com/TrelisResearch/nanochat/master/scripts/push_to_hf.py"
  echo "  curl -o scripts/pull_from_hf.py https://raw.githubusercontent.com/TrelisResearch/nanochat/master/scripts/pull_from_hf.py"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# ──────────────────────────────────────────────────────────────────────────────
# 5. Environment Ready Summary
# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NanoChat Environment Ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Repository: ${GIT_USERNAME}/nanochat"
echo "  Location: /workspace/nanochat"
echo "  HF_TOKEN: ${HF_TOKEN:+✅ SET}${HF_TOKEN:-❌ NOT SET (REQUIRED)}"
echo "  WANDB_API_KEY: ${WANDB_API_KEY:+✅ SET}${WANDB_API_KEY:-⚪ NOT SET (OPTIONAL)}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To start training (~4 hours, ~\$100):"
echo ""
echo "  cd /workspace/nanochat"
echo "  export WANDB_RUN=my_run_name"
echo "  screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh"
echo ""
echo "Screen commands:"
echo "  - Detach from session: Ctrl+A, then D"
echo "  - Reattach to session: screen -r speedrun"
echo "  - Monitor logs: tail -f speedrun.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Continue with standard Runpod startup
exec /start.sh
'
