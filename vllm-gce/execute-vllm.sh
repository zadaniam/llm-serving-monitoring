#!/bin/bash
# ==============================================================================
# Title:        execute-vllm.sh
# Description:  Manual script to safely control and update vLLM on GCE.
# Automation:   Orchestrates environment provisioning via IAP tunnel.
# ==============================================================================

# Exit immediately if any command returns a non-zero status
set -e

# --- GCE Target VM Configuration ---
VM_NAME="vllm-serving"
ZONE="asia-southeast1-a"

# --- Google Secret Manager Configuration ---
SECRET_HF_TOKEN="HF_TOKEN"
SECRET_VLLM_KEY="VLLM_API_KEY"

# --- Model & Runtime Configuration ---
MODEL_NAME="qwen-2.5-14b-awq"

echo "[INFO] Pushing automation state to GCE instance: $VM_NAME"
echo "--------------------------------------------------------"

echo "--> Connecting via IAP tunnel..."
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --quiet \
  --command="
    cd /opt/llm-serving-monitoring/vllm/

    echo '--> Pulling secrets from Google Secret Manager to internal .env file...'
    echo \"HF_TOKEN=\$(gcloud secrets versions access latest --secret=$SECRET_HF_TOKEN)\" > .env
    echo \"VLLM_API_KEY=\$(gcloud secrets versions access latest --secret=$SECRET_VLLM_KEY)\" >> .env
    echo \"MODEL_NAME=$MODEL_NAME\" >> .env

    echo '--> Validating Custom Docker Network...'
    sudo docker network inspect shared-monitor-network >/dev/null 2>&1 || sudo docker network create shared-monitor-network

    echo '--> Running Docker Compose (vLLM Engine)...'
    sudo docker compose up -d --remove-orphans
"

echo "--> Deployment signal acknowledged."
echo "[NOTE] Model allocation onto L4 VRAM takes 3-7 minutes."
echo "--> To stream runtime container logs, execute:"
echo "    gcloud compute ssh $VM_NAME --zone=$ZONE --tunnel-through-iap --command=\"docker logs -f vllm-server\""
