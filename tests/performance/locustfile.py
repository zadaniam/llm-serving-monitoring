import os
from locust import HttpUser, task, between

# ==============================================================================
# CONFIGURATION / ENVIRONMENT VARIABLES
# Sesuaikan bagian ini atau biarkan membaca otomatis dari file .env Anda
# ==============================================================================
MODEL_NAME = os.getenv("MODEL_NAME")
VLLM_API_KEY = os.getenv("VLLM_API_KEY")

# Pengaturan Payload LLM
PROMPT_CONTENT = "Berikan penjelasan singkat dan padat mengenai apa itu arsitektur LLM."
MAX_TOKENS = 100
TEMPERATURE = 0.7
STREAM_MODE = False  # Set True jika ingin menguji performa streaming token
# ==============================================================================

class VLLMLoadTestUser(HttpUser):
    # Memberikan jeda acak 1 hingga 3 detik antar request per user
    wait_time = between(1, 3)

    @task
    def test_qwen_chat(self):
        # Header standar OpenAI API / vLLM
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {VLLM_API_KEY}"
        }

        # Payload request menggunakan variabel dari atas
        payload = {
            "model": MODEL_NAME,
            "messages": [
                {
                    "role": "user",
                    "content": PROMPT_CONTENT
                }
            ],
            "max_tokens": MAX_TOKENS,
            "temperature": TEMPERATURE,
            "stream": STREAM_MODE
        }

        # Menembak endpoint vLLM
        with self.client.post("/v1/chat/completions", json=payload, headers=headers, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(
                    f"Gagal memproses request. Status Code: {response.status_code}, Respon: {response.text}"
                )
