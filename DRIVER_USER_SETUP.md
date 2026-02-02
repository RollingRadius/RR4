# Driver User Account Setup - Quick Guide

## What's New?

When creating a driver, you now also create a user account for them so they can log into the application!

## 🔧 Setup Steps

### 1. Run Database Migration

```bash
cd E:\Projects\RR4\backend

# Activate virtual environment
venv\Scripts\activate

# Run the migration
alembic upgrade head
```

**This will:**
- Add `user_id` column to `drivers` table
- Create foreign key to `users` table
- Add unique constraint and index

### 2. Restart Backend Server

```bash
# Stop current server (Ctrl+C)
# Then restart:
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Or use the startup script:
```bash
start_server.bat
```

### 3. Update Frontend (Add Driver Screen)

The driver creation form now requires two additional fields:

#### Required Fields:
- **Username** (for driver login)
- **Password** (for driver login)

See `docs/driver-user-account-creation.md` for complete frontend implementation guide.

## 📝 How It Works

### When Owner Creates a Driver:

1. **Owner fills form:**
   - Driver details (name, phone, address, etc.)
   - **NEW:** Username (e.g., "john_driver")
   - **NEW:** Password (e.g., "SecurePass123")
   - License information

2. **System automatically:**
   - ✅ Creates user account with username & hashed password
   - ✅ Assigns "driver" role
   - ✅ Links user to organization
   - ✅ Creates driver profile
   - ✅ Stores license information
   - ✅ Logs audit events

3. **Owner receives:**
   - Driver ID
   - User ID
   - Confirmation with credentials to share

4. **Driver can now:**
   - ✅ Login with username & password
   - ✅ View assigned trips
   - ✅ Update trip status
   - ✅ Share GPS location
   - ✅ Report vehicle issues

## 🧪 Testing

### 1. Create a Test Driver

```bash
curl -X POST http://localhost:8000/api/drivers \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_driver",
    "password": "TestPass123",
    "employee_id": "EMP001",
    "join_date": "2026-01-29",
    "first_name": "Test",
    "last_name": "Driver",
    "phone": "9876543210",
    "license": {
      "license_number": "TEST1234567890",
      "license_type": "HMV",
      "issue_date": "2023-01-01",
      "expiry_date": "2028-01-01"
    }
  }'
```

### 2. Verify Driver Can Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_driver",
    "password": "TestPass123"
  }'
```

**Expected:** Success with JWT token

### 3. Check Database

```sql
-- View user account
SELECT id, username, full_name, is_verified
FROM users
WHERE username = 'test_driver';

-- View driver profile
SELECT d.id, d.user_id, d.first_name, d.last_name, d.employee_id
FROM drivers d
WHERE d.user_id = (SELECT id FROM users WHERE username = 'test_driver');

-- View role assignment
SELECT u.username, r.role_name, uo.status
FROM user_organizations uo
JOIN users u ON uo.user_id = u.id
JOIN roles r ON uo.role_id = r.id
WHERE u.username = 'test_driver';
```

## 📋 API Changes

### Create Driver Endpoint

**Before:**
```json
{
  "employee_id": "EMP001",
  "first_name": "John",
  "last_name": "Doe",
  ... other fields ...
}
```

**After (New Required Fields):**
```json
{
  "username": "john_driver",     // ← NEW: Required
  "password": "SecurePass123",   // ← NEW: Required
  "employee_id": "EMP001",
  "first_name": "John",
  "last_name": "Doe",
  ... other fields ...
}
```

### Password Requirements

✅ Minimum 8 characters
✅ At least one uppercase letter
✅ At least one lowercase letter
✅ At least one digit

### Username Requirements

✅ 3-50 characters
✅ Alphanumeric with underscores
✅ Must be unique

## 🔒 Security Features

- ✅ Passwords hashed with bcrypt (never stored in plain text)
- ✅ Username uniqueness enforced
- ✅ Strong password validation
- ✅ Driver role auto-assigned
- ✅ Audit logging for all actions
- ✅ Auto-verified accounts (trusted by owner)

## 🎯 Benefits

### For Owners
- Easy driver onboarding
- Control over credentials
- Centralized management

### For Drivers
- Personal login credentials
- Access to mobile app
- Real-time trip updates

## 📖 Documentation

Complete details in: `docs/driver-user-account-creation.md`

## ⚠️ Important Notes

1. **Migration Required:** Must run database migration before using this feature
2. **Existing Drivers:** Old drivers without user accounts can still exist (user_id nullable)
3. **Frontend Update Needed:** Add username and password fields to driver creation form
4. **Credentials:** Password is only shown once during creation - owner must save it
5. **Backend Restart:** Restart backend after migration for changes to take effect

## 🚀 Status

- ✅ Database model updated
- ✅ Service layer implemented
- ✅ API schema updated
- ✅ Migration created
- ✅ Documentation complete
- ⏳ Frontend update needed
- ⏳ Migration needs to be run

## Next Steps

1. Run the database migration: `alembic upgrade head`
2. Restart backend server
3. Update frontend add driver screen
4. Test driver creation
5. Test driver login

---

**Ready to go! Just run the migration and restart the server.**
