# Profile Completion System

**Date:** 2026-01-28
**Status:** COMPLETED ✅

---

## Overview

Implemented a profile completion system where users select their role on first login. Once a role is selected, it **cannot be changed** (permanent decision).

---

## User Flow

### 1. Signup
- User creates account (email or security questions method)
- If they **skip company selection** → `profile_completed = false`
- If they **join/create company** → `profile_completed = true`

### 2. First Login
- User logs in with username/password
- Backend returns `profile_completed: false`
- Frontend detects this and redirects to `/profile` page

### 3. Profile Completion Page
User chooses one of 4 role types:

1. **Independent User** - No company affiliation
2. **Driver** - Register as driver (requires license info)
3. **Join Company** - Join existing company (becomes Pending User)
4. **Create Company** - Create new company (becomes Owner)

### 4. After Selection
- `profile_completed = true` (locked forever)
- User redirected to dashboard
- Role cannot be changed

---

## Database Changes

### Migration: 007_add_profile_completed

**Added Column:**
```sql
ALTER TABLE users ADD COLUMN profile_completed BOOLEAN NOT NULL DEFAULT false;
```

**Updates:**
- Existing users with roles → `profile_completed = true`
- New users without roles → `profile_completed = false`

---

## Backend Implementation

### 1. User Model Updated

**File:** `backend/app/models/user.py`

```python
class User(Base):
    # ... existing fields
    profile_completed = Column(Boolean, nullable=False, default=False)
```

### 2. New API Endpoints

**File:** `backend/app/api/v1/profile.py`

#### Get Profile Status
```
GET /api/profile/status
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "profile_completed": false,
  "user_id": "uuid",
  "username": "john_doe",
  "full_name": "John Doe",
  "email": "john@example.com",
  "phone": "1234567890",
  "role": null,
  "role_type": null,
  "company_id": null,
  "company_name": null
}
```

#### Complete Profile
```
POST /api/profile/complete
Authorization: Bearer <token>
```

**Request Examples:**

**Option 1: Independent User**
```json
{
  "role_type": "independent"
}
```

**Option 2: Driver**
```json
{
  "role_type": "driver",
  "license_number": "DL1234567890",
  "license_expiry": "2027-12-31"
}
```

**Option 3: Join Company**
```json
{
  "role_type": "join_company",
  "company_id": "uuid-of-company"
}
```

**Option 4: Create Company**
```json
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

**Response:**
```json
{
  "success": true,
  "message": "Profile completed successfully as driver",
  "user_id": "uuid",
  "role": "Driver",
  "role_type": "driver",
  "company_id": null,
  "company_name": null,
  "driver_id": "uuid"
}
```

**Error if Already Completed:**
```json
{
  "detail": "Profile already completed. Role cannot be changed."
}
```

### 3. Updated Login Response

**File:** `backend/app/services/auth_service.py`

**Login now returns:**
```json
{
  "success": true,
  "access_token": "jwt-token-here",
  "token_type": "bearer",
  "user_id": "uuid",
  "username": "john_doe",
  "email": "john@example.com",
  "profile_completed": false,  ← NEW!
  "role": null,
  "company_id": null,
  "company_name": null
}
```

### 4. Updated Signup Logic

**File:** `backend/app/services/auth_service.py`

**Before:**
- Skip company selection → Becomes Independent User automatically

**Now:**
- Skip company selection → No role assigned, must complete profile on first login
- Join company → Role assigned (Pending User), `profile_completed = true`
- Create company → Role assigned (Owner), `profile_completed = true`

### 5. Profile Service

**File:** `backend/app/services/profile_service.py`

**Key Methods:**
- `get_profile_status()` - Check if profile completed
- `complete_profile()` - Set role (one-time only)

**Security Features:**
- Validates profile not already completed
- Creates appropriate role and relationships
- Logs audit events
- Marks profile as permanently completed

---

## Role Types Explained

### 1. Independent User
- No company affiliation
- Can use basic features
- Cannot access company-specific features
- Can upgrade to join/create company later? NO - role is locked

### 2. Driver
- Creates driver profile with license info
- Can be hired by companies
- Initially independent (no company)
- Driver profile includes:
  - License number
  - License expiry
  - Employment type: permanent
  - Status: available
  - Verified: true

### 3. Join Company (Pending User)
- User selects existing company
- Status: pending (awaits admin approval)
- Cannot use company features until approved
- Admin must approve from organization management

### 4. Create Company (Owner)
- User creates new company
- Becomes Owner immediately
- Full access to all company features
- Can manage users, vehicles, drivers, etc.

---

## Frontend Implementation Guide

### 1. Login Page - Check Profile Status

```dart
// After successful login
final loginResponse = await authApi.login(username, password);

if (!loginResponse.profileCompleted) {
  // Redirect to profile completion page
  Navigator.pushReplacementNamed(context, '/profile-complete');
} else {
  // Go to dashboard
  Navigator.pushReplacementNamed(context, '/dashboard');
}
```

### 2. Profile Completion Page

**File:** `frontend/lib/screens/profile/profile_completion_page.dart`

```dart
class ProfileCompletionPage extends StatefulWidget {
  @override
  _ProfileCompletionPageState createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  String? selectedRoleType;

  // Controllers for different role types
  final licenseNumberController = TextEditingController();
  final licenseExpiryController = TextEditingController();
  final companyNameController = TextEditingController();
  // ... other controllers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Cannot go back
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Role',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '⚠️ This decision is permanent and cannot be changed later.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            // Role Type Selection
            _buildRoleOption('independent', 'Independent User',
              'Use basic features without company affiliation'),
            _buildRoleOption('driver', 'Driver',
              'Register as a driver with license information'),
            _buildRoleOption('join_company', 'Join Company',
              'Join an existing company (requires approval)'),
            _buildRoleOption('create_company', 'Create Company',
              'Create your own company and become the owner'),

            SizedBox(height: 24),

            // Conditional forms based on selected role
            if (selectedRoleType == 'driver') _buildDriverForm(),
            if (selectedRoleType == 'join_company') _buildJoinCompanyForm(),
            if (selectedRoleType == 'create_company') _buildCreateCompanyForm(),

            SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedRoleType != null ? _submitProfile : null,
                child: Text('Complete Profile', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(String value, String title, String description) {
    return Card(
      elevation: selectedRoleType == value ? 4 : 1,
      color: selectedRoleType == value ? Colors.blue[50] : null,
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedRoleType,
        onChanged: (value) {
          setState(() {
            selectedRoleType = value;
          });
        },
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildDriverForm() {
    return Column(
      children: [
        TextField(
          controller: licenseNumberController,
          decoration: InputDecoration(
            labelText: 'License Number *',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: licenseExpiryController,
          decoration: InputDecoration(
            labelText: 'License Expiry Date (YYYY-MM-DD) *',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinCompanyForm() {
    return Column(
      children: [
        // Company search/selection UI
        TextField(
          decoration: InputDecoration(
            labelText: 'Search Company',
            border: OutlineInputBorder(),
          ),
          onChanged: (query) {
            // Search companies API call
          },
        ),
        // Display search results
      ],
    );
  }

  Widget _buildCreateCompanyForm() {
    return Column(
      children: [
        TextField(
          controller: companyNameController,
          decoration: InputDecoration(
            labelText: 'Company Name *',
            border: OutlineInputBorder(),
          ),
        ),
        // ... other company fields
      ],
    );
  }

  Future<void> _submitProfile() async {
    try {
      Map<String, dynamic> requestData = {
        'role_type': selectedRoleType,
      };

      // Add fields based on role type
      if (selectedRoleType == 'driver') {
        requestData['license_number'] = licenseNumberController.text;
        requestData['license_expiry'] = licenseExpiryController.text;
      } else if (selectedRoleType == 'join_company') {
        requestData['company_id'] = selectedCompanyId;
      } else if (selectedRoleType == 'create_company') {
        requestData['company_name'] = companyNameController.text;
        // ... other company fields
      }

      final response = await profileApi.completeProfile(requestData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      // Navigate to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');

    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
```

### 3. Profile API Service

**File:** `frontend/lib/services/profile_api.dart`

```dart
class ProfileApi {
  final Dio dio;

  ProfileApi(this.dio);

  Future<ProfileStatusResponse> getProfileStatus() async {
    final response = await dio.get('/api/profile/status');
    return ProfileStatusResponse.fromJson(response.data);
  }

  Future<ProfileCompletionResponse> completeProfile(Map<String, dynamic> data) async {
    final response = await dio.post('/api/profile/complete', data: data);
    return ProfileCompletionResponse.fromJson(response.data);
  }
}
```

### 4. Route Guard

**File:** `frontend/lib/main.dart` or router setup

```dart
// Check profile completion before allowing access to app
class AuthGuard {
  static Future<bool> checkProfileCompleted() async {
    final profileApi = ProfileApi(dio);
    final status = await profileApi.getProfileStatus();
    return status.profileCompleted;
  }
}

// In your router
onGenerateRoute: (settings) {
  if (settings.name == '/dashboard') {
    return MaterialPageRoute(
      builder: (context) => FutureBuilder(
        future: AuthGuard.checkProfileCompleted(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LoadingScreen();
          }
          if (!snapshot.data!) {
            return ProfileCompletionPage();
          }
          return DashboardPage();
        },
      ),
    );
  }
}
```

---

## Security Features

### 1. One-Time Selection
- `profile_completed` flag prevents multiple changes
- Backend validates flag before allowing profile update
- Returns 400 error if already completed

### 2. Authentication Required
- All profile endpoints require JWT token
- Uses `get_current_user` dependency

### 3. Audit Logging
- All profile completions logged
- Tracks:
  - User ID
  - Role type selected
  - Timestamp
  - Company (if applicable)

### 4. Validation
- Driver: requires license_number and license_expiry
- Join company: requires valid company_id
- Create company: requires company details
- Independent: no additional fields required

---

## API Testing

### 1. Test Profile Status (New User)
```bash
curl -X GET http://localhost:8000/api/profile/status \
  -H "Authorization: Bearer <jwt-token>"
```

**Expected:**
```json
{
  "success": true,
  "profile_completed": false,
  "role": null
}
```

### 2. Test Complete Profile (Driver)
```bash
curl -X POST http://localhost:8000/api/profile/complete \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "role_type": "driver",
    "license_number": "DL1234567890",
    "license_expiry": "2027-12-31"
  }'
```

**Expected:**
```json
{
  "success": true,
  "message": "Profile completed successfully as driver",
  "role": "Independent User",
  "role_type": "driver",
  "driver_id": "uuid"
}
```

### 3. Test Second Attempt (Should Fail)
```bash
curl -X POST http://localhost:8000/api/profile/complete \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "role_type": "independent"
  }'
```

**Expected:**
```json
{
  "detail": "Profile already completed. Role cannot be changed."
}
```

---

## Files Created/Modified

### New Files (4)
1. `backend/alembic/versions/007_add_profile_completed.py` - Migration
2. `backend/app/schemas/profile.py` - Profile schemas
3. `backend/app/services/profile_service.py` - Profile business logic
4. `backend/app/api/v1/profile.py` - Profile API endpoints

### Modified Files (4)
1. `backend/app/models/user.py` - Added profile_completed field
2. `backend/app/schemas/auth.py` - Updated LoginResponse
3. `backend/app/services/auth_service.py` - Updated signup and login logic
4. `backend/app/main.py` - Registered profile router

---

## Summary

✅ **Backend Complete:**
- Database migration applied
- Profile completion API endpoints created
- Login returns `profile_completed` status
- Signup doesn't auto-assign role if company skipped
- Profile can only be completed once (permanent)

🎨 **Frontend TODO:**
- Create ProfileCompletionPage
- Add route guard to check profile_completed
- Create ProfileApi service
- Add forms for each role type
- Handle profile completion flow

---

## User Experience

### Current Flow (OLD):
1. Signup → Skip company → Becomes "Independent User" automatically ❌

### New Flow:
1. Signup → Skip company → No role assigned
2. Login → `profile_completed: false` → Redirect to `/profile`
3. User sees 4 options:
   - Independent User
   - Driver (with license form)
   - Join Company (with company search)
   - Create Company (with company form)
4. User selects → **Permanent decision** ⚠️
5. Redirect to dashboard with assigned role ✅

---

**Generated:** 2026-01-28
**Status:** Backend Complete ✅ | Frontend Pending
