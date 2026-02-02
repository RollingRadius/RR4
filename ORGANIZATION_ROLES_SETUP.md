# Organization Roles Setup - Complete

## Date: 2026-02-02

## Changes Made

### 1. Created Database Migration ✅
**File:** `backend/alembic/versions/011_add_organization_roles.py`

Added 4 organization member roles:
- **Admin** - Can manage members and settings
- **Dispatcher** - Can manage trips and assignments
- **User** - Standard access to features
- **Viewer** - Read-only access

### 2. Updated Frontend Dialog ✅
**File:** `frontend/lib/presentation/screens/organizations/organization_management_screen.dart`

Fixed the role selection dialog:
- ✅ Shows only the 4 roles that backend supports
- ✅ Each role has an icon and color
- ✅ Clear descriptions for each role
- ✅ OK button to confirm selection
- ✅ Visual feedback when a role is selected
- ✅ Scrollable dialog for better UX

## How to Verify Migration Worked

### 1. Check Migration Status
```bash
cd backend
python -m alembic current
```

**Expected output:**
```
011_add_organization_roles (head)
```

### 2. Verify Roles in Database
Connect to your PostgreSQL database and run:

```sql
SELECT role_key, role_name, description, is_system_role
FROM roles
ORDER BY is_system_role DESC, role_name;
```

**Expected output:**
```
role_key         | role_name        | description                          | is_system_role
-----------------|------------------|--------------------------------------|---------------
owner            | Owner            | Full access to company resources     | true
pending_user     | Pending User     | User awaiting role assignment        | true
independent_user | Independent User | User without company affiliation     | true
admin            | Admin            | Can manage members and settings      | false
dispatcher       | Dispatcher       | Can manage trips and assignments     | false
user             | User             | Standard access to features          | false
viewer           | Viewer           | Read-only access                     | false
```

### 3. Check Backend Logs
When you start the backend, you should see:
```
INFO:     Application startup complete.
```

No errors about missing migrations.

## Testing the Approve User Flow

### Step 1: Start Backend
```bash
cd backend
python -m uvicorn app.main:app --reload
```

**Verify:** Backend starts without errors at http://localhost:8000

### Step 2: Start Frontend
```bash
cd frontend
flutter run
```

### Step 3: Test Approval Flow

1. **Login as Owner/Admin**
   - Use credentials for a user who created an organization

2. **Navigate to Organization Management**
   - Go to Organizations → Select your organization
   - Click on the organization name to open management screen

3. **Check Pending Tab**
   - Should see a badge with count of pending users
   - Should see list of users waiting for approval

4. **Approve a User**
   - Click the green checkmark (✓) icon on a pending user
   - **Expected:** Dialog opens with 4 roles:
     - Admin (red shield icon)
     - Dispatcher (purple assignment icon)
     - User (blue person icon)
     - Viewer (grey eye icon)
   - Select a role (card should highlight with colored border)
   - Click **OK** button
   - **Expected:** Success message "Username approved successfully"
   - **Expected:** User moves from Pending tab to Members tab

5. **Verify in Members Tab**
   - User should appear with assigned role shown as a chip
   - Role chip color: Admin=amber, others=blue

### Step 4: Check Backend Logs

**Successful approval should show:**
```
INFO: POST /api/organizations/{org_id}/approve-user HTTP/1.1 200 OK
```

**If you see 400 errors, check:**
```sql
-- Verify the role exists
SELECT * FROM roles WHERE role_key = 'admin';
```

## API Endpoint Details

### POST /api/organizations/{organization_id}/approve-user

**Request Body:**
```json
{
  "user_id": "uuid-of-pending-user",
  "role_key": "admin"  // or "dispatcher", "user", "viewer"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "User approved successfully",
  "user_id": "uuid-of-user",
  "role_assigned": "Admin"
}
```

**Response (Error - 400):**
```json
{
  "detail": "Invalid role: admin"
}
```
↑ This means the migration didn't run or role doesn't exist in database

## Troubleshooting

### Problem: "Invalid role: admin" Error

**Solution 1:** Check migration status
```bash
cd backend
python -m alembic current
```

If not on `011_add_organization_roles`, run:
```bash
python -m alembic upgrade head
```

**Solution 2:** Manually insert roles
If migration fails, run this SQL directly:

```sql
INSERT INTO roles (role_name, role_key, description, is_system_role) VALUES
('Admin', 'admin', 'Can manage members and settings', false),
('Dispatcher', 'dispatcher', 'Can manage trips and assignments', false),
('User', 'user', 'Standard access to features', false),
('Viewer', 'viewer', 'Read-only access', false)
ON CONFLICT (role_key) DO NOTHING;
```

### Problem: Dialog doesn't show roles

**Check:**
1. Frontend compiled successfully
2. No console errors in browser DevTools
3. Dialog component is using updated code

**Fix:** Hard refresh browser (Ctrl+F5) or restart Flutter app

### Problem: User can't approve (button disabled)

**Check:**
1. Current user is Owner or Admin role
2. User being approved is in "pending" status
3. Backend permissions are working

## Role Hierarchy

```
SYSTEM ROLES (Cannot be assigned through approval):
├── Owner (created when organization is created)
├── Pending User (temporary status)
└── Independent User (users without organization)

ORGANIZATION ROLES (Can be assigned through approval):
├── Admin (highest organization-level access)
├── Dispatcher (operational management)
├── User (standard member)
└── Viewer (read-only)
```

## Database Schema

```sql
-- Roles table structure
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(100) UNIQUE NOT NULL,
    role_key VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- User-Organization relationship
CREATE TABLE user_organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    role_id UUID REFERENCES roles(id),
    requested_role_id UUID REFERENCES roles(id),
    status VARCHAR(20) NOT NULL,  -- 'pending' or 'active'
    joined_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    approved_by UUID REFERENCES users(id)
);
```

## Next Steps

1. ✅ Run migration: `python -m alembic upgrade head`
2. ✅ Restart backend server
3. ✅ Test approve user flow
4. ✅ Verify user appears in Members tab with correct role
5. ✅ Test reject user flow (red X icon)
6. ✅ Test change role for existing members (popup menu)

## Files Modified

### Backend
- **Created:** `backend/alembic/versions/011_add_organization_roles.py`

### Frontend
- **Modified:** `frontend/lib/presentation/screens/organizations/organization_management_screen.dart`
  - Replaced hardcoded 4 roles with new dialog component
  - Added `_RoleSelectionDialog` widget with all features
  - Updated approve and change role flows

## Summary

✅ **Backend:** Migration created to add 4 organization roles
✅ **Frontend:** Dialog updated with icons, descriptions, and OK button
✅ **API:** Will work correctly once migration is applied
✅ **UX:** Clean, professional role selection interface

**Status:** Ready for testing after running migration!

---

**Last Updated:** 2026-02-02 17:20:00
