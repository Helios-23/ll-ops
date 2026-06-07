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
| `qwen3-coder:30b` | ~19GB | Newer large coding model | 32K |
| `deepseek-coder-v2:16b` | 9GB | Strong coding performance, 600+ languages | 16K |
| `deepseek-r1:32b` | ~20GB | Large reasoning + coding assistant | 32K |
| `starcoder2:7b` | 4GB | Fast code completion, 17 languages | 16K |
| `phi4:latest` | 9.1GB | Microsoft's 14B model, strong reasoning | 16K |

### General LLM & Writing
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `llama3.1:8b` | 4.7GB | Meta's 8B instruct model | 8K |
| `mistral-small3.2:24b` | ~15GB | General-purpose model with improved tool use | 128K |
| `mistral-small3.1:24b` | ~15GB | General-purpose multilingual model | 128K |
| `gemma4:e4b` | ~9.6GB | Google multimodal model | 128K |
| `qwen2.5:14b` | 9GB | Alibaba's 14B, multilingual | 32K |

### Reasoning
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `deepseek-r1:8b` | 4.7GB | Reasoning specialist with chain-of-thought | 8K |
| `magistral:24b` | ~15GB | Larger reasoning-focused model | 128K |

### Multimodal / Vision
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `gemma4:e4b` | ~9.6GB | Multimodal (image + text) | 128K |
| `llava:7b` | 4.7GB | Vision-language model, image understanding | 8K |
| `bakllava:7b` | 4.7GB | Mistral 7B + LLaVA architecture | 32K |

### Small Fast Models (Multiple Simultaneous)
| Model | Size | Purpose | Context |
|-------|------|---------|---------|
| `phi4-mini:3.8b` | 2.5GB | Tiny Phi-4, 128K context, fast inference | 128K |
| `gemma4:e2b` | ~7.2GB | Fast multimodal edge-oriented model | 128K |
| `gemma:2b` | 1.3GB | Ultra-lightweight, good for simple tasks | 8K |

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

---

## Server Optimization

- **GPU VRAM:** 20GB target, 1 large active model, `OLLAMA_KEEP_ALIVE=30m`, `OLLAMA_NUM_PARALLEL=2`
- **GPU Runtime:** `nvidia-driver-535`, NVIDIA Container Toolkit, persistence mode + `nvidia-persistenced`
- **Memory Safety:** 16GB swap (`/swapfile`) + VM tuning (`swappiness=10`, `overcommit_memory=1`)
- **Network Path:** WebUI on `127.0.0.1:3000`, TLS endpoint `https://ai.epetype.org`, Ollama reachable through proxy
- **Ops Safety:** GPU OOM watchdog, daily cleanup timer, certbot auto-renew
- **Reboot Guard:** periodic NVIDIA userspace/driver mismatch check that writes the standard reboot-required marker only when configured interactive user processes are idle

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
- `deepseek-r1:32b` - Best quality reasoning
- `deepseek-r1:8b` - Fast general reasoning chains
- `magistral:24b` - Strong long-form reasoning
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
- `mistral-small3.2:24b` - High-quality writing and summarization
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
1. Use `nomic-embed-text` to generate embeddings
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

### Generate an API Key in Open WebUI
1. Sign in to `https://ai.epetype.org` with your WebUI account.
2. Open your user menu in the top-right corner.
3. Go to `Settings` then `Account` (or `Profile`, depending on WebUI version).
4. Find the `API Keys` section.
5. Click `Create New Key`.
6. Enter a label (example: `ci-agent`), then confirm.
7. Copy the generated key immediately and store it in your secret manager.
8. Test the key with a simple request against the WebUI API endpoint.

Example test:
```bash
curl -H "Authorization: Bearer <WEBUI_API_KEY>" https://ai.epetype.org/api/v1/models
```

### Use Open WebUI API Token in Zed (Private CLI)
1. Generate a WebUI API key using the steps above.
2. In your shell profile (`~/.zshrc` or `~/.bashrc`), add:
   ```bash
   export OPENAI_API_KEY="<WEBUI_API_KEY>"
   export OPENAI_API_BASE="https://ai.epetype.org/api/v1"
   ```
3. Reload your shell:
   ```bash
   source ~/.zshrc
   ```
4. Open Zed, then go to `Settings` -> `AI` (or `Assistant`) and add a new provider using the OpenAI-compatible option.
5. Set provider fields as follows:
   - **Base URL / Endpoint:** `https://ai.epetype.org/api/v1`
   - **API Key:** use environment variable `OPENAI_API_KEY` (or paste the token directly if your Zed build requires manual entry)
   - **Compatibility/Provider Type:** `OpenAI-compatible` (not hosted OpenAI)
6. In the model selection field, pick a server-installed model name exactly as listed in this doc (example: `deepseek-coder-v2:16b`).
7. Open a new assistant chat in Zed and run a verification prompt such as `Reply with exactly: PRIVATE_AI_OK`. Success criteria: low-latency response and exact output from the selected private model.

Note: Some Zed builds label this as "OpenAI-compatible endpoint" rather than "OpenAI API Base".

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
