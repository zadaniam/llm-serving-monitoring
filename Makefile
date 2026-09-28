.PHONY: help dev-up dev-down dev-logs install-dev run-bot test-load clean

# Menampilkan menu bantuan otomatis saat mengetik 'make' atau 'make help'
help:
	@echo "======================================================================"
	@echo "                 🌐 HYBRID LLM GATEWAY COMMAND CENTER                "
	@echo "======================================================================"
	@echo "Perintah yang tersedia:"
	@echo "  make install-dev  - Menginstal dependensi Locust di folder load-testing"
	@echo "  make dev-up       - Menyalakan seluruh ekosistem lokal dev (Docker Compose)"
	@echo "  make dev-down     - Mematikan seluruh ekosistem lokal dev"
	@echo "  make dev-logs     - Melihat log real-time dari LiteLLM Proxy lokal"
	@echo "  make test-load    - Menjalankan Locust untuk melakukan load testing"
	@echo "  make clean        - Membersihkan cache Python, Docker volume, dan .venv"
	@echo "======================================================================"

# 1. MANAGEMENT DEPENDENSI LOKAL (UV DI SUB-FOLDER)
install-dev:
	@echo "⚙️ Masuk ke sub-folder & menginstal dependensi Locust menggunakan UV..."
	cd load-testing && uv sync

# 2. LOCAL DEVELOPMENT DOCKER (DOCKER COMPOSE)
dev-up:
	@echo "🚀 Menyalakan lingkungan lokal dev (LiteLLM, Redis, Mock vLLM, Grafana)..."
	docker compose -f docker-compose.local.yml up -d
	@echo "✅ Sistem menyala! LiteLLM: http://localhost:4000 | Grafana: http://localhost:3000"

dev-down:
	@echo "🛑 Mematikan lingkungan lokal dev..."
	docker compose -f docker-compose.local.yml down

dev-logs:
	docker compose -f docker-compose.local.yml logs -f litellm-proxy-dev

# 3. BENCHMARK & TESTING (LOCUST DENGAN INTEGRASI CD)
run-bot:
	@echo "🤖 Menjalankan Aplikasi Bot Interaktif..."
	cd load-testing && uv run python test_bot.py

test-load:
	@echo "🦟 Menjalankan pengujian beban Locust secara lokal..."
	@echo "Buka http://localhost:8089 di browser untuk mengatur jumlah user."
	cd load-testing && uv run locust -f locustfile.py

# 4. CLEANUP UTILITIES
clean:
	@echo "🧹 Membersihkan sisa cache, kontainer, dan .venv lokal..."
	docker compose -f docker-compose.local.yml down -v
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -rf load-testing/.uv load-testing/.venv
