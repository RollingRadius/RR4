"""Check all users in database"""
import psycopg2

# Connect to database
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="RR4",
    user="postgres",
    password="admin"
)

cursor = conn.cursor()

# Get all users
cursor.execute("""
    SELECT id, username, auth_method, status, email_verified, created_at
    FROM users
    ORDER BY created_at DESC
""")

users = cursor.fetchall()

print("=" * 80)
print(f"Total Users in Database: {len(users)}")
print("=" * 80)

if users:
    for user in users:
        user_id, username, auth_method, status, email_verified, created_at = user
        print(f"\nUsername: {username}")
        print(f"  ID: {user_id}")
        print(f"  Auth Method: {auth_method}")
        print(f"  Status: {status}")
        print(f"  Email Verified: {email_verified}")
        print(f"  Created: {created_at}")

        # Check security answers count
        cursor.execute("""
            SELECT COUNT(*)
            FROM user_security_answers
            WHERE user_id = %s
        """, (user_id,))
        sq_count = cursor.fetchone()[0]
        print(f"  Security Answers: {sq_count}")

        # Check if can login
        can_login = status == 'active' and (auth_method != 'email' or email_verified)
        print(f"  Can Login: {'✅ YES' if can_login else '❌ NO'}")
else:
    print("\n❌ No users found!")
    print("\nNext Steps:")
    print("1. Complete signup via Flutter app with security questions")
    print("2. Or create test user manually via backend test_signup.json")

print("\n" + "=" * 80)
print("Login Test Credentials:")
print("=" * 80)

if users:
    # Show which users can login
    cursor.execute("""
        SELECT username, auth_method, status, email_verified
        FROM users
        WHERE status = 'active'
        AND (auth_method = 'security_questions' OR email_verified = true)
    """)

    loginable_users = cursor.fetchall()

    if loginable_users:
        print("✅ These users can login now:")
        for username, auth_method, status, email_verified in loginable_users:
            print(f"\n  Username: {username}")
            print(f"  Password: Test1234! (if created with test data)")
    else:
        print("❌ No users can login yet")
        print("   (Users need status='active' and email verified OR security questions method)")

cursor.close()
conn.close()

print("\n" + "=" * 80)
