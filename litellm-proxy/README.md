# LiteLLM Proxy — Gateway Router

The core routing layer of the LLM Serving Gateway. Built on [LiteLLM Proxy v1.103.0](https://github.com/BerriAI/litellm), it handles intelligent failover, rate limiting, and load balancing between self-hosted vLLM and cloud LLM providers.

## Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **Smart Routing** | Priority-based model selection (Order 1 → Order 2 fallback) |
| **Failover** | Automatic fallback to Groq/Gemini when vLLM times out or errors |
| **Rate Limiting** | Per-model RPM/TPM guards enforced via Redis |
| **Load Balancing** | Usage-based distribution among fallback models |
| **Authentication** | `LITELLM_MASTER_KEY` required on all requests |

## Configuration (`config.yaml`)

All routing logic lives in `litellm-proxy/config.yaml`. Key sections:

### Model List (Layered Fallback)

```yaml
model_list:
  # Layer 1: Self-hosted vLLM (Primary)
  - model_name: my-smart-router
    litellm_params:
      model: openai/qwen-2.5-14b-awq
      api_key: os.environ/VLLM_API_KEY
      api_base: os.environ/VLLM_API_BASE
      rpm: 1000
      tpm: 1000000
      max_parallel_requests: 10
      timeout: 3
      order: 1
    model_info:
      id: "vllm-local-primary"

  # Layer 2: Groq Cloud (Fallback)
  - model_name: my-smart-router
    litellm_params:
      model: groq/openai/gpt-oss-20b
      api_key: os.environ/GROQ_API_KEY
      rpm: 1000
      tpm: 100000
      timeout: 5
      order: 2
    model_info:
      id: "groq-cloud-backup-1"

  # Layer 2: Gemini Cloud (Fallback)
  - model_name: my-smart-router
    litellm_params:
      model: gemini/gemini-2.5-flash-lite
      api_key: os.environ/GEMINI_KEY_2_5
      rpm: 15
      tpm: 1000000
      timeout: 5
      order: 2
    model_info:
      id: "gemini-2.5-cloud-backup-2"
```

### Router Settings

| Setting | Value | Meaning |
|---------|-------|---------|
| `routing_strategy` | `simple-shuffle` | Usage-based load balancing among same-order models |
| `redis_url` | `os.environ/REDIS_URL` | Redis for distributed rate limiting & cooldown state |
| `cooldown_time` | `45` | Seconds a model is cooled down after failure |
| `num_retries` | `0` | No retry on same model before failover (faster fallback) |
| `allowed_fails` | `1` | Max failures before triggering cooldown |
| `enable_pre_call_checks` | `true` | Enforce rate limits before forwarding request |
| `optional_pre_call_checks` | `enforce_model_rate_limits` | Redis-backed RPM/TPM enforcement |

### General Settings

| Setting | Value | Meaning |
|---------|-------|---------|
| `master_key` | `os.environ/LITELLM_MASTER_KEY` | Bearer token required on all gateway requests |
| `hide_errors` | `true` | Mask internal error details from clients |

## 🔌 Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `REDIS_URL` | Yes | Redis connection string (e.g., `redis://host:6379/0`) |
| `VLLM_API_BASE` | Yes | Self-hosted vLLM endpoint (e.g., `http://<vm-ip>:8000/v1`) |
| `VLLM_API_KEY` | Yes | API key for vLLM server authentication |
| `GROQ_API_KEY` | Yes | Groq cloud API key |
| `GEMINI_KEY_3_5` | Yes | Gemini cloud API key (backup) |
| `GEMINI_KEY_2_5` | Yes | Gemini cloud API key (backup) |
| `LITELLM_MASTER_KEY` | Yes | Gateway authentication token |

## Port Mapping

| Environment | Port | Notes |
|-------------|------|-------|
| Local Docker Compose | `4000:4000` | Fixed mapping in `docker-compose.local.yml` |
| Cloud Run | `${PORT:-4000}` | Dynamic port from Cloud Run environment |

> ⚠️ The Dockerfile `EXPOSE 8080` is for Cloud Run compatibility; local compose overrides to port 4000.

## Running Locally

```bash
# Build the image
make docker-build

# Start the full stack (LiteLLM + Prometheus + Grafana)
make dev-up

# View logs
make dev-logs

# Stop everything
make dev-down
```

> Redis and vLLM must be running externally before starting the proxy.

## Testing the Gateway

### Health Check
```bash
curl http://localhost:4000/health/liveness
```

### Chat Completion (with Master Key)
```bash
curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <LITELLM_MASTER_KEY>" \
  -d '{
    "model": "my-smart-router",
    "messages": [{"role": "user", "content": "Hello"}],
    "temperature": 0.2
  }'
```

### Integration Tests
```bash
make test-integration
```

> Integration tests target the `LITELLM_URL` from `.env` (default: production Cloud Run), not localhost.

## Failover Behavior

| Scenario | Router Action |
|----------|---------------|
| vLLM responds successfully | Return response to client |
| vLLM timeout (3s) | Immediate fallback to Layer 2 (Groq/Gemini) |
| vLLM HTTP error | Count 1 fail → cooldown 45s → route to next available |
| Rate limit exceeded (Redis) | Route to next available model or return 429 |
| All layers fail | Return error (`hide_errors: true` masks internals) |

## Files

| File | Purpose |
|------|---------|
| `config.yaml` | LiteLLM router configuration (models, order, timeouts) |
| `Dockerfile` | Multi-stage build: Python builder → LiteLLM runtime |
| `pyproject.toml` | Redis dependency for rate limiting |
| `README.md` | This file |

## Known Considerations

- **Gemini model names**: `gemini-2.5-flash-lite` and `gemini-3.5-flash-lite` may not be valid public model IDs. Verify against LiteLLM provider docs before production use.
- **`num_retries: 0`**: No retry on transient vLLM errors. This prioritizes fast failover over retry reliability.
- **`VLLM_API_KEY`**: If your vLLM server does not require auth, set this to any non-empty value; LiteLLM still expects a key string.