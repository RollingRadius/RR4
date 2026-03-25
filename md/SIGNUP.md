# User Signup & Registration Guide

## Overview

This document describes the user signup and registration process for the Fleet Management System. The system supports multiple registration flows depending on the user role and organizational requirements.

---

## Table of Contents

1. [Signup Types](#signup-types)
2. [Authentication Methods](#authentication-methods)
3. [Signup Flows](#signup-flows)
4. [User Onboarding Process](#user-onboarding-process)
5. [API Endpoints](#api-endpoints)
6. [Frontend Implementation](#frontend-implementation)
7. [Role Assignment](#role-assignment)
8. [Verification & Activation](#verification--activation)
9. [Security Questions](#security-questions)
10. [Password & Username Recovery](#password--username-recovery)
11. [Security Measures](#security-measures)
12. [Example Scenarios](#example-scenarios)

---

## Signup Types

The system supports three types of user registration:

### 1. Admin-Created Accounts (Primary Method)
- **Who:** Super Admin or authorized managers
- **Process:** Admin creates user account and assigns role
- **Use Case:** Creating accounts for employees, drivers, accountants, etc.
- **Activation:** Email invitation with password setup link

### 2. Organization Self-Registration
- **Who:** New organizations/fleet operators
- **Process:** Organization owner signs up with company details
- **Use Case:** New companies starting to use the platform
- **Activation:** Email verification and admin approval (optional)

### 3. Driver Self-Registration (Optional)
- **Who:** Individual drivers applying to join fleet
- **Process:** Driver submits application with credentials
- **Use Case:** Gig economy model, contract drivers
- **Activation:** Background check and manager approval

---

## Authentication Methods

The system supports **two authentication methods** during signup:

### Method 1: Email-Based Authentication (Recommended)

**When Email is Provided:**
- User provides email address during registration
- Email verification link sent to confirm ownership
- Password reset available via email
- Account recovery through email
- Two-factor authentication available (optional)

**Benefits:**
- Convenient password recovery
- Email notifications for account activity
- Secure verification process
- Industry-standard approach

---

### Method 2: Security Questions Authentication (Email-Optional)

**When Email is NOT Provided:**
- User must answer **3 security questions**
- Answers are **encrypted** and stored securely
- Questions are used for:
  - Username recovery
  - Password reset
  - Account verification
  - Identity confirmation

**Security Questions Categories:**
1. **Personal Information:** First pet name, mother's maiden name, birth city
2. **Memorable Events:** First car model, favorite teacher, childhood friend
3. **Preferences:** Favorite book, dream vacation, memorable year

**Security Measures:**
- Answers stored using AES-256 encryption
- Case-insensitive matching
- Trimmed whitespace for comparison
- Maximum 3 attempts for recovery
- Temporary lockout after failed attempts

**Example Questions:**
```
1. What is your mother's maiden name?
2. What was the name of your first pet?
3. In what city were you born?
4. What is your favorite book?
5. What was the model of your first car?
6. What is the name of your childhood best friend?
7. What is your father's middle name?
8. In what year did you graduate high school?
9. What is your dream vacation destination?
10. What was the name of your elementary school?
```

**Flow Comparison:**

| Feature | Email-Based | Security Questions |
|---------|-------------|-------------------|
| **Email Required** | Yes | No |
| **Password Recovery** | Email link | Security questions |
| **Username Recovery** | Email | Security questions |
| **Verification** | Email verification | Security questions |
| **Two-Factor Auth** | Available | Not available |
| **Account Recovery Time** | Immediate | Manual verification |
| **Privacy Level** | Medium | High (no email required) |

---

## Signup Flows

### Flow 1: Admin Creates User Account

**Most Common Flow for Internal Users**

```
┌─────────────────────────────────────────────────────────────┐
│                    ADMIN DASHBOARD                           │
│  (Super Admin / Fleet Manager / Operations Manager)         │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 1. Navigate to "Users" → "Add New User"
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    USER CREATION FORM                        │
├─────────────────────────────────────────────────────────────┤
│  • Full Name                                                 │
│  • Email Address                                             │
│  • Phone Number                                              │
│  • Employee ID (optional)                                    │
│  • Department                                                │
│  • Select Role:                                              │
│    [ ] Super Admin                                           │
│    [ ] Fleet Manager                                         │
│    [ ] Dispatcher                                            │
│    [✓] Driver                                                │
│    [ ] Accountant                                            │
│    [ ] Maintenance Manager                                   │
│    [ ] Compliance Officer                                    │
│    [ ] Operations Manager                                    │
│    [ ] Maintenance Technician                                │
│    [ ] Customer Service                                      │
│    [ ] Viewer/Analyst                                        │
│    [ ] Custom Role: [Select Custom Role ▼]                  │
│                                                              │
│  • Assign to Organization: [West Coast Fleet ▼]             │
│  • Send invitation email: [✓]                                │
│                                                              │
│  [Create User]  [Cancel]                                    │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 2. Admin clicks "Create User"
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND PROCESSING                        │
├─────────────────────────────────────────────────────────────┤
│  1. Validate email uniqueness                                │
│  2. Create user record (status: pending)                     │
│  3. Generate secure invitation token                         │
│  4. Assign role and capabilities                             │
│  5. Send invitation email                                    │
│  6. Log action in audit trail                                │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 3. System sends email
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    INVITATION EMAIL                          │
├─────────────────────────────────────────────────────────────┤
│  To: john.driver@example.com                                 │
│  Subject: Welcome to Fleet Management System                 │
│                                                              │
│  Hi John,                                                    │
│                                                              │
│  You have been invited to join West Coast Fleet as a        │
│  Driver. Click the link below to set up your password       │
│  and activate your account:                                  │
│                                                              │
│  [Set Up Your Account]                                       │
│  https://fleetapp.com/activate?token=abc123xyz              │
│                                                              │
│  This link expires in 48 hours.                              │
│                                                              │
│  Your assigned role: Driver                                  │
│  Capabilities: View trips, Update status, View vehicle info  │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 4. User clicks activation link
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    PASSWORD SETUP PAGE                       │
├─────────────────────────────────────────────────────────────┤
│  Welcome, John!                                              │
│                                                              │
│  Email: john.driver@example.com                              │
│  Role: Driver                                                │
│                                                              │
│  Set Your Password:                                          │
│  Password: [••••••••]                                        │
│  Confirm Password: [••••••••]                                │
│                                                              │
│  Password Requirements:                                      │
│  ✓ At least 8 characters                                     │
│  ✓ One uppercase letter                                      │
│  ✓ One lowercase letter                                      │
│  ✓ One number                                                │
│  ✓ One special character                                     │
│                                                              │
│  [✓] I agree to Terms of Service                            │
│                                                              │
│  [Activate Account]                                          │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 5. User sets password
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    ACCOUNT ACTIVATED                         │
├─────────────────────────────────────────────────────────────┤
│  ✓ Success! Your account is now active.                     │
│                                                              │
│  Redirecting to login...                                     │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 6. Redirect to login
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    USER DASHBOARD                            │
│  (User can now access system with assigned role)            │
└─────────────────────────────────────────────────────────────┘
```

---

### Flow 2: Organization Self-Registration

**For New Fleet Operators Starting Fresh**

```
┌─────────────────────────────────────────────────────────────┐
│                    PUBLIC LANDING PAGE                       │
│  https://fleetapp.com                                        │
└────────────┬────────────────────────────────────────────────┘
             │
             │ User clicks "Sign Up"
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    REGISTRATION TYPE SELECTION               │
├─────────────────────────────────────────────────────────────┤
│  How would you like to sign up?                             │
│                                                              │
│  [Organization Owner]  [Individual Driver]                  │
│                                                              │
│  • Organization Owner: Start managing your fleet            │
│  • Individual Driver: Apply to join existing fleet          │
└────────────┬────────────────────────────────────────────────┘
             │
             │ Selects "Organization Owner"
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    ORGANIZATION SIGNUP FORM                  │
├─────────────────────────────────────────────────────────────┤
│  STEP 1 of 3: Company Information                            │
│  ──────────────────────────────────────────                 │
│  Organization Name: [________________]                       │
│  Business Type: [Transportation ▼]                          │
│  Fleet Size: [10-50 vehicles ▼]                             │
│  Country: [United States ▼]                                 │
│  Business Registration Number: [____________]                │
│  Business Email: [________________]                          │
│  Phone: [________________]                                   │
│                                                              │
│  [Continue to Step 2]                                        │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    OWNER DETAILS FORM                        │
├─────────────────────────────────────────────────────────────┤
│  STEP 2 of 3: Your Information                              │
│  ──────────────────────────────────────────                 │
│  Full Name: [________________]                               │
│  Email: [________________]                                   │
│  Phone: [________________]                                   │
│  Job Title: [________________]                               │
│  Password: [••••••••]                                        │
│  Confirm Password: [••••••••]                                │
│                                                              │
│  [← Back]  [Continue to Step 3]                             │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    PLAN SELECTION                            │
├─────────────────────────────────────────────────────────────┤
│  STEP 3 of 3: Choose Your Plan                              │
│  ──────────────────────────────────────────                 │
│                                                              │
│  [Starter]      [Professional]      [Enterprise]            │
│  $49/month      $199/month           Custom Pricing         │
│  • 10 vehicles  • 50 vehicles       • Unlimited vehicles    │
│  • 5 users      • 20 users          • Unlimited users       │
│  • Basic track  • Advanced track    • Custom features       │
│                                                              │
│  [Select Plan]                                               │
│                                                              │
│  [✓] I agree to Terms of Service and Privacy Policy         │
│                                                              │
│  [← Back]  [Complete Registration]                          │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND PROCESSING                        │
├─────────────────────────────────────────────────────────────┤
│  1. Create organization record                               │
│  2. Create owner user (role: Super Admin)                    │
│  3. Initialize default settings                              │
│  4. Generate verification token                              │
│  5. Send verification email                                  │
│  6. Create subscription                                      │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    VERIFICATION EMAIL                        │
├─────────────────────────────────────────────────────────────┤
│  To: owner@company.com                                       │
│  Subject: Verify Your Fleet Management Account              │
│                                                              │
│  Hi [Name],                                                  │
│                                                              │
│  Thank you for registering! Click below to verify           │
│  your email and complete your registration:                 │
│                                                              │
│  [Verify Email]                                              │
│  https://fleetapp.com/verify?token=xyz789                   │
│                                                              │
│  Once verified, you can:                                     │
│  • Add vehicles to your fleet                                │
│  • Invite team members                                       │
│  • Start tracking in real-time                               │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING DASHBOARD                      │
│  (Owner can now set up fleet and invite users)              │
└─────────────────────────────────────────────────────────────┘
```

---

### Flow 3: Driver Self-Registration

**Optional: For Gig Economy / Contract Driver Model**

```
┌─────────────────────────────────────────────────────────────┐
│                    DRIVER APPLICATION FORM                   │
├─────────────────────────────────────────────────────────────┤
│  Apply to Become a Driver                                   │
│  ──────────────────────────────────────────                 │
│  Personal Information:                                       │
│  • Full Name: [________________]                             │
│  • Email: [________________]                                 │
│  • Phone: [________________]                                 │
│  • Date of Birth: [__/__/____]                              │
│  • Address: [________________]                               │
│                                                              │
│  Driver Information:                                         │
│  • License Number: [________________]                        │
│  • License State: [Select ▼]                                │
│  • License Expiry: [__/__/____]                             │
│  • Upload License Copy: [Choose File]                       │
│  • Years of Experience: [____]                               │
│  • Vehicle Type Experience: [✓] Truck [✓] Van [ ] Bus      │
│                                                              │
│  Background Check Consent:                                   │
│  [✓] I authorize background check                           │
│  [✓] I agree to Terms of Service                            │
│                                                              │
│  [Submit Application]                                        │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION SUBMITTED                     │
├─────────────────────────────────────────────────────────────┤
│  ✓ Application Received                                     │
│                                                              │
│  Thank you! Your application is under review.               │
│                                                              │
│  Next Steps:                                                 │
│  1. Background check (2-3 business days)                    │
│  2. Manager review                                           │
│  3. You'll receive email when approved                       │
│                                                              │
│  Application ID: #DR-2024-0123                              │
└────────────┬────────────────────────────────────────────────┘
             │
             │ (Manager Reviews Application)
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    APPROVAL NOTIFICATION                     │
├─────────────────────────────────────────────────────────────┤
│  Congratulations! You've been approved as a driver.         │
│                                                              │
│  Click below to set up your account:                         │
│  [Set Up Account]                                            │
└─────────────────────────────────────────────────────────────┘
```

---

### Flow 4: User Signup with Email (Standard)

```
┌─────────────────────────────────────────────────────────────┐
│                    SIGNUP PAGE                               │
├─────────────────────────────────────────────────────────────┤
│  Create Your Account                                         │
│  ──────────────────────────────────────────                 │
│  Full Name: [________________]                               │
│  Username: [________________]                                │
│  Email: [________________] (Optional)                        │
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
└────────────┬──────────────────────────┬─────────────────────┘
             │                          │
             │ Existing Company         │ Add New Company
             ▼                          ▼
┌──────────────────────────┐  ┌─────────────────────────────────────┐
│  SELECT COMPANY          │  │  NEW COMPANY REGISTRATION           │
├──────────────────────────┤  ├─────────────────────────────────────┤
│  Search for your company │  │  Company Information                │
│                          │  │  ──────────────────────────────     │
│  [Search companies...] 🔍│  │  Company Name: [________________]   │
│                          │  │  Business Type: [Transportation ▼]  │
│  Results:                │  │                                      │
│  • ABC Logistics         │  │  Legal Information:                 │
│  • XYZ Transport Co.     │  │  GSTIN: [__________________]        │
│  • Fleet Services Inc.   │  │  PAN Number: [__________]           │
│                          │  │  Registration Number: [__________]  │
│  [Select]                │  │  Registration Date: [__/__/____]    │
│                          │  │                                      │
│  Note: Admin will assign │  │  Contact Details:                   │
│  your role after joining │  │  Business Email: [________________] │
│                          │  │  Business Phone: [________________] │
│                          │  │  Address: [____________________]    │
│                          │  │  City: [____________]               │
│                          │  │  State: [____________]              │
│                          │  │  Pincode: [______]                  │
│                          │  │                                      │
│                          │  │  [Continue]                         │
└──────────┬───────────────┘  └────────────┬────────────────────────┘
           │                               │
           │ Email provided                │ Email provided
           ▼                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND PROCESSING                        │
├─────────────────────────────────────────────────────────────┤
│  IF EXISTING COMPANY:                                        │
│  1. Validate user data                                       │
│  2. Create user account (status: pending_verification)       │
│  3. Link user to selected company                            │
│  4. Assign default role: "Pending User" (no capabilities)    │
│  5. Hash password with bcrypt                                │
│  6. Generate email verification token (if email provided)    │
│  7. Send verification email or activate immediately          │
│  8. Notify company admins of new join request                │
│                                                              │
│  IF NEW COMPANY:                                             │
│  1. Validate user data and company data                      │
│  2. Verify GSTIN, PAN, Registration Number                   │
│  3. Create new organization record                           │
│  4. Create user account (status: pending_verification)       │
│  5. Link user to new company                                 │
│  6. Assign role: "Owner" (full capabilities for company)     │
│  7. Hash password with bcrypt                                │
│  8. Generate email verification token (if email provided)    │
│  9. Send verification email or activate immediately          │
│  10. Initialize default company settings                     │
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
│  Your account is now active.                                 │
│                                                              │
│  [Continue to Dashboard]                                     │
└─────────────────────────────────────────────────────────────┘
```

---

### Flow 5: User Signup WITHOUT Email (Security Questions)

```
┌─────────────────────────────────────────────────────────────┐
│                    SIGNUP PAGE                               │
├─────────────────────────────────────────────────────────────┤
│  Create Your Account                                         │
│  ──────────────────────────────────────────                 │
│  Full Name: [________________]                               │
│  Username: [________________]                                │
│  Email: [________________] (Optional) ← Left blank          │
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
│                    COMPANY SELECTION                         │
├─────────────────────────────────────────────────────────────┤
│  (Same as Flow 4 - Select Existing or Add New Company)      │
│  • Existing Company: Join as Pending User                   │
│  • New Company: Become Owner with full access               │
└────────────┬────────────────────────────────────────────────┘
             │
             │ No email provided
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY QUESTIONS PAGE                   │
├─────────────────────────────────────────────────────────────┤
│  Set Up Security Questions                                   │
│  ──────────────────────────────────────────                 │
│  Since you didn't provide an email, please answer these     │
│  security questions for account recovery:                    │
│                                                              │
│  Question 1:                                                 │
│  [Select a question ▼]                                      │
│  → What is your mother's maiden name?                       │
│  Answer: [________________]                                  │
│                                                              │
│  Question 2:                                                 │
│  [Select a question ▼]                                      │
│  → What was the name of your first pet?                     │
│  Answer: [________________]                                  │
│                                                              │
│  Question 3:                                                 │
│  [Select a question ▼]                                      │
│  → In what city were you born?                              │
│  Answer: [________________]                                  │
│                                                              │
│  ⚠️ Important: Remember these questions for account        │
│     recovery. Answers are encrypted and cannot be viewed.   │
│                                                              │
│  [Complete Registration]                                     │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND PROCESSING                        │
├─────────────────────────────────────────────────────────────┤
│  IF EXISTING COMPANY:                                        │
│  1. Validate user data                                       │
│  2. Hash password with bcrypt                                │
│  3. Encrypt security question answers (AES-256)              │
│  4. Store encrypted answers in database                      │
│  5. Create user account (status: active)                     │
│  6. Link user to selected company                            │
│  7. Assign default role: "Pending User" (no capabilities)    │
│  8. Store user with auth_method: 'security_questions'        │
│  9. Notify company admins of new join request                │
│  10. Log account creation                                    │
│                                                              │
│  IF NEW COMPANY:                                             │
│  1. Validate user data and company data                      │
│  2. Verify GSTIN, PAN, Registration Number                   │
│  3. Create new organization record                           │
│  4. Hash password with bcrypt                                │
│  5. Encrypt security question answers (AES-256)              │
│  6. Store encrypted answers in database                      │
│  7. Create user account (status: active)                     │
│  8. Link user to new company                                 │
│  9. Assign role: "Owner" (full capabilities for company)     │
│  10. Store user with auth_method: 'security_questions'       │
│  11. Initialize default company settings                     │
│  12. Log account creation                                    │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    REGISTRATION COMPLETE                     │
├─────────────────────────────────────────────────────────────┤
│  ✓ Account created successfully!                            │
│                                                              │
│  Your account is now active.                                 │
│  You can log in with your username and password.            │
│                                                              │
│  Note: Keep your security question answers safe.            │
│  They will be needed if you forget your password.           │
│                                                              │
│  [Continue to Login]                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## User Onboarding Process

### Post-Registration Steps

After account activation, users go through an onboarding process based on their role:

#### 1. Super Admin / Organization Owner
```
1. Welcome screen with quick tour
2. Set up organization profile
3. Add first vehicle
4. Invite team members
5. Configure notification preferences
6. Complete profile setup
```

#### 2. Fleet Manager / Operations Manager
```
1. Welcome screen
2. Review assigned vehicles and drivers
3. Set up personal dashboard preferences
4. Configure notification preferences
5. Watch tutorial videos (optional)
6. Complete profile setup
```

#### 3. Driver
```
1. Welcome screen
2. Download mobile app prompt
3. Review assigned vehicle (if any)
4. Watch safety guidelines video
5. Complete driver profile (emergency contact, etc.)
6. Accept driver agreement
```

#### 4. Other Roles
```
1. Welcome screen
2. Review role capabilities
3. Set up dashboard preferences
4. Watch role-specific tutorial
5. Complete profile setup
```

---

## API Endpoints

### Admin User Creation

**POST** `/api/auth/users/create`

**Request:**
```json
{
  "full_name": "John Driver",
  "email": "john.driver@example.com",
  "phone": "+1234567890",
  "employee_id": "EMP-001",
  "department": "Operations",
  "role_id": "role_driver_uuid",
  "organization_id": "org_uuid",
  "send_invitation": true,
  "additional_info": {
    "license_number": "DL123456",
    "hire_date": "2024-01-15"
  }
}
```

**Response:**
```json
{
  "user_id": "user_uuid",
  "email": "john.driver@example.com",
  "status": "pending_activation",
  "invitation_sent": true,
  "invitation_expires_at": "2024-01-17T10:00:00Z",
  "role": {
    "role_id": "role_driver_uuid",
    "role_name": "Driver",
    "capabilities": ["trip.view.own", "trip.status.update", ...]
  }
}
```

---

### Organization Self-Registration

**POST** `/api/auth/register/organization`

**Request:**
```json
{
  "organization": {
    "name": "Acme Transportation",
    "business_type": "transportation",
    "fleet_size": "10-50",
    "country": "USA",
    "registration_number": "BRN123456",
    "business_email": "info@acmetrans.com",
    "phone": "+1234567890"
  },
  "owner": {
    "full_name": "Jane Owner",
    "email": "jane@acmetrans.com",
    "phone": "+1234567890",
    "job_title": "CEO",
    "password": "SecurePass123!"
  },
  "plan": "professional",
  "terms_accepted": true
}
```

**Response:**
```json
{
  "organization_id": "org_uuid",
  "user_id": "user_uuid",
  "status": "pending_verification",
  "verification_email_sent": true,
  "message": "Please check your email to verify your account"
}
```

---

### Driver Self-Registration

**POST** `/api/auth/register/driver`

**Request:**
```json
{
  "personal_info": {
    "full_name": "Bob Driver",
    "email": "bob.driver@email.com",
    "phone": "+1234567890",
    "date_of_birth": "1990-05-15",
    "address": "123 Main St, City, State"
  },
  "driver_info": {
    "license_number": "DL987654",
    "license_state": "CA",
    "license_expiry": "2026-05-15",
    "license_document_url": "s3://uploads/licenses/dl_123.pdf",
    "years_experience": 5,
    "vehicle_types": ["truck", "van"]
  },
  "consent": {
    "background_check": true,
    "terms_accepted": true
  }
}
```

**Response:**
```json
{
  "application_id": "DR-2024-0123",
  "status": "under_review",
  "message": "Your application has been submitted successfully",
  "estimated_review_time": "2-3 business days"
}
```

---

### Email Verification

**POST** `/api/auth/verify-email`

**Request:**
```json
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

### Password Setup (Invited Users)

**POST** `/api/auth/activate`

**Request:**
```json
{
  "token": "invitation_token_from_email",
  "password": "SecurePass123!",
  "terms_accepted": true
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "user_uuid",
  "message": "Account activated successfully",
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": {
    "id": "user_uuid",
    "email": "john.driver@example.com",
    "full_name": "John Driver",
    "role": "Driver",
    "capabilities": [...]
  }
}
```

---

### Resend Invitation

**POST** `/api/auth/users/{user_id}/resend-invitation`

**Request:**
```json
{
  "email": "john.driver@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Invitation email sent successfully",
  "expires_at": "2024-01-17T10:00:00Z"
}
```

---

### User Signup with Email - Existing Company

**POST** `/api/auth/signup`

**Request:**
```json
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
  "message": "Verification email sent. Admin will assign your role after verification.",
  "verification_expires_at": "2024-01-16T10:00:00Z"
}
```

---

### User Signup with Email - New Company

**POST** `/api/auth/signup`

**Request:**
```json
{
  "full_name": "John Doe",
  "username": "johndoe123",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
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
    "address": "123 Transport Lane",
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
  "username": "johndoe123",
  "email": "john.doe@example.com",
  "status": "pending_verification",
  "auth_method": "email",
  "company_id": "new_company_uuid",
  "company_name": "XYZ Transport Solutions",
  "role": "Owner",
  "capabilities": ["*"],
  "message": "Verification email sent. You are now the Owner of XYZ Transport Solutions.",
  "verification_expires_at": "2024-01-16T10:00:00Z"
}
```

---

### User Signup WITHOUT Email - Existing Company

**POST** `/api/auth/signup`

**Request:**
```json
{
  "full_name": "Jane Smith",
  "username": "janesmith456",
  "email": null,
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "auth_method": "security_questions",
  "company_type": "existing",
  "company_id": "company_uuid",
  "security_questions": [
    {
      "question_id": "Q1",
      "question_text": "What is your mother's maiden name?",
      "answer": "Johnson"
    },
    {
      "question_id": "Q2",
      "question_text": "What was the name of your first pet?",
      "answer": "Fluffy"
    },
    {
      "question_id": "Q5",
      "question_text": "In what city were you born?",
      "answer": "Chicago"
    }
  ],
  "terms_accepted": true
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "user_uuid",
  "username": "janesmith456",
  "status": "active",
  "auth_method": "security_questions",
  "company_id": "company_uuid",
  "company_name": "ABC Logistics",
  "role": "Pending User",
  "message": "Account created successfully. Admin will assign your role.",
  "security_questions_count": 3
}
```

---

### User Signup WITHOUT Email - New Company

**POST** `/api/auth/signup`

**Request:**
```json
{
  "full_name": "Jane Smith",
  "username": "janesmith456",
  "email": null,
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "auth_method": "security_questions",
  "company_type": "new",
  "company_details": {
    "company_name": "ABC Transport Pvt Ltd",
    "business_type": "logistics",
    "gstin": "27ABCDE5678G1Z9",
    "pan_number": "ABCDE5678G",
    "registration_number": "U63040MH2024PTC567890",
    "registration_date": "2024-02-01",
    "business_email": "contact@abctransport.in",
    "business_phone": "+91-9876543210",
    "address": "456 Logistics Park",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "country": "India"
  },
  "security_questions": [
    {
      "question_id": "Q1",
      "question_text": "What is your mother's maiden name?",
      "answer": "Johnson"
    },
    {
      "question_id": "Q2",
      "question_text": "What was the name of your first pet?",
      "answer": "Fluffy"
    },
    {
      "question_id": "Q5",
      "question_text": "In what city were you born?",
      "answer": "Chicago"
    }
  ],
  "terms_accepted": true
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "user_uuid",
  "username": "janesmith456",
  "status": "active",
  "auth_method": "security_questions",
  "company_id": "new_company_uuid",
  "company_name": "ABC Transport Pvt Ltd",
  "role": "Owner",
  "capabilities": ["*"],
  "message": "Account created successfully. You are now the Owner of ABC Transport Pvt Ltd.",
  "security_questions_count": 3
}
```

---

### Search Companies (For Existing Company Selection)

**GET** `/api/auth/companies/search?q={search_term}`

**Query Parameters:**
- `q` - Search term (company name)
- `limit` - Optional, default 10

**Response:**
```json
{
  "success": true,
  "companies": [
    {
      "company_id": "company_uuid_1",
      "company_name": "ABC Logistics Pvt Ltd",
      "city": "Bangalore",
      "state": "Karnataka",
      "business_type": "transportation"
    },
    {
      "company_id": "company_uuid_2",
      "company_name": "ABC Transport Solutions",
      "city": "Mumbai",
      "state": "Maharashtra",
      "business_type": "logistics"
    }
  ],
  "count": 2
}
```

---

### Validate Company Details

**POST** `/api/auth/companies/validate`

**Request:**
```json
{
  "gstin": "29ABCDE1234F1Z5",
  "pan_number": "ABCDE1234F",
  "registration_number": "U63040KA2024PTC123456"
}
```

**Response (Valid):**
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

**Response (Invalid):**
```json
{
  "success": false,
  "valid": false,
  "message": "Invalid company details",
  "errors": {
    "gstin": "Invalid GSTIN format",
    "pan_number": "PAN not linked to GSTIN"
  }
}
```

---

### Get Available Security Questions

**GET** `/api/auth/security-questions`

**Response:**
```json
{
  "questions": [
    {
      "question_id": "Q1",
      "question_text": "What is your mother's maiden name?",
      "category": "personal"
    },
    {
      "question_id": "Q2",
      "question_text": "What was the name of your first pet?",
      "category": "personal"
    },
    {
      "question_id": "Q3",
      "question_text": "In what city were you born?",
      "category": "personal"
    },
    {
      "question_id": "Q4",
      "question_text": "What is your favorite book?",
      "category": "preferences"
    },
    {
      "question_id": "Q5",
      "question_text": "What was the model of your first car?",
      "category": "memorable_events"
    },
    {
      "question_id": "Q6",
      "question_text": "What is the name of your childhood best friend?",
      "category": "personal"
    },
    {
      "question_id": "Q7",
      "question_text": "What is your father's middle name?",
      "category": "personal"
    },
    {
      "question_id": "Q8",
      "question_text": "In what year did you graduate high school?",
      "category": "memorable_events"
    },
    {
      "question_id": "Q9",
      "question_text": "What is your dream vacation destination?",
      "category": "preferences"
    },
    {
      "question_id": "Q10",
      "question_text": "What was the name of your elementary school?",
      "category": "memorable_events"
    }
  ]
}
```

---

### Verify Security Questions (For Account Recovery)

**POST** `/api/auth/verify-security-questions`

**Request:**
```json
{
  "username": "janesmith456",
  "answers": [
    {
      "question_id": "Q1",
      "answer": "Johnson"
    },
    {
      "question_id": "Q2",
      "answer": "Fluffy"
    },
    {
      "question_id": "Q5",
      "answer": "Chicago"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "verified": true,
  "user_id": "user_uuid",
  "username": "janesmith456",
  "message": "Security questions verified successfully",
  "recovery_token": "temp_token_for_password_reset"
}
```

**Error Response (Failed Verification):**
```json
{
  "success": false,
  "verified": false,
  "attempts_remaining": 2,
  "message": "One or more answers are incorrect",
  "lockout_in_minutes": null
}
```

**Error Response (Locked Out):**
```json
{
  "success": false,
  "verified": false,
  "attempts_remaining": 0,
  "message": "Account temporarily locked due to multiple failed attempts",
  "lockout_in_minutes": 30
}
```

---

### Get User's Security Questions (For Recovery)

**POST** `/api/auth/get-security-questions`

**Request:**
```json
{
  "username": "janesmith456"
}
```

**Response:**
```json
{
  "success": true,
  "username": "janesmith456",
  "questions": [
    {
      "question_id": "Q1",
      "question_text": "What is your mother's maiden name?"
    },
    {
      "question_id": "Q2",
      "question_text": "What was the name of your first pet?"
    },
    {
      "question_id": "Q5",
      "question_text": "In what city were you born?"
    }
  ],
  "auth_method": "security_questions"
}
```

---

## Frontend Implementation

### Flutter - Admin User Creation Screen

```dart
// screens/admin/create_user_screen.dart

class CreateUserScreen extends StatefulWidget {
  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedRoleId;
  List<Role> _availableRoles = [];
  bool _sendInvitation = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    // Fetch available roles from API
    final roles = await RoleService.fetchRoles();
    setState(() {
      _availableRoles = roles;
    });
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.createUser(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        roleId: _selectedRoleId!,
        sendInvitation: _sendInvitation,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User created successfully! Invitation sent to ${_emailController.text}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New User'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              // Role Selection
              DropdownButtonFormField<String>(
                value: _selectedRoleId,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                ),
                items: _availableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role.name),
                        Text(
                          role.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoleId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Send Invitation Checkbox
              CheckboxListTile(
                title: Text('Send invitation email'),
                subtitle: Text('User will receive email to set up password'),
                value: _sendInvitation,
                onChanged: (value) {
                  setState(() {
                    _sendInvitation = value ?? true;
                  });
                },
              ),
              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Create User', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Flutter - Password Setup Screen (For Invited Users)

```dart
// screens/auth/password_setup_screen.dart

class PasswordSetupScreen extends StatefulWidget {
  final String invitationToken;

  const PasswordSetupScreen({required this.invitationToken});

  @override
  _PasswordSetupScreenState createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;

  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadInvitationDetails();
  }

  Future<void> _loadInvitationDetails() async {
    try {
      final info = await AuthService.getInvitationDetails(widget.invitationToken);
      setState(() {
        _userInfo = info;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid or expired invitation link')),
      );
    }
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
           RegExp(r'[A-Z]').hasMatch(password) &&
           RegExp(r'[a-z]').hasMatch(password) &&
           RegExp(r'[0-9]').hasMatch(password) &&
           RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  Future<void> _activateAccount() async {
    if (!_formKey.currentState!.validate() || !_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept terms of service')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.activateAccount(
        token: widget.invitationToken,
        password: _passwordController.text,
        termsAccepted: _termsAccepted,
      );

      // Navigate to login or dashboard
      Navigator.pushReplacementNamed(context, '/login');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account activated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userInfo == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Set Up Your Account')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_userInfo!['full_name']}!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Email: ${_userInfo!['email']}'),
              Text('Role: ${_userInfo!['role_name']}'),
              SizedBox(height: 24),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (!_validatePassword(value)) {
                    return 'Password does not meet requirements';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password Requirements
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Password Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      _buildRequirement('At least 8 characters', _passwordController.text.length >= 8),
                      _buildRequirement('One uppercase letter', RegExp(r'[A-Z]').hasMatch(_passwordController.text)),
                      _buildRequirement('One lowercase letter', RegExp(r'[a-z]').hasMatch(_passwordController.text)),
                      _buildRequirement('One number', RegExp(r'[0-9]').hasMatch(_passwordController.text)),
                      _buildRequirement('One special character', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Terms Checkbox
              CheckboxListTile(
                title: Text('I agree to Terms of Service'),
                value: _termsAccepted,
                onChanged: (value) => setState(() => _termsAccepted = value ?? false),
              ),
              SizedBox(height: 24),

              // Activate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _activateAccount,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Activate Account', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.cancel,
          color: met ? Colors.green : Colors.grey,
          size: 16,
        ),
        SizedBox(width: 8),
        Text(text, style: TextStyle(color: met ? Colors.green : Colors.grey)),
      ],
    );
  }
}
```

---

### Flutter - User Signup Screen (Email Optional)

```dart
// screens/auth/signup_screen.dart

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept terms of service')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email is provided
      bool hasEmail = _emailController.text.trim().isNotEmpty;

      if (hasEmail) {
        // Email-based signup
        await _signupWithEmail();
      } else {
        // Security questions based signup
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SecurityQuestionsScreen(
              fullName: _nameController.text,
              username: _usernameController.text,
              phone: _phoneController.text,
              password: _passwordController.text,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signupWithEmail() async {
    final response = await AuthService.signup(
      fullName: _nameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      authMethod: 'email',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification email sent! Please check your inbox.'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to verification pending screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmailVerificationPendingScreen(
          email: _emailController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Your Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.account_circle),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email (Optional)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  helperText: 'Leave blank to use security questions instead',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter valid email';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Terms Checkbox
              CheckboxListTile(
                title: Text('I agree to Terms of Service'),
                value: _termsAccepted,
                onChanged: (value) => setState(() => _termsAccepted = value ?? false),
              ),
              SizedBox(height: 24),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Flutter - Security Questions Screen

```dart
// screens/auth/security_questions_screen.dart

class SecurityQuestionsScreen extends StatefulWidget {
  final String fullName;
  final String username;
  final String phone;
  final String password;

  const SecurityQuestionsScreen({
    required this.fullName,
    required this.username,
    required this.phone,
    required this.password,
  });

  @override
  _SecurityQuestionsScreenState createState() => _SecurityQuestionsScreenState();
}

class _SecurityQuestionsScreenState extends State<SecurityQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();

  List<SecurityQuestion> _availableQuestions = [];
  List<SecurityQuestionAnswer> _selectedQuestions = [
    SecurityQuestionAnswer(),
    SecurityQuestionAnswer(),
    SecurityQuestionAnswer(),
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityQuestions();
  }

  Future<void> _loadSecurityQuestions() async {
    try {
      final questions = await AuthService.getSecurityQuestions();
      setState(() {
        _availableQuestions = questions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading questions: ${e.toString()}')),
      );
    }
  }

  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Check all questions are selected
    for (var i = 0; i < 3; i++) {
      if (_selectedQuestions[i].questionId == null ||
          _selectedQuestions[i].answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please answer all 3 security questions')),
        );
        return;
      }
    }

    // Check no duplicate questions
    Set<String?> questionIds = _selectedQuestions.map((q) => q.questionId).toSet();
    if (questionIds.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select different questions')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signup(
        fullName: widget.fullName,
        username: widget.username,
        email: null,
        phone: widget.phone,
        password: widget.password,
        authMethod: 'security_questions',
        securityQuestions: _selectedQuestions,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Up Security Questions')),
      body: _availableQuestions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, size: 40, color: Colors.blue),
                            SizedBox(height: 8),
                            Text(
                              'Since you didn\'t provide an email, please answer these security questions for account recovery.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Question 1
                    Text('Question 1', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select a question',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableQuestions.map((q) {
                        return DropdownMenuItem(
                          value: q.questionId,
                          child: Text(q.questionText, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuestions[0].questionId = value;
                          _selectedQuestions[0].questionText =
                            _availableQuestions.firstWhere((q) => q.questionId == value).questionText;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Answer',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _selectedQuestions[0].answer = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an answer';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Question 2
                    Text('Question 2', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select a question',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableQuestions.map((q) {
                        return DropdownMenuItem(
                          value: q.questionId,
                          child: Text(q.questionText, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuestions[1].questionId = value;
                          _selectedQuestions[1].questionText =
                            _availableQuestions.firstWhere((q) => q.questionId == value).questionText;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Answer',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _selectedQuestions[1].answer = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an answer';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Question 3
                    Text('Question 3', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select a question',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableQuestions.map((q) {
                        return DropdownMenuItem(
                          value: q.questionId,
                          child: Text(q.questionText, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuestions[2].questionId = value;
                          _selectedQuestions[2].questionText =
                            _availableQuestions.firstWhere((q) => q.questionId == value).questionText;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Answer',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _selectedQuestions[2].answer = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an answer';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Warning Card
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Important: Remember these questions for account recovery. Answers are encrypted and cannot be viewed.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Complete Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeSignup,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Complete Registration', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Models
class SecurityQuestion {
  final String questionId;
  final String questionText;
  final String category;

  SecurityQuestion({
    required this.questionId,
    required this.questionText,
    required this.category,
  });
}

class SecurityQuestionAnswer {
  String? questionId;
  String? questionText;
  String answer = '';
}
```

---

### Flutter - Company Selection Screen

```dart
// screens/auth/company_selection_screen.dart

class CompanySelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CompanySelectionScreen({required this.userData});

  @override
  _CompanySelectionScreenState createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  String _selectedType = ''; // 'existing' or 'new'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Company Selection')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Are you joining an existing company or creating a new one?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Existing Company Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchCompanyScreen(
                      userData: widget.userData,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: Container(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.business, size: 60, color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'Existing Company',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Join your team\'s organization',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // New Company Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewCompanyRegistrationScreen(
                      userData: widget.userData,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: Container(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.add_business, size: 60, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        '+ Add New Company',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Register your company and become the Owner',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Flutter - Search Company Screen

```dart
// screens/auth/search_company_screen.dart

class SearchCompanyScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SearchCompanyScreen({required this.userData});

  @override
  _SearchCompanyScreenState createState() => _SearchCompanyScreenState();
}

class _SearchCompanyScreenState extends State<SearchCompanyScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _selectedCompanyId;

  Future<void> _searchCompanies(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final companies = await AuthService.searchCompanies(query);
      setState(() {
        _companies = companies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCompany() async {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a company')),
      );
      return;
    }

    // Proceed with signup
    try {
      await AuthService.signup(
        fullName: widget.userData['full_name'],
        username: widget.userData['username'],
        email: widget.userData['email'],
        phone: widget.userData['phone'],
        password: widget.userData['password'],
        authMethod: widget.userData['auth_method'],
        companyType: 'existing',
        companyId: _selectedCompanyId,
        securityQuestions: widget.userData['security_questions'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created! Waiting for admin approval.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Company')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for your company',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchCompanies(_searchController.text),
                ),
              ),
              onSubmitted: _searchCompanies,
            ),
            SizedBox(height: 16),

            // Note
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Admin will assign your role after joining',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Results
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _companies.isEmpty
                      ? Center(
                          child: Text(
                            'Search for companies to join',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _companies.length,
                          itemBuilder: (context, index) {
                            final company = _companies[index];
                            return Card(
                              child: RadioListTile<String>(
                                title: Text(company.companyName),
                                subtitle: Text('${company.city}, ${company.state}'),
                                value: company.companyId,
                                groupValue: _selectedCompanyId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCompanyId = value;
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),

            // Select Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCompanyId == null ? null : _selectCompany,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Select Company', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Company {
  final String companyId;
  final String companyName;
  final String city;
  final String state;
  final String businessType;

  Company({
    required this.companyId,
    required this.companyName,
    required this.city,
    required this.state,
    required this.businessType,
  });
}
```

---

### Flutter - New Company Registration Screen

```dart
// screens/auth/new_company_registration_screen.dart

class NewCompanyRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NewCompanyRegistrationScreen({required this.userData});

  @override
  _NewCompanyRegistrationScreenState createState() => _NewCompanyRegistrationScreenState();
}

class _NewCompanyRegistrationScreenState extends State<NewCompanyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _businessEmailController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String? _businessType;
  DateTime? _registrationDate;
  bool _isLoading = false;

  Future<void> _validateAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate company details
      final validation = await AuthService.validateCompanyDetails(
        gstin: _gstinController.text,
        panNumber: _panController.text,
        registrationNumber: _registrationNumberController.text,
      );

      if (!validation['valid']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid company details: ${validation['message']}')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Submit signup with company details
      await AuthService.signup(
        fullName: widget.userData['full_name'],
        username: widget.userData['username'],
        email: widget.userData['email'],
        phone: widget.userData['phone'],
        password: widget.userData['password'],
        authMethod: widget.userData['auth_method'],
        companyType: 'new',
        companyDetails: {
          'company_name': _companyNameController.text,
          'business_type': _businessType,
          'gstin': _gstinController.text,
          'pan_number': _panController.text,
          'registration_number': _registrationNumberController.text,
          'registration_date': _registrationDate?.toIso8601String(),
          'business_email': _businessEmailController.text,
          'business_phone': _businessPhoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'pincode': _pincodeController.text,
          'country': 'India',
        },
        securityQuestions: widget.userData['security_questions'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Company registered! You are now the Owner.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register New Company')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Information Section
              Text(
                'Company Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _companyNameController,
                decoration: InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _businessType,
                decoration: InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                ),
                items: ['transportation', 'logistics', 'freight', 'courier']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _businessType = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              SizedBox(height: 24),

              // Legal Information Section
              Text(
                'Legal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _gstinController,
                decoration: InputDecoration(
                  labelText: 'GSTIN',
                  hintText: '29ABCDE1234F1Z5',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$')
                      .hasMatch(value!)) {
                    return 'Invalid GSTIN format';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _panController,
                decoration: InputDecoration(
                  labelText: 'PAN Number',
                  hintText: 'ABCDE1234F',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value!)) {
                    return 'Invalid PAN format';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _registrationNumberController,
                decoration: InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 24),

              // Contact Details Section
              Text(
                'Contact Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _businessEmailController,
                decoration: InputDecoration(
                  labelText: 'Business Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _businessPhoneController,
                decoration: InputDecoration(
                  labelText: 'Business Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _pincodeController,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!RegExp(r'^\d{6}$').hasMatch(value!)) {
                    return 'Invalid pincode';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Register Company', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Role Assignment

### How Roles Are Assigned During Signup

#### 1. Admin-Created Users
- Admin explicitly selects role during user creation
- Role can be:
  - One of 11 predefined roles
  - A custom role created by admin
- User receives role immediately upon creation
- Capabilities are automatically assigned based on role

#### 2. Organization Owner (Self-Registration)
- Automatically assigned **Super Admin** role for their organization
- Full capabilities within their organization
- Cannot access other organizations (multi-tenant isolation)

#### 3. Self-Registered Drivers
- Initially assigned **Pending Driver** status (no capabilities)
- After approval, assigned **Driver** role
- Limited capabilities appropriate for field operations

### Role Assignment Rules

1. **One Role Per User:** Each user has exactly one primary role
2. **Role Changes:** Only Super Admin or authorized managers can change roles
3. **Capability Inheritance:** Users automatically get all capabilities from their assigned role
4. **Custom Constraints:** Additional restrictions can be added (region, department, etc.)

---

## Verification & Activation

### Email Verification Process

**Purpose:** Confirm email ownership

```python
# Backend: Generate verification token
def generate_verification_token(user_id: str) -> str:
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(hours=48)

    # Store in database
    db.execute(
        "INSERT INTO email_verifications (user_id, token, expires_at) VALUES (?, ?, ?)",
        (user_id, token, expires_at)
    )

    return token

# Verification endpoint
@router.post("/auth/verify-email")
async def verify_email(token: str, db: Session = Depends(get_db)):
    verification = db.query(EmailVerification).filter_by(token=token).first()

    if not verification:
        raise HTTPException(status_code=400, detail="Invalid verification token")

    if verification.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Verification token expired")

    # Update user status
    user = db.query(User).get(verification.user_id)
    user.email_verified = True
    user.status = "active"

    db.commit()

    return {"success": True, "message": "Email verified successfully"}
```

### Account Activation Process

**Purpose:** Set up password for invited users

```python
@router.post("/auth/activate")
async def activate_account(
    token: str,
    password: str,
    terms_accepted: bool,
    db: Session = Depends(get_db)
):
    # Validate invitation token
    invitation = db.query(Invitation).filter_by(token=token).first()

    if not invitation or invitation.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invalid or expired invitation")

    if not terms_accepted:
        raise HTTPException(status_code=400, detail="Must accept terms of service")

    # Validate password strength
    if not validate_password_strength(password):
        raise HTTPException(status_code=400, detail="Password does not meet requirements")

    # Update user
    user = db.query(User).get(invitation.user_id)
    user.password_hash = hash_password(password)
    user.status = "active"
    user.activated_at = datetime.utcnow()

    # Delete invitation token
    db.delete(invitation)
    db.commit()

    # Generate access tokens
    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    return {
        "success": True,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user": user.to_dict()
    }
```

---

## Security Measures

### 1. Password Security
```python
# Password Requirements
PASSWORD_MIN_LENGTH = 8
PASSWORD_REQUIREMENTS = {
    "uppercase": r"[A-Z]",
    "lowercase": r"[a-z]",
    "digit": r"[0-9]",
    "special": r"[!@#$%^&*(),.?\":{}|<>]"
}

def validate_password_strength(password: str) -> bool:
    if len(password) < PASSWORD_MIN_LENGTH:
        return False

    for requirement, pattern in PASSWORD_REQUIREMENTS.items():
        if not re.search(pattern, password):
            return False

    return True

# Password Hashing (bcrypt)
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
```

### 2. Token Security
```python
# Invitation tokens expire in 48 hours
INVITATION_TOKEN_EXPIRY = 48  # hours

# Verification tokens expire in 48 hours
VERIFICATION_TOKEN_EXPIRY = 48  # hours

# Tokens are cryptographically secure
import secrets

def generate_secure_token() -> str:
    return secrets.token_urlsafe(32)  # 32 bytes = 256 bits
```

### 3. Email Uniqueness
```python
# Ensure email is unique across system
@router.post("/auth/users/create")
async def create_user(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if email already exists
    existing_user = db.query(User).filter_by(email=user_data.email).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    # Create user
    ...
```

### 4. Rate Limiting
```python
# Prevent abuse of registration endpoints
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/auth/register/organization")
@limiter.limit("5/hour")  # Max 5 registrations per hour per IP
async def register_organization(...):
    ...

@router.post("/auth/verify-email")
@limiter.limit("10/hour")  # Max 10 verification attempts per hour
async def verify_email(...):
    ...
```

### 5. CAPTCHA (Optional)
```python
# Add CAPTCHA for public registration
from recaptcha import verify_recaptcha

@router.post("/auth/register/organization")
async def register_organization(
    data: OrganizationRegister,
    captcha_token: str
):
    # Verify CAPTCHA
    if not verify_recaptcha(captcha_token):
        raise HTTPException(status_code=400, detail="Invalid CAPTCHA")

    # Process registration
    ...
```

### 6. Audit Logging
```python
# Log all signup activities
def log_signup_activity(
    action: str,
    user_id: str,
    ip_address: str,
    user_agent: str,
    db: Session
):
    audit_log = AuditLog(
        action=action,
        user_id=user_id,
        ip_address=ip_address,
        user_agent=user_agent,
        timestamp=datetime.utcnow()
    )
    db.add(audit_log)
    db.commit()

# Example usage
log_signup_activity(
    action="user_created",
    user_id=new_user.id,
    ip_address=request.client.host,
    user_agent=request.headers.get("user-agent"),
    db=db
)
```

---

### 7. Security Question Encryption

```python
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2
import base64
import os

# Generate encryption key from master secret
def generate_encryption_key(master_secret: str, salt: bytes) -> bytes:
    kdf = PBKDF2(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(master_secret.encode()))
    return key

# Encrypt security answer
def encrypt_answer(answer: str, user_salt: bytes) -> str:
    # Normalize answer: lowercase and trim
    normalized_answer = answer.strip().lower()

    # Get encryption key
    master_secret = os.getenv("ENCRYPTION_MASTER_KEY")
    key = generate_encryption_key(master_secret, user_salt)

    # Encrypt using AES-256 (Fernet)
    f = Fernet(key)
    encrypted = f.encrypt(normalized_answer.encode())

    return base64.b64encode(encrypted).decode()

# Verify security answer
def verify_answer(provided_answer: str, encrypted_answer: str, user_salt: bytes) -> bool:
    try:
        # Normalize provided answer
        normalized_provided = provided_answer.strip().lower()

        # Decrypt stored answer
        master_secret = os.getenv("ENCRYPTION_MASTER_KEY")
        key = generate_encryption_key(master_secret, user_salt)
        f = Fernet(key)

        encrypted_bytes = base64.b64decode(encrypted_answer.encode())
        decrypted = f.decrypt(encrypted_bytes).decode()

        # Compare
        return normalized_provided == decrypted
    except Exception:
        return False
```

**Encryption Details:**
- Algorithm: AES-256 (via Fernet)
- Key Derivation: PBKDF2 with SHA-256
- Iterations: 100,000
- Unique salt per user
- Answer normalization: lowercase, trimmed whitespace
- Master encryption key stored in environment variables

---

## Security Questions

### Database Schema

```sql
-- Security Questions Table
CREATE TABLE security_questions (
    question_id VARCHAR(10) PRIMARY KEY,
    question_text VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Security Answers Table
CREATE TABLE user_security_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id VARCHAR(10) NOT NULL REFERENCES security_questions(question_id),
    encrypted_answer TEXT NOT NULL,
    salt BYTEA NOT NULL,  -- Unique salt per user for encryption
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, question_id)
);

-- Security Question Attempt Tracking
CREATE TABLE security_question_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    attempt_type VARCHAR(20) NOT NULL,  -- 'recovery', 'verification'
    success BOOLEAN NOT NULL,
    ip_address INET,
    user_agent TEXT,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_attempts ON security_question_attempts(user_id, attempted_at);
```

### Verification Service

```python
from datetime import datetime, timedelta
from typing import List, Dict, Optional

class SecurityQuestionService:
    MAX_ATTEMPTS = 3
    LOCKOUT_DURATION_MINUTES = 30

    @staticmethod
    async def verify_security_answers(
        user_id: str,
        answers: List[Dict[str, str]],
        db: Session,
        ip_address: str,
        user_agent: str
    ) -> Dict:
        """Verify user's security question answers"""

        # Check if user is locked out
        lockout_until = await SecurityQuestionService.check_lockout(user_id, db)
        if lockout_until:
            minutes_remaining = int((lockout_until - datetime.utcnow()).total_seconds() / 60)
            return {
                "success": False,
                "verified": False,
                "message": "Account temporarily locked",
                "lockout_in_minutes": minutes_remaining,
                "attempts_remaining": 0
            }

        # Get user's stored answers
        stored_answers = db.query(UserSecurityAnswer).filter_by(
            user_id=user_id
        ).all()

        if len(stored_answers) != 3:
            raise HTTPException(status_code=400, detail="Security questions not configured")

        # Verify each answer
        correct_count = 0
        for provided in answers:
            question_id = provided["question_id"]
            provided_answer = provided["answer"]

            # Find matching stored answer
            stored = next(
                (a for a in stored_answers if a.question_id == question_id),
                None
            )

            if stored and verify_answer(provided_answer, stored.encrypted_answer, stored.salt):
                correct_count += 1

        # All answers must be correct
        verified = correct_count == 3

        # Log attempt
        await SecurityQuestionService.log_attempt(
            user_id=user_id,
            attempt_type="recovery",
            success=verified,
            ip_address=ip_address,
            user_agent=user_agent,
            db=db
        )

        if verified:
            # Generate recovery token
            recovery_token = secrets.token_urlsafe(32)
            expires_at = datetime.utcnow() + timedelta(minutes=15)

            # Store recovery token
            db.execute(
                "INSERT INTO password_recovery_tokens (user_id, token, expires_at, method) VALUES (?, ?, ?, ?)",
                (user_id, recovery_token, expires_at, "security_questions")
            )
            db.commit()

            user = db.query(User).get(user_id)
            return {
                "success": True,
                "verified": True,
                "user_id": user_id,
                "username": user.username,
                "recovery_token": recovery_token,
                "message": "Security questions verified successfully"
            }
        else:
            # Check remaining attempts
            recent_attempts = await SecurityQuestionService.get_recent_failed_attempts(
                user_id, db
            )

            attempts_remaining = SecurityQuestionService.MAX_ATTEMPTS - recent_attempts

            if attempts_remaining <= 0:
                return {
                    "success": False,
                    "verified": False,
                    "attempts_remaining": 0,
                    "message": "Account locked due to multiple failed attempts",
                    "lockout_in_minutes": SecurityQuestionService.LOCKOUT_DURATION_MINUTES
                }

            return {
                "success": False,
                "verified": False,
                "attempts_remaining": attempts_remaining,
                "message": "One or more answers are incorrect"
            }

    @staticmethod
    async def get_recent_failed_attempts(user_id: str, db: Session) -> int:
        """Count failed attempts in the last 30 minutes"""
        since = datetime.utcnow() - timedelta(minutes=30)
        count = db.query(SecurityQuestionAttempt).filter(
            SecurityQuestionAttempt.user_id == user_id,
            SecurityQuestionAttempt.success == False,
            SecurityQuestionAttempt.attempted_at >= since
        ).count()
        return count

    @staticmethod
    async def check_lockout(user_id: str, db: Session) -> Optional[datetime]:
        """Check if user is locked out"""
        since = datetime.utcnow() - timedelta(
            minutes=SecurityQuestionService.LOCKOUT_DURATION_MINUTES
        )

        failed_count = db.query(SecurityQuestionAttempt).filter(
            SecurityQuestionAttempt.user_id == user_id,
            SecurityQuestionAttempt.success == False,
            SecurityQuestionAttempt.attempted_at >= since
        ).count()

        if failed_count >= SecurityQuestionService.MAX_ATTEMPTS:
            # Get the 3rd failed attempt time
            third_attempt = db.query(SecurityQuestionAttempt).filter(
                SecurityQuestionAttempt.user_id == user_id,
                SecurityQuestionAttempt.success == False,
                SecurityQuestionAttempt.attempted_at >= since
            ).order_by(SecurityQuestionAttempt.attempted_at.desc()).offset(2).first()

            if third_attempt:
                lockout_until = third_attempt.attempted_at + timedelta(
                    minutes=SecurityQuestionService.LOCKOUT_DURATION_MINUTES
                )
                if lockout_until > datetime.utcnow():
                    return lockout_until

        return None

    @staticmethod
    async def log_attempt(
        user_id: str,
        attempt_type: str,
        success: bool,
        ip_address: str,
        user_agent: str,
        db: Session
    ):
        """Log security question attempt"""
        attempt = SecurityQuestionAttempt(
            user_id=user_id,
            attempt_type=attempt_type,
            success=success,
            ip_address=ip_address,
            user_agent=user_agent
        )
        db.add(attempt)
        db.commit()
```

---

## Password & Username Recovery

### Password Recovery - Email Method

**Standard Email Recovery Flow:**

1. User clicks "Forgot Password"
2. Enters email address
3. Receives password reset link via email
4. Clicks link and sets new password

**API Endpoint:**
```python
@router.post("/auth/forgot-password")
async def forgot_password(email: str, db: Session = Depends(get_db)):
    user = db.query(User).filter_by(email=email, auth_method='email').first()

    if not user:
        # Return success even if user not found (security best practice)
        return {"success": True, "message": "If email exists, reset link sent"}

    # Generate reset token
    reset_token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(hours=1)

    # Store token
    db.execute(
        "INSERT INTO password_recovery_tokens (user_id, token, expires_at, method) VALUES (?, ?, ?, ?)",
        (user.id, reset_token, expires_at, "email")
    )
    db.commit()

    # Send email
    send_password_reset_email(user.email, reset_token)

    return {"success": True, "message": "Password reset email sent"}
```

---

### Password Recovery - Security Questions Method

**Recovery Flow Diagram:**

```
┌─────────────────────────────────────────────────────────────┐
│                    FORGOT PASSWORD PAGE                      │
├─────────────────────────────────────────────────────────────┤
│  Enter your username to recover your account                │
│                                                              │
│  Username: [________________]                                │
│                                                              │
│  [Continue]                                                  │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    VERIFY IDENTITY                           │
├─────────────────────────────────────────────────────────────┤
│  Answer your security questions to verify your identity     │
│                                                              │
│  Question 1: What is your mother's maiden name?             │
│  Answer: [________________]                                  │
│                                                              │
│  Question 2: What was the name of your first pet?           │
│  Answer: [________________]                                  │
│                                                              │
│  Question 3: In what city were you born?                    │
│  Answer: [________________]                                  │
│                                                              │
│  ⚠️ 3 attempts remaining                                    │
│                                                              │
│  [Verify]                                                    │
└────────────┬────────────────────────────────────────────────┘
             │
             │ All answers correct
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    RESET PASSWORD                            │
├─────────────────────────────────────────────────────────────┤
│  ✓ Identity verified!                                       │
│                                                              │
│  Set your new password:                                      │
│  New Password: [••••••••]                                    │
│  Confirm Password: [••••••••]                                │
│                                                              │
│  [Reset Password]                                            │
└─────────────────────────────────────────────────────────────┘
```

**API Endpoints:**
```python
# Step 1: Get user's security questions
@router.post("/auth/forgot-password/security-questions")
async def get_security_questions_for_recovery(
    username: str,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter_by(
        username=username,
        auth_method='security_questions'
    ).first()

    if not user:
        return {
            "success": False,
            "message": "User not found"
        }

    questions = db.query(UserSecurityAnswer).filter_by(
        user_id=user.id
    ).join(SecurityQuestion).all()

    if len(questions) != 3:
        return {
            "success": False,
            "message": "Security questions not configured"
        }

    return {
        "success": True,
        "user_id": user.id,
        "questions": [
            {
                "question_id": q.question_id,
                "question_text": q.security_question.question_text
            }
            for q in questions
        ]
    }

# Step 2: Verify answers and reset password
@router.post("/auth/reset-password/security-questions")
async def reset_password_with_security_questions(
    user_id: str,
    answers: List[Dict[str, str]],
    new_password: str,
    request: Request,
    db: Session = Depends(get_db)
):
    # Verify security questions
    verification = await SecurityQuestionService.verify_security_answers(
        user_id=user_id,
        answers=answers,
        db=db,
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    if not verification["verified"]:
        return verification

    # Validate new password
    if not validate_password_strength(new_password):
        return {
            "success": False,
            "message": "Password does not meet requirements"
        }

    # Update password
    user = db.query(User).get(user_id)
    user.password_hash = hash_password(new_password)
    user.updated_at = datetime.utcnow()
    db.commit()

    # Log password change
    log_audit_activity(
        action="password_reset_security_questions",
        user_id=user_id,
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent"),
        db=db
    )

    return {
        "success": True,
        "message": "Password reset successfully"
    }
```

---

### Username Recovery

**For Email-Based Accounts:**
```python
@router.post("/auth/forgot-username")
async def forgot_username(email: str, db: Session = Depends(get_db)):
    user = db.query(User).filter_by(email=email).first()

    if user:
        send_username_reminder_email(user.email, user.username)

    # Return success even if not found (security)
    return {
        "success": True,
        "message": "If email exists, username reminder sent"
    }
```

**For Security Questions Accounts:**
```python
@router.post("/auth/recover-username")
async def recover_username_with_security_questions(
    full_name: str,
    phone: str,
    db: Session = Depends(get_db)
):
    # Find user by name and phone
    user = db.query(User).filter_by(
        full_name=full_name,
        phone=phone,
        auth_method='security_questions'
    ).first()

    if not user:
        return {
            "success": False,
            "message": "No account found with provided information"
        }

    # Return security questions
    questions = db.query(UserSecurityAnswer).filter_by(
        user_id=user.id
    ).join(SecurityQuestion).all()

    return {
        "success": True,
        "user_id": user.id,
        "questions": [
            {
                "question_id": q.question_id,
                "question_text": q.security_question.question_text
            }
            for q in questions
        ]
    }

# After verifying security questions
@router.post("/auth/reveal-username")
async def reveal_username(
    user_id: str,
    answers: List[Dict],
    request: Request,
    db: Session = Depends(get_db)
):
    # Verify security questions
    result = await SecurityQuestionService.verify_security_answers(
        user_id=user_id,
        answers=answers,
        db=db,
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )

    if result["verified"]:
        user = db.query(User).get(user_id)
        return {
            "success": True,
            "username": user.username,
            "message": "Your username has been recovered"
        }
    else:
        return result
```

---

## Example Scenarios

### Scenario 1: Fleet Manager Creates Driver Account

**Story:** Fleet manager Sarah needs to onboard a new driver, Mike.

**Steps:**
1. Sarah logs into admin dashboard (role: Fleet Manager)
2. Navigates to Users → Add New User
3. Fills in Mike's details:
   - Name: Mike Johnson
   - Email: mike.j@company.com
   - Phone: +1-555-0123
   - Role: Driver
   - Department: East Coast Operations
4. Checks "Send invitation email"
5. Clicks "Create User"
6. System creates user with status "pending_activation"
7. Mike receives invitation email
8. Mike clicks link, sets password
9. Account activated with Driver role
10. Mike can now log in and see assigned trips

**Capabilities Mike Gets:**
- `trip.view.own` - View his assigned trips
- `trip.status.update` - Update trip status
- `tracking.view.own` - Share his location
- `vehicle.view` - View assigned vehicle info
- `maintenance.workorder.view` - View maintenance tasks

---

### Scenario 2: New Company Registers

**Story:** ABC Logistics wants to start using the platform.

**Steps:**
1. Visit fleetapp.com
2. Click "Sign Up"
3. Select "Organization Owner"
4. Fill in company details:
   - Name: ABC Logistics
   - Fleet size: 25 vehicles
   - Business email: admin@abclogistics.com
5. Fill in owner details:
   - Name: Alice Admin
   - Email: alice@abclogistics.com
   - Password: (sets password)
6. Select "Professional" plan
7. Accept terms, complete registration
8. Receives verification email
9. Clicks verification link
10. Account activated with Super Admin role
11. Redirected to onboarding wizard:
    - Add first vehicle
    - Invite team members
    - Configure settings

**Capabilities Alice Gets:**
- All capabilities (Super Admin role)
- Full control over ABC Logistics organization
- Can create users, assign roles, manage fleet

---

### Scenario 3: Driver Self-Registration (Gig Economy Model)

**Story:** Tom wants to become a contract driver.

**Steps:**
1. Visit fleetapp.com/apply-driver
2. Fills in application:
   - Personal info: Name, email, phone, address
   - License info: License number, state, expiry date
   - Uploads license copy (PDF)
   - Years of experience: 8
   - Vehicle types: Truck, Van
3. Consents to background check
4. Accepts terms
5. Submits application
6. Application goes to "under_review" status
7. Background check runs (2-3 days)
8. Fleet manager reviews application
9. Manager approves Tom
10. Tom receives approval email
11. Tom clicks link, sets password
12. Account activated with Driver role
13. Tom can now log in and see available jobs

---

### Scenario 4: User Signup Without Email (Security Questions)

**Story:** Mark wants to register but doesn't want to provide an email address for privacy reasons.

**Steps:**
1. Visit fleetapp.com/signup
2. Fills in registration form:
   - Name: Mark Smith
   - Username: marksmith789
   - Email: (leaves blank)
   - Phone: +1-555-9876
   - Password: SecurePass123!
3. Clicks "Sign Up"
4. Redirected to Security Questions page
5. Selects 3 security questions and provides answers:
   - Q1: "What is your mother's maiden name?" → "Anderson"
   - Q2: "What was the name of your first pet?" → "Rex"
   - Q3: "In what city were you born?" → "Portland"
6. System encrypts answers using AES-256
7. Account created immediately (status: active)
8. Mark can now log in with username and password

**Later: Mark forgets his password:**
1. Goes to "Forgot Password"
2. Enters username: marksmith789
3. System shows his 3 security questions
4. Mark answers correctly
5. All answers verified
6. Mark can set a new password
7. Password reset successful

**Benefits for Mark:**
- No email required (privacy preserved)
- Instant account activation
- Secure account recovery via security questions
- Encrypted answers stored securely

**Security Features Applied:**
- AES-256 encryption for answers
- Answer normalization (case-insensitive, trimmed)
- 3 attempts maximum for recovery
- 30-minute lockout after failed attempts
- Audit logging of all attempts

---

## Summary

The signup process supports **multiple authentication methods**:

### Primary Signup Flows:

1. **Admin-Created (Most Common):** For employees, drivers, staff
   - Admin creates user → Email invitation → User sets password → Account active

2. **Organization Self-Registration:** For new companies
   - Owner registers → Email verification → Account active → Onboarding

3. **Driver Self-Registration:** For contract/gig drivers
   - Driver applies → Review & approval → Invitation sent → Account active

### Authentication Methods:

4. **Email-Based Authentication (Recommended):**
   - Email required during signup
   - Email verification for account activation
   - Password reset via email link
   - Username recovery via email

5. **Security Questions Authentication (Email-Optional):**
   - No email required
   - 3 security questions for account recovery
   - Answers encrypted with AES-256
   - Password reset via security questions
   - Username recovery via security questions + personal info

### Common Features:

All flows include:
- **Security:** Strong password requirements, encrypted data, rate limiting
- **Account Recovery:** Email or security questions based on auth method
- **Audit Logging:** All signup and recovery activities logged
- **Role-Based Access:** Automatic capability assignment based on role
- **Multi-Tenant:** Organization isolation and data privacy

### Security Measures:

- **Password:** Bcrypt hashing, 8+ chars, uppercase/lowercase/digit/special
- **Tokens:** Cryptographically secure, time-limited expiration
- **Encryption:** AES-256 for security answers, PBKDF2 key derivation
- **Rate Limiting:** Prevents brute force and abuse
- **Lockout:** 3 failed attempts = 30-minute lockout
- **CAPTCHA:** Optional for public registrations

The system provides flexible signup options while maintaining strong security, allowing users to choose between email-based authentication (convenient) or security questions (private, no email required).
