# Authentication Methods

## Overview

The Fleet Management System supports **two authentication methods** to accommodate different user privacy preferences and organizational requirements.

---

## Method 1: Email-Based Authentication (Recommended)

### When to Use
- Standard business users
- Users who want easy password recovery
- Organizations requiring email communication

### How It Works

**Registration:**
1. User provides email during signup
2. System sends verification email
3. User clicks link to verify
4. Account activated

**Recovery:**
- Password reset via email link
- Username reminder via email
- Immediate, self-service recovery

**Benefits:**
- ✅ Convenient password recovery
- ✅ Email notifications for account activity
- ✅ Industry-standard security
- ✅ Two-factor authentication available
- ✅ Instant account recovery

**Limitations:**
- ❌ Requires valid email address
- ❌ Email privacy concerns
- ❌ Dependent on email service availability

---

## Method 2: Security Questions Authentication (Email-Optional)

### When to Use
- Privacy-conscious users
- Users without email access
- High-security environments
- Offline verification scenarios

### How It Works

**Registration:**
1. User skips email field
2. System prompts for 3 security questions
3. Answers encrypted with AES-256
4. Account activated immediately

**Recovery:**
- Username recovery via name + phone + security questions
- Password reset via security questions
- Manual verification process

**Benefits:**
- ✅ No email required (enhanced privacy)
- ✅ Instant account activation
- ✅ Encrypted answer storage
- ✅ Offline-capable recovery
- ✅ No dependency on external services

**Limitations:**
- ❌ Must remember security answers
- ❌ No two-factor authentication
- ❌ 3-attempt limit before lockout
- ❌ Manual recovery process

---

## Feature Comparison

| Feature | Email-Based | Security Questions |
|---------|-------------|-------------------|
| **Email Required** | ✅ Yes | ❌ No |
| **Password Recovery** | Email link (instant) | Answer questions (manual) |
| **Username Recovery** | Email | Name + Phone + Questions |
| **Account Verification** | Email link | Immediate activation |
| **Two-Factor Auth** | ✅ Available | ❌ Not available |
| **Recovery Time** | Immediate | 2-3 minutes (manual) |
| **Privacy Level** | Medium | High |
| **Email Notifications** | ✅ Yes | ❌ No |
| **Lockout Protection** | Email-based reset | 30-min lockout after 3 fails |

---

## Security Comparison

### Email-Based Security
- **Password**: Bcrypt hashing
- **Tokens**: 32-byte secure tokens
- **Expiration**: 24-48 hours
- **Rate Limiting**: 10 attempts/hour
- **Recovery**: Email link validation

### Security Questions Security
- **Password**: Bcrypt hashing
- **Answers**: AES-256 encryption with PBKDF2
- **Salt**: Unique per user
- **Iterations**: 100,000 (PBKDF2)
- **Attempts**: Max 3 before 30-min lockout
- **Normalization**: Case-insensitive, trimmed

---

## Choosing an Authentication Method

### Recommended: Email-Based

**Use when:**
- Building standard business applications
- Users need quick self-service recovery
- Email notifications are important
- Organization has email infrastructure

**Example users:**
- Corporate employees
- Fleet managers
- Dispatchers
- Accountants

---

### Alternative: Security Questions

**Use when:**
- Maximum privacy is required
- Users don't have reliable email access
- Operating in high-security environments
- Email dependency is unacceptable

**Example users:**
- Privacy-conscious individuals
- Field workers without email
- Temporary/contract workers
- Users in restricted networks

---

## Implementation Notes

### For Developers

**Email Method:**
```json
{
  "auth_method": "email",
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Security Questions Method:**
```json
{
  "auth_method": "security_questions",
  "email": null,
  "password": "SecurePass123!",
  "security_questions": [...]
}
```

### For Users

**Signup Decision Point:**
- Email field is **optional**
- Leaving it blank triggers security questions flow
- Filling it enables email-based recovery

---

## Hybrid Approach (Future Enhancement)

**Planned Feature:**
- Allow email users to **also** set security questions
- Provides dual recovery methods
- Enhanced security and flexibility
- Currently not implemented

---

## Related Documents

- [Email Signup Flow](02-signup-flow-email.md)
- [Security Questions Flow](03-signup-flow-security-questions.md)
- [Password Recovery](08-password-recovery.md)
- [Security Measures](09-security-measures.md)

---

## Next Steps

1. Choose authentication method based on requirements
2. Review the specific signup flow documentation
3. Implement appropriate frontend forms
4. Test recovery workflows

---

Last Updated: January 2026
