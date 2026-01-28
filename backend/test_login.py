"""Test login with testuser2"""
import requests
import json

# Backend URL
BASE_URL = "http://localhost:8000"

# Test credentials
USERNAME = "testuser2"
PASSWORD = "Test1234!"

print("=" * 60)
print("Testing Login with testuser2")
print("=" * 60)

# Test login
login_data = {
    "username": USERNAME,
    "password": PASSWORD
}

print(f"\nAttempting login:")
print(f"  Username: {USERNAME}")
print(f"  Password: {PASSWORD}")

try:
    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json=login_data,
        headers={"Content-Type": "application/json"}
    )

    print(f"\nResponse Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print("\n✅ LOGIN SUCCESSFUL!")
        print("=" * 60)
        print(f"User ID: {data.get('user_id')}")
        print(f"Username: {data.get('username')}")
        print(f"Role: {data.get('role')}")
        print(f"Company: {data.get('company_name', 'None (Independent User)')}")
        print(f"Token: {data.get('access_token')[:50]}...")
        print("=" * 60)
    else:
        print(f"\n❌ LOGIN FAILED!")
        print(f"Response: {response.text}")

except requests.exceptions.ConnectionError:
    print("\n❌ Cannot connect to backend!")
    print("Make sure backend is running on http://localhost:8000")
except Exception as e:
    print(f"\n❌ Error: {e}")

print("\n" + "=" * 60)
print("Next Steps:")
print("=" * 60)
print("1. If login worked: Use testuser2/Test1234! in Flutter app")
print("2. If login failed: Check backend logs")
print("3. Create new user via Flutter signup with security questions")
print("=" * 60)
