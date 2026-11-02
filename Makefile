# Binds environment variables from .env file if it exists
-include .env
export

.PHONY: help install-dev docker-build dev-up dev-down dev-logs run-bot test-integration test-load clean

help:
	@echo "Available commands:"
	@echo "  make install-dev     - Install test dependencies in tests folder"
	@echo "  make dev-up          - Build Docker image & start dev ecosystem"
	@echo "  make dev-down        - Stop entire local dev ecosystem"
	@echo "  make dev-logs        - View real-time logs from LiteLLM Proxy"
	@echo "  make run-bot         - Run automated bot test script"
	@echo "  make test-integration- Run integration testing with Pytest"
	@echo "  make test-load       - Run Locust for load testing"
	@echo "  make clean           - Clean Python cache, Docker volume, & .venv"

# 1. LOCAL DEPENDENCY MANAGEMENT (UV)
install-dev:
	@echo "Entering sub-folder & installing testing dependencies using UV..."
	cd tests && uv sync

# 2. LOCAL DEVELOPMENT DOCKER (DOCKER COMPOSE)
docker-build:
	@echo "Building LiteLLM Docker image locally..."
	docker build -t litellm-proxy-local:latest ./litellm-proxy

dev-up: docker-build
	@echo "Setting up external Redis & vLLM connection based on .env file..."
	@echo "Starting local dev environment (LiteLLM, Prometheus, Grafana)..."
	docker compose -f docker-compose.local.yml up -d
	@echo "System is up! LiteLLM: http://localhost:4000 | Grafana: http://localhost:3000"

dev-down:
	@echo "Stopping local dev environment..."
	docker compose -f docker-compose.local.yml down --remove-orphans

dev-logs:
	docker compose -f docker-compose.local.yml logs -f litellm-proxy-dev

# 3. AUTOMATION SCRIPT & BOT RUNNER
run-bot:
	@echo "Running Bot Test Script..."
	cd tests/performance && uv run --env-file ../../.env test_bot.py

# 4. BENCHMARK & TESTING (INTEGRATION & PERFORMANCE)
test-integration:
	@echo "Run Integration Tests via Pytest..."
	cd tests/integration && uv run --env-file ../../.env pytest . -v -s

test-load:
	@echo "Running Locust load testing locally..."
	@echo "Open http://localhost:8089 in browser to configure user count."
	cd tests/performance && uv run locust -f locustfile.py

# 5. CLEANUP UTILITIES
clean:
	@echo "🧹 Cleaning local cache and .venv remnants..."
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	rm -rf tests/.uv tests/.venv
