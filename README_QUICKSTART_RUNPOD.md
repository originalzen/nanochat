# Runpod Deployment Quickstart: Train Your Own LLM in 4 Hours

**Cost:** ~$100 | **Time:** ~4 hours | **Result:** 561M parameter GPT-2 level chatbot

> **Complete end-to-end guide** for deploying and training nanochat on Runpod cloud GPUs. For general information about nanochat, advanced usage, and customization, see the [main README](README.md).

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Video Tutorial](#video-tutorial)
- [Step 1: Get API Keys](#step-1-get-api-keys)
- [Step 2: Configure SSH Access](#step-2-configure-ssh-access)
- [Step 3: Configure Runpod Secrets](#step-3-configure-runpod-secrets)
- [Step 4: Deploy Pod with Optimal Settings](#step-4-deploy-pod-with-optimal-settings)
- [Step 5: Start Training](#step-5-start-training)
- [Step 6: Monitor Training Progress](#step-6-monitor-training-progress)
- [Step 7: Test Your Model](#step-7-test-your-model)
- [Step 8: Backup Checkpoints](#step-8-backup-checkpoints)
- [Step 9: Terminate Pod](#step-9-terminate-pod)
- [Troubleshooting](#troubleshooting)
- [Advanced Runpod Configuration](#advanced-runpod-configuration)

---

## Prerequisites

Before starting, ensure you have:

- [ ] Runpod account ([sign up here](https://runpod.io))
- [ ] Credit card or credits in Runpod account (~$100 minimum)
- [ ] HuggingFace account for API token
- [ ] (Optional) Weights & Biases account for monitoring

**Estimated total time:** 4-5 hours including setup and training

---

## Video Tutorial

Follow along with this comprehensive video guide by Trelis Research:

<a href="https://www.youtube.com/watch?v=qra052AchPE">
  <img src="https://img.youtube.com/vi/qra052AchPE/maxresdefault.jpg" alt="Train an LLM from Scratch with Karpathy's Nanochat" width="400">
</a>

**[▶️ Train an LLM from Scratch with Karpathy's Nanochat](https://www.youtube.com/watch?v=qra052AchPE)** (29 minutes)

**Note:** This guide includes improvements and updates beyond the video tutorial.

---

## Step 1: Get API Keys

### HuggingFace Token (REQUIRED)

1. Go to [HuggingFace Settings → Tokens](https://huggingface.co/settings/tokens)
2. Click "New token"
3. Name: `nanochat-training`
4. Type: **Write** (required for uploading checkpoints)
5. Copy token and save securely

### Weights & Biases API Key (RECOMMENDED)

1. Go to [W&B Authorize](https://wandb.ai/authorize)
2. Copy your API key
3. Provides real-time training dashboards and metrics visualization

---

## Step 2: Configure SSH Access

**Purpose:** Enable SSH access from your local machine to the Runpod pod terminal.

### Generate SSH Key Pair (if you don't have one)

```bash
# Generate ed25519 key (recommended)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or generate RSA key (alternative)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### Add Public Key to Runpod

1. Go to **Runpod Console** → **Settings** → **SSH Public Keys**
2. Click **Add SSH Key**
3. Paste your public key content from:
   - `~/.ssh/id_ed25519.pub` (ed25519) or
   - `~/.ssh/id_rsa.pub` (RSA)
4. Give it a descriptive name (e.g., "My Laptop")
5. Save

**Alternative:** Use Runpod's web-based terminal (no SSH setup required, but less convenient)

---

## Step 3: Configure Runpod Secrets

**Purpose:** Securely store API tokens as encrypted environment variables.

![Runpod Secrets Configuration](assets/runpod-00-secrets.png)

### Navigate to Secrets

Go to **Runpod Console** → **Secrets** → **Create Secret**

### Required Secrets

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `HF_TOKEN` | Your HuggingFace write token | Download datasets, upload checkpoints |

### Recommended Secrets

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `WANDB_API_KEY` | Your W&B API key | Real-time training dashboards |

### Optional Secrets

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `GITHUB_PAT` | Personal access token | Only for private forks |
| `GIT_USERNAME` | Your GitHub username | If you forked the repo (defaults to `originalzen`) |
| `GIT_USER_NAME` | Your full name | Git commit author name |
| `GIT_USER_EMAIL` | Your email | Git commit author email |

**Security Note:** Never commit these values to git or share them publicly.

---

## Step 4: Deploy Pod with Optimal Settings

### Quick Deploy (Recommended)

**🚀 [One-Click Deploy Template](https://console.runpod.io/deploy?template=q3zrjjxw39)**

Or search for `originalzen_nanochat` in Runpod's public templates.

### Template Specifications

- **Docker Image:** `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`
    - [Runpod Template Reference](https://console.runpod.io/hub/template/runpod-pytorch-2-8-0?id=runpod-torch-v280)
    - [Docker Hub Details](https://hub.docker.com/layers/runpod/pytorch/1.0.2-cu1281-torch280-ubuntu2404/images/sha256-4d1721e62b56d345c83b4fd6090664be6daf9312caab5b2e76f23d8231941851)
- **PyTorch:** 2.8.0 | **CUDA:** 12.8.1 | **Ubuntu:** 24.04
- **Image Size:** 9.8 GB
- **Includes:** Automated setup script (`runpod_onstart.sh`)

### Deployment Configuration Walkthrough

#### 4.1: Select Cloud Type & Filters

![Runpod Cloud Filters](assets/runpod-01-cloud-filters.png)

**Cloud Selection:**

- **Community Cloud** (recommended for cost optimization)
    - Provides Internet Speed filtering (critical for fast downloads)
    - Might lower cost with faster bandwidth at the expense of reliability guarantees
    - **Trade-off:** Managed by external hosts, not directly controlled by Runpod
    - **Best for:** Short-term training runs (~4 hours), cost-sensitive workloads

- **Secure Cloud** (alternative for stability)
    - Fully managed by Runpod with greater stability
    - Better support and quicker issue resolution
    - Security & compliance filters available
    - No Internet Speed filtering available
    - **Best for:** Mission-critical or long-running workloads

**Recommended Filter Settings (Community Cloud):**

1. **Internet Speed:** Select **"Extreme - 1000 Mb/s or higher"**
   - Avoids bandwidth bottlenecks (prevents 60+ minute downloads)
   - Critical for cost optimization on $20+/hour instances

2. **Region:** Select **"Any"**
   - Maximizes GPU availability

3. **Additional Filters → CUDA Version:** Select **ONLY 12.8** ✅
   - **Why:** Docker image requires CUDA 12.8.1, needs matching host drivers
   - Older or newer versions may cause initialization failures
   - **Rule:** Docker CUDA version should match host driver version

4. **Additional Filters → Disk Type:** Select **NVME** (if available)
   - Significantly faster package installation/extraction
   - Reduces setup time vs SSD

#### 4.2: Select GPU Configuration

![H100 Availability](assets/runpod-02-h100-sxm-pcie-nvl-availability.png)

**Availability Note:** With strict filters (Community + Extreme + CUDA 12.8 + NVME):

- H100 SXM/PCIe may be unavailable
- H100 NVL may be your only option

**Recommended Selection:**

- **8x H100 NVL** ($20.72/hour)
- **8 GPUs required** for optimal training speed (~4 hours for d20 model)

**Alternative:** If you need SXM availability, try Secure Cloud (accept trade-offs).

#### 4.3: Configure Template Settings

![Deployment Configuration](assets/runpod-03-deployment-config-template-docker-image-gpu-count.png)

**Pod Template:** `originalzen_nanochat` (should be preselected from template link)

**GPU Count:** Select **8** GPUs

**Inspect Template (Optional):**

- Click **"Edit"** to view template contents
- **Container Start Command:** Equivalent to `runpod_onstart.sh`
- **Environment Variables:** Shows Secret injection (e.g., `{{ RUNPOD_SECRET_HF_TOKEN }}`)
- **Ports:** 8888, 6006, 8000 (Jupyter/TensorBoard/Web UI)
- **Volume Mount:** `/workspace` (code clone location)

![Template Environment Variables](assets/runpod-05-template-env-variables-secrets-ports-workspace-mount-path.png)

**Optional Overrides:**

- Add environment variables (e.g., `GIT_USER_NAME`, `GIT_USER_EMAIL`)
- Modify disk sizes
- Change exposed ports

#### 4.4: Review & Deploy

![Review Specs](assets/runpod-06-review-specs-before-deployment.png)

**Pre-Deployment Checklist:**

- ✅ Secrets configured (HF_TOKEN, WANDB_API_KEY)
- ✅ SSH key added to Runpod account
- ✅ CUDA 12.8 filter applied
- ✅ Community Cloud + Extreme speed selected (or your preferred filters)
- ✅ 8 GPUs selected
- ✅ Template: `originalzen_nanochat`

**Cost Estimate:** ~$85-110 for complete 4-hour training (varies by GPU type and region)

**Click "Deploy On-Demand"** → Pod will start initializing (~2-5 minutes)

---

## Step 5: Start Training

### Wait for Pod Initialization

1. Pod status shows **"Running"**
2. Container start command executes (clones repo, installs dependencies)
3. Wait ~5-15 minutes for setup to complete (depends on network speed)

### SSH into Pod

**Get SSH connection details:**

1. Click on your pod in Runpod console
2. Click **"Connect"** → **"SSH"**
3. Copy the SSH command (e.g., `ssh root@<pod-id>.proxy.runpod.net -p 22`)

**Connect from your terminal:**

```bash
ssh root@<pod-id>.proxy.runpod.net -p 22
```

### Launch Training

```bash
# Repository already cloned to /workspace/nanochat by template
cd /workspace/nanochat

# Set your W&B run name
export WANDB_RUN=nanochat_d20

# Start training in persistent screen session
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

**What happens next:**

1. Virtual environment created
2. Dependencies installed (PyTorch, transformers, etc.)
3. Tokenizer trained (~1 minute)
4. Base model pre-trained (~3.5 hours)
5. Mid-training (~10 minutes)
6. Supervised fine-tuning (~5 minutes)
7. Evaluation (~5 minutes)

**Note:** The video tutorial shows manual `git clone` and `apt-get install screen`, but these are **already done** by the template. Just launch training!

---

## Step 6: Monitor Training Progress

### Screen Session Management

**Detach from screen** (keeps training running in background):

```bash
# Press: Ctrl+A, then D
```

**Reattach to screen** (reconnect to see training output):

```bash
screen -r speedrun
```

**List all screen sessions:**

```bash
screen -ls
```

### Monitor Training Logs

**Real-time log monitoring:**

```bash
# From pod terminal (while detached from screen)
tail -f speedrun.log

# With line count
tail -f speedrun.log -n 100
```

### Monitoring Dashboards

- **Weights & Biases:** [wandb.ai](https://wandb.ai) (if WANDB_API_KEY set)
    - Real-time loss curves
    - FLOPS utilization metrics
    - Training progress visualization

- **Runpod Console:** Monitor costs and GPU utilization

### Training Phases & Timeline

| Phase | Duration | Purpose |
|-------|----------|---------|
| Tokenizer Training | ~1 min | BPE vocabulary generation |
| Base Pre-training | ~3.5 hours | 10B tokens from FineWeb Edu |
| Mid-training | ~10 min | Chat data and tool use |
| Supervised Fine-tuning | ~5 min | Instruction following |
| Evaluation | ~5 min | MMLU, GSM8K, HumanEval benchmarks |

**Total:** ~3h 47m (may vary by GPU type)

### What to Watch For

✅ **Good signs:**

- FLOPS utilization > 40% in first 10 minutes
- Loss decreasing steadily
- No CUDA errors

❌ **Warning signs:**

- CUDA out of memory errors → reduce `device_batch_size` (see troubleshooting)
- FLOPS < 30% → potential GPU issue
- Training stuck → check logs for errors

---

## Step 7: Test Your Model

**After training completes** (screen session will show completion message):

### Activate Environment & Launch Web UI

```bash
# SSH into pod if disconnected
ssh root@<pod-id>.proxy.runpod.net -p 22

# Navigate to project
cd /workspace/nanochat

# Activate virtual environment
source .venv/bin/activate

# Set base directory
export NANOCHAT_BASE_DIR="$HOME/.cache/nanochat"

# Launch web interface
python -m scripts.chat_web
```

### Access Web Interface

**URL:** `https://<your-pod-id>-8000.proxy.runpod.net`

(Replace `<your-pod-id>` with your actual pod ID from Runpod console)

### Test Prompts

Try these example prompts to verify your model works:

- "What is the capital of France?"
- "Tell me a joke"
- "Why is the sky blue?"
- "Write a Python function to calculate fibonacci numbers"

**Expected behavior:** Model responds (may be imperfect - this is a small 561M parameter model trained for educational purposes).

---

## Step 8: Backup Checkpoints

**⚠️ CRITICAL: Backup BEFORE terminating pod!**

All data is lost forever when the pod terminates. Runpod volumes are ephemeral.

### What Gets Generated (~8GB total)

| Artifact | Size | Required For | Priority |
|----------|------|--------------|----------|
| **SFT checkpoint** | ~2GB | Chat inference | 🟢 CRITICAL |
| **Tokenizer** | ~1MB | All inference (text encoding/decoding) | 🟢 CRITICAL |
| **Report** | ~50KB | Training metrics & benchmarks | 🟡 RECOMMENDED |
| **Base checkpoint** | ~2GB | Custom fine-tuning, experiments | 🟡 RECOMMENDED |
| **Mid checkpoint** | ~2GB | Research, stage comparison | 🟡 RECOMMENDED |
| **Training logs** | ~10MB | speedrun.log (debugging, learning) | ⚪ OPTIONAL |

### Complete Backup (RECOMMENDED)

Backs up all artifacts to HuggingFace Hub (FREE storage for public models):

```bash
# Should already be in environment from Step 7
# If not:
cd /workspace/nanochat
source .venv/bin/activate
export NANOCHAT_BASE_DIR="$HOME/.cache/nanochat"

# Replace YourUsername/my-nanochat with your HuggingFace repo name

# Critical artifacts (SFT + tokenizer + report)
python -m scripts.push_to_hf --stage sft --repo-id YourUsername/my-nanochat --path-in-repo sft/d20
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/tokenizer" --repo-id YourUsername/my-nanochat --path-in-repo tokenizer/latest
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/report" --repo-id YourUsername/my-nanochat --path-in-repo report/latest

# Optional but recommended (base + mid for future experiments)
python -m scripts.push_to_hf --stage base --repo-id YourUsername/my-nanochat --path-in-repo base/d20
python -m scripts.push_to_hf --stage mid --repo-id YourUsername/my-nanochat --path-in-repo mid/d20
```

**Upload time:** 10-20 minutes depending on network speed

### Minimum Backup (Time-Constrained)

If you're short on time, back up only the essentials (~5 minutes):

```bash
# Just SFT + tokenizer (~2GB)
python -m scripts.push_to_hf --stage sft --repo-id YourUsername/my-nanochat --path-in-repo sft/d20
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/tokenizer" --repo-id YourUsername/my-nanochat --path-in-repo tokenizer/latest
```

### Verify HuggingFace Uploads

Visit `https://huggingface.co/YourUsername/my-nanochat` to confirm all folders exist.

### Download Training Logs (Local Backup)

**⚠️ Do NOT upload logs to HuggingFace** (may contain directory paths, usernames)

**Download to your local machine:**

**Option 1: SCP (Command Line)**

```bash
# Run on your LOCAL machine (not in pod)
# Get SSH details from Runpod: pod → Connect → SSH

# Download speedrun.log
scp -P 22 root@<pod-id>.proxy.runpod.net:/workspace/nanochat/speedrun.log ./

# Download report.md
scp -P 22 root@<pod-id>.proxy.runpod.net:/workspace/nanochat/report.md ./
```

**Option 2: WinSCP (GUI, Windows)**

1. Download [WinSCP](https://winscp.net/)
2. Connect using SSH details from Runpod
   - Host: `<pod-id>.proxy.runpod.net`
   - Port: `22`
   - Username: `root`
3. Navigate to `/workspace/nanochat/`
4. Drag `speedrun.log` and `report.md` to your local machine

**What logs contain:**

- Full training output (loss curves, FLOPS, validation)
- Tokenizer training details
- Evaluation results
- Timing information

---

## Step 9: Terminate Pod

**Before terminating, verify:**

- ✅ HuggingFace uploads completed and verified
- ✅ Training logs downloaded to local machine (optional)
- ✅ Report.md reviewed and saved

**Terminate pod:**

1. Go to Runpod Console
2. Click on your pod
3. Click **"Terminate"**
4. Confirm termination

**Billing stops immediately** upon termination.

**Why backup all checkpoints?**

- Base/Mid checkpoints enable custom fine-tuning without re-training
- Checkpoints include optimizer states for continuation
- Compare different training stages
- Educational value (shows full training progression)
- FREE HuggingFace storage for public models

---

## Troubleshooting

### Slow Network Speeds / Long Download Times

**Problem:** Docker image and package downloads taking 60+ minutes.

**Root Cause:** Some availability zones experience bandwidth bottlenecks.

**Solution:**

Apply optimal filter settings (see Step 4):

1. Use Community Cloud (enables Internet Speed filtering)
2. Filter by "Extreme (1000 Mb/s or higher)"
3. Select NVME disk type (faster extraction)
4. Select "Any" region

**Expected Performance:**

- ✅ Good: ~5 minutes for setup (1000 Mb/s+ with NVME)
- ❌ Bad: 60+ minutes (slow zones or HDD disks)

**Cost Impact:** Slow downloads waste $15-40 before training starts!

**Trade-offs:**

- **Community + Extreme filters:** Fast speeds, limited GPU availability (often only H100 NVL)
- **Secure Cloud:** Better GPU availability, risk of slow network
- **Community (no filters):** Most availability, unpredictable performance

Experiment with different filter combinations based on your priorities.

### Screen Session Lost After Disconnect

**Problem:** SSH disconnected and can't see training output.

**Solution:**

```bash
# Reconnect to running session
screen -r speedrun

# If that fails, list all sessions
screen -ls

# Then reconnect to specific session
screen -r <session-id>
```

The template uses `-L -Logfile speedrun.log`, so even if screen is lost, you can review `speedrun.log`.

### CUDA Out of Memory Errors

**Problem:** Training fails with "CUDA out of memory" error.

**Solution:**

Edit `speedrun.sh` to reduce `--device_batch_size`:

```bash
# Original (in speedrun.sh):
torchrun --standalone --nproc_per_node=8 -m scripts.base_train -- --device_batch_size=32

# Reduce to 16, 8, 4, or 2:
torchrun --standalone --nproc_per_node=8 -m scripts.base_train -- --device_batch_size=16
```

Scripts automatically compensate with gradient accumulation, so final results are identical (just slightly slower).

### HuggingFace Authentication Errors

**Problem:** Training fails with "Invalid credentials" or similar errors.

**Solution:**

1. Verify `HF_TOKEN` is set in Runpod Secrets (NOT plain environment variables)
2. Token must have "Write" permissions: <https://huggingface.co/settings/tokens>
3. After setting/changing secrets, **restart the pod** for changes to take effect

### Training Stuck or Not Starting

**Possible causes:**

1. **Still initializing:** Wait 5-15 minutes for container setup to complete
2. **Missing dependencies:** Check `/workspace/nanochat/` exists and has files
3. **Wrong directory:** Ensure you're in `/workspace/nanochat/`
4. **Syntax error:** Check you copied commands correctly

**Debug steps:**

```bash
# Check if repo was cloned
ls -la /workspace/nanochat/

# Check container start command logs
cat /var/log/start.log

# Manually run setup if needed
cd /workspace
git clone https://github.com/originalzen/nanochat.git
cd nanochat
```

---

## Advanced Runpod Configuration

### Manual Deployment (Without Template)

If you prefer not to use the template:

```bash
# After deploying a standard Runpod PyTorch pod, SSH in and run:
cd /workspace
git clone https://github.com/originalzen/nanochat.git
cd nanochat

# Install screen for session persistence
apt-get update && apt-get install -y screen

# Set environment variables
export HF_TOKEN="your_token_here"
export WANDB_API_KEY="your_key_here"
export WANDB_RUN=nanochat_d20

# Start training
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

**Using your own fork?** Replace `originalzen` with your GitHub username.

### Cost Optimization Strategies

**Monitor costs in real-time:**

- Runpod console shows cumulative cost
- Set calendar alert at 3h45m to check progress
- Hard stop at 4h15m if not done (target < $110)

**Alternative GPU options:**

- 8x A100 80GB: Slower but may be cheaper depending on availability
- Smaller models: d20 → d18 or d16 for faster/cheaper training (lower quality)

### Training on Other Cloud Providers

This guide is specific to Runpod. For AWS, Lambda Labs, or other providers, see the [main README](README.md) for general deployment guidance.

---

## Expected Training Results

For the d20 model (~561M parameters):

| Metric | BASE | MID | SFT |
|--------|------|-----|-----|
| CORE | ~0.22 | - | - |
| ARC-Easy | - | ~0.36 | ~0.39 |
| GSM8K | - | ~0.03 | ~0.05 |
| HumanEval | - | ~0.07 | ~0.09 |
| MMLU | - | ~0.31 | ~0.32 |

**Training time:** ~3h 47m | View full report: `cat report.md` in pod

See Karpathy's walkthrough: [Introducing nanochat](https://github.com/karpathy/nanochat/discussions/1)

---

## Next Steps

After successful training:

- **Advanced Usage:** See [main README](README.md) for:
    - Training bigger models (d26, d32)
    - Custom personalities and identity injection
    - GPU options and memory management
    - Evaluation framework customization

- **Deploy for Inference:** Set up your model on:
    - Local machine
    - AWS EC2
    - HuggingFace Spaces
    - Personal server

- **Community:** Join discussions at:
    - [karpathy/nanochat Discussions](https://github.com/karpathy/nanochat/discussions)
    - [Runpod Discord](https://discord.gg/runpod)
    - [DeepWiki](https://deepwiki.com/karpathy/nanochat)

---

**Questions or issues?** Open an issue at [originalzen/nanochat](https://github.com/originalzen/nanochat/issues)

**Main README:** [README.md](README.md) | **Runpod Template:** [One-Click Deploy](https://console.runpod.io/deploy?template=q3zrjjxw39)

---

*Last updated: December 2025 | Based on nanochat d20 training workflow*
