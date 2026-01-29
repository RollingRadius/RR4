# Organization Dashboard for Owners

## Overview
Complete organization management system for owners to manage their company, employees, and access requests.

---

## Features

### 1. **My Organization Overview**
- Company details and information
- Real-time statistics
- Employee count
- Pending requests count
- Role distribution chart

### 2. **Employee Management**
- List all employees with their roles
- Filter by status (active/pending/all)
- View employee details
- Change employee roles
- Remove employees
- Protected: Cannot modify owner

### 3. **Grant Access (Pending Requests)**
- View all pending join requests
- Approve with requested role
- Change role before approving
- Reject requests
- User information and requested role

---

## Backend API Endpoints

### Base URL: `/api/organization`

#### 1. Get My Organization
```http
GET /api/organization/my-organization
Authorization: Bearer {owner_token}
```

**Response:**
```json
{
  "success": true,
  "organization": {
    "id": "uuid",
    "name": "ABC Transport",
    "business_type": "Transportation",
    "email": "contact@abc.com",
    "phone": "+1234567890",
    "address": "123 Main St",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "country": "India",
    "status": "active",
    "created_at": "2026-01-15T10:00:00Z"
  },
  "statistics": {
    "total_employees": 15,
    "pending_requests": 3,
    "total_members": 18,
    "role_distribution": {
      "owner": 1,
      "fleet_manager": 3,
      "dispatcher": 5,
      "driver": 6
    }
  },
  "owner": {
    "id": "uuid",
    "name": "John Doe",
    "username": "johndoe",
    "email": "john@abc.com"
  }
}
```

#### 2. Get Employees
```http
GET /api/organization/employees?status_filter=active&role_filter=fleet_manager
Authorization: Bearer {owner_token}
```

**Query Parameters:**
- `status_filter`: 'active', 'pending', 'all' (default: 'active')
- `role_filter`: Filter by role_key (optional)

**Response:**
```json
{
  "success": true,
  "employees": [
    {
      "user_organization_id": "uuid",
      "user_id": "uuid",
      "full_name": "Jane Smith",
      "username": "janesmith",
      "email": "jane@example.com",
      "phone": "+1234567890",
      "status": "active",
      "joined_at": "2026-01-20T10:00:00Z",
      "role": {
        "id": "uuid",
        "name": "Fleet Manager",
        "key": "fleet_manager",
        "is_custom": false
      },
      "approved_at": "2026-01-20T11:00:00Z",
      "approved_by": "John Doe"
    }
  ],
  "count": 1,
  "filters_applied": {
    "role": "fleet_manager",
    "status": "active"
  }
}
```

#### 3. Update Employee Role
```http
PUT /api/organization/employees/{user_org_id}/role?new_role_id={role_id}
Authorization: Bearer {owner_token}
```

**Response:**
```json
{
  "success": true,
  "message": "Employee role updated from Fleet Manager to Dispatcher",
  "employee": {
    "id": "uuid",
    "name": "Jane Smith",
    "username": "janesmith"
  },
  "old_role": "Fleet Manager",
  "new_role": {
    "id": "uuid",
    "name": "Dispatcher",
    "key": "dispatcher"
  }
}
```

#### 4. Remove Employee
```http
DELETE /api/organization/employees/{user_org_id}
Authorization: Bearer {owner_token}
```

**Response:**
```json
{
  "success": true,
  "message": "Jane Smith (Fleet Manager) has been removed from the organization"
}
```

#### 5. Get Statistics
```http
GET /api/organization/statistics
Authorization: Bearer {owner_token}
```

**Response:**
```json
{
  "success": true,
  "statistics": {
    "total_members": 18,
    "active_employees": 15,
    "pending_requests": 3,
    "inactive_members": 0,
    "recent_joins_30_days": 5,
    "role_distribution": {
      "fleet_manager": {
        "role_name": "Fleet Manager",
        "count": 3,
        "is_custom": false
      },
      "dispatcher": {
        "role_name": "Dispatcher",
        "count": 5,
        "is_custom": false
      }
    }
  }
}
```

---

## Frontend Implementation

### Files Created

#### Backend (1 file):
1. **`backend/app/api/v1/organization_management.py`** - Organization management endpoints

#### Frontend (7 files):

**Dashboard Feature (Owner View):**
1. **`frontend/lib/data/services/organization_dashboard_api.dart`** - Dashboard API service
2. **`frontend/lib/providers/organization_dashboard_provider.dart`** - Dashboard state management
3. **`frontend/lib/presentation/screens/organization/organization_dashboard.dart`** - Main dashboard with tabs
4. **`frontend/lib/presentation/screens/organization/organization_overview_tab.dart`** - Overview tab
5. **`frontend/lib/presentation/screens/organization/employees_tab.dart`** - Employees management tab

**Multi-Organization Management (Organization Switching):**
6. **`frontend/lib/data/services/organization_api.dart`** - Organization API service
7. **`frontend/lib/providers/organization_provider.dart`** - Multi-organization state management

### Navigation Integration

**Add to your Home/Dashboard screen:**

```dart
// Check if user is owner
if (userRole?.roleKey == 'owner') {
  ListTile(
    leading: const Icon(Icons.business),
    title: const Text('My Organization'),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrganizationDashboard(),
        ),
      );
    },
  ),
}
```

---

## User Experience

### Owner Dashboard Flow

1. **Login as Owner**
2. **Navigate to "My Organization"**
3. **See 3 Tabs:**

#### Tab 1: Overview
- Company name and details
- Quick stats (employees, pending requests)
- Role distribution chart
- Company contact information

#### Tab 2: Employees
- List of all active employees
- Each card shows:
  - Name, username, avatar
  - Current role
  - Contact info
  - Status badge
- **Actions per employee:**
  - **Change Role**: Opens dialog to select new role
  - **Remove**: Confirmation dialog then removes
- **Filters:**
  - Status: Active/Pending/All
  - Refresh button
- **Protected:**
  - Cannot change owner's role
  - Cannot remove self

#### Tab 3: Grant Access
- List of pending join requests
- Each request shows:
  - User information
  - Requested role
  - Request date
- **Actions:**
  - **Approve**: Accept with requested role
  - **Change**: Select different role then approve
  - **Reject**: Decline the request
- **Badge on tab** shows pending count

---

## Security & Permissions

### Authorization Checks

All endpoints verify:
1. ✅ User is authenticated (JWT token)
2. ✅ User has 'owner' role
3. ✅ User's organization matches the resource
4. ✅ Cannot modify owner role
5. ✅ Cannot remove self

### Protected Actions

- ❌ Cannot change owner's role
- ❌ Cannot assign owner role to others
- ❌ Cannot remove yourself
- ❌ Only owners can access organization management

---

## Features Breakdown

### Organization Overview
```dart
// Shows:
✓ Company name with business type
✓ Location (city, state)
✓ Total employees count
✓ Pending requests count with alert badge
✓ Role distribution breakdown
✓ Contact information (email, phone, address)
✓ Pull-to-refresh
```

### Employee Management
```dart
// Features:
✓ Search/filter employees
✓ Status filter (active/pending/all)
✓ Role badges with colors
✓ Change employee role (dropdown selection)
✓ Remove employee (with confirmation)
✓ Owner protection (cannot modify)
✓ Pull-to-refresh
✓ Empty states
✓ Loading states
✓ Error handling
```

### Grant Access (Pending Requests)
```dart
// Features:
✓ View pending join requests
✓ See requested role
✓ User information display
✓ Approve as requested
✓ Change role before approval
✓ Reject requests
✓ Badge count on tab
✓ Refresh button
```

---

## API Service Structure

### Organization Dashboard API (for owner dashboard)
```dart
class OrganizationDashboardApi {
  ✓ getMyOrganization()
  ✓ getEmployees({roleFilter, statusFilter})
  ✓ updateEmployeeRole(userOrgId, newRoleId)
  ✓ removeEmployee(userOrgId)
  ✓ getStatistics()
}
```

### Organization API (for multi-organization management)
```dart
class OrganizationApi {
  ✓ getUserOrganizations()
  ✓ switchOrganization(organizationId)
  ✓ getOrganizationMembers(organizationId, {includePending})
  ✓ getPendingUsers(organizationId)
  ✓ approveUser(organizationId, userId, roleKey)
  ✓ rejectUser(organizationId, userId)
  ✓ updateUserRole(organizationId, userId, roleKey)
  ✓ removeUser(organizationId, userId)
}
```

## State Management

### Organization Dashboard State (for owner dashboard)
```dart
class OrganizationDashboardState {
  ✓ organization (company details)
  ✓ statistics (counts, distributions)
  ✓ employees (list)
  ✓ isLoading
  ✓ error
}

class OrganizationDashboardNotifier {
  ✓ loadMyOrganization()
  ✓ loadEmployees({roleFilter, statusFilter})
  ✓ loadStatistics()
  ✓ updateEmployeeRole(userOrgId, roleId)
  ✓ removeEmployee(userOrgId)
  ✓ clearError()
}
```

### Organization State (for multi-organization switching)
```dart
class OrganizationState {
  ✓ currentOrganizationId
  ✓ currentOrganization
  ✓ organizations (list)
  ✓ activeOrganizations (getter)
  ✓ isLoading
  ✓ error
}

class OrganizationNotifier {
  ✓ loadOrganizations()
  ✓ switchOrganization(organizationId)
  ✓ clearError()
}
```

---

## Testing Scenarios

### Test 1: View Organization
```bash
# Login as owner
POST /api/auth/login

# View organization
GET /api/organization/my-organization
Expected: Organization details with statistics
```

### Test 2: View Employees
```bash
# Get all active employees
GET /api/organization/employees?status_filter=active
Expected: List of active employees

# Filter by role
GET /api/organization/employees?role_filter=fleet_manager
Expected: Only fleet managers
```

### Test 3: Change Employee Role
```bash
# Update role
PUT /api/organization/employees/{user_org_id}/role?new_role_id={new_role}
Expected: Role updated, statistics refreshed
```

### Test 4: Remove Employee
```bash
# Remove employee
DELETE /api/organization/employees/{user_org_id}
Expected: Employee removed, counts updated
```

### Test 5: Try to Modify Owner
```bash
# Try to change owner role
PUT /api/organization/employees/{owner_user_org_id}/role?new_role_id={any}
Expected: 403 Forbidden - "Cannot change owner's role"
```

---

## UI Components

### Color Scheme by Role
- **Owner**: Purple
- **Fleet Manager**: Blue
- **Dispatcher**: Green
- **Driver**: Orange
- **Accountant**: Teal
- **Maintenance Manager**: Brown
- **Default**: Grey

### Icons
- Organization: `Icons.business`
- Employees: `Icons.people`
- Grant Access: `Icons.pending_actions`
- Role Badge: `Icons.badge`
- Change Role: `Icons.swap_horiz`
- Remove: `Icons.person_remove`

---

## Error Handling

All screens handle:
- ✅ Loading states (spinner)
- ✅ Error states (message + retry button)
- ✅ Empty states (helpful message)
- ✅ Network errors
- ✅ Permission errors
- ✅ Not found errors

---

## Future Enhancements

1. **Bulk Actions**: Select multiple employees and change roles
2. **Export**: Download employee list as CSV/Excel
3. **Analytics**: Employee join trends, role changes over time
4. **Notifications**: Email owner when new join requests
5. **Role Templates**: Save custom role combinations
6. **Department Management**: Group employees by department
7. **Activity Log**: Track all role changes and removals
8. **Search**: Search employees by name, role, email
9. **Employee Profile**: Detailed view with activity history
10. **Invitation System**: Invite specific users to join

---

## Important Notes

### Provider Separation

The organization feature uses **two separate providers** for different purposes:

1. **OrganizationDashboardProvider** (`organization_dashboard_provider.dart`)
   - Used for the owner dashboard feature
   - Shows company details, statistics, and employee management
   - Used in: `organization_dashboard.dart`, `organization_overview_tab.dart`, `employees_tab.dart`
   - Endpoints: `/api/organization/my-organization`, `/api/organization/employees`, etc.

2. **OrganizationProvider** (`organization_provider.dart`)
   - Used for multi-organization management
   - Allows users to view and switch between organizations they belong to
   - Used in: `main_screen.dart`, `organization_selector_screen.dart`, `create_organization_screen.dart`, `organization_management_screen.dart`
   - Endpoints: `/api/user/organizations`, `/api/user/switch-organization`, etc.

**Why separate?**
- Different data structures: Dashboard needs detailed org info; Selector needs list of orgs
- Different use cases: Dashboard for managing ONE organization; Selector for switching between MULTIPLE organizations
- Prevents conflicts and keeps code clean and maintainable

---

## Summary

The Organization Dashboard provides owners with **complete control** over their organization:

✅ **See** company details and statistics
✅ **Manage** employee roles
✅ **Grant** or deny access to new joiners
✅ **Remove** employees when needed
✅ **Monitor** team composition
✅ **Protected** owner role
✅ **Real-time** statistics
✅ **Intuitive** 3-tab interface

All features are production-ready with proper security, error handling, and user experience! 🎉
