# Fix: Ambiguous Foreign Keys Error

## Problem

SQLAlchemy was throwing an error:
```
sqlalchemy.exc.AmbiguousForeignKeysError: Can't determine join between 'roles' and 'user_organizations';
tables have more than one foreign key constraint relationship between them.
```

### Root Cause

The `user_organizations` table has **TWO foreign keys** pointing to the `roles` table:

1. **`role_id`** - The actual assigned role
2. **`requested_role_id`** - The role the user requested when joining

When SQLAlchemy tried to join these tables without explicit foreign key specification, it didn't know which one to use.

## Solution

### 1. Fixed Role Model Relationship
**File:** `backend/app/models/role.py`

**Before:**
```python
user_organizations = relationship(
    "UserOrganization",
    back_populates="role"
)
```

**After:**
```python
user_organizations = relationship(
    "UserOrganization",
    foreign_keys="[UserOrganization.role_id]",  # Specify which FK to use
    back_populates="role"
)
```

### 2. Fixed Queries in Multiple Files

Updated all queries that join `UserOrganization` with `Role` to explicitly specify the foreign key:

#### user.py
**Before:**
```python
user_orgs = db.query(UserOrganization).filter(
    UserOrganization.user_id == current_user.id
).join(Organization).join(Role).all()
```

**After:**
```python
user_orgs = db.query(UserOrganization).filter(
    UserOrganization.user_id == current_user.id
).join(Organization).join(
    Role, UserOrganization.role_id == Role.id  # Explicit join condition
).all()
```

#### organization_management.py (2 places)
```python
# Fixed join conditions
owner_org = db.query(UserOrganization).join(
    Role, UserOrganization.role_id == Role.id
).filter(...)

query = query.join(
    Role, UserOrganization.role_id == Role.id
).filter(Role.role_key == role_filter)
```

#### roles.py (3 places)
```python
# Fixed all owner_org queries
owner_org = db.query(UserOrganization).join(
    Role, UserOrganization.role_id == Role.id
).filter(...)
```

## Why This Happened

When we added the `requested_role_id` field to track user role requests, we created a second foreign key relationship between `user_organizations` and `roles`. SQLAlchemy relationships need to be explicit when there are multiple foreign keys between the same tables.

## Files Modified

1. `backend/app/models/role.py` - Added foreign_keys specification
2. `backend/app/api/v1/user.py` - Fixed join in get_user_organizations()
3. `backend/app/api/v1/organization_management.py` - Fixed 2 joins
4. `backend/app/api/v1/roles.py` - Fixed 3 joins

## Testing

After the fix, the endpoint works correctly:

```bash
$ curl http://192.168.1.4:8000/api/user/organizations
{"detail":"Not authenticated"}  # Expected - needs JWT token
```

No SQLAlchemy errors! The organization page should now work properly in the frontend.

## Prevention

When adding foreign keys that create multiple relationships to the same table:

1. **Always specify `foreign_keys` in the relationship definition**
2. **Use explicit join conditions in queries** when joining tables with multiple FKs
3. **Test the endpoint immediately** after adding new foreign keys

## Related Documentation

- Database schema: `docs/organization-data-flow.md`
- Role selection feature: `docs/role-selection-feature.md`
- Organization dashboard: `docs/organization-dashboard-feature.md`
