# Tests — Integration & Load Testing

Testing suite for the LLM Serving Gateway, covering **integration tests** (Pytest) and **load tests** (Locust).

## Structure

```
tests/
├── integration/          # Pytest integration tests
│   ├── test_proxy.py     # Gateway health + chat completion tests
│   ├── test_redis.py     # Redis connectivity tests
│   └── README.md         # Integration test guide
├── performance/          # Locust load tests
│   ├── locustfile.py     # vLLM load test user
│   ├── test_bot.py       # Interactive bot test script
│   └── README.md         # Load testing guide
├── pyproject.toml        # Test dependencies (pytest, locust, redis, requests)
└── uv.lock               # Locked dependencies
```

## Quick Start

### Install dependencies
```bash
cd tests
uv sync
```

### Run integration tests
```bash
uv run pytest integration/ -v -s
```

### Run load tests
```bash
cd performance
uv run locust -f locustfile.py
# Open http://localhost:8089 in browser
```

## Environment Variables

Tests require a `.env` file at the project root with the following variables:

| Variable | Purpose |
|----------|---------|
| `LITELLM_URL` | Gateway endpoint (e.g., Cloud Run URL or localhost) |
| `LITELLM_MASTER_KEY` | Gateway authentication token |
| `REDIS_URL` | Redis connection string |
| `VLLM_API_KEY` | vLLM API key (for load tests) |
| `MODEL_NAME` | Model name for load test payload |

## Available Commands (from project root)

| Command | Description |
|---------|-------------|
| `make install-dev` | Install test dependencies via uv |
| `make test-integration` | Run Pytest integration tests |
| `make test-load` | Run Locust load testing |
| `make run-bot` | Run interactive bot test script |

## ⚠️ Important Notes

- **Integration tests target `LITELLM_URL`** from `.env`, which defaults to the production Cloud Run endpoint — not localhost.
- **Redis and vLLM must be running** before integration tests can pass.
- Load tests hit the vLLM endpoint directly, not through the LiteLLM proxy (see `tests/performance/locustfile.py`).