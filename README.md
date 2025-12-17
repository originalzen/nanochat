# nanochat

![nanochat logo](dev/nanochat.png)

> The best ChatGPT that $100 can buy.

---

## Quick Start: Train Your Own LLM in 4 Hours

**Cost:** ~$100 | **Time:** ~4 hours | **Result:** 500M parameter GPT-2 level chatbot

### Watch Tutorial (Recommended)

Follow along with this comprehensive video guide by Trelis Research:

<a href="https://www.youtube.com/watch?v=qra052AchPE">
  <img src="https://img.youtube.com/vi/qra052AchPE/maxresdefault.jpg" alt="Train an LLM from Scratch with Karpathy's Nanochat" width="400">
</a>

**[▶️ Train an LLM from Scratch with Karpathy's Nanochat](https://www.youtube.com/watch?v=qra052AchPE)** (29 minutes)

### Step 1: Get API Keys

1. **HuggingFace Token** (REQUIRED) - [Create token with "Write" permissions](https://huggingface.co/settings/tokens)
2. **Weights & Biases API Key** (RECOMMENDED) - [Get your API key](https://wandb.ai/authorize)

### Step 2: Deploy & Configure

**Deploy 8x H100 pod on [Runpod](https://runpod.io):**

#### Quick Deploy (Recommended)

Use the pre-configured template with `runpod_onstart.sh` already set up:

**🚀 [One-Click Deploy Template](https://console.runpod.io/deploy?template=q3zrjjxw39)**

Or search for `originalzen_nanochat` in Runpod's public templates.

**Template Details:**

- **Docker Image:** `runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2204` ([Docker Hub](https://hub.docker.com/r/runpod/pytorch))
- **Size:** ~10.6 GB (download time varies by network speed - see troubleshooting below)

#### Deployment Settings

**⚠️ IMPORTANT: Network Speed Optimization**

To avoid wasting money on slow downloads (~30 min for Docker image + packages):

1. **Select "Community Cloud"** (NOT "Secure Cloud")
   - Community Cloud provides additional filtering options
   - Better availability and network speeds in most cases

2. **Filter by Internet Speed:**
   - Set to **"Extreme (1000 Mb/s or higher)"**
   - This reduces Docker image download from 60+ minutes to ~15 minutes
   - Critical for cost optimization on expensive H100 instances

3. **Region Selection:**
   - Select **"Any"** to maximize GPU availability
   - The system will assign you to the nearest available high-speed zone
   - Typical assignments: US (various states), Canada (CA), or EU zones

4. **GPU Selection:**
   - **Primary choice:** 8x H100 SXM (~$24/hour, best performance)
   - **Alternatives:** 8x H100 PCIe or NVL (similar performance)
   - Wait for all 8 GPUs to be available (don't settle for 5-6 if you can wait)

**Configure Runpod Secrets (Environment Variables):**

![Runpod Environment Variables](assets/runpod-environment-variables.png)

**Required:**

- `HF_TOKEN` - Your HuggingFace token with "Write" permissions ([get token](https://huggingface.co/settings/tokens))

**Recommended:**

- `WANDB_API_KEY` - Your W&B key for training dashboards ([get key](https://wandb.ai/authorize))

**Optional:**

- `GIT_USERNAME` - Your GitHub username if you forked (defaults to `originalzen`)
- `GIT_USER_NAME` - Full name for git commits (optional)
- `GIT_USER_EMAIL` - Email for git commits (optional)
- `GITHUB_PAT` - Personal access token (only for private forks)

**Cost Estimate:** ~$100 for complete 4-hour training run

### Step 3: Start Training

**Two deployment options:**

#### Option A: Using Pre-Configured Template (Recommended)

**If you used the one-click deploy template:**

The template automatically handles: cloning repo, installing dependencies (`screen`, `git`, etc.), setting up environment variables.

**SSH into pod and run:**

```bash
# Repository already cloned to /workspace/nanochat by template
cd /workspace/nanochat

# Set your run name for `wandb` and start training in a persistent screen session
export WANDB_RUN=nanochat_d20
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

**Note:** The video tutorial shows manual `git clone` and `apt-get install screen` commands, but these are **already done** by the template. Just set `WANDB_RUN` and launch `speedrun.sh`!

#### Option B: Manual Deployment (No Template)

**If you're deploying without the template:**

```bash
# SSH into pod and run:
cd /workspace
git clone https://github.com/originalzen/nanochat.git
cd nanochat

# Install screen for session persistence
apt-get update && apt-get install -y screen

# Set run name and start training
export WANDB_RUN=nanochat_d20
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

**Using your own fork?** Replace `originalzen` with your GitHub username in clone command.

#### Managing Your Training Session

**Screen Commands (Essential):**

```bash
# Detach from screen session (keeps training running)
# Press: Ctrl+A, then D

# Reattach to running session (reconnect after disconnect)
screen -r speedrun

# List all screen sessions
screen -ls

# Monitor training progress (live log tail)
tail -f speedrun.log

# Monitor with auto-scroll (follows output)
tail -f speedrun.log -n 100
```

**Monitoring Progress:**

- **W&B Dashboard:** [wandb.ai](https://wandb.ai) - Real-time metrics, loss curves, FLOPS (if WANDB_API_KEY set)
- **Local Logs:** `tail -f speedrun.log` - Full training output
- **Expected Duration:** ~4 hours for complete training
- **Cost Tracking:** Monitor in Runpod console (target: < $100)

**Training Phases:**

1. **Tokenizer Training** - BPE vocabulary generation
2. **Base Pre-training** - 10B tokens from FineWeb Edu
3. **Mid-training** - Chat data and tool use
4. **Supervised Fine-tuning** - Instruction following
5. **Evaluation** - MMLU, GSM8K, HumanEval benchmarks

**What to Watch For:**

- FLOPS utilization should be > 40% in first 10 minutes (confirms GPU efficiency)
- Loss should decrease steadily during training
- No CUDA out-of-memory errors (if occurs, terminate and adjust `device_batch_size`)

### Step 4: Test Your Model (5 minutes)

**After training completes:**

```bash
source .venv/bin/activate
export NANOCHAT_BASE_DIR="$HOME/.cache/nanochat"
python -m scripts.chat_web
```

Access at: `https://<your-pod-id>-8000.proxy.runpod.net`

**Test prompts:** "What is the capital of France?", "Tell me a joke", "Why is the sky blue?"

### Step 5: Backup Checkpoints (10-20 minutes)

**⚠️ CRITICAL: Backup BEFORE terminating pod!** All data is lost forever when pod terminates.

**What gets generated (total ~8GB):**

| Artifact | Size | Required For | Priority |
|----------|------|--------------|----------|
| **SFT checkpoint** | ~2GB | Chat inference | 🔴 CRITICAL |
| **Tokenizer** | ~1MB | All inference (text encoding/decoding) | 🔴 CRITICAL |
| **Report** | ~50KB | Training metrics & benchmarks | 🟡 RECOMMENDED |
| **Base checkpoint** | ~2GB | Custom fine-tuning, experiments | 🟡 RECOMMENDED |
| **Mid checkpoint** | ~2GB | Research, stage comparison | 🟡 RECOMMENDED |
| **Training logs** | ~10MB | speedrun.log (debugging, learning) | ⚪ OPTIONAL |

**Complete backup (RECOMMENDED - backs up ALL artifacts):**

```bash
source .venv/bin/activate
export NANOCHAT_BASE_DIR="$HOME/.cache/nanochat"

# Replace YourUsername/my-nanochat with your HuggingFace repo

# Critical (SFT + tokenizer + report)
python -m scripts.push_to_hf --stage sft --repo-id YourUsername/my-nanochat --path-in-repo sft/d20
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/tokenizer" --repo-id YourUsername/my-nanochat --path-in-repo tokenizer/latest
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/report" --repo-id YourUsername/my-nanochat --path-in-repo report/latest

# Optional but recommended (base + mid for future experiments)
python -m scripts.push_to_hf --stage base --repo-id YourUsername/my-nanochat --path-in-repo base/d20
python -m scripts.push_to_hf --stage mid --repo-id YourUsername/my-nanochat --path-in-repo mid/d20
```

**Minimum backup (time-constrained, ~5 minutes):**

```bash
# Just SFT + tokenizer (~2GB)
python -m scripts.push_to_hf --stage sft --repo-id YourUsername/my-nanochat --path-in-repo sft/d20
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/tokenizer" --repo-id YourUsername/my-nanochat --path-in-repo tokenizer/latest
```

**Verify HuggingFace uploads:** Visit `https://huggingface.co/YourUsername/my-nanochat` to confirm all folders exist

#### Download Training Logs (Local Backup)

**⚠️ Do NOT upload logs to HuggingFace** (may contain sensitive info like directory paths, usernames)

**Download to your local machine:**

**Option 1: SCP (Command Line)**

```bash
# On your local machine (PowerShell, WSL, or Mac/Linux terminal)
# Get SSH details from Runpod pod → Connect → SSH

# Download speedrun.log
scp -P 22 root@<pod-id>.proxy.runpod.net:/workspace/nanochat/speedrun.log ./

# Download report.md (if not uploaded to HF)
scp -P 22 root@<pod-id>.proxy.runpod.net:/workspace/nanochat/report.md ./
```

**Option 2: WinSCP (GUI, Windows)**

1. Download [WinSCP](https://winscp.net/)
2. Connect using SSH details from Runpod
   - Host: `<pod-id>.proxy.runpod.net`
   - Port: `22`
   - Username: `root`
3. Navigate to `/workspace/nanochat/`
4. Drag `speedrun.log` to your local machine

**What logs contain:**

- Full training output (loss curves, FLOPS, validation metrics)
- Tokenizer training details
- Evaluation results at each stage
- Timing information

**Security note:** Review logs before sharing publicly - they may contain:

- Directory paths (usually benign)
- Environment variable names (no values, safe)
- No API tokens (tokens are never printed to logs)

**Note:** HuggingFace storage is FREE for public models. Back up checkpoints there, logs locally!

### Step 6: Terminate Pod

**Before terminating, ensure backups complete:**

- [x] HuggingFace uploads verified (visit your HF repo)
- [x] Training logs downloaded to local machine (optional)
- [x] Report.md reviewed and saved

**Then:** Terminate pod in Runpod console → Billing stops immediately

**Why backup all checkpoints?**

- **Future experiments:** Base/Mid checkpoints enable custom fine-tuning without re-training
- **Resume training:** Checkpoints include optimizer states for continuation (e.g., monthly $100 runs)
- **Research:** Compare different training stages
- **Educational:** Logs show full training progression for learning
- **Free storage:** No cost to keep checkpoints on HuggingFace (logs stored locally)

---

## Common Deployment Issues & Solutions

### Slow Network Speeds / Long Download Times

**Problem:** Docker image (`runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2204`, ~10.6 GB) and package dependencies download taking much longer than expected.

**Root Cause:** Assignment to distant availability zones or low-bandwidth nodes during peak traffic hours (e.g., Iceland EUR-IS-3 when you're in US).

**Solution:**

Select the correct cloud type and filters to ensure high-speed network assignment:

![Runpod Cloud Filters](assets/runpod-cloud-filters.png)

1. **Use Community Cloud** (not Secure Cloud) - provides Internet Speed filtering
2. **Filter by "Extreme (1000 Mb/s or higher)"** bandwidth
3. **Select "Any" region** for maximum availability
4. **Wait for all 8 GPUs** to be available rather than accepting partial node

**Expected Performance:**

- ✅ Good: ~15 minutes for Docker image + packages (1000 Mb/s+)
- ❌ Bad: 60+ minutes (slow zones like some EU locations from US)

**Cost Impact:** Slow downloads can waste over $30 in compute time before training even starts!

### Missing Environment Variables

**Problem:** Training fails with HuggingFace authentication errors.

**Solution:**

- Verify `HF_TOKEN` is set in Runpod Secrets (NOT plain environment variables)
- Token must have "Write" permissions: <https://huggingface.co/settings/tokens>
- After setting, restart Pod for Secrets to take effect

### Screen Session Lost After Disconnect

**Problem:** SSH disconnected and can't see training output.

**Solution:**

```bash
# Reconnect to your running session
screen -r speedrun

# If that fails, list all sessions
screen -ls

# Then reconnect to specific session
screen -r <session-id>
```

The template uses `-L -Logfile speedrun.log` which saves everything to file, so even if screen is lost, you can review `speedrun.log`.

### Out of Memory Errors

**Problem:** CUDA out of memory during training.

**Solution:**

Edit training scripts to reduce `--device_batch_size`:

```bash
# In speedrun.sh, modify the torchrun commands:
# Change --device_batch_size=32 to 16, 8, 4, or 2
# Example:
torchrun --standalone --nproc_per_node=8 -m scripts.base_train -- --device_batch_size=16
```

Scripts automatically compensate with gradient accumulation, so final results are identical.

---

## Fork Information

This fork integrates convenience enhancements from [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat) into the upstream [karpathy/nanochat](https://github.com/karpathy/nanochat) codebase.

**Maintained by:** [@originalzen](https://github.com/originalzen)

### What's Added

**Base:** Latest karpathy/nanochat code (all bug fixes through Dec 8, 2025)

**Enhancements from TrelisResearch:**

- `scripts/push_to_hf.py` - Upload checkpoints to HuggingFace Hub
- `scripts/pull_from_hf.py` - Download checkpoints from HuggingFace Hub
- `runpod_onstart.sh` - Automated Runpod environment setup
- `hf-transfer` + `huggingface-hub` dependencies

### Why This Fork Exists

TrelisResearch added excellent Runpod integration and HuggingFace utilities, but was missing some upstream bug fixes from Karpathy. This fork merges the best of both:

- Latest updates and bug fixes from Karpathy upstream
- Convenience scripts from TrelisResearch (Runpod automation, W&B integration, HF backup workflow)
- Regular upstream sync to stay current

This fork also serves as a learning tool for git workflows, ML/LLM training, and experimentation. Thanks to Andrej Karpathy for making nanochat accessible to everyone, and to Ronan K. McGovern at Trelis Research for the tutorial and scripts.

---

## About nanochat

This repo is a full-stack implementation of an LLM like ChatGPT in a single, clean, minimal, hackable, dependency-lite codebase. nanochat is designed to run on a single 8x H100 node via scripts like [speedrun.sh](speedrun.sh), running the entire pipeline start to end: tokenization, pretraining, finetuning, evaluation, inference, and web serving. nanochat will become the capstone project of the course **LLM101n** being developed by [Eureka Labs](https://eurekalabs.ai).

**Talk to it:** You can try [nanochat d32](https://github.com/karpathy/nanochat/discussions/8) hosted at [nanochat.karpathy.ai](https://nanochat.karpathy.ai/). This 1.9B parameter model was trained for ~$800 (33 hours on 8x H100). While it outperforms GPT-2, it falls short of modern LLMs. These micro models make mistakes, hallucinate, and act childlike - but they're fully yours to configure, tweak, and hack.

---

## Training Results

Expected metrics for speedrun (d20 model, ~500M parameters):

| Metric | BASE | MID | SFT |
|--------|------|-----|-----|
| CORE | ~0.22 | - | - |
| ARC-Easy | - | ~0.36 | ~0.39 |
| GSM8K | - | ~0.03 | ~0.05 |
| HumanEval | - | ~0.07 | ~0.09 |
| MMLU | - | ~0.31 | ~0.32 |

**Training time:** ~3h 47m | View full report: `cat report.md` after training

See Karpathy's walkthrough: [Introducing nanochat](https://github.com/karpathy/nanochat/discussions/1)

---

## Advanced Usage

### Download Pre-Trained Checkpoints

Skip training and use existing checkpoints:

```bash
source .venv/bin/activate
export NANOCHAT_BASE_DIR="$HOME/.cache/nanochat"

# Download SFT model + tokenizer
python -m scripts.pull_from_hf --repo-id YourUsername/nanochat-d20 \
  --repo-path sft/d20 --stage sft --target-tag d20
python -m scripts.pull_from_hf --repo-id YourUsername/nanochat-d20 \
  --repo-path tokenizer/latest --dest-dir "$NANOCHAT_BASE_DIR/tokenizer"

# Run chat interface
python -m scripts.chat_web
```

### Train Bigger Models

**~$300 tier (d26, 12 hours):** Slightly outperforms GPT-2

```bash
# In speedrun.sh, modify:
python -m nanochat.dataset -n 450 &  # More data
torchrun --standalone --nproc_per_node=8 -m scripts.base_train -- --depth=26 --device_batch_size=16
torchrun --standalone --nproc_per_node=8 -m scripts.mid_train -- --device_batch_size=16
```

**~$1000 tier (d32, 41 hours):** 1.9B parameters (like demo at nanochat.karpathy.ai)

### GPU Options & Memory Management

**GPU recommendations:**

- **Best:** 8x H100 SXM (~$24/hr, optimal interconnect)
- **Alternative:** 8x A100 80GB (slower, may cost more overall)
- **Budget:** Single GPU (8x slower, but same results via gradient accumulation)

**Memory management:**

- GPUs with <80GB VRAM: Reduce `--device_batch_size` from `32` to `16`, `8`, `4`, or `2`
- Scripts automatically compensate with gradient accumulation

**CPU/MPS support:** For testing on Macbook/CPU, see [dev/runcpu.sh](dev/runcpu.sh)

### Customization

**Infuse personality:**

- [Guide: infusing identity to your nanochat](https://github.com/karpathy/nanochat/discussions/139)
- Generate synthetic conversations, mix into mid-training and SFT

**Add new abilities:**

- [Guide: counting r in strawberry](https://github.com/karpathy/nanochat/discussions/164)
- Create custom tasks, extend evaluation framework

---

## Fork & Sync

### Fork This Repository

1. Click "Fork" on GitHub
2. Clone: `git clone https://github.com/YourUsername/nanochat.git`
3. (Optional) Update `runpod_onstart.sh` default `GIT_USERNAME` to yours
4. Deploy and train!

### Stay Synced with Upstream

This fork regularly pulls updates from [karpathy/nanochat](https://github.com/karpathy/nanochat):

```bash
git remote add upstream https://github.com/karpathy/nanochat.git
git fetch upstream
git merge upstream/master
git push origin master
```

**Last synced:** December 10, 2025 (commit `d575940`)

**Recent upstream changes:**

- Checkpoint race condition fix (multi-GPU stability)
- Multi-epoch dataloader resume improvements
- SpellingBee random seed collision fix
- Iterator pattern updates, KV cache enhancements

---

## File Structure

```
.
├── scripts/
│   ├── push_to_hf.py             # NEW: Upload to HuggingFace
│   ├── pull_from_hf.py           # NEW: Download from HuggingFace
│   ├── base_train.py             # Base model training
│   ├── mid_train.py              # Mid-training (chat data)
│   ├── chat_sft.py               # Supervised fine-tuning
│   └── chat_web.py               # Web interface
├── runpod_onstart.sh             # NEW: Runpod automation
├── nanochat/
│   ├── gpt.py                    # GPT Transformer
│   ├── tokenizer.py              # BPE tokenizer
│   └── engine.py                 # Inference with KV cache
├── tasks/                        # Evaluation (MMLU, GSM8K, etc.)
├── rustbpe/                      # Rust BPE tokenizer trainer
├── speedrun.sh                   # Train ~$100 nanochat (d20)
├── run1000.sh                    # Train ~$800 nanochat (d32)
└── pyproject.toml                # Dependencies
```

See [karpathy/nanochat](https://github.com/karpathy/nanochat#file-structure) for complete descriptions.

---

## Tests

```bash
python -m pytest tests/test_rustbpe.py -v -s
```

---

## Questions & Community

**Ask questions:**

- [DeepWiki](https://deepwiki.com/karpathy/nanochat) - AI-powered code Q&A
- [karpathy/nanochat Discussions](https://github.com/karpathy/nanochat/discussions) - Main community
- [Runpod Discord](https://discord.gg/runpod) - Infrastructure help
- [HuggingFace Forums](https://discuss.huggingface.co) - Model sharing

---

## Contributing

**To this fork:**

- Open issues for deployment guides or fork-specific features
- Submit PRs for enhancements

**To upstream (karpathy/nanochat):**

- Report bugs or request features at [karpathy/nanochat](https://github.com/karpathy/nanochat)
- This fork regularly pulls upstream changes

**LLM Policy (Disclosure):**  
When submitting PRs, declare any parts with substantial LLM contribution you haven't fully verified.  
*This fork is developed with LLM assistance.*

---

## Credits & Attribution

**Core Implementation:**

- **Andrej Karpathy** - Original design, implementation, ongoing development
    - Repository: [karpathy/nanochat](https://github.com/karpathy/nanochat)
    - Course: [LLM101n](https://github.com/karpathy/LLM101n) (upcoming from Eureka Labs)

**Runpod + W&B Integration & HuggingFace Utilities:**

- **Trelis Research** (Ronan K. McGovern) - Runpod template concept/adaptation, push/pull scripts, tutorial
    - Repository: [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat)
    - [Substack Guide](https://trelis.substack.com/p/train-an-llm-from-scratch-with-karpathys)
    - [YouTube Tutorial](https://www.youtube.com/watch?v=qra052AchPE) (29 min)
    - [Trelis Runpod Template](https://console.runpod.io/deploy?template=ikas3s2cii) (original, affiliate link)

**Fork Integration:**

- **originalzen** (@originalzen) - Merged karpathy + TrelisResearch with deployment optimizations
    - Repository: [originalzen/nanochat](https://github.com/originalzen/nanochat)
    - [originalzen Runpod Template](https://console.runpod.io/deploy?template=q3zrjjxw39)

### Acknowledgements (from upstream)

- Name derives from [nanoGPT](https://github.com/karpathy/nanoGPT)
- Inspired by [modded-nanoGPT](https://github.com/KellerJordan/modded-nanogpt)
- Thank you to [HuggingFace](https://huggingface.co/) for fineweb and smoltalk
- Thank you [Lambda](https://lambda.ai/service/gpu-cloud) for compute
- Thank you to Alec Radford for guidance
- Thank you to [@svlandeg](https://github.com/svlandeg) for repo management

---

## Citation

```bibtex
@misc{nanochat,
  author = {Andrej Karpathy},
  title = {nanochat: The best ChatGPT that $100 can buy},
  year = {2025},
  publisher = {GitHub},
  url = {https://github.com/karpathy/nanochat}
}
```

---

## License

MIT (same as upstream)

---

## Links

**Repositories:**

- **This Fork:** [originalzen/nanochat](https://github.com/originalzen/nanochat) ⭐
- **Upstream:** [karpathy/nanochat](https://github.com/karpathy/nanochat)
- **Reference:** [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat)

**Resources:**

- [Trelis Video](https://www.youtube.com/watch?v=qra052AchPE) - 29 min tutorial
- [Karpathy Discussions](https://github.com/karpathy/nanochat/discussions)
- [LLM101n Course](https://github.com/karpathy/LLM101n) - upcoming

**Tools:**

- [Runpod Console](https://runpod.io/console/pods)
- [Runpod Template: originalzen_nanochat](https://console.runpod.io/deploy?template=q3zrjjxw39) - One-click deploy
- [HuggingFace Hub](https://huggingface.co)
- [Weights & Biases](https://wandb.ai)

---

## Listen to More Generalized Discussion with Andrej Karpathy

<a href="https://www.youtube.com/watch?v=cdiD-9MMpb0">
  <img src="https://img.youtube.com/vi/cdiD-9MMpb0/maxresdefault.jpg" alt="Andrej Karpathy: Tesla AI, Self-Driving, Optimus, Aliens, and AGI | Lex Fridman Podcast #333" width="400">
</a>

**[▶️ Andrej Karpathy: Tesla AI, Self-Driving, Optimus, Aliens, and AGI | Lex Fridman Podcast #333](https://www.youtube.com/watch?v=cdiD-9MMpb0)** (3 hours, 29 minutes)

---

*fin*
