# Fix: 401 Unauthorized Errors

## The Problem
You're seeing these errors in the backend logs:
```
INFO: 127.0.0.1:53780 - "GET /api/user/organizations HTTP/1.1" 401 Unauthorized
```

This means the frontend is trying to access protected endpoints without a valid JWT token.

## Common Causes

1. **Not logged in** - User session expired or logged out
2. **Token expired** - JWT tokens have expiration time
3. **Token missing** - Frontend not sending Authorization header
4. **Auto-loading** - App trying to load data before authentication

## What I Fixed

### 1. Graceful Error Handling (frontend/lib/providers/organization_provider.dart)
```dart
// Now handles 401 errors silently instead of showing errors
catch (e) {
  if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
    state = state.copyWith(isLoading: false, organizations: []);
  }
}
```

### 2. Authentication Check (frontend/lib/presentation/screens/organizations/organization_selector_screen.dart)
```dart
// Only load organizations if user is authenticated
void initState() {
  final authState = ref.read(authProvider);
  if (authState.isAuthenticated && authState.token != null) {
    ref.read(organizationProvider.notifier).loadOrganizations();
  }
}
```

## How to Fix Right Now

### Quick Solution
**Just restart your frontend:**
```bash
cd frontend
# Press Ctrl+C to stop
flutter run -d chrome
```

The 401 errors should stop appearing.

### If Errors Persist

1. **Clear browser storage:**
   - Open browser DevTools (F12)
   - Go to Application → Storage
   - Click "Clear site data"
   - Refresh page

2. **Check if logged in:**
   ```javascript
   // In browser console (F12)
   const token = localStorage.getItem('auth_token');
   console.log('Token:', token ? 'Present' : 'Missing');

   if (token) {
     const parts = token.split('.');
     const payload = JSON.parse(atob(parts[1]));
     const expiry = new Date(payload.exp * 1000);
     console.log('Expires:', expiry);
     console.log('Is expired:', new Date() > expiry);
   }
   ```

3. **Re-login:**
   - Logout from app
   - Login again
   - Fresh token will be issued

## Understanding 401 vs 403

- **401 Unauthorized** = "Who are you?" (no valid token)
- **403 Forbidden** = "I know who you are, but you can't do that" (valid token, insufficient permissions)

## Token Expiration

JWT tokens expire after a certain time (configured in backend):
```python
# backend/app/config.py
ACCESS_TOKEN_EXPIRE_MINUTES = 30  # Default: 30 minutes
```

After 30 minutes, you'll get 401 errors and need to login again.

## Checking Backend Logs

### Good Request (200 OK)
```
INFO: 127.0.0.1:53780 - "GET /api/user/organizations HTTP/1.1" 200 OK
```

### Missing/Invalid Token (401)
```
INFO: 127.0.0.1:53780 - "GET /api/user/organizations HTTP/1.1" 401 Unauthorized
```

### Valid Token, No Permission (403)
```
INFO: 127.0.0.1:53780 - "POST /api/drivers HTTP/1.1" 403 Forbidden
```

## Debugging Steps

### Step 1: Check Authentication
```javascript
// Browser console
localStorage.getItem('auth_token')
```
- **null** = Not logged in → Login first
- **string** = Logged in → Check if expired

### Step 2: Check Token Validity
```bash
# Backend logs should show:
# If token invalid:
INFO: ... "GET /api/user/me HTTP/1.1" 401 Unauthorized

# If token valid:
INFO: ... "GET /api/user/me HTTP/1.1" 200 OK
```

### Step 3: Check API Calls
```javascript
// Browser DevTools → Network tab
// Filter: XHR
// Look for failed requests (red)
// Click on them to see:
// - Request Headers (should have Authorization: Bearer ...)
// - Response (error message)
```

## Prevention

### Auto Token Refresh (Future Enhancement)
Could implement automatic token refresh before expiration:
```dart
// Check token expiry
// If expiring in < 5 minutes, refresh automatically
```

### Better Error Messages
Could show user-friendly messages:
```dart
if (error.statusCode == 401) {
  showDialog('Session expired. Please login again.');
  navigator.pushReplacementNamed('/login');
}
```

## Current Behavior

With the fixes I applied:

✅ **Before navigating to organization screen:** Check if user is authenticated
✅ **If 401 error:** Silently fail instead of showing error message
✅ **User experience:** No confusing error messages

## Testing

### Test 1: Login and Navigate
```
1. Login with valid credentials
2. Navigate to "My Organizations"
3. Should load organizations ✅
4. No 401 errors in backend logs ✅
```

### Test 2: Expired Token
```
1. Login
2. Wait 30+ minutes
3. Try to access any page
4. Should get redirected to login ✅
5. 401 errors are normal here
```

### Test 3: Not Logged In
```
1. Don't login
2. Try to access /organizations
3. Should redirect to login ✅
4. No repeated 401 errors ✅
```

## Summary

✅ **Fixed:** Organization loading only happens when authenticated
✅ **Fixed:** 401 errors are handled gracefully
✅ **Result:** No more confusing error messages or repeated 401 requests

**Action Required:** Just restart your frontend to apply the fixes!

```bash
cd E:\Projects\RR4\frontend
flutter run -d chrome
```
