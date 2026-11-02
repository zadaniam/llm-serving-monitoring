#!/bin/bash
# ==============================================================================
# Title:        setup-gpu.sh
# Description:  Automation script to provision GPU drivers and runtime for vLLM.
# Target OS:    Ubuntu Enterprise Server (Headless VM Architecture).
# ==============================================================================

# Exit immediately if any command returns a non-zero status
set -e

echo "--> Installing Docker Engine and core core utilities..."
sudo apt-get update -y
sudo apt-get install -y curl git docker.io docker-compose-v2

echo "--> Installing official NVIDIA Headless Driver and runtime utilities..."
# Install official server driver and supporting utilities
sudo apt-get install -y nvidia-headless-580 nvidia-utils-580

echo "--> Configuring NVIDIA Container Toolkit repository..."
# Add official NVIDIA repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

echo "--> Installing toolkit components and registering Docker runtime..."
# Install Toolkit and connect to Docker
sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-container-toolkit runtime configure --runtime=docker

echo "--> Creating workspace directories and aligning permission boundaries..."
# Create deployment folder structure in /opt directory
sudo mkdir -p /opt/llm-serving-monitoring/vllm
sudo mkdir -p /opt/llm-serving-monitoring/monitoring

# Change folder ownership to current user so gcloud SCP does not get permission denied
sudo chown -R $USER:$USER /opt/llm-serving-monitoring

# Create huggingface cache folder to avoid errors during volume mount
sudo mkdir -p /home/ubuntu/.cache/huggingface
sudo chmod -R 777 /home/ubuntu/.cache/huggingface

echo "--> Granting rootless Docker permissions and reloading daemon..."
# Add current user to docker group so you don't have to type 'sudo docker' repeatedly
sudo usermod -aG docker $USER

# Restart Docker to apply all GPU runtime changes
sudo systemctl restart docker

echo "--> Setup orchestration completed successfully."
echo "[NOTE] You must reboot the VM instance or re-authenticate the SSH session"
echo "       for the user group privileges and GPU environment hooks to take effect."
