# Operations & Troubleshooting

Runbook for operating the LLM Serving Gateway in production and local environments.

## Health Checks

### LiteLLM Proxy
```bash
curl http://localhost:4000/health/liveness
# Expected: HTTP 200
```

### Redis
```bash
redis-cli -u <REDIS_URL> PING
# Expected: PONG
```

### vLLM
```bash
curl http://<vm-ip>:8000/health
# Expected: HTTP 200
```

## Common Issues

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Gateway returns 502/504 | vLLM down or overloaded | Check vLLM health; failover should trigger to Groq/Gemini |
| `AuthenticationError` from Redis | Wrong password in `REDIS_URL` | Verify `.env` matches Redis instance credentials |
| `401 Unauthorized` on chat | Invalid `LITELLM_MASTER_KEY` | Ensure client sends `Authorization: Bearer <KEY>` |
| Prometheus can't scrape vLLM | vLLM not on same Docker network | Ensure `shared-monitor-network` exists and vLLM is attached |
| vLLM OOM (Out of Memory) | `max_num_seqs × max_model_len` too high | Reduce `max_num_seqs` or `max_model_len` in `docker-compose.yml` |
| Slow fallback latency | `num_retries: 0` + `cooldown_time: 45s` | Expected behavior; trade-off for fast failover |
| Cloud Run deployment fails | Missing Secret Manager secrets | Verify all 6 secrets exist in GCP Secret Manager |

## Failover Runbook

### Scenario: vLLM unresponsive
1. Check vLLM health: `curl http://<vm-ip>:8000/health`
2. If down, restart vLLM on GCE: `sudo docker restart vllm-server`
3. Monitor LiteLLM logs: `make dev-logs` (local) or Cloud Run logs (prod)
4. Verify fallback to Groq/Gemini is working via response headers (`x-litellm-model-id`)

### Scenario: Rate limit exceeded
1. Check Redis for rate limit counters
2. Wait for cooldown period (45s default) or increase RPM/TPM in `config.yaml`
3. Consider adding more fallback models in Layer 2

### Scenario: All layers fail
1. Check Redis connectivity
2. Check all API keys (Groq, Gemini) are valid and have quota
3. Review LiteLLM error logs (masked by `hide_errors: true`)

## Monitoring Checklist

- [ ] Prometheus is scraping vLLM `/metrics`
- [ ] Grafana dashboards are configured
- [ ] Alert rules are defined for: high latency, high error rate, GPU memory pressure
- [ ] Redis memory usage is monitored
- [ ] Cloud Run revision history is reviewed after each deploy

## Key Rotation

| Secret | Rotation Trigger | Process |
|--------|------------------|---------|
| `GROQ_API_KEY` | Quarterly or on compromise | Update in GCP Secret Manager; next Cloud Run deploy picks it up |
| `GEMINI_API_KEY_*` | Quarterly or on compromise | Same as above |
| `LITELLM_MASTER_KEY` | On compromise | Update in Secret Manager + all client apps; redeploy Cloud Run |
| `VLLM_API_KEY` | On compromise | Update in Secret Manager; restart vLLM on GCE |
| `REDIS_URL` password | On compromise | Update Redis instance + Secret Manager; restart all services |

## Maintenance Tasks

| Task | Frequency | Command |
|------|-----------|---------|
| Clean Docker volumes | Monthly | `docker volume prune` |
| Clean Python cache | Weekly | `make clean` |
| Review Cloud Run revisions | Monthly | GCP Console → Cloud Run |
| Update vLLM model | As needed | Edit `execute-vllm.sh` + redeploy |
| Rotate API keys | Quarterly | GCP Secret Manager |