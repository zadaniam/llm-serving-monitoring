# LLM Serving Gateway

A hybrid, cloud-native LLM inference gateway built with **LiteLLM Proxy**, featuring intelligent failover, usage-based load balancing, and multi-layer routing between self-hosted **vLLM** and cloud providers (**Groq**, **Gemini**).

## Architecture

```text
┌─────────────┐      ┌─────────────────────────────────────┐
│   Client    │─────▶│   LiteLLM Proxy (Port 4000)         │
└─────────────┘      │                                       │
                     │  Layer 1: vLLM (Self-hosted, Order 1) │
                     │  Layer 2: Groq / Gemini (Fallback)    │
                     └─────────────┬───────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
        ┌─────────┐          ┌──────────┐        ┌──────────┐
        │  vLLM   │          │  Groq    │        │ Gemini   │
        │  L4 GPU │          │  Cloud   │        │  Cloud   │
        └─────────┘          └──────────┘        └──────────┘
```

## Quick Start

### Prerequisites
- Docker & Docker Compose v2
- External **Redis** server (not included in local compose)
- External **vLLM** inference server (not included in local compose)

### 1. Clone and configure
```bash
git clone <your-repo>
cd llm-serving-gateway
cp .env.example .env
```

Edit `.env` and fill in your actual credentials:
- `REDIS_URL` — Redis connection string
- `VLLM_API_BASE` — Your vLLM endpoint (e.g., `http://<vm-ip>:8000/v1`)
- `GROQ_API_KEY`, `GEMINI_KEY_3_5`, `GEMINI_KEY_2_5` — Cloud LLM API keys
- `LITELLM_MASTER_KEY` — Gateway authentication token

### 2. Start local environment
```bash
make dev-up
```

Services:
- **LiteLLM Proxy:** http://localhost:4000
- **Prometheus:** http://localhost:9090
- **Grafana:** http://localhost:3000

> ⚠️ Redis and vLLM must be running externally before `make dev-up`.

## Project Structure

```
llm-serving-gateway/
├── litellm-proxy/          # LiteLLM Proxy gateway (Dockerized)
├── vllm-gce/               # vLLM inference engine on GCE (GPU L4)
├── monitoring/             # Prometheus + Grafana stack
├── tests/                  # Integration & load testing
│   ├── integration/        # Pytest integration tests
│   └── performance/        # Locust load tests
├── docs/                   # Technical documentation
├── .github/workflows/      # GitHub Actions CI/CD (Cloud Run + GCE)
└── docker-compose.local.yml # Local development compose
```

## Key Features

- **Smart Failover:** Layer 1 (vLLM) → Layer 2 (Groq/Gemini) with usage-based load balancing
- **Rate Limiting:** RPM/TPM guards per model with Redis-backed cooldown
- **Multi-Cloud Backup:** Groq and Gemini as fallback clusters
- **Observability:** Prometheus metrics + Grafana dashboards
- **Secure by Design:** Master key auth, VPC private egress, GCP WIF for CI/CD
- **Load Testing:** Locust-based performance testing suite

## Available Commands

| Command | Description |
|---------|-------------|
| `make dev-up` | Build & start local dev environment |
| `make dev-down` | Stop and remove local containers |
| `make dev-logs` | Follow LiteLLM proxy logs |
| `make test-integration` | Run Pytest integration tests |
| `make test-load` | Run Locust load testing |
| `make clean` | Clean Python cache and venv |

## Documentation

| Document | Description |
|----------|-------------|
| `docs/architecture-design.md` | System architecture & data flow |
| `litellm-proxy/README.md` | Gateway configuration & router settings |
| `vllm-gce/README.md` | vLLM GPU setup & model configuration |
| `tests/README.md` | Integration & load testing guide |
| `monitoring/README.md` | Prometheus & Grafana setup |

## Security

- `.env` is gitignored — never commit real credentials
- Production secrets managed via GCP Secret Manager
- CI/CD authenticated via Workload Identity Federation (WIF)
- Cloud Run deployed with private VPC egress

## License

AGPL-3.0