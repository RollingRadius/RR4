"""Test signup validation to see what's failing"""
import requests
import json

# Test data matching what frontend sends
signup_data = {
    "full_name": "Test User",
    "username": "testuser2",
    "phone": "1234567890",
    "password": "Test1234!",
    "auth_method": "security_questions",
    "security_questions": [
        {
            "question_id": "Q1",
            "question_text": "What is your mother's maiden name?",
            "answer": "Smith"
        },
        {
            "question_id": "Q2",
            "question_text": "What was the name of your first pet?",
            "answer": "Buddy"
        },
        {
            "question_id": "Q3",
            "question_text": "In what city were you born?",
            "answer": "Portland"
        }
    ],
    "terms_accepted": True
}

print("Testing signup endpoint...")
print("="*60)
print("Request Data:")
print(json.dumps(signup_data, indent=2))
print("="*60)

try:
    response = requests.post(
        "http://localhost:8000/api/auth/signup",
        json=signup_data,
        headers={"Content-Type": "application/json"}
    )

    print(f"\nResponse Status: {response.status_code}")
    print("="*60)

    if response.status_code == 422:
        print("VALIDATION ERROR:")
        print(json.dumps(response.json(), indent=2))
    elif response.status_code == 201:
        print("SUCCESS!")
        print(json.dumps(response.json(), indent=2))
    else:
        print("Response:")
        print(response.text)

except Exception as e:
    print(f"ERROR: {e}")
