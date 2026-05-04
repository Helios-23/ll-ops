# AI Server Documentation

**Server:** `gex0` (ai.epetype.org)  
**Hardware:** RTX 4000 SFF Ada (20GB VRAM, 14 CPU threads)  
**Engine:** Ollama + Open WebUI (Docker containers)

---

## Installed Models

### Coding & Logic
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `qwen2.5-coder:32b` | 20GB | Large coding model, multilingual support | 32K |
| `deepseek-coder-v2:16b` | 9GB | Strong coding performance, 600+ languages | 16K |
| `starcoder2:7b` | 4GB | Fast code completion, 17 languages | 16K |
| `phi4:latest` | 9.1GB | Microsoft's 14B model, strong reasoning | 16K |

### General LLM & Writing
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `llama3.1:8b` | 4.7GB | Meta's 8B instruct model | 8K |
| `mistral:7b` | 4.1GB | Fast 7B general purpose model | 8K |
| `gemma2:9b` | 5.4GB | Google's 9B, good balance | 8K |
| `qwen2.5:14b` | 9GB | Alibaba's 14B, multilingual | 32K |

### Reasoning
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `deepseek-r1:8b` | 4.7GB | Reasoning specialist with chain-of-thought | 8K |

### Multimodal / Vision
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `llava:7b` | 4.7GB | Vision-language model, image understanding | 8K |
| `bakllava:7b` | 4.7GB | Mistral 7B + LLaVA architecture | 32K |

### Small Fast Models (Multiple Simultaneous)
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `phi4-mini:3.8b` | 2.5GB | Tiny Phi-4, 128K context, fast inference | 128K |
| `gemma:2b` | 1.3GB | Ultra-lightweight, good for simple tasks | 8K |

### Math & Proofs
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `ima/deepseek-math:latest` | 4GB | Math specialist (7B), step-by-step reasoning | 4K |

### Coding (Small/Fast)
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `starcoder2:3b` | 1.7GB | Tiny coder, 17 languages | 16K |
| `codegemma:2b` | 1.3GB | Small coding model from Google | 8K |

### Structured Output / Agents
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `hermes3:8b` | 4.7GB | Nous Research, strong agentic capabilities | 128K |

### Embeddings (for RAG)
| Model | Size | Purpose |
|-------|------|---------|
| `nomic-embed-text:latest` | 274MB | High-quality text embeddings |
| `mxbai-embed-large:latest` | 438MB | Large embedding model for RAG |

---

## Server Optimizations

### GPU & VRAM Management
- **Max Loaded Models:** 1 large model at a time (20GB VRAM limit)
- **OLLAMA_MAX_LOADED_MODELS:** 4 (for small models)
- **OLLAMA_KEEP_ALIVE:** 30 minutes (not 24h - saves VRAM)
- **OLLAMA_NUM_PARALLEL:** 2 (limit concurrent requests)
- **OLLAMA_NUM_GPU:** 999 (use all available GPU)
- **Swap File:** 16GB (`/swapfile`) for CPU offload when VRAM full
- **GPU Memory Utilization:** 85% (leaves room for fragmentation)

### NVIDIA Configuration
- **Driver:** Version 535 (installed via `nvidia-driver-535`)
- **NVIDIA Container Toolkit:** Configured for Docker (`nvidia-ctk runtime configure`)
- **Persistence Mode:** Enabled (`nvidia-smi -pm 1`)
- **Persistence Daemon:** `nvidia-persistenced` enabled + started
- **Transparent HugePages:** Enabled for better memory performance

### CPU & System
- **CPU Governor:** Performance mode (`cpupower frequency-set -g performance`)
- **Virtual Memory Tuning:**
  - `vm.swappiness = 10` (prefer RAM)
  - `vm.dirty_ratio = 10`
  - `vm.dirty_background_ratio = 5`
  - `vm.overcommit_memory = 1`
- **OOM Score:** Configured for Ollama process protection

### Docker & Networking
- **Docker Engine:** Official Docker repo (docker-ce, containerd.io)
- **Docker Compose:** v2 plugin installed
- **Internal Network:** `ai_network` (isolated Docker network)
- **Ollama Port:** `11434` (published)
- **Open WebUI Port:** `3000` (localhost only, proxied via nginx)

### Nginx Reverse Proxy
- **Domain:** `ai.epetype.org`
- **TLS:** Let's Encrypt certificates (auto-renewal)
- **Proxy Buffering:** Off (streaming responses)
- **Read Timeout:** 600s (long model responses)
- **Client Max Body:** 128M

### Maintenance & Monitoring
- **GPU Watchdog:** `gpu-oom-watcher.sh` (restarts Ollama if VRAM >95% for 5 checks)
- **Daily Cleanup:** `ai-cleanup.sh` (removed stopped containers, dangling images)
- **Log Rotation:** Journald logs vacuumed to 7 days
- **Certbot Timer:** Auto-renews TLS certificates

---

## Use Cases Guide

### 1. Code Generation & Completion
**Best Models:**
- `qwen2.5-coder:32b` - Large projects, complex algorithms
- `deepseek-coder-v2:16b` - General coding (defdault model)
- `starcoder2:7b` - Fast autocomplete
- `starcoder2:3b` - Ultra-fast snippets

**Example (Open WebUI):**
```
Write a Python function to implement a binary search tree with insert and search methods.
```

### 2. Mathematical Proofs & Reasoning
**Best Models:**
- `ima/deepseek-math:latest` - Math problems (add "Please reason step by step, and put your final answer within \boxed{}.")
- `deepseek-r1:8b` - General reasoning chains
- `phi4:latest` - Logic and reasoning

**Example:**
```
Solve for x: 3x² - 12x + 9 = 0
Please reason step by step, and put your final answer within \boxed{}.
```

### 3. General Writing & Conversation
**Best Models:**
- `llama3.1:8b` - Balanced general purpose
- `qwen2.5:14b` - Multilingual writing
- `gemma2:9b` - Creative writing
- `hermes3:8b` - Agentic conversations

### 4. Vision & Image Understanding
**Best Models:**
- `llava:7b` - Image analysis, visual Q&A
- `bakllava:7b` - Mistral-based vision tasks

**Example (Open WebUI):**
```
[Upload image] What objects are present in this image?
```

### 5. Small/Fast Tasks (Low Latency)
**Best Models:**
- `phi4-mini:3.8b` - Fast inference, 128K context
- `gemma:2b` - Ultra-lightweight
- `codegemma:2b` - Quick code snippets

### 6. RAG (Retrieval-Augmented Generation)
**Workflow:**
1. Use `nomic-embed-text` or `mxbai-embed-large` to generate embeddings
2. Store in vector database
3. Query with any chat model (recommended: `llama3.1:8b`, `qwen2.5:14b`)

### 7. Agentic Workflows & Structured Output
**Best Models:**
- `hermes3:8b` - Function calling, structured JSON output
- `phi4:latest` - Agent reasoning
- `qwen2.5:14b` - Multilingual agents

---

## Open WebUI Access

**URL:** https://ai.epetype.org  
**Local Port:** `3000` (localhost only, nginx proxy handles TLS)

**Features:**
- Model selection (all installed models visible)
- Chat interface with streaming
- Image upload for vision models
- RAG document upload
- Function/tool calling support

---

## Managing Models

### Pull a New Model
```bash
docker exec ollama ollama pull <model-name>
```

### Remove a Model
```bash
docker exec ollama ollama rm <model-name>
```

### List Installed Models
```bash
docker exec ollama ollama list
```

### Check VRAM Usage
```bash
nvidia-smi
```

---

## Troubleshooting

### Model Pull Fails
- Check model name at https://ollama.com/library
- Verify NVIDIA runtime: `docker run --runtime=nvidia --rm nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi`

### Ollama Container Won't Start
- Check NVIDIA persistence daemon: `systemctl status nvidia-persistenced`
- Verify Docker runtime: `docker info | grep -i runtime`

### High VRAM Usage
- Reduce `OLLAMA_MAX_LOADED_MODELS` in Ansible vars
- Enable swap: already configured at 16GB
- Use smaller models (`phi4-mini`, `gemma:2b`)

### Restart Services
```bash
docker restart ollama
docker restart open-webui
```
