LiteLLM

1. Failover/Fallback by Order (Priority)
2. Load balancing after Failover (usage based by tpm rpm)
3. timeout &

Fitur utama:
------------

Deployment dengan gcp auth WIF (OIDC) untuk security

hybrid-llm-router/ (Root Monorepo)
├── .github/workflows/         # Opsional: CI/CD automation script
├── vllm-server/               # 1. Bagian vLLM Self-Hosted (GCE G2)
│   ├── Dockerfile
│   ├── setup-gpu.sh           # Skrip instalasi driver CUDA/NVIDIA di GCE
│   └── README.md              # Penjelasan spesifikasi VM dan model yang dipakai
├── litellm-proxy/             # 2. Bagian Gatekeeper (Cloud Run)
│   ├── config.yaml            # Konfigurasi routing berlapis (order 1 & 2)
│   ├── Dockerfile             # Dockerfile untuk deploy ke Cloud Run
│   └── README.md
├── monitoring/                # 3. Infrastruktur Monitoring (Khusus vLLM)
│   ├── prometheus.yml         # Konfigurasi target scraping vLLM
│   ├── grafana-dashboards/    # Ekspor file JSON dashboard Grafana Anda
│   └── docker-compose.yml     # Menyalakan Prometheus+Grafana lokal untuk testing
├── load-testing/              # 4. Simulasi Beban
│   ├── locustfile.py          # Skrip Locust yang Anda buat
│   └── README.md              # Instruksi cara menjalankan benchmark
├── docker-compose.local.yml   # Skrip simulasi arsitektur utuh secara lokal (opsional)
└── README.md                  # 🌟 Halaman Utama Portofolio Anda
