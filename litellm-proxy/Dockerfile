# Stage 1: Build dependencies
FROM python:3.11-slim AS builder
WORKDIR /build

COPY pyproject.toml .
RUN pip install --no-cache-dir --target=/build/third_party .

# Stage 2: Production runtime
FROM ghcr.io/berriai/litellm:v1.103.0
WORKDIR /app

# Inject Redis and third-party dependencies into LiteLLM's internal site-packages
COPY --from=builder /build/third_party /usr/local/lib/python3.11/site-packages/
COPY config.yaml .

# Cloud Run requires binding to a dynamic port provided via the PORT env variable
EXPOSE 8080

# Clear the base image's default entrypoint to allow execution of the customized CMD
ENTRYPOINT []

CMD litellm --config config.yaml --host 0.0.0.0 --port ${PORT:-4000}
