"""
Test database connection
Run this to verify your database credentials are correct
"""
import psycopg2
from psycopg2 import OperationalError

def test_connection():
    """Test PostgreSQL connection with different credentials"""

    # Test configurations
    configs = [
        {
            "name": "Config from .env (admin/admin)",
            "host": "localhost",
            "port": 5432,
            "database": "RR4",
            "user": "admin",
            "password": "admin"
        },
        {
            "name": "Try with postgres user",
            "host": "localhost",
            "port": 5432,
            "database": "RR4",
            "user": "postgres",
            "password": "admin"
        },
        {
            "name": "Try with postgres/postgres",
            "host": "localhost",
            "port": 5432,
            "database": "RR4",
            "user": "postgres",
            "password": "postgres"
        }
    ]

    for config in configs:
        print(f"\n{'='*60}")
        print(f"Testing: {config['name']}")
        print(f"Connection: {config['user']}@{config['host']}:{config['port']}/{config['database']}")
        print(f"{'='*60}")

        try:
            conn = psycopg2.connect(
                host=config["host"],
                port=config["port"],
                database=config["database"],
                user=config["user"],
                password=config["password"]
            )

            print("✅ CONNECTION SUCCESSFUL!")

            # Test query
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            version = cursor.fetchone()
            print(f"✅ PostgreSQL Version: {version[0]}")

            cursor.close()
            conn.close()

            print(f"\n🎉 SUCCESS! Use these credentials:")
            print(f"   DATABASE_URL=postgresql://{config['user']}:{config['password']}@{config['host']}:{config['port']}/{config['database']}")
            return config

        except OperationalError as e:
            print(f"❌ CONNECTION FAILED")
            print(f"   Error: {str(e)}")

        except Exception as e:
            print(f"❌ UNEXPECTED ERROR")
            print(f"   Error: {str(e)}")

    print(f"\n{'='*60}")
    print("❌ ALL CONNECTION ATTEMPTS FAILED")
    print(f"{'='*60}")
    print("\nPlease verify:")
    print("1. PostgreSQL is running")
    print("2. Database 'RR4' exists")
    print("3. User credentials are correct")
    print("\nTo check, open pgAdmin or run:")
    print('   psql -U postgres -c "\\l"  (list databases)')
    print('   psql -U postgres -c "\\du" (list users)')
    return None

if __name__ == "__main__":
    print("=" * 60)
    print("Fleet Management System - Database Connection Test")
    print("=" * 60)

    result = test_connection()

    if not result:
        print("\n💡 TROUBLESHOOTING TIPS:")
        print("\n1. Check if PostgreSQL is running:")
        print("   - Open Services (services.msc)")
        print("   - Look for 'postgresql' service")
        print("   - Make sure it's running")
        print("\n2. Verify database exists:")
        print("   - Open pgAdmin")
        print("   - Check if 'RR4' database is listed")
        print("   - If not, create it: CREATE DATABASE RR4;")
        print("\n3. Check user and password:")
        print("   - What username did you use to create the database?")
        print("   - Try connecting with pgAdmin to verify credentials")
