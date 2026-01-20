# Company Management During Signup

## Overview

During signup, users must choose between **joining an existing company** or **creating a new company**. This decision determines their initial role and access level.

---

## Company Selection Screen

```
┌─────────────────────────────────────────────────────────────┐
│                    COMPANY SELECTION                         │
├─────────────────────────────────────────────────────────────┤
│  Are you joining an existing company or creating a new one? │
│                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  Existing Company    │  │  + Add New Company   │        │
│  │                      │  │                      │        │
│  │  Join your team's    │  │  Register your       │        │
│  │  organization        │  │  company and become  │        │
│  │                      │  │  the Owner           │        │
│  └──────────────────────┘  └──────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## Option 1: Join Existing Company

### User Journey

1. **Search for Company**
   - User enters at least **3 letters** of company name
   - System searches database after 3rd character
   - Returns **top 3 matching companies only**
   - Real-time search as user types

2. **Select Company**
   - User sees max 3 matches
   - Each shows: Name, City, State, Business Type
   - User selects one company from the list

3. **Submit Request**
   - Account created with "Pending User" role
   - Company admins notified
   - User waits for role assignment

### Role Assignment

**Initial Role:** `Pending User`
- **Capabilities:** None (read-only if any)
- **Status:** Waiting for admin approval
- **Access:** Limited or no access to features

**Admin Action Required:**
- Admin reviews join request
- Admin assigns appropriate role:
  - Driver
  - Dispatcher
  - Fleet Manager
  - Accountant
  - Maintenance Technician
  - etc.

**After Approval:**
- User receives role with full capabilities
- Can access all features permitted by role
- Becomes active member of organization

---

### Search Company API

**Endpoint:** `GET /api/auth/companies/search`

**Query Parameters:**
- `q` (required): Search term - **minimum 3 characters**
- `limit` (optional): Max results - **default and max is 3**

**Example:**
```
?q=ABC
&limit=3
```

**Validation Rules:**
- Minimum search length: 3 characters
- Maximum results returned: 3 companies
- Search is case-insensitive
- Matches company name from start or contains

**Response:**
```json
{
  "success": true,
  "companies": [
    {
      "company_id": "uuid-1",
      "company_name": "ABC Logistics Pvt Ltd",
      "city": "Bangalore",
      "state": "Karnataka",
      "business_type": "transportation"
    },
    {
      "company_id": "uuid-2",
      "company_name": "ABC Transport Solutions",
      "city": "Mumbai",
      "state": "Maharashtra",
      "business_type": "logistics"
    },
    {
      "company_id": "uuid-3",
      "company_name": "ABC Freight Services",
      "city": "Delhi",
      "state": "Delhi",
      "business_type": "freight"
    }
  ],
  "count": 3,
  "query": "ABC",
  "has_more": true
}
```

**Error Response (Less than 3 characters):**
```json
{
  "success": false,
  "error": "search_too_short",
  "message": "Please enter at least 3 characters to search",
  "min_length": 3
}
```

**Response (No matches):**
```json
{
  "success": true,
  "companies": [],
  "count": 0,
  "query": "XYZ",
  "message": "No companies found matching 'XYZ'"
}
```

---

## Option 2: Create New Company

### User Journey

1. **Fill Company Form**
   - Company information (required)
   - Legal details (optional - can be added later)
   - Contact information (required)
   - Business address (required)

2. **Validate Details**
   - GSTIN format validation (if provided)
   - PAN format validation (if provided)
   - GSTIN-PAN linkage check (if both provided)
   - All required fields validated

3. **Submit Registration**
   - Company created
   - User becomes Owner
   - Full access granted immediately

### Role Assignment

**Automatic Role:** `Owner`
- **Capabilities:** All (`*`)
- **Status:** Active immediately
- **Access:** Full control over company
- **Permissions:**
  - Create/manage users
  - Assign roles
  - Manage vehicles
  - View all data
  - Change settings
  - Billing access

---

### Company Registration Form

#### Section 1: Company Information

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Company Name | Text | ✅ Yes | 3-100 chars |
| Business Type | Dropdown | ✅ Yes | Predefined list |

**Business Type Options:**
- Transportation
- Logistics
- Freight
- Courier
- Fleet Services

---

#### Section 2: Legal Information (Optional)

| Field | Type | Required | Format |
|-------|------|----------|--------|
| GSTIN | Text | ❌ No | `29ABCDE1234F1Z5` (15 chars) |
| PAN Number | Text | ❌ No | `ABCDE1234F` (10 chars) |
| Registration Number | Text | ❌ No | Company registration no. |
| Registration Date | Date | ❌ No | DD/MM/YYYY |

**Note:** Legal information can be added later from company settings if not provided during registration.

**GSTIN Format:**
- 2 digits (state code)
- 5 letters (first 5 chars of PAN)
- 4 digits (registration number)
- 1 letter (entity type)
- 1 alphanumeric (default Z)
- 1 letter (checksum)

**Example:** `29ABCDE1234F1Z5`

**PAN Format:**
- 5 letters (first 3: AAA to ZZZ, 4th: P for person/C for company, 5th: first letter of name)
- 4 digits (sequential number)
- 1 letter (checksum)

**Example:** `ABCDE1234F`

---

#### Section 3: Contact Details

| Field | Type | Required |
|-------|------|----------|
| Business Email | Email | ✅ Yes |
| Business Phone | Phone | ✅ Yes |
| Address | Text (multiline) | ✅ Yes |
| City | Text | ✅ Yes |
| State | Text/Dropdown | ✅ Yes |
| Pincode | Text | ✅ Yes |
| Country | Text/Dropdown | ✅ Yes |

**Pincode:** 6 digits for India, varies by country

---

### Validation API

**Endpoint:** `POST /api/auth/companies/validate`

**Note:** This endpoint is only called if legal information is provided. All fields are optional.

**Request:**
```json
{
  "gstin": "29ABCDE1234F1Z5",
  "pan_number": "ABCDE1234F",
  "registration_number": "U63040KA2024PTC123456"
}
```

**Request (Minimal - Skip Validation):**
```json
{
  "gstin": null,
  "pan_number": null,
  "registration_number": null
}
```

**Success Response:**
```json
{
  "success": true,
  "valid": true,
  "message": "Company details validated successfully",
  "validation": {
    "gstin_valid": true,
    "pan_valid": true,
    "registration_number_valid": true,
    "gstin_status": "Active",
    "pan_linked": true
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "valid": false,
  "message": "Invalid company details",
  "errors": {
    "gstin": "Invalid GSTIN format",
    "pan_number": "PAN not linked to GSTIN",
    "registration_number": "Invalid format"
  }
}
```

---

## Complete API Examples

### Join Existing Company

```json
POST /api/auth/signup

{
  "full_name": "John Doe",
  "username": "johndoe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "auth_method": "email",
  "company_type": "existing",
  "company_id": "company-uuid-here",
  "terms_accepted": true
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "user-uuid",
  "company_id": "company-uuid",
  "company_name": "ABC Logistics Pvt Ltd",
  "role": "Pending User",
  "status": "pending_verification",
  "message": "Verification email sent. Admin will assign your role."
}
```

---

### Create New Company (With Legal Information)

```json
POST /api/auth/signup

{
  "full_name": "Jane Smith",
  "username": "janesmith",
  "email": "jane@newcompany.com",
  "phone": "+91-9876543210",
  "password": "SecurePass123!",
  "auth_method": "email",
  "company_type": "new",
  "company_details": {
    "company_name": "XYZ Transport Solutions",
    "business_type": "transportation",
    "gstin": "29ABCDE1234F1Z5",
    "pan_number": "ABCDE1234F",
    "registration_number": "U63040KA2024PTC123456",
    "registration_date": "2024-01-15",
    "business_email": "info@xyztransport.com",
    "business_phone": "+91-1234567890",
    "address": "123 Transport Lane, Business District",
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
  "user_id": "user-uuid",
  "company_id": "new-company-uuid",
  "company_name": "XYZ Transport Solutions",
  "role": "Owner",
  "capabilities": ["*"],
  "status": "pending_verification",
  "message": "Verification email sent. You are now the Owner."
}
```

---

### Create New Company (Without Legal Information)

```json
POST /api/auth/signup

{
  "full_name": "Jane Smith",
  "username": "janesmith",
  "email": "jane@newcompany.com",
  "phone": "+91-9876543210",
  "password": "SecurePass123!",
  "auth_method": "email",
  "company_type": "new",
  "company_details": {
    "company_name": "XYZ Transport Solutions",
    "business_type": "transportation",
    "gstin": null,
    "pan_number": null,
    "registration_number": null,
    "registration_date": null,
    "business_email": "info@xyztransport.com",
    "business_phone": "+91-1234567890",
    "address": "123 Transport Lane, Business District",
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
  "user_id": "user-uuid",
  "company_id": "new-company-uuid",
  "company_name": "XYZ Transport Solutions",
  "role": "Owner",
  "capabilities": ["*"],
  "status": "pending_verification",
  "message": "Verification email sent. You are now the Owner."
}
```

---

## Role & Access Comparison

| Aspect | Join Existing | Create New |
|--------|--------------|------------|
| **Initial Role** | Pending User | Owner |
| **Capabilities** | None (until assigned) | All (*) |
| **Activation** | After email verification + admin approval | After email verification |
| **Can Add Users** | ❌ No | ✅ Yes |
| **Can Manage Fleet** | ❌ No | ✅ Yes |
| **Can View All Data** | ❌ No | ✅ Yes |
| **Can Change Settings** | ❌ No | ✅ Yes |
| **Admin Approval Needed** | ✅ Yes | ❌ No |

---

## Admin Workflow (For Existing Company)

### When User Joins

1. **Notification Sent**
   - Email to all company admins
   - In-app notification
   - Shows user details: Name, Email, Phone

2. **Admin Reviews**
   - Views join request
   - Checks user information
   - Verifies legitimacy

3. **Admin Assigns Role**
   - Selects appropriate role
   - System grants capabilities
   - User notified of approval

4. **User Activated**
   - Role assigned
   - Full access granted
   - Can start using system

---

## Database Schema

### Organizations Table

```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    business_type VARCHAR(50),
    gstin VARCHAR(15) UNIQUE NULL,              -- Optional, can be NULL
    pan_number VARCHAR(10) NULL,                -- Optional, can be NULL
    registration_number VARCHAR(100) NULL,       -- Optional, can be NULL
    registration_date DATE NULL,                 -- Optional, can be NULL
    business_email VARCHAR(255),
    business_phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    country VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Note:** Legal information fields (GSTIN, PAN, registration details) are optional and can be added later via company settings.

### User-Company Link

```sql
CREATE TABLE user_organizations (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    organization_id UUID REFERENCES organizations(id),
    role_id UUID REFERENCES roles(id),
    status VARCHAR(20) DEFAULT 'pending',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    approved_by UUID REFERENCES users(id)
);
```

---

## Frontend Validation

**Note:** Validations are only applied if legal information fields are provided. Empty/null fields are allowed.

### GSTIN Validation (JavaScript/Dart)

```javascript
function validateGSTIN(gstin) {
  // Skip validation if field is empty
  if (!gstin || gstin.trim() === '') return true;

  const pattern = /^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$/;
  return pattern.test(gstin);
}
```

### PAN Validation

```javascript
function validatePAN(pan) {
  // Skip validation if field is empty
  if (!pan || pan.trim() === '') return true;

  const pattern = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
  return pattern.test(pan);
}
```

---

## Related Documents

- [Signup Flow - Email](02-signup-flow-email.md)
- [Signup Flow - Security Questions](03-signup-flow-security-questions.md)
- [Role Assignment](10-role-assignment.md)
- [API Endpoints](05-api-endpoints.md)

---

Last Updated: January 2026
