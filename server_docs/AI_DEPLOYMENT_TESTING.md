# AI Server Deployment & Testing

## Deployment Commands

```bash
# 1. Load credentials
cd /Users/H23/logicallight/Epytype/ops
source ./bin/loadenv.sh
# Enter password: "take me to the spaceport at oxford valley mall"

# 2. Deploy AI server stack (uses wrapper for correct relative paths)
apb ai-server.yml --ask-become-pass
# Enter become password when prompted (from vault)

# 3. Verify services are running
ansible gex1 -m shell -a "docker ps"
ansible gex1 -m ping
```

## Post-Deployment Testing

### 1. Web UI Test
```bash
# Open in browser
open https://ai.epytype.org

# Expected: Open WebUI loads with model selection dropdown
# - All installed quantized models should be visible
# - Select a model (e.g., phi3:3.8b-q4_0)
# - Send test message: "Solve: 2x + 5 = 13"
```

### 2. API Direct Test
```bash
# Test basic chat API
curl -X POST https://ai.epytype.org/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "phi3:3.8b-q4_0",
    "messages": [{"role": "user", "content": "What is 25 * 4?"}],
    "stream": false
  }' | jq .

# Test math model
curl -X POST https://ai.epytype.org/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-math:7b-q4_0",
    "messages": [{"role": "user", "content": "Prove that sqrt(2) is irrational"}],
    "stream": false
  }' | jq .
```

### 3. Ollama Direct Test
```bash
# Test Ollama API directly (port 11434)
curl http://gex1:11434/api/tags | jq .

# Pull a model directly via API
curl -X POST http://gex1:11434/api/pull -d '{"name": "phi3:3.8b-q4_0"}'

# Generate text
curl -X POST http://gex1:11434/api/generate \
  -d '{"model": "phi3:3.8b-q4_0", "prompt": "Write code for fibonacci"}'
```

### 4. Configure in Zed Editor
```
1. Open Zed Settings (Cmd+,)
2. Search for "Assistant"
3. Add OpenAI-Compatible API:
   - API URL: https://ai.epytype.org/api
   - API Key: (leave empty if WEBUI_SECRET_KEY is set)
   - Model: phi3:3.8b-q4_0 (or any installed model)
4. Test: Cmd+Shift+A to open Assistant
```

### 5. Health Checks
```bash
# Check Open WebUI health
curl -s https://ai.epytype.org/health | jq .

# Check Ollama health
curl -s http://gex1:11434/api/version | jq .

# Check Docker containers
ansible gex1 -m shell -a "docker ps --format '{{.Names}} {{.Status}}'"

# Check GPU usage
ansible gex1 -m shell -a "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv"
```

### 6. Test Small Math Models
```bash
# Test deepseek-math
curl -X POST https://ai.epytype.org/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-math:7b-q4_0",
    "messages": [{"role": "user", "content": "Calculate integral of x^2 from 0 to 5"}],
    "stream": false
  }' | jq -r '.message.content'

# Test qwen2.5:3b (small math)
curl -X POST https://ai.epytype.org/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:3b-q4_0",
    "messages": [{"role": "user", "content": "If x + 3 = 10, what is x?"}],
    "stream": false
  }' | jq -r '.message.content'
```

## Troubleshooting

```bash
# View Open WebUI logs
ansible gex1 -m shell -a "docker logs open-webui --tail 50"

# View Ollama logs
ansible gex1 -m shell -a "docker logs ollama --tail 50"

# Restart services
ansible gex1 -m shell -a "docker restart ollama && docker restart open-webui"

# Check Nginx logs
ansible gex1 -m shell -a "tail -50 /var/log/nginx/error.log"
```
