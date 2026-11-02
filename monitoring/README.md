# Monitoring — Prometheus & Grafana

Observability stack for the LLM Serving Gateway. Scrapes metrics from vLLM and LiteLLM Proxy, visualized in Grafana dashboards.

## Purpose

- **Prometheus:** Collects and stores time-series metrics from vLLM (`/metrics` endpoint) and LiteLLM Proxy
- **Grafana:** Visualizes metrics via dashboards for latency, token throughput, error rates, and GPU utilization

## Structure

```
monitoring/
├── docker-compose.yml    # Prometheus + Grafana service definitions
├── prometheus.yml        # Prometheus scrape configuration
└── README.md             # This file
```

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| Prometheus | `prom/prometheus:v3.15.0` | 9090 | Metrics collection & storage |
| Grafana | `grafana/grafana:13.2.2` | 3000 | Metrics visualization |

## Prometheus Configuration (`prometheus.yml`)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'vllm-metrics'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['vllm-server:8000']
```

| Setting | Value | Meaning |
|---------|-------|---------|
| `scrape_interval` | 15s | How often Prometheus scrapes targets |
| `evaluation_interval` | 15s | How often alert rules are evaluated |
| `metrics_path` | `/metrics` | vLLM Prometheus metrics endpoint |
| `targets` | `vllm-server:8000` | vLLM container hostname on shared network |

## Network

Both services run on the **external** Docker network `shared-monitor-network`, which is also used by vLLM. This allows Prometheus to scrape vLLM via container name (`vllm-server:8000`).

## Running Locally

```bash
# From project root
cd monitoring
docker compose up -d

# Access
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000
```

> ⚠️ The `shared-monitor-network` must exist before starting. Create it with:
> ```bash
> docker network create shared-monitor-network
> ```

## What to Monitor

| Metric | Source | What It Tells You |
|--------|--------|-------------------|
| `vllm:gpu_utilization` | vLLM | GPU load percentage |
| `vllm:kv_cache_usage` | vLLM | KV cache memory usage |
| `vllm:request_latency` | vLLM | Time to first token / per-token latency |
| `litellm:request_count` | LiteLLM | Total requests routed |
| `litellm:fallback_count` | LiteLLM | Number of fallbacks to Layer 2 |
| `litellm:rate_limit_hits` | LiteLLM | Redis-enforced rate limit rejections |

## Environment Variables

No runtime environment variables required for the monitoring stack itself. Configuration is file-based (`prometheus.yml`).

## Related Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Prometheus + Grafana service definitions with persistent volumes |
| `prometheus.yml` | Scrape targets and collection intervals |

## ⚠️ Known Considerations

- **Local Dev Gap:** In `docker-compose.local.yml`, Prometheus targets `vllm-server:8000`, but vLLM is **not** part of the local compose stack — it runs externally on GCE. Prometheus will not be able to scrape vLLM in a purely local environment unless vLLM is reachable from the Docker network.
- **Persistent Storage:** Grafana data is persisted via named volume (`grafana-storage`). Prometheus data is persisted via named volume (`prometheus-storage` in the standalone monitoring compose).
- **Dashboard Setup:** Grafana dashboards are not pre-configured in this repo. You will need to add Prometheus as a data source and create dashboards manually in the Grafana UI.