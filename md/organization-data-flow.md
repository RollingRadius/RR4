# Organization Data Flow

## Database Structure

### Tables Involved

1. **`organizations` (Company table)**
   - Stores company/organization details
   - Fields: `id`, `company_name`, `business_type`, `email`, `phone`, `address`, `city`, `state`, `pincode`, `country`, `status`, etc.
   - This is the main source of organization information

2. **`user_organizations` (Junction table)**
   - Links users to organizations
   - Fields: `id`, `user_id`, `organization_id`, `role_id`, `requested_role_id`, `status`, `joined_at`, `approved_at`, `approved_by`, etc.
   - Tracks which users belong to which organizations
   - Status can be: 'active', 'pending', 'inactive'

3. **`roles` table**
   - Stores role definitions
   - Fields: `id`, `role_name`, `role_key`, `description`, `is_custom`
   - Defines available roles (owner, fleet_manager, dispatcher, driver, etc.)

## Data Flow: Database → Backend → Frontend → UI

### Flow 1: Organization Selector (Multi-Organization View)

**Purpose:** User wants to see all organizations they belong to and switch between them

**Endpoint:** `GET /api/user/organizations`

**Database Query:**
```sql
SELECT
    uo.id,
    uo.user_id,
    uo.organization_id,
    uo.status,
    uo.joined_at,
    o.company_name,
    o.business_type,
    r.role_name,
    r.role_key
FROM user_organizations uo
JOIN organizations o ON uo.organization_id = o.id
JOIN roles r ON uo.role_id = r.id
WHERE uo.user_id = :current_user_id
```

**Backend Processing:**
```python
# backend/app/api/v1/user.py: get_user_organizations()
user_orgs = db.query(UserOrganization).filter(
    UserOrganization.user_id == current_user.id
).join(Organization).join(Role).all()

organizations = []
for user_org in user_orgs:
    if user_org.organization:
        organizations.append({
            "organization_id": str(user_org.organization_id),
            "organization_name": user_org.organization.company_name,  # From organizations table
            "role": user_org.role.role_name,
            "role_key": user_org.role.role_key,
            "status": user_org.status,
            "joined_at": user_org.joined_at.isoformat()
        })
```

**Frontend Processing:**
```dart
// frontend/lib/data/services/organization_api.dart
Future<Map<String, dynamic>> getUserOrganizations() async {
  final response = await _apiService.dio.get('/api/user/organizations');
  return response.data;
}

// frontend/lib/providers/organization_provider.dart
final organizations = (response['organizations'] as List)
    .map((e) => e as Map<String, dynamic>)
    .toList();

state = state.copyWith(
  organizations: organizations,
  currentOrganization: organizations.first
);
```

**UI Display:**
```dart
// frontend/lib/presentation/screens/organizations/organization_selector_screen.dart
ListView(
  children: orgState.organizations.map((org) {
    return ListTile(
      title: Text(org['organization_name']),  // Shows company name
      subtitle: Text(org['role']),             // Shows role
      trailing: org['status'] == 'pending'
          ? Chip(label: Text('Pending'))
          : Icon(Icons.arrow_forward_ios),
    );
  }).toList(),
)
```

---

### Flow 2: Organization Dashboard (Owner View)

**Purpose:** Owner wants to see detailed company information and manage employees

**Endpoint:** `GET /api/organization/my-organization`

**Database Query:**
```sql
-- Get organization details
SELECT * FROM organizations
WHERE id = :organization_id

-- Get statistics
SELECT
    COUNT(DISTINCT uo.id) as total_employees,
    SUM(CASE WHEN uo.status = 'pending' THEN 1 ELSE 0 END) as pending_requests,
    r.role_key,
    r.role_name,
    COUNT(uo.id) as count
FROM user_organizations uo
JOIN roles r ON uo.role_id = r.id
WHERE uo.organization_id = :organization_id
GROUP BY r.role_key, r.role_name
```

**Backend Processing:**
```python
# backend/app/api/v1/organization_management.py: get_my_organization()
user_org = db.query(UserOrganization).filter(
    UserOrganization.user_id == current_user.id,
    UserOrganization.status == 'active'
).first()

organization = user_org.organization  # Get from organizations table

# Build organization response with data from organizations table
org_data = {
    "id": str(organization.id),
    "name": organization.company_name,
    "business_type": organization.business_type,
    "email": organization.business_email,
    "phone": organization.business_phone,
    "address": organization.address,
    "city": organization.city,
    "state": organization.state,
    "pincode": organization.pincode,
    "country": organization.country,
    "status": organization.status,
}

# Get statistics
total_employees = db.query(UserOrganization).filter(
    UserOrganization.organization_id == organization.id,
    UserOrganization.status == 'active'
).count()
```

**Frontend Processing:**
```dart
// frontend/lib/providers/organization_dashboard_provider.dart
Future<void> loadMyOrganization() async {
  final response = await _organizationDashboardApi.getMyOrganization();

  state = state.copyWith(
    organization: response['organization'],  // Company details
    statistics: response['statistics'],      // Counts and distributions
  );
}
```

**UI Display:**
```dart
// frontend/lib/presentation/screens/organization/organization_overview_tab.dart
Card(
  child: Column(
    children: [
      Text(org['name']),              // Company name from organizations table
      Text(org['business_type']),     // Business type
      Text('${org['city']}, ${org['state']}'),  // Location
      Text(org['email']),             // Contact email
      Text(org['phone']),             // Contact phone
    ],
  ),
)
```

---

## Key Points

### Data Source
- **All organization details** (name, address, email, phone, etc.) come from the `organizations` table
- The `user_organizations` table only stores the **relationship** between users and organizations (role, status, dates)

### Status Types in `user_organizations`
1. **active** - User is an active member of the organization
2. **pending** - User has requested to join but not yet approved
3. **inactive** - User was removed or left the organization

### Role Assignment
1. When user creates a company → Automatically assigned "owner" role
2. When user joins a company → Selects desired role, stores in `requested_role_id`
3. Owner approves → Copies `requested_role_id` to `role_id`, sets status to 'active'

### Endpoints Summary

**Multi-Organization Management:**
- `GET /api/user/organizations` - Get all user's organizations
- `POST /api/user/set-organization/{id}` - Switch active organization

**Organization Dashboard (Owner):**
- `GET /api/organization/my-organization` - Get current org details + stats
- `GET /api/organization/employees` - Get employee list
- `PUT /api/organization/employees/{id}/role` - Update employee role
- `DELETE /api/organization/employees/{id}` - Remove employee
- `GET /api/organization/statistics` - Get detailed statistics

**Organization Member Management:**
- `GET /api/organizations/{id}/members` - Get organization members
- `GET /api/organizations/{id}/pending-users` - Get pending join requests
- `POST /api/organizations/{id}/approve-user` - Approve join request
- `POST /api/organizations/{id}/reject-user` - Reject join request
- `PUT /api/organizations/{id}/members/{id}/role` - Update member role
- `DELETE /api/organizations/{id}/members/{id}` - Remove member

---

## Fixed Issues

### Issue 1: AttributeError - Role.name
**Problem:** Code was using `role.name` instead of `role.role_name`
**Location:** `backend/app/api/v1/user.py` line 110 and 136
**Fix:** Changed to `role.role_name`

### Issue 2: Provider Conflict
**Problem:** Two different providers with same name
**Solution:** Separated into:
- `OrganizationProvider` - Multi-organization switching
- `OrganizationDashboardProvider` - Owner dashboard view

### Issue 3: Wrong Endpoint Name
**Problem:** Frontend calling `/switch-organization` but backend has `/set-organization`
**Fix:** Updated frontend to use correct endpoint path

---

## Testing the Organization Flow

1. **Create Organization:**
   ```
   POST /api/companies/create
   → Creates entry in organizations table
   → Creates entry in user_organizations with role=owner, status=active
   ```

2. **View Organizations:**
   ```
   GET /api/user/organizations
   → Joins user_organizations + organizations + roles
   → Returns list with company names and user's role in each
   ```

3. **View Dashboard:**
   ```
   GET /api/organization/my-organization
   → Gets current organization from organizations table
   → Calculates statistics from user_organizations
   → Returns company details + employee counts + role distribution
   ```

All data flows correctly from the database tables to the UI!
