# Driver User Account Creation

## Overview

When an owner creates a driver in the system, a user account is automatically created for that driver. This allows the driver to log into the application with their own credentials and access driver-specific features.

## What Changed

### 1. Database Schema Update

**File:** `backend/app/models/driver.py`

Added `user_id` field to link driver profile to user account:

```python
# User Account Reference (1-to-1 relationship)
user_id = Column(
    UUID(as_uuid=True),
    ForeignKey("users.id", ondelete="SET NULL"),
    nullable=True,
    unique=True,
    index=True
)
```

**Relationship:**
- Driver ↔ User (1-to-1)
- Each driver has one user account
- Each user account can have one driver profile

### 2. Driver Creation Process

**File:** `backend/app/services/driver_service.py`

When owner creates a driver, the system now:

1. **Creates User Account**
   - Username and password provided by owner
   - Password is hashed before storage
   - User is auto-verified (no email verification needed)
   - Profile status set to 'complete'

2. **Assigns Driver Role**
   - Automatically assigns 'driver' role
   - Creates UserOrganization link
   - Status set to 'active'
   - Approved by the creating user (owner)

3. **Creates Driver Profile**
   - Links to the created user account (user_id)
   - Includes all driver-specific information
   - License information stored separately

4. **Audit Logging**
   - Logs user account creation
   - Logs driver profile creation
   - Tracks who created the driver

### 3. API Schema Update

**File:** `backend/app/schemas/driver.py`

Added required fields to `DriverCreateRequest`:

```python
# User Account Information (for driver login)
username: str = Field(..., min_length=3, max_length=50)
password: str = Field(..., min_length=8)
```

**Username Requirements:**
- 3-50 characters
- Alphanumeric with underscores
- Must be unique across the system

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit

## User Flow

### Creating a Driver (Owner Perspective)

1. **Owner logs in** to the fleet management system
2. **Navigate to Drivers** → Add Driver
3. **Fill in driver details:**
   - Username (for driver login)
   - Password (to be given to driver)
   - Employee ID
   - Personal information (name, phone, email)
   - Address details
   - Emergency contact
   - License information
4. **Submit** → Driver and user account created
5. **Credentials displayed** → Owner can share with driver

### Driver Login (Driver Perspective)

1. **Receive credentials** from owner
   - Username
   - Password
2. **Open the app** and login
3. **Access driver features:**
   - View assigned trips
   - Update trip status (start, complete)
   - Share GPS location
   - Report vehicle issues
   - View trip history

## API Request Example

### Create Driver with User Account

**Endpoint:** `POST /api/drivers`

**Request Body:**
```json
{
  "username": "john_driver",
  "password": "SecurePass123",
  "employee_id": "EMP001",
  "join_date": "2026-01-29",
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "date_of_birth": "1990-05-15",
  "address": "123 Main St",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "country": "India",
  "emergency_contact_name": "Jane Doe",
  "emergency_contact_phone": "9876543211",
  "emergency_contact_relationship": "Spouse",
  "license": {
    "license_number": "MH01-20230001234",
    "license_type": "HMV",
    "issue_date": "2023-01-15",
    "expiry_date": "2028-01-15",
    "issuing_authority": "RTO Mumbai",
    "issuing_state": "Maharashtra"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Driver and user account created successfully",
  "driver_id": "uuid-here",
  "user_id": "uuid-here",
  "username": "john_driver",
  "driver_name": "John Doe",
  "employee_id": "EMP001",
  "credentials": {
    "username": "john_driver",
    "note": "Please provide these credentials to the driver"
  }
}
```

## Database Migration

A database migration is needed to add the `user_id` column to the `drivers` table:

```sql
-- Add user_id column to drivers table
ALTER TABLE drivers
ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE SET NULL,
ADD CONSTRAINT drivers_user_id_unique UNIQUE (user_id);

-- Create index for better query performance
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
```

**To run migration:**
```bash
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Create migration
alembic revision --autogenerate -m "Add user_id to drivers table"

# Review the migration file in alembic/versions/

# Apply migration
alembic upgrade head
```

## Security Considerations

### Password Security
- ✅ Passwords are hashed using bcrypt before storage
- ✅ Plain text passwords never stored in database
- ✅ Password requirements enforce strong passwords
- ✅ Password is only shown once during creation

### Account Security
- ✅ Username uniqueness enforced at database level
- ✅ Driver accounts auto-verified (trusted by owner)
- ✅ Driver role automatically assigned
- ✅ Audit logs track account creation

### Access Control
- ✅ Only organization owners/admins can create drivers
- ✅ Driver accounts limited to driver role permissions
- ✅ Drivers can only access their own data
- ✅ Cannot view other drivers' information

## Benefits

### For Fleet Owners
- ✅ Easy driver onboarding
- ✅ Centralized user management
- ✅ Control over credentials
- ✅ Audit trail of account creation

### For Drivers
- ✅ Personal login credentials
- ✅ Access to assigned trips
- ✅ Mobile app access
- ✅ Real-time updates

### For System
- ✅ Consistent user management
- ✅ Role-based access control
- ✅ Better security
- ✅ Audit logging

## Frontend Changes Needed

### Add Driver Screen

**File:** `frontend/lib/presentation/screens/drivers/add_driver_screen.dart`

Add these fields to the form:

1. **Username Field**
   ```dart
   TextFormField(
     controller: _usernameController,
     decoration: InputDecoration(
       labelText: 'Username for Driver Login',
       hintText: 'Enter username (3-50 characters)',
       prefixIcon: Icon(Icons.person),
     ),
     validator: (value) {
       if (value == null || value.isEmpty) {
         return 'Username is required';
       }
       if (!RegExp(r'^[a-zA-Z0-9_]{3,50}$').hasMatch(value)) {
         return 'Username: 3-50 alphanumeric characters';
       }
       return null;
     },
   )
   ```

2. **Password Field**
   ```dart
   TextFormField(
     controller: _passwordController,
     obscureText: _obscurePassword,
     decoration: InputDecoration(
       labelText: 'Password for Driver Login',
       hintText: 'Create a strong password',
       prefixIcon: Icon(Icons.lock),
       suffixIcon: IconButton(
         icon: Icon(
           _obscurePassword ? Icons.visibility : Icons.visibility_off,
         ),
         onPressed: () {
           setState(() {
             _obscurePassword = !_obscurePassword;
           });
         },
       ),
     ),
     validator: (value) {
       if (value == null || value.isEmpty) {
         return 'Password is required';
       }
       if (value.length < 8) {
         return 'Password must be at least 8 characters';
       }
       if (!RegExp(r'[A-Z]').hasMatch(value)) {
         return 'Must contain uppercase letter';
       }
       if (!RegExp(r'[a-z]').hasMatch(value)) {
         return 'Must contain lowercase letter';
       }
       if (!RegExp(r'\d').hasMatch(value)) {
         return 'Must contain digit';
       }
       return null;
     },
   )
   ```

3. **Info Box**
   ```dart
   Container(
     padding: EdgeInsets.all(12),
     decoration: BoxDecoration(
       color: Colors.blue.shade50,
       borderRadius: BorderRadius.circular(8),
     ),
     child: Row(
       children: [
         Icon(Icons.info_outline, color: Colors.blue),
         SizedBox(width: 8),
         Expanded(
           child: Text(
             'These credentials will be used by the driver to log into the app. Please save them and share with the driver.',
             style: TextStyle(fontSize: 12),
           ),
         ),
       ],
     ),
   )
   ```

4. **Success Dialog** (after creation)
   ```dart
   showDialog(
     context: context,
     barrierDismissible: false,
     builder: (context) => AlertDialog(
       title: Text('Driver Created Successfully'),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text('Driver has been added with the following credentials:'),
           SizedBox(height: 16),
           Text('Username: ${response['username']}',
                style: TextStyle(fontWeight: FontWeight.bold)),
           Text('Password: (shown once)',
                style: TextStyle(color: Colors.red)),
           SizedBox(height: 16),
           Text('Please save these credentials and provide them to the driver.',
                style: TextStyle(fontStyle: FontStyle.italic)),
         ],
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.of(context).pop(),
           child: Text('OK'),
         ),
       ],
     ),
   );
   ```

## Testing

### Test Driver Creation

1. **Login as Owner**
   ```bash
   POST /api/auth/login
   {
     "username": "owner",
     "password": "password"
   }
   ```

2. **Create Driver**
   ```bash
   POST /api/drivers
   Authorization: Bearer {owner_token}
   {
     "username": "test_driver",
     "password": "TestPass123",
     ... driver details ...
   }
   ```

3. **Verify in Database**
   ```sql
   -- Check user created
   SELECT id, username, full_name, is_verified
   FROM users
   WHERE username = 'test_driver';

   -- Check driver profile
   SELECT id, user_id, first_name, last_name, employee_id
   FROM drivers
   WHERE user_id = (SELECT id FROM users WHERE username = 'test_driver');

   -- Check role assignment
   SELECT uo.*, r.role_name
   FROM user_organizations uo
   JOIN roles r ON uo.role_id = r.id
   WHERE uo.user_id = (SELECT id FROM users WHERE username = 'test_driver');
   ```

4. **Test Driver Login**
   ```bash
   POST /api/auth/login
   {
     "username": "test_driver",
     "password": "TestPass123"
   }
   ```

5. **Verify Driver Access**
   - Driver should be able to login
   - Should have 'driver' role
   - Should see driver-specific features

## Troubleshooting

### Error: "Username already taken"
- **Cause:** Username exists in database
- **Solution:** Choose a different username

### Error: "Driver role not found"
- **Cause:** 'driver' role doesn't exist in roles table
- **Solution:** Seed roles in database

### Error: "Password does not meet requirements"
- **Cause:** Weak password
- **Solution:** Use strong password with uppercase, lowercase, and digit

### Driver can't login
- **Cause:** Account not created or wrong credentials
- **Solution:** Check users table, verify credentials

## Summary

✅ **Added user_id to Driver model** - Links driver to user account
✅ **Updated driver creation service** - Creates user account automatically
✅ **Added username/password to schema** - Required fields for driver creation
✅ **Audit logging** - Tracks user and driver creation
✅ **Security** - Password hashing, role assignment, access control
✅ **Documentation** - Complete guide for implementation

Drivers can now log into the application with their own credentials and access driver-specific features!
