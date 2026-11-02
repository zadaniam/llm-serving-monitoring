# Local Development Guide

Step-by-step guide to running the LLM Serving Gateway locally with Docker Compose.

## Prerequisites

Before starting, ensure the following are installed and running:

| Requirement | Version | Purpose |
|-------------|---------|---------|
| Docker | 20.10+ | Container runtime |
| Docker Compose | v2+ | Multi-container orchestration |
| Redis Server | 6+ | External rate limiting & router state |
| vLLM Inference Server | v0.30.0+ | External Layer 1 model endpoint |

> ⚠️ **Redis and vLLM are NOT included** in `docker-compose.local.yml`. They must be running externally before starting the gateway.

## Step 1: Clone the Repository

```bash
git clone <your-repo>
cd llm-serving-gateway
```

## Step 2: Configure Environment

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```ini
# Required: External Redis
REDIS_URL="redis://<host>:6379/0"

# Required: External vLLM endpoint
VLLM_API_BASE="http://<vm-ip>:8000/v1"

# Required: Cloud LLM API keys
GROQ_API_KEY="your_groq_api_key"
GEMINI_KEY_3_5="your_gemini_api_key"
GEMINI_KEY_2_5="your_gemini_api_key"

# Required: Gateway authentication
LITELLM_MASTER_KEY="your_master_key"

# Optional: vLLM (if vLLM server requires auth)
VLLM_API_KEY="your_vllm_api_key"
```

| Variable | Required | Description |
|----------|----------|-------------|
| `REDIS_URL` | Yes | Redis connection string |
| `VLLM_API_BASE` | Yes | vLLM endpoint (e.g., `http://localhost:8000/v1`) |
| `GROQ_API_KEY` | Yes | Groq cloud API key |
| `GEMINI_KEY_3_5` | Yes | Gemini cloud API key (backup) |
| `GEMINI_KEY_2_5` | Yes | Gemini cloud API key (backup) |
| `LITELLM_MASTER_KEY` | Yes | Gateway bearer token |
| `VLLM_API_KEY` | No | vLLM server auth key (if required) |

> `.env` is gitignored. Never commit real credentials to version control.

## Step 3: Start the Local Stack

```bash
# Build the LiteLLM Docker image
make docker-build

# Start all services (LiteLLM + Prometheus + Grafana)
make dev-up
```

Services will be available at:

| Service | URL |
|---------|-----|
| LiteLLM Proxy | http://localhost:4000 |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 |

## Step 4: Verify the Gateway

### Health Check
```bash
curl http://localhost:4000/health/liveness
```
Expected: HTTP 200

### Chat Completion
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
Expected: HTTP 200 with valid JSON response containing `choices`.

## Available Make Commands

| Command | Description |
|---------|-------------|
| `make dev-up` | Build image & start local stack |
| `make dev-down` | Stop and remove all containers |
| `make dev-logs` | Follow LiteLLM proxy logs in real-time |
| `make docker-build` | Build LiteLLM Docker image only |
| `make test-integration` | Run Pytest integration tests |
| `make test-load` | Run Locust load testing |
| `make run-bot` | Run interactive bot test script |
| `make clean` | Clean Python cache, Docker volumes, and venv |

## Running Tests

### Integration Tests (Pytest)
```bash
make test-integration
```
> Targets `LITELLM_URL` from `.env`. Default points to production Cloud Run, not localhost.

### Load Tests (Locust)
```bash
make test-load
```
Open http://localhost:8089 in your browser to configure users and spawn rate.

## Stopping the Stack

```bash
make dev-down
```

This stops and removes all containers defined in `docker-compose.local.yml`.

## Cleanup

```bash
make clean
```
Removes `__pycache__`, `.pytest_cache`, and `tests/.venv`.

## Troubleshooting

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| `Connection refused` on port 4000 | Container not started | Run `make dev-up` and check `docker ps` |
| `AuthenticationError` from Redis | Wrong `REDIS_URL` or password | Verify `.env` credentials |
| `Timeout` on vLLM requests | vLLM server not reachable | Confirm `VLLM_API_BASE` is accessible from Docker network |
| `401 Unauthorized` on chat | Wrong `LITELLM_MASTER_KEY` | Verify master key matches `.env` |
| Prometheus can't scrape vLLM | vLLM not on Docker network | vLLM runs externally; ensure network reachability |

## Files Involved

| File | Purpose |
|------|---------|
| `docker-compose.local.yml` | Local Docker Compose stack definition |
| `.env.example` | Template for environment variables |
| `.env` | Your local environment variables (gitignored) |
| `litellm-proxy/config.yaml` | LiteLLM router configuration |
| `Makefile` | Development commands |
| `tests/` | Integration and load test suites |

## Related Documentation

- [`docs/architecture-design.md`](architecture-design.md) — System architecture & data flow
- [`litellm-proxy/README.md`](../../litellm-proxy/README.md) — Gateway router configuration
- [`tests/README.md`](../../tests/README.md) — Testing guide