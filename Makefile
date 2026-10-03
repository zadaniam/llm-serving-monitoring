-include .env
export

.PHONY: help install-dev docker-build dev-up dev-down dev-logs run-bot test-integration test-load clean

help:
	@echo "======================================================================"
	@echo "                 🌐 HYBRID LLM GATEWAY COMMAND CENTER                "
	@echo "======================================================================"
	@echo "Perintah yang tersedia:"
	@echo "  make install-dev     - Menginstal dependensi pengujian di folder tests"
	@echo "  make dev-up          - Mengompilasi Docker image & menyalakan ekosistem dev"
	@echo "  make dev-down        - Mematikan seluruh ekosistem lokal dev"
	@echo "  make dev-logs        - Melihat log real-time dari LiteLLM Proxy"
	@echo "  make run-bot         - Menjalankan skrip uji bot otomatis"
	@echo "  make test-integration- Menjalankan integration testing dengan Pytest"
	@echo "  make test-load       - Menjalankan Locust untuk load testing"
	@echo "  make clean           - Membersihkan cache Python, Docker volume, & .venv"
	@echo "======================================================================"
	@echo "⚠️  CATATAN: Pastikan eksternal server Redis & vLLM sudah menyala,"
	@echo "   serta file .env sudah diisi sebelum menjalankan 'make dev-up'!"
	@echo "======================================================================"


# 1. MANAJEMEN DEPENDENSI LOKAL (UV)
install-dev:
	@echo "⚙️ Masuk ke sub-folder & menginstal dependensi testing menggunakan UV..."
	cd tests && uv sync

# 2. LOCAL DEVELOPMENT DOCKER (DOCKER COMPOSE)
docker-build:
	@echo "📦 Building LiteLLM Docker image locally..."
	docker build -t litellm-proxy-local:latest ./litellm-proxy

dev-up: docker-build
	@echo "📢 Menyiapkan koneksi ke eksternal Redis & vLLM berdasarkan file .env..."
	@echo "🚀 Menyalakan lingkungan lokal dev (LiteLLM, Prometheus, Grafana)..."
	docker compose -f docker-compose.local.yml up -d
	@echo "✅ Sistem menyala! LiteLLM: http://localhost:4000 | Grafana: http://localhost:3000"

dev-down:
	@echo "🛑 Mematikan lingkungan lokal dev..."
	docker compose -f docker-compose.local.yml down --remove-orphans

dev-logs:
	docker compose -f docker-compose.local.yml logs -f litellm-proxy-dev

# 3. SKRIP OTOMATISASI & BOT RUNNER
run-bot:
	@echo "🤖 Running Bot Test Script..."
	uv run --env-file .env tests/performance/test_bot.py

# 4. BENCHMARK & TESTING (INTEGRATION & PERFORMANCE)
test-integration:
	@echo "🧪 Run Integration Tests via Pytest..."
	uv run --env-file .env pytest tests/integration/ -v -s

test-load:
	@echo "🦟 Menjalankan pengujian beban Locust secara lokal..."
	@echo "🔗 Buka http://localhost:8089 di browser untuk mengatur jumlah user."
	cd tests/performance && uv run locust -f locustfile.py

# 5. CLEANUP UTILITIES
clean:
	@echo "🧹 Membersihkan sisa cache, kontainer, dan .venv lokal..."
	docker compose -f docker-compose.local.yml down -v --remove-orphans
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -rf tests/.uv tests/.venv
