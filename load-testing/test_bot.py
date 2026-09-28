import os
import requests
import json
import time

# 1. Konfigurasi Endpoint (Menembak ke LiteLLM Proxy Lokal Anda)
PROXY_URL = "http://localhost:4000/v1/chat/completions"
# Mengambil token keamanan Master Key dari file .env Anda
MASTER_KEY = os.getenv("LITELLM_MASTER_KEY", "local-dev-secret-token")

def send_message_to_bot(prompt_text):
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {MASTER_KEY}" # 🛡️ Menembus satpam autentikasi proxy
    }
    
    payload = {
        "model": "my-smart-router", # Nama model virtual hibrida dari config.yaml
        "messages": [
            {"role": "user", "content": prompt_text}
        ],
        "temperature": 0.7
    }
    
    print("\n[🤖 BOT] Mengirim pesan ke Gateway Router...")
    start_time = time.time()
    
    try:
        response = requests.post(PROXY_URL, headers=headers, json=payload)
        latency = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            answer = result["choices"][0]["message"]["content"]
            
            # 🌟 PERBAIKAN: Menangkap nama model internal asli dari Header Kustom LiteLLM
            # Jika 'x-litellm-model-id' tidak ditemukan di header, ia akan membaca fallback dari JSON body
            actual_model = response.headers.get("x-litellm-model-id", result.get("model", "Unknown"))
            
            print("======================================================================")
            print(f"📥 JAWABAN AI:\n{answer}")
            print("======================================================================")
            print(f"📊 METADATA JALUR UTAS (ROUTING METADATA):")
            print(f"   • Model Aktual Yang Merespons : {actual_model}")
            print(f"   • Waktu Tunggu (Latency)      : {latency:.2f} detik")
            print("======================================================================")
        else:
            print(f"❌ GAGAL! Kode Status HTTP: {response.status_code}")
            print(f"   Pesan Kesalahan: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ KONEKSI PUTUS: Pastikan LiteLLM Proxy sudah menyala (make dev-up)!")

if __name__ == "__main__":
    print("======================================================================")
    print("                 💬 APLIKASI BOT PENGUJI LIVE GATEWAY                ")
    print("======================================================================")
    
    while True:
        user_input = input("\nTanya Sesuatu (atau ketik 'exit' untuk keluar): ")
        if user_input.lower() == 'exit':
            print("Sampai jumpa!")
            break
        if user_input.strip() == "":
            continue
        send_message_to_bot(user_input)
