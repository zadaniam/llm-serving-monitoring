# ==============================================================================
# STAGE 1: Builder (Gunakan Python lengkap untuk compile & download package)
# ==============================================================================
FROM python:3.11-slim AS builder
WORKDIR /build

# Salin manifest dependensi Anda
COPY pyproject.toml .

# Unduh pustaka redis dan dependensinya ke dalam folder lokal khusus
RUN pip install --no-cache-dir --target=/build/third_party .

# ==============================================================================
# STAGE 2: Runtime (Gunakan base image resmi LiteLLM yang aman)
# ==============================================================================
FROM ghcr.io/berriai/litellm:v1.103.0

WORKDIR /app

# Salin folder dependensi pihak ketiga dari STAGE 1 ke jalur pustaka internal LiteLLM
COPY --from=builder /build/third_party /usr/local/lib/python3.11/site-packages/

# Salin file konfigurasi utama LiteLLM Anda
COPY config.yaml .

# Cloud Run mendengarkan port secara dinamis
EXPOSE 8080

# 1. Reset ENTRYPOINT bawaan agar tidak mengganggu perintah CMD
ENTRYPOINT []

# Jalankan LiteLLM Proxy bawaan dengan port dinamis dari Cloud Run
CMD litellm --config config.yaml --host 0.0.0.0 --port ${PORT:-4000}
