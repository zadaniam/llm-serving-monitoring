import os
import requests

# Get environment variables with local fallback values for easier testing
LITELLM_URL = os.getenv("LITELLM_URL", "http://localhost:4000")
MASTER_KEY = os.getenv("LITELLM_MASTER_KEY", "sk-local-dev-secret-token")

TIMEOUT_SECONDS = 10

def test_gateway_health_ping():
    """Verify LiteLLM proxy health check endpoint is active"""
    response = requests.get(f"{LITELLM_URL}/health/liveness")
    assert response.status_code == 200, f"Proxy is not accessible, HTTP {response.status_code}"

def test_smart_router_chat_completion():
    """Verify smart router returns valid text response and JSON format"""
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {MASTER_KEY}"
    }
    
    payload = {
        "model": "my-smart-router",
        "messages": [
            {
                "role": "user",
                "content": "Hello, respond with exactly one word: 'Success'."
            }
        ],
        "temperature": 0.2
    }
    
    response = requests.post(
        f"{LITELLM_URL}/v1/chat/completions",
        json=payload,
        headers=headers,
        timeout=TIMEOUT_SECONDS,
    )
    
    assert response.status_code == 200, f"API failed with status {response.status_code}. Detail: {response.text}"
    
    data = response.json()
    assert "choices" in data, "Invalid response format, key 'choices' not found"
    assert len(data["choices"]) > 0, "Choices list is empty"
    
    message = data["choices"][0]["message"]
    assert "content" in message, "AI response text content not found"
    assert message["content"].strip() != "", "AI response text is empty"
    
    print(f"\n[INTEGRATION TEST] Responded by backend model: {data.get('model')}")
