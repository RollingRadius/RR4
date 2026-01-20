# Fleet Management System - Documentation

## 📚 Documentation Structure

This documentation has been broken down into smaller, focused documents for easier reading and reference.

---

## 🚀 Quick Start

**New to the system?** Start here:
1. [00 - Overview](00-overview.md) - System overview and navigation
2. [01 - Authentication Methods](01-authentication-methods.md) - Understand authentication options

**Building the frontend?** Go to:
- [02 - Signup Flow (Email)](02-signup-flow-email.md)
- [03 - Signup Flow (Security Questions)](03-signup-flow-security-questions.md)
- [04 - Company Management](04-company-management.md)

**Integrating the API?** Check:
- [05 - API Endpoints](05-api-endpoints.md)

---

## 📖 All Documents

### Core Documentation

| # | Document | Description | Size |
|---|----------|-------------|------|
| 00 | [Overview](00-overview.md) | System overview and quick navigation | ~2 KB |
| 01 | [Authentication Methods](01-authentication-methods.md) | Email vs Security Questions comparison | ~4 KB |
| 02 | [Signup Flow - Email](02-signup-flow-email.md) | Standard email-based signup process | ~6 KB |
| 03 | [Signup Flow - Security Questions](03-signup-flow-security-questions.md) | Privacy-focused signup without email | ~7 KB |
| 04 | [Company Management](04-company-management.md) | Join existing or create new company | ~8 KB |
| 05 | [API Endpoints](05-api-endpoints.md) | Complete API reference | ~10 KB |

### Coming Soon

Additional documents will be added for:
- Frontend Implementation (Flutter code examples)
- Security Questions System (detailed encryption)
- Password & Username Recovery
- Security Measures (bcrypt, AES-256, etc.)
- Role Assignment (RBAC system)
- Usage Scenarios (real-world examples)

---

## 🎯 Use Cases

### For Developers
✅ Building signup forms → See [02](02-signup-flow-email.md), [03](03-signup-flow-security-questions.md)
✅ Integrating APIs → See [05](05-api-endpoints.md)
✅ Understanding auth → See [01](01-authentication-methods.md)
✅ Company registration → See [04](04-company-management.md)

### For Product Managers
✅ Understanding flows → See [00](00-overview.md)
✅ Feature comparison → See [01](01-authentication-methods.md)
✅ User journeys → See [02](02-signup-flow-email.md), [03](03-signup-flow-security-questions.md)

### For Security Auditors
✅ Encryption details → See [03](03-signup-flow-security-questions.md)
✅ API security → See [05](05-api-endpoints.md)
✅ Validation rules → See [04](04-company-management.md)

---

## 🔗 Complete Documentation

For the **complete, comprehensive documentation** in a single file, refer to:
- **[SIGNUP.md](../SIGNUP.md)** (main documentation file)
- **[SIGNUP_IMPLEMENTATION.md](../SIGNUP_IMPLEMENTATION.md)** (technical implementation)

---

## 📊 Key Features Covered

### Authentication
- ✅ Email-based authentication with verification
- ✅ Security questions (email-optional)
- ✅ Flexible password recovery
- ✅ Username recovery

### Company Management
- ✅ Join existing companies
- ✅ Create new companies (become Owner)
- ✅ GSTIN/PAN validation
- ✅ Complete legal registration

### Security
- ✅ AES-256 encryption for security answers
- ✅ Bcrypt password hashing
- ✅ PBKDF2 key derivation (100K iterations)
- ✅ Rate limiting & lockout protection
- ✅ Secure token generation

### Role-Based Access
- ✅ Automatic role assignment
- ✅ Pending User approval flow
- ✅ Owner with full capabilities
- ✅ Multi-tenant isolation

---

## 🛠️ Technology Stack

**Backend:**
- Python/FastAPI
- PostgreSQL
- bcrypt (password hashing)
- Fernet/AES-256 (answer encryption)
- PBKDF2 (key derivation)

**Frontend:**
- Flutter/Dart
- Material Design
- Form validation
- Secure token handling

---

## 📝 Document Conventions

Each document follows this structure:
- **Overview** - What the document covers
- **Visual Diagrams** - Flow charts and UI mockups
- **Code Examples** - Request/response samples
- **API Reference** - Endpoint details
- **Security Notes** - Important considerations
- **Related Docs** - Cross-references

---

## 🔄 Updates

Documents are regularly updated to reflect:
- New features
- API changes
- Security improvements
- Bug fixes
- User feedback

**Last Major Update:** January 2026

---

## 🤝 Contributing

When adding new documentation:
1. Keep documents focused (single topic)
2. Include code examples
3. Add visual diagrams where helpful
4. Cross-reference related docs
5. Update this index file

---

## 📧 Support

For questions or clarifications:
- Review the appropriate document
- Check the complete [SIGNUP.md](../SIGNUP.md)
- Raise an issue in the repository

---

## ✅ Document Status

| Document | Status | Last Updated |
|----------|--------|--------------|
| 00-overview.md | ✅ Complete | Jan 2026 |
| 01-authentication-methods.md | ✅ Complete | Jan 2026 |
| 02-signup-flow-email.md | ✅ Complete | Jan 2026 |
| 03-signup-flow-security-questions.md | ✅ Complete | Jan 2026 |
| 04-company-management.md | ✅ Complete | Jan 2026 |
| 05-api-endpoints.md | ✅ Complete | Jan 2026 |
| 06-frontend-implementation.md | 🔄 Planned | - |
| 07-security-questions.md | 🔄 Planned | - |
| 08-password-recovery.md | 🔄 Planned | - |
| 09-security-measures.md | 🔄 Planned | - |
| 10-role-assignment.md | 🔄 Planned | - |
| 11-usage-scenarios.md | 🔄 Planned | - |

---

**Happy Reading! 📚**
