# Role Selection & Request System

## Overview
This feature allows users to select their desired role when joining or creating a company. The organization owner can then approve, modify, or reject the role request.

---

## Workflow

### 1. User Joins Company
```
User signs up → Completes profile → Selects "Join Company"
→ Selects Company → **ROLE SELECTION SCREEN** → Request sent
→ Status: PENDING → Waits for owner approval
```

### 2. User Creates Company
```
User signs up → Completes profile → Selects "Create Company"
→ Enters company details → Automatically becomes OWNER
→ Status: ACTIVE (no approval needed)
```

### 3. Owner Reviews Requests
```
Owner logs in → Views "Pending Requests" → Reviews user info & requested role
→ Options:
   - Approve as requested
   - Change role and approve
   - Reject request
```

---

## Backend Implementation

### Database Changes

**New Field Added to `user_organizations` table:**
```sql
ALTER TABLE user_organizations
ADD COLUMN requested_role_id UUID REFERENCES roles(id);
```

**Migration File:** `backend/alembic/versions/005_add_requested_role_field.py`

To apply migration:
```bash
cd backend
alembic upgrade head
```

### API Endpoints

#### 1. Get Available Roles
```http
GET /api/roles/available
```
**Response:**
```json
{
  "success": true,
  "roles": [
    {
      "id": "uuid",
      "role_name": "Fleet Manager",
      "role_key": "fleet_manager",
      "description": "Manages day-to-day fleet operations",
      "is_system_role": true,
      "is_custom_role": false
    },
    ...
  ],
  "count": 11
}
```

#### 2. Get My Role
```http
GET /api/roles/my-role
Authorization: Bearer {token}
```
**Response:**
```json
{
  "success": true,
  "has_role": true,
  "status": "pending",
  "current_role": {
    "id": "uuid",
    "name": "Pending User",
    "key": "pending_user"
  },
  "requested_role": {
    "id": "uuid",
    "name": "Fleet Manager",
    "key": "fleet_manager"
  },
  "organization": {
    "id": "uuid",
    "name": "ABC Transport"
  }
}
```

#### 3. Get Pending Requests (Owners Only)
```http
GET /api/roles/pending-requests
Authorization: Bearer {owner_token}
```
**Response:**
```json
{
  "success": true,
  "organization": {
    "id": "uuid",
    "name": "ABC Transport"
  },
  "pending_requests": [
    {
      "user_organization_id": "uuid",
      "user_id": "uuid",
      "user_name": "John Doe",
      "username": "johndoe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "joined_at": "2026-01-29T10:30:00Z",
      "current_role": {
        "id": "uuid",
        "name": "Pending User",
        "key": "pending_user"
      },
      "requested_role": {
        "id": "uuid",
        "name": "Fleet Manager",
        "key": "fleet_manager",
        "description": "Manages day-to-day fleet operations"
      }
    }
  ],
  "count": 1
}
```

#### 4. Approve Role Request
```http
POST /api/roles/approve-request/{user_org_id}
Authorization: Bearer {owner_token}
Query Parameters:
  - approved_role_id (optional): Different role ID to assign
```
**Response:**
```json
{
  "success": true,
  "message": "Role request approved successfully",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "username": "johndoe"
  },
  "assigned_role": {
    "id": "uuid",
    "name": "Fleet Manager",
    "key": "fleet_manager"
  },
  "approved_by": "Owner Name",
  "approved_at": "2026-01-29T14:30:00Z"
}
```

#### 5. Reject Role Request
```http
POST /api/roles/reject-request/{user_org_id}
Authorization: Bearer {owner_token}
```
**Response:**
```json
{
  "success": true,
  "message": "Role request from John Doe has been rejected"
}
```

---

## Frontend Implementation

### Files Created

1. **Model:** `frontend/lib/data/models/role_model.dart`
   - RoleModel
   - PendingRoleRequest
   - RoleInfo

2. **API Service:** `frontend/lib/data/services/role_api.dart`
   - getAvailableRoles()
   - getMyRole()
   - getPendingRoleRequests()
   - approveRoleRequest()
   - rejectRoleRequest()

3. **Provider:** `frontend/lib/providers/role_provider.dart`
   - RolesState
   - RolesNotifier
   - rolesProvider

4. **UI Screens:**
   - `frontend/lib/presentation/screens/profile/role_selection_screen.dart`
   - `frontend/lib/presentation/screens/organization/pending_requests_screen.dart`

### Integration with Signup Flow

Update your existing company selection screen to navigate to role selection:

**Example: `company_selection_screen.dart`**
```dart
// When user selects "Join Company"
Future<void> _handleJoinCompany(String companyId) async {
  // Navigate to role selection
  final roleData = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (context) => const RoleSelectionScreen(),
    ),
  );

  if (roleData != null) {
    // Submit profile with requested role
    final profileData = {
      'role_type': 'join_company',
      'company_id': companyId,
      'requested_role_id': roleData['requested_role_id'], // ← NEW
    };

    final result = await ref.read(authProvider.notifier).completeProfile(profileData);

    if (result) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent! Role: ${roleData['requested_role_name']}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
```

### Adding Pending Requests to Owner Dashboard

**Example: `home_screen.dart` (for owners)**
```dart
// Check if user is owner
if (userRole?.roleKey == 'owner') {
  ListTile(
    leading: const Icon(Icons.pending_actions),
    title: const Text('Pending Requests'),
    trailing: pendingCount > 0
        ? Badge(
            label: Text('$pendingCount'),
            child: const Icon(Icons.arrow_forward_ios),
          )
        : const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PendingRequestsScreen(),
        ),
      );
    },
  ),
}
```

---

## Available Roles

The system includes **12 roles** (11 selectable + 1 internal):

### Selectable Roles:
1. **Super Admin** - Full system control
2. **Fleet Manager** - Day-to-day fleet operations
3. **Dispatcher** - Trip coordination
4. **Driver** - Vehicle operation
5. **Accountant/Finance Manager** - Financial management
6. **Maintenance Manager** - Vehicle maintenance oversight
7. **Compliance Officer** - Regulatory compliance
8. **Operations Manager** - Strategic oversight
9. **Maintenance Technician** - Hands-on repairs
10. **Customer Service Representative** - Customer support
11. **Viewer/Analyst** - Read-only reporting
12. **Owner** - Organization owner (auto-assigned)

### Internal Roles (Not Selectable):
- **Pending User** - Temporary role while awaiting approval
- **Independent User** - Users without organization

---

## User Experience

### User Flow:
1. User signs up and completes basic profile
2. Selects company option:
   - **Join Company**: Search → Select → Choose Role → Submit Request
   - **Create Company**: Enter details → Auto-assigned as Owner
   - **Independent**: Auto-assigned as Independent User
3. If joining:
   - Sees role selection screen with all 12 roles
   - Can search/filter roles
   - Sees role descriptions
   - Selects desired role
   - Request sent to owner
4. User sees "Pending" status until approved

### Owner Flow:
1. Owner sees notification badge for pending requests
2. Opens "Pending Requests" screen
3. Reviews each request:
   - User information
   - Requested role
   - Request timestamp
4. Takes action:
   - **Approve**: User gets requested role, status → Active
   - **Change & Approve**: Selects different role, then approves
   - **Reject**: Request deleted, user can reapply

---

## Testing

### Test Scenarios

#### 1. User Joins Company
```bash
# Create user and complete profile
POST /api/auth/signup
POST /api/profile/complete
Body: {
  "role_type": "join_company",
  "company_id": "company-uuid",
  "requested_role_id": "fleet-manager-uuid"
}

# Verify status
GET /api/roles/my-role
Expected: status = "pending", requested_role = "Fleet Manager"
```

#### 2. Owner Reviews Request
```bash
# Login as owner
POST /api/auth/login (owner credentials)

# Get pending requests
GET /api/roles/pending-requests
Expected: List with 1 pending request

# Approve request
POST /api/roles/approve-request/{user_org_id}
Expected: User status → "active", role → "Fleet Manager"
```

#### 3. Owner Changes Role
```bash
# Approve with different role
POST /api/roles/approve-request/{user_org_id}?approved_role_id={dispatcher-uuid}
Expected: User gets Dispatcher role instead of Fleet Manager
```

#### 4. Owner Rejects Request
```bash
# Reject request
POST /api/roles/reject-request/{user_org_id}
Expected: UserOrganization record deleted

# User can reapply
POST /api/profile/complete (same user, same company)
Expected: New pending request created
```

---

## Security Considerations

1. **Owner Verification**: Only users with 'owner' role can view/approve requests
2. **Organization Scope**: Owners can only see requests for their organization
3. **Role Validation**: Requested role must exist in roles table
4. **Status Checks**: Only pending requests can be approved/rejected
5. **Audit Trail**: All approvals tracked with `approved_by` and `approved_at`

---

## Future Enhancements

1. **Email Notifications**:
   - Notify owner when new request arrives
   - Notify user when request is approved/rejected

2. **Request Comments**:
   - Owner can add comments when rejecting
   - User can add note with request

3. **Bulk Actions**:
   - Approve/reject multiple requests at once

4. **Role Suggestions**:
   - AI-powered role recommendations based on user info

5. **Time-Limited Requests**:
   - Auto-reject requests older than X days

6. **Request Analytics**:
   - Track which roles are most requested
   - Average approval time

---

## Troubleshooting

### Issue: Roles not loading
**Solution:** Check API endpoint is accessible
```bash
curl http://192.168.1.4:8000/api/roles/available
```

### Issue: Owner can't see pending requests
**Solution:** Verify user has 'owner' role
```sql
SELECT uo.*, r.role_key
FROM user_organizations uo
JOIN roles r ON uo.role_id = r.id
WHERE uo.user_id = 'user-uuid';
```

### Issue: Approval fails
**Solution:** Check user_org_id is valid and status is 'pending'
```sql
SELECT * FROM user_organizations WHERE id = 'user-org-uuid';
```

---

## Summary

This feature provides a complete role request and approval system:

✅ **Users** can select their desired role when joining
✅ **Owners** have full control over who joins and what role they get
✅ **12 roles** available for selection
✅ **Flexible** - owner can approve as-is or change the role
✅ **Secure** - proper authorization checks
✅ **User-friendly** - clean UI with search and descriptions
✅ **Tracked** - complete audit trail

The implementation is production-ready and follows best practices for security, user experience, and code organization.
