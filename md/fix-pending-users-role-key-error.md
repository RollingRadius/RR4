# Fix: Pending Users Role Key Validation Error

## Error Description

**Error:** 500 Internal Server Error when accessing `/api/organizations/{id}/pending-users`

**Full Error:**
```
pydantic_core._pydantic_core.ValidationError: 1 validation error for PendingUsersResponse
pending_users.0.role_key
  Input should be a valid string [type=string_type, input_value=None, input_type=NoneType]
```

## Root Cause

When a pending user doesn't have a `requested_role` set in the database, the service was returning `None` for the `role_key` field. However, the Pydantic response model `OrganizationMemberResponse` defines `role_key: str` (not `Optional[str]`), which means it cannot accept `None` values.

**Issue Location:**
- **File:** `backend/app/services/organization_service.py`
- **Line:** 204
- **Problem Code:**
  ```python
  role_key = requested_role.role_key if requested_role else None  # ❌ Returns None
  ```

**Schema Expectation:**
- **File:** `backend/app/schemas/organization.py`
- **Line:** 19
- **Schema Definition:**
  ```python
  class OrganizationMemberResponse(BaseModel):
      ...
      role_key: str  # ❌ Expects string, cannot be None
      ...
  ```

## The Fix

Changed the default value from `None` to `'pending_user'` when `requested_role` is not set.

**File:** `backend/app/services/organization_service.py`

**Before (Line 204):**
```python
role_key = requested_role.role_key if requested_role else None  # ❌ Invalid
```

**After (Line 204):**
```python
role_key = requested_role.role_key if requested_role else 'pending_user'  # ✅ Valid string
```

## Why 'pending_user' as Default?

1. **Valid String:** Satisfies Pydantic's string type requirement
2. **Descriptive:** Clearly indicates the user is pending
3. **Consistent:** Matches the intended workflow where pending users have a temporary role
4. **Safe:** Won't cause validation errors even if requested_role is missing

## Testing

### Before Fix
```bash
# Request would fail with 500 error
GET /api/organizations/c402ab1b-763f-4844-9237-0de8c6482fd2/pending-users
# Error: ValidationError - role_key cannot be None
```

### After Fix
```bash
# Request succeeds
GET /api/organizations/c402ab1b-763f-4844-9237-0de8c6482fd2/pending-users

# Response:
{
  "success": true,
  "organization_id": "c402ab1b-763f-4844-9237-0de8c6482fd2",
  "organization_name": "Organization Name",
  "pending_users": [
    {
      "user_id": "...",
      "username": "john_doe",
      "role": "No role requested",
      "role_key": "pending_user",  // ✅ Valid string instead of null
      "requested_role": "No role requested",
      "requested_role_key": "pending_user",  // ✅ Valid string instead of null
      "status": "pending",
      ...
    }
  ],
  "count": 1
}
```

## Alternative Solutions Considered

### Option 1: Make role_key Optional in Schema (Not Chosen)
```python
# In backend/app/schemas/organization.py
class OrganizationMemberResponse(BaseModel):
    ...
    role_key: Optional[str]  # Allow None
    ...
```

**Why Not:** This would allow None values everywhere, even for active members where role_key should always be present. Better to fix at the source.

### Option 2: Use Empty String (Not Chosen)
```python
role_key = requested_role.role_key if requested_role else ''
```

**Why Not:** An empty string is less descriptive than 'pending_user' and might cause confusion.

### Option 3: Use 'pending_user' (Chosen) ✅
```python
role_key = requested_role.role_key if requested_role else 'pending_user'
```

**Why Yes:** Clear, descriptive, and matches the user's actual status.

## Impact

- **Users Affected:** Pending users without a requested_role set
- **Endpoints Fixed:** `/api/organizations/{id}/pending-users`
- **Breaking Changes:** None (only changes default value for missing data)
- **Database Changes:** None required
- **Frontend Changes:** None required (frontend already handles the display)

## Backend Restart

After making the code change:

1. **With --reload flag:** Changes are automatically detected and server reloads
2. **Manual restart:**
   ```bash
   cd backend
   # Stop server (Ctrl+C)
   # Restart
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

## Related Issues

This fix is related to the earlier pending users fix documented in:
- `docs/fix-pending-users-display.md`

The earlier fix changed the query to use `requested_role` instead of `role`, but didn't account for cases where `requested_role` might be `None`.

## Verification

To verify the fix works:

1. **Create a pending user** without a requested_role in database:
   ```sql
   INSERT INTO user_organizations (user_id, organization_id, status, requested_role_id)
   VALUES ('user-id', 'org-id', 'pending', NULL);  -- requested_role_id is NULL
   ```

2. **Call the endpoint:**
   ```bash
   curl http://localhost:8000/api/organizations/{org-id}/pending-users \
     -H "Authorization: Bearer {token}"
   ```

3. **Check response:**
   - Should return 200 OK
   - `role_key` should be "pending_user" (not null)
   - No validation errors

## Summary

✅ **Fixed validation error** by providing default value
✅ **Used descriptive default** ('pending_user' instead of None)
✅ **No schema changes needed**
✅ **Backend automatically reloaded** with fix
✅ **Pending users endpoint now works** without errors

The Organization Management screen's Pending tab should now load successfully without 500 errors!
