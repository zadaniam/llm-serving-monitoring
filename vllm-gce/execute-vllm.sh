#!/bin/bash
# Skrip Manual untuk Mengontrol & Update vLLM di GCE secara aman

set -e

# Konfigurasi Variabel Target GCE
VM_NAME="vllm-serving"
ZONE="asia-southeast1-a"

# Definisi nama Secret di Google Secret Manager (Sesuaikan dengan nama di GCP Anda)
SECRET_HF_TOKEN="HF_TOKEN"
SECRET_VLLM_KEY="VLLM_API_KEY"

# Variabel non-rahasia (Bisa diubah langsung di sini)
MODEL_NAME="qwen-2.5-14b-awq"

echo "=========================================================="
echo " 🚀 MEMULAI EKSEKUSI MANAJEMEN vLLM PADA VM: $VM_NAME"
echo "=========================================================="

echo ">>> 1. Menghubungkan ke VM via SSH untuk setup environment..."
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --quiet \
  --command="
    cd /opt/llm-serving-monitoring/vllm/

    echo '>>> 2. Menarik rahasia dari Google Secret Manager ke file .env internal...'
    echo \"HF_TOKEN=\$(gcloud secrets versions access latest --secret=$SECRET_HF_TOKEN)\" > .env
    echo \"VLLM_API_KEY=\$(gcloud secrets versions access latest --secret=$SECRET_VLLM_KEY)\" >> .env
    echo \"MODEL_NAME=$MODEL_NAME\" >> .env

    echo '>>> 3. Validasi Docker Network Kustom...'
    docker network inspect shared-monitor-network >/dev/null 2>&1 || docker network create shared-monitor-network

    echo '>>> 4. Menjalankan Docker Compose (vLLM Engine)...'
    docker compose up -d --remove-orphans
"

echo "=========================================================="
echo " PROSES DEPLOYMENT MANUAL DIKIRIM DENGAN SUKSES!"
echo "=========================================================="
echo " Perlu diingat: vLLM membutuhkan waktu sekitar 3-7 menit"
echo " untuk mengunduh/memuat model Qwen ke dalam VRAM GPU L4."
echo ""
echo " Untuk memantau log proses pemuatan model, jalankan perintah ini:"
echo " gcloud compute ssh $VM_NAME --zone=$ZONE --tunnel-through-iap --command=\"docker logs -f vllm-server\""
echo "=========================================================="
