# Signup Flow - Security Questions Method

## Overview

Privacy-focused signup process for users who choose **not** to provide an email address.

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
│  Email: [________________] (Optional) ← Left BLANK          │
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
│  (Same as email flow - Select Existing or Create New)       │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY QUESTIONS PAGE                   │
├─────────────────────────────────────────────────────────────┤
│  Set Up Security Questions                                   │
│  ──────────────────────────────────────────                 │
│  ⚠️ Since you didn't provide email, please answer 3        │
│     security questions for account recovery.                 │
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
│  ⚠️ Important: Remember these for account recovery!         │
│     Answers are encrypted and cannot be viewed.              │
│                                                              │
│  [Complete Registration]                                     │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND PROCESSING                        │
├─────────────────────────────────────────────────────────────┤
│  1. Validate user data                                       │
│  2. Hash password with bcrypt                                │
│  3. Generate unique salt for encryption                      │
│  4. Encrypt each answer with AES-256 + user salt             │
│  5. Store encrypted answers in database                      │
│  6. Create user account (status: ACTIVE immediately)         │
│  7. Link to company (existing or new)                        │
│  8. Assign role (Pending User or Owner)                      │
│  9. Notify company admins (if joining existing)              │
│  10. Log account creation                                    │
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
│  IF JOINED EXISTING COMPANY:                                 │
│    → Status: Active (Pending User role)                      │
│    → Waiting for admin to assign proper role                 │
│                                                              │
│  IF CREATED NEW COMPANY:                                     │
│    → Status: Active (Owner role)                             │
│    → Full access to company immediately                      │
│                                                              │
│  📝 Note: Keep security question answers safe for recovery  │
│                                                              │
│  [Continue to Login]                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Differences from Email Flow

| Feature | Email Flow | Security Questions Flow |
|---------|-----------|------------------------|
| **Email Required** | ✅ Yes | ❌ No (optional field left blank) |
| **Verification Step** | Email link verification | None (instant activation) |
| **Account Status** | Pending → Active | Active immediately |
| **Recovery Method** | Email link | Security questions |
| **Additional Step** | None | Security questions setup |
| **Privacy** | Medium | High (no email stored) |

---

## Security Questions

### Available Questions (10 Total)

Users select 3 from these categories:

#### Personal Information
1. What is your mother's maiden name?
2. What was the name of your first pet?
3. In what city were you born?
4. What is your father's middle name?
5. What is the name of your childhood best friend?

#### Memorable Events
6. What was the model of your first car?
7. In what year did you graduate high school?
8. What was the name of your elementary school?

#### Preferences
9. What is your favorite book?
10. What is your dream vacation destination?

---

## Encryption Process

### Step-by-Step Encryption

1. **Generate User Salt**
   - Unique 32-byte random salt per user
   - Stored with user record

2. **Normalize Answer**
   - Convert to lowercase
   - Trim whitespace
   - Example: "  FLUFFY  " → "fluffy"

3. **Derive Encryption Key**
   - Algorithm: PBKDF2 with SHA-256
   - Iterations: 100,000
   - Input: Master secret + User salt
   - Output: 32-byte encryption key

4. **Encrypt Answer**
   - Algorithm: AES-256 (via Fernet)
   - Input: Normalized answer + Encryption key
   - Output: Encrypted ciphertext

5. **Store in Database**
   - User ID
   - Question ID
   - Encrypted answer (base64 encoded)
   - User salt
   - Timestamp

### Why This Approach?

- ✅ **User-Specific Salt**: Each user has unique encryption
- ✅ **Strong Key Derivation**: 100,000 iterations prevents brute force
- ✅ **Industry Standard**: AES-256 is military-grade encryption
- ✅ **Answer Normalization**: Case-insensitive matching
- ✅ **No Plain Text**: Answers never stored unencrypted

---

## API Request Example

### Joining Existing Company

```json
POST /api/auth/signup

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

**Response:**
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
  "message": "Account created successfully. Admin will assign your role.",
  "security_questions_count": 3
}
```

---

### Creating New Company

```json
POST /api/auth/signup

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

**Response:**
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
  "message": "Account created successfully. You are now the Owner.",
  "security_questions_count": 3
}
```

---

## Validation Rules

### Question Selection
- Must select exactly 3 questions
- All 3 questions must be different
- Cannot select same question multiple times

### Answer Requirements
- Minimum length: 2 characters
- Maximum length: 100 characters
- Cannot be empty
- Can contain letters, numbers, spaces

### Security Checks
- Answers are normalized before storage
- Case-insensitive comparison during recovery
- Whitespace trimmed automatically

---

## Error Scenarios

### Duplicate Questions
```json
{
  "success": false,
  "error": "duplicate_questions",
  "message": "Please select different questions"
}
```

### Missing Answers
```json
{
  "success": false,
  "error": "incomplete_questions",
  "message": "Please answer all 3 security questions"
}
```

### Invalid Answer Format
```json
{
  "success": false,
  "error": "invalid_answer",
  "message": "Answers must be 2-100 characters"
}
```

---

## Security Considerations

### Strengths
- ✅ No email dependency (privacy-first)
- ✅ Military-grade encryption (AES-256)
- ✅ Strong key derivation (100K iterations)
- ✅ Unique salt per user
- ✅ Immediate account activation

### Limitations
- ⚠️ User must remember answers
- ⚠️ No email notifications
- ⚠️ 3-attempt lockout on recovery
- ⚠️ Manual recovery process
- ⚠️ No two-factor authentication

### Best Practices
1. **Choose memorable answers** - Use answers you won't forget
2. **Be consistent** - Always use same format (e.g., "fluffy" not "Fluffy")
3. **Keep it private** - Don't share answers with anyone
4. **Write it down** - Store answers securely offline if needed

---

## Related Documents

- [Security Questions System](07-security-questions.md)
- [Password Recovery](08-password-recovery.md)
- [Security Measures](09-security-measures.md)
- [Company Management](04-company-management.md)

---

Last Updated: January 2026
