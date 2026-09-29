FROM ghcr.io/berriai/litellm:v1.103.0

WORKDIR /app

# Salin file definisi dependensi terlebih dahulu (memanfaatkan Docker Layer Caching)
COPY pyproject.toml .

# Install dependensi pakai python internal absolut milik LiteLLM
RUN /usr/local/bin/python3 -m pip install --no-cache-dir .

# Salin file konfigurasi utama LiteLLM
COPY config.yaml .

# Cloud Run mendengarkan port secara dinamis, tapi kita kunci internal ke 4000
EXPOSE 8000

# Jalankan LiteLLM Proxy menggunakan paket yang sudah diinstal
# Jika $PORT kosong (misal saat dijalankan lokal), ia akan otomatis menggunakan port 4000.
CMD ["/bin/sh", "-c", "litellm --config config.yaml --host 0.0.0.0 --port ${PORT:-4000}"]
