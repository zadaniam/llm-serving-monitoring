# Integration Tests

Pytest-based integration tests for the LLM Serving Gateway. These tests validate end-to-end connectivity and response quality through the gateway router.

## Files

| File | Purpose |
|------|---------|
| `test_proxy.py` | Gateway health check + chat completion validation |
| `test_redis.py` | Redis connectivity and authentication check |

## Test Coverage

| Test | What It Validates |
|------|-------------------|
| `test_gateway_health_ping` | LiteLLM `/health/liveness` returns HTTP 200 |
| `test_smart_router_chat_completion` | Gateway returns valid JSON response with non-empty content |
| `test_redis_connection` | Redis URL is valid and server responds to `PING` |

## Running Tests

```bash
# From project root
make test-integration

# Or directly
cd tests && uv run pytest integration/ -v -s
```

## Example Output

```
[INTEGRATION TEST] Direspon oleh backend model: vllm-local-primary
```

This shows which backend model (vLLM / Groq / Gemini) actually responded — useful for verifying failover behavior.

## Target Environment

Integration tests hit `LITELLM_URL` from `.env`. By default this points to **production Cloud Run**, not localhost. Ensure:
1. `LITELLM_URL` is set and reachable
2. `LITELLM_MASTER_KEY` is valid
3. Redis and vLLM are healthy