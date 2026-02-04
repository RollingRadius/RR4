"""
Application Constants
Predefined security questions and other constants
"""

# Predefined Security Questions
# Users must select exactly 3 questions during signup with security_questions method
SECURITY_QUESTIONS = [
    {
        "question_key": "Q1",
        "question_text": "What is your mother's maiden name?",
        "category": "personal",
        "display_order": 1
    },
    {
        "question_key": "Q2",
        "question_text": "What was the name of your first pet?",
        "category": "personal",
        "display_order": 2
    },
    {
        "question_key": "Q3",
        "question_text": "In what city were you born?",
        "category": "personal",
        "display_order": 3
    },
    {
        "question_key": "Q4",
        "question_text": "What is your father's middle name?",
        "category": "personal",
        "display_order": 4
    },
    {
        "question_key": "Q5",
        "question_text": "What is the name of your childhood best friend?",
        "category": "personal",
        "display_order": 5
    },
    {
        "question_key": "Q6",
        "question_text": "What was the model of your first car?",
        "category": "memorable_events",
        "display_order": 6
    },
    {
        "question_key": "Q7",
        "question_text": "In what year did you graduate high school?",
        "category": "memorable_events",
        "display_order": 7
    },
    {
        "question_key": "Q8",
        "question_text": "What was the name of your elementary school?",
        "category": "memorable_events",
        "display_order": 8
    },
    {
        "question_key": "Q9",
        "question_text": "What is your favorite book?",
        "category": "preferences",
        "display_order": 9
    },
    {
        "question_key": "Q10",
        "question_text": "What is your dream vacation destination?",
        "category": "preferences",
        "display_order": 10
    }
]

# Default Roles for Signup
DEFAULT_ROLES = [
    {
        "role_name": "Owner",
        "role_key": "owner",
        "description": "Full access to company resources. Assigned to user who creates a new company.",
        "is_system_role": True
    },
    {
        "role_name": "Pending User",
        "role_key": "pending_user",
        "description": "User awaiting role assignment by admin. Assigned when joining existing company.",
        "is_system_role": True
    },
    {
        "role_name": "Independent User",
        "role_key": "independent_user",
        "description": "User without company affiliation. Assigned when skipping company selection.",
        "is_system_role": True
    }
]

# Authentication Methods
AUTH_METHOD_EMAIL = "email"
AUTH_METHOD_SECURITY_QUESTIONS = "security_questions"

# User Status
USER_STATUS_PENDING_VERIFICATION = "pending_verification"
USER_STATUS_ACTIVE = "active"
USER_STATUS_INACTIVE = "inactive"
USER_STATUS_LOCKED = "locked"

# Company Types for Signup
COMPANY_TYPE_EXISTING = "existing"
COMPANY_TYPE_NEW = "new"

# Token Types
TOKEN_TYPE_EMAIL_VERIFICATION = "email_verification"
TOKEN_TYPE_PASSWORD_RESET = "password_reset"
TOKEN_TYPE_USERNAME_RECOVERY = "username_recovery"

# Recovery Attempt Types
RECOVERY_TYPE_LOGIN = "login"
RECOVERY_TYPE_SECURITY_QUESTIONS = "security_questions"
RECOVERY_TYPE_PASSWORD_RESET = "password_reset"

# Audit Log Actions
AUDIT_ACTION_USER_SIGNUP = "user_signup"
AUDIT_ACTION_USER_CREATED = "user_created"
AUDIT_ACTION_USER_LOGIN = "user_login"
AUDIT_ACTION_USER_LOGOUT = "user_logout"
AUDIT_ACTION_EMAIL_VERIFIED = "email_verified"
AUDIT_ACTION_PASSWORD_RESET = "password_reset"
AUDIT_ACTION_USERNAME_RECOVERED = "username_recovered"
AUDIT_ACTION_COMPANY_CREATED = "company_created"
AUDIT_ACTION_COMPANY_JOINED = "company_joined"
AUDIT_ACTION_ACCOUNT_LOCKED = "account_locked"
AUDIT_ACTION_ACCOUNT_UNLOCKED = "account_unlocked"
AUDIT_ACTION_FAILED_LOGIN = "failed_login"
AUDIT_ACTION_FAILED_RECOVERY = "failed_recovery"
AUDIT_ACTION_DRIVER_CREATED = "driver_created"
AUDIT_ACTION_DRIVER_UPDATED = "driver_updated"
AUDIT_ACTION_DRIVER_DELETED = "driver_deleted"
AUDIT_ACTION_USER_APPROVED = "user_approved"
AUDIT_ACTION_USER_REJECTED = "user_rejected"
AUDIT_ACTION_ROLE_CHANGED = "role_changed"
AUDIT_ACTION_USER_REMOVED = "user_removed"
AUDIT_ACTION_VEHICLE_CREATED = "vehicle_created"
AUDIT_ACTION_VEHICLE_UPDATED = "vehicle_updated"
AUDIT_ACTION_VEHICLE_DELETED = "vehicle_deleted"
AUDIT_ACTION_VEHICLE_ASSIGNED = "vehicle_assigned"
AUDIT_ACTION_VEHICLE_UNASSIGNED = "vehicle_unassigned"
AUDIT_ACTION_VEHICLE_DOCUMENT_UPLOADED = "vehicle_document_uploaded"
AUDIT_ACTION_VEHICLE_DOCUMENT_DELETED = "vehicle_document_deleted"
AUDIT_ACTION_VEHICLE_ARCHIVED = "vehicle_archived"
AUDIT_ACTION_VEHICLE_IMPORTED = "vehicle_imported"
AUDIT_ACTION_VEHICLE_EXPORTED = "vehicle_exported"

# Entity Types for Audit Logs
ENTITY_TYPE_USER = "user"
ENTITY_TYPE_COMPANY = "company"
ENTITY_TYPE_ROLE = "role"
ENTITY_TYPE_VERIFICATION_TOKEN = "verification_token"
ENTITY_TYPE_DRIVER = "driver"
ENTITY_TYPE_DRIVER_LICENSE = "driver_license"
ENTITY_TYPE_USER_ORG = "user_organization"
ENTITY_TYPE_VEHICLE = "vehicle"
ENTITY_TYPE_VEHICLE_DOCUMENT = "vehicle_document"

# Business Types for Companies
BUSINESS_TYPES = [
    "transportation",
    "logistics",
    "freight",
    "courier",
    "delivery",
    "taxi",
    "rental",
    "other"
]

# Indian States (for company address validation)
INDIAN_STATES = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
]

# Driver Status
DRIVER_STATUS_ACTIVE = "active"
DRIVER_STATUS_INACTIVE = "inactive"
DRIVER_STATUS_ON_LEAVE = "on_leave"
DRIVER_STATUS_TERMINATED = "terminated"

# Driver License Types (Indian)
LICENSE_TYPE_LMV = "LMV"  # Light Motor Vehicle (cars, jeeps, small vans)
LICENSE_TYPE_HMV = "HMV"  # Heavy Motor Vehicle (trucks, buses)
LICENSE_TYPE_MCWG = "MCWG"  # Motorcycle with Gear
LICENSE_TYPE_HPMV = "HPMV"  # Heavy Passenger Motor Vehicle (large buses)

LICENSE_TYPES = [LICENSE_TYPE_LMV, LICENSE_TYPE_HMV, LICENSE_TYPE_MCWG, LICENSE_TYPE_HPMV]

# Vehicle Status
VEHICLE_STATUS_ACTIVE = "active"
VEHICLE_STATUS_INACTIVE = "inactive"
VEHICLE_STATUS_MAINTENANCE = "maintenance"
VEHICLE_STATUS_DECOMMISSIONED = "decommissioned"

VEHICLE_STATUSES = [
    VEHICLE_STATUS_ACTIVE,
    VEHICLE_STATUS_INACTIVE,
    VEHICLE_STATUS_MAINTENANCE,
    VEHICLE_STATUS_DECOMMISSIONED
]

# Vehicle Types
VEHICLE_TYPE_TRUCK = "truck"
VEHICLE_TYPE_BUS = "bus"
VEHICLE_TYPE_VAN = "van"
VEHICLE_TYPE_CAR = "car"
VEHICLE_TYPE_MOTORCYCLE = "motorcycle"
VEHICLE_TYPE_OTHER = "other"

VEHICLE_TYPES = [
    VEHICLE_TYPE_TRUCK,
    VEHICLE_TYPE_BUS,
    VEHICLE_TYPE_VAN,
    VEHICLE_TYPE_CAR,
    VEHICLE_TYPE_MOTORCYCLE,
    VEHICLE_TYPE_OTHER
]

# Fuel Types
FUEL_TYPE_PETROL = "petrol"
FUEL_TYPE_DIESEL = "diesel"
FUEL_TYPE_ELECTRIC = "electric"
FUEL_TYPE_HYBRID = "hybrid"
FUEL_TYPE_CNG = "cng"
FUEL_TYPE_LPG = "lpg"

FUEL_TYPES = [
    FUEL_TYPE_PETROL,
    FUEL_TYPE_DIESEL,
    FUEL_TYPE_ELECTRIC,
    FUEL_TYPE_HYBRID,
    FUEL_TYPE_CNG,
    FUEL_TYPE_LPG
]

# Vehicle Document Types
VEHICLE_DOC_REGISTRATION = "registration"
VEHICLE_DOC_INSURANCE = "insurance"
VEHICLE_DOC_POLLUTION_CERT = "pollution_cert"
VEHICLE_DOC_FITNESS_CERT = "fitness_cert"
VEHICLE_DOC_PERMIT = "permit"
VEHICLE_DOC_TAX_RECEIPT = "tax_receipt"
VEHICLE_DOC_OTHER = "other"

VEHICLE_DOCUMENT_TYPES = [
    VEHICLE_DOC_REGISTRATION,
    VEHICLE_DOC_INSURANCE,
    VEHICLE_DOC_POLLUTION_CERT,
    VEHICLE_DOC_FITNESS_CERT,
    VEHICLE_DOC_PERMIT,
    VEHICLE_DOC_TAX_RECEIPT,
    VEHICLE_DOC_OTHER
]

# Emergency Contact Relationships
EMERGENCY_CONTACT_RELATIONSHIPS = [
    "Parent",
    "Spouse",
    "Sibling",
    "Friend",
    "Relative",
    "Other"
]

# Password Requirements
PASSWORD_MIN_LENGTH = 8
PASSWORD_MAX_LENGTH = 128
PASSWORD_REQUIRE_UPPERCASE = True
PASSWORD_REQUIRE_LOWERCASE = True
PASSWORD_REQUIRE_DIGIT = True
PASSWORD_REQUIRE_SPECIAL = False  # Optional for now

# Username Requirements
USERNAME_MIN_LENGTH = 3
USERNAME_MAX_LENGTH = 50
USERNAME_ALLOWED_CHARS = "alphanumeric and underscore only"

# Company Search
COMPANY_SEARCH_MIN_LENGTH = 3
COMPANY_SEARCH_MAX_RESULTS = 3

# Error Messages
ERROR_USERNAME_EXISTS = "Username already exists"
ERROR_EMAIL_EXISTS = "Email already registered"
ERROR_INVALID_CREDENTIALS = "Invalid username or password"
ERROR_ACCOUNT_LOCKED = "Account is locked due to multiple failed login attempts. Please try again after {minutes} minutes."
ERROR_EMAIL_NOT_VERIFIED = "Please verify your email before logging in"
ERROR_GSTIN_INVALID_FORMAT = "Invalid GSTIN format. Expected format: 29ABCDE1234F1Z5"
ERROR_PAN_INVALID_FORMAT = "Invalid PAN format. Expected format: ABCDE1234F"
ERROR_COMPANY_NOT_FOUND = "Company not found"
ERROR_INSUFFICIENT_SECURITY_QUESTIONS = "Please answer at least 3 security questions"
ERROR_DUPLICATE_SECURITY_QUESTIONS = "Please select different security questions"
ERROR_WEAK_PASSWORD = "Password must be at least 8 characters with uppercase, lowercase, and digit"

# Success Messages
SUCCESS_SIGNUP_EMAIL = "Signup successful! Please check your email for verification link."
SUCCESS_SIGNUP_SECURITY_QUESTIONS = "Signup successful! You can now login."
SUCCESS_EMAIL_VERIFIED = "Email verified successfully! You can now login."
SUCCESS_PASSWORD_RESET = "Password reset successful! You can now login with your new password."
SUCCESS_USERNAME_RECOVERED = "Username recovered successfully! We've sent it to your registered contact."
SUCCESS_COMPANY_CREATED = "Company created successfully!"
SUCCESS_COMPANY_JOINED = "Successfully joined company. Admin will assign your role."

# Vendor Types
VENDOR_TYPE_SUPPLIER = "supplier"
VENDOR_TYPE_WORKSHOP = "workshop"
VENDOR_TYPE_FUEL_STATION = "fuel_station"
VENDOR_TYPE_INSURANCE = "insurance"
VENDOR_TYPE_OTHER = "other"

VENDOR_TYPES = [
    VENDOR_TYPE_SUPPLIER,
    VENDOR_TYPE_WORKSHOP,
    VENDOR_TYPE_FUEL_STATION,
    VENDOR_TYPE_INSURANCE,
    VENDOR_TYPE_OTHER
]

# Vendor Status
VENDOR_STATUS_ACTIVE = "active"
VENDOR_STATUS_INACTIVE = "inactive"

# Expense Categories
EXPENSE_CATEGORY_FUEL = "fuel"
EXPENSE_CATEGORY_MAINTENANCE = "maintenance"
EXPENSE_CATEGORY_TOLL = "toll"
EXPENSE_CATEGORY_PARKING = "parking"
EXPENSE_CATEGORY_INSURANCE = "insurance"
EXPENSE_CATEGORY_SALARY = "salary"
EXPENSE_CATEGORY_OTHER = "other"

EXPENSE_CATEGORIES = [
    EXPENSE_CATEGORY_FUEL,
    EXPENSE_CATEGORY_MAINTENANCE,
    EXPENSE_CATEGORY_TOLL,
    EXPENSE_CATEGORY_PARKING,
    EXPENSE_CATEGORY_INSURANCE,
    EXPENSE_CATEGORY_SALARY,
    EXPENSE_CATEGORY_OTHER
]

# Expense Status
EXPENSE_STATUS_DRAFT = "draft"
EXPENSE_STATUS_SUBMITTED = "submitted"
EXPENSE_STATUS_APPROVED = "approved"
EXPENSE_STATUS_REJECTED = "rejected"
EXPENSE_STATUS_PAID = "paid"

EXPENSE_STATUSES = [
    EXPENSE_STATUS_DRAFT,
    EXPENSE_STATUS_SUBMITTED,
    EXPENSE_STATUS_APPROVED,
    EXPENSE_STATUS_REJECTED,
    EXPENSE_STATUS_PAID
]

# Invoice Status
INVOICE_STATUS_DRAFT = "draft"
INVOICE_STATUS_SENT = "sent"
INVOICE_STATUS_PARTIALLY_PAID = "partially_paid"
INVOICE_STATUS_PAID = "paid"
INVOICE_STATUS_OVERDUE = "overdue"
INVOICE_STATUS_CANCELLED = "cancelled"

INVOICE_STATUSES = [
    INVOICE_STATUS_DRAFT,
    INVOICE_STATUS_SENT,
    INVOICE_STATUS_PARTIALLY_PAID,
    INVOICE_STATUS_PAID,
    INVOICE_STATUS_OVERDUE,
    INVOICE_STATUS_CANCELLED
]

# Payment Types
PAYMENT_TYPE_RECEIVED = "received"
PAYMENT_TYPE_PAID = "paid"

PAYMENT_TYPES = [PAYMENT_TYPE_RECEIVED, PAYMENT_TYPE_PAID]

# Payment Methods
PAYMENT_METHOD_CASH = "cash"
PAYMENT_METHOD_BANK_TRANSFER = "bank_transfer"
PAYMENT_METHOD_CHEQUE = "cheque"
PAYMENT_METHOD_UPI = "upi"
PAYMENT_METHOD_CARD = "card"
PAYMENT_METHOD_OTHER = "other"

PAYMENT_METHODS = [
    PAYMENT_METHOD_CASH,
    PAYMENT_METHOD_BANK_TRANSFER,
    PAYMENT_METHOD_CHEQUE,
    PAYMENT_METHOD_UPI,
    PAYMENT_METHOD_CARD,
    PAYMENT_METHOD_OTHER
]

# Budget Period
BUDGET_PERIOD_MONTHLY = "monthly"
BUDGET_PERIOD_QUARTERLY = "quarterly"
BUDGET_PERIOD_YEARLY = "yearly"

BUDGET_PERIODS = [BUDGET_PERIOD_MONTHLY, BUDGET_PERIOD_QUARTERLY, BUDGET_PERIOD_YEARLY]

# Maintenance Types
MAINTENANCE_TYPE_PREVENTIVE = "preventive"
MAINTENANCE_TYPE_CORRECTIVE = "corrective"
MAINTENANCE_TYPE_INSPECTION = "inspection"
MAINTENANCE_TYPE_EMERGENCY = "emergency"

MAINTENANCE_TYPES = [
    MAINTENANCE_TYPE_PREVENTIVE,
    MAINTENANCE_TYPE_CORRECTIVE,
    MAINTENANCE_TYPE_INSPECTION,
    MAINTENANCE_TYPE_EMERGENCY
]

# Work Order Status
WORK_ORDER_STATUS_PENDING = "pending"
WORK_ORDER_STATUS_IN_PROGRESS = "in_progress"
WORK_ORDER_STATUS_COMPLETED = "completed"
WORK_ORDER_STATUS_CANCELLED = "cancelled"

WORK_ORDER_STATUSES = [
    WORK_ORDER_STATUS_PENDING,
    WORK_ORDER_STATUS_IN_PROGRESS,
    WORK_ORDER_STATUS_COMPLETED,
    WORK_ORDER_STATUS_CANCELLED
]

# Schedule Trigger Types
SCHEDULE_TRIGGER_MILEAGE = "mileage"
SCHEDULE_TRIGGER_TIME = "time"
SCHEDULE_TRIGGER_BOTH = "both"

SCHEDULE_TRIGGER_TYPES = [
    SCHEDULE_TRIGGER_MILEAGE,
    SCHEDULE_TRIGGER_TIME,
    SCHEDULE_TRIGGER_BOTH
]

# Part Categories
PART_CATEGORY_ENGINE = "engine"
PART_CATEGORY_TRANSMISSION = "transmission"
PART_CATEGORY_BRAKE = "brake"
PART_CATEGORY_SUSPENSION = "suspension"
PART_CATEGORY_ELECTRICAL = "electrical"
PART_CATEGORY_TIRE = "tire"
PART_CATEGORY_BODY = "body"
PART_CATEGORY_FLUID = "fluid"
PART_CATEGORY_OTHER = "other"

PART_CATEGORIES = [
    PART_CATEGORY_ENGINE,
    PART_CATEGORY_TRANSMISSION,
    PART_CATEGORY_BRAKE,
    PART_CATEGORY_SUSPENSION,
    PART_CATEGORY_ELECTRICAL,
    PART_CATEGORY_TIRE,
    PART_CATEGORY_BODY,
    PART_CATEGORY_FLUID,
    PART_CATEGORY_OTHER
]

# Report Types
REPORT_TYPE_FLEET_PERFORMANCE = "fleet_performance"
REPORT_TYPE_DRIVER_PERFORMANCE = "driver_performance"
REPORT_TYPE_FINANCIAL = "financial"
REPORT_TYPE_MAINTENANCE = "maintenance"
REPORT_TYPE_CUSTOM = "custom"

REPORT_TYPES = [
    REPORT_TYPE_FLEET_PERFORMANCE,
    REPORT_TYPE_DRIVER_PERFORMANCE,
    REPORT_TYPE_FINANCIAL,
    REPORT_TYPE_MAINTENANCE,
    REPORT_TYPE_CUSTOM
]

# Report Export Formats
REPORT_FORMAT_CSV = "csv"
REPORT_FORMAT_PDF = "pdf"
REPORT_FORMAT_EXCEL = "excel"

REPORT_FORMATS = [REPORT_FORMAT_CSV, REPORT_FORMAT_PDF, REPORT_FORMAT_EXCEL]

# Dashboard Widget Types
WIDGET_TYPE_KPI = "kpi"
WIDGET_TYPE_CHART = "chart"
WIDGET_TYPE_TABLE = "table"
WIDGET_TYPE_GAUGE = "gauge"
WIDGET_TYPE_MAP = "map"

WIDGET_TYPES = [
    WIDGET_TYPE_KPI,
    WIDGET_TYPE_CHART,
    WIDGET_TYPE_TABLE,
    WIDGET_TYPE_GAUGE,
    WIDGET_TYPE_MAP
]

# Audit Actions - Financial
AUDIT_ACTION_EXPENSE_CREATED = "expense_created"
AUDIT_ACTION_EXPENSE_UPDATED = "expense_updated"
AUDIT_ACTION_EXPENSE_SUBMITTED = "expense_submitted"
AUDIT_ACTION_EXPENSE_APPROVED = "expense_approved"
AUDIT_ACTION_EXPENSE_REJECTED = "expense_rejected"
AUDIT_ACTION_EXPENSE_PAID = "expense_paid"
AUDIT_ACTION_EXPENSE_ATTACHMENT_UPLOADED = "expense_attachment_uploaded"
AUDIT_ACTION_VENDOR_CREATED = "vendor_created"
AUDIT_ACTION_VENDOR_UPDATED = "vendor_updated"
AUDIT_ACTION_INVOICE_CREATED = "invoice_created"
AUDIT_ACTION_INVOICE_UPDATED = "invoice_updated"
AUDIT_ACTION_INVOICE_SENT = "invoice_sent"
AUDIT_ACTION_INVOICE_PAYMENT_RECORDED = "invoice_payment_recorded"
AUDIT_ACTION_INVOICE_CANCELLED = "invoice_cancelled"
AUDIT_ACTION_PAYMENT_CREATED = "payment_created"
AUDIT_ACTION_PAYMENT_UPDATED = "payment_updated"
AUDIT_ACTION_PAYMENT_DELETED = "payment_deleted"
AUDIT_ACTION_PAYMENT_RECORDED = "payment_recorded"
AUDIT_ACTION_BUDGET_CREATED = "budget_created"
AUDIT_ACTION_BUDGET_UPDATED = "budget_updated"
AUDIT_ACTION_BUDGET_ALERT = "budget_alert"

# Audit Actions - Maintenance
AUDIT_ACTION_SCHEDULE_CREATED = "schedule_created"
AUDIT_ACTION_SCHEDULE_UPDATED = "schedule_updated"
AUDIT_ACTION_WORK_ORDER_CREATED = "work_order_created"
AUDIT_ACTION_WORK_ORDER_UPDATED = "work_order_updated"
AUDIT_ACTION_WORK_ORDER_ASSIGNED = "work_order_assigned"
AUDIT_ACTION_WORK_ORDER_STARTED = "work_order_started"
AUDIT_ACTION_WORK_ORDER_COMPLETED = "work_order_completed"
AUDIT_ACTION_INSPECTION_CREATED = "inspection_created"
AUDIT_ACTION_PART_CREATED = "part_created"
AUDIT_ACTION_PART_UPDATED = "part_updated"
AUDIT_ACTION_PART_USAGE_RECORDED = "part_usage_recorded"
AUDIT_ACTION_STOCK_UPDATED = "stock_updated"

# Entity Types - Financial
ENTITY_TYPE_EXPENSE = "expense"
ENTITY_TYPE_VENDOR = "vendor"
ENTITY_TYPE_INVOICE = "invoice"
ENTITY_TYPE_PAYMENT = "payment"
ENTITY_TYPE_BUDGET = "budget"

# Entity Types - Maintenance
ENTITY_TYPE_SCHEDULE = "maintenance_schedule"
ENTITY_TYPE_WORK_ORDER = "work_order"
ENTITY_TYPE_INSPECTION = "inspection"
ENTITY_TYPE_PART = "part"
ENTITY_TYPE_PART_USAGE = "part_usage"

# Entity Types - Reporting
ENTITY_TYPE_REPORT = "report"
ENTITY_TYPE_DASHBOARD = "dashboard"
ENTITY_TYPE_KPI = "kpi"
