"""Simple database connection test"""
import psycopg2
import sys

configs = [
    ("admin", "admin", "RR4"),
    ("postgres", "admin", "RR4"),
    ("postgres", "postgres", "RR4"),
    ("admin", "", "RR4"),  # Empty password
]

print("Testing database connections...")
print("="*60)

for user, password, db in configs:
    try:
        print(f"\nTrying: user='{user}', password='{password}', database='{db}'")
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database=db,
            user=user,
            password=password
        )
        print("SUCCESS! Connection works!")
        cursor = conn.cursor()
        cursor.execute("SELECT current_database(), current_user;")
        result = cursor.fetchone()
        print(f"Connected to database: {result[0]} as user: {result[1]}")
        cursor.close()
        conn.close()

        print(f"\nUse this in .env:")
        print(f"DATABASE_URL=postgresql://{user}:{password}@localhost:5432/{db}")
        sys.exit(0)

    except Exception as e:
        print(f"FAILED: {str(e)[:100]}")

print("\n" + "="*60)
print("All attempts failed!")
print("\nPlease check:")
print("1. Is PostgreSQL running?")
print("2. Does database 'RR4' exist?")
print("3. What are the correct username and password?")
print("\nYou can check with pgAdmin or run:")
print('  psql -U postgres -l  (list databases)')
