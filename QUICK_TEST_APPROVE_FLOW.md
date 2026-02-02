# Quick Test: Approve User Flow

## Before Testing

### 1. Run Migration (One Time)
```bash
cd backend
python -m alembic upgrade head
```

**Check it worked:**
```bash
python -m alembic current
```
Should show: `011_add_organization_roles (head)`

### 2. Start Backend
```bash
cd backend
python -m uvicorn app.main:app --reload
```

Wait for: `Application startup complete`

### 3. Start Frontend
```bash
cd frontend
flutter run
```

## Test Steps

### ✅ Test 1: View Pending Users

1. Login as organization owner
2. Go to: **Organizations** → Select org → **Pending** tab
3. **Verify:** Badge shows count of pending users
4. **Verify:** List shows pending users with:
   - Username and full name
   - Email/phone
   - "Requested: [role]" if they requested a role

### ✅ Test 2: Approve User with Role Selection

1. In Pending tab, click **green checkmark (✓)** on a user
2. **Verify Dialog Opens:**
   - Title: "Approve [username]"
   - Shows 4 roles with icons:
     - 🛡️ Admin (red)
     - 📋 Dispatcher (purple)
     - 👤 User (blue)
     - 👁️ Viewer (grey)
   - Each role shows description
3. **Select a role** (click on card)
   - **Verify:** Card highlights with colored border
   - **Verify:** Checkmark appears on selected role
4. Click **OK** button
5. **Verify:**
   - Success message: "[username] approved successfully"
   - User disappears from Pending tab
   - User appears in Members tab with role chip

### ✅ Test 3: Verify in Members Tab

1. Switch to **Members** tab
2. **Verify:**
   - Approved user is listed
   - Role shown as colored chip
   - Can click menu (⋮) to change role or remove user

### ✅ Test 4: Change User Role

1. In Members tab, click **⋮** menu on a user
2. Select **"Change Role"**
3. **Verify:** Same dialog opens showing current role
4. Select different role
5. Click **OK**
6. **Verify:** Success message and role chip updates

### ✅ Test 5: Reject User

1. In Pending tab, click **red X** on a user
2. **Verify:** Confirmation dialog appears
3. Click **Reject**
4. **Verify:**
   - Success message: "[username] rejected"
   - User disappears from list

## Expected Backend Logs

### Successful Approval:
```
INFO: POST /api/organizations/{org_id}/approve-user HTTP/1.1 200 OK
```

### Successful Role Change:
```
INFO: PUT /api/organizations/{org_id}/update-user-role HTTP/1.1 200 OK
```

### Successful Rejection:
```
INFO: POST /api/organizations/{org_id}/reject-user HTTP/1.1 200 OK
```

## If You See Errors

### Error: "Invalid role: admin"
**Problem:** Migration didn't run
**Fix:** Run `python -m alembic upgrade head` in backend directory

### Error: 404 Not Found
**Problem:** Backend not running
**Fix:** Start backend with `python -m uvicorn app.main:app --reload`

### Error: Dialog shows no roles
**Problem:** Frontend not updated
**Fix:** Stop and restart Flutter app (hot reload may not be enough)

### Error: Can't click OK button
**Problem:** No role selected
**Fix:** Click on a role card to select it first

## Success Criteria

✅ Can view pending users
✅ Dialog shows all 4 roles with icons
✅ Can select a role (visual feedback)
✅ OK button works when role is selected
✅ User gets approved and moves to Members tab
✅ Can change user's role later
✅ Can reject pending users
✅ All actions show success messages
✅ No errors in backend logs
✅ No errors in browser console

## Quick Verify Roles in Database

```sql
-- Check all roles exist
SELECT role_key, role_name FROM roles WHERE is_system_role = false;

-- Should return:
-- admin     | Admin
-- dispatcher| Dispatcher
-- user      | User
-- viewer    | Viewer
```

---

**Time to test:** ~5 minutes
**Created:** 2026-02-02
