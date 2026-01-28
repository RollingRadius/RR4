"""
Encryption Utilities for Security Questions
AES-256 encryption using Fernet with PBKDF2 key derivation
"""

import os
import base64
import hashlib
from typing import Tuple
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from app.config import settings


def generate_salt() -> str:
    """
    Generate a unique 32-byte salt for encryption.
    Each user gets a unique salt for their security question answers.

    Returns:
        Base64-encoded 32-byte salt string

    Example:
        salt = generate_salt()  # Returns something like "8B7f9A2c..."
    """
    salt_bytes = os.urandom(32)  # 32 bytes = 256 bits
    return base64.b64encode(salt_bytes).decode('utf-8')


def derive_key(password: str, salt: str, iterations: int = 100000) -> bytes:
    """
    Derive an encryption key using PBKDF2 with SHA-256.

    This function combines the user's password with a unique salt and applies
    PBKDF2 with 100,000 iterations to create a strong encryption key.

    Args:
        password: User's password (plain text)
        salt: Base64-encoded salt string
        iterations: Number of PBKDF2 iterations (default: 100000)

    Returns:
        32-byte encryption key suitable for Fernet

    Note:
        The key is derived from: password + salt + master_key
        This ensures that even if password is compromised, the master key
        provides additional protection.
    """
    # Decode salt from base64
    salt_bytes = base64.b64decode(salt.encode('utf-8'))

    # Combine password with master key for additional security
    password_bytes = (password + settings.ENCRYPTION_MASTER_KEY).encode('utf-8')

    # Use PBKDF2 with SHA-256 and 100,000 iterations
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,  # 32 bytes = 256 bits for AES-256
        salt=salt_bytes,
        iterations=iterations
    )

    key = kdf.derive(password_bytes)
    return base64.urlsafe_b64encode(key)


def encrypt_answer(answer: str, password: str, salt: str) -> str:
    """
    Encrypt a security question answer using AES-256 via Fernet.

    Process:
    1. Derive encryption key from password + salt using PBKDF2
    2. Encrypt answer using Fernet (AES-256-CBC + HMAC)
    3. Return base64-encoded encrypted answer

    Args:
        answer: Security question answer (plain text)
        password: User's password for key derivation
        salt: Unique salt for this user (base64-encoded)

    Returns:
        Base64-encoded encrypted answer

    Example:
        encrypted = encrypt_answer("Portland", "userPassword123", user_salt)
    """
    # Normalize answer (lowercase, strip whitespace)
    normalized_answer = answer.lower().strip()

    # Derive encryption key
    key = derive_key(password, salt)

    # Create Fernet cipher
    cipher = Fernet(key)

    # Encrypt answer
    encrypted_bytes = cipher.encrypt(normalized_answer.encode('utf-8'))

    # Return as base64 string
    return encrypted_bytes.decode('utf-8')


def decrypt_and_compare(
    encrypted_answer: str,
    user_input: str,
    password: str,
    salt: str
) -> bool:
    """
    Decrypt an encrypted security answer and compare with user input.

    This function is used during password recovery or username recovery to
    verify that the user provided correct answers to security questions.

    Args:
        encrypted_answer: Encrypted answer from database
        user_input: User's answer input (plain text)
        password: User's password for key derivation
        salt: User's unique salt (base64-encoded)

    Returns:
        True if user input matches decrypted answer, False otherwise

    Example:
        is_correct = decrypt_and_compare(
            stored_encrypted_answer,
            "portland",
            user_password,
            user_salt
        )
    """
    try:
        # Normalize user input
        normalized_input = user_input.lower().strip()

        # Derive decryption key
        key = derive_key(password, salt)

        # Create Fernet cipher
        cipher = Fernet(key)

        # Decrypt stored answer
        decrypted_bytes = cipher.decrypt(encrypted_answer.encode('utf-8'))
        decrypted_answer = decrypted_bytes.decode('utf-8')

        # Compare (case-insensitive, whitespace-trimmed)
        return decrypted_answer == normalized_input

    except Exception:
        # Decryption failed (invalid key, corrupted data, etc.)
        return False


def verify_multiple_answers(
    encrypted_answers: list[Tuple[str, str]],  # [(encrypted, user_input), ...]
    password: str,
    salt: str
) -> bool:
    """
    Verify multiple security question answers at once.

    This is used during password recovery when user must answer
    multiple questions correctly (typically 3 questions).

    Args:
        encrypted_answers: List of tuples (encrypted_answer, user_input)
        password: User's password for key derivation
        salt: User's unique salt

    Returns:
        True if ALL answers are correct, False if any answer is wrong

    Example:
        answers_to_verify = [
            (stored_answer1, user_input1),
            (stored_answer2, user_input2),
            (stored_answer3, user_input3)
        ]
        all_correct = verify_multiple_answers(answers_to_verify, pwd, salt)
    """
    for encrypted_answer, user_input in encrypted_answers:
        if not decrypt_and_compare(encrypted_answer, user_input, password, salt):
            return False
    return True


def re_encrypt_answers(
    encrypted_answers: list[str],
    old_password: str,
    new_password: str,
    salt: str
) -> list[str]:
    """
    Re-encrypt security answers when user changes password.

    Since encryption key is derived from password, changing password
    requires re-encrypting all security answers.

    Args:
        encrypted_answers: List of encrypted answers with old password
        old_password: User's old password
        new_password: User's new password
        salt: User's unique salt (remains the same)

    Returns:
        List of re-encrypted answers with new password

    Example:
        new_encrypted = re_encrypt_answers(
            old_encrypted_answers,
            "oldPassword123",
            "newPassword456",
            user_salt
        )
    """
    re_encrypted = []

    for encrypted_answer in encrypted_answers:
        try:
            # Decrypt with old password
            old_key = derive_key(old_password, salt)
            cipher_old = Fernet(old_key)
            decrypted_bytes = cipher_old.decrypt(encrypted_answer.encode('utf-8'))
            plain_answer = decrypted_bytes.decode('utf-8')

            # Encrypt with new password
            new_key = derive_key(new_password, salt)
            cipher_new = Fernet(new_key)
            new_encrypted_bytes = cipher_new.encrypt(plain_answer.encode('utf-8'))

            re_encrypted.append(new_encrypted_bytes.decode('utf-8'))

        except Exception:
            # If any answer fails to re-encrypt, return empty list
            return []

    return re_encrypted


# Test function for development/debugging
def test_encryption():
    """
    Test encryption/decryption cycle.
    This function can be used to verify that encryption is working correctly.
    """
    # Generate test data
    test_password = "TestPassword123!"
    test_answer = "Portland"
    test_salt = generate_salt()

    # Encrypt
    encrypted = encrypt_answer(test_answer, test_password, test_salt)
    print(f"Salt: {test_salt}")
    print(f"Encrypted: {encrypted}")

    # Verify correct answer
    is_correct = decrypt_and_compare(encrypted, "portland", test_password, test_salt)
    print(f"Correct answer verification: {is_correct}")  # Should be True

    # Verify wrong answer
    is_wrong = decrypt_and_compare(encrypted, "Seattle", test_password, test_salt)
    print(f"Wrong answer verification: {is_wrong}")  # Should be False

    # Verify with wrong password
    wrong_pwd = decrypt_and_compare(encrypted, "portland", "WrongPassword", test_salt)
    print(f"Wrong password verification: {wrong_pwd}")  # Should be False


if __name__ == "__main__":
    # Run test if executed directly
    test_encryption()
