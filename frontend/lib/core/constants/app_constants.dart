/// Application-wide Constants
class AppConstants {
  // Authentication Methods
  static const String authMethodEmail = 'email';
  static const String authMethodSecurityQuestions = 'security_questions';

  // Company Types
  static const String companyTypeExisting = 'existing';
  static const String companyTypeNew = 'new';

  // User Status
  static const String userStatusPending = 'pending_verification';
  static const String userStatusActive = 'active';
  static const String userStatusInactive = 'inactive';
  static const String userStatusLocked = 'locked';

  // Routes
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeVerifyEmail = '/verify-email';
  static const String routeSecurityQuestions = '/security-questions';
  static const String routeCompanySelection = '/company-selection';
  static const String routeCompanySearch = '/company-search';
  static const String routeCompanyCreate = '/company-create';
  static const String routeDashboard = '/dashboard';

  // Error Messages
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorUnknown = 'An unexpected error occurred. Please try again.';
  static const String errorInvalidCredentials = 'Invalid username or password.';
  static const String errorAccountLocked = 'Account is locked. Please try again later.';
  static const String errorEmailNotVerified = 'Please verify your email before logging in.';

  // Success Messages
  static const String successSignupEmail = 'Signup successful! Please check your email for verification link.';
  static const String successSignupSecurity = 'Signup successful! You can now login.';
  static const String successEmailVerified = 'Email verified successfully! You can now login.';
  static const String successLogin = 'Login successful!';

  // Validation Messages
  static const String validationRequired = 'This field is required';
  static const String validationEmail = 'Please enter a valid email address';
  static const String validationUsername = 'Username must be 3-50 alphanumeric characters';
  static const String validationPassword = 'Password must be at least 8 characters with uppercase, lowercase, and digit';
  static const String validationPasswordMismatch = 'Passwords do not match';
  static const String validationPhone = 'Please enter a valid phone number';

  // UI Text
  static const String loginTitle = 'Login';
  static const String signupTitle = 'Sign Up';
  static const String welcomeMessage = 'Welcome to Fleet Management System';
  static const String loginButton = 'Login';
  static const String signupButton = 'Sign Up';
  static const String emailLabel = 'Email';
  static const String usernameLabel = 'Username';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String phoneLabel = 'Phone Number';
  static const String fullNameLabel = 'Full Name';

  // Security Questions Count
  static const int requiredSecurityQuestions = 3;

  // Timeouts
  static const int loginTimeoutSeconds = 30;
  static const int apiTimeoutSeconds = 30;
}
