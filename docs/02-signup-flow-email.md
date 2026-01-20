# Signup Flow - Email Method

## Overview

Standard signup process for users who provide an email address during registration.

**Key Features:**
- Email verification required
- **Company selection is optional** - can skip and add later
- Three options: Join existing company, create new company, or skip
- Independent users can add/join company anytime from dashboard

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    SIGNUP PAGE                               │
├─────────────────────────────────────────────────────────────┤
│  Create Your Account                                         │
│  ──────────────────────────────────────────                 │
│  Full Name: [________________]                               │
│  Username: [________________]                                │
│  Email: [user@example.com___]  ← Email provided            │
│  Phone: [________________]                                   │
│  Password: [••••••••]                                        │
│  Confirm Password: [••••••••]                                │
│                                                              │
│  [✓] I agree to Terms of Service                            │
│                                                              │
│  [Continue]                                                  │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    COMPANY SELECTION (OPTIONAL)              │
├─────────────────────────────────────────────────────────────┤
│  Are you joining an existing company or creating a new one? │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────┐ │
│  │ Existing Company │  │ + Add New Company│  │Skip Now ⏭│ │
│  │ Join your team   │  │ Become Owner     │  │Add Later │ │
│  └──────────────────┘  └──────────────────┘  └──────────┘ │
└────────┬────────────────────┬──────────────────────┬────────┘
         │                    │                      │
         ▼                    ▼                      ▼
  [Join Existing]    [Create New Company]      [Skip for now]
         │                    │                      │
         ▼                    ▼                      │
┌──────────────────┐  ┌─────────────────────┐       │
│ Search & Select  │  │ Company Reg Form    │       │
│ Company          │  │ (GSTIN, PAN, etc.) │       │
└────────┬─────────┘  └─────────┬───────────┘       │
         │                      │                    │
         └──────────┬───────────┘                    │
                    │                                │
                    └────────────┬───────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND PROCESSING                        │
├─────────────────────────────────────────────────────────────┤
│  1. Validate all user data                                   │
│  2. Create user account (status: pending_verification)       │
│  3. IF company selected: Link to company (existing or new)   │
│  4. IF company selected: Assign role (Pending User or Owner) │
│  5. IF no company: Assign role "Independent User"            │
│  6. Hash password with bcrypt                                │
│  7. Generate email verification token (24h expiry)           │
│  8. Send verification email                                  │
│  9. IF joining existing: Notify company admins               │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    VERIFICATION EMAIL                        │
├─────────────────────────────────────────────────────────────┤
│  To: user@example.com                                        │
│  Subject: Verify Your Account                               │
│                                                              │
│  Hi [Name],                                                  │
│                                                              │
│  Click the link below to verify your email:                 │
│  [Verify Email]                                              │
│  https://fleetapp.com/verify?token=xyz789                   │
│                                                              │
│  This link expires in 24 hours.                              │
└────────────┬────────────────────────────────────────────────┘
             │
             │ User clicks verification link
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    EMAIL VERIFIED                            │
├─────────────────────────────────────────────────────────────┤
│  ✓ Email verified successfully!                             │
│                                                              │
│  IF JOINED EXISTING COMPANY:                                 │
│    → Status: Active (Pending User role)                      │
│    → Waiting for admin to assign proper role                 │
│                                                              │
│  IF CREATED NEW COMPANY:                                     │
│    → Status: Active (Owner role)                             │
│    → Full access to company                                  │
│                                                              │
│  IF SKIPPED COMPANY SELECTION:                               │
│    → Status: Active (Independent User)                       │
│    → Can add/join company later from dashboard               │
│    → Limited functionality until company assigned            │
│                                                              │
│  [Continue to Dashboard]                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Process

### Step 1: User Information

**Input Fields:**
- Full Name (required)
- Username (required, unique, 3+ chars)
- Email (required, valid format)
- Phone (required)
- Password (required, 8+ chars with complexity)
- Confirm Password (must match)
- Terms of Service acceptance

**Validation:**
- Email format: `user@domain.com`
- Username: alphanumeric, 3-20 characters
- Password: min 8 chars, uppercase, lowercase, number, special char
- Phone: valid format

---

### Step 2: Company Selection (Optional)

**Note:** Users can skip this step and add/join a company later from their dashboard.

#### Option A: Join Existing Company

**Flow:**
1. User searches for company by name
2. System returns matching companies
3. User selects company from list
4. Proceeds to verification

**Result:**
- Role: **Pending User** (no capabilities)
- Status: Waiting for admin approval
- Admin notification sent

#### Option B: Create New Company

**Required Information:**
- Company Name
- Business Type (dropdown)
- Business Email & Phone
- Complete Address (street, city, state, pincode)

**Optional Information:**
- GSTIN (15-char format validation)
- PAN Number (10-char format validation)
- Registration Number
- Registration Date

**Note:** Legal information (GSTIN, PAN, registration details) can be added later from company settings.

**Validation:**
- GSTIN format check (if provided)
- PAN format check (if provided)
- GSTIN-PAN linkage verification (if both provided)

**Result:**
- Role: **Owner** (full capabilities)
- Status: Active immediately
- Company created and initialized

#### Option C: Skip Company Selection

**Flow:**
1. User clicks "Skip for now"
2. Account created without company
3. Can add/join company later

**Result:**
- Role: **Independent User** (limited capabilities)
- Status: Active after email verification
- Can join/create company from dashboard later

**When to Skip:**
- Exploring the platform
- Not sure which company to join
- Want to evaluate before committing
- Personal account without organization

---

### Step 3: Email Verification

**Process:**
1. Verification email sent with secure token
2. Token expires in 24 hours
3. User clicks verification link
4. Token validated by backend
5. Account status updated to "active"

**Token Security:**
- 32-byte cryptographically secure token
- Single-use (invalidated after verification)
- Time-limited expiration
- Stored with user ID and timestamp

---

## API Request Example

### Joining Existing Company

```json
POST /api/auth/signup

{
  "full_name": "John Doe",
  "username": "johndoe123",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "auth_method": "email",
  "company_type": "existing",
  "company_id": "company_uuid",
  "terms_accepted": true
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "user_uuid",
  "username": "johndoe123",
  "email": "john.doe@example.com",
  "status": "pending_verification",
  "auth_method": "email",
  "company_id": "company_uuid",
  "company_name": "ABC Logistics",
  "role": "Pending User",
  "message": "Verification email sent. Admin will assign your role.",
  "verification_expires_at": "2024-01-16T10:00:00Z"
}
```

---

### Creating New Company

```json
POST /api/auth/signup

{
  "full_name": "Jane Smith",
  "username": "janesmith456",
  "email": "jane@xyzlogistics.com",
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "auth_method": "email",
  "company_type": "new",
  "company_details": {
    "company_name": "XYZ Logistics Pvt Ltd",
    "business_type": "transportation",
    "gstin": "29ABCDE1234F1Z5",
    "pan_number": "ABCDE1234F",
    "registration_number": "U63040KA2024PTC123456",
    "business_email": "info@xyzlogistics.com",
    "business_phone": "+91-1234567890",
    "address": "123 Transport St",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560001",
    "country": "India"
  },
  "terms_accepted": true
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "user_uuid",
  "username": "janesmith456",
  "email": "jane@xyzlogistics.com",
  "status": "pending_verification",
  "auth_method": "email",
  "company_id": "new_company_uuid",
  "company_name": "XYZ Logistics Pvt Ltd",
  "role": "Owner",
  "capabilities": ["*"],
  "message": "Verification email sent. You are now the Owner.",
  "verification_expires_at": "2024-01-16T10:00:00Z"
}
```

---

### Skip Company Selection

```json
POST /api/auth/signup

{
  "full_name": "Alex Johnson",
  "username": "alexjohnson789",
  "email": "alex@personal.com",
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "auth_method": "email",
  "company_type": null,
  "terms_accepted": true
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "user_uuid",
  "username": "alexjohnson789",
  "email": "alex@personal.com",
  "status": "pending_verification",
  "auth_method": "email",
  "company_id": null,
  "company_name": null,
  "role": "Independent User",
  "capabilities": ["profile.view", "profile.edit"],
  "message": "Verification email sent. You can add a company later from your dashboard.",
  "verification_expires_at": "2024-01-16T10:00:00Z"
}
```

---

## Email Verification Endpoint

```json
POST /api/auth/verify-email

{
  "token": "verification_token_from_email"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully",
  "user_id": "user_uuid",
  "redirect_url": "/dashboard"
}
```

---

## Error Scenarios

### Email Already Exists
```json
{
  "success": false,
  "error": "email_exists",
  "message": "Email already registered"
}
```

### Username Taken
```json
{
  "success": false,
  "error": "username_taken",
  "message": "Username not available"
}
```

### Invalid GSTIN
```json
{
  "success": false,
  "error": "invalid_gstin",
  "message": "Invalid GSTIN format or not linked to PAN"
}
```

### Token Expired
```json
{
  "success": false,
  "error": "token_expired",
  "message": "Verification link expired. Request new link."
}
```

---

## Security Features

1. **Password Hashing**: Bcrypt with salt
2. **Email Verification**: Required before full access
3. **Token Expiration**: 24-hour limit
4. **Rate Limiting**: 5 signup attempts per hour per IP
5. **GSTIN Validation**: Real-time verification
6. **Audit Logging**: All actions tracked

---

## Related Documents

- [Company Management](04-company-management.md)
- [API Endpoints](05-api-endpoints.md)
- [Frontend Implementation](06-frontend-implementation.md)
- [Role Assignment](10-role-assignment.md)

---

Last Updated: January 2026
