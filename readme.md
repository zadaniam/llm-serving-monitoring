## 📋 Prasyarat Infrastruktur

Proyek `docker-compose.local.yml` ini hanya menyalakan komponen **Gateway Router (LiteLLM Proxy)** dan **Monitoring (Prometheus & Grafana)**. 

Untuk dapat berfungsi dengan benar, komponen di bawah ini **tidak termasuk** di dalam Docker Compose lokal dan harus sudah menyala terlebih dahulu secara terpisah:

1. **Redis Server:** Pastikan URL koneksi sudah dikonfigurasi di file `.env` pada variabel `REDIS_URL` (misal: `redis://localhost:6379`).
2. **vLLM Engine Server:** Server inferensi model harus sudah aktif dan alamat jalurnya diisi pada variabel `VLLM_API_BASE` (misal: `http://localhost:8000/v1`).

Pastikan Anda sudah menyalin file `.env.example` menjadi `.env` dan mengisi seluruh API Key yang dibutuhkan sebelum menjalankan aplikasi.



## Still Notes

LiteLLM

1. Failover/Fallback by Order (Priority)
2. Load balancing after Failover (usage based by tpm rpm)
3. timeout &

Security:

- Isolated network with Direct VPC Egress to close the public IP
- Deployment dengan gcp auth WIF (OIDC)
