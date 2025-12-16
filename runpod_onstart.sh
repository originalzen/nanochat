#!/bin/bash

bash -lc '
set -euo pipefail

# ═══════════════════════════════
# 0. Environment Variables Setup
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
# 1. System Dependencies Installation
# ════════════════════════════════════

echo "==> Installing system dependencies..."
# Using -q (not -qq) option to suppress progress bars while preserving package names and errors for debugging
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  git nano screen vim ninja-build build-essential \
  python3-dev python3-venv libnuma1 libnuma-dev \
  pkg-config curl ca-certificates wget unzip

# ═════════════════════════════════════════
# 2. Git Identity Configuration (Optional)
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
# 3. Repository Cloning
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

# ═══════════════════════════════
# 4. Verify HuggingFace Scripts
# ═══════════════════════════════

if [ ! -f "scripts/push_to_hf.py" ] || [ ! -f "scripts/pull_from_hf.py" ]; then
  echo "══════════════════════════════════════════"
  echo "⚠️  WARNING: HF utility scripts missing!"
  echo "══════════════════════════════════════════"
  echo "Expected: scripts/push_to_hf.py, scripts/pull_from_hf.py"
  echo "Training will work but manual checkpoint backup required."
  echo ""
  echo "To add manually after SSH:"
  echo "  cd /workspace/nanochat && curl -o scripts/push_to_hf.py https://raw.githubusercontent.com/TrelisResearch/nanochat/master/scripts/push_to_hf.py"
  echo "══════════════════════════════════════════"
fi

# ══════════════════════
# 5. Environment Ready
# ══════════════════════

echo ""
echo "═════════════════════════════════"
echo "  🚀 NanoChat Environment Ready"
echo "═════════════════════════════════"
echo "  Repository: ${GIT_USERNAME}/nanochat"
echo "  Location: /workspace/nanochat"
echo "  HF_TOKEN: ${HF_TOKEN:+✅ SET}${HF_TOKEN:-❌ NOT SET (REQUIRED)}"
echo "  WANDB_API_KEY: ${WANDB_API_KEY:+✅ SET}${WANDB_API_KEY:-⚪ NOT SET (OPTIONAL)}"
echo ""
echo "Start training (~4h, ~\$100):"
echo "  cd /workspace/nanochat"
echo "  export WANDB_RUN=my_run_name"
echo "  screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh"
echo ""
echo "Screen: Ctrl+A, then D (detach) | screen -r speedrun (reattach) | tail -f speedrun.log (monitor)"
echo "══════════════════════════════════════════"

exec /start.sh
'
