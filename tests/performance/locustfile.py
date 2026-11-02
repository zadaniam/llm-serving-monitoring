import os
from locust import HttpUser, task, between

# Configuration / environment variables
MODEL_NAME = os.getenv("MODEL_NAME")
API_KEY = os.getenv("VLLM_API_KEY")

# LLM payload settings
PROMPT_CONTENT = "Give a brief and concise explanation of what LLM architecture is."
MAX_TOKENS = 100
TEMPERATURE = 0.7
STREAM_MODE = False  # Set True to test streaming token performance


class VLLMLoadTestUser(HttpUser):
    """Locust user that simulates load against the vLLM inference endpoint."""

    # Wait 1 to 3 seconds between requests per simulated user
    wait_time = between(1, 3)

    @task
    def test_qwen_chat(self):
        """Send a chat completion request to vLLM and mark success/failure."""
        # Standard OpenAI API / vLLM headers
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_KEY}"
        }

        # Request payload using variables from above
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

        # Hit vLLM endpoint
        with self.client.post("/v1/chat/completions", json=payload, headers=headers, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(
                    f"Failed to process request. Status Code: {response.status_code}, Response: {response.text}"
                )
