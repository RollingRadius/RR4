# Organization Management Features

## Overview
Implemented complete organization management system allowing independent users to create their own organizations and manage member access requests.

## Features Implemented

### 1. Organization Creation for Independent Users

**Backend:**
- Updated `/api/companies/create` endpoint to support authenticated users
- Creates organization and assigns creator as Owner
- Location: `backend/app/api/v1/company.py:89`

**Frontend:**
- New screen: `CreateOrganizationScreen`
- Location: `frontend/lib/presentation/screens/organizations/create_organization_screen.dart`
- Accessible via:
  - Profile menu → "Create Organization"
  - Organization selector screen → "+" button in app bar
  - Organization selector screen → "Create Your Organization" button (when no orgs)

**Route:** `/organizations/create`

### 2. Organization Member Management

**Backend API Endpoints:**
All endpoints require Owner or Admin role (except viewing members)

#### View Members
- **GET** `/api/organizations/{organization_id}/members`
- Query param: `include_pending` (optional)
- Returns: List of all members with roles and status

#### View Pending Users
- **GET** `/api/organizations/{organization_id}/pending-users`
- Returns: List of users awaiting approval
- **Requires:** Owner or Admin role

#### Approve User
- **POST** `/api/organizations/{organization_id}/approve-user`
- Body: `{ "user_id": "...", "role_key": "admin|dispatcher|user|viewer" }`
- Assigns role and activates user
- **Requires:** Owner or Admin role

#### Reject User
- **POST** `/api/organizations/{organization_id}/reject-user`
- Body: `{ "user_id": "...", "reason": "..." }`
- Removes pending user request
- **Requires:** Owner or Admin role

#### Update User Role
- **POST** `/api/organizations/{organization_id}/update-role`
- Body: `{ "user_id": "...", "role_key": "admin|dispatcher|user|viewer" }`
- Changes existing member's role
- **Requires:** Owner or Admin role
- **Restrictions:**
  - Only owners can change/assign owner roles
  - Users cannot change their own role
  - Admins cannot change owner roles

#### Remove User
- **POST** `/api/organizations/{organization_id}/remove-user`
- Body: `{ "user_id": "..." }`
- Removes user from organization
- **Requires:** Owner or Admin role
- **Restrictions:**
  - Only owners can remove other owners
  - Users cannot remove themselves

**Files:**
- Service: `backend/app/services/organization_service.py`
- API: `backend/app/api/v1/organization.py`
- Schemas: `backend/app/schemas/organization.py`

### 3. Organization Management Screen (Frontend)

**Features:**
- Two tabs: Members and Pending Users
- View all organization members with roles
- Badge showing pending user count
- Approve pending users with role selection dialog
- Reject pending users
- Change member roles
- Remove members from organization

**Location:** `frontend/lib/presentation/screens/organizations/organization_management_screen.dart`

**Access:**
- Profile menu → "Manage Organization"
- Route: `/organizations/{id}/manage`

### 4. Organization Selector Screen (Enhanced)

**New Features:**
- "+" button in app bar to create organization
- "Create Your Organization" button when no organizations exist
- Shows all user's organizations with ability to switch between them

**Location:** `frontend/lib/presentation/screens/organizations/organization_selector_screen.dart`

**Route:** `/organizations`

## Available Roles

1. **Owner** - Full access, assigned to organization creator
2. **Admin** - Can manage members and settings
3. **Dispatcher** - Can manage trips and assignments
4. **User** - Standard access to features
5. **Viewer** - Read-only access

## Audit Logging

All actions are logged in the audit_log table:
- User approved: `user_approved`
- User rejected: `user_rejected`
- Role changed: `role_changed`
- User removed: `user_removed`

## Navigation Structure

```
Profile Menu
├── My Organizations (/organizations)
│   ├── View all organizations
│   ├── Switch between organizations
│   └── Create new organization (+ button)
│
├── Create Organization (/organizations/create)
│   └── Form to create new organization
│
└── Manage Organization (/organizations/{id}/manage)
    ├── Members Tab
    │   ├── View all members
    │   ├── Change member roles
    │   └── Remove members
    │
    └── Pending Tab
        ├── View pending requests
        ├── Approve with role selection
        └── Reject requests
```

## User Flow

### Independent User Creates Organization:
1. User signs up as independent user (skips company selection)
2. Logs in to dashboard
3. Opens profile menu → "Create Organization"
4. Fills organization details
5. Submits form
6. User becomes Owner of new organization
7. Organization appears in "My Organizations"

### User Joins Existing Organization:
1. User searches for organization during signup
2. Selects organization to join
3. Status: Pending, Role: Pending User
4. Owner/Admin receives notification
5. Owner/Admin opens "Manage Organization"
6. Views pending user in "Pending" tab
7. Approves user with role selection
8. User status changes to Active with assigned role

### Owner/Admin Manages Members:
1. Opens "Manage Organization" from profile menu
2. Views "Members" tab for active members
3. Views "Pending" tab for approval requests
4. Can approve/reject pending users
5. Can change roles of existing members
6. Can remove members from organization

## Testing

1. **Create Organization:**
   - Login as independent user
   - Profile menu → Create Organization
   - Fill form and submit
   - Verify you become Owner

2. **Approve Pending User:**
   - Have a user join your organization
   - Profile menu → Manage Organization
   - Switch to "Pending" tab
   - Approve user with desired role

3. **Change User Role:**
   - Manage Organization → Members tab
   - Click menu on user
   - Select "Change Role"
   - Choose new role

4. **Remove User:**
   - Manage Organization → Members tab
   - Click menu on user
   - Select "Remove"
   - Confirm removal

## Database Schema

### New Constants Added:
```python
AUDIT_ACTION_USER_APPROVED = "user_approved"
AUDIT_ACTION_USER_REJECTED = "user_rejected"
AUDIT_ACTION_ROLE_CHANGED = "role_changed"
AUDIT_ACTION_USER_REMOVED = "user_removed"
ENTITY_TYPE_USER_ORG = "user_organization"
```

## API Documentation

Full API documentation available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

Look for "Organization Management" tag for all endpoints.

## Security

- All organization management endpoints require JWT authentication
- Role-based access control enforced at service layer
- Only Owner/Admin can manage members
- Audit logging for all administrative actions
- Owners cannot be removed by admins
- Users cannot change their own roles

## Future Enhancements

Potential features to add:
- Email notifications for pending approvals
- Organization settings page
- Transfer ownership functionality
- Organization logo upload
- Member invitation system via email
- Activity feed for organization actions
- Organization statistics dashboard
