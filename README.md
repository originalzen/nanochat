# nanochat

![nanochat logo](dev/nanochat.png)

> The best ChatGPT that $100 can buy.

---

## Fork Information

This fork integrates convenience enhancements from [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat) into the upstream [karpathy/nanochat](https://github.com/karpathy/nanochat) codebase.

**Maintained by:** [@originalzen](https://github.com/originalzen)

### What's Added

**Base:** Latest karpathy/nanochat code (all bug fixes through Dec 8, 2025)

**Enhancements from TrelisResearch:**

- `scripts/push_to_hf.py` - Upload checkpoints to HuggingFace Hub
- `scripts/pull_from_hf.py` - Download checkpoints from HuggingFace Hub
- `runpod_onstart.sh` - Automated Runpod environment setup (adaptation based on the template from TrelisResearch)
- `hf-transfer` dependency

### Why This Fork Exists

TrelisResearch added excellent Runpod integration and HuggingFace utilities, but was missing some upstream bug fixes from Karpathy at the time of forking the repo. This fork merges the best of both:

- Latest updates and bug fixes from Karpathy upstream
- Convenience scripts from TrelisResearch
    - Runpod automation template with injection of environment variables/Secrets
    - Integration with Weights & Biases (`wandb`) for monitoring, tracking, and visualization of training progress
    - HuggingFace backup/restore workflow
- Regular upstream sync to stay current with Karpathy's active development

This fork also exists for me to learn and practice more with `git` and GitHub workflows and of course as a learning tool/opportunity for ML and LLM training and development through tinkering and experimentation. Much thanks and appreciation to Andrej Karpathy for making nanochat open source, accessible to everyone, and to Ronan K. McGovern at Trelis Research for the added scripts and the video tutorial [Train an LLM from Scratch with Karpathy's Nanochat](https://www.youtube.com/watch?v=qra052AchPE).

---

## About **nanochat**

This repo is a full-stack implementation of an LLM like ChatGPT in a single, clean, minimal, hackable, dependency-lite codebase. nanochat is designed to run on a single 8x H100 node via scripts like [speedrun.sh](speedrun.sh), which run the entire pipeline start to end. This includes tokenization, pretraining, finetuning, evaluation, inference, and web serving over a simple UI so that you can talk to your own LLM just like ChatGPT. nanochat will become the capstone project of the course **LLM101n** being developed by [Eureka Labs](https://eurekalabs.ai).

### Talk to it

To get a sense of the endpoint of this repo, you can currently find [nanochat d32](https://github.com/karpathy/nanochat/discussions/8) hosted on [nanochat.karpathy.ai](https://nanochat.karpathy.ai/). "d32" means that this model has 32 layers in the Transformer neural network. This model has 1.9 billion parameters, it was trained on 38 billion tokens by simply running the single script [run1000.sh](run1000.sh), and the total cost of training was ~$800 (about 33 hours training time on an 8x H100 GPU node). While today this is enough to outperform GPT-2 of 2019, it falls dramatically short of modern Large Language Models like GPT-5. When talking to these micro models, you'll see that they make a lot of mistakes: they are a little bit naive, silly, and they hallucinate a ton, a bit like children. It's kind of amusing. But what makes nanochat unique is that it is fully yours - fully configurable, tweakable, hackable, and trained by you from start to end.

---

## Quick Start

### Standard Setup (Any Cloud Provider)

The fastest way to feel the magic is to run the speedrun script [speedrun.sh](speedrun.sh), which trains the $100 tier nanochat. On an 8x H100 node at ~$24/hr, this gives a total run time of about 4 hours.

```bash
# Clone this fork
git clone https://github.com/originalzen/nanochat.git
cd nanochat

# Run training (use screen for persistence)
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

Detach with `Ctrl-A`, then press `D` to detach from the `screen` session. Monitor progress with `tail -f speedrun.log`. After ~4 hours, talk to your LLM via the ChatGPT-like web UI:

```bash
source .venv/bin/activate
python -m scripts.chat_web
```

Then visit the URL shown (e.g., `http://<host-ip>:8000`).

### Runpod Quick Start

For Runpod deployment with automated setup:

**Option 1: Manual Clone (Recommended):**

```bash
# SSH into your 8x H100 Runpod pod
cd /workspace
git clone https://github.com/originalzen/nanochat.git
cd nanochat
export WANDB_RUN=my_run_name
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
```

**Option 2: Automated Template:**

1. **Configure Runpod Secrets:**
   - `HF_TOKEN` - HuggingFace token with write permissions (required)
   - `WANDB_API_KEY` - Weights & Biases API key (recommended)
   - `GIT_USERNAME` - Your GitHub username (optional, defaults to `originalzen`)

2. **Upload `runpod_onstart.sh` as custom template** (optional)

3. **Deploy 8x H100 pod** → Repo auto-clones → Ready to train

**Training time:** ~4 hours | **Cost:** ~$100 | **Result:** Your own GPT-2 level LLM

---

## Backup & Restore Checkpoints

### Upload to HuggingFace (After Training)

This fork includes convenience scripts for checkpoint management:

```bash
source .venv/bin/activate
export NANOCHAT_BASE_DIR="$HOME/.cache/nanochat"

# Upload SFT checkpoint (most important - your final chat model)
python -m scripts.push_to_hf --stage sft --repo-id YourUsername/nanochat-d20 --path-in-repo sft/d20

# Upload tokenizer (required for inference)
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/tokenizer" \
  --repo-id YourUsername/nanochat-d20 --path-in-repo tokenizer/latest

# Upload training report (metrics and benchmarks)
python -m scripts.push_to_hf --model-dir "$NANOCHAT_BASE_DIR/report" \
  --repo-id YourUsername/nanochat-d20 --path-in-repo report/latest
```

### Download from HuggingFace

```bash
# Download SFT checkpoint for inference
python -m scripts.pull_from_hf --repo-id YourUsername/nanochat-d20 \
  --repo-path sft/d20 --stage sft --target-tag d20

# Download tokenizer
export NANOCHAT_BASE_DIR="$HOME/.cache/nanochat"
python -m scripts.pull_from_hf --repo-id YourUsername/nanochat-d20 \
  --repo-path tokenizer/latest --dest-dir "$NANOCHAT_BASE_DIR/tokenizer"
```

Downloads land in `$NANOCHAT_BASE_DIR/{base,mid,chatsft}` by default, so scripts like `chat_web` can find them automatically.

---

## Training Results

After training completes, view the report card:

```bash
cat report.md
```

Expected metrics for the $100 speedrun (d20 model, ~500M parameters):

| Metric          | BASE     | MID      | SFT      |
|-----------------|----------|----------|----------|
| CORE            | ~0.2219  | -        | -        |
| ARC-Challenge   | -        | ~0.2875  | ~0.2807  |
| ARC-Easy        | -        | ~0.3561  | ~0.3876  |
| GSM8K           | -        | ~0.0250  | ~0.0455  |
| HumanEval       | -        | ~0.0671  | ~0.0854  |
| MMLU            | -        | ~0.3111  | ~0.3151  |

**Total wall clock time:** ~3h 47m

For more details, see Karpathy's walkthrough: [Introducing nanochat: The best ChatGPT that $100 can buy.](https://github.com/karpathy/nanochat/discussions/1)

---

## Using This Fork

### Fork This Repository

To create your own version:

1. Click "Fork" on GitHub
2. Clone your fork: `git clone https://github.com/YourUsername/nanochat.git`
3. (Optional) Update `runpod_onstart.sh` default `GIT_USERNAME` to yours
4. Deploy and train!

### Stay Synced with Upstream

This fork will regularly pull updates from the upstream `karpathy/nanochat` repository:

```bash
# Add upstream remote (if not already added)
git remote add upstream https://github.com/karpathy/nanochat.git

# Sync with latest karpathy changes
git fetch upstream
git merge upstream/master
git push origin master
```

---

## Bigger Models

Unsurprisingly, $100 is not enough to train a highly performant ChatGPT clone. For better performance, consider:

- **~$300 tier (d26):** Trains in ~12 hours, slightly outperforms GPT-2 CORE score
- **~$1000 tier (d32):** Trains in ~41.6 hours, 1.9B parameters

To train larger models, adjust these parameters in `speedrun.sh`:

```bash
# Download more data shards (for d26)
python -m nanochat.dataset -n 450 &

# Increase model depth and adjust batch size to fit in VRAM
torchrun --standalone --nproc_per_node=8 -m scripts.base_train -- --depth=26 --device_batch_size=16
torchrun --standalone --nproc_per_node=8 -m scripts.mid_train -- --device_batch_size=16
```

---

## Computing Environments

**GPU recommendations:**

- **Best:** 8x H100 SXM (~$24/hr, optimal interconnect)
- **Alternative:** 8x A100 80GB (slower, may cost more per epoch)
- **Budget:** Single GPU (significantly slower by at least 8x, but it produces about the same results via gradient accumulation)

**Memory management:**

- GPUs with <80GB VRAM: Reduce `--device_batch_size` from `32` to `16`, `8`, `4`, or `2`
- Scripts automatically compensate with gradient accumulation

**CPU/MPS support:**

- For testing pipelines on Macbook/CPU, see [dev/runcpu.sh](dev/runcpu.sh)
- Merged in [CPU|MPS PR](https://github.com/karpathy/nanochat/pull/88) on Oct 21, 2025

---

## Customization

**Infuse personality:**

- See [Guide: infusing identity to your nanochat](https://github.com/karpathy/nanochat/discussions/139)
- Generate synthetic identity conversations
- Mix into midtraining and SFT stages

**Add new abilities:**

- See [Guide: counting r in strawberry](https://github.com/karpathy/nanochat/discussions/164)
- Create custom tasks and datasets
- Extend evaluation framework

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
│   ├── chat_web.py               # Web interface
│   └── [other training scripts]
├── runpod_onstart.sh             # NEW: Runpod automation
├── nanochat/
│   ├── gpt.py                    # GPT Transformer implementation
│   ├── tokenizer.py              # BPE tokenizer
│   ├── engine.py                 # Inference with KV cache
│   └── [core modules]
├── tasks/                        # Evaluation tasks (MMLU, GSM8K, etc.)
├── rustbpe/                      # Custom Rust BPE tokenizer trainer
├── speedrun.sh                   # Train the ~$100 nanochat d20
├── run1000.sh                    # Train the ~$800 nanochat d32
└── pyproject.toml                # Dependencies
```

See [karpathy/nanochat](https://github.com/karpathy/nanochat#file-structure) for complete file descriptions.

---

## Credits & Attribution

**Core Implementation:**

- **Andrej Karpathy** - Original nanochat design, implementation, and ongoing development
    - Repository: [karpathy/nanochat](https://github.com/karpathy/nanochat)
    - Course: [LLM101n](https://github.com/karpathy/LLM101n) (upcoming from Eureka Labs)

**Runpod + `wandb` Integration and HuggingFace Utilities:**

- **Trelis Research** - Runpod template, push/pull scripts, comprehensive tutorial
    - Repository: [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat)
    - Substack Guide: [Train an LLM from Scratch with Karpathy's Nanochat](https://trelis.substack.com/p/train-an-llm-from-scratch-with-karpathys)
    - YouTube Video Tutorial: [Train an LLM from Scratch with Karpathy's Nanochat](https://www.youtube.com/watch?v=qra052AchPE)

### Upstream Tracking

This fork tracks [karpathy/nanochat](https://github.com/karpathy/nanochat) and merges updates regularly:

- **Last synced:** December 10, 2025
- **Base commit:** `d575940` (Dec 8, 2025)
- **Sync frequency:** Weekly or before major updates

**Recent upstream changes integrated:**

- ✅ Checkpoint directory race condition fix (multi-GPU training stability)
- ✅ Multi-epoch dataloader resume improvements
- ✅ SpellingBee random seed collision fix
- ✅ Iterator pattern updates in SFT training
- ✅ KV cache readability enhancements

---

## Tests

Some tests exist, especially for the tokenizer:

```bash
python -m pytest tests/test_rustbpe.py -v -s
```

---

## Questions & Community

**Ask questions about this repo:**

- [DeepWiki](https://deepwiki.com/karpathy/nanochat) - AI-powered code Q&A

**Community discussions:**

- [karpathy/nanochat Discussions](https://github.com/karpathy/nanochat/discussions) - Main community
- [Runpod Discord](https://discord.gg/runpod) - Cloud infrastructure help
- [HuggingFace Forums](https://discuss.huggingface.co) - Model sharing

---

## Contributing

**To this fork:**

- Open issues for fork-specific features or deployment guides
- Submit PRs for enhancements or documentation improvements

**To upstream (karpathy/nanochat):**

- Report bugs or request features at [karpathy/nanochat](https://github.com/karpathy/nanochat)
- This fork regularly pulls upstream changes

**Current LLM Policy: Disclosure (for both this fork and upstream):**

When submitting a PR, please declare any parts that had substantial LLM contribution and that you have not written or that you do not fully understand.

*This fork itself is being developed in collaboration and with the assistance of LLMs.*

---

## Acknowledgements

From **karpathy/nanochat:**

- The name (nanochat) derives from [nanoGPT](https://github.com/karpathy/nanoGPT), which only covered pretraining
- Inspired by [modded-nanoGPT](https://github.com/KellerJordan/modded-nanogpt)
- Thank you to [HuggingFace](https://huggingface.co/) for fineweb and smoltalk
- Thank you [Lambda](https://lambda.ai/service/gpu-cloud) for compute
- Thank you to Alec Radford for guidance
- Thank you to [@svlandeg](https://github.com/svlandeg) for repo management

Of **TrelisResearch** for:

- Runpod one-click template and deployment automation. Find it here via his affiliate link:
    - <https://console.runpod.io/deploy?template=ikas3s2cii>
- Weights & Biases integration and monitoring
- HuggingFace push/pull utility scripts
- Comprehensive video tutorial and written guide

---

## Citation

If you find nanochat helpful in your research, cite the original:

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
- **Adaptation:** [TrelisResearch/nanochat](https://github.com/TrelisResearch/nanochat)

**Resources:**

- [Trelis Video Tutorial](https://www.youtube.com/watch?v=qra052AchPE)
- [Karpathy Discussions](https://github.com/karpathy/nanochat/discussions)
- [LLM101n Course](https://github.com/karpathy/LLM101n)

**Tools:**

- [Runpod Console](https://www.runpod.io/console/pods)
- [HuggingFace Hub](https://huggingface.co)
- [Weights & Biases](https://wandb.ai)

---

*fin*
