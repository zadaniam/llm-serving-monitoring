import os
import requests

# Mengambil variabel lingkungan dengan fallback nilai lokal untuk mempermudah testing
LITELLM_URL = os.getenv("LITELLM_URL")
MASTER_KEY = os.getenv("LITELLM_MASTER_KEY")

def test_gateway_health_ping():
    """Memastikan endpoint health check proxy LiteLLM aktif"""
    response = requests.get(f"{LITELLM_URL}/health/liveness")
    assert response.status_code == 200, f"Proxy tidak dapat diakses, HTTP {response.status_code}"

def test_smart_router_chat_completion():
    """Memastikan router pintar mengembalikan respons teks dan format JSON yang valid"""
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
        headers=headers
    )
    
    # --- ASSERTIONS (Validasi Otomatis) ---
    assert response.status_code == 200, f"API Gagal dengan status {response.status_code}. Detail: {response.text}"
    
    data = response.json()
    assert "choices" in data, "Format respons salah, tidak ditemukan key 'choices'"
    assert len(data["choices"]) > 0, "Daftar pilihan (choices) kosong"
    
    message = data["choices"][0]["message"]
    assert "content" in message, "Konten teks balasan AI tidak ditemukan"
    assert message["content"].strip() != "", "Balasan teks AI kosong"
    
    # Menampilkan info di terminal model apa yang sesungguhnya menjawab (vLLM/Groq/Gemini)
    print(f"\n[INTEGRATION TEST] Direspon oleh backend model: {data.get('model')}")
