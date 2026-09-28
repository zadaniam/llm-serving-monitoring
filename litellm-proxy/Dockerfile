FROM python:3.12-slim

WORKDIR /app

# Salin file definisi dependensi terlebih dahulu (memanfaatkan Docker Layer Caching)
COPY pyproject.toml .

# Install dependensi langsung di dalam kontainer
RUN pip install --no-cache-dir .

# Salin file konfigurasi utama LiteLLM
COPY config.yaml .

# Cloud Run mendengarkan port secara dinamis, tapi kita kunci internal ke 4000
EXPOSE 8000

# Jalankan LiteLLM Proxy menggunakan paket yang sudah diinstal
# Jika $PORT kosong (misal saat dijalankan lokal), ia akan otomatis menggunakan port 4000.
CMD litellm --config config.yaml --host 0.0.0.0 --port ${PORT:-4000}
