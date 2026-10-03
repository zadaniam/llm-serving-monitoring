import os
import redis
import pytest

# Mengambil variabel lingkungan dari context yang dialirkan oleh uv run
REDIS_URL = os.getenv("REDIS_URL")

def test_redis_connection():
    """Menguji apakah string REDIS_URL tersedia dan server dapat di-PING dengan sukses"""
    
    # 1. Validasi keberadaan variabel lingkungan
    assert REDIS_URL is not None, "❌ Variabel lingkungan REDIS_URL belum disetel di file .env!"
    assert REDIS_URL.startswith("redis://") or REDIS_URL.startswith("rediss://"), \
        f"❌ Format REDIS_URL salah! Harus diawali dengan 'redis://' atau 'rediss://'. Terbaca: {REDIS_URL}"

    # 2. Mencoba melakukan handshake / PING ke instans Redis
    try:
        # Menyetel timeout 5 detik agar testing tidak menggantung jika server mati
        client = redis.Redis.from_url(REDIS_URL, socket_timeout=5.0)
        is_alive = client.ping()
        
        # 3. Validasi respons dari server
        assert is_alive is True, "Server Redis merespons namun tidak mengembalikan status True"
        
    except redis.exceptions.AuthenticationError:
        pytest.fail("❌ Gagal terhubung ke Redis: Password/Kredensial salah! (AuthenticationError)")
        
    except redis.exceptions.TimeoutError:
        pytest.fail("❌ Gagal terhubung ke Redis: Waktu tunggu habis! Batas 5 detik terlampaui (TimeoutError). "
                    "Periksa apakah IP Anda diblokir firewall atau server sedang down.")
        
    except Exception as e:
        pytest.fail(f"❌ Terjadi kesalahan tidak terduga saat menghubungkan ke Redis. Detail: {e}")
