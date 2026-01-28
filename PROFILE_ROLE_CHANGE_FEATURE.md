# Profile Page with Role Change Feature

## Overview
Implemented a profile page feature that allows **Independent Users** to change/select their role. The profile page is accessible from the dashboard's profile icon menu.

## What Was Implemented

### Backend Changes

#### 1. New API Endpoint: `/api/profile/change-role`
**File:** `backend/app/api/v1/profile.py`

Added a new POST endpoint that allows Independent Users to change their role to:
- **Driver** - Become a driver (requires license number and expiry date)
- **Join Company** - Request to join an existing company (becomes Pending User)
- **Create Company** - Create their own company (becomes Owner)

**Key Features:**
- Only Independent Users can use this endpoint
- Users affiliated with companies cannot change roles
- Validates role-specific requirements (license for drivers, company details for creation)

#### 2. New Service Method: `change_role()`
**File:** `backend/app/services/profile_service.py`

Implements the business logic for role changes:
- Validates user is an Independent User with no company affiliation
- Handles three role change scenarios:
  - **Become Driver**: Creates driver profile in database
  - **Join Company**: Updates user to Pending User status (awaits admin approval)
  - **Create Company**: Creates new organization and makes user the Owner
- Logs all role changes in audit log
- Prevents independent users from "changing" to independent again

### Frontend Changes

#### 1. Profile API Service
**File:** `frontend/lib/data/services/profile_api.dart`

Added new method:
```dart
Future<Map<String, dynamic>> changeRole(Map<String, dynamic> profileData)
```
Calls the backend `/api/profile/change-role` endpoint.

#### 2. Profile Provider
**File:** `frontend/lib/providers/profile_provider.dart`

Added new method to `ProfileNotifier`:
```dart
Future<bool> changeRole(Map<String, dynamic> profileData)
```
Manages state for role change operations.

#### 3. Enhanced Profile Screen
**File:** `frontend/lib/presentation/screens/profile/profile_screen.dart`

**Key UI Updates:**
1. **Conditional Display Logic:**
   - If user is Independent User: Shows role change options
   - If user has company affiliation: Shows "Your role is managed by your organization" message

2. **Role Change Options Section (for Independent Users):**
   - Green-highlighted card with three action buttons:
     - **Join Organization** - Navigates to organizations list
     - **Create Organization** - Navigates to organization creation page
     - **Become Driver** - Opens dialog to enter license details

3. **Become Driver Dialog:**
   - Collects license number and expiry date
   - Validates inputs
   - Submits role change request
   - Shows success/error feedback
   - Refreshes profile and auth state on success

## User Flow

### For Independent Users

1. User clicks profile icon in dashboard app bar
2. Selects "My Profile" from menu
3. Profile page displays current role as "Independent User"
4. User sees green card with "Want to change your role?" section
5. Three options are available:

   **Option A: Join Organization**
   - Click "Join Organization" button
   - Redirects to organizations list
   - User can browse and request to join companies
   - Becomes "Pending User" awaiting approval

   **Option B: Create Organization**
   - Click "Create Organization" button
   - Redirects to organization creation form
   - User fills in company details
   - Becomes "Owner" of new organization

   **Option C: Become Driver**
   - Click "Become Driver" button
   - Dialog opens requesting license details
   - User enters license number and expiry date
   - Submits form
   - Role changes to driver
   - Success message shown
   - Profile refreshes to show driver role

### For Organization-Affiliated Users

1. User clicks profile icon and selects "My Profile"
2. Profile page displays their organization role (Owner, Admin, etc.)
3. Blue information box shows: "Your role is managed by your organization"
4. No role change options available (organization admins manage member roles)

## Technical Details

### Role Change Validation

**Backend validates:**
- User exists
- User has an existing role assignment
- User's current role is "Independent User"
- User has no organization affiliation (organization_id is NULL)
- Required fields provided based on role type:
  - Driver: license_number, license_expiry
  - Join Company: company_id
  - Create Company: company_name, business_type, etc.

**Frontend validates:**
- License number and expiry are not empty (for driver)
- Provides user-friendly error messages

### Database Changes
No new database migrations needed. Uses existing tables:
- `user_organizations` - Updated for role changes
- `drivers` - New driver records created
- `organizations` - New organizations created
- `audit_logs` - All changes logged

### Security Considerations
- Only authenticated users can access endpoint
- Only Independent Users can change roles
- Role change logged in audit trail
- Company affiliation prevents self-service role changes
- Proper HTTP status codes for errors (403, 404, 400)

## API Examples

### Request: Become a Driver
```json
POST /api/profile/change-role
{
  "role_type": "driver",
  "license_number": "DL1234567890",
  "license_expiry": "2027-12-31"
}
```

### Request: Join Existing Company
```json
POST /api/profile/change-role
{
  "role_type": "join_company",
  "company_id": "uuid-here"
}
```

### Request: Create New Company
```json
POST /api/profile/change-role
{
  "role_type": "create_company",
  "company_name": "My Fleet Company",
  "business_type": "Transportation",
  "business_email": "company@example.com",
  "business_phone": "1234567890",
  "address": "123 Main St",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "country": "India"
}
```

### Response (Success)
```json
{
  "success": true,
  "message": "Role changed successfully to driver",
  "user_id": "uuid",
  "role": "Independent User",
  "role_type": "driver",
  "company_id": null,
  "company_name": null,
  "driver_id": "driver-uuid"
}
```

### Response (Error - Not Independent User)
```json
{
  "detail": "Only Independent Users can change their role. Users with company affiliations cannot change roles."
}
```

## Files Modified

### Backend
1. `backend/app/api/v1/profile.py` - Added `/change-role` endpoint
2. `backend/app/services/profile_service.py` - Added `change_role()` method

### Frontend
1. `frontend/lib/data/services/profile_api.dart` - Added `changeRole()` API method
2. `frontend/lib/providers/profile_provider.dart` - Added `changeRole()` provider method
3. `frontend/lib/presentation/screens/profile/profile_screen.dart` - Enhanced UI with role change options

## Testing Recommendations

### Manual Testing Steps

1. **Test Independent User → Driver**
   - Login as independent user
   - Go to profile page
   - Click "Become Driver"
   - Enter license details
   - Verify success message
   - Verify profile shows driver role

2. **Test Independent User → Join Company**
   - Login as independent user
   - Go to profile page
   - Click "Join Organization"
   - Select a company
   - Verify pending status

3. **Test Independent User → Create Company**
   - Login as independent user
   - Go to profile page
   - Click "Create Organization"
   - Fill in company details
   - Verify user becomes Owner

4. **Test Organization Member Cannot Change Role**
   - Login as user with organization affiliation (Owner, Admin, etc.)
   - Go to profile page
   - Verify role change options NOT shown
   - Verify message shows "Your role is managed by your organization"

### Edge Cases to Test

1. Independent user tries to become driver with invalid license date
2. Independent user tries to join non-existent company
3. Organization member tries to call `/change-role` endpoint directly (should get 403)
4. Independent user already a driver tries to become driver again (should fail)

## Next Steps / Future Enhancements

1. **Driver Verification Workflow**
   - Admin approval for driver applications
   - Document upload for license verification

2. **Role Change History**
   - Show audit log of all role changes in profile page
   - Display timestamps and reasons

3. **Leave Organization Feature**
   - Allow organization members to leave their organization
   - Revert to Independent User status

4. **Profile Editing**
   - Allow users to edit personal information (name, phone, email)
   - Update profile picture

## Notes

- The original profile completion process (first-time setup) remains unchanged
- Role changes are logged in `audit_logs` table for compliance
- Independent users can change role multiple times (e.g., become driver, then create company)
- Once a user joins/creates an organization, they can only change roles through organization admin
