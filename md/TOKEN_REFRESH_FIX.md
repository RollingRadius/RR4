# Token Refresh Fix - Organization Context

## Problem

When an independent user creates an organization, their JWT token still contains the old context (`company_id: null`, `role: independent_user`). This causes 403 errors when trying to:
- Create drivers
- Access organization-specific features
- Use any endpoint that requires `get_current_organization`

**Error Message:**
```
403 Forbidden: "User must be associated with an active organization"
```

## Solution

Implemented automatic token refresh system that updates the JWT token with new organization context.

## What Was Fixed

### Backend Changes

1. **Updated `/api/user/set-organization/{organization_id}`** (backend/app/api/v1/user.py:98)
   - Now generates a new JWT token with updated organization context
   - Returns new token in response

2. **Added `/api/user/refresh-token` endpoint** (backend/app/api/v1/user.py:139)
   - Refreshes JWT token with current user's organization info
   - Called after creating or switching organizations

### Frontend Changes

1. **Added `refreshToken()` to AuthNotifier** (frontend/lib/providers/auth_provider.dart:214)
   - Calls backend refresh-token endpoint
   - Updates stored token
   - Updates API service with new token

2. **Added `refreshToken()` to UserApi** (frontend/lib/data/services/user_api.dart:43)
   - Service method to call backend endpoint

3. **Updated CreateOrganizationScreen** (frontend/lib/presentation/screens/organizations/create_organization_screen.dart:122)
   - Automatically refreshes token after creating organization
   - User can immediately create drivers

4. **Updated OrganizationSelectorScreen** (frontend/lib/presentation/screens/organizations/organization_selector_screen.dart:156)
   - Refreshes token when switching organizations
   - Ensures correct organization context

## How It Works

### Flow After Creating Organization

1. User creates organization
   ```
   POST /api/companies/create
   ```

2. User becomes Owner of organization
   - UserOrganization record created with status='active'
   - Role set to 'owner'

3. Frontend automatically calls refresh token
   ```
   POST /api/user/refresh-token
   ```

4. Backend generates new JWT with organization context
   ```json
   {
     "sub": "user-id",
     "username": "testuser",
     "role": "owner",
     "company_id": "org-id"
   }
   ```

5. Frontend updates stored token and API service

6. User can now create drivers and use all features
   ```
   POST /api/drivers
   ✅ Success - user has active organization
   ```

## Testing

### Test Scenario 1: Create Organization Then Driver

1. **Login as independent user**
   ```bash
   # JWT token shows:
   "role": "independent_user"
   "company_id": null
   ```

2. **Create organization**
   - Profile → Create Organization
   - Fill form and submit
   - Token automatically refreshes

3. **Verify new token**
   - Check browser dev tools → Application → Storage
   - Token should now show:
   ```
   "role": "owner"
   "company_id": "actual-org-id"
   ```

4. **Create driver**
   - Navigate to Drivers → Add Driver
   - Fill form and submit
   - ✅ Should succeed

### Test Scenario 2: Switch Organizations

1. **User with multiple organizations**
   - Open "My Organizations"
   - Select different organization
   - Token refreshes with new org context

2. **Verify context**
   - Create driver in new organization
   - Should associate with correct organization

## Manual Fix (If Needed)

If user already created organization but token not refreshed:

### Option 1: Logout and Login
```
1. Click profile → Logout
2. Login again
3. Token will have updated organization info
```

### Option 2: Switch Organization
```
1. Profile → My Organizations
2. Click on your organization
3. Token refreshes automatically
```

### Option 3: Manual Token Refresh (Dev Tools)
```javascript
// In browser console
fetch('http://localhost:8000/api/user/refresh-token', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + localStorage.getItem('auth_token')
  }
})
.then(r => r.json())
.then(data => {
  localStorage.setItem('auth_token', data.access_token);
  console.log('Token refreshed!');
  location.reload();
});
```

## API Endpoints

### Refresh Token
```bash
POST /api/user/refresh-token
Authorization: Bearer <current-token>

Response:
{
  "success": true,
  "access_token": "new-jwt-token",
  "token_type": "bearer",
  "user_id": "...",
  "username": "...",
  "company_id": "...",
  "company_name": "...",
  "role": "Owner"
}
```

### Set Active Organization
```bash
POST /api/user/set-organization/{organization_id}
Authorization: Bearer <current-token>

Response:
{
  "success": true,
  "access_token": "new-jwt-token",
  "token_type": "bearer",
  "organization_id": "...",
  "organization_name": "...",
  "role": "Owner",
  "message": "Organization context updated successfully"
}
```

## JWT Token Contents

### Before Creating Organization
```json
{
  "sub": "user-id",
  "username": "testuser",
  "role": "independent_user",
  "company_id": null,
  "exp": 1769514783,
  "iat": 1769512983
}
```

### After Creating Organization
```json
{
  "sub": "user-id",
  "username": "testuser",
  "role": "owner",
  "company_id": "org-uuid",
  "exp": 1769514783,
  "iat": 1769512983
}
```

## Troubleshooting

### Issue: Still getting 403 after creating organization

**Solution:**
1. Check if token was actually refreshed:
   ```javascript
   // Decode JWT in browser console
   const token = localStorage.getItem('auth_token');
   const payload = JSON.parse(atob(token.split('.')[1]));
   console.log('Company ID:', payload.company_id);
   console.log('Role:', payload.role);
   ```

2. If company_id is still null, manually logout and login

### Issue: Token refresh fails

**Check:**
1. Backend is running: `http://localhost:8000/docs`
2. Token is valid (not expired)
3. User has active organization in database:
   ```sql
   SELECT * FROM user_organizations
   WHERE user_id = 'your-user-id'
   AND status = 'active';
   ```

### Issue: Multiple organizations, wrong one active

**Solution:**
1. Profile → My Organizations
2. Click desired organization
3. Token refreshes with selected org

## Restart Instructions

### Backend
```bash
cd backend
python -m uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend
flutter run -d chrome
```

## Summary

The 403 error is now automatically fixed by:
1. ✅ Token refresh after creating organization
2. ✅ Token refresh when switching organizations
3. ✅ New refresh-token endpoint
4. ✅ Updated set-organization endpoint

Users can now create organizations and immediately start adding drivers without manual logout/login.
