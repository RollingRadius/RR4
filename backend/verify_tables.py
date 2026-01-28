"""Verify database tables were created"""
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="RR4",
    user="postgres",
    password="admin"
)

cursor = conn.cursor()

# Get all tables
cursor.execute("""
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name;
""")

tables = cursor.fetchall()

print("="*60)
print("DATABASE TABLES IN 'RR4'")
print("="*60)

if tables:
    for idx, (table,) in enumerate(tables, 1):
        print(f"{idx}. {table}")

        # Count rows in each table
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"   Rows: {count}")
else:
    print("No tables found!")

# Check for security questions
print("\n" + "="*60)
print("CHECKING SECURITY QUESTIONS")
print("="*60)
cursor.execute("SELECT COUNT(*) FROM security_questions")
sq_count = cursor.fetchone()[0]
print(f"Security Questions: {sq_count}")

if sq_count > 0:
    cursor.execute("SELECT question_key, question_text FROM security_questions ORDER BY display_order LIMIT 3")
    questions = cursor.fetchall()
    print("\nSample questions:")
    for key, text in questions:
        print(f"  {key}: {text}")

# Check roles
print("\n" + "="*60)
print("CHECKING ROLES")
print("="*60)
cursor.execute("SELECT COUNT(*) FROM roles")
roles_count = cursor.fetchone()[0]
print(f"Roles: {roles_count}")

if roles_count > 0:
    cursor.execute("SELECT role_name, description FROM roles")
    roles = cursor.fetchall()
    for name, desc in roles:
        print(f"  - {name}: {desc}")

cursor.close()
conn.close()

print("\n" + "="*60)
print("DATABASE SETUP COMPLETE!")
print("="*60)
