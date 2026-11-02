# Performance Tests

Locust-based load testing suite for the LLM Serving Gateway and vLLM inference engine.

## Files

| File | Purpose |
|------|---------|
| `locustfile.py` | Locust user definition for vLLM load testing |
| `test_bot.py` | Interactive bot script for manual gateway testing |

## Locust Load Test (`locustfile.py`)

Simulates concurrent users sending chat completion requests to vLLM.

### Configuration

Edit environment variables in `.env` or modify the file directly:

| Variable | Description |
|----------|-------------|
| `MODEL_NAME` | Model name to test (e.g., `qwen-2.5-14b-awq`) |
| `VLLM_API_KEY` | vLLM API key |
| `PROMPT_CONTENT` | Prompt text sent in each request |
| `MAX_TOKENS` | Max tokens per response |
| `TEMPERATURE` | Sampling temperature |
| `STREAM_MODE` | Enable/disable streaming |

### Running Locust

```bash
# From project root
make test-load

# Or directly
cd tests/performance && uv run locust -f locustfile.py
```

Then open **http://localhost:8089** in your browser to configure user count and spawn rate.

## Interactive Bot (`test_bot.py`)

Manual CLI bot for testing the gateway through the LiteLLM proxy.

### Running

```bash
# From project root
make run-bot

# Or directly
uv run --env-file .env tests/performance/test_bot.py
```

The bot will prompt you for input and display:
- AI response text
- Actual model that responded (via `x-litellm-model-id` header)
- Request latency

## ⚠️ Target Endpoints

| Test File | Target Endpoint |
|-----------|-----------------|
| `locustfile.py` | vLLM directly (`/v1/chat/completions`) |
| `test_bot.py` | LiteLLM Proxy (`LITELLM_URL/v1/chat/completions`) |

Ensure the target service is running before executing tests.