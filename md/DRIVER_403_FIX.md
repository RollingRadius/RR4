# Quick Fix: 403 Error When Creating Drivers

## The Problem
You were getting this error when creating a driver:
```
403 Forbidden: "User must be associated with an active organization"
```

Your JWT token showed:
```json
{
  "role": "independent_user",
  "company_id": null
}
```

## The Solution ✅

I've implemented automatic token refresh that updates your JWT token after creating an organization.

## What You Need to Do

### Step 1: Restart Backend
```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Step 2: Restart Frontend
```bash
cd frontend
flutter run -d chrome
```

### Step 3: Follow This Flow

#### If You Already Created an Organization:

1. **Logout and Login Again**
   - Click profile icon → Logout
   - Login with your credentials
   - Your token will now have the organization info

2. **Now Create Driver**
   - Drivers → Add Driver
   - Fill form and submit
   - ✅ Should work!

#### If You Haven't Created an Organization Yet:

1. **Create Organization**
   - Profile icon → "Create Organization"
   - Fill the form with company details
   - Submit
   - Token automatically refreshes (NEW!)

2. **Create Driver**
   - Drivers → Add Driver
   - Fill form and submit
   - ✅ Works immediately!

## How It Works Now

### Before (Old Behavior)
```
1. User creates organization ✅
2. User tries to create driver ❌
   Error: "User must be associated with an active organization"
3. User must logout and login again 😞
4. Then can create driver ✅
```

### After (New Behavior)
```
1. User creates organization ✅
2. Token automatically refreshes 🔄
3. User can immediately create driver ✅
4. No logout needed! 🎉
```

## Technical Details

### New Endpoints Added

#### 1. Refresh Token
```
POST /api/user/refresh-token
Authorization: Bearer <your-token>

Returns: New JWT token with updated organization
```

#### 2. Updated Set Organization
```
POST /api/user/set-organization/{org-id}
Authorization: Bearer <your-token>

Returns: New JWT token for selected organization
```

### Automatic Refresh Triggers

Token refreshes automatically when you:
- ✅ Create a new organization
- ✅ Switch between organizations
- ✅ Join an organization (and get approved)

## Testing

### Test 1: Create Organization
```
1. Login as testuser2
2. Profile → Create Organization
3. Name: "My Fleet Company"
4. Submit
5. Check JWT token in browser dev tools
   Should show: "role": "owner", "company_id": "actual-id"
6. Go to Drivers → Add Driver
7. Fill form
8. Submit ✅ Success!
```

### Test 2: Current User (Already Has Org)
```
1. Logout
2. Login again
3. Token refreshes with organization info
4. Create driver ✅ Success!
```

## Check Your Token

To verify your token has organization info:

### Browser Console
```javascript
// Paste this in browser console (F12)
const token = localStorage.getItem('auth_token');
if (token) {
  const parts = token.split('.');
  const payload = JSON.parse(atob(parts[1]));
  console.log('User:', payload.username);
  console.log('Role:', payload.role);
  console.log('Company ID:', payload.company_id);
} else {
  console.log('No token found');
}
```

### Expected Output (After Fix)
```
User: testuser2
Role: owner
Company ID: 7edf4e71-4267-4b2e-ad6f-fe12c7d277eb
```

## Files Changed

### Backend
- `backend/app/api/v1/user.py` - Added refresh-token endpoint
- `backend/app/api/v1/user.py` - Updated set-organization to return new token

### Frontend
- `frontend/lib/providers/auth_provider.dart` - Added refreshToken() method
- `frontend/lib/data/services/user_api.dart` - Added refreshToken() service
- `frontend/lib/presentation/screens/organizations/create_organization_screen.dart` - Auto-refresh after creation
- `frontend/lib/presentation/screens/organizations/organization_selector_screen.dart` - Auto-refresh when switching

## Common Issues

### Issue 1: Still Getting 403 Error

**Solution:** Logout and login again to get fresh token

### Issue 2: Don't See "Create Organization" Option

**Solution:**
1. Make sure you're logged in
2. Click profile icon in top-right
3. Should see "Create Organization" option

### Issue 3: Organization Created But Can't Create Driver

**Solution:**
1. Check token in browser console (see above)
2. If company_id is null, logout and login
3. If company_id is present, check backend logs for error

### Issue 4: Frontend Not Showing Changes

**Solution:**
```bash
cd frontend
flutter clean
flutter pub get
flutter run -d chrome
```

## API Documentation

View full API docs at: http://localhost:8000/docs

Look for:
- **User Profile** section → `POST /api/user/refresh-token`
- **User Profile** section → `POST /api/user/set-organization/{organization_id}`

## Summary

✅ **Fixed:** Token refresh after creating organization
✅ **Fixed:** Token refresh when switching organizations
✅ **Added:** `/api/user/refresh-token` endpoint
✅ **Added:** Automatic token updates in frontend

**Result:** You can now create an organization and immediately add drivers without logging out!

## Quick Start (For You Right Now)

Since you already have a user (testuser2) that might have created an organization:

```bash
# 1. Restart backend
cd E:\Projects\RR4\backend
python -m uvicorn app.main:app --reload

# 2. In another terminal, restart frontend
cd E:\Projects\RR4\frontend
flutter run -d chrome

# 3. In the app:
# - Logout (profile → logout)
# - Login as testuser2
# - Try creating driver ✅ Should work now!
```

If you need to create organization:
```
Profile → Create Organization → Fill form → Submit
Then immediately: Drivers → Add Driver → Fill form → Submit ✅
```
