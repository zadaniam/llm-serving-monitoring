#!/bin/bash

# ==============================================================================
# AUTOMATION SETUP GPU ENGINE FOR vLLM (PORTFOLIO VERSION)
# ==============================================================================
set -e

echo ">>> 1. Menginstal Docker Engine & Tools Utama"
sudo apt-get update -y
sudo apt-get install -y curl git docker.io docker-compose

echo ">>> 2. Menginstal Driver Resmi NVIDIA (Versi Stabil Headless)"
# Memasang driver server resmi dan utility pendukungnya
sudo apt-get install -y nvidia-headless-580 nvidia-utils-580

echo ">>> 3. Menginstal NVIDIA Container Toolkit (Agar Docker Bisa Membaca GPU)"
# Menambahkan repository resmi NVIDIA
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install Toolkit dan hubungkan ke Docker
sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-container-toolkit runtime configure --runtime=docker

echo ">>> 4. Menyiapkan Folder Aplikasi & Hak Akses CI/CD (KOREKSI BARU)"
# Membuat struktur folder deployment di direktori /opt
sudo mkdir -p /opt/llm-serving-monitoring/vllm
sudo mkdir -p /opt/llm-serving-monitoring/monitoring

# Mengubah hak kepemilikan folder ke user saat ini agar gcloud SCP tidak permission denied
sudo chown -R $USER:$USER /opt/llm-serving-monitoring

# Membuat folder cache huggingface agar tidak error saat volume mount
sudo mkdir -p /home/ubuntu/.cache/huggingface
sudo chmod -R 777 /home/ubuntu/.cache/huggingface

echo ">>> 5. Finalisasi Konfigurasi & Akses Docker Tanpa Sudo"
# Memasukkan user aktif ke grup docker agar tidak perlu mengetik 'sudo docker' terus
sudo usermod -aG docker $USER

# Restart Docker untuk menerapkan semua perubahan GPU runtime
sudo systemctl restart docker

echo "========================================================"
echo " SETUP SELESAI! SILAKAN REBOOT VM ATAU RE-LOGIN SSH Anda."
echo " Setelah itu, Anda bisa langsung menjalankan Docker Compose."
echo "========================================================"
