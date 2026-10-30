# vLLM Inference Engine — Layer 1

Self-hosted vLLM inference server deployed on Google Compute Engine (GCE) with NVIDIA L4 GPU. Serves as the **primary (Order 1)** model layer in the LLM Serving Gateway.

## Purpose

- Hosts Qwen2.5-14B-Instruct-AWQ (4-bit quantized) for cost-effective, low-latency inference
- Acts as Layer 1 in the smart failover chain: vLLM → Groq → Gemini
- Exposes OpenAI-compatible API at port 8000

## Structure

```
vllm-gce/
├── docker-compose.yml    # vLLM service definition (GPU, network, env)
├── execute-vllm.sh       # Manual deployment script to GCE VM
├── setup-gpu.sh          # One-time GPU driver & Docker setup for VM
└── README.md             # This file
```

## Hardware

| Component | Specification |
|-----------|---------------|
| GPU | NVIDIA L4 (24 GB VRAM) |
| VM | Google Compute Engine (GCE) |
| Zone | `asia-southeast1-a` |
| Container | `vllm/vllm-openai:v0.30.0` (CUDA 13.0) |

## Model Configuration

| Parameter | Value |
|-----------|-------|
| Model | `Qwen/Qwen2.5-14B-Instruct-AWQ` |
| Quantization | AWQ (4-bit) |
| Served model name | `${MODEL_NAME}` (env var) |
| GPU memory utilization | 0.90 |
| Max model length | 512 tokens |
| Max concurrent sequences | 256 |
| Prefix caching | Enabled |
| API key | `${VLLM_API_KEY}` |

## Deployment

### 1. One-time VM Setup (setup-gpu.sh)

Run this once on a fresh GCE VM to install Docker, NVIDIA drivers, and container toolkit:

```bash
# On the GCE VM
bash setup-gpu.sh
# Reboot or re-login after completion
```

### 2. Deploy vLLM (execute-vllm.sh)

Deploys vLLM to the GCE VM via SSH through IAP Tunnel:

```bash
# From your local machine
bash execute-vllm.sh
```

This script:
1. SSHs into the VM via IAP Tunnel
2. Pulls HF_TOKEN and VLLM_API_KEY from GCP Secret Manager
3. Ensures `shared-monitor-network` Docker network exists
4. Starts vLLM with `docker compose up -d`

### 3. CI/CD Sync (deploy-vllm.yml)

GitHub Actions workflow triggers on push to `main` when `vllm-gce/**` changes. It copies `docker-compose.yml` to the VM via `gcloud compute scp`.

## Network

- **Port:** 8000 (mapped `8000:8000`)
- **Docker Network:** `shared-monitor-network` (external, shared with Prometheus)
- **Access:** vLLM is reachable by LiteLLM Proxy via `VLLM_API_BASE`

## Environment Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `HF_TOKEN` | GCP Secret Manager | Hugging Face token for model access |
| `VLLM_API_KEY` | GCP Secret Manager | API key for vLLM server authentication |
| `MODEL_NAME` | `execute-vllm.sh` | Served model name override |

## Memory & Capacity Planning

Based on NVIDIA L4 (24 GB VRAM) with `gpu_memory_utilization = 0.90`:

| Item | Allocation |
|------|------------|
| Total usable VRAM | ~21.6 GB |
| Model weights (Qwen 14B AWQ) | ~7–8 GB |
| System & CUDA overhead | ~1.5 GB |
| Available for KV cache | ~12–13 GB |

**Constraint:** `max_num_seqs × max_model_len` must not exceed total KV cache token capacity (~250K tokens for 14B model).

Current config: `256 seqs × 512 tokens = 131,072 tokens` — within safe limits.

> ⚠️ If you change `max_model_len` or `max_num_seqs`, recalculate to avoid OOM (Out of Memory).

## Related Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | vLLM service with GPU reservation, env, volumes |
| `execute-vllm.sh` | Manual deploy script (SSH + Secret Manager) |
| `setup-gpu.sh` | VM provisioning: Docker, NVIDIA drivers, toolkit |

## ⚠️ Known Considerations

- **Documentation mismatch:** Older notes reference Qwen-2.5-7B, but the active deployment uses Qwen2.5-14B-Instruct-AWQ. Memory calculations should be based on 14B.
- **`VLLM_API_KEY`:** If your vLLM server does not require auth, set any non-empty string; LiteLLM still expects a key value.
- **Model load time:** 3–7 minutes to download and load Qwen 14B into VRAM on first start.