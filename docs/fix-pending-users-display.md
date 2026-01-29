# Fix: Pending Users Not Showing in Organization Management

## Problem

User created a join request for an organization (e.g., "asdf" organization), but the request wasn't showing up in the "Pending" tab of Organization Management screen.

## Root Cause

The backend query for pending users was checking `user_org.role` which is null for pending users. Pending users only have `requested_role_id` set, not `role_id`.

**Issue in code:**
```python
# backend/app/services/organization_service.py: get_pending_users()
if user_org.user and user_org.role:  # ❌ role is None for pending users!
    users.append({...})
```

## The Fix

### 1. Updated Backend Query

**File:** `backend/app/services/organization_service.py`

**Before:**
```python
pending_users = self.db.query(UserOrganization).options(
    joinedload(UserOrganization.user),
    joinedload(UserOrganization.role)  # ❌ Wrong - role is not set yet
).filter(
    UserOrganization.organization_id == organization_id,
    UserOrganization.status == 'pending'
).all()

for user_org in pending_users:
    if user_org.user and user_org.role:  # ❌ Skips all pending users
        users.append({...})
```

**After:**
```python
pending_users = self.db.query(UserOrganization).options(
    joinedload(UserOrganization.user),
    joinedload(UserOrganization.requested_role)  # ✅ Load requested_role instead
).filter(
    UserOrganization.organization_id == organization_id,
    UserOrganization.status == 'pending'
).all()

for user_org in pending_users:
    if user_org.user:  # ✅ Only check user exists
        requested_role = user_org.requested_role
        role_name = requested_role.role_name if requested_role else 'No role requested'
        users.append({
            "requested_role": role_name,  # Show what role they requested
            ...
        })
```

### 2. Enhanced Frontend Display

**File:** `frontend/lib/presentation/screens/organizations/organization_management_screen.dart`

**Changes:**
1. Added better error handling for pending tab
2. Added loading indicator
3. Display requested role in pending user cards
4. Added debug logging to track data flow

**New Features:**
- Shows "Requested: [Role Name]" badge on pending users
- Better empty state message
- Error display with retry button
- Debug logging for troubleshooting

## How Pending Users Work

### Join Request Flow

1. **User Signs Up** → Completes registration
2. **Choose "Join Existing Company"** → Searches for company
3. **Select Company** → User selects "asdf" organization
4. **Select Role** → User picks desired role (e.g., "Fleet Manager")
5. **Submit Request** → Creates UserOrganization record:
   ```sql
   INSERT INTO user_organizations (
       user_id,
       organization_id,
       role_id,              -- Set to 'pending_user' role ID
       requested_role_id,    -- Set to the role they want (e.g., Fleet Manager)
       status                -- Set to 'pending'
   )
   ```

### Approval Flow

1. **Owner Logs In** → Navigates to Organization Management
2. **Pending Tab** → Shows badge with count of pending requests
3. **View Requests** → List shows:
   - User name and username
   - Requested role (e.g., "Requested: Fleet Manager")
   - Email/Phone
   - Join date
4. **Approve** → Owner clicks approve:
   ```sql
   UPDATE user_organizations
   SET status = 'active',
       role_id = requested_role_id,  -- Assign the requested role
       approved_at = NOW(),
       approved_by = owner_user_id
   WHERE id = user_org_id
   ```
5. **User Can Access** → User can now use organization features

## Database Schema

### user_organizations Table

```sql
CREATE TABLE user_organizations (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    organization_id UUID REFERENCES organizations(id),
    role_id UUID REFERENCES roles(id),              -- Assigned role (pending_user for pending)
    requested_role_id UUID REFERENCES roles(id),    -- Role user wants
    status VARCHAR(20) DEFAULT 'pending',           -- 'pending', 'active', 'inactive'
    joined_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    approved_by UUID REFERENCES users(id)
);
```

### Example Records

**Pending User:**
```sql
id: "abc-123"
user_id: "user-456"
organization_id: "asdf-org-789"
role_id: "pending-user-role-id"        -- Pending User role
requested_role_id: "fleet-manager-id"  -- Wants to be Fleet Manager
status: "pending"
joined_at: "2026-01-29 10:00:00"
approved_at: NULL
approved_by: NULL
```

**After Approval:**
```sql
id: "abc-123"
user_id: "user-456"
organization_id: "asdf-org-789"
role_id: "fleet-manager-id"            -- NOW assigned Fleet Manager
requested_role_id: "fleet-manager-id"  -- Still shows original request
status: "active"                        -- NOW active
joined_at: "2026-01-29 10:00:00"
approved_at: "2026-01-29 11:00:00"     -- Approval timestamp
approved_by: "owner-user-id"           -- Who approved
```

## API Endpoints

### Get Pending Users

```http
GET /api/organizations/{organization_id}/pending-users
Authorization: Bearer {owner_jwt_token}
```

**Response:**
```json
{
  "success": true,
  "organization_id": "asdf-org-789",
  "organization_name": "asdf",
  "pending_users": [
    {
      "user_id": "user-456",
      "username": "john_doe",
      "full_name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "role": "Fleet Manager",
      "role_key": "fleet_manager",
      "requested_role": "Fleet Manager",
      "requested_role_key": "fleet_manager",
      "status": "pending",
      "joined_at": "2026-01-29T10:00:00Z",
      "approved_at": null,
      "is_pending": true,
      "is_active": false
    }
  ],
  "count": 1
}
```

### Approve User

```http
POST /api/organizations/{organization_id}/approve-user
Authorization: Bearer {owner_jwt_token}
Content-Type: application/json

{
  "user_id": "user-456",
  "role_key": "fleet_manager"
}
```

### Reject User

```http
POST /api/organizations/{organization_id}/reject-user
Authorization: Bearer {owner_jwt_token}
Content-Type: application/json

{
  "user_id": "user-456",
  "reason": "Position filled"
}
```

## Testing Steps

### 1. Create a Pending User Request

```bash
# As a new user, join the "asdf" organization
# This happens through the Flutter app signup flow
```

### 2. Verify Database Record

```sql
-- Check if the pending request was created
SELECT
    uo.id,
    u.username,
    o.company_name,
    r_assigned.role_name as assigned_role,
    r_requested.role_name as requested_role,
    uo.status
FROM user_organizations uo
JOIN users u ON uo.user_id = u.id
JOIN organizations o ON uo.organization_id = o.id
LEFT JOIN roles r_assigned ON uo.role_id = r_assigned.id
LEFT JOIN roles r_requested ON uo.requested_role_id = r_requested.id
WHERE uo.status = 'pending'
ORDER BY uo.joined_at DESC;
```

### 3. Test Backend API

```bash
# Get your JWT token after logging in as owner
TOKEN="your-jwt-token-here"

# Replace ORG_ID with your organization ID
ORG_ID="asdf-org-id"

# Get pending users
curl -X GET "http://192.168.1.4:8000/api/organizations/$ORG_ID/pending-users" \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Test Frontend

1. **Login as Owner** of the "asdf" organization
2. **Navigate to:** Profile Menu → Manage Organization
3. **Click:** "Pending" tab (should show badge with count)
4. **Verify:**
   - Pending user appears in list
   - Shows username and full name
   - Shows "Requested: [Role Name]" badge
   - Shows email/phone
   - Has Approve and Reject buttons

## Debug Logging

The frontend now includes debug logging:

```dart
print('Members response: ${results[0]}');
print('Pending users response: ${results[1]}');
print('Pending users count: ${pendingUsersList.length}');
```

Check your Flutter console/logs to see:
- What data is being received from the backend
- How many pending users are in the response
- Any errors during the API call

## Troubleshooting

### Pending users not showing?

1. **Check database:**
   ```sql
   SELECT * FROM user_organizations
   WHERE organization_id = 'asdf-org-id' AND status = 'pending';
   ```

2. **Check backend logs:**
   - Look for errors when calling `/api/organizations/{id}/pending-users`
   - Verify the organization ID matches

3. **Check Flutter logs:**
   - Look for the debug print statements
   - Verify API response contains pending users

4. **Verify owner access:**
   - Make sure you're logged in as the owner of the organization
   - Only owners can see pending users

### Request created but user can't access?

- Check that `status = 'pending'` (not 'active')
- Verify `requested_role_id` is set
- Ensure organization exists and is active

## Summary

✅ **Fixed backend query** to load `requested_role` instead of `role`
✅ **Show requested role** in pending user cards
✅ **Better error handling** in frontend
✅ **Debug logging** added for troubleshooting
✅ **Pending users now display** in Organization Management → Pending tab

Your pending join request for "asdf" organization should now appear in the Pending tab!
