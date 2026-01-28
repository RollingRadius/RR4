# Organization Management - Quick Start Guide

## Setup

### Backend
The backend is already configured. Just restart the server to load the new endpoints:

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend
No additional setup needed. The frontend is ready to use.

```bash
cd frontend
flutter run -d chrome
```

## Usage Guide

### For Independent Users

#### Create Your Organization

1. **Login** to the application
2. Click your **profile icon** in the top-right
3. Select **"Create Organization"**
4. Fill in the form:
   - **Required Fields:**
     - Company Name
     - Business Type
     - Business Email
     - Business Phone
     - Address, City, State, Pincode
   - **Optional Fields:**
     - GSTIN (15 characters)
     - PAN Number (10 characters)
5. Click **"Create Organization"**
6. You are now the **Owner** of the organization!

#### Alternative Access Points:
- Profile menu → "My Organizations" → "+" button
- Organization selector screen → "Create Your Organization" button

### For Organization Owners/Admins

#### Manage Your Organization

1. Click **profile icon** → **"Manage Organization"**
2. You'll see two tabs:

#### Members Tab
- View all active members
- See their roles (Owner, Admin, Dispatcher, User, Viewer)
- **Change Role:**
  - Click the ⋮ menu on a member
  - Select "Change Role"
  - Choose new role
- **Remove Member:**
  - Click the ⋮ menu on a member
  - Select "Remove"
  - Confirm removal

#### Pending Tab (Badge shows count)
- View users requesting to join
- **Approve:**
  - Click the ✓ (green checkmark)
  - Select role to assign
  - User is now active
- **Reject:**
  - Click the ✗ (red X)
  - Confirm rejection
  - User request is removed

### For Users Joining Organizations

1. During **signup**, search for organization
2. Select organization to join
3. Your status: **Pending**
4. Wait for Owner/Admin approval
5. Once approved, you'll have access based on assigned role

## Roles & Permissions

| Role | Can Create Org | Can Approve Users | Can Manage Members | Can Change Roles | Can Remove Members |
|------|---------------|-------------------|-------------------|------------------|-------------------|
| **Owner** | ✅ | ✅ | ✅ | ✅ (including owners) | ✅ (including owners) |
| **Admin** | ✅ | ✅ | ✅ | ✅ (except owners) | ✅ (except owners) |
| **Dispatcher** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **User** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Viewer** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Independent** | ✅ | ❌ | ❌ | ❌ | ❌ |

**Note:** Everyone can create their own organization and become its Owner.

## Common Scenarios

### Scenario 1: First-Time User Without Organization
```
1. Sign up as independent user (skip company selection)
2. Login to dashboard
3. Profile menu → "Create Organization"
4. Fill form and submit
5. You're now Owner!
```

### Scenario 2: User Wants to Join Existing Organization
```
1. Sign up and search for organization
2. Select organization
3. Status: Pending
4. Owner/Admin approves with role
5. You're now active member!
```

### Scenario 3: Owner Approves Pending User
```
1. Profile menu → "Manage Organization"
2. Switch to "Pending" tab
3. See list of pending users
4. Click ✓ on desired user
5. Select role (Admin, Dispatcher, User, Viewer)
6. User is now active!
```

### Scenario 4: Admin Changes User Role
```
1. Profile menu → "Manage Organization"
2. Members tab
3. Find user
4. Click ⋮ menu → "Change Role"
5. Select new role
6. Role updated!
```

### Scenario 5: Remove Problematic User
```
1. Profile menu → "Manage Organization"
2. Members tab
3. Find user
4. Click ⋮ menu → "Remove"
5. Confirm removal
6. User removed from organization
```

## API Endpoints

### For Development/Testing

#### Create Organization (Authenticated)
```bash
POST http://localhost:8000/api/companies/create
Authorization: Bearer <your_jwt_token>
Content-Type: application/json

{
  "company_name": "My Fleet Company",
  "business_type": "Transportation",
  "business_email": "contact@myfleet.com",
  "business_phone": "+911234567890",
  "address": "123 Main Street",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "country": "India"
}
```

#### Get Organization Members
```bash
GET http://localhost:8000/api/organizations/{org_id}/members?include_pending=true
Authorization: Bearer <your_jwt_token>
```

#### Get Pending Users
```bash
GET http://localhost:8000/api/organizations/{org_id}/pending-users
Authorization: Bearer <your_jwt_token>
```

#### Approve User
```bash
POST http://localhost:8000/api/organizations/{org_id}/approve-user
Authorization: Bearer <your_jwt_token>
Content-Type: application/json

{
  "user_id": "user-uuid-here",
  "role_key": "admin"
}
```

#### Update User Role
```bash
POST http://localhost:8000/api/organizations/{org_id}/update-role
Authorization: Bearer <your_jwt_token>
Content-Type: application/json

{
  "user_id": "user-uuid-here",
  "role_key": "dispatcher"
}
```

#### Remove User
```bash
POST http://localhost:8000/api/organizations/{org_id}/remove-user
Authorization: Bearer <your_jwt_token>
Content-Type: application/json

{
  "user_id": "user-uuid-here"
}
```

## Troubleshooting

### Issue: "Create Organization" button not visible
- **Solution:** Make sure you're logged in and can see the profile icon

### Issue: Cannot approve pending users
- **Solution:** Check that you're an Owner or Admin of the organization

### Issue: Cannot change owner's role
- **Solution:** Only owners can modify other owners. Admins cannot change owner roles.

### Issue: Organization creation fails
- **Solution:**
  - Check all required fields are filled
  - Verify GSTIN format (15 chars) if provided
  - Verify PAN format (10 chars) if provided
  - Check backend logs for detailed error

### Issue: Pending tab shows no users but users are waiting
- **Solution:**
  - Refresh the page
  - Check backend logs
  - Verify users completed signup correctly

## Testing Checklist

- [ ] Independent user can create organization
- [ ] User becomes Owner after creating organization
- [ ] Owner can see "Manage Organization" option
- [ ] Pending users appear in Pending tab
- [ ] Owner can approve users with role selection
- [ ] Owner can reject pending users
- [ ] Owner/Admin can change member roles
- [ ] Owner/Admin can remove members
- [ ] Admins cannot change owner roles
- [ ] Users cannot change their own roles
- [ ] Badge shows correct pending count
- [ ] Organization appears in "My Organizations"

## Support

For issues or questions:
1. Check the API documentation: http://localhost:8000/docs
2. Review backend logs for errors
3. Check browser console for frontend errors
4. Refer to ORGANIZATION_FEATURES.md for detailed documentation
