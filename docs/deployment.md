# Deployment Guide

CI/CD and production deployment for the LLM Serving Gateway on Google Cloud Platform (GCP).

## Overview

| Component | Target | Trigger |
|-----------|--------|---------|
| LiteLLM Proxy | Cloud Run | Push to `main` (path: `litellm-proxy/**`) |
| vLLM Inference | GCE VM | Push to `main` (path: `vllm-gce/**`) |
| Monitoring (Prometheus + Grafana) | GCE VM | Push to `main` (path: `monitoring/**`) |

All deployments use **Workload Identity Federation (WIF)** — no long-lived service account keys stored in GitHub secrets.

## Authentication (WIF)

GitHub Actions authenticates to GCP via OIDC / Workload Identity Federation:

```
GitHub Actions → OIDC Token → GCP Workload Identity Pool → Service Account → GCP Resources
```

Service accounts used:
- `litellm-deployer@<PROJECT_ID>.iam.gserviceaccount.com` — Cloud Run deployments
- `vllm-deployer@<PROJECT_ID>.iam.gserviceaccount.com` — GCE VM operations

Required GitHub repository variables (Settings → Secrets and variables → Actions → Variables):

| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECT_ID` | GCP project number | `352692367446` |
| `PROJECT_ID_STRING` | GCP project ID string | `project-0cb13828-a08a-466a-934` |
| `REGION` | GCP region | `asia-southeast1` |
| `GAR_REPO` | Artifact Registry repository name | `llm-serving-monitoring` |
| `WIF_PROVIDER` | Workload Identity Provider full path | `projects/.../locations/global/workloadIdentityPools/github-pool-v2/providers/github-provider-v2` |
| `GCE_VM_NAME` | Target GCE VM name | `vllm-serving` |
| `GCE_VM_ZONE` | GCE VM zone | `asia-southeast1-a` |

Required GCP Secret Manager secrets (referenced in workflows):

| Secret Name | Description |
|-------------|-------------|
| `VLLM_API_KEY` | vLLM server authentication key |
| `GROQ_API_KEY` | Groq cloud API key |
| `GEMINI_API_KEY_3_5` | Gemini cloud API key (backup) |
| `GEMINI_API_KEY_2_5` | Gemini cloud API key (backup) |
| `REDIS_URL` | Redis connection string |
| `LITELLM_MASTER_KEY` | Gateway bearer token |

## Workflow 1: Deploy LiteLLM to Cloud Run

**File:** `.github/workflows/deploy-litellm.yml`  
**Trigger:** Push to `main` when `litellm-proxy/**` or the workflow file changes

### Steps

1. **Checkout code** — `actions/checkout@v4`
2. **Authenticate to GCP** — WIF via `google-github-actions/auth@v2`
3. **Setup Cloud SDK** — `google-github-actions/setup-gcloud@v2`
4. **Setup Docker Buildx** — `docker/setup-buildx-action@v3`
5. **Configure Docker for Artifact Registry** — `gcloud auth configure-docker`
6. **Build and push image** — `docker/build-push-action@v6` to `REGION-docker.pkg.dev/PROJECT_ID/GAR_REPO/litellm:<SHA>`
7. **Deploy to Cloud Run** — `google-github-actions/deploy-cloudrun@v2`

### Cloud Run Configuration

| Setting | Value |
|---------|-------|
| Service name | `litellm-vllm` |
| Region | `${REGION}` (asia-southeast1) |
| Image | `REGION-docker.pkg.dev/PROJECT_ID/GAR_REPO/litellm:<SHA>` |
| Network | `default` subnet |
| VPC Egress | `private-ranges-only` |
| Auth | `--allow-unauthenticated` |
| Env vars | `LITELLM_MODE=production`, `VLLM_API_BASE` |
| Secrets | Injected from GCP Secret Manager (latest version) |

## Workflow 2: Sync vLLM Config to GCE

**File:** `.github/workflows/deploy-vllm.yml`  
**Trigger:** Push to `main` when `vllm-gce/**` or the workflow file changes

### Steps

1. **Checkout code**
2. **Authenticate to GCP** — WIF
3. **Setup Cloud SDK**
4. **Sync docker-compose.yml** — `gcloud compute scp` to VM at `/opt/llm-serving-monitoring/vllm/`
5. **Tunnel:** IAP Tunnel (`--tunnel-through-iap`)

> ⚠️ This workflow only copies the compose file. The VM must already have Docker, NVIDIA drivers, and container toolkit installed (via `setup-gpu.sh`). The `execute-vllm.sh` script handles the actual `docker compose up`.

## Workflow 3: Deploy Monitoring to GCE

**File:** `.github/workflows/deploy-monitoring.yml`  
**Trigger:** Push to `main` when `monitoring/**` or the workflow file changes

### Steps

1. **Checkout code**
2. **Authenticate to GCP** — WIF
3. **Setup Cloud SDK**
4. **Copy monitoring files** — `gcloud compute scp --recurse monitoring/` to VM at `/opt/llm-serving-monitoring/monitoring/`
5. **Restart monitoring** — SSH via IAP Tunnel, create `shared-monitor-network`, run `docker compose up -d --remove-orphans`

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Google Cloud Platform                   │
│                                                             │
│  ┌──────────────┐    VPC Private Egress    ┌────────────┐  │
│  │  Cloud Run   │─────────────────────────▶│   GCE VM   │  │
│  │  (LiteLLM)   │    (private-ranges-only) │  (vLLM)    │  │
│  └──────────────┘                          └────────────┘  │
│         │                                               │   │
│         │                                               │   │
│         ▼                                               ▼   │
│  ┌──────────────┐                              ┌────────────┐ │
│  │ Secret Mgr   │                              │ Prometheus │ │
│  │   (secrets)  │                              │  (Grafana) │ │
│  └──────────────┘                              └────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Artifact Registry

| Setting | Value |
|---------|-------|
| Repository | `llm-serving-monitoring` |
| Location | `asia-southeast1` |
| Format | Docker |
| Image path | `asia-southeast1-docker.pkg.dev/352692367446/llm-serving-monitoring/litellm` |

## Security Model

| Layer | Mechanism |
|-------|-----------|
| CI/CD Auth | Workload Identity Federation (OIDC, no long-lived keys) |
| Container Registry | Artifact Registry with IAM bindings |
| Cloud Run | VPC private egress, `--allow-unauthenticated` (gateway auth via master key) |
| GCE VM | IAP Tunnel for SSH/SCP (no public SSH exposure) |
| Secrets | GCP Secret Manager, injected at runtime |
| Network | `shared-monitor-network` for monitoring + vLLM communication |

## Manual Deployment (vLLM on GCE)

If you need to deploy vLLM manually without CI/CD:

```bash
# 1. SSH to VM and pull secrets
gcloud compute ssh vllm-serving --zone=asia-southeast1-a --tunnel-through-iap

# 2. On the VM
cd /opt/llm-serving-monitoring/vllm
echo "HF_TOKEN=$(gcloud secrets versions access latest --secret=HF_TOKEN)" > .env
echo "VLLM_API_KEY=$(gcloud secrets versions access latest --secret=VLLM_API_KEY)" >> .env
echo "MODEL_NAME=qwen-2.5-14b-awq" >> .env

# 3. Ensure network exists
sudo docker network inspect shared-monitor-network >/dev/null 2>&1 || \
  sudo docker network create shared-monitor-network

# 4. Start vLLM
sudo docker compose up -d --remove-orphans
```

## Related Files

| File | Purpose |
|------|---------|
| `.github/workflows/deploy-litellm.yml` | Cloud Run CI/CD pipeline |
| `.github/workflows/deploy-vllm.yml` | GCE vLLM config sync |
| `.github/workflows/deploy-monitoring.yml` | GCE monitoring deploy |
| `litellm-proxy/Dockerfile` | Multi-stage LiteLLM Docker build |
| `litellm-proxy/config.yaml` | Router configuration (injected at runtime) |
| `vllm-gce/docker-compose.yml` | vLLM service on GCE |
| `monitoring/docker-compose.yml` | Prometheus + Grafana on GCE |
| `.env.prod` | Production environment template |

## Related Documentation

- [`docs/architecture-design.md`](architecture-design.md) — System architecture & data flow
- [`docs/local-development.md`](local-development.md) — Local development setup