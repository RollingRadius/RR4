"""Check if user exists and verify password"""
import psycopg2
from passlib.context import CryptContext

# Password hasher
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Connect to database
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="RR4",
    user="postgres",
    password="admin"
)

cursor = conn.cursor()

# Check if testuser2 exists
cursor.execute("""
    SELECT id, username, full_name, auth_method, status, email_verified,
           password_hash, created_at
    FROM users
    WHERE username = 'testuser2'
""")

user = cursor.fetchone()

if user:
    print("User found!")
    print("="*60)
    print(f"ID: {user[0]}")
    print(f"Username: {user[1]}")
    print(f"Full Name: {user[2]}")
    print(f"Auth Method: {user[3]}")
    print(f"Status: {user[4]}")
    print(f"Email Verified: {user[5]}")
    print(f"Password Hash: {user[6][:50]}...")
    print(f"Created: {user[7]}")
    print("="*60)

    # Test password verification
    password_hash = user[6]
    test_password = "Test1234!"

    print(f"\nTesting password: '{test_password}'")
    try:
        is_valid = pwd_context.verify(test_password, password_hash)
        if is_valid:
            print("Password verification: VALID")
        else:
            print("Password verification: INVALID")
    except Exception as e:
        print(f"Password verification ERROR: {e}")

    # Check security answers
    cursor.execute("""
        SELECT COUNT(*)
        FROM user_security_answers
        WHERE user_id = %s
    """, (user[0],))

    sq_count = cursor.fetchone()[0]
    print(f"\nSecurity Answers: {sq_count} (should be 3)")

else:
    print("User NOT found!")
    print("\nChecking all users:")
    cursor.execute("SELECT username, auth_method, status FROM users")
    all_users = cursor.fetchall()
    for u in all_users:
        print(f"  - {u[0]} ({u[1]}) - {u[2]}")

cursor.close()
conn.close()
