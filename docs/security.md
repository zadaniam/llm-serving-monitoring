# Security Model

Security architecture and best practices for the LLM Serving Gateway.

## Authentication

| Layer | Mechanism | Details |
|-------|-----------|---------|
| Client → Gateway | Bearer Token | `Authorization: Bearer <LITELLM_MASTER_KEY>` required on all requests |
| Gateway → vLLM | API Key | `VLLM_API_KEY` passed in request headers |
| Gateway → Groq/Gemini | API Key | Provider API keys from environment variables |
| CI/CD → GCP | Workload Identity Federation | OIDC-based, no long-lived service account keys |

## Secret Management

| Secret | Storage | Injection Method |
|--------|---------|------------------|
| `REDIS_URL` | GCP Secret Manager | Cloud Run env var (latest version) |
| `GROQ_API_KEY` | GCP Secret Manager | Cloud Run env var (latest version) |
| `GEMINI_API_KEY_*` | GCP Secret Manager | Cloud Run env var (latest version) |
| `LITELLM_MASTER_KEY` | GCP Secret Manager | Cloud Run env var (latest version) |
| `VLLM_API_KEY` | GCP Secret Manager | Injected into vLLM `.env` on GCE VM |
| `HF_TOKEN` | GCP Secret Manager | Injected into vLLM `.env` on GCE VM |

### `.env` Rules (Local Development)

- `.env` is **gitignored** — never commit it
- Copy from `.env.example` and fill in locally
- Use different values for local vs production
- Rotate immediately if accidentally exposed

## Network Security

| Component | Configuration |
|-----------|---------------|
| Cloud Run (LiteLLM) | VPC private egress (`private-ranges-only`), `--allow-unauthenticated` |
| GCE VM (vLLM) | Accessible only via IAP Tunnel (no public SSH) |
| Docker Network | `shared-monitor-network` (external, shared between vLLM + monitoring) |
| Redis | External instance (Google Memorystore or Redis Labs) with firewall rules |

## Runtime Protections

| Protection | Implementation |
|------------|----------------|
| Error masking | `hide_errors: true` in `config.yaml` masks internal error details |
| Rate limiting | Redis-backed RPM/TPM enforcement per model |
| Cooldown | 45s cooldown after model failure (`allowed_fails: 1`) |
| No retry | `num_retries: 0` — fast failover instead of retry loops |
| Concurrency guard | `max_parallel_requests: 10` on vLLM layer |

## Key Rotation Procedure

1. Generate new key in provider console (Groq/Gemini/Redis)
2. Update secret in GCP Secret Manager (create new version)
3. For Cloud Run: trigger new deployment (picks up latest secret version)
4. For GCE VM: SSH via IAP Tunnel, update `.env`, restart vLLM container
5. Verify services are healthy after rotation
6. Revoke old key if possible

## ⚠️ Known Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `.env` committed to git | High | `.gitignore` includes `.env`; pre-commit hooks recommended |
| Master key leaked | High | Rotate immediately; update all client applications |
| vLLM `VLLM_API_KEY` is placeholder | Medium | Verify vLLM server actually requires auth; set real key if needed |
| Public Cloud Run endpoint | Medium | Authenticated via master key; VPC private egress limits egress traffic |
| No SSL/TLS termination docs | Low | Cloud Run handles TLS automatically; local dev is HTTP only |

## 🔗 Related Documentation

- [`docs/architecture-design.md`](architecture-design.md) — System architecture & data flow
- [`docs/deployment.md`](deployment.md) — CI/CD & production deployment
- [`docs/operations.md`](operations.md) — Operations & troubleshooting