import hashlib
import base64
from datetime import datetime, date
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import os
import json

def generate_key(date_str: str, salt: str) -> bytes:
    combined = f"{date_str}_{salt}"
    hash_obj = hashlib.sha256(combined.encode('utf-8'))
    return hash_obj.digest()

def get_today_key(salt: str) -> bytes:
    today = date.today().isoformat()
    return generate_key(today, salt)

def pad_data(data: bytes) -> bytes:
    block_size = 16
    padding_length = block_size - (len(data) % block_size)
    padding = bytes([padding_length] * padding_length)
    return data + padding

def unpad_data(data: bytes) -> bytes:
    padding_length = data[-1]
    return data[:-padding_length]

def encrypt(data: str, key: bytes) -> str:
    iv = os.urandom(16)
    padded_data = pad_data(data.encode('utf-8'))
    
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    encrypted = encryptor.update(padded_data) + encryptor.finalize()
    
    result = base64.b64encode(iv + encrypted).decode('utf-8')
    return result

def decrypt(encrypted_data: str, key: bytes) -> str:
    raw_data = base64.b64decode(encrypted_data.encode('utf-8'))
    iv = raw_data[:16]
    encrypted = raw_data[16:]
    
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
    decryptor = cipher.decryptor()
    decrypted = decryptor.update(encrypted) + decryptor.finalize()
    
    unpadded = unpad_data(decrypted)
    return unpadded.decode('utf-8')

def encrypt_json(data: dict, key: bytes) -> str:
    json_str = json.dumps(data, ensure_ascii=False)
    return encrypt(json_str, key)

def decrypt_json(encrypted_data: str, key: bytes) -> dict:
    json_str = decrypt(encrypted_data, key)
    return json.loads(json_str)

def hash_password(password: str, salt: str) -> str:
    combined = f"{password}_{salt}"
    return hashlib.sha256(combined.encode('utf-8')).hexdigest()

def verify_password(password: str, salt: str, password_hash: str) -> bool:
    return hash_password(password, salt) == password_hash

def generate_token(user_id: int, timestamp: datetime, key: bytes) -> str:
    token_data = {
        'user_id': user_id,
        'timestamp': timestamp.isoformat()
    }
    return encrypt_json(token_data, key)

def verify_token(token: str, key: bytes, expiry_hours: int = 24) -> int:
    try:
        token_data = decrypt_json(token, key)
        user_id = token_data['user_id']
        timestamp = datetime.fromisoformat(token_data['timestamp'])
        
        elapsed = datetime.now() - timestamp
        if elapsed.total_seconds() > expiry_hours * 3600:
            return None
        
        return user_id
    except Exception:
        return None
