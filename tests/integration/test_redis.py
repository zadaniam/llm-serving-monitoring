import os
import redis
import pytest

REDIS_URL = os.getenv("REDIS_URL")

def test_redis_connection():
    """Verify REDIS_URL is set and the Redis server responds to PING."""
    
    assert REDIS_URL is not None, "Environment variable REDIS_URL is not set in .env file!"
    assert REDIS_URL.startswith("redis://") or REDIS_URL.startswith("rediss://"), \
        f"Invalid REDIS_URL format! Must start with 'redis://' or 'rediss://'. Read: {REDIS_URL}"

    # Attempt handshake / PING to the Redis instance
    try:
        # Set 5-second timeout so the test does not hang if the server is down
        client = redis.Redis.from_url(REDIS_URL, socket_timeout=5.0)
        is_alive = client.ping()

        assert is_alive is True, "Redis server responded but did not return status True"
        
    except redis.exceptions.AuthenticationError:
        pytest.fail("Failed to connect to Redis: Wrong password/credentials! (AuthenticationError)")
        
    except redis.exceptions.TimeoutError:
        pytest.fail("Failed to connect to Redis: Timeout! 5-second limit exceeded. "
                    "Check if your IP is blocked by the firewall or the server is down.")
        
    except Exception as e:
        pytest.fail(f"Unexpected error occurred while connecting to Redis. Detail: {e}")
