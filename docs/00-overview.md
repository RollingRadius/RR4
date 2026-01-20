# Fleet Management System - Documentation Overview

## Quick Navigation

This documentation is organized into focused, topic-specific guides for easier reading and reference.

### Authentication & Signup

1. **[Authentication Methods](01-authentication-methods.md)**
   - Email-based authentication
   - Security questions authentication
   - Comparison and use cases

2. **[Signup Flow - Email Method](02-signup-flow-email.md)**
   - Standard email signup process
   - Email verification
   - Company selection during signup

3. **[Signup Flow - Security Questions](03-signup-flow-security-questions.md)**
   - No-email signup process
   - Setting up security questions
   - Company selection for privacy-focused users

4. **[Company Management](04-company-management.md)**
   - Joining existing companies
   - Creating new companies (becoming Owner)
   - GSTIN, PAN, and legal registration

### Technical Implementation

5. **[API Endpoints](05-api-endpoints.md)**
   - User signup endpoints
   - Company management endpoints
   - Security questions endpoints
   - Recovery endpoints

6. **[Frontend Implementation](06-frontend-implementation.md)**
   - Flutter screens and widgets
   - Form validation
   - Navigation flows
   - Complete code examples

### Security & Recovery

7. **[Security Questions System](07-security-questions.md)**
   - Question management
   - AES-256 encryption
   - Answer verification
   - Attempt tracking and lockout

8. **[Password & Username Recovery](08-password-recovery.md)**
   - Email-based recovery
   - Security questions recovery
   - Reset workflows

9. **[Security Measures](09-security-measures.md)**
   - Password hashing (bcrypt)
   - Token security
   - Rate limiting
   - Encryption standards
   - Audit logging

### Access Control

10. **[Role Assignment](10-role-assignment.md)**
    - Admin-created users
    - Organization owners
    - Pending users
    - Role capabilities
    - Multi-tenant isolation

### Examples & Scenarios

11. **[Usage Scenarios](11-usage-scenarios.md)**
    - Real-world examples
    - Complete user journeys
    - Admin workflows
    - Company registration scenarios

---

## Quick Start

### For Developers
1. Start with [Authentication Methods](01-authentication-methods.md) to understand the system
2. Review [API Endpoints](05-api-endpoints.md) for backend integration
3. Check [Frontend Implementation](06-frontend-implementation.md) for UI code

### For Designers
1. Review [Signup Flows](02-signup-flow-email.md) for UX patterns
2. Check [Usage Scenarios](11-usage-scenarios.md) for user journeys
3. See [Company Management](04-company-management.md) for form designs

### For Security Auditors
1. Read [Security Measures](09-security-measures.md)
2. Review [Security Questions System](07-security-questions.md)
3. Check [Password Recovery](08-password-recovery.md)

---

## System Features

### Multi-Authentication Support
- Email with verification
- Security questions (email-optional)
- Flexible account recovery

### Company Management
- Join existing organizations
- Register new companies
- Automatic role assignment
- GSTIN/PAN validation

### Role-Based Access Control
- 11 predefined roles
- Custom role support
- Capability-based permissions
- Multi-tenant isolation

### Security First
- AES-256 encryption for sensitive data
- Bcrypt password hashing
- Rate limiting and CAPTCHA
- Comprehensive audit logging
- 3-attempt lockout system

---

## Document Structure

Each document is self-contained and includes:
- Clear section headings
- Code examples where relevant
- Visual flow diagrams
- API request/response examples
- Security considerations

---

## Related Files

- **Main Documentation**: `SIGNUP.md` (complete comprehensive guide)
- **Implementation Docs**: `SIGNUP_IMPLEMENTATION.md` (technical details)

---

Last Updated: January 2026
