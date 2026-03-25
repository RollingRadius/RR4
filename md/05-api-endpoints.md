# API Endpoints Reference

## Overview

Complete API reference for user authentication, signup, and company management.

**Base URL:** `https://api.fleetapp.com`

---

## Table of Contents

1. [User Signup](#user-signup)
2. [Email Verification](#email-verification)
3. [Company Management](#company-management)
4. [Security Questions](#security-questions)
5. [Password Recovery](#password-recovery)
6. [Username Recovery](#username-recovery)

---

## User Signup

### Signup - Email with Existing Company

**POST** `/api/auth/signup`

Creates user account with email, joining an existing company.

**Request Body:**
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

**Response:** `201 Created`
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

### Signup - Email with New Company

**POST** `/api/auth/signup`

Creates user account and new company, user becomes Owner.

**Request Body:**
```json
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
    "registration_date": "2024-01-15",
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

**Response:** `201 Created`
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

### Signup - Security Questions with Existing Company

**POST** `/api/auth/signup`

Creates user without email, uses security questions.

**Request Body:**
```json
{
  "full_name": "Mark Wilson",
  "username": "markwilson789",
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
      "answer": "Anderson"
    },
    {
      "question_id": "Q2",
      "question_text": "What was the name of your first pet?",
      "answer": "Rex"
    },
    {
      "question_id": "Q3",
      "question_text": "In what city were you born?",
      "answer": "Portland"
    }
  ],
  "terms_accepted": true
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "user_id": "user_uuid",
  "username": "markwilson789",
  "status": "active",
  "auth_method": "security_questions",
  "company_id": "company_uuid",
  "company_name": "ABC Logistics",
  "role": "Pending User",
  "message": "Account created. Admin will assign your role.",
  "security_questions_count": 3
}
```

---

### Signup - Security Questions with New Company

**POST** `/api/auth/signup`

Creates user and company without email.

**Request Body:**
```json
{
  "full_name": "Sarah Chen",
  "username": "sarahchen456",
  "email": null,
  "phone": "+91-9876543210",
  "password": "SecurePass123!",
  "auth_method": "security_questions",
  "company_type": "new",
  "company_details": {
    "company_name": "Chen Transport Solutions",
    "business_type": "logistics",
    "gstin": "27ABCDE5678G1Z9",
    "pan_number": "ABCDE5678G",
    "registration_number": "U63040MH2024PTC567890",
    "business_email": "contact@chentransport.in",
    "business_phone": "+91-9876543210",
    "address": "456 Business Park",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "country": "India"
  },
  "security_questions": [
    {
      "question_id": "Q4",
      "question_text": "What is your favorite book?",
      "answer": "1984"
    },
    {
      "question_id": "Q6",
      "question_text": "What is the name of your childhood best friend?",
      "answer": "Emily"
    },
    {
      "question_id": "Q8",
      "question_text": "In what year did you graduate high school?",
      "answer": "2005"
    }
  ],
  "terms_accepted": true
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "user_id": "user_uuid",
  "username": "sarahchen456",
  "status": "active",
  "auth_method": "security_questions",
  "company_id": "new_company_uuid",
  "company_name": "Chen Transport Solutions",
  "role": "Owner",
  "capabilities": ["*"],
  "message": "Account created. You are now the Owner.",
  "security_questions_count": 3
}
```

---

## Email Verification

### Verify Email

**POST** `/api/auth/verify-email`

Verifies user's email address using token from email.

**Request Body:**
```json
{
  "token": "verification_token_from_email"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Email verified successfully",
  "user_id": "user_uuid",
  "redirect_url": "/dashboard"
}
```

**Error Response:** `400 Bad Request`
```json
{
  "success": false,
  "error": "token_expired",
  "message": "Verification link expired. Request new link."
}
```

---

### Resend Verification Email

**POST** `/api/auth/resend-verification`

Resends verification email to user.

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Verification email sent",
  "expires_at": "2024-01-16T10:00:00Z"
}
```

---

## Company Management

### Search Companies

**GET** `/api/auth/companies/search`

Searches for companies by name.

**Query Parameters:**
- `q` (required): Search term
- `limit` (optional): Max results (default: 10)

**Example:** `/api/auth/companies/search?q=ABC&limit=5`

**Response:** `200 OK`
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
    }
  ],
  "count": 2
}
```

---

### Validate Company Details

**POST** `/api/auth/companies/validate`

Validates GSTIN, PAN, and registration number.

**Request Body:**
```json
{
  "gstin": "29ABCDE1234F1Z5",
  "pan_number": "ABCDE1234F",
  "registration_number": "U63040KA2024PTC123456"
}
```

**Response:** `200 OK`
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

**Error Response:** `400 Bad Request`
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

## Security Questions

### Get Available Questions

**GET** `/api/auth/security-questions`

Returns list of available security questions.

**Response:** `200 OK`
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
    }
  ]
}
```

---

### Get User's Security Questions

**POST** `/api/auth/get-security-questions`

Retrieves user's security questions (for recovery).

**Request Body:**
```json
{
  "username": "markwilson789"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "username": "markwilson789",
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
      "question_id": "Q3",
      "question_text": "In what city were you born?"
    }
  ],
  "auth_method": "security_questions"
}
```

---

### Verify Security Questions

**POST** `/api/auth/verify-security-questions`

Verifies security question answers for recovery.

**Request Body:**
```json
{
  "username": "markwilson789",
  "answers": [
    {
      "question_id": "Q1",
      "answer": "Anderson"
    },
    {
      "question_id": "Q2",
      "answer": "Rex"
    },
    {
      "question_id": "Q3",
      "answer": "Portland"
    }
  ]
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "verified": true,
  "user_id": "user_uuid",
  "username": "markwilson789",
  "message": "Security questions verified successfully",
  "recovery_token": "temp_token_for_password_reset"
}
```

**Error Response (Failed):** `400 Bad Request`
```json
{
  "success": false,
  "verified": false,
  "attempts_remaining": 2,
  "message": "One or more answers are incorrect",
  "lockout_in_minutes": null
}
```

**Error Response (Locked):** `429 Too Many Requests`
```json
{
  "success": false,
  "verified": false,
  "attempts_remaining": 0,
  "message": "Account temporarily locked",
  "lockout_in_minutes": 30
}
```

---

## Password Recovery

### Forgot Password (Email Method)

**POST** `/api/auth/forgot-password`

Sends password reset email.

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "If email exists, reset link sent"
}
```

---

### Get Security Questions for Password Reset

**POST** `/api/auth/forgot-password/security-questions`

Gets user's security questions for password reset.

**Request Body:**
```json
{
  "username": "markwilson789"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "user_id": "user_uuid",
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
      "question_id": "Q3",
      "question_text": "In what city were you born?"
    }
  ]
}
```

---

### Reset Password with Security Questions

**POST** `/api/auth/reset-password/security-questions`

Resets password after verifying security questions.

**Request Body:**
```json
{
  "user_id": "user_uuid",
  "answers": [
    {
      "question_id": "Q1",
      "answer": "Anderson"
    },
    {
      "question_id": "Q2",
      "answer": "Rex"
    },
    {
      "question_id": "Q3",
      "answer": "Portland"
    }
  ],
  "new_password": "NewSecurePass456!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

### Reset Password with Email Token

**POST** `/api/auth/reset-password`

Resets password using token from email.

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "new_password": "NewSecurePass456!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

## Username Recovery

### Forgot Username (Email Method)

**POST** `/api/auth/forgot-username`

Sends username reminder email.

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "If email exists, username reminder sent"
}
```

---

### Recover Username with Security Questions

**POST** `/api/auth/recover-username`

Retrieves security questions for username recovery.

**Request Body:**
```json
{
  "full_name": "Mark Wilson",
  "phone": "+1234567890"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "user_id": "user_uuid",
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
      "question_id": "Q3",
      "question_text": "In what city were you born?"
    }
  ]
}
```

---

### Reveal Username

**POST** `/api/auth/reveal-username`

Reveals username after verifying security questions.

**Request Body:**
```json
{
  "user_id": "user_uuid",
  "answers": [
    {
      "question_id": "Q1",
      "answer": "Anderson"
    },
    {
      "question_id": "Q2",
      "answer": "Rex"
    },
    {
      "question_id": "Q3",
      "answer": "Portland"
    }
  ]
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "username": "markwilson789",
  "message": "Your username has been recovered"
}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| `email_exists` | Email already registered |
| `username_taken` | Username not available |
| `invalid_token` | Invalid verification/reset token |
| `token_expired` | Token has expired |
| `invalid_credentials` | Wrong email/password |
| `account_locked` | Too many failed attempts |
| `invalid_gstin` | Invalid GSTIN format |
| `pan_not_linked` | PAN not linked to GSTIN |
| `duplicate_questions` | Same question selected multiple times |
| `incomplete_questions` | Not all questions answered |

---

## Rate Limiting

| Endpoint | Limit |
|----------|-------|
| `/api/auth/signup` | 5 per hour per IP |
| `/api/auth/verify-email` | 10 per hour per IP |
| `/api/auth/forgot-password` | 5 per hour per IP |
| `/api/auth/verify-security-questions` | 3 attempts, then 30-min lockout |

---

## Related Documents

- [Signup Flow - Email](02-signup-flow-email.md)
- [Signup Flow - Security Questions](03-signup-flow-security-questions.md)
- [Password Recovery](08-password-recovery.md)
- [Security Measures](09-security-measures.md)

---

Last Updated: January 2026
