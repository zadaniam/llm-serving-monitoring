import os
import requests
import json
import time
from dotenv import load_dotenv

load_dotenv()

# Get environment variables after loading via dotenv
MASTER_KEY = os.getenv("LITELLM_MASTER_KEY")
LITELLM_URL = os.getenv("LITELLM_URL")

# Early validation to avoid errors if .env is empty
if not LITELLM_URL or not MASTER_KEY:
    print("❌ ERROR: LITELLM_URL or LITELLM_MASTER_KEY not found in .env file!")
    print("Make sure you created the .env file in the same folder as this script.")
    exit(1)

PROXY_URL = f"{LITELLM_URL}/v1/chat/completions"

def send_message_to_bot(prompt_text):
    """Send a chat completion request to the LiteLLM gateway and print the response.

    Args:
        prompt_text (str): The user's message to send to the gateway router.

    Returns:
        None. Prints the AI response, responding model, and latency to stdout.
    """
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {MASTER_KEY}"
    }
    
    payload = {
        "model": "my-smart-router",  # Hybrid virtual model from config.yaml
        "messages": [
            {"role": "user", "content": prompt_text}
        ],
        "temperature": 0.7
    }
    
    print("\n[🤖 BOT] Sending message to Gateway Router...")
    start_time = time.time()
    
    try:
        response = requests.post(PROXY_URL, headers=headers, json=payload)
        latency = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            answer = result["choices"][0]["message"]["content"]
            
            # Capture actual internal model name from LiteLLM custom header
            actual_model = response.headers.get("x-litellm-model-id", result.get("model", "Unknown"))
            
            print("======================================================================")
            print(f"📥 AI RESPONSE:\n{answer}")
            print("======================================================================")
            print(f"📊 ROUTING METADATA:")
            print(f"   • Actual Responding Model : {actual_model}")
            print(f"   • Wait Time (Latency)     : {latency:.2f} seconds")
            print("======================================================================")
        else:
            print(f"❌ FAILED! HTTP Status Code: {response.status_code}")
            print(f"   Error Message: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ CONNECTION LOST: Make sure LiteLLM Proxy is running (make dev-up)!")

if __name__ == "__main__":
    print("======================================================================")
    print("       💬 LIVE GATEWAY TEST BOT APPLICATION (DOTENV ENABLED)         ")
    print("======================================================================")
    print(f"🔗 Connected to Proxy: {LITELLM_URL}")
    
    while True:
        user_input = input("\nAsk something (or type 'exit' to quit): ")
        if user_input.lower() == 'exit':
            print("Goodbye!")
            break
        if user_input.strip() == "":
            continue
        send_message_to_bot(user_input)
