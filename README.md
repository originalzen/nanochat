# nanochat

![nanochat logo](dev/nanochat.png)

> The best ChatGPT that $100 can buy.

---

## 🚀 Quick Start

**Ready to train your own LLM?** Choose your deployment platform:

### Runpod Cloud GPUs (Recommended for Beginners)

**📘 [Complete Runpod Quickstart Guide](README_QUICKSTART_RUNPOD.md)**

**Cost:** ~$100 | **Time:** ~4 hours | **Result:** 561M parameter GPT-2 level chatbot

Comprehensive step-by-step guide with:

- Visual deployment walkthrough with screenshots
- Optimal configuration settings for cost efficiency
- Complete troubleshooting guide
- End-to-end workflow from setup to model backup

**[▶️ Video Tutorial (29 min)](https://www.youtube.com/watch?v=qra052AchPE)** | **[🚀 One-Click Deploy](https://console.runpod.io/deploy?template=q3zrjjxw39)**

### Other Cloud Providers

For AWS, Lambda Labs, or other GPU cloud providers:

- Follow general deployment steps below
- Adapt environment setup for your platform
- See [Advanced Usage](#advanced-usage) for configuration details

**Platform requirements:** 8x H100 (or 8x A100 80GB) GPUs, CUDA 12.8+, Ubuntu 22.04+

---

## Table of Contents

- **[Quick Start](#-quick-start)** - Choose your deployment platform
- **[General Deployment Requirements](#general-deployment-requirements)** - Platform-agnostic prerequisites
- **[About nanochat](#about-nanochat)** - What this project is and does
- **[Training Results](#training-results)** - Expected metrics and benchmarks
- **[Advanced Usage](#advanced-usage)** - Bigger models, customization, pre-trained checkpoints
- **[Fork & Sync](#fork--sync)** - How to fork and stay updated
- **[File Structure](#file-structure)** - Repository organization
- **[Community & Support](#questions--community)** - Where to get help
- **[Contributing](#contributing)** - How to contribute
- **[Credits](#credits--attribution)** - Acknowledgements

---

## General Deployment Requirements

**For any cloud platform:**

- **GPUs:** 8x H100 (SXM/PCIe/NVL) or 8x A100 80GB
- **CUDA:** 12.8+ (for PyTorch 2.8.0 compatibility)
- **OS:** Ubuntu 22.04+ or similar Linux distribution
- **Disk:** 300GB+ recommended (for datasets, checkpoints, logs)
- **Network:** High-speed internet (1000 Mb/s+) recommended for faster setup

**Required API keys:**

- [HuggingFace Token](https://huggingface.co/settings/tokens) with "Write" permissions (REQUIRED)
- [Weights & Biases API Key](https://wandb.ai/authorize) (RECOMMENDED for monitoring)

**Platform-specific guides:**

- **Runpod:** See [Runpod Quickstart Guide](README_QUICKSTART_RUNPOD.md)
- **AWS/Lambda Labs/Others:** Follow advanced usage instructions below

---

## About nanochat

This repo is a full-stack implementation of an LLM like ChatGPT in a single, clean, minimal, hackable, dependency-lite codebase. nanochat is designed to run on a single 8x H100 node via scripts like [speedrun.sh](speedrun.sh), running the entire pipeline start to end: tokenization, pretraining, finetuning, evaluation, inference, and web serving. nanochat will become the capstone project of the course **LLM101n** being developed by [Eureka Labs](https://eurekalabs.ai).

**Talk to it:** Try [nanochat d34](https://github.com/karpathy/nanochat/discussions/314) at [nanochat.karpathy.ai](https://nanochat.karpathy.ai/). This 2.2B parameter model cost ~$2,500 to train (100 hours on 8x H100), using [run1000.sh](run1000.sh) configured for extended training (`--target_param_data_ratio=40`) across 88 billion tokens -- double the Chinchilla-optimal duration. It beats GPT-2 but can't match frontier LLMs. These micro models hallucinate, make mistakes, and behave childishly, but they're entirely open to configure, tweak, and hack.

---

## Training Results

Expected metrics for speedrun (d20 model, ~561M parameters, ~$100 tier):

| Metric     | BASE  | MID   | SFT   |
| ---------- | ----- | ----- | ----- |
| CORE       | ~0.22 | -     | -     |
| ARC-Easy   | -     | ~0.36 | ~0.39 |
| GSM8K      | -     | ~0.03 | ~0.05 |
| HumanEval  | -     | ~0.07 | ~0.09 |
| MMLU       | -     | ~0.31 | ~0.32 |

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

**~$1000 tier (d32, 33 hours):** 1.9B parameters

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

**Identity Conversations & OpenRouter Setup:**

During mid-training, nanochat downloads `identity_conversations.jsonl` (2.3MB) to inject personality into the model. The training script automatically handles this with a robust multi-tier approach:

1. **Check cache first:** If file already exists from previous run, skip download
2. **Download from TrelisResearch GitHub:** Primary source (free, fast, reliable)
3. **Fallback to local generation:** If download fails, generate using OpenRouter API

**You don't need to do anything for standard training** - the script handles everything automatically. However, if you want to generate custom identity conversations with different personalities, you'll need to set up OpenRouter API access:

**OpenRouter Setup (only for custom generation):**

1. **Sign up for OpenRouter:** [https://openrouter.ai/](https://openrouter.ai/)
2. **Get API key:** Visit [OpenRouter Dashboard](https://openrouter.ai/keys) after signing up
3. **Create token file in repository root:**

   ```bash
   # Create file with your API key
   echo "your-api-key-here" > openroutertoken.txt
   ```

4. **Add to .gitignore (CRITICAL):**

   ```bash
   echo "openroutertoken.txt" >> .gitignore
   ```

**Generate custom identity conversations (advanced):**

```bash
# Only needed if you want custom personalities - not required for standard training!

# Activate virtual environment
source .venv/bin/activate

# Generate new identity_conversations.jsonl
PYTHONPATH=$(pwd) python dev/gen_synthetic_data.py

# The script will:
# - Use your OpenRouter API key from openroutertoken.txt
# - Generate synthetic personality conversations via LLM
# - Save to cache directory for use in next training run
```

**When you need OpenRouter API:**

- ❌ **Standard training:** NOT needed - file downloads automatically from GitHub
- ✅ **Custom personalities:** Generate different conversation styles
- ✅ **Fallback only:** If GitHub download fails (rare)

**Cost:** Typically a few cents per generation. Check [OpenRouter pricing](https://openrouter.ai/models).

**Custom generation use cases:**

- Different personality profiles (formal vs casual, technical vs general)
- Domain-specific conversation patterns
- Multilingual identity injection
- Experimental conversational styles

See [Guide: infusing identity to your nanochat](https://github.com/karpathy/nanochat/discussions/139) for detailed customization strategies.

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

---

## Fork Information

This fork integrates convenience enhancements from [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat) into the upstream [karpathy/nanochat](https://github.com/karpathy/nanochat) codebase.

**Maintained by:** [@originalzen](https://github.com/originalzen)

### What's Added

**Base:** Latest karpathy/nanochat code

**Enhancements from TrelisResearch:**

- `scripts/push_to_hf.py` - Upload checkpoints to HuggingFace Hub
- `scripts/pull_from_hf.py` - Download checkpoints from HuggingFace Hub
- `runpod_onstart.sh` - Automated Runpod Container Start Command
- `hf-transfer` + `huggingface-hub` dependencies

**Deployment Guides:**

- [Runpod Quickstart](README_QUICKSTART_RUNPOD.md) - Complete step-by-step deployment guide with visual walkthrough

### Why This Fork Exists

TrelisResearch added excellent Runpod integration and HuggingFace utilities, but was missing some upstream bug fixes from Karpathy. This fork merges the best of both:

- Latest updates and bug fixes from Karpathy upstream
- Convenience scripts from TrelisResearch (Runpod automation, W&B integration, HF backup workflow)
- Comprehensive deployment documentation with troubleshooting
- Regular upstream sync to stay current

This fork also serves as a learning tool for git workflows, ML/LLM training, and experimentation. Thanks to Andrej Karpathy for making nanochat accessible to everyone, and to Ronan K. McGovern at Trelis Research for the tutorial and scripts.

---

## File Structure

```tree
.
├── LICENSE
├── README.md
├── dev
│   ├── gen_synthetic_data.py       # Example synthetic data for identity
│   ├── generate_logo.html
│   ├── nanochat.png
│   ├── repackage_data_reference.py # Pretraining data shard generation
│   └── runcpu.sh                   # Small example of how to run on CPU/MPS
├── nanochat
│   ├── __init__.py                 # empty
│   ├── adamw.py                    # Distributed AdamW optimizer
│   ├── checkpoint_manager.py       # Save/Load model checkpoints
│   ├── common.py                   # Misc small utilities, quality of life
│   ├── configurator.py             # A superior alternative to argparse
│   ├── core_eval.py                # Evaluates base model CORE score (DCLM paper)
│   ├── dataloader.py               # Tokenizing Distributed Data Loader
│   ├── dataset.py                  # Download/read utils for pretraining data
│   ├── engine.py                   # Efficient model inference with KV Cache
│   ├── execution.py                # Allows the LLM to execute Python code as tool
│   ├── gpt.py                      # The GPT nn.Module Transformer
│   ├── logo.svg
│   ├── loss_eval.py                # Evaluate bits per byte (instead of loss)
│   ├── muon.py                     # Distributed Muon optimizer
│   ├── report.py                   # Utilities for writing the nanochat Report
│   ├── tokenizer.py                # BPE Tokenizer wrapper in style of GPT-4
│   └── ui.html                     # HTML/CSS/JS for nanochat frontend
├── pyproject.toml
├── run1000.sh                      # Train the ~$800 nanochat d32
├── rustbpe                         # Custom Rust BPE tokenizer trainer
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── README.md                   # see for why this even exists
│   └── src
│       └── lib.rs
├── scripts
│   ├── base_eval.py                # Base model: calculate CORE score
│   ├── base_loss.py                # Base model: calculate bits per byte, sample
│   ├── base_train.py               # Base model: train
│   ├── chat_cli.py                 # Chat model (SFT/Mid): talk to over CLI
│   ├── chat_eval.py                # Chat model (SFT/Mid): eval tasks
│   ├── chat_rl.py                  # Chat model (SFT/Mid): reinforcement learning
│   ├── chat_sft.py                 # Chat model: train SFT
│   ├── chat_web.py                 # Chat model (SFT/Mid): talk to over WebUI
│   ├── mid_train.py                # Chat model: midtraining
│   ├── tok_eval.py                 # Tokenizer: evaluate compression rate
│   └── tok_train.py                # Tokenizer: train it
├── speedrun.sh                     # Train the ~$100 nanochat d20
├── tasks
│   ├── arc.py                      # Multiple choice science questions
│   ├── common.py                   # TaskMixture | TaskSequence
│   ├── customjson.py               # Make Task from arbitrary jsonl convos
│   ├── gsm8k.py                    # 8K Grade School Math questions
│   ├── humaneval.py                # Misnomer; Simple Python coding task
│   ├── mmlu.py                     # Multiple choice questions, broad topics
│   ├── smoltalk.py                 # Conglomerate dataset of SmolTalk from HF
│   └── spellingbee.py              # Task teaching model to spell/count letters
├── tests
│   └── test_engine.py
│   └── test_rustbpe.py
└── uv.lock
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
When submitting PRs to karpathy/nanochat, declare any parts with substantial LLM contribution you haven't fully verified.

*This fork itself is developed with the assistance of LLMs!*

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

**Fork Integration & Deployment Guides:**

- **originalzen** (@originalzen) - Merged karpathy + TrelisResearch with deployment optimizations
    - Repository: [originalzen/nanochat](https://github.com/originalzen/nanochat)
    - [Runpod Quickstart Guide](README_QUICKSTART_RUNPOD.md) - Complete deployment documentation
    - [Runpod Template](https://console.runpod.io/deploy?template=q3zrjjxw39) - One-click deploy

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

## Listen to Thought-Provoking Discussion with Andrej Karpathy and Lex Fridman

<a href="https://www.youtube.com/watch?v=cdiD-9MMpb0">
  <img src="https://img.youtube.com/vi/cdiD-9MMpb0/maxresdefault.jpg" alt="Andrej Karpathy: Tesla AI, Self-Driving, Optimus, Aliens, and AGI | Lex Fridman Podcast #333" width="400">
</a>

**[▶️ Andrej Karpathy: Tesla AI, Self-Driving, Optimus, Aliens, and AGI | Lex Fridman Podcast #333](https://www.youtube.com/watch?v=cdiD-9MMpb0)** (3 hours, 29 minutes)

---

*fin*
