# AI Server

Primary operator reference for the AI host `gex0` at `https://ai.epytype.org`.

## Server profile

- host: `gex0`
- public domain: `ai.epytype.org`
- hardware target: RTX 4000 SFF Ada, 20GB VRAM, 14 CPU threads
- engine: Ollama + Open WebUI in Docker
- source of truth for model inventory: `roles/ai_rig/defaults/main.yml`

## Installed model inventory

These lists are expected to stay in sync with `ai_models` and `ai_models_remove` in `roles/ai_rig/defaults/main.yml`.

### Active model set

#### Coding & logic

<!-- ai_models:start -->
- `qwen2.5-coder:14b`: Mid-size coder variant
- `qwen2.5-coder:32b`: 32B coder, 32K context
- `qwen3-coder:30b`: 30B coder, Q4_K_M quantized
- `deepseek-coder-v2:16b`: 16B coding specialist
- `deepseek-r1:32b`: 32B reasoning, Q4_K_M quantized
- `starcoder2:7b`: Fast code completion, 16K context
- `phi4:latest`: 14B reasoning model
- `llama3.1:8b`: Meta 8B instruct, 8K context
- `mistral-small3.2:24b`: 24B, improved function calling
- `mistral-small3.1:24b`: 24B, 128K context, multimodal
- `gemma4:e4b`: 9.6GB, 128K context, multimodal
- `qwen2.5:14b`: 14B multilingual support
- `deepseek-r1:14b`: 14B reasoning model
- `deepseek-r1:8b`: 8B reasoning specialist
- `magistral:24b`: 24B reasoning specialist
- `llava:7b`: Vision-language, image understanding
- `bakllava:7b`: Mistral 7B + vision
- `phi4-mini:3.8b`: Tiny Phi-4, 128K context
- `gemma4:e2b`: 7.2GB, 128K context, edge device ready
- `gemma:2b`: Ultra-lightweight
- `starcoder2:3b`: Tiny coder, 3B params
- `codegemma:2b`: Small Google coder
- `hermes3:8b`: 8B agentic capabilities
- `nomic-embed-text:latest`: High-quality embeddings
<!-- ai_models:end -->

#### Configured removals

These entries are removed by the role when present:

<!-- ai_models_remove:start -->
- `deepseek-v4-pro:cloud`
- `mistral-small3.1:24b`
<!-- ai_models_remove:end -->

### Operator notes

- `open_webui_show_all_models: true`
- `open_webui_model_selection: advanced`
- one large model is the intended steady-state VRAM footprint: `max_vram_models: 1`
- idle VRAM retention: `vram_keep_alive: 30m`
- concurrent request limit: `parallel_requests: 6`

## Runtime configuration

- NVIDIA driver target: `535`
- CPU governor: `performance`
- swap: `16384MB`
- Ollama port: `11434`
- Open WebUI port: `3000`
- Ollama data path: `/opt/ollama`
- Open WebUI data path: `/opt/open-webui`
- nginx proxy buffering: `off`
- nginx read timeout: `600s`
- reboot guard enabled: `true`
- reboot guard watch users: `j`, `devops`, `r`

## Use cases

### Coding

- large code changes: `qwen2.5-coder:32b`, `qwen3-coder:30b`
- balanced coding work: `qwen2.5-coder:14b`, `deepseek-coder-v2:16b`
- fast completion/snippets: `starcoder2:7b`, `starcoder2:3b`, `codegemma:2b`

### Reasoning

- strongest reasoning: `deepseek-r1:32b`, `magistral:24b`
- mid-size reasoning: `deepseek-r1:14b`, `phi4:latest`
- fast reasoning: `deepseek-r1:8b`, `phi4-mini:3.8b`

### General chat and writing

- balanced chat: `llama3.1:8b`
- multilingual writing: `qwen2.5:14b`
- higher-quality general output: `mistral-small3.2:24b`
- agentic interaction: `hermes3:8b`

### Vision and multimodal

- direct vision tasks: `llava:7b`, `bakllava:7b`
- multimodal general work: `gemma4:e4b`, `gemma4:e2b`

### Embeddings and RAG

- embeddings: `nomic-embed-text:latest`
- pair it with `llama3.1:8b`, `qwen2.5:14b`, or another chat model as needed

## Open WebUI access

- URL: `https://ai.epytype.org`
- local binding: `127.0.0.1:3000`
- TLS is terminated by nginx

Generate an API key in Open WebUI:

1. Sign in to `https://ai.epytype.org`.
2. Open the user menu.
3. Go to `Settings`, then `Account` or `Profile`.
4. Open `API Keys`.
5. Create a new key.
6. Store it immediately in your secret manager.

Smoke test:

```bash
curl -H "Authorization: Bearer <WEBUI_API_KEY>" https://ai.epytype.org/api/v1/models
```

Zed setup with the OpenAI-compatible endpoint:

```bash
export OPENAI_API_KEY="<WEBUI_API_KEY>"
export OPENAI_API_BASE="https://ai.epytype.org/api/v1"
```

In Zed, add an OpenAI-compatible provider and select a model exactly as listed in this document.

## Deployment & testing

Deploy from `ops/`:

```bash
source ./bin/loadenv.sh
apb setup_epytype.yml -l gex0
```

Narrow deployment or refresh paths:

```bash
apb setup_epytype.yml -l gex0 -t ai_rig
apb setup_epytype.yml -l gex0 -t ollama
apb setup_epytype.yml -l gex0 -t pull_models
apb setup_epytype.yml -l gex0 -t show_models
apb setup_epytype.yml -l gex0 -t webui
```

Post-deployment checks:

```bash
ansible gex0 -m ping
ansible gex0 -m shell -a "docker ps --format '{{.Names}} {{.Status}}'"
ansible gex0 -m shell -a "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv"
curl -H "Authorization: Bearer <WEBUI_API_KEY>" https://ai.epytype.org/api/v1/models
curl http://gex0:11434/api/tags | jq .
```

Interactive smoke tests:

```bash
curl -X POST http://gex0:11434/api/generate \
  -d '{"model":"phi4-mini:3.8b","prompt":"Reply with exactly: AI_SERVER_OK","stream":false}'

curl -X POST http://gex0:11434/api/generate \
  -d '{"model":"qwen2.5-coder:14b","prompt":"Write a Python function that returns fibonacci numbers up to n.","stream":false}'

curl -X POST http://gex0:11434/api/generate \
  -d '{"model":"deepseek-r1:8b","prompt":"If x + 3 = 10, what is x?","stream":false}'
```

Web UI check:

1. Open `https://ai.epytype.org`.
2. Confirm the model selector shows the expected installed models.
3. Run a simple prompt against one coding model and one reasoning model.

## Managing models

List installed models:

```bash
docker exec ollama ollama list
```

Pull a model manually:

```bash
docker exec ollama ollama pull <model-name>
```

Remove a model manually:

```bash
docker exec ollama ollama rm <model-name>
```

Use the role-managed path when the configured inventory changes:

```bash
apb setup_epytype.yml -l gex0 -t pull_models
```

## Troubleshooting

Model pull failure:

- verify the requested name exists in the Ollama library
- inspect the Ollama container logs
- confirm NVIDIA runtime health on the host

Service checks:

```bash
ansible gex0 -m shell -a "docker logs ollama --tail 50"
ansible gex0 -m shell -a "docker logs open-webui --tail 50"
ansible gex0 -m shell -a "systemctl status nvidia-persistenced --no-pager"
ansible gex0 -m shell -a "docker info | grep -i runtime"
```

Restart services:

```bash
ansible gex0 -m shell -a "docker restart ollama"
ansible gex0 -m shell -a "docker restart open-webui"
```

High VRAM pressure:

- keep to one large loaded model at a time
- use smaller models such as `phi4-mini:3.8b`, `gemma:2b`, or `starcoder2:3b`
- confirm swap remains available at `/swapfile`
