# nanochat

![nanochat logo](dev/nanochat.png)

> The best ChatGPT that $100 can buy.

---

## Quick Start: Train Your Own LLM in 4 Hours

**Cost:** ~$100 | **Time:** ~4 hours | **Result:** 500M parameter GPT-2 level chatbot

### Watch Tutorial (Recommended)

Follow along with this comprehensive video guide by Trelis Research:

[![Train an LLM from Scratch](https://img.youtube.com/vi/qra052AchPE/maxresdefault.jpg)](https://www.youtube.com/watch?v=qra052AchPE)

**[▶️ Train an LLM from Scratch with Karpathy's Nanochat](https://www.youtube.com/watch?v=qra052AchPE)** (29 minutes)

### Step 1: Get API Keys

1. **HuggingFace Token** (REQUIRED) - [Create token with "Write" permissions](https://huggingface.co/settings/tokens)
2. **Weights & Biases API Key** (RECOMMENDED) - [Get your API key](https://wandb.ai/authorize)

### Step 2: Deploy & Configure

**Deploy 8x H100 pod on [RunPod](https://runpod.io):**

- Select: 8x H100 SXM (or PCIe/NVL)
- Cost: ~$24/hour

**Configure RunPod Secrets:**

- `HF_TOKEN` - Your HuggingFace token (required)
- `WANDB_API_KEY` - Your W&B key (optional but recommended)
- `GIT_USERNAME` - Your GitHub username if you forked (optional, defaults to `originalzen`)

### Step 3: Start Training (3 commands)

**SSH into pod and run:**

```bash
cd /workspace
git clone https://github.com/originalzen/nanochat.git
cd nanochat
export WANDB_RUN=nanochat_d20
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

**Then:**

- Detach: `Ctrl+A`, then `D`
- Monitor: `tail -f speedrun.log`
- Wait ~4 hours (or watch training on [wandb.ai](https://wandb.ai))

**Using your own fork?** Replace `originalzen` with your GitHub username in clone command above.

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

**Verify:** Visit `https://huggingface.co/YourUsername/my-nanochat` to confirm uploads

**Note:** HuggingFace storage is FREE for public models. Back up everything - you can always delete later!

### Step 6: Terminate Pod

**After backup verified:** Terminate pod in RunPod console (billing stops immediately)

**Why backup all checkpoints?**

- **Future experiments:** Base/Mid checkpoints enable custom fine-tuning without re-training
- **Resume training:** Checkpoints include optimizer states for continuation (e.g., monthly $100 runs)
- **Research:** Compare different training stages
- **FREE storage:** No cost to keep everything on HuggingFace

---

## Fork Information

This fork integrates convenience enhancements from [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat) into the upstream [karpathy/nanochat](https://github.com/karpathy/nanochat) codebase.

**Maintained by:** [@originalzen](https://github.com/originalzen)

### What's Added

**Base:** Latest karpathy/nanochat code (all bug fixes through Dec 8, 2025)

**Enhancements from TrelisResearch:**

- `scripts/push_to_hf.py` - Upload checkpoints to HuggingFace Hub
- `scripts/pull_from_hf.py` - Download checkpoints from HuggingFace Hub
- `runpod_onstart.sh` - Automated RunPod environment setup
- `hf-transfer` + `huggingface-hub` dependencies

### Why This Fork Exists

TrelisResearch added excellent RunPod integration and HuggingFace utilities, but was missing some upstream bug fixes from Karpathy. This fork merges the best of both:

- Latest updates and bug fixes from Karpathy upstream
- Convenience scripts from TrelisResearch (RunPod automation, W&B integration, HF backup workflow)
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
├── runpod_onstart.sh             # NEW: RunPod automation
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
- [RunPod Discord](https://discord.gg/runpod) - Infrastructure help
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

**RunPod + W&B Integration & HuggingFace Utilities:**

- **Trelis Research** (Ronan K. McGovern) - RunPod template, push/pull scripts, tutorial
    - Repository: [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat)
    - [Substack Guide](https://trelis.substack.com/p/train-an-llm-from-scratch-with-karpathys)
    - [YouTube Tutorial](https://www.youtube.com/watch?v=qra052AchPE) (29 min)
    - [RunPod One-Click Template](https://console.runpod.io/deploy?template=ikas3s2cii) (affiliate)

**Fork Integration:**

- **Original Zen** (@originalzen) - Merged karpathy + TrelisResearch with bug analysis

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

- [RunPod Console](https://runpod.io/console/pods)
- [HuggingFace Hub](https://huggingface.co)
- [Weights & Biases](https://wandb.ai)

---

*fin*
