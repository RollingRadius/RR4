"""
API Test Script
Demonstrates all authentication and company management endpoints
"""

import requests
import json
from datetime import datetime

# API Base URL
BASE_URL = "http://localhost:8000"

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_success(message):
    print(f"{Colors.GREEN}✓ {message}{Colors.END}")

def print_error(message):
    print(f"{Colors.RED}✗ {message}{Colors.END}")

def print_info(message):
    print(f"{Colors.BLUE}ℹ {message}{Colors.END}")

def print_warning(message):
    print(f"{Colors.YELLOW}⚠ {message}{Colors.END}")

def print_section(title):
    print(f"\n{Colors.BLUE}{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}{Colors.END}\n")


def test_health_check():
    """Test 1: Health Check"""
    print_section("TEST 1: Health Check")

    response = requests.get(f"{BASE_URL}/health")

    if response.status_code == 200:
        data = response.json()
        print_success(f"Health check passed")
        print_info(f"App: {data['app_name']} v{data['version']}")
        print_info(f"Environment: {data['environment']}")
        return True
    else:
        print_error(f"Health check failed: {response.status_code}")
        return False


def test_get_security_questions():
    """Test 2: Get Security Questions"""
    print_section("TEST 2: Get Security Questions")

    response = requests.get(f"{BASE_URL}/api/auth/security-questions")

    if response.status_code == 200:
        data = response.json()
        print_success(f"Retrieved {data['count']} security questions")

        for i, q in enumerate(data['questions'][:3], 1):
            print_info(f"  {i}. {q['question_text']} ({q['category']})")

        return data['questions']
    else:
        print_error(f"Failed to get security questions: {response.status_code}")
        return None


def test_company_search():
    """Test 3: Company Search"""
    print_section("TEST 3: Company Search")

    # Test with short query (should fail)
    print_info("Testing with short query (should fail)...")
    response = requests.get(f"{BASE_URL}/api/companies/search?q=AB")

    if response.status_code == 400:
        print_success("Correctly rejected short query")
    else:
        print_warning("Short query validation not working")

    # Test with valid query
    print_info("Testing with valid query...")
    response = requests.get(f"{BASE_URL}/api/companies/search?q=ABC&limit=3")

    if response.status_code == 200:
        data = response.json()
        print_success(f"Search completed, found {data['count']} companies")

        if data['count'] > 0:
            for company in data['companies']:
                print_info(f"  - {company['company_name']} ({company['city']}, {company['state']})")
        else:
            print_info("  No companies found (database empty)")

        return True
    else:
        print_error(f"Company search failed: {response.status_code}")
        return False


def test_company_validation():
    """Test 4: Company Validation"""
    print_section("TEST 4: Company Validation")

    # Valid GSTIN and PAN
    valid_data = {
        "gstin": "29ABCDE1234F1Z5",
        "pan_number": "ABCDE1234F",
        "registration_number": "U63040KA2024PTC123456"
    }

    print_info("Testing valid GSTIN and PAN...")
    response = requests.post(
        f"{BASE_URL}/api/companies/validate",
        json=valid_data
    )

    if response.status_code == 200:
        data = response.json()
        if data['valid']:
            print_success("Validation passed")
            print_info(f"  GSTIN: {data['validation']['gstin_valid']}")
            print_info(f"  PAN: {data['validation']['pan_valid']}")
            print_info(f"  PAN Linked: {data['validation']['pan_linked']}")
        else:
            print_warning("Validation failed (might be already registered)")
            if data.get('errors'):
                for error in data['errors']:
                    print_warning(f"  - {error}")
    else:
        print_error(f"Validation request failed: {response.status_code}")

    # Invalid GSTIN
    print_info("\nTesting invalid GSTIN...")
    invalid_data = {
        "gstin": "INVALID123",
        "pan_number": "ABCDE1234F"
    }

    response = requests.post(
        f"{BASE_URL}/api/companies/validate",
        json=invalid_data
    )

    if response.status_code == 200:
        data = response.json()
        if not data['valid']:
            print_success("Correctly detected invalid GSTIN")
        else:
            print_error("Failed to detect invalid GSTIN")

    return True


def test_signup_email_method():
    """Test 5: Signup with Email Method"""
    print_section("TEST 5: Signup with Email Method")

    signup_data = {
        "full_name": "John Doe",
        "username": f"johndoe_{datetime.now().timestamp()}",
        "email": f"john{datetime.now().timestamp()}@example.com",
        "phone": "+1234567890",
        "password": "SecurePass123!",
        "auth_method": "email",
        "company_type": None,  # Skip company
        "terms_accepted": True
    }

    print_info(f"Signing up user: {signup_data['username']}")
    response = requests.post(
        f"{BASE_URL}/api/auth/signup",
        json=signup_data
    )

    if response.status_code == 201:
        data = response.json()
        print_success("Signup successful!")
        print_info(f"  User ID: {data['user_id']}")
        print_info(f"  Username: {data['username']}")
        print_info(f"  Status: {data['status']}")
        print_info(f"  Role: {data['role']}")
        print_info(f"  Message: {data['message']}")

        return {
            'username': signup_data['username'],
            'password': signup_data['password'],
            'user_id': data['user_id']
        }
    else:
        print_error(f"Signup failed: {response.status_code}")
        if response.status_code == 400:
            print_error(f"  Error: {response.json()['detail']}")
        return None


def test_signup_security_questions():
    """Test 6: Signup with Security Questions"""
    print_section("TEST 6: Signup with Security Questions")

    signup_data = {
        "full_name": "Jane Smith",
        "username": f"janesmith_{datetime.now().timestamp()}",
        "email": None,  # No email for security questions method
        "phone": "+9876543210",
        "password": "SecurePass456!",
        "auth_method": "security_questions",
        "company_type": None,  # Skip company
        "security_questions": [
            {
                "question_id": "Q1",
                "question_text": "What is your mother's maiden name?",
                "answer": "Anderson"
            },
            {
                "question_id": "Q2",
                "question_text": "What was the name of your first pet?",
                "answer": "Rex"
            },
            {
                "question_id": "Q3",
                "question_text": "In what city were you born?",
                "answer": "Portland"
            }
        ],
        "terms_accepted": True
    }

    print_info(f"Signing up user: {signup_data['username']}")
    response = requests.post(
        f"{BASE_URL}/api/auth/signup",
        json=signup_data
    )

    if response.status_code == 201:
        data = response.json()
        print_success("Signup successful!")
        print_info(f"  User ID: {data['user_id']}")
        print_info(f"  Username: {data['username']}")
        print_info(f"  Status: {data['status']}")
        print_info(f"  Role: {data['role']}")
        print_info(f"  Security Questions: {data['security_questions_count']}")
        print_info(f"  Message: {data['message']}")

        return {
            'username': signup_data['username'],
            'password': signup_data['password'],
            'user_id': data['user_id']
        }
    else:
        print_error(f"Signup failed: {response.status_code}")
        if response.status_code == 400:
            print_error(f"  Error: {response.json()['detail']}")
        return None


def test_login(user_credentials):
    """Test 7: Login"""
    print_section("TEST 7: Login")

    if not user_credentials:
        print_warning("Skipping login test (no user credentials)")
        return None

    login_data = {
        "username": user_credentials['username'],
        "password": user_credentials['password']
    }

    print_info(f"Logging in as: {login_data['username']}")
    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json=login_data
    )

    if response.status_code == 200:
        data = response.json()
        print_success("Login successful!")
        print_info(f"  Token Type: {data['token_type']}")
        print_info(f"  Access Token: {data['access_token'][:50]}...")
        print_info(f"  User ID: {data['user_id']}")
        print_info(f"  Role: {data['role']}")

        return data['access_token']
    elif response.status_code == 403:
        error_detail = response.json()['detail']
        if "verify your email" in error_detail.lower():
            print_warning("Login blocked: Email not verified")
            print_info("  This is expected for email-based signups")
        else:
            print_error(f"Login failed: {error_detail}")
        return None
    else:
        print_error(f"Login failed: {response.status_code}")
        if response.status_code == 401:
            print_error(f"  Error: {response.json()['detail']}")
        return None


def test_signup_with_new_company():
    """Test 8: Signup with New Company"""
    print_section("TEST 8: Signup with New Company")

    signup_data = {
        "full_name": "Company Owner",
        "username": f"owner_{datetime.now().timestamp()}",
        "email": f"owner{datetime.now().timestamp()}@example.com",
        "phone": "+1112223333",
        "password": "OwnerPass123!",
        "auth_method": "security_questions",
        "company_type": "new",
        "company_details": {
            "company_name": f"Test Logistics {datetime.now().timestamp()}",
            "business_type": "transportation",
            "gstin": None,  # Optional
            "pan_number": None,  # Optional
            "business_email": f"info{datetime.now().timestamp()}@testlogistics.com",
            "business_phone": "+9988776655",
            "address": "123 Test Street",
            "city": "Bangalore",
            "state": "Karnataka",
            "pincode": "560001",
            "country": "India"
        },
        "security_questions": [
            {
                "question_id": "Q1",
                "question_text": "What is your mother's maiden name?",
                "answer": "Wilson"
            },
            {
                "question_id": "Q2",
                "question_text": "What was the name of your first pet?",
                "answer": "Max"
            },
            {
                "question_id": "Q3",
                "question_text": "In what city were you born?",
                "answer": "Seattle"
            }
        ],
        "terms_accepted": True
    }

    print_info(f"Creating company: {signup_data['company_details']['company_name']}")
    response = requests.post(
        f"{BASE_URL}/api/auth/signup",
        json=signup_data
    )

    if response.status_code == 201:
        data = response.json()
        print_success("Company creation successful!")
        print_info(f"  User ID: {data['user_id']}")
        print_info(f"  Username: {data['username']}")
        print_info(f"  Company: {data['company_name']}")
        print_info(f"  Role: {data['role']}")
        print_info(f"  Capabilities: {data['capabilities']}")

        return data
    else:
        print_error(f"Company creation failed: {response.status_code}")
        if response.status_code == 400:
            print_error(f"  Error: {response.json()['detail']}")
        return None


def run_all_tests():
    """Run all API tests"""
    print(f"\n{Colors.BLUE}")
    print("="*60)
    print("  FLEET MANAGEMENT SYSTEM - API TEST SUITE")
    print("="*60)
    print(f"{Colors.END}")

    print_info(f"Testing API at: {BASE_URL}")
    print_info(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    results = []

    # Test 1: Health Check
    results.append(("Health Check", test_health_check()))

    # Test 2: Security Questions
    questions = test_get_security_questions()
    results.append(("Get Security Questions", questions is not None))

    # Test 3: Company Search
    results.append(("Company Search", test_company_search()))

    # Test 4: Company Validation
    results.append(("Company Validation", test_company_validation()))

    # Test 5: Email Signup
    email_user = test_signup_email_method()
    results.append(("Signup (Email)", email_user is not None))

    # Test 6: Security Questions Signup
    sq_user = test_signup_security_questions()
    results.append(("Signup (Security Questions)", sq_user is not None))

    # Test 7: Login (with security questions user)
    token = test_login(sq_user)
    results.append(("Login", token is not None))

    # Test 8: Signup with Company
    company_data = test_signup_with_new_company()
    results.append(("Signup with Company", company_data is not None))

    # Summary
    print_section("TEST SUMMARY")

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        if result:
            print_success(f"{test_name}")
        else:
            print_error(f"{test_name}")

    print(f"\n{Colors.BLUE}Results: {passed}/{total} tests passed{Colors.END}")

    if passed == total:
        print(f"{Colors.GREEN}🎉 All tests passed!{Colors.END}\n")
    else:
        print(f"{Colors.YELLOW}⚠ Some tests failed{Colors.END}\n")


if __name__ == "__main__":
    try:
        run_all_tests()
    except requests.exceptions.ConnectionError:
        print_error("\n❌ Cannot connect to API server!")
        print_info("Make sure the backend is running:")
        print_info("  cd backend")
        print_info("  uvicorn app.main:app --reload")
    except Exception as e:
        print_error(f"\n❌ Error running tests: {e}")
        import traceback
        traceback.print_exc()
