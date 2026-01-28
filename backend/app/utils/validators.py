"""
Validation Utilities
GSTIN, PAN, email, password, username validators
"""

import re
from typing import Tuple, Optional

# Regex Patterns
GSTIN_PATTERN = r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$'
PAN_PATTERN = r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$'
EMAIL_PATTERN = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
PHONE_PATTERN = r'^\+?[\d\s-]{10,15}$'
USERNAME_PATTERN = r'^[a-zA-Z0-9_]{3,50}$'


def validate_gstin(gstin: str) -> Tuple[bool, Optional[str]]:
    """
    Validate GSTIN (Goods and Services Tax Identification Number) format.

    GSTIN Format: 2 digits + 5 letters + 4 digits + 1 letter + 1 alphanumeric + Z + 1 alphanumeric
    Example: 29ABCDE1234F1Z5

    Structure:
    - First 2 digits: State code
    - Next 5 letters: PAN of the business
    - Next 4 digits: Entity number
    - Next 1 letter: Alphabet
    - Next 1 alphanumeric: Registration center code
    - Next 1 letter: Z (default)
    - Last 1 alphanumeric: Check code

    Args:
        gstin: GSTIN string to validate

    Returns:
        Tuple of (is_valid, error_message)

    Example:
        is_valid, error = validate_gstin("29ABCDE1234F1Z5")
    """
    if not gstin:
        return True, None  # GSTIN is optional

    # Remove whitespace
    gstin = gstin.strip().upper()

    # Check length
    if len(gstin) != 15:
        return False, "GSTIN must be exactly 15 characters"

    # Check format
    if not re.match(GSTIN_PATTERN, gstin):
        return False, "Invalid GSTIN format. Expected: 29ABCDE1234F1Z5"

    # Extract and validate state code (01-37 for Indian states)
    state_code = int(gstin[:2])
    if state_code < 1 or state_code > 37:
        return False, "Invalid state code in GSTIN (must be 01-37)"

    return True, None


def validate_pan(pan: str) -> Tuple[bool, Optional[str]]:
    """
    Validate PAN (Permanent Account Number) format.

    PAN Format: 5 letters + 4 digits + 1 letter
    Example: ABCDE1234F

    Structure:
    - First 3 letters: Sequence of letters
    - 4th character: Type of holder (C=Company, P=Person, H=HUF, etc.)
    - 5th character: First letter of surname/name
    - Next 4 digits: Sequential number
    - Last letter: Check digit

    Args:
        pan: PAN string to validate

    Returns:
        Tuple of (is_valid, error_message)

    Example:
        is_valid, error = validate_pan("ABCDE1234F")
    """
    if not pan:
        return True, None  # PAN is optional

    # Remove whitespace
    pan = pan.strip().upper()

    # Check length
    if len(pan) != 10:
        return False, "PAN must be exactly 10 characters"

    # Check format
    if not re.match(PAN_PATTERN, pan):
        return False, "Invalid PAN format. Expected: ABCDE1234F"

    return True, None


def validate_email(email: str) -> Tuple[bool, Optional[str]]:
    """
    Validate email format.

    Args:
        email: Email address to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not email:
        return False, "Email is required"

    email = email.strip().lower()

    if not re.match(EMAIL_PATTERN, email):
        return False, "Invalid email format"

    if len(email) > 255:
        return False, "Email is too long (max 255 characters)"

    return True, None


def validate_phone(phone: str) -> Tuple[bool, Optional[str]]:
    """
    Validate phone number format.

    Accepts formats:
    - +1234567890
    - 1234567890
    - +91 12345 67890
    - +91-1234-567-890

    Args:
        phone: Phone number to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not phone:
        return False, "Phone number is required"

    phone = phone.strip()

    if not re.match(PHONE_PATTERN, phone):
        return False, "Invalid phone number format"

    # Remove all non-digit characters for length check
    digits_only = re.sub(r'\D', '', phone)
    if len(digits_only) < 10 or len(digits_only) > 15:
        return False, "Phone number must be 10-15 digits"

    return True, None


def validate_username(username: str) -> Tuple[bool, Optional[str]]:
    """
    Validate username format.

    Rules:
    - 3-50 characters
    - Alphanumeric and underscore only
    - No spaces or special characters

    Args:
        username: Username to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not username:
        return False, "Username is required"

    username = username.strip()

    if len(username) < 3:
        return False, "Username must be at least 3 characters"

    if len(username) > 50:
        return False, "Username must be at most 50 characters"

    if not re.match(USERNAME_PATTERN, username):
        return False, "Username can only contain letters, numbers, and underscores"

    return True, None


def validate_password(password: str) -> Tuple[bool, Optional[str]]:
    """
    Validate password strength.

    Requirements:
    - At least 8 characters
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 digit
    - Maximum 128 characters

    Args:
        password: Password to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not password:
        return False, "Password is required"

    if len(password) < 8:
        return False, "Password must be at least 8 characters"

    if len(password) > 128:
        return False, "Password is too long (max 128 characters)"

    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"

    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"

    if not re.search(r'\d', password):
        return False, "Password must contain at least one digit"

    return True, None


def validate_registration_number(reg_number: str) -> Tuple[bool, Optional[str]]:
    """
    Validate company registration number format.
    This is a basic validation as registration formats vary.

    Args:
        reg_number: Registration number to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not reg_number:
        return True, None  # Registration number is optional

    reg_number = reg_number.strip()

    if len(reg_number) < 5:
        return False, "Registration number is too short"

    if len(reg_number) > 100:
        return False, "Registration number is too long (max 100 characters)"

    return True, None


def validate_pincode(pincode: str) -> Tuple[bool, Optional[str]]:
    """
    Validate Indian pincode format (6 digits).

    Args:
        pincode: Pincode to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not pincode:
        return False, "Pincode is required"

    pincode = pincode.strip()

    if not re.match(r'^\d{6}$', pincode):
        return False, "Invalid pincode format (must be 6 digits)"

    return True, None


def validate_license_number(license_num: str) -> Tuple[bool, Optional[str]]:
    """
    Validate driver license number format.

    Format: 10-50 alphanumeric characters (uppercase) with optional hyphens
    Example: DL-1420110012345, KA0120120012345

    Args:
        license_num: License number to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not license_num:
        return False, "License number is required"

    license_num = license_num.strip().upper()

    if len(license_num) < 10 or len(license_num) > 50:
        return False, "License number must be 10-50 characters"

    if not re.match(r'^[A-Z0-9\-]{10,50}$', license_num):
        return False, "License number can only contain uppercase letters, numbers, and hyphens"

    return True, None


def validate_employee_id(emp_id: str) -> Tuple[bool, Optional[str]]:
    """
    Validate employee ID format.

    Format: 3-50 alphanumeric characters with optional hyphens
    Example: EMP-001, E12345, DRIVER-2024-001

    Args:
        emp_id: Employee ID to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not emp_id:
        return False, "Employee ID is required"

    emp_id = emp_id.strip()

    if len(emp_id) < 3 or len(emp_id) > 50:
        return False, "Employee ID must be 3-50 characters"

    if not re.match(r'^[A-Za-z0-9\-]{3,50}$', emp_id):
        return False, "Employee ID can only contain letters, numbers, and hyphens"

    return True, None


def extract_pan_from_gstin(gstin: str) -> Optional[str]:
    """
    Extract PAN from GSTIN.
    The PAN is embedded in positions 2-11 of the GSTIN.

    Args:
        gstin: Valid GSTIN string

    Returns:
        Extracted PAN or None if invalid GSTIN

    Example:
        pan = extract_pan_from_gstin("29ABCDE1234F1Z5")  # Returns "ABCDE1234F"
    """
    if not gstin or len(gstin) != 15:
        return None

    return gstin[2:12]


def validate_gstin_pan_linkage(gstin: str, pan: str) -> Tuple[bool, Optional[str]]:
    """
    Validate that PAN matches the PAN embedded in GSTIN.

    Args:
        gstin: GSTIN string
        pan: PAN string

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not gstin or not pan:
        return True, None  # Both are optional, so skip linkage validation

    extracted_pan = extract_pan_from_gstin(gstin)
    if not extracted_pan:
        return False, "Could not extract PAN from GSTIN"

    if extracted_pan.upper() != pan.upper():
        return False, "PAN does not match the PAN embedded in GSTIN"

    return True, None


# Test function for development
if __name__ == "__main__":
    # Test GSTIN
    print("Testing GSTIN validation:")
    valid_gstin = "29ABCDE1234F1Z5"
    invalid_gstin = "29ABCDE1234"
    print(f"  Valid GSTIN: {validate_gstin(valid_gstin)}")
    print(f"  Invalid GSTIN: {validate_gstin(invalid_gstin)}")

    # Test PAN
    print("\nTesting PAN validation:")
    valid_pan = "ABCDE1234F"
    invalid_pan = "ABCDE1234"
    print(f"  Valid PAN: {validate_pan(valid_pan)}")
    print(f"  Invalid PAN: {validate_pan(invalid_pan)}")

    # Test PAN extraction from GSTIN
    print("\nTesting PAN extraction:")
    print(f"  Extracted PAN: {extract_pan_from_gstin(valid_gstin)}")

    # Test linkage
    print("\nTesting GSTIN-PAN linkage:")
    print(f"  Matching PAN: {validate_gstin_pan_linkage(valid_gstin, 'ABCDE1234F')}")
    print(f"  Non-matching PAN: {validate_gstin_pan_linkage(valid_gstin, 'ZZZZZ9999Z')}")
