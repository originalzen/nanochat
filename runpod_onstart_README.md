# Runpod Template Startup Script for NanoChat Training

## Overview

This automated setup script is adapted from TrelisResearch/nanochat and configured for the originalzen/nanochat fork, which integrates karpathy/nanochat (latest code) with TrelisResearch enhancements (HuggingFace utilities, Runpod automation).

**Source:** <https://github.com/TrelisResearch/nanochat/blob/master/runpod_onstart.sh>
**Fork:** <https://github.com/originalzen/nanochat>
**Upstream:** <https://github.com/karpathy/nanochat>

## Usage

1. Configure Runpod Secrets (see Environment Variables section below)
2. Upload this script as a custom Runpod template startup script
3. Deploy 8x H100 pod → Repo auto-clones → Ready to train

## Reproducibility

To use with your own fork:

- Fork this repository on GitHub
- Set `GIT_USERNAME` secret in Runpod to your GitHub username
- Deploy pod with this template
- Template will clone from YOUR_USERNAME/nanochat automatically

## Environment Variables

Set these in Runpod Console → Secrets

### REQUIRED (Training will fail without these)

- **HF_TOKEN**: HuggingFace token with write permissions
  Get from: <https://huggingface.co/settings/tokens>

### RECOMMENDED (For monitoring and tracking)

- **WANDB_API_KEY**: Weights & Biases API key for training dashboards
  Get from: <https://wandb.ai/authorize>

### OPTIONAL (For customization)

- **GIT_USERNAME**: GitHub username for cloning (default: originalzen)
- **GIT_USER_NAME**: Full name for git commit author
- **GIT_USER_EMAIL**: Email address for git commit author
- **GITHUB_PAT**: Personal Access Token (only needed for private forks)

## Script Execution Flow

1. **Environment Variables Setup**: Configures HF_TOKEN, WANDB_API_KEY, and git settings
2. **System Dependencies Installation**: Installs git, build tools, Python dev packages
3. **Git Identity Configuration**: Sets up git user name and email (optional)
4. **Repository Cloning**: Clones nanochat from configured GitHub username
5. **Verify Critical Files**: Checks for HuggingFace utility scripts (push_to_hf.py, pull_from_hf.py)
6. **Environment Ready Summary**: Displays status and next steps

## Training Instructions

After the pod starts, SSH in and run:

```bash
cd /workspace/nanochat
export WANDB_RUN=my_run_name
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

### Screen Commands

- Detach from session: `Ctrl+A`, then `D`
- Reattach to session: `screen -r speedrun`
- Monitor logs: `tail -f speedrun.log`

## Troubleshooting

### Missing HuggingFace Scripts

If the warning about missing HuggingFace utility scripts appears, add them manually:

```bash
cd /workspace/nanochat
curl -o scripts/push_to_hf.py https://raw.githubusercontent.com/TrelisResearch/nanochat/master/scripts/push_to_hf.py
curl -o scripts/pull_from_hf.py https://raw.githubusercontent.com/TrelisResearch/nanochat/master/scripts/pull_from_hf.py
```

Training will complete successfully without these scripts, but you'll need to manually backup checkpoints before terminating the pod.
