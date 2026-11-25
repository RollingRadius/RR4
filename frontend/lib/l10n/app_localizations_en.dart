// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLoading => 'Please wait...';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose English or Hindi';

  @override
  String get apiErrorCancelled => 'Request cancelled';

  @override
  String get apiErrorCannotConnect =>
      'Cannot connect to server. Please check your connection.';

  @override
  String get apiErrorNetwork => 'Network error. Please check your connection.';

  @override
  String apiErrorServer(String code) {
    return 'Server error: $code';
  }

  @override
  String get apiErrorTimeout => 'Connection timeout. Please try again.';

  @override
  String get apiErrorUnexpected => 'An unexpected error occurred';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authEmail => 'Email';

  @override
  String get authFieldRequired => 'This field is required';

  @override
  String get authPassword => 'Password';

  @override
  String get authPhoneNumber => 'Phone Number';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authUnknownError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get authUsername => 'Username';

  @override
  String get authVerifyEmail => 'Verify Email';

  @override
  String get codeVerifyExpiry => 'Code expires in 24 hours';

  @override
  String get codeVerifyFailed => 'Verification failed';

  @override
  String get codeVerifyHeading => 'Enter Verification Code';

  @override
  String get codeVerifyIncomplete => 'Please enter the complete 6-digit code';

  @override
  String get codeVerifyInstruction =>
      'Enter the code below to verify your email';

  @override
  String codeVerifySentTo(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get codeVerifySuccess => 'Email verified successfully!';

  @override
  String get emailVerifyCodeHint => 'Enter the code from your email';

  @override
  String get emailVerifyCodeLabel => 'Verification Code';

  @override
  String get emailVerifyCodeTooShort =>
      'Verification code must be at least 6 characters';

  @override
  String get emailVerifyEnterCode =>
      'Please enter the verification code from your email below.';

  @override
  String emailVerifyError(String error) {
    return 'Error: $error';
  }

  @override
  String get emailVerifyFailed => 'Verification failed. Please try again.';

  @override
  String get emailVerifyHeading => 'Verify Your Email';

  @override
  String get emailVerifyResend => 'Didn\'t receive the code? Resend';

  @override
  String get emailVerifyResent => 'Verification email resent!';

  @override
  String get emailVerifySentTo => 'We sent a verification code to:';

  @override
  String get emailVerifyVerified =>
      'Email verified successfully! You can now login.';

  @override
  String get loginBiometricSoon => 'Biometric login coming soon';

  @override
  String get loginBiometricTooltip => 'Biometric Login';

  @override
  String get loginButton => 'Login to Fleet';

  @override
  String get loginCompleteProfile => 'Please complete your profile to continue';

  @override
  String get loginCorporateId => 'Corporate ID';

  @override
  String get loginCorporateSoon => 'Corporate SSO coming soon';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginGoogleSoon => 'Google SSO coming soon';

  @override
  String get loginHelpCenter => 'Help Center';

  @override
  String get loginNewToFleet => 'New to the fleet? ';

  @override
  String get loginOrContinueWith => 'Or continue with';

  @override
  String get loginPendingMessage =>
      'Wait for acceptance by company owner.\n\nOnce the company owner accepts your request, you will be able to log in.';

  @override
  String get loginPendingTitle => 'Pending Approval';

  @override
  String get loginSubtitle => 'Securely access your fleet dashboard';

  @override
  String get loginSuccess => 'Login successful!';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginUsernameHint => 'Enter your username';

  @override
  String get loginWelcome => 'Welcome back to RR';

  @override
  String get signupAcceptTerms => 'Please accept the terms and conditions';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get signupConfirmPassword => 'Confirm Password';

  @override
  String get signupConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get signupCreateAccount => 'Create Account';

  @override
  String get signupEmailInvalid =>
      'Enter a valid email — e.g. name@company.com';

  @override
  String get signupEmailNoAt =>
      'Email must contain \"@\" — e.g. name@company.com';

  @override
  String get signupEmailNoDomain =>
      'Email must have a domain ending — e.g. .com or .in';

  @override
  String get signupEmailRequired => 'Email is required';

  @override
  String get signupFullName => 'Full Name';

  @override
  String get signupFullNameHint => 'John Doe';

  @override
  String get signupFullNameNoNumbers =>
      'Do not enter numbers in full name — letters only';

  @override
  String get signupFullNameRequired => 'Full name is required';

  @override
  String get signupFullNameTooShort =>
      'Full name must be at least 2 characters';

  @override
  String get signupLogIn => 'Log In';

  @override
  String get signupPasswordMismatch =>
      'Passwords do not match — please re-enter';

  @override
  String get signupPasswordRequired => 'Password is required';

  @override
  String get signupPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get signupPhoneChecking =>
      'Please wait — checking phone number availability';

  @override
  String get signupPhoneLength => 'Mobile number must be exactly 10 digits';

  @override
  String get signupPhoneRequired => 'Phone number is required';

  @override
  String get signupPhoneTaken => 'This phone number is already registered';

  @override
  String get signupSecurityQ => 'Security Q';

  @override
  String get signupSuccessEmail =>
      'Signup successful! Please check your email for verification link.';

  @override
  String get signupTermsAnd => ' and ';

  @override
  String get signupTermsOfService => 'Terms of Service';

  @override
  String get signupTermsPrefix =>
      'By clicking Create Account, you agree to our ';

  @override
  String get signupTermsSuffix => '.';

  @override
  String get signupUsernameChecking =>
      'Please wait — checking username availability';

  @override
  String get signupUsernameHint => 'e.g. johndoe or john99';

  @override
  String get signupUsernameInvalid =>
      'Username can only contain letters, numbers, and underscores';

  @override
  String get signupUsernameRequired => 'Username is required';

  @override
  String get signupUsernameTaken => 'This username is already taken';

  @override
  String get signupUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get signupWorkEmail => 'Work Email';

  @override
  String get authAnswerAllQuestions => 'Please answer all security questions';

  @override
  String get authAnswerSecurityQuestions => 'Answer Your Security Questions';

  @override
  String get authEnterAnswer => 'Enter your answer';

  @override
  String get authNewPassword => 'New Password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authPasswordRule =>
      'Password must be at least 8 characters with uppercase, lowercase, and digit';

  @override
  String authQuestionNumber(int n) {
    return 'Question $n';
  }

  @override
  String get changePwConfirmNew => 'Confirm New Password';

  @override
  String get changePwFailed => 'Failed to change password';

  @override
  String get changePwIntro =>
      'Answer your security questions and set a new password. You will be signed out of every device and need to log in again.';

  @override
  String get changePwNoUsername =>
      'Could not determine your username. Please try again.';

  @override
  String get changePwSuccess => 'Password changed. Please log in again.';

  @override
  String get changePwTitle => 'Change Password';

  @override
  String get pwRecoveryComingSoon => 'Coming Soon';

  @override
  String get pwRecoveryConfirmPassword => 'Confirm Password';

  @override
  String get pwRecoveryEmailComingSoon =>
      'Email-based password recovery is under development. Please use Security Questions to reset your password for now.';

  @override
  String get pwRecoveryEnterUsername => 'Please enter your username';

  @override
  String get pwRecoveryHeading => 'Forgot Your Password?';

  @override
  String get pwRecoveryLoadQuestions => 'Load Security Questions';

  @override
  String get pwRecoveryMethod => 'Recovery Method';

  @override
  String get pwRecoveryMethodEmail => 'Email';

  @override
  String get pwRecoveryMethodQuestions => 'Security Questions';

  @override
  String get pwRecoveryResetButton => 'Reset Password';

  @override
  String get pwRecoveryResetSuccess =>
      'Password reset successful! Please login with your new password.';

  @override
  String get pwRecoverySessionExpired => 'Session expired. Please start over.';

  @override
  String get pwRecoverySetNewPassword => 'Set New Password';

  @override
  String get pwRecoverySubtitle =>
      'Reset your password using your security questions';

  @override
  String get pwRecoveryTitle => 'Password Recovery';

  @override
  String get pwRecoveryUseQuestions => 'Use Security Questions Instead';

  @override
  String get pwRecoveryUsername => 'Username';

  @override
  String get pwRecoveryUsernameInfo =>
      'Enter your username and we\'ll show you your security questions.';

  @override
  String get pwRecoveryVerifyAnswers => 'Verify Answers';

  @override
  String get secQuestionsAnswerMin => 'Answer must be at least 2 characters';

  @override
  String get secQuestionsEncrypted => 'END-TO-END ENCRYPTED';

  @override
  String get secQuestionsIntro =>
      'Choose three security questions to verify your identity if you lose access to your account.';

  @override
  String get secQuestionsSaved => 'Security questions saved!';

  @override
  String get secQuestionsSelectAll => 'Please select all 3 security questions';

  @override
  String get secQuestionsSelectDifferent =>
      'Please select 3 different security questions';

  @override
  String get secQuestionsSelectError => 'Please select a question';

  @override
  String get secQuestionsSelectHint => 'Select a security question';

  @override
  String secQuestionsStepOf(int step) {
    return 'Step $step of 4';
  }

  @override
  String get secQuestionsTitle => 'Secure Your Account';

  @override
  String get secQuestionsYourAnswer => 'Your answer';

  @override
  String get userRecoveryAnswerPrompt =>
      'Please answer the following questions to verify your identity';

  @override
  String get userRecoveryContinueToLogin => 'Continue to Login';

  @override
  String get userRecoveryEnterDetails => 'Enter Your Details';

  @override
  String get userRecoveryFullName => 'Full Name';

  @override
  String get userRecoveryFullNameHint => 'Enter your registered full name';

  @override
  String get userRecoveryHeading => 'Forgot Your Username?';

  @override
  String get userRecoveryInfo =>
      'You will need to answer your security questions to verify your identity.';

  @override
  String get userRecoveryPhone => 'Phone Number';

  @override
  String get userRecoveryPhoneHint => 'Enter your registered phone number';

  @override
  String get userRecoveryRecovered => 'Username Recovered!';

  @override
  String get userRecoverySaveNote =>
      'Please save this username for future reference';

  @override
  String get userRecoverySubtitle =>
      'We\'ll help you recover your username by verifying your identity';

  @override
  String get userRecoveryTitle => 'Username Recovery';

  @override
  String get userRecoveryVerifyButton => 'Verify & Recover Username';

  @override
  String get userRecoveryYourUsernameIs => 'Your username is:';

  @override
  String get companyCreateAddressLabel => 'Address *';

  @override
  String get companyCreateBusinessType => 'Business Type *';

  @override
  String get companyCreateBusinessTypeError =>
      'Please select at least one business type';

  @override
  String get companyCreateButton => 'Create Company';

  @override
  String get companyCreateCityLabel => 'City *';

  @override
  String get companyCreateCountryLabel => 'Country *';

  @override
  String get companyCreateEmailInvalid =>
      'Enter a valid email, for example name@company.com';

  @override
  String get companyCreateEmailLabel => 'Business Email *';

  @override
  String get companyCreateEmailNoAt =>
      'Email must contain @, for example name@company.com';

  @override
  String get companyCreateEmailNoDomain =>
      'Email must have a domain ending, for example .com or .in';

  @override
  String get companyCreateEmailRequired => 'Business email is required';

  @override
  String get companyCreateFailed => 'Company creation failed';

  @override
  String get companyCreateGstinHint => '15-character GSTIN';

  @override
  String get companyCreateGstinInvalid => 'Invalid GSTIN format';

  @override
  String get companyCreateGstinLabel => 'GSTIN (Optional)';

  @override
  String get companyCreateGstinLength => 'GSTIN must be exactly 15 characters';

  @override
  String get companyCreateHeading => 'Register Your Company';

  @override
  String get companyCreateHide => 'Hide';

  @override
  String get companyCreateInvalidDetails => 'Invalid company details';

  @override
  String get companyCreateLegalHint =>
      'You can add GSTIN and PAN details now or later from company settings';

  @override
  String get companyCreateLoDesc =>
      'Posts load requirements and seeks transport';

  @override
  String get companyCreateLpDesc =>
      'Manages a fleet and fulfills load requirements';

  @override
  String get companyCreateNameLabel => 'Company Name *';

  @override
  String get companyCreatePanHint => '10-character PAN';

  @override
  String get companyCreatePanInvalid => 'Invalid PAN format';

  @override
  String get companyCreatePanLabel => 'PAN Number (Optional)';

  @override
  String get companyCreatePanLength => 'PAN must be exactly 10 characters';

  @override
  String get companyCreatePhoneLabel => 'Business Phone *';

  @override
  String get companyCreatePhoneLength =>
      'Mobile number must be exactly 10 digits';

  @override
  String get companyCreatePhoneRequired => 'Business phone is required';

  @override
  String get companyCreatePincodeInvalid =>
      'Enter a valid 6-digit Indian pincode';

  @override
  String get companyCreatePincodeLabel => 'Pincode *';

  @override
  String get companyCreateSectionAddress => 'Address Information';

  @override
  String get companyCreateSectionCompany => 'Company Information';

  @override
  String get companyCreateSectionLegal => 'Legal Information (Optional)';

  @override
  String get companyCreateShow => 'Show';

  @override
  String get companyCreateStateLabel => 'State *';

  @override
  String get companyCreateSubheading =>
      'You will become the company Owner with full administrative access.';

  @override
  String get companyCreateSuccess =>
      'Company created successfully! You are now the Owner.';

  @override
  String get companyCreateTitle => 'Create Company';

  @override
  String get companySearchEmptyHint => 'Enter at least 3 characters to search';

  @override
  String get companySearchEmptyTitle => 'Search for a company';

  @override
  String get companySearchError => 'Error searching companies';

  @override
  String get companySearchHintDefault =>
      'Search by company name (min 3 characters)';

  @override
  String get companySearchHintLo => 'Search load owner companies...';

  @override
  String get companySearchHintLp => 'Search logistic partner companies...';

  @override
  String get companySearchJoinButton => 'Join';

  @override
  String get companySearchJoinNotice =>
      'You will be added as a Pending User. The company owner must approve your request.';

  @override
  String get companySearchJoinPrompt => 'You want to join:';

  @override
  String get companySearchJoinTitle => 'Join Company';

  @override
  String get companySearchKeepTyping => 'Keep typing...';

  @override
  String get companySearchMinChars => 'Minimum 3 characters required';

  @override
  String get companySearchNoResults => 'No companies found';

  @override
  String get companySearchRegisterFailed => 'Registration failed';

  @override
  String get companySearchRegisterSuccess =>
      'Registration successful! You are now a Pending User. Please wait for approval.';

  @override
  String get companySearchTitle => 'Search Company';

  @override
  String get companySearchTryOther => 'Try a different search term';

  @override
  String get companySelectCreateDesc =>
      'Register your company and become the Owner. You will have full control over your company and can invite team members.';

  @override
  String get companySelectCreateTitle => 'Create New Company';

  @override
  String get companySelectHeading => 'Company Association';

  @override
  String get companySelectJoinDesc =>
      'Search and join an existing company. You will be added as a Pending User until approved by the company owner.';

  @override
  String get companySelectJoinTitle => 'Join Existing Company';

  @override
  String get companySelectSkipDesc =>
      'Continue as an Independent User without company affiliation. You can join or create a company later from your profile.';

  @override
  String get companySelectSkipDialogBody =>
      'You will be registered as an Independent User. You can join or create a company later from your profile settings.\n\nContinue?';

  @override
  String get companySelectSkipDialogTitle => 'Skip Company Selection';

  @override
  String get companySelectSkipDone =>
      'Registration completed! You can now login as an Independent User.';

  @override
  String get companySelectSkipTitle => 'Skip for Now';

  @override
  String get companySelectSubheading =>
      'Choose how you want to proceed with your account';

  @override
  String get companySelectTitle => 'Company Selection';

  @override
  String get profileCompleteAddress => 'Address';

  @override
  String get profileCompleteAddressMin =>
      'Address must be at least 5 characters';

  @override
  String get profileCompleteBusinessAddressHint => 'Your business address';

  @override
  String get profileCompleteBusinessEmail => 'Business Email';

  @override
  String get profileCompleteBusinessPhone => 'Business Phone';

  @override
  String get profileCompleteButton => 'Complete Profile';

  @override
  String get profileCompleteCategoryHint =>
      'Select the category that best describes your business';

  @override
  String get profileCompleteChooseRole => 'Choose Your Role';

  @override
  String get profileCompleteCity => 'City';

  @override
  String get profileCompleteComingSoon => 'Coming Soon';

  @override
  String get profileCompleteCreateCompany => 'Create Company';

  @override
  String get profileCompleteCreateCompanyDesc =>
      'Register your company and become the Logistic Partner';

  @override
  String get profileCompleteDriverDesc =>
      'Register as a driver with license information';

  @override
  String get profileCompleteDriverInfo => 'Driver Information';

  @override
  String get profileCompleteEnterCompanyName => 'Please enter company name';

  @override
  String get profileCompleteEnterLicense => 'Please enter your license number';

  @override
  String get profileCompleteEnterLicenseExpiry =>
      'Please enter your license expiry date';

  @override
  String get profileCompleteEnterPan => 'Please enter your PAN Card Number';

  @override
  String get profileCompleteEnterYourCompanyName =>
      'Please enter your company name';

  @override
  String get profileCompleteFailed => 'Failed to complete profile';

  @override
  String get profileCompleteFieldExecutiveDesc =>
      'Manage trip stages and fleet status on the ground';

  @override
  String get profileCompleteGstOptional => 'GST Number (optional)';

  @override
  String get profileCompleteIndependentDesc =>
      'Use basic features without company affiliation';

  @override
  String get profileCompleteJoinTransporter => 'Join as Transporter';

  @override
  String get profileCompleteJoinTransporterDesc =>
      'Register as an independent transporter to upload loading slips for assigned trips';

  @override
  String get profileCompleteJoinWorker => 'Join as Worker';

  @override
  String get profileCompleteJoinWorkerDesc =>
      'Join an existing company as a worker (requires owner approval)';

  @override
  String get profileCompleteLicenseExpiry =>
      'License Expiry Date (YYYY-MM-DD) *';

  @override
  String get profileCompleteLicenseNumber => 'License Number *';

  @override
  String get profileCompleteLoCompany => 'Load Owner Company';

  @override
  String get profileCompleteLoCompanyWorkDesc => 'Work at a cargo/load company';

  @override
  String get profileCompleteLoadProviderCompany => 'Load Provider Company';

  @override
  String get profileCompleteLoadProviderDesc =>
      'You have cargo/goods that need to be transported';

  @override
  String get profileCompleteLoadReceiverCompany => 'Load Receiver Company';

  @override
  String get profileCompleteLoadReceiverDesc =>
      'You receive deliveries — you are the consignee';

  @override
  String get profileCompleteLpCompany => 'Logistic Partner Company';

  @override
  String get profileCompleteLpCompanyCreateDesc =>
      'You manage a fleet of vehicles for transportation — your role: Logistic Partner';

  @override
  String get profileCompleteLpCompanyWorkDesc =>
      'Work at a fleet/logistics company (Field Executive or RR Operations)';

  @override
  String get profileCompletePanLabel => 'PAN Card Number *';

  @override
  String get profileCompletePermanentWarning =>
      'This decision is permanent and cannot be changed later.';

  @override
  String get profileCompletePincode => 'Pincode (6 digits)';

  @override
  String get profileCompleteRequestSent =>
      'Request sent! Wait for acceptance by the company owner.';

  @override
  String get profileCompleteRrOpsDesc =>
      'Handle RR sync and trip data entry in the RR system';

  @override
  String get profileCompleteSearchCompany => 'Search Company';

  @override
  String profileCompleteSearchFailed(String error) {
    return 'Failed to search companies: $error';
  }

  @override
  String get profileCompleteSearchHint => 'Enter at least 3 characters';

  @override
  String get profileCompleteSelectCompanyToJoin =>
      'Please select a company to join';

  @override
  String get profileCompleteSelectCompanyType => 'Please select a company type';

  @override
  String get profileCompleteSelectCompanyTypeTitle => 'Select Company Type';

  @override
  String get profileCompleteSelectRole => 'Please select a role type';

  @override
  String get profileCompleteSelectWorkerType =>
      'Please select your worker type';

  @override
  String get profileCompleteSelectYourRole => 'Select Your Role';

  @override
  String profileCompleteSelectedCompany(String name) {
    return 'Selected: $name';
  }

  @override
  String get profileCompleteSessionExpired =>
      'Session expired. Please log in again.';

  @override
  String get profileCompleteState => 'State';

  @override
  String get profileCompleteSuccess => 'Profile completed successfully!';

  @override
  String get profileCompleteTitle => 'Complete Your Profile';

  @override
  String get profileCompleteTransporterCompanyHint =>
      'Your transport company name';

  @override
  String get profileCompleteTransporterDetails => 'Transporter Details';

  @override
  String get profileCompleteTransporterSub =>
      'Enter your transport business details';

  @override
  String get profileCompleteWhatCompanyType =>
      'What type of company are you registering?';

  @override
  String get profileCompleteWhatWillYouDo =>
      'What will you do at the logistics company?';

  @override
  String get profileCompleteWorkForWhichType =>
      'Which type of company do you want to work for?';

  @override
  String get roleDriver => 'Driver';

  @override
  String get roleFieldExecutive => 'Field Executive';

  @override
  String get roleIndependentUser => 'Independent User';

  @override
  String get roleLoadOwner => 'Load Owner';

  @override
  String get roleLogisticPartner => 'Logistic Partner';

  @override
  String get roleRrOperations => 'RR Operations';

  @override
  String get ongoingCardActive => 'Active';

  @override
  String get ongoingCardAmount => 'AMOUNT';

  @override
  String get ongoingCardBiltyNo => 'BILTY NO.';

  @override
  String get ongoingCardCompleteBody =>
      'This will mark the trip as completed and notify the load owner. This action cannot be undone.';

  @override
  String get ongoingCardCompleteDone =>
      'Trip marked as completed. Load owner notified.';

  @override
  String get ongoingCardCompleteLocked =>
      'Complete Trip is only available after Stage 5';

  @override
  String get ongoingCardCompleteTitle => 'Complete Trip?';

  @override
  String get ongoingCardCompleteTrip => 'Complete Trip';

  @override
  String get ongoingCardConfirm => 'Confirm';

  @override
  String get ongoingCardDone => 'Done';

  @override
  String get ongoingCardFailed => 'Failed';

  @override
  String ongoingCardGoToStage(String stage, String name) {
    return 'Go to Stage $stage  ·  $name';
  }

  @override
  String ongoingCardInTransitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips in transit',
      one: '1 trip in transit',
    );
    return '$_temp0';
  }

  @override
  String get ongoingCardInvoice => 'INVOICE';

  @override
  String get ongoingCardLoadItem => 'LOAD ITEM';

  @override
  String get ongoingCardLocateTrip => 'Locate Trip';

  @override
  String get ongoingCardNoVehicle => 'No Vehicle';

  @override
  String get ongoingCardOngoingTrips => 'Ongoing Trips';

  @override
  String get ongoingCardRrSync => 'RR Sync';

  @override
  String get ongoingCardStage0CompleteS1 => 'Stage 0 · Complete S1 to sync RR';

  @override
  String get ongoingCardStage0NotSynced => 'Stage 0 · Not synced to RR';

  @override
  String get ongoingCardStageComplianceCheck => 'Compliance Check';

  @override
  String get ongoingCardStageDieselReceipt => 'Diesel Receipt';

  @override
  String get ongoingCardStageExitCheck => 'Exit Check';

  @override
  String get ongoingCardStageFactoryArrival => 'Factory Arrival';

  @override
  String get ongoingCardStageTruckRegistration => 'Truck Registration';

  @override
  String get ongoingCardSyncFailed => 'RR sync failed';

  @override
  String get ongoingCardTripCompleted => 'Trip Completed';

  @override
  String get ongoingCardTripNumber => 'TRIP NUMBER';

  @override
  String get ongoingCardViewAll => 'View all';

  @override
  String get ongoingCardViewDetails => 'View Details';

  @override
  String get ongoingCardWeight => 'WEIGHT';

  @override
  String get recvDocsAttachImageRequired =>
      'Please attach the receiving sheet image';

  @override
  String get recvDocsAttachPhoto => 'Attach receiving sheet photo';

  @override
  String recvDocsBy(String name) {
    return 'By $name';
  }

  @override
  String get recvDocsChooseGallery => 'Choose from Gallery';

  @override
  String get recvDocsDate => 'Date';

  @override
  String get recvDocsDeleteBody =>
      'This permanently removes the image and cannot be undone.';

  @override
  String recvDocsDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get recvDocsDeleteTitle => 'Delete receiving doc?';

  @override
  String get recvDocsEditTitle => 'Edit Receiving Doc';

  @override
  String get recvDocsEmpty => 'No receiving docs uploaded yet';

  @override
  String get recvDocsEmptyForDate => 'No receiving docs found for that date';

  @override
  String recvDocsLoadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get recvDocsOpenDownload => 'Open / Download';

  @override
  String get recvDocsPickDate => 'Pick a date';

  @override
  String get recvDocsPickDateRequired =>
      'Please pick the date this receiving sheet is for';

  @override
  String recvDocsPickImageFailed(String error) {
    return 'Could not pick image: $error';
  }

  @override
  String get recvDocsSaveChanges => 'Save Changes';

  @override
  String get recvDocsSearchByDate => 'Search by date';

  @override
  String get recvDocsSheetDate => 'Date this sheet is for';

  @override
  String get recvDocsTakePhoto => 'Take Photo';

  @override
  String get recvDocsTitle => 'Receiving Docs';

  @override
  String get recvDocsUpload => 'Upload';

  @override
  String get recvDocsUploadNew => 'Upload New';

  @override
  String get recvDocsUploadTitle => 'Upload Receiving Doc';

  @override
  String get recvDocsUploadedBy => 'Uploaded by';

  @override
  String get recvDocsViewTitle => 'Receiving Doc';

  @override
  String get rrConnectionActionConnect => '· Connect';

  @override
  String get rrConnectionActionDisconnect => '· Disconnect';

  @override
  String get rrConnectionConnected => 'Connected';

  @override
  String get rrConnectionDisconnect => 'Disconnect';

  @override
  String get rrConnectionDisconnectBody =>
      'Sync and pre-fill will stop working for everyone at your company until someone reconnects.';

  @override
  String get rrConnectionDisconnectTitle => 'Disconnect from RR?';

  @override
  String get rrConnectionDisconnected => 'Disconnected';

  @override
  String get rrConnectionExpiringSoon => 'Expiring Soon';

  @override
  String get rrLoginButton => 'Sign in';

  @override
  String get rrLoginEnterCredentials => 'Enter your RR username and password';

  @override
  String get rrLoginFailed => 'Login failed';

  @override
  String get rrLoginSubtitle =>
      'Enter your RollingRadius credentials to continue.';

  @override
  String get rrLoginTitle => 'Sign in to RR';

  @override
  String rrLoginUnexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get rrLoginUsernameLabel => 'Username / Phone';

  @override
  String get rrSearchNoMatches => 'No matches found';

  @override
  String get tripCardAllowFeStage1 => 'Allow FE to fill Stage 1';

  @override
  String get tripCardAlreadyInRecords => 'Already in Records';

  @override
  String get tripCardAwaitCompanyConfirm =>
      'Let this trip get confirmed by your company';

  @override
  String tripCardBiltyNo(String number) {
    return 'Bilty No: $number';
  }

  @override
  String get tripCardBookingConfirmFailed => 'Could not confirm booking';

  @override
  String get tripCardBookingConfirmed => 'Booking confirmed';

  @override
  String get tripCardBookingNeedsConfirm => 'Booking needs confirmation';

  @override
  String get tripCardCompletedViewOnly => 'Completed trips are view only';

  @override
  String get tripCardConfirmBooking => 'Confirm Booking';

  @override
  String tripCardCreated(String when) {
    return 'Created $when';
  }

  @override
  String get tripCardDismiss => 'Dismiss';

  @override
  String get tripCardEditTrip => 'Edit trip';

  @override
  String get tripCardLabelAxleType => 'Axle Type';

  @override
  String get tripCardLabelBiltyNumber => 'Bilty Number';

  @override
  String get tripCardLabelBodyType => 'Body Type';

  @override
  String get tripCardLabelConsignee => 'Consignee';

  @override
  String get tripCardLabelConsigneeGstin => 'Consignee GSTIN';

  @override
  String get tripCardLabelConsignor => 'Consignor';

  @override
  String get tripCardLabelConsignorGstin => 'Consignor GSTIN';

  @override
  String get tripCardLabelCreatedAt => 'Created At';

  @override
  String get tripCardLabelDepotCode => 'Depot Code';

  @override
  String get tripCardLabelDescription => 'Description';

  @override
  String get tripCardLabelMaterial => 'Material';

  @override
  String get tripCardLabelPartLoad => 'Part Load';

  @override
  String get tripCardLabelPickupAddress => 'Pickup Address';

  @override
  String get tripCardLabelTotalInvoiceValue => 'Total Invoice Value';

  @override
  String get tripCardLabelUnloadAddress => 'Unload Address';

  @override
  String get tripCardLabelVehicle => 'Vehicle';

  @override
  String get tripCardLabelWeight => 'Weight';

  @override
  String get tripCardLabelWheels => 'Wheels';

  @override
  String get tripCardMoveToRecords => 'Move to Records';

  @override
  String get tripCardMoveToRecordsFailed => 'Could not move trip to Records';

  @override
  String get tripCardMovedToRecords => 'Trip moved to Records';

  @override
  String tripCardResumeConflict(String driver) {
    return 'Cannot resume — $driver has already been assigned to a new trip';
  }

  @override
  String get tripCardResumeFailed => 'Could not resume driver tracking';

  @override
  String get tripCardResumeTracking => 'Resume Driver Tracking for this Trip';

  @override
  String get tripCardRetryBookingFailed =>
      'Could not retry booking — try again';

  @override
  String get tripCardStillFailing => 'Still failing — check back or try again';

  @override
  String tripCardStillFailingWith(String error) {
    return 'Still failing: $error';
  }

  @override
  String get tripCardStopTracking => 'Stop Driver Tracking for this Trip';

  @override
  String tripCardStopTrackingBody(String driver) {
    return 'This will release $driver from this trip so they can be assigned to a new trip. You can resume tracking for this trip later, but only if this driver has not already been assigned to a new trip by then. Continue?';
  }

  @override
  String get tripCardStopTrackingButton => 'Stop Tracking';

  @override
  String get tripCardStopTrackingFailed => 'Could not stop driver tracking';

  @override
  String get tripCardStopTrackingTitle => 'Stop Driver Tracking';

  @override
  String get tripCardSyncedToRr => 'Synced to RR';

  @override
  String get tripCardTheDriver => 'the driver';

  @override
  String get tripCardThisDriver => 'this driver';

  @override
  String get tripCardTrackDriver => 'Track Driver Location';

  @override
  String get tripCardTrackingResumed => 'Driver tracking resumed for this trip';

  @override
  String get tripCardTrackingStopped => 'Driver tracking stopped for this trip';

  @override
  String get tripCardTripInfo => 'Trip Info';

  @override
  String get tripCardUpdateFailed => 'Failed to update — try again';

  @override
  String get tripSearchHint => 'Search by trip number';

  @override
  String get tripStatusCancelled => 'Cancelled';

  @override
  String get tripStatusCompleted => 'Completed';

  @override
  String get tripStatusInTransit => 'In Transit';

  @override
  String get tripStatusOngoing => 'Ongoing';

  @override
  String get tripStatusPending => 'Pending';

  @override
  String get driverAssignedDriver => 'DRIVER';

  @override
  String get driverAssignedGoToTrip => 'Go to Trip Assignment';

  @override
  String get driverAssignedHeading => 'Vehicle Assigned Successfully';

  @override
  String get driverAssignedReturn => 'Return to Fleet Overview';

  @override
  String get driverAssignedSubtitle =>
      'The driver and vehicle are now linked in the system and ready for dispatch.';

  @override
  String get driverAssignedTitle => 'Confirmation';

  @override
  String driverAssignedUnitId(String id) {
    return 'UNIT ID: $id';
  }

  @override
  String get driverAssignedVehicle => 'VEHICLE';

  @override
  String get driverAssignedViewVehicle => 'View Vehicle Details';

  @override
  String get driverDashBAddress => 'Address';

  @override
  String get driverDashBAge => 'Age';

  @override
  String driverDashBAgeYears(int years) {
    return '$years years';
  }

  @override
  String get driverDashBAssignedBy => 'Assigned by';

  @override
  String get driverDashBAssignedOn => 'Assigned on';

  @override
  String get driverDashBAssignedVehicle => 'Assigned Vehicle';

  @override
  String get driverDashBAuthority => 'Authority';

  @override
  String get driverDashBClass => 'Class';

  @override
  String get driverDashBCountry => 'Country';

  @override
  String get driverDashBDob => 'Date of Birth';

  @override
  String get driverDashBEmail => 'Email';

  @override
  String get driverDashBEmergencyContact => 'Emergency Contact';

  @override
  String get driverDashBEmployeeId => 'Employee ID';

  @override
  String driverDashBEmployeeIdShort(String id) {
    return 'ID: $id';
  }

  @override
  String get driverDashBExpired => 'Expired';

  @override
  String driverDashBExpiringIn(int days) {
    return 'Expiring in $days days';
  }

  @override
  String get driverDashBExpiryDate => 'Expiry Date';

  @override
  String get driverDashBFuel => 'Fuel';

  @override
  String get driverDashBFuelReceipt => 'Fuel\nReceipt';

  @override
  String get driverDashBFullName => 'Full Name';

  @override
  String get driverDashBIssueDate => 'Issue Date';

  @override
  String get driverDashBIssuingState => 'Issuing State';

  @override
  String get driverDashBLicenseDetails => 'License Details';

  @override
  String driverDashBLicenseExpiredOn(String date) {
    return 'License expired on $date';
  }

  @override
  String driverDashBLicenseExpiresOn(String date) {
    return 'License expires on $date — renew soon';
  }

  @override
  String get driverDashBLicenseNumber => 'License Number';

  @override
  String get driverDashBName => 'Name';

  @override
  String get driverDashBNoEmergency => 'No emergency contact on file';

  @override
  String get driverDashBNoLicense => 'No license on file';

  @override
  String get driverDashBNoVehicle => 'No vehicle assigned';

  @override
  String get driverDashBNotFound => 'Driver not found';

  @override
  String get driverDashBPersonalInfo => 'Personal Information';

  @override
  String get driverDashBPhone => 'Phone';

  @override
  String get driverDashBQuickActions => 'QUICK ACTIONS';

  @override
  String get driverDashBRegNo => 'Reg No';

  @override
  String get driverDashBRelationship => 'Relationship';

  @override
  String get driverDashBReportIssue => 'Report\nIssue';

  @override
  String get driverDashBSafetyCheck => 'Safety\nCheck';

  @override
  String get driverDashBStatus => 'Status';

  @override
  String get driverDashBTitle => 'Driver';

  @override
  String get driverDashBType => 'Type';

  @override
  String driverDashBValidDaysLeft(int days) {
    return 'Valid ($days days left)';
  }

  @override
  String get driverDashBViewVehicle => 'View Vehicle Details';

  @override
  String get driverOnboardCertDefensive => 'Defensive Driving';

  @override
  String get driverOnboardCertDetails => 'CERTIFICATION DETAILS';

  @override
  String get driverOnboardCertFirstAid => 'First Aid/CPR';

  @override
  String get driverOnboardCertFuel => 'Fuel Efficiency Training';

  @override
  String get driverOnboardCertHazmat => 'HAZMAT Handling';

  @override
  String get driverOnboardCompletionDate => 'COMPLETION DATE';

  @override
  String get driverOnboardCoreCerts => 'CORE CERTIFICATIONS';

  @override
  String get driverOnboardDoneAssignVehicle => 'Assign Vehicle';

  @override
  String get driverOnboardDoneDashboard => 'Go to Dashboard';

  @override
  String get driverOnboardDoneEmployeeId => 'EMPLOYEE ID';

  @override
  String get driverOnboardDoneHeading => 'Driver Added Successfully';

  @override
  String get driverOnboardDoneNotified =>
      'Driver has been notified via email and SMS';

  @override
  String get driverOnboardDoneReady => 'Ready for Assignment';

  @override
  String get driverOnboardDoneStatus => 'STATUS';

  @override
  String get driverOnboardDoneSubtitle =>
      'The driver registration process is complete and verified.';

  @override
  String get driverOnboardDoneViewProfile => 'View Driver Profile';

  @override
  String get driverOnboardExpirationDate => 'EXPIRATION DATE';

  @override
  String get driverOnboardHeading => 'Training & Certifications';

  @override
  String get driverOnboardNextReview => 'Next: Review';

  @override
  String get driverOnboardPercentComplete => '66% Complete';

  @override
  String get driverOnboardSelectDate => 'Select date';

  @override
  String get driverOnboardSkills => 'SPECIALIZED SKILLS';

  @override
  String get driverOnboardSkillsHelp =>
      'List any other relevant qualifications or equipment experience (e.g., forklift license, refrigerated cargo handling).';

  @override
  String get driverOnboardSkillsHint => 'Type your additional skills here...';

  @override
  String get driverOnboardStep => 'STEP 2 OF 3';

  @override
  String get driverOnboardSubtitle =>
      'Please provide details of your professional certifications and specialized skills.';

  @override
  String get driverOnboardTitle => 'Onboarding';

  @override
  String get driverOnboardUploadCert => 'Upload Certificate (PDF/JPG)';

  @override
  String get driverSelectVehicleAssigningTo => 'ASSIGNING TO';

  @override
  String driverSelectVehicleAvailableCount(int count) {
    return '$count Available Vehicles';
  }

  @override
  String get driverSelectVehicleChange => 'Change';

  @override
  String get driverSelectVehicleFilterAll => 'All Units';

  @override
  String get driverSelectVehicleFilterHeavy => 'Heavy Duty';

  @override
  String get driverSelectVehicleFilterLowFuel => 'Low Fuel';

  @override
  String get driverSelectVehicleFilterMedium => 'Medium Duty';

  @override
  String get driverSelectVehicleFuelLevel => 'FUEL LEVEL';

  @override
  String get driverSelectVehicleOdometer => 'ODOMETER';

  @override
  String get driverSelectVehicleSearchHint => 'Search Unit ID, VIN or Model...';

  @override
  String get driverSelectVehicleSelect => 'Select Vehicle';

  @override
  String get driverSelectVehicleSort => 'Sort';

  @override
  String get driverSelectVehicleStatusAvailable => 'Available';

  @override
  String get driverSelectVehicleStatusLowFuel => 'Low Fuel';

  @override
  String get driverSelectVehicleTitle => 'Assign Vehicle';

  @override
  String get driverDashActiveTripBadge => 'ACTIVE TRIP';

  @override
  String get driverDashDetails => 'Details';

  @override
  String get driverDashFrom => 'FROM';

  @override
  String get driverDashGoodAfternoon => 'Good afternoon';

  @override
  String get driverDashGoodEvening => 'Good evening';

  @override
  String get driverDashGoodMorning => 'Good morning';

  @override
  String get driverDashNoActiveTrip => 'No Active Trip';

  @override
  String get driverDashNoOngoingTrips => 'You have no ongoing trips right now.';

  @override
  String get driverDashOngoingWarning =>
      'Your trip is still ongoing — please keep location turned on.';

  @override
  String get driverDashProgress => 'Progress';

  @override
  String get driverDashTapToEnable => 'Tap to Enable';

  @override
  String get driverDashTo => 'TO';

  @override
  String get driverDashTrackingOn => 'Tracking On';

  @override
  String get driverHomeCurrentTrip => 'Current Trip';

  @override
  String get driverHomeDropoff => 'DROPOFF';

  @override
  String driverHomeEta(String time) {
    return 'ETA: $time';
  }

  @override
  String driverHomeGreeting(String name) {
    return 'Good morning, $name 👋';
  }

  @override
  String get driverHomeInProgress => 'IN PROGRESS';

  @override
  String get driverHomeNavigateDropoff => 'Navigate to Dropoff';

  @override
  String get driverHomeOnDuty => 'On Duty';

  @override
  String get driverHomePickup => 'PICKUP';

  @override
  String get driverHomeScheduled => 'Scheduled';

  @override
  String get driverHomeStatDone => 'Done';

  @override
  String get driverHomeStatLeft => 'Left';

  @override
  String get driverHomeStatTotal => 'Total';

  @override
  String get driverHomeTomorrow => 'Tomorrow';

  @override
  String get driverHomeUpcomingTrips => 'Upcoming Trips';

  @override
  String get driverHomeViewAll => 'View All';

  @override
  String get driverVehicleAssignedUnit => 'Assigned Unit';

  @override
  String get driverVehicleAvailable => 'Available';

  @override
  String get driverVehicleBattery => 'Battery';

  @override
  String get driverVehicleBrakeInspection => 'Brake Inspection';

  @override
  String get driverVehicleClassA => 'Class A';

  @override
  String get driverVehicleDiesel => 'Diesel';

  @override
  String get driverVehicleEngineTemp => 'Engine Temp';

  @override
  String get driverVehicleFuelLevel => 'Fuel Level';

  @override
  String get driverVehicleHeavyDuty => 'Heavy Duty';

  @override
  String get driverVehicleLastOilChange => 'Last Oil Change';

  @override
  String get driverVehicleLogRefuel => 'Log Refuel';

  @override
  String get driverVehicleMaintenanceStatus => 'Maintenance Status';

  @override
  String get driverVehicleNextServiceDue => 'Next Service Due';

  @override
  String get driverVehicleNormal => 'Normal';

  @override
  String get driverVehicleOdometer => 'Odometer';

  @override
  String get driverVehiclePreTripCheck => 'Pre-Trip Check';

  @override
  String get driverVehicleQuickActions => 'Quick Actions';

  @override
  String get driverVehicleReportIssue => 'Report Issue';

  @override
  String get driverVehicleTitle => 'My Vehicle';

  @override
  String get driverVehicleUpToDate => 'UP TO DATE';

  @override
  String get driverVehicleViewHistory => 'View History';

  @override
  String get feDashAboutRr => 'About RR Logistics';

  @override
  String get feDashActiveTrips => 'Active Trips';

  @override
  String feDashActiveTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active trips',
      one: '$count active trip',
    );
    return '$_temp0';
  }

  @override
  String get feDashClearAll => 'Clear all';

  @override
  String feDashDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get feDashHelpComingSoon => 'Help & Support coming soon.';

  @override
  String get feDashHelpSupport => 'Help & Support';

  @override
  String feDashHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get feDashJustNow => 'Just now';

  @override
  String get feDashLive => 'LIVE';

  @override
  String get feDashLoadTripsFailed => 'Could not load trips';

  @override
  String get feDashLogOut => 'Log Out';

  @override
  String get feDashLogout => 'Logout';

  @override
  String get feDashMarkAllRead => 'Mark all read';

  @override
  String feDashMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get feDashMore => 'MORE';

  @override
  String get feDashNavDashboard => 'Dashboard';

  @override
  String get feDashNavProfile => 'Profile';

  @override
  String get feDashNavRecords => 'Records';

  @override
  String get feDashNavigation => 'NAVIGATION';

  @override
  String get feDashNoActiveTrips => 'No active trips';

  @override
  String get feDashNoActiveTripsHint =>
      'You will be notified when a new trip is assigned';

  @override
  String get feDashNoNotifications => 'No notifications';

  @override
  String get feDashNoSyncedTrips => 'No synced trips yet';

  @override
  String feDashNoTripsMatch(String query) {
    return 'No trips match \"$query\"';
  }

  @override
  String get feDashNotifications => 'Notifications';

  @override
  String get feDashRecordsTitle => 'RR Web Records';

  @override
  String get feDashSearchBilty => 'Search by bilty number';

  @override
  String get feDashSettings => 'Settings';

  @override
  String feDashSyncedCount(int count) {
    return '$count synced';
  }

  @override
  String get feDashSyncedTrips => 'Synced trips';

  @override
  String get feDashSyncedTripsHint => 'Trips synced to RR web will appear here';

  @override
  String feDashUpdatedAt(String time) {
    return 'updated $time';
  }

  @override
  String feDashWelcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get feDashWorkerFallback => 'Worker';

  @override
  String get stageCommonAdd => 'Add';

  @override
  String get stageCommonAlreadyOnRr => 'Already on RR';

  @override
  String get stageCommonBackToDashboard => 'Back to Dashboard';

  @override
  String get stageCommonBrowsePhotos => 'Browse photos';

  @override
  String get stageCommonCamera => 'Camera';

  @override
  String get stageCommonCameraDenied =>
      'Permission denied. Enable Camera access for this app in Settings and try again.';

  @override
  String get stageCommonCameraFailed =>
      'Could not open camera. Please try again.';

  @override
  String get stageCommonCameraOrGallery => 'Camera or Gallery';

  @override
  String get stageCommonChooseGallery => 'Choose from Gallery';

  @override
  String get stageCommonCompleteStage => 'Complete Stage ✓';

  @override
  String get stageCommonConfirmWeight => 'Confirm Weight';

  @override
  String stageCommonDraftSaveFailed(String status, String detail) {
    return 'Draft save failed ($status): $detail';
  }

  @override
  String get stageCommonDriver => 'Driver';

  @override
  String stageCommonEg(String value) {
    return 'e.g. $value';
  }

  @override
  String stageCommonFailedWith(String error) {
    return 'Failed: $error';
  }

  @override
  String stageCommonFieldRequired(String label) {
    return '$label is required';
  }

  @override
  String get stageCommonFilePickerFailed =>
      'Could not open file picker. Please try again.';

  @override
  String stageCommonFutureNotAllowed(String label) {
    return '$label cannot be a future date/time — using current time instead';
  }

  @override
  String get stageCommonGallery => 'Gallery';

  @override
  String get stageCommonGalleryFailed =>
      'Could not access gallery. Please try again.';

  @override
  String stageCommonHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get stageCommonImageLoadFailed => 'Could not load image';

  @override
  String get stageCommonImageSelected => 'Image selected';

  @override
  String get stageCommonInsideFactory => 'Inside Factory';

  @override
  String get stageCommonJustNow => 'just now';

  @override
  String stageCommonLastSaved(String time) {
    return 'Last saved: $time';
  }

  @override
  String get stageCommonLoad => 'Load';

  @override
  String get stageCommonLoadOwner => 'Load Owner';

  @override
  String get stageCommonLoadOwnerNotified =>
      'Load owner notified successfully!';

  @override
  String get stageCommonLoadTripFailed =>
      'Failed to load trip details. Please try again.';

  @override
  String get stageCommonLockedSynced => 'Locked — already synced to RR';

  @override
  String get stageCommonLpTeam => 'LP Team';

  @override
  String get stageCommonLpTeamNotified => 'LP team notified successfully!';

  @override
  String stageCommonMaxChars(int count) {
    return 'Maximum $count characters';
  }

  @override
  String stageCommonMinAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String stageCommonNotified(String name) {
    return '$name Notified';
  }

  @override
  String stageCommonNotify(String name) {
    return 'Notify $name';
  }

  @override
  String stageCommonNotifyFailed(String error) {
    return 'Notification failed: $error';
  }

  @override
  String get stageCommonNumberTooShort => 'Too short to be a valid number';

  @override
  String get stageCommonOutsideFactory => 'Outside Factory';

  @override
  String get stageCommonPdfOpenFailed => 'Could not open the PDF.';

  @override
  String get stageCommonPhone10Digits => 'Enter exactly 10 digits';

  @override
  String get stageCommonPhoneRequired => 'Phone number is required';

  @override
  String get stageCommonPhotosDenied =>
      'Permission denied. Enable Photos access for this app in Settings and try again.';

  @override
  String stageCommonPleaseUpload(String docs) {
    return 'Please upload: $docs';
  }

  @override
  String get stageCommonReadOnlyCompleted => 'Read-only — Completed Trip';

  @override
  String get stageCommonReadyToUpload => 'Ready to Upload';

  @override
  String get stageCommonRemove => 'Remove';

  @override
  String get stageCommonReplace => 'Replace';

  @override
  String get stageCommonRetake => 'Retake';

  @override
  String get stageCommonSaveContinue => 'Save & Continue →';

  @override
  String get stageCommonSavingEllipsis => 'Saving…';

  @override
  String get stageCommonSelectDateTime => 'Select date & time';

  @override
  String get stageCommonSendingEllipsis => 'Sending…';

  @override
  String get stageCommonStateCancelled => 'CANCELLED';

  @override
  String get stageCommonStateCompleted => 'COMPLETED';

  @override
  String get stageCommonStateInTransit => 'IN TRANSIT';

  @override
  String get stageCommonStateOngoing => 'ONGOING';

  @override
  String get stageCommonStatePending => 'PENDING';

  @override
  String stageCommonSubmittedBy(String username) {
    return 'Submitted by @$username';
  }

  @override
  String get stageCommonSubmittingEllipsis => 'Submitting…';

  @override
  String get stageCommonTakePhoto => 'Take Photo';

  @override
  String get stageCommonTapToReplace => 'Tap to replace';

  @override
  String get stageCommonTapToView => 'Tap to view';

  @override
  String get stageCommonTrackTruck => 'Track Truck';

  @override
  String get stageCommonUnknownError => 'Unknown error';

  @override
  String get stageCommonUploadFailed => 'Upload failed';

  @override
  String get stageCommonUploadWeighSlip => 'Upload Weigh Slip';

  @override
  String get stageCommonUploaded => 'Uploaded';

  @override
  String get stageCommonUploading => 'Uploading...';

  @override
  String get stageCommonUploadingEllipsis => 'Uploading…';

  @override
  String get stageCommonUseCamera => 'Use camera';

  @override
  String get stageCommonVehicle => 'Vehicle';

  @override
  String get stageCommonWeighSlip => 'Weigh Slip';

  @override
  String get stageCommonWeight => 'Weight';

  @override
  String stageCommonWeightRecorded(String weight, String unit) {
    return 'Weight recorded: $weight $unit';
  }

  @override
  String get stageDocAadhaarCard => 'Aadhaar Card';

  @override
  String get stageDocBackSide => 'Back Side';

  @override
  String get stageDocBilty => 'Bilty';

  @override
  String get stageDocCancelledCheque =>
      'Cancelled Cheque (Owner / Transporter)';

  @override
  String get stageDocDrivingLicense => 'Driving License';

  @override
  String get stageDocDrivingLicenseBack => 'Driving License (Back)';

  @override
  String get stageDocDrivingLicenseFront => 'Driving License (Front)';

  @override
  String get stageDocEway => 'E-way Bill';

  @override
  String get stageDocFitness => 'Fitness Certificate';

  @override
  String get stageDocFrontSide => 'Front Side';

  @override
  String get stageDocInsurance => 'Insurance';

  @override
  String get stageDocInvoice => 'Invoice';

  @override
  String get stageDocLoadingSlip => 'Loading Slip';

  @override
  String get stageDocPermit => 'Permit';

  @override
  String get stageDocPollution => 'Pollution Certificate';

  @override
  String get stageDocRcFull => 'RC (Registration Certificate)';

  @override
  String get stageDocTaxDeclaration => 'Tax Declaration';

  @override
  String get stageRrAllStagesCompleteTitle => 'All stages complete';

  @override
  String get stageRrLater => 'Later';

  @override
  String get stageRrNotSyncedSub => 'Tap retry to push this trip to RR Web';

  @override
  String get stageRrNotSyncedTitle => 'Not synced to RR';

  @override
  String get stageRrSendToRr => 'Send to RR';

  @override
  String get stageRrSyncUpToDate => 'Up to date with RR web';

  @override
  String get stageSyncTripCancelled =>
      'Trip cancelled — nothing is synced to RR web';

  @override
  String get stageSyncTripNotCreated =>
      'Trip creation failed on RR web — nothing is synced';

  @override
  String get stageRrSyncComplete => 'Sync complete';

  @override
  String stageRrSyncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get stageRrSyncFailedShort => 'Sync failed';

  @override
  String get stageRrSyncFailedTitle => 'RR sync failed';

  @override
  String get stageRrSyncNow => 'Sync Now';

  @override
  String get stageRrSyncPromptBody =>
      'This trip is fully completed. Sync all uploads and data to RR web now?';

  @override
  String get stageRrSyncToRrWeb => 'Sync to RR web';

  @override
  String get stageRrSyncTooltip => 'Sync to RR';

  @override
  String get stageRrSyncedToRrWeb => 'Synced to RR web';

  @override
  String get stageRrSyncingEllipsis => 'Syncing…';

  @override
  String get stageRrTripSynced => 'Trip synced';

  @override
  String get stageS0Intro =>
      'Before proceeding to Stage 1, complete the following steps:';

  @override
  String get stageS0Step1Sub =>
      'Tap Stage 1 in the strip above to enter vehicle & driver details.';

  @override
  String get stageS0Step1Title => 'Fill Stage 1 — Truck Registration';

  @override
  String get stageS0Step2Sub =>
      'Once Stage 1 is complete, use the \"Send to RR\" button above to push the trip.';

  @override
  String get stageS0Step2Title => 'Sync trip to RR';

  @override
  String get stageS0Step3Sub =>
      'After RR sync, proceed with Pre-Arrival Compliance Check.';

  @override
  String get stageS0Step3Title => 'Continue to Stage 2';

  @override
  String get stageS0Title => 'Stage 0 — RR Sync';

  @override
  String get stageS1AadhaarBackPhoto => 'Photo of the back of the Aadhaar card';

  @override
  String get stageS1AadhaarFrontPhoto =>
      'Photo of the front of the Aadhaar card';

  @override
  String get stageS1AadhaarLength => 'Aadhaar must be exactly 12 digits';

  @override
  String get stageS1AadhaarNumber => 'Aadhaar Number (12 digits)';

  @override
  String get stageS1AppointNewDriver => 'Appoint New Driver';

  @override
  String get stageS1DlBackPhoto => 'Photo of the back of the driving license';

  @override
  String get stageS1DlFormatHint =>
      'New: RJ1420230012345   Old: RJ14/1234/2009';

  @override
  String get stageS1DlFrontPhoto => 'Photo of the front of the driving license';

  @override
  String get stageS1DlInvalid =>
      'Invalid format — e.g. RJ1420230012345 (state+RTO+year+7 digits)';

  @override
  String get stageS1DlNumber => 'Driving License No.';

  @override
  String get stageS1DlRequired => 'Driving License is required';

  @override
  String get stageS1DriverName => 'Driver Name';

  @override
  String get stageS1DriverNameRequired => 'Driver Name is required';

  @override
  String get stageS1DriverReassigned => 'Driver reassigned';

  @override
  String get stageS1FitnessNumber => 'Fitness Number';

  @override
  String get stageS1InsuranceNumber => 'Insurance Policy Number';

  @override
  String get stageS1NotNecessary =>
      'Filling S1 is not necessary for this trip.';

  @override
  String get stageS1OnlyAlphabets => 'Only alphabets allowed';

  @override
  String get stageS1PermitNumber => 'Permit Number';

  @override
  String get stageS1PucNumber => 'PUC Number';

  @override
  String get stageS1RcBackPhoto => 'Photo of the back of the RC';

  @override
  String get stageS1RcFrontPhoto => 'Photo of the front of the RC';

  @override
  String get stageS1RcInvalid =>
      'Invalid RC number — must contain both letters and digits';

  @override
  String get stageS1RcNumber => 'RC Number';

  @override
  String get stageS1Reassign => 'Reassign';

  @override
  String stageS1ReassignBusyWarning(String trip) {
    return 'This driver has another open trip ($trip). If you reassign, he will be removed from that trip and tracked on this one.';
  }

  @override
  String stageS1ReassignBody(String name) {
    return 'This trip will be reassigned to $name on RR — the My Trips list and crew records will update to reflect this.';
  }

  @override
  String get stageS1ReassignFailed => 'Could not reassign driver';

  @override
  String get stageS1ReassignTitle => 'Reassign Driver?';

  @override
  String stageS1ReassignPending(String name) {
    return 'New driver $name is selected but not reassigned yet. Tap \"Reassign to $name\" to continue, then save.';
  }

  @override
  String stageS1ReassignTo(String name) {
    return 'Reassign to $name';
  }

  @override
  String get stageS1Saved => 'Stage 1 saved. Proceed to compliance check.';

  @override
  String get stageS1SearchDriver => 'Search Driver by Name or Phone';

  @override
  String get stageS1SecDriver => 'Driver Details';

  @override
  String get stageS1SecOwnerDocs => 'Owner Documents';

  @override
  String get stageS1SecOwnerPayment => 'Truck Owner Payment Details';

  @override
  String get stageS1SecVehicleDocs => 'Vehicle Documents';

  @override
  String get stageS1SelectedDriver => 'the selected driver';

  @override
  String get stageS1ThisDriver => 'this driver';

  @override
  String get stageS1Updated => 'Stage 1 updated successfully.';

  @override
  String get stageS1UploadCancelledCheque => 'Upload a cancelled cheque';

  @override
  String get stageS1UploadFitness => 'Upload fitness certificate';

  @override
  String get stageS1UploadInsurance => 'Upload insurance document';

  @override
  String get stageS1UploadPan => 'Upload PAN card';

  @override
  String get stageS1PanNumber => 'PAN Number';

  @override
  String get stageS1PanInvalid => 'Enter a valid PAN, like ABCDE1234F';

  @override
  String get stageS1PanNumberRequired =>
      'PAN number is required with the PAN photo';

  @override
  String get stageS1TaxValidTill => 'Tax Declaration Valid Till';

  @override
  String get stageCommonSelectDate => 'Select date';

  @override
  String get stageS1UploadPermit => 'Upload permit document';

  @override
  String get stageS1UploadPollution => 'Upload pollution certificate';

  @override
  String get stageS1UploadTaxDeclaration => 'Upload tax declaration document';

  @override
  String get stageS2AttachSlip => 'Attach the loading slip image';

  @override
  String get stageS2CheckDocs => 'All documents uploaded';

  @override
  String get stageS2CheckDriverDocs => 'Driver documents valid';

  @override
  String get stageS2CheckSpecs => 'Truck specifications match requirement';

  @override
  String get stageS2ChooseSlipSource => 'Choose how to add the slip image';

  @override
  String get stageS2DharamKanta => 'Dharam Kanta (Weighbridge)';

  @override
  String get stageS2DharamKantaWhere =>
      'Is the weighbridge inside or outside the factory?';

  @override
  String get stageS2Done =>
      'Entry permission issued. Coordinate truck arrival.';

  @override
  String get stageS2EmptyWeightLabel => 'Empty Truck Weight Before Loading';

  @override
  String get stageS2EmptyWeightNote =>
      'Weight recorded outside factory (before loading).';

  @override
  String get stageS2EntryIssued => 'Truck Entry Permission Issued';

  @override
  String get stageS2EntryIssuedNote =>
      'Factory logistics team receives truck number + driver details.';

  @override
  String get stageS2ErrCheckEntry =>
      'Please check \"Truck Entry Permission Issued\" before proceeding.';

  @override
  String get stageS2ErrConfirmAll =>
      'Please confirm all verification items before proceeding.';

  @override
  String get stageS2ErrEmptyWeight =>
      'Please enter a valid empty truck weight (greater than 0) and confirm it.';

  @override
  String get stageS2ErrEntryRequired =>
      'Entry Permission must be issued to proceed.';

  @override
  String get stageS2ErrSelectWeighbridge =>
      'Please select weighbridge location (Inside or Outside Factory).';

  @override
  String get stageS2IssueEntry => 'Issue Entry Permission →';

  @override
  String get stageS2SlipOptional => 'Optional — tap to attach slip image';

  @override
  String get stageS2SlipRequiredBody =>
      'Upload the loading slip before the truck can proceed to the factory.';

  @override
  String get stageS2SlipRequiredTitle => 'Loading Slip Required';

  @override
  String get stageS2SlipUploadedBadge => 'Slip Uploaded';

  @override
  String get stageS2SlipUploadedByTransporter =>
      'Slip uploaded by transporter. Tap image to replace if needed.';

  @override
  String get stageS2SlipUploadedTitle => 'Loading Slip Uploaded';

  @override
  String get stageS2SubmitSlip => 'Submit Loading Slip';

  @override
  String get stageS2TapToUploadSlip => 'Tap to upload loading slip';

  @override
  String get stageS2UploadSlipTitle => 'Upload Loading Slip';

  @override
  String get stageS2Verifies => 'RR Executive verifies:';

  @override
  String get stageS2VerifiesNote =>
      'All items must be confirmed before issuing entry permission.';

  @override
  String get stageS3ArrivalSteps => 'Arrival Steps';

  @override
  String get stageS3AttachEway => 'Attach the e-way bill document';

  @override
  String get stageS3AttachInvoice => 'Attach the invoice document';

  @override
  String get stageS3Coordinates => 'RR Executive coordinates with driver:';

  @override
  String get stageS3DharamKanta => 'Dharma Kanta (Weigh Bridge)';

  @override
  String get stageS3DocsToSecurity => 'Documents submitted to security';

  @override
  String get stageS3DriverParks => 'Driver parks outside factory';

  @override
  String get stageS3EmptyWeight => 'Empty Truck Weight';

  @override
  String get stageS3EmptyWeightNote =>
      'Record the empty truck weight before loading.';

  @override
  String get stageS3ErrLoadingCompleted =>
      'Please check \"Loading Completed\" before completing the stage.';

  @override
  String get stageS3ErrStepsLoading =>
      'All steps must be completed before marking loading complete.';

  @override
  String get stageS3ErrStepsStage =>
      'All steps must be completed before completing the stage.';

  @override
  String get stageS3EwayExpiryDate => 'E-way Bill Expiry Date';

  @override
  String get stageS3EwayIssueDate => 'E-way Bill Issue Date';

  @override
  String get stageS3EwayNumber => 'E-way Bill Number';

  @override
  String get stageS3ExitCabin => 'Driver must exit cabin';

  @override
  String get stageS3ExtraInfo => 'Extra info (optional)';

  @override
  String get stageS3ExtraInfoHint =>
      'Anything that helps — a close-up of the plate, a visible phone number, etc.';

  @override
  String get stageS3ExtraPhoto => 'Extra photo';

  @override
  String get stageS3InvoiceNumber => 'Enter Invoice Number';

  @override
  String get stageS3InvoiceValue => 'Enter Invoice Value (₹, max 10 digits)';

  @override
  String get stageS3LoadedWeight => 'Loaded Truck Weight';

  @override
  String get stageS3LoadedWeightNote =>
      'Record the truck weight after loading is done.';

  @override
  String get stageS3MaterialWeight => 'Only Material Weight';

  @override
  String get stageS3MaterialWeightNote =>
      'Enter only the net material (goods) weight from the dharam kanta slip, not the truck weight.';

  @override
  String get stageS3LoadingCompleteBody =>
      'Loading complete. Proceed to factory exit.';

  @override
  String get stageS3LoadingCompleteTitle => 'Truck Loading Complete!';

  @override
  String get stageS3LoadingCompleted => 'Loading Completed';

  @override
  String get stageS3LoadingTiming => 'Loading Timing';

  @override
  String get stageS3NextStageExit => 'Next Stage — Truck Exit →';

  @override
  String get stageS3PhotoBack => 'Back';

  @override
  String get stageS3PhotoFront => 'Front';

  @override
  String get stageS3PhotoLeft => 'Left Side';

  @override
  String get stageS3PhotoRight => 'Right Side';

  @override
  String stageS3PhotosAdded(int count) {
    return '$count/4 photos added';
  }

  @override
  String stageS3PhotosNeedPhone(int count) {
    return '$count/4 photos · phone number needed';
  }

  @override
  String get stageS3SafetyGear => 'Safety shoes and helmet required';

  @override
  String get stageS3SafetyRules => 'Driver Safety Rules';

  @override
  String get stageS3SecurityVerifies =>
      'Security verifies vehicle requirements';

  @override
  String get stageS3SendForId => 'Send for Identification';

  @override
  String get stageS3SentForId => 'Sent for identification';

  @override
  String get stageS3TruckPhone => 'Phone number on the truck';

  @override
  String stageS3TruckPhotosFailed(String error) {
    return 'Could not send truck photos: $error';
  }

  @override
  String get stageS3TruckPhotosSent => 'Truck photos sent for identification.';

  @override
  String get stageS3TruckPictures => 'Truck Pictures';

  @override
  String get stageS3TruckPicturesSub =>
      'Add photos of all 4 sides of the truck';

  @override
  String get stageS3UploadEway => 'Upload E-way Bill';

  @override
  String get stageS3UploadInvoice => 'Upload Invoice';

  @override
  String get stageS3VehicleReach => 'Vehicle Reach Date And Time';

  @override
  String get stageS3WheelStoppers => 'Wheel stoppers installed';

  @override
  String get stageS4BiltyDate => 'Bilty Date And Time (Optional)';

  @override
  String stageS4BiltyBeforeTrip(String date) {
    return 'Bilty date cannot be before the trip was created ($date)';
  }

  @override
  String get stageS4BiltyNumber => 'Bilty Number (4 digits)';

  @override
  String get stageS4BiltyNumberError => 'Bilty Number must be exactly 4 digits';

  @override
  String get stageS4ChecklistDone =>
      'Exit checklist complete. Now upload diesel receipt.';

  @override
  String get stageS4ChooseReceiptSource =>
      'Choose how to add the receipt image';

  @override
  String get stageS4ConfirmAllItems =>
      'Please confirm all items above before proceeding';

  @override
  String get stageS4DieselAndBilty => 'Diesel Receipt and Bilty';

  @override
  String get stageS4DieselReceipt => 'Diesel Receipt';

  @override
  String get stageS4DocsChecked => 'Documents Checked';

  @override
  String get stageS4ExitChecklist => 'Exit Checklist';

  @override
  String get stageS4ExitProcedure => 'Exit Procedure';

  @override
  String get stageS4ExitTiming => 'Exit Timing';

  @override
  String get stageS4HeaderDieselSub =>
      'Upload the diesel receipt to complete Stage 4';

  @override
  String get stageS4HeaderExit => 'Truck Exit From Factory';

  @override
  String get stageS4HeaderExitSub =>
      'Verify all exit procedures before releasing truck';

  @override
  String get stageS4LoadedWeightSlip => 'Loaded Weight Slip';

  @override
  String get stageS4ManualBilty => 'Manual Bilty Upload';

  @override
  String get stageS4ManualBiltySub => 'Upload the physical bilty document';

  @override
  String get stageS4MaterialDocs => 'Material Documents';

  @override
  String get stageS4MaterialVerification => 'Material Verification Sheet';

  @override
  String get stageS4MaterialVerificationSub =>
      'Upload the material verification sheet';

  @override
  String get stageS4SecurityVerifies => 'Security verifies documents';

  @override
  String get stageS4SubmitDiesel => 'Submit Diesel Receipt';

  @override
  String get stageS4TapToUploadDiesel => 'Tap to upload diesel receipt';

  @override
  String get stageS4TruckExits => 'Truck Exits Factory';

  @override
  String get stageS4TruckMoves => 'Truck moves to factory exit gate';

  @override
  String get stageS4UploadDiesel => 'Upload Diesel Receipt';

  @override
  String get stageS4VehicleExit => 'Vehicle Exit Date And Time';

  @override
  String get stageS5AllCompletedBody =>
      'All stages completed including unloading.';

  @override
  String get stageS5AllCompletedTitle => 'All Stages Completed!';

  @override
  String get stageS5AllStagesDone => 'All Stages Done';

  @override
  String get stageS5CameraGalleryPdf => 'Camera, Gallery, or PDF File';

  @override
  String get stageS5ChoosePodSource => 'Choose how to add the POD document';

  @override
  String get stageS5Complete => 'Complete Unloading Stage';

  @override
  String get stageS5FilePdf => 'File (PDF)';

  @override
  String get stageS5HaltingCharge => 'Halting Charge (Optional)';

  @override
  String get stageS5HaltingHint => 'Enter amount in ₹ (e.g. 500)';

  @override
  String get stageS5Header => 'Unloading Stage';

  @override
  String get stageS5HeaderDone => 'Unloading Stage Complete';

  @override
  String get stageS5HeaderDoneSub => 'POD uploaded. Tap to replace if needed.';

  @override
  String get stageS5HeaderSub =>
      'Upload POD and enter halting charge if applicable.';

  @override
  String get stageS5PodRequired =>
      'Please upload the Proof of Delivery document';

  @override
  String get stageS5PodTitle => 'Proof of Delivery (POD)';

  @override
  String get stageS5PodUploadedBadge => 'POD Uploaded';

  @override
  String get stageS5TapToUploadPod => 'Tap to upload POD document';

  @override
  String get stageS5UnloadingEnd => 'Unloading End Date And Time';

  @override
  String get stageS5UnloadingTiming => 'Unloading Timing';

  @override
  String get stageS5UploadPod => 'Upload Proof of Delivery';

  @override
  String get stageNameArrival => 'Arrival';

  @override
  String get stageNameCompliance => 'Compliance';

  @override
  String get stageNameDetails => 'Details';

  @override
  String get stageNameExit => 'Exit';

  @override
  String get stageNameUnloading => 'Unloading';

  @override
  String get createTripAddNewDriver => 'Add New Driver';

  @override
  String get createTripAddressLine1 => 'Address Line 1';

  @override
  String get createTripAddressLine2 => 'Address Line 2';

  @override
  String createTripAddressN(int number) {
    return 'Address $number';
  }

  @override
  String get createTripAttachingDriver => 'Attaching driver to vehicle on RR…';

  @override
  String get createTripAutoFilledHint => 'Auto-filled or enter manually';

  @override
  String get createTripAxleDouble => 'Double';

  @override
  String get createTripAxleMultiple => 'Multiple';

  @override
  String get createTripAxleSingle => 'Single';

  @override
  String get createTripAxleTriple => 'Triple';

  @override
  String get createTripBiddingHint =>
      'Set your offline bid / booking amount to the vehicle provider';

  @override
  String get createTripBodyType => 'Vehicle Body Type';

  @override
  String get createTripBookingAmount => 'Vehicle Provider Booking Amount (₹) *';

  @override
  String get createTripBookingHint =>
      'e.g. 42000  (offline bid sent to vehicle provider)';

  @override
  String get createTripConsigneeGstin => 'Consignee GSTIN';

  @override
  String get createTripConsigneeHint =>
      'Select from Partners to auto fill Consignee details';

  @override
  String get createTripConsigneeName => 'Consignee Name';

  @override
  String get createTripConsigneeNameHint => 'e.g. JSW Steel Ltd';

  @override
  String get createTripConsignorGstin => 'Consignor GSTIN';

  @override
  String get createTripConsignorHint =>
      'Select from Partners to auto fill Consignor details';

  @override
  String get createTripConsignorName => 'Consignor Name *';

  @override
  String get createTripConsignorNameHint => 'e.g. Tata Steel Ltd';

  @override
  String get createTripCreateButton => 'Create Trip';

  @override
  String get createTripDepotHint => 'e.g. KNP01';

  @override
  String get createTripDiscard => 'Discard';

  @override
  String get createTripDiscardBody =>
      'Your edits to this trip have not been saved.';

  @override
  String get createTripDiscardTitle => 'Discard changes?';

  @override
  String get createTripDriverLabel => 'Driver *';

  @override
  String get createTripDriverSearchHint =>
      'Full 10-digit phone, or part of the name';

  @override
  String get createTripDriverSearchLabel => 'Driver Name or Phone Number';

  @override
  String createTripEditTitle(String ident) {
    return 'Edit Trip · $ident';
  }

  @override
  String createTripErrAttachDriver(String error) {
    return 'Could not attach driver to vehicle on RR: $error';
  }

  @override
  String get createTripErrCreateFailed => 'Failed to create trip';

  @override
  String get createTripErrNoUserFound => 'No user found for this number';

  @override
  String get createTripErrRrSlow =>
      'RR is taking too long to respond — please try again';

  @override
  String get createTripErrSaveFailed =>
      'Could not save the changes — please try again';

  @override
  String get createTripExpectedFreight => 'Expected Freight Amount (₹) *';

  @override
  String get createTripFreightHint => 'e.g. 45000';

  @override
  String get createTripHandledByPerson => 'Handled by Person *';

  @override
  String get createTripInvoiceHint => 'e.g. 150000';

  @override
  String get createTripInvoiceValue => 'Total Invoice Value (₹) *';

  @override
  String get createTripKeepEditing => 'Keep editing';

  @override
  String get createTripLandmark => 'Landmark / locality';

  @override
  String get createTripLoadingBodyTypes => 'Loading body types…';

  @override
  String get createTripLoadingCompanies => 'Loading companies…';

  @override
  String get createTripLoadingPartners => 'Loading partners…';

  @override
  String get createTripLoadingVehicles => 'Loading vehicles…';

  @override
  String get createTripLoadingWorkers => 'Loading workers…';

  @override
  String get createTripLookingUp => 'Looking up…';

  @override
  String get createTripMarketShort => 'market';

  @override
  String get createTripMaterialType => 'Material / Product Type *';

  @override
  String createTripMaxChars(int max, int count) {
    return 'Max $max characters   $count/$max';
  }

  @override
  String get createTripNewTrip => 'New Trip';

  @override
  String get createTripNoCompanies =>
      'No companies — vehicle from personal fleet below';

  @override
  String get createTripNoDriverOnRr =>
      'This vehicle has no driver assigned on RR — search for one below or add a new driver.';

  @override
  String get createTripNoEntryZone => 'No Entry Zone';

  @override
  String get createTripNoVehicles => 'No vehicles found';

  @override
  String get createTripNotBookedNotice =>
      'Not booked on RR yet — changes are saved here and sent to RR when you Confirm Booking.';

  @override
  String get createTripNothingChanged => 'Nothing has been changed';

  @override
  String get createTripParcelDesc => 'Description of Parcel';

  @override
  String get createTripParcelDescHint => 'e.g. Steel coils';

  @override
  String get createTripPickupCityName => 'Pickup City Name *';

  @override
  String get createTripPickupHint => 'Select consignor address to auto fill';

  @override
  String get createTripPinHint => '6-digit PIN';

  @override
  String get createTripPinZip => 'Pin / Zip Code';

  @override
  String get createTripSearchCity => 'Search city…';

  @override
  String get createTripSearchMaterial => 'Search material…';

  @override
  String get createTripSectionBidding => 'Bidding Amount';

  @override
  String get createTripSectionConsignee => 'Consignee Info';

  @override
  String get createTripSectionConsignor => 'Consignor Info';

  @override
  String get createTripSectionHandledBy => 'Trip Handled By';

  @override
  String get createTripSectionParcel => 'Parcel / Load Information';

  @override
  String get createTripSectionPickup => 'Pickup Location';

  @override
  String get createTripSectionUnload => 'Unload Location';

  @override
  String get createTripSectionVehicleProvider => 'Vehicle Provider';

  @override
  String get createTripSectionVehicleSpecs => 'Vehicle Specs';

  @override
  String get createTripSelectAxle => 'Select axle type';

  @override
  String get createTripSelectBodyType => 'Select vehicle body type';

  @override
  String get createTripOwnTrucksOption => 'No company — his own trucks';

  @override
  String get createTripSelectCompany => 'Select company';

  @override
  String get createTripSelectCompanyFirst =>
      'Select a company above to load vehicles';

  @override
  String get createTripSelectConsigneeAddress =>
      'Select consignee address (optional)';

  @override
  String get createTripSelectConsigneeCompany => 'Select Consignee Company';

  @override
  String get createTripSelectConsignorAddress =>
      'Select consignor address (optional)';

  @override
  String get createTripSelectConsignorCompany => 'Select Consignor Company *';

  @override
  String get createTripSelectFromPartners => 'Select from Partners (optional)';

  @override
  String get createTripSelectOpsWorker => 'Select RR Ops worker';

  @override
  String get createTripSelectPartner => 'Select partner';

  @override
  String get createTripSelectPartnerFirst => 'Select a partner above first';

  @override
  String get createTripSelectProviderCompany => 'Select Provider Company *';

  @override
  String get createTripSelectToAutoFill => 'Select to auto-fill address fields';

  @override
  String get createTripSelectVehicle => 'Select Vehicle *';

  @override
  String get createTripSelectVehicleHint => 'Select a vehicle';

  @override
  String get createTripSelectWheels => 'Select number of wheels';

  @override
  String get createTripStepBidding => 'Bidding';

  @override
  String get createTripStepVehicle => 'Vehicle';

  @override
  String get createTripStreetArea => 'Street / area';

  @override
  String get createTripTabLoadInfo => 'Load Info';

  @override
  String get createTripTapToSelect => 'Tap to select';

  @override
  String get createTripTotalWeight => 'Total Weight / Quantity *';

  @override
  String get createTripUnknown => 'Unknown';

  @override
  String get createTripUnknownError => 'unknown error';

  @override
  String get createTripUnloadCityName => 'Unload City Name *';

  @override
  String get createTripUnloadHint => 'Select consignee address to auto fill';

  @override
  String get createTripUpdate => 'Update';

  @override
  String get createTripUpdated => 'Trip updated';

  @override
  String get createTripValBookingAmount =>
      'Booking Amount (₹) is required and must be greater than 0';

  @override
  String get createTripValConsignorCompany =>
      'Must select company from dropdown';

  @override
  String get createTripValConsignorName =>
      'Consignor Name is required — pick a partner above or type it in';

  @override
  String get createTripValDriver => 'Select a Driver';

  @override
  String get createTripValExpectedFreight =>
      'Expected Freight Amount (₹) is required by RR create trip';

  @override
  String get createTripValInvoiceValue =>
      'Total Invoice Value (₹) is required — used as parcel cost in RR';

  @override
  String get createTripValMaterial =>
      'Material / Product Type is required — search and select from the list';

  @override
  String get createTripValOpsWorker =>
      'Select the RR Ops worker handling this trip';

  @override
  String get createTripValPickupCity =>
      'Pickup City is required — search and select from the list';

  @override
  String get createTripValUnloadCity =>
      'Unload City is required — search and select from the list';

  @override
  String get createTripValVehicle => 'Select a Vehicle';

  @override
  String get createTripValVpCompany =>
      'Vehicle Provider Company is required — select a company';

  @override
  String get createTripValVpPhone =>
      'Enter Vehicle Provider phone number and tap the result to select';

  @override
  String get createTripValWeight => 'Total Weight / Quantity is required';

  @override
  String get createTripVpPhone => 'Vehicle Provider Phone *';

  @override
  String get createTripVpPhoneHint =>
      'e.g. 8960281816 — auto-searches at 10 digits';

  @override
  String get createTripVpSteps =>
      'Enter provider phone → select user → select company → select vehicle';

  @override
  String get createTripWarnBusy =>
      'This driver is already on another open trip — tracking won\'t link to this trip until that one is finished.';

  @override
  String get createTripWarnNoApp =>
      'This driver hasn\'t set up the RR4 app yet — tracking won\'t be available for this trip until they do.';

  @override
  String get createTripWeightHint => 'e.g. 20';

  @override
  String createTripWheelsCount(int count) {
    return '$count wheels';
  }

  @override
  String get lpDashAboutRr => 'About RR Logistics';

  @override
  String get lpDashAddCompany => 'Add Company';

  @override
  String get lpDashAddDriver => 'Add Driver';

  @override
  String get lpDashAddVehicle => 'Add Vehicle';

  @override
  String get lpDashBrowseLoads => 'Browse available load requirements';

  @override
  String get lpDashComingSoonBody =>
      'This section is under development\nand will be available soon.';

  @override
  String get lpDashCreateTrip => 'Create Trip';

  @override
  String get lpDashEmployees => 'Employees';

  @override
  String get lpDashEmptyTripsHint =>
      'Create a trip to track it here in real time';

  @override
  String get lpDashFleetHub => 'Fleet Hub';

  @override
  String get lpDashFleetStatus => 'Fleet Status';

  @override
  String get lpDashHireTruck => 'Hire Truck';

  @override
  String get lpDashLoadFleetFailed => 'Could not load fleet status';

  @override
  String get lpDashNavFleet => 'Fleet';

  @override
  String get lpDashNavLoads => 'Loads';

  @override
  String get lpDashNavSoon => 'Soon';

  @override
  String get lpDashNewTrip => 'New Trip';

  @override
  String get lpDashNoRecords => 'No RR Web records yet';

  @override
  String get lpDashNoRecordsHint => 'Completed RR Web trips will appear here';

  @override
  String get lpDashPanelSubtitle => 'Logistic Partner Panel';

  @override
  String lpDashPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get lpDashReconnect => 'Reconnect';

  @override
  String get lpDashRecordsSubtitle => 'Completed RR Web trips';

  @override
  String get lpDashRequests => 'Requests';

  @override
  String get lpDashRrQuickAdd => 'RR QUICK ADD';

  @override
  String lpDashRrSyncFailedDetail(String reason) {
    return 'RR sync failed: $reason';
  }

  @override
  String get lpDashRrTripNumber => 'RR Trip Number';

  @override
  String get lpDashS1AllowBody =>
      'Allow the Field Executive to fill Stage 1 (Truck Detail Registration) docs for this trip?\n\nYou can change this later from the trip card.';

  @override
  String get lpDashS1AllowTitle => 'Field Executive — Stage 1';

  @override
  String get lpDashSearchNewLoads => 'Search New Loads';

  @override
  String get lpDashTrack => 'Track';

  @override
  String lpDashTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$_temp0';
  }

  @override
  String get lpDashTripCreated => 'Trip Created';

  @override
  String get lpDashTripNumberCopied => 'Trip number copied';

  @override
  String get lpDashTripSyncedToRrWeb => 'Trip Synced to RR Web';

  @override
  String get lpDashVehicleHireRequests => 'Vehicle Hire Requests';

  @override
  String get lpOpsAddCompany => 'Add Company';

  @override
  String get lpOpsAddDriver => 'Add Driver';

  @override
  String get lpOpsAddVehicle => 'Add Vehicle';

  @override
  String get lpOpsDrawerTrack => 'Track';

  @override
  String get lpOpsEmptyBody =>
      'No active RR Web trips yet.\nTap \"+ New Trip\" above to get started.';

  @override
  String get lpOpsEmptyTitle => 'No RR Web trips yet';

  @override
  String get lpOpsHireRequests => 'Vehicle Hire Requests';

  @override
  String get lpOpsHireTruck => 'Hire Truck';

  @override
  String get lpOpsNavLoads => 'Loads';

  @override
  String get lpOpsNeedsSlip => 'Needs Slip';

  @override
  String get lpOpsNewTrip => 'New Trip';

  @override
  String lpOpsNoMatch(String query) {
    return 'No trips match \"$query\"';
  }

  @override
  String get lpOpsNoSyncedHint => 'Trips synced to RR web will appear here';

  @override
  String get lpOpsNoSyncedTitle => 'No synced trips yet';

  @override
  String get lpOpsQuickAdd => 'RR QUICK ADD';

  @override
  String get lpOpsReconnect => 'Reconnect';

  @override
  String get lpOpsRrTripNumber => 'RR Trip Number';

  @override
  String get lpOpsS1Body =>
      'Allow the Field Executive to fill Stage 1 (Truck Detail Registration) docs for this trip?\n\nYou can change this later from the trip card.';

  @override
  String get lpOpsS1Title => 'Field Executive — Stage 1';

  @override
  String get lpOpsSlipDone => 'Slip Done';

  @override
  String lpOpsSyncFailedMsg(String error) {
    return 'RR sync failed: $error';
  }

  @override
  String lpOpsSyncedCount(int count) {
    return '$count synced';
  }

  @override
  String get lpOpsTripCreated => 'Trip Created';

  @override
  String get lpOpsTripNumberCopied => 'Trip number copied';

  @override
  String get lpOpsTripSynced => 'Trip Synced to RR Web';

  @override
  String get lpOpsWebTrips => 'RR Web Trips';

  @override
  String get lpWorkersDaily => 'Daily';

  @override
  String get lpWorkersEmptyHint =>
      'Active employees in your organisation will appear here.';

  @override
  String get lpWorkersEmptyTitle => 'No employees found';

  @override
  String get lpWorkersLoadFailed => 'Failed to load';

  @override
  String get lpWorkersMonthly => 'Monthly';

  @override
  String get lpWorkersNoActivityHint =>
      'No stage submissions recorded for this period.';

  @override
  String get lpWorkersNoActivityTitle => 'No activity yet';

  @override
  String lpWorkersPoints(int count) {
    return '$count pts';
  }

  @override
  String get lpWorkersPtsShort => 'pts';

  @override
  String lpWorkersRemoveConfirm(String name) {
    return 'Remove $name from the organization? They will lose access immediately and can request to rejoin later.';
  }

  @override
  String lpWorkersRemoveFailed(String error) {
    return 'Failed to remove: $error';
  }

  @override
  String get lpWorkersRemoveTitle => 'Remove From Organization';

  @override
  String lpWorkersRemoved(String name) {
    return '$name removed from the organization';
  }

  @override
  String get lpWorkersTabLeaderboard => 'Leaderboard';

  @override
  String get lpWorkersTabRecord => 'Record';

  @override
  String get lpWorkersTitle => 'Employees';

  @override
  String lpWorkersTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '$count trip',
    );
    return '$_temp0';
  }

  @override
  String get rrQuickAddActionFailed => 'Action failed. Please try again.';

  @override
  String get rrQuickAddAddCompanyButton => 'Add Company';

  @override
  String get rrQuickAddAddDriverButton => 'Add Driver';

  @override
  String get rrQuickAddAddVehicleButton => 'Add Vehicle';

  @override
  String get rrQuickAddApprove => 'Approve';

  @override
  String get rrQuickAddApprovedEndDate => 'Approved End Date';

  @override
  String rrQuickAddApprovedRange(String start, String end) {
    return 'Approved: $start to $end';
  }

  @override
  String get rrQuickAddApprovedStartDate => 'Approved Start Date';

  @override
  String get rrQuickAddBizCommissionAgent => 'Commission Agent';

  @override
  String get rrQuickAddBizDriver => 'Driver';

  @override
  String get rrQuickAddBizOther => 'Other';

  @override
  String get rrQuickAddBizParcelReceiver => 'Parcel Receiver - Consignee';

  @override
  String get rrQuickAddBizParcelReceiverAgent =>
      'Parcel Receiver Agent - Consignee Commission Agent';

  @override
  String get rrQuickAddBizParcelSender => 'Parcel Sender - Consignor';

  @override
  String get rrQuickAddBizParcelSenderAgent =>
      'Parcel Sender Agent - Consignor Commission Agent';

  @override
  String get rrQuickAddBizTransporter => 'Transporter';

  @override
  String get rrQuickAddBizVehicleAgent => 'Vehicle Agent';

  @override
  String get rrQuickAddBizVehicleOwner => 'Vehicle Owner';

  @override
  String get rrQuickAddBusinessTypeLabel => 'Business Type *';

  @override
  String get rrQuickAddCheckHistory => 'Check Vehicle History';

  @override
  String rrQuickAddCompanyAdded(String name) {
    return 'Company \"$name\" added on RR';
  }

  @override
  String get rrQuickAddCompanyFirmLabel => 'Company / Firm Name';

  @override
  String get rrQuickAddCompanyIntro =>
      'Register a new vehicle-provider company on RR';

  @override
  String get rrQuickAddCompanyNameRequired => 'Company name is required';

  @override
  String get rrQuickAddCompanyOptional => 'Company (optional)';

  @override
  String get rrQuickAddCompanyOwnerLabel =>
      'Company Owner (search or enter a new 10-digit phone) *';

  @override
  String get rrQuickAddCompanyTitle => 'Add New Company';

  @override
  String rrQuickAddContractorLine(String value) {
    return 'Contractor: $value';
  }

  @override
  String rrQuickAddDateRangeTo(String start, String end) {
    return '$start to $end';
  }

  @override
  String rrQuickAddDriverAdded(String name) {
    return 'Driver \"$name\" added on RR';
  }

  @override
  String get rrQuickAddDriverIntro => 'Register a new driver on RR';

  @override
  String get rrQuickAddDriverTitle => 'Add New Driver';

  @override
  String rrQuickAddEndLine(String date) {
    return 'End: $date';
  }

  @override
  String get rrQuickAddEngineModelLabel => 'Engine Model *';

  @override
  String get rrQuickAddFind => 'Find';

  @override
  String rrQuickAddFromLine(String date) {
    return 'From: $date';
  }

  @override
  String get rrQuickAddHireApproved => 'Hire request approved';

  @override
  String get rrQuickAddHireEmpty => 'No pending hire requests';

  @override
  String get rrQuickAddHireLoadFailed => 'Could not load hire requests';

  @override
  String get rrQuickAddHirePerson => 'Hire Person';

  @override
  String get rrQuickAddHirePersonLabel => 'Vehicle Hire Person *';

  @override
  String get rrQuickAddHireRejected => 'Hire request rejected';

  @override
  String get rrQuickAddHireSendFailed =>
      'Could not send hire request. Please try again.';

  @override
  String get rrQuickAddHireSent => 'Hiring request sent successfully';

  @override
  String get rrQuickAddHireTitle => 'Vehicle Hire Requests';

  @override
  String get rrQuickAddHiringDateFrom => 'Hiring Request Date — From';

  @override
  String get rrQuickAddHiringDateTo => 'Hiring Request Date — To';

  @override
  String get rrQuickAddHiringRequestDate => 'Hiring Request Date';

  @override
  String get rrQuickAddHistoryFailed =>
      'Could not load history. Please try again.';

  @override
  String get rrQuickAddHistoryHint =>
      'Reference only — look up a vehicle\'s past hires';

  @override
  String get rrQuickAddHistorySelectFirst =>
      'Search and select a vehicle first';

  @override
  String get rrQuickAddLenderDetail => 'Lender Detail';

  @override
  String get rrQuickAddLenderVehicles => 'Lender Vehicles *';

  @override
  String get rrQuickAddMarketTitle => 'Add Market Vehicle';

  @override
  String get rrQuickAddNameLabel => 'Name *';

  @override
  String get rrQuickAddNameMin => 'Enter at least 2 characters';

  @override
  String rrQuickAddNoHistory(String vehicle) {
    return 'No hire history found for $vehicle';
  }

  @override
  String get rrQuickAddNoOwnerVehicles => 'This owner has no vehicles on RR';

  @override
  String get rrQuickAddNotSet => 'Not set';

  @override
  String get rrQuickAddOrByPhone => '— or by phone number —';

  @override
  String rrQuickAddOwnerLine(String value) {
    return 'Owner: $value';
  }

  @override
  String get rrQuickAddOwnerOrPhone =>
      'Select an existing owner or enter a valid 10-digit phone number';

  @override
  String get rrQuickAddOwnerPhoneLabel => 'Owner Phone Number *';

  @override
  String get rrQuickAddPhoneLabel => 'Phone Number *';

  @override
  String get rrQuickAddPhoneSearchHint =>
      'Full 10-digit phone, or part of the name';

  @override
  String get rrQuickAddRcHint => 'e.g. RJ14';

  @override
  String get rrQuickAddRcNumberLabel => 'RC Number *';

  @override
  String get rrQuickAddRcRequired => 'RC number is required';

  @override
  String get rrQuickAddReject => 'Reject';

  @override
  String get rrQuickAddRequestInfo => 'Request Information';

  @override
  String get rrQuickAddRequestTimePeriod => 'Request Time Period';

  @override
  String rrQuickAddRequestedByLine(String value) {
    return 'Requested by: $value';
  }

  @override
  String rrQuickAddRequestedRangeArrow(String start, String end) {
    return 'Requested: $start → $end';
  }

  @override
  String rrQuickAddRequestedRangeTo(String start, String end) {
    return 'Requested: $start to $end';
  }

  @override
  String get rrQuickAddReviewTitle => 'Review Hire Request';

  @override
  String get rrQuickAddSamePerson =>
      'The hiring person and lender must be different. You cannot hire your own vehicle.';

  @override
  String get rrQuickAddSearchByCompany => 'Search by company/firm';

  @override
  String get rrQuickAddSelectCity => 'Select a city from the suggestions';

  @override
  String get rrQuickAddSelectEngineModel =>
      'Select an engine model from the suggestions';

  @override
  String get rrQuickAddSelectFleetVehicle =>
      'Select a vehicle from the owner\'s fleet';

  @override
  String get rrQuickAddSelectHirePerson =>
      'Search and select the Vehicle Hire Person';

  @override
  String get rrQuickAddSelectOwner => 'Select an owner from the suggestions';

  @override
  String get rrQuickAddSelectVehicleHint => 'Select vehicle';

  @override
  String get rrQuickAddSelectVehicleOwner =>
      'Search and select the Vehicle Owner';

  @override
  String rrQuickAddStartLine(String date) {
    return 'Start: $date';
  }

  @override
  String get rrQuickAddStatusApproved => 'Approved';

  @override
  String get rrQuickAddStatusRejected => 'Rejected';

  @override
  String get rrQuickAddStatusRequested => 'Requested';

  @override
  String get rrQuickAddStatusTerminated => 'Terminated';

  @override
  String rrQuickAddTerminatedLine(String date) {
    return 'Terminated: $date';
  }

  @override
  String rrQuickAddToLine(String date) {
    return 'To: $date';
  }

  @override
  String get rrQuickAddUnknown => 'Unknown';

  @override
  String rrQuickAddVehicleAdded(String rc) {
    return 'Vehicle \"$rc\" added on RR';
  }

  @override
  String get rrQuickAddVehicleDetail => 'Vehicle Detail';

  @override
  String get rrQuickAddVehicleIntro => 'Register a new vehicle on RR';

  @override
  String rrQuickAddVehicleLine(String value) {
    return 'Vehicle: $value';
  }

  @override
  String get rrQuickAddVehicleOwnerLabel => 'Vehicle Owner *';

  @override
  String get rrQuickAddVehicleTitle => 'Add New Vehicle';

  @override
  String get rrQuickAddYourFleet => 'Your fleet';

  @override
  String loadsBrowserCompany(String name) {
    return 'Company: $name';
  }

  @override
  String loadsBrowserCopiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count load requirements copied to clipboard',
      one: 'Load requirement copied to clipboard',
    );
    return '$_temp0';
  }

  @override
  String get loadsBrowserCopyDetails => 'Copy Details';

  @override
  String loadsBrowserCopySelected(int count) {
    return 'Copy Selected ($count)';
  }

  @override
  String get loadsBrowserDetailsCopied => 'Load details copied to clipboard';

  @override
  String get loadsBrowserDropHint => 'Drop city…';

  @override
  String get loadsBrowserEmpty => 'No pending load requirements';

  @override
  String loadsBrowserLogisticPartner(String name) {
    return 'Logistic Partner: $name';
  }

  @override
  String loadsBrowserMaterialWeight(String weight) {
    return 'Material: $weight';
  }

  @override
  String get loadsBrowserPickupHint => 'Pickup city…';

  @override
  String get loadsBrowserSubtitle =>
      'Browse pending requirements from load owners';

  @override
  String get loadsBrowserTitle => 'Search Loads';

  @override
  String loadsBrowserTruckUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trucks',
      one: 'truck',
    );
    return '$_temp0';
  }

  @override
  String loadsBrowserTruckWeight(String weight) {
    return 'Truck: $weight';
  }

  @override
  String get loadsBrowserTrucksNeeded => 'Trucks Needed:';

  @override
  String get loadsBrowserWhatsApp => 'WhatsApp';

  @override
  String get loadsBrowserWhatsAppFailed => 'Could not open WhatsApp';

  @override
  String get tripDetailCreated => 'Created';

  @override
  String get tripDetailEndDate => 'End Date';

  @override
  String get tripDetailFetchingGps => 'Fetching GPS location…';

  @override
  String get tripDetailGoToStage => 'GO TO PRESENT STAGE';

  @override
  String get tripDetailInvoiceNumber => 'Invoice Number';

  @override
  String get tripDetailLoadItem => 'Load Item';

  @override
  String get tripDetailRoute => 'ROUTE';

  @override
  String get tripDetailSectionCargo => 'Cargo Details';

  @override
  String get tripDetailSectionFinancial => 'Financial Details';

  @override
  String get tripDetailSectionIdentifiers => 'Identifiers';

  @override
  String get tripDetailSectionLogistics => 'Logistics';

  @override
  String tripDetailStageLine(int number, String name) {
    return 'Stage $number: $name';
  }

  @override
  String get tripDetailStartDate => 'Start Date';

  @override
  String get tripDetailTitle => 'Trip Details';

  @override
  String get tripDetailTripAmount => 'Trip Amount';

  @override
  String get tripDetailTripNumber => 'Trip Number';

  @override
  String get tripDetailViewOnMap => 'View vehicle on live map';

  @override
  String tripLocateDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String tripLocateGapLocationOff(String time) {
    return 'Location off · $time';
  }

  @override
  String get tripLocateGapNearDetail => 'The vehicle stayed in the same area.';

  @override
  String tripLocateGapNoTracking(String time) {
    return 'No tracking for this trip · $time';
  }

  @override
  String tripLocateGapOkDetail(String km) {
    return 'About $km km by road. Approximate route, minimum distance.';
  }

  @override
  String tripLocateGapOkDetailMode(String km, String mode) {
    return 'About $km km by road. Approximate route, minimum distance ($mode).';
  }

  @override
  String get tripLocateGapReleasedDetail =>
      'Tracking was paused for this trip or the driver changed. No route is drawn.';

  @override
  String tripLocateGapSemanticsOff(String label) {
    return 'Location off for $label. Tap for details.';
  }

  @override
  String tripLocateGapSemanticsReleased(String label) {
    return 'No tracking for this trip for $label. Tap for details.';
  }

  @override
  String tripLocateGapSuspiciousDetail(String km) {
    return 'The vehicle moved $km km in a straight line, which is too far for this time. No route is drawn.';
  }

  @override
  String get tripLocateGapUnavailable => 'Route not available yet.';

  @override
  String get tripLocateGpsActive => 'GPS Active';

  @override
  String tripLocateHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String tripLocateHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get tripLocateJustNow => 'just now';

  @override
  String tripLocateLastUpdated(String ago, String time) {
    return 'Last updated: $ago ($time)';
  }

  @override
  String get tripLocateLegendLocationOff => 'Location off';

  @override
  String get tripLocateLegendSemantics =>
      'Map key. Orange line: tracked route. Grey dotted line: location was off.';

  @override
  String get tripLocateLegendTracked => 'Tracked';

  @override
  String get tripLocateLoadingTrail => 'Loading trail…';

  @override
  String tripLocateLocating(String tripNumber) {
    return 'Locating $tripNumber';
  }

  @override
  String tripLocateMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String tripLocateMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get tripLocateModeCar => 'car route';

  @override
  String get tripLocateModeHeavyTruck => 'heavy truck route';

  @override
  String get tripLocateModeLightTruck => 'light truck route';

  @override
  String get tripLocateModeMediumTruck => 'medium truck route';

  @override
  String get tripLocateModeTruck => 'truck route';

  @override
  String get tripLocateNoGpsMessage =>
      'The driver app has not shared a location yet for this trip.';

  @override
  String get tripLocateNoGpsTitle => 'No GPS Location Available';

  @override
  String get tripLocateNoSignal => 'No Signal';

  @override
  String get tripLocateOpenMaps => 'Open in Google Maps';

  @override
  String get tripLocateStale => 'Stale';

  @override
  String get tripLocateTimeMismatch => 'time mismatch';

  @override
  String get tripLocateTryAgain => 'Try Again';

  @override
  String get tripLocateVehicleFallback => 'VEHICLE';

  @override
  String get workerReqAccept => 'Accept';

  @override
  String get workerReqAccepted => 'Worker accepted!';

  @override
  String get workerReqAssignRole => 'Assign Role';

  @override
  String workerReqCurrentRole(String role) {
    return 'Currently: $role';
  }

  @override
  String workerReqJoined(String date) {
    return 'Joined $date';
  }

  @override
  String workerReqJoinedBy(String date, String name) {
    return 'Joined $date by $name';
  }

  @override
  String get workerReqLoadFailed => 'Failed to load requests';

  @override
  String get workerReqNoAccepted => 'No accepted employees yet';

  @override
  String get workerReqNoAcceptedHint => 'Accepted employees will appear here.';

  @override
  String get workerReqNoPending => 'No pending requests';

  @override
  String get workerReqNoPendingHint => 'Worker requests will appear here.';

  @override
  String get workerReqNoRolePicked =>
      'This worker didn\'t pick a role at signup — choose one below.';

  @override
  String get workerReqNoRoleRequested => 'No role requested yet';

  @override
  String get workerReqReject => 'Reject';

  @override
  String get workerReqRejectConfirm =>
      'Are you sure you want to reject this worker request?';

  @override
  String get workerReqRejectTitle => 'Reject Request';

  @override
  String get workerReqRejected => 'Request rejected.';

  @override
  String workerReqRequestedOn(String date) {
    return 'Requested: $date';
  }

  @override
  String get workerReqRoleFeDesc =>
      'Manages trip stages and fleet status on the ground';

  @override
  String get workerReqRoleLoadOwnerWorker => 'Load Owner Worker';

  @override
  String get workerReqRoleLoadOwnerWorkerDesc =>
      'Manages load postings and shipment tracking';

  @override
  String get workerReqRoleNotSet => 'Role not set — tap to assign';

  @override
  String get workerReqRoleRrOpsDesc =>
      'Handles RR sync and trip data entry in the RR system';

  @override
  String get workerReqTabAccepted => 'Accepted';

  @override
  String get workerReqTabPending => 'Pending';

  @override
  String get workerReqTitle => 'Employee Requests';

  @override
  String get workerReqUnknown => 'Unknown';

  @override
  String get loadSpecAxleFullTrailer => 'Full Trailer';

  @override
  String get loadSpecAxleMulti => 'Multi-Axle';

  @override
  String get loadSpecAxleSemiTrailer => 'Semi-Trailer';

  @override
  String get loadSpecAxleSingle => 'Single Axle';

  @override
  String get loadSpecAxleTandem => 'Tandem Axle';

  @override
  String get loadSpecAxleTri => 'Tri-Axle';

  @override
  String get loadSpecBodyCarCarrier => 'Car Carrier';

  @override
  String get loadSpecBodyClosed => 'Closed Body';

  @override
  String get loadSpecBodyContainer => 'Container';

  @override
  String get loadSpecBodyFlatbed => 'Flatbed';

  @override
  String get loadSpecBodyLowBed => 'Low Bed';

  @override
  String get loadSpecBodyOpen => 'Open Body';

  @override
  String get loadSpecBodyRefrigerated => 'Refrigerated';

  @override
  String get loadSpecBodySideWall => 'Side Wall';

  @override
  String get loadSpecBodyTanker => 'Tanker';

  @override
  String get loadSpecBodyTipper => 'Tipper / Dumper';

  @override
  String get loadSpecFloorAluminium => 'Aluminium';

  @override
  String get loadSpecFloorBamboo => 'Bamboo';

  @override
  String get loadSpecFloorCorrugated => 'Corrugated';

  @override
  String get loadSpecFloorPlain => 'Plain Floor';

  @override
  String get loadSpecFloorRubberMatted => 'Rubber Matted';

  @override
  String get loadSpecFloorSteel => 'Steel';

  @override
  String get loadSpecFloorWooden => 'Wooden';

  @override
  String get loadSpecMatAgri => 'Agricultural Produce';

  @override
  String get loadSpecMatAutoParts => 'Automotive Parts';

  @override
  String get loadSpecMatChemicals => 'Chemicals';

  @override
  String get loadSpecMatConstruction => 'Construction Materials';

  @override
  String get loadSpecMatElectronics => 'Electronics';

  @override
  String get loadSpecMatFmcg => 'FMCG / Packaged Goods';

  @override
  String get loadSpecMatFurniture => 'Furniture';

  @override
  String get loadSpecMatGlass => 'Glass & Ceramics';

  @override
  String get loadSpecMatHazardous => 'Hazardous Goods';

  @override
  String get loadSpecMatIndustrial => 'Industrial';

  @override
  String get loadSpecMatLiquids => 'Liquids / Beverages';

  @override
  String get loadSpecMatMachinery => 'Machinery & Equipment';

  @override
  String get loadSpecMatOthers => 'Others';

  @override
  String get loadSpecMatPaints => 'Paints & Coatings';

  @override
  String get loadSpecMatPaper => 'Paper & Printing';

  @override
  String get loadSpecMatPerishables => 'Perishables';

  @override
  String get loadSpecMatPharma => 'Pharmaceuticals';

  @override
  String get loadSpecMatPlastics => 'Plastics & Rubber';

  @override
  String get loadSpecMatSteelCoils => 'Steel Coils';

  @override
  String get loadSpecMatTextiles => 'Textiles & Fabrics';

  @override
  String get loDashBottomDashboard => 'DASHBOARD';

  @override
  String get loDashBottomDocs => 'DOCS';

  @override
  String get loDashBottomLoads => 'LOADS';

  @override
  String get loDashBottomMyTrips => 'MY TRIPS';

  @override
  String get loDashBottomProfile => 'PROFILE';

  @override
  String get loDashBottomSoon => 'SOON';

  @override
  String get loDashClearAll => 'Clear All';

  @override
  String get loDashClearAllBody =>
      'This will permanently delete all notifications.';

  @override
  String get loDashClearAllTitle => 'Clear all notifications?';

  @override
  String get loDashCreateLoadButton => 'Create Load Requirement';

  @override
  String get loDashNavMyLoads => 'My Loads';

  @override
  String get loDashNoNotifications => 'No notifications yet';

  @override
  String get loDashPanelTitle => 'Load Owner Panel';

  @override
  String get loDashPostLoadBody =>
      'Send your load details to your preferred logistic partner and get it moving.';

  @override
  String get loDashPostLoadTitle => 'Post a Load Requirement';

  @override
  String loDashSoonSuffix(String label) {
    return '$label (Soon)';
  }

  @override
  String get loDashTabDocuments => 'Documents';

  @override
  String get loDashTabTracking => 'Tracking';

  @override
  String get appRouterErrorTitle => 'Error';

  @override
  String appRouterPageNotFound(String location) {
    return 'Page not found: $location';
  }

  @override
  String get mainNavCreateOrganization => 'Create Organization';

  @override
  String get mainNavInventory => 'Inventory';

  @override
  String mainNavLoadOrganizationsError(String error) {
    return 'Error loading organizations: $error';
  }

  @override
  String get mainNavLoadingOrganizations => 'Loading organizations...';

  @override
  String get mainNavLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get mainNavManageOrganization => 'Manage Organization';

  @override
  String get mainNavMyOrganizations => 'My Organizations';

  @override
  String get mainNavMyProfile => 'My Profile';

  @override
  String get mainNavMyTasks => 'My Tasks';

  @override
  String get mainNavNoOrganization =>
      'No organization found. Please join or create one first.';

  @override
  String get mainNavOrganizationFallback => 'Organization';

  @override
  String get mainNavReports => 'Reports';

  @override
  String get mainNavRoles => 'Roles';

  @override
  String get mainNavSchedule => 'Schedule';

  @override
  String get mainNavSignOut => 'Sign Out';

  @override
  String get mainNavTasks => 'Tasks';

  @override
  String get mainNavUserFallback => 'User';

  @override
  String get loReceiverDashboardTitle => 'Load Receiver Dashboard';

  @override
  String get loReceiverEmpty => 'Your incoming deliveries will appear here.';

  @override
  String get loReceiverRole => 'Load Receiver';

  @override
  String get loUploadBody => 'Body';

  @override
  String get loUploadBroadcastHint => 'Leave empty to broadcast to all';

  @override
  String get loUploadDropHint => 'Enter Destination';

  @override
  String get loUploadDropLocation => 'Drop Location';

  @override
  String get loUploadEntryDate => 'Entry Date';

  @override
  String get loUploadEntryMethod => 'Entry Method';

  @override
  String get loUploadExpectedContact => 'Expected Contact';

  @override
  String get loUploadExpectedContactBody =>
      'Our logistics coordinator will reach out within 15 minutes for final verification.';

  @override
  String get loUploadExpectedContactHighlight => '15 minutes';

  @override
  String get loUploadFleetStatus => 'Fleet Status';

  @override
  String get loUploadFleetStatusBody =>
      '4 heavy-duty trailers are currently available in your pickup zone.';

  @override
  String get loUploadFloor => 'Floor';

  @override
  String get loUploadMaterialType => 'Material Type';

  @override
  String get loUploadMaterialWeight => 'Material Weight';

  @override
  String get loUploadMethodBulk => 'BULK';

  @override
  String get loUploadMethodManual => 'MANUAL';

  @override
  String get loUploadMethodPhoto => 'PHOTO';

  @override
  String get loUploadNavDocs => 'Docs';

  @override
  String get loUploadNavTracking => 'Tracking';

  @override
  String get loUploadNewLoad => 'New Load';

  @override
  String get loUploadNewLoadRequirement => 'New Load Requirement';

  @override
  String get loUploadPickDate => 'Pick date';

  @override
  String get loUploadPickupHint => 'Enter Origin Hub';

  @override
  String get loUploadProcessUpdate => 'Process Update';

  @override
  String get loUploadProcessUpdateBody =>
      'Fleet optimization algorithms are calculating the most efficient route for your cargo.';

  @override
  String get loUploadReferenceId => 'Reference ID';

  @override
  String get loUploadSearchPartnerHint => 'Search Logistic Partner here';

  @override
  String get loUploadSelect => 'Select';

  @override
  String get loUploadSelectMaterial => 'Select material';

  @override
  String get loUploadSelected => 'Selected';

  @override
  String get loUploadSendTo => 'Send To';

  @override
  String get loUploadSoonBadge => 'SOON';

  @override
  String get loUploadSubmitButton => 'Submit Load Requirement';

  @override
  String get loUploadSubmitFailed => 'Submission failed. Please try again.';

  @override
  String loUploadSuccessBody(int count, String material) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
    );
    return 'Your load requirement for $_temp0 of $material has been received. Our team is now assigning the fleet.';
  }

  @override
  String get loUploadSuccessTitle => 'Submission Successful';

  @override
  String get loUploadTargetPartners => 'Target Partners';

  @override
  String get loUploadTrackInTrips => 'Track in My Trips';

  @override
  String get loUploadTruckCount => 'Truck Count';

  @override
  String get loUploadTruckRequirements => 'Truck Requirements';

  @override
  String get loUploadTruckWeightOptional => 'Truck Weight (Optional)';

  @override
  String get loUploadUnits => 'Units';

  @override
  String get loUploadValAxle => 'Please select an axle type';

  @override
  String get loUploadValBody => 'Please select a body type';

  @override
  String get loUploadValDate => 'Please select an entry date';

  @override
  String get loUploadValDrop => 'Please enter a drop location';

  @override
  String get loUploadValFloor => 'Please select a floor type';

  @override
  String get loUploadValMaterial => 'Please select a material type';

  @override
  String get loUploadValMaterialWeight => 'Please enter the material weight';

  @override
  String get loUploadValPartner => 'Please select a logistic partner';

  @override
  String get loUploadValPickup => 'Please enter a pickup location';

  @override
  String get loUploadValTruckCount => 'Truck count can\'t be zero';

  @override
  String get loUploadValTruckWeight =>
      'Enter a valid truck weight, or leave it blank';

  @override
  String get loWorkerHomeBuilding =>
      'Your load owner worker workspace is being built. Check back soon.';

  @override
  String get loWorkerHomeFallbackName => 'Worker';

  @override
  String get loWorkerHomeTitle => 'Load Owner Worker Dashboard';

  @override
  String loWorkerHomeWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get transporterComingSoonBody =>
      'This dashboard is currently under\ndevelopment and will be available soon.';

  @override
  String get transporterDashboardTitle => 'Transporter Dashboard';

  @override
  String get drvAddAdding => 'Adding Driver...';

  @override
  String get drvAddButton => 'Add Driver to Fleet';

  @override
  String get drvAddCancelReturn => 'Cancel and return';

  @override
  String get drvAddDatesRequired =>
      'License issue date and expiry date are required';

  @override
  String get drvAddEmail => 'Email Address';

  @override
  String get drvAddEmailInvalid => 'Enter a valid email address';

  @override
  String get drvAddExpiryAfterIssue =>
      'License expiry date must be after issue date';

  @override
  String get drvAddExpiryFuture => 'License expiry date must be in the future';

  @override
  String drvAddFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get drvAddFirstName => 'First Name';

  @override
  String get drvAddFixErrors => 'Please fix the errors in the form';

  @override
  String drvAddHintExample(String value) {
    return 'e.g. $value';
  }

  @override
  String get drvAddJoinDate => 'Join Date';

  @override
  String get drvAddJoinFuture => 'Join date cannot be in the future';

  @override
  String get drvAddLastName => 'Last Name';

  @override
  String get drvAddLicenseClass => 'License Class';

  @override
  String get drvAddLicenseFormat =>
      'License must be 10-50 alphanumeric characters';

  @override
  String get drvAddLicenseHmv => 'HMV (Heavy Motor Vehicle)';

  @override
  String get drvAddLicenseHpmv => 'HPMV (Heavy Passenger Motor Vehicle)';

  @override
  String get drvAddLicenseLmv => 'LMV (Light Motor Vehicle)';

  @override
  String get drvAddLicenseMcwg => 'MCWG (Motorcycle with Gear)';

  @override
  String get drvAddLicenseRequired => 'License number is required';

  @override
  String get drvAddLicenseScan => 'License Document Scan';

  @override
  String get drvAddLicenseScanHint => 'Upload clear scan or photo';

  @override
  String get drvAddPasswordDigit => 'Must include a digit';

  @override
  String get drvAddPasswordHint => 'Min 8 chars, with uppercase & digit';

  @override
  String get drvAddPasswordLength => 'Password must be at least 8 characters';

  @override
  String get drvAddPasswordLower => 'Must include a lowercase letter';

  @override
  String get drvAddPasswordRequired => 'Password is required';

  @override
  String get drvAddPasswordUpper => 'Must include an uppercase letter';

  @override
  String get drvAddPhoneDigits => 'Phone must be 10 digits';

  @override
  String get drvAddPhoneRequired => 'Phone number is required';

  @override
  String drvAddPhotoFailed(String error) {
    return 'Driver added, but photo upload failed: $error';
  }

  @override
  String get drvAddPhotoHint => 'PNG, JPG up to 5MB';

  @override
  String get drvAddPhotoSelected => 'Photo selected — tap to change';

  @override
  String get drvAddProgress => 'REGISTRATION PROGRESS';

  @override
  String get drvAddRoleLogistics => 'Logistics';

  @override
  String get drvAddRoleSupport => 'Support';

  @override
  String get drvAddSectionLogin => 'Login Credentials';

  @override
  String get drvAddSectionRole => 'Assignment & Role';

  @override
  String get drvAddSelect => 'Select';

  @override
  String get drvAddStep => 'Step 1 of 3';

  @override
  String get drvAddSuccess => 'Driver added successfully!';

  @override
  String get drvAddSystemRole => 'System Role';

  @override
  String get drvAddTitle => 'Add New Driver';

  @override
  String get drvAddUploadPhoto => 'Upload Profile Photo';

  @override
  String get drvAddUsernameFormat =>
      'Username: 3-50 chars (letters, numbers, underscore)';

  @override
  String get drvAddUsernameRequired => 'Username is required';

  @override
  String get drvMgmtAddFirstHint => 'Tap + to add your first driver';

  @override
  String get drvMgmtCurrentlyOnLeave => 'Currently on leave';

  @override
  String get drvMgmtMainDepot => 'Main Depot';

  @override
  String get drvMgmtNoDrivers => 'No drivers yet';

  @override
  String get drvMgmtNoMatch => 'No drivers match your filter';

  @override
  String get drvMgmtSearchHint => 'Search drivers, employee ID...';

  @override
  String get drvMgmtStatusActive => 'Active';

  @override
  String get drvMgmtStatusAll => 'All';

  @override
  String get drvMgmtStatusAvailable => 'Available';

  @override
  String get drvMgmtStatusOnLeave => 'On Leave';

  @override
  String get drvMgmtStatusTerminated => 'Terminated';

  @override
  String get drvMgmtTitle => 'Drivers';

  @override
  String drvMgmtTotalMembers(int count) {
    return '$count total fleet members';
  }

  @override
  String get helpCenterArticleAddVehicle => 'How to add a new vehicle';

  @override
  String get helpCenterArticleAddVehicleDesc =>
      'Step-by-step guide to adding vehicles to your fleet';

  @override
  String helpCenterArticleDetailIntro(String title) {
    return 'This is a detailed article about: $title';
  }

  @override
  String get helpCenterArticleDriverPerms => 'Managing driver permissions';

  @override
  String get helpCenterArticleDriverPermsDesc =>
      'Learn how to assign and manage driver roles and permissions';

  @override
  String get helpCenterArticleMaintenance => 'Creating maintenance schedules';

  @override
  String get helpCenterArticleMaintenanceDesc =>
      'Keep your fleet running smoothly with scheduled maintenance';

  @override
  String get helpCenterArticlePlaceholder =>
      'Article content would go here with step-by-step instructions, screenshots, and helpful tips.';

  @override
  String get helpCenterArticleRealtimeTracking =>
      'Setting up real-time tracking';

  @override
  String get helpCenterArticleRealtimeTrackingDesc =>
      'Configure GPS tracking for your fleet vehicles';

  @override
  String get helpCenterAvgResponse => 'Average response time: 2 minutes';

  @override
  String get helpCenterBrowseByCategory => 'Browse by Category';

  @override
  String get helpCenterCatDriver => 'Driver Management';

  @override
  String get helpCenterCatDriverDesc =>
      'Driver profiles, licenses, and assignments';

  @override
  String get helpCenterCatFinancial => 'Financial Management';

  @override
  String get helpCenterCatFinancialDesc => 'Expenses, invoices, and payments';

  @override
  String get helpCenterCatMaintenance => 'Maintenance';

  @override
  String get helpCenterCatMaintenanceDesc =>
      'Schedules, repairs, and inspections';

  @override
  String get helpCenterCatReports => 'Reports & Analytics';

  @override
  String get helpCenterCatReportsDesc => 'Generating and exporting reports';

  @override
  String get helpCenterCatRoles => 'Roles & Permissions';

  @override
  String get helpCenterCatRolesDesc => 'User roles and access control';

  @override
  String get helpCenterCatTracking => 'Real-time Tracking';

  @override
  String get helpCenterCatTrackingDesc => 'GPS tracking and location services';

  @override
  String get helpCenterCatTrip => 'Trip Management';

  @override
  String get helpCenterCatTripDesc => 'Creating and monitoring trips';

  @override
  String get helpCenterCatVehicle => 'Vehicle Management';

  @override
  String get helpCenterCatVehicleDesc =>
      'Adding, editing, and managing vehicles';

  @override
  String get helpCenterChatWithTeam => 'Chat with our support team';

  @override
  String get helpCenterContactSupport => 'Contact Support';

  @override
  String get helpCenterEmailSupport => 'Email Support';

  @override
  String get helpCenterEmailUs => 'Email Us';

  @override
  String get helpCenterGettingStarted => 'Getting Started';

  @override
  String get helpCenterGuideTitle => 'Getting Started Guide';

  @override
  String get helpCenterIssueDescription => 'Description';

  @override
  String get helpCenterIssueReported => 'Issue reported successfully';

  @override
  String get helpCenterIssueTitle => 'Issue Title';

  @override
  String get helpCenterLiveChat => 'Live Chat';

  @override
  String get helpCenterMarkedHelpful => 'Article marked as helpful';

  @override
  String get helpCenterNeedMoreHelp => 'Need More Help?';

  @override
  String helpCenterNoResults(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get helpCenterNoResultsHint =>
      'Try different keywords or browse categories below';

  @override
  String helpCenterOpeningCategory(String category) {
    return 'Opening $category articles...';
  }

  @override
  String get helpCenterOpeningChat => 'Opening live chat...';

  @override
  String get helpCenterPhoneSupport => 'Phone Support';

  @override
  String get helpCenterPopularArticles => 'Popular Articles';

  @override
  String get helpCenterQuickActions => 'Quick Actions';

  @override
  String helpCenterReadMinutes(int minutes) {
    return '$minutes min read';
  }

  @override
  String get helpCenterReportIssue => 'Report Issue';

  @override
  String get helpCenterReportTitle => 'Report an Issue';

  @override
  String helpCenterResultsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results found',
      one: '1 result found',
    );
    return '$_temp0';
  }

  @override
  String get helpCenterSearchDriverPermsDesc =>
      'Learn how to assign and manage driver roles';

  @override
  String get helpCenterSearchGpsDesc => 'Configure real-time vehicle tracking';

  @override
  String get helpCenterSearchGpsTitle => 'Setting up GPS tracking';

  @override
  String get helpCenterSearchHint =>
      'Search for help articles, guides, FAQs...';

  @override
  String get helpCenterSearchMaintenanceDesc =>
      'Schedule regular vehicle maintenance';

  @override
  String get helpCenterSearchReportsDesc =>
      'Create and export financial reports';

  @override
  String get helpCenterSearchReportsTitle => 'Generating financial reports';

  @override
  String get helpCenterShowingAll => 'Showing all articles...';

  @override
  String get helpCenterStep1Desc => 'Sign up with your details';

  @override
  String get helpCenterStep1Title => 'Create Your Account';

  @override
  String get helpCenterStep2Desc => 'Create or join an organization';

  @override
  String get helpCenterStep2Title => 'Set Up Your Organization';

  @override
  String get helpCenterStep3Desc => 'Add vehicles to the system';

  @override
  String get helpCenterStep3Title => 'Add Your Fleet';

  @override
  String get helpCenterStep4Desc => 'Add drivers and staff';

  @override
  String get helpCenterStep4Title => 'Invite Team Members';

  @override
  String get helpCenterStep5Desc => 'Begin tracking and managing your fleet';

  @override
  String get helpCenterStep5Title => 'Start Managing';

  @override
  String get helpCenterSupport247 =>
      'Our support team is available 24/7 to assist you';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterVideoComingSoon => 'Video tutorials coming soon!';

  @override
  String get helpCenterVideoTutorials => 'Video Tutorials';

  @override
  String get helpCenterViewAll => 'View All';

  @override
  String get helpCenterWasHelpful => 'Was this helpful?';

  @override
  String get orgCreate10Chars => '10 characters';

  @override
  String get orgCreate15Chars => '15 characters';

  @override
  String get orgCreateAdd => 'Add';

  @override
  String get orgCreateAddressRequired => 'Address is required';

  @override
  String get orgCreateBusinessEmail => 'Business Email';

  @override
  String get orgCreateBusinessPhone => 'Business Phone';

  @override
  String get orgCreateBusinessType => 'Business Type';

  @override
  String get orgCreateBusinessTypeHint => 'e.g., Transportation, Logistics';

  @override
  String get orgCreateBusinessTypeRequired => 'Business type is required';

  @override
  String get orgCreateCity => 'City';

  @override
  String get orgCreateCompanyName => 'Company Name';

  @override
  String get orgCreateCompanyNameHint => 'e.g., Acme Logistics Pvt. Ltd.';

  @override
  String get orgCreateCompanyNameRequired => 'Company name is required';

  @override
  String get orgCreateCountry => 'Country';

  @override
  String get orgCreateEmailInvalid => 'Invalid email format';

  @override
  String get orgCreateEmailRequired => 'Business email is required';

  @override
  String orgCreateFailed(String error) {
    return 'Failed to create organization: $error';
  }

  @override
  String get orgCreateGstinInvalid => 'Invalid GSTIN format';

  @override
  String get orgCreateGstinLength => 'GSTIN must be exactly 15 characters';

  @override
  String get orgCreateHeaderSub => 'Set up your fleet workspace';

  @override
  String get orgCreateHeaderTitle => 'New Organization';

  @override
  String get orgCreateInvalid => 'Invalid';

  @override
  String get orgCreateLegalSub => 'GSTIN & PAN — Optional';

  @override
  String get orgCreateMin10Digits => 'Must be at least 10 digits';

  @override
  String get orgCreateMin2Chars => 'Must be at least 2 characters';

  @override
  String orgCreateOptionalLabel(String label) {
    return '$label (Optional)';
  }

  @override
  String get orgCreatePanInvalid => 'Invalid PAN format';

  @override
  String get orgCreatePanLength => 'PAN must be exactly 10 characters';

  @override
  String get orgCreatePanNumber => 'PAN Number';

  @override
  String get orgCreatePhoneRequired => 'Business phone is required';

  @override
  String get orgCreatePincode => 'Pincode';

  @override
  String get orgCreateRequired => 'Required';

  @override
  String get orgCreateSecAddress => 'Address';

  @override
  String get orgCreateSecCompany => 'Company Information';

  @override
  String get orgCreateSecContact => 'Contact Information';

  @override
  String get orgCreateSecLegal => 'Legal Information';

  @override
  String get orgCreateState => 'State';

  @override
  String get orgCreateStreetAddress => 'Street Address';

  @override
  String get orgCreateStreetAddressHint => 'Building, street, area…';

  @override
  String orgCreateSuccess(String name) {
    return 'Organization \"$name\" created successfully!';
  }

  @override
  String get orgCreateTitle => 'Create Organization';

  @override
  String get orgManageAllCaughtUp => 'All caught up!';

  @override
  String get orgManageApproveAssign => 'Approve & Assign Role';

  @override
  String orgManageApproveFailed(String error) {
    return 'Failed to approve user: $error';
  }

  @override
  String orgManageApproveTitle(String username) {
    return 'Approve $username';
  }

  @override
  String orgManageApproved(String username) {
    return '$username approved successfully';
  }

  @override
  String get orgManageAssignRole => 'Assign Role';

  @override
  String get orgManageChangeRole => 'Change Role';

  @override
  String orgManageHeaderSummary(int members, int pending) {
    return '$members members · $pending pending';
  }

  @override
  String get orgManageLoadFailed => 'Failed to load organization data.';

  @override
  String get orgManageMembersHint => 'Members will appear here';

  @override
  String orgManageMembersTab(int count) {
    return 'Members ($count)';
  }

  @override
  String orgManageNewRoleFor(String username) {
    return 'New role for $username';
  }

  @override
  String get orgManageNoMembers => 'No members yet';

  @override
  String get orgManageNoPending => 'No pending join requests';

  @override
  String orgManageNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get orgManageNoRole => 'No Role';

  @override
  String get orgManageOwner => 'Owner';

  @override
  String get orgManagePendingBadge => 'Pending';

  @override
  String orgManagePendingTab(int count) {
    return 'Pending ($count)';
  }

  @override
  String get orgManageRefresh => 'Refresh';

  @override
  String get orgManageReject => 'Reject';

  @override
  String orgManageRejectConfirm(String username) {
    return 'Reject $username\'s request to join?';
  }

  @override
  String orgManageRejectFailed(String error) {
    return 'Failed to reject: $error';
  }

  @override
  String get orgManageRejectUserTitle => 'Reject User';

  @override
  String orgManageRejected(String username) {
    return '$username rejected';
  }

  @override
  String get orgManageRemove => 'Remove';

  @override
  String orgManageRemoveConfirm(String username, String orgName) {
    return 'Remove $username from $orgName? They will lose access immediately.';
  }

  @override
  String orgManageRemoveFailed(String error) {
    return 'Failed to remove: $error';
  }

  @override
  String get orgManageRemoveTitle => 'Remove Member';

  @override
  String orgManageRemoved(String username) {
    return '$username removed';
  }

  @override
  String orgManageRequestedRole(String role) {
    return 'Requested: $role';
  }

  @override
  String get orgManageRoleAdmin => 'Admin';

  @override
  String get orgManageRoleAdminDesc => 'Manage members & settings';

  @override
  String get orgManageRoleDispatcher => 'Dispatcher';

  @override
  String get orgManageRoleDispatcherDesc => 'Manage trips & assignments';

  @override
  String orgManageRoleUpdateFailed(String error) {
    return 'Failed to update role: $error';
  }

  @override
  String get orgManageRoleUpdated => 'Role updated successfully';

  @override
  String get orgManageRoleUser => 'User';

  @override
  String get orgManageRoleUserDesc => 'Standard access to features';

  @override
  String get orgManageRoleViewer => 'Viewer';

  @override
  String get orgManageRoleViewerDesc => 'Read-only access';

  @override
  String get orgManageSearchHint => 'Search members…';

  @override
  String get orgManageSelectRole => 'Select a role to assign';

  @override
  String get orgSelectCreate => 'Create Organization';

  @override
  String get orgSelectCreateNew => 'Create New Organization';

  @override
  String get orgSelectCreateNewSub => 'Set up your own fleet organization';

  @override
  String get orgSelectNoOrgs => 'No Organizations Yet';

  @override
  String get orgSelectNoOrgsBody =>
      'Create your own or ask an admin to add you to an existing organization.';

  @override
  String get orgSelectNoRole => 'No Role';

  @override
  String get orgSelectSwitchFailed => 'Failed to switch organization';

  @override
  String orgSelectSwitched(String name) {
    return 'Switched to $name';
  }

  @override
  String get orgSelectTitle => 'Select Organization';

  @override
  String get orgSelectTryAgain => 'Try again';

  @override
  String get orgSelectUser => 'User';

  @override
  String get orgSelectWelcome => 'Welcome back,';

  @override
  String get orgSelectWrong => 'Something went wrong';

  @override
  String get orgSelectYourOrgs => 'Your Organizations';

  @override
  String get profileAccountStatus => 'Account Status';

  @override
  String get profileAuthEmailPassword => 'Email & Password';

  @override
  String get profileAuthMethod => 'Auth Method';

  @override
  String get profileAuthSecurityQuestions => 'Security Questions';

  @override
  String get profileBecameDriver => 'Role changed to Driver successfully!';

  @override
  String get profileBecomeDriver => 'Become Driver';

  @override
  String get profileBecomeDriverTitle => 'Become a Driver';

  @override
  String get profileCancelPendingMessage =>
      'This will cancel your pending organization request and return you to Independent User status. You can join or create an organization again at any time.';

  @override
  String get profileCancelPendingTitle => 'Cancel Pending Request?';

  @override
  String get profileChange => 'Change';

  @override
  String get profileChangeOrganization => 'Change Organization';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileChangeRoleChoose =>
      'Choose how you want to change your role:';

  @override
  String get profileChangeRoleFailed => 'Failed to change role';

  @override
  String get profileChangeRolePending =>
      'Your request is pending. What would you like to do?';

  @override
  String get profileChangeRoleTitle => 'Change Role';

  @override
  String get profileCompany => 'Company';

  @override
  String get profileCreateOrganization => 'Create Organization';

  @override
  String get profileDefaultUser => 'User';

  @override
  String get profileDriverLicenseIntro => 'Enter your driver license details:';

  @override
  String get profileEditBanner =>
      'Edit mode — tap ✓ in the toolbar to save changes';

  @override
  String get profileEditTooltip => 'Edit Profile';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileEnterLicenseExpiry => 'Please enter license expiry date';

  @override
  String get profileEnterLicenseNumber => 'Please enter license number';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileFullNameRequired => 'Full name is required';

  @override
  String get profileGoIndependent => 'Go Independent';

  @override
  String profileImageReadError(String error) {
    return 'Error reading image: $error';
  }

  @override
  String profileImageSelectError(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get profileIndependentOptions => 'As an Independent User, you can:';

  @override
  String get profileJoinFailed => 'Failed to join organization';

  @override
  String get profileJoinOrganization => 'Join Organization';

  @override
  String get profileJoinSubmitted =>
      'Join request submitted! Awaiting approval.';

  @override
  String get profileKeepPending => 'Keep Pending';

  @override
  String get profileLicenseExpiry => 'License Expiry (YYYY-MM-DD)';

  @override
  String get profileLicenseNumber => 'License Number';

  @override
  String get profileNewPhotoSelected =>
      'New photo selected · tap Save to apply';

  @override
  String get profileNoPreference => 'No preference';

  @override
  String get profileNoRole => 'No Role';

  @override
  String get profileNone => 'None';

  @override
  String get profileNotAssigned => 'Not assigned';

  @override
  String get profileNotAvailable => 'N/A';

  @override
  String get profileNowIndependent => 'You are now an Independent User.';

  @override
  String get profilePendingOptions =>
      'Your request is pending approval. You can:';

  @override
  String get profilePersonalInfo => 'Personal Information';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profilePhotoAddHint => 'Tap to add a photo';

  @override
  String get profilePhotoChangeHint =>
      'Tap to change photo · long-press to remove';

  @override
  String get profileRemove => 'Remove';

  @override
  String get profileRemovePictureFailed => 'Failed to remove profile picture';

  @override
  String get profileRemovePictureMessage =>
      'Are you sure you want to remove your profile picture?';

  @override
  String get profileRemovePictureTitle => 'Remove Profile Picture';

  @override
  String get profileRequestedRole => 'Requested Role (Optional)';

  @override
  String get profileRole => 'Role';

  @override
  String get profileRoleAccountant => 'Accountant';

  @override
  String get profileRoleComplianceOfficer => 'Compliance Officer';

  @override
  String get profileRoleCustomerService => 'Customer Service';

  @override
  String get profileRoleDispatcher => 'Dispatcher';

  @override
  String get profileRoleFleetManager => 'Fleet Manager';

  @override
  String get profileRoleMaintenanceManager => 'Maintenance Manager';

  @override
  String get profileRoleMaintenanceTechnician => 'Maintenance Technician';

  @override
  String get profileRoleManaged => 'Your role is managed by your organization.';

  @override
  String get profileRoleOperationsManager => 'Operations Manager';

  @override
  String get profileRoleOrg => 'Role & Organization';

  @override
  String get profileRoleUpdateFailed => 'Failed to update role';

  @override
  String get profileRoleViewerAnalyst => 'Viewer / Analyst';

  @override
  String get profileStatus => 'Profile Status';

  @override
  String get profileStatusCompleted => 'Completed';

  @override
  String get profileStatusIncomplete => 'Incomplete';

  @override
  String get profileStatusLabel => 'Status';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileUnknown => 'Unknown';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get profileUploadPictureFailed => 'Failed to upload profile picture';

  @override
  String get profileUsername => 'Username';

  @override
  String get customRoleAfterCreateNote =>
      'After creation, you\'ll be taken to the role editor to configure capabilities.';

  @override
  String get customRoleCapabilities => 'Capabilities';

  @override
  String customRoleCapabilityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capabilities',
      one: '1 capability',
    );
    return '$_temp0';
  }

  @override
  String get customRoleCatCompliance => 'Compliance & Safety';

  @override
  String get customRoleCatCustomer => 'Customer Management';

  @override
  String get customRoleCatDriver => 'Driver Management';

  @override
  String get customRoleCatFinancial => 'Financial Management';

  @override
  String get customRoleCatMaintenance => 'Maintenance';

  @override
  String get customRoleCatReporting => 'Reporting & Analytics';

  @override
  String get customRoleCatRole => 'Role Management';

  @override
  String get customRoleCatSystem => 'System Settings';

  @override
  String get customRoleCatTracking => 'Tracking & Monitoring';

  @override
  String get customRoleCatTrip => 'Trip Management';

  @override
  String get customRoleCatUser => 'User Management';

  @override
  String get customRoleCatVehicle => 'Vehicle Management';

  @override
  String customRoleCategoryEnabled(int enabled, int total) {
    return '$enabled / $total capabilities enabled';
  }

  @override
  String get customRoleChooseMethod => 'Choose creation method';

  @override
  String get customRoleChooseMethodHint =>
      'Start from a predefined template or build from scratch';

  @override
  String get customRoleCreateButton => 'Create Role';

  @override
  String customRoleCreateFailed(String error) {
    return 'Failed to create role: $error';
  }

  @override
  String get customRoleCreateTitle => 'Create Custom Role';

  @override
  String get customRoleCreated => 'Custom role created successfully';

  @override
  String get customRoleCreating => 'Creating...';

  @override
  String get customRoleDescription => 'Description';

  @override
  String get customRoleDescriptionHint => 'Describe the purpose of this role';

  @override
  String get customRoleDescriptionOptional => 'Description (Optional)';

  @override
  String get customRoleDetailsHint =>
      'Give your custom role a name and description';

  @override
  String get customRoleDetailsTitle => 'Role Details';

  @override
  String get customRoleEditTitle => 'Edit Custom Role';

  @override
  String customRoleEnabledCount(int enabled, int total) {
    return '$enabled / $total enabled';
  }

  @override
  String get customRoleFromScratch => 'From Scratch';

  @override
  String get customRoleFromScratchDesc =>
      'Build a completely custom role with your own capabilities. Configure everything manually.';

  @override
  String get customRoleFromScratchTitle => 'Start from Scratch';

  @override
  String get customRoleFromTemplate => 'From Template';

  @override
  String get customRoleFromTemplateDesc =>
      'Use predefined role templates as a starting point. Inherit capabilities and customize.';

  @override
  String get customRoleFromTemplateTitle => 'Start from Template';

  @override
  String get customRoleInfoTitle => 'Role Information';

  @override
  String get customRoleIntersection => 'Intersection (Only Common)';

  @override
  String get customRoleIntersectionCommon => 'Intersection (Common Only)';

  @override
  String get customRoleIntersectionDesc =>
      'Include only capabilities shared by all selected templates';

  @override
  String get customRoleLeave => 'Leave';

  @override
  String get customRoleLevelFull => 'Full';

  @override
  String get customRoleLevelLimited => 'Limited';

  @override
  String get customRoleLevelNone => 'None';

  @override
  String get customRoleLevelView => 'View';

  @override
  String get customRoleLoadFailed => 'Failed to load role';

  @override
  String get customRoleMergeStrategy => 'Merge Strategy';

  @override
  String get customRoleNameHint => 'e.g., Regional Manager - West Coast';

  @override
  String get customRoleNameLabel => 'Role Name';

  @override
  String get customRoleNameRequired => 'Please enter a role name';

  @override
  String get customRoleNameRequiredShort => 'Role name required';

  @override
  String get customRoleNoDescription => 'No description';

  @override
  String get customRoleNotSet => '(not set)';

  @override
  String get customRoleQuickAll => 'All';

  @override
  String get customRoleReviewHint =>
      'Confirm your custom role details before creating';

  @override
  String get customRoleReviewTitle => 'Review & Create';

  @override
  String get customRoleSaveChanges => 'Save Changes';

  @override
  String get customRoleSaving => 'Saving...';

  @override
  String get customRoleSelectOneTemplate =>
      'Please select at least one template';

  @override
  String get customRoleSelectTemplates => 'Select Templates';

  @override
  String get customRoleSelectTemplatesHint =>
      'Choose one or more templates to combine';

  @override
  String customRoleSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get customRoleStay => 'Stay';

  @override
  String get customRoleStepDetails => 'Details';

  @override
  String get customRoleStepMethod => 'Method';

  @override
  String get customRoleStepReview => 'Review';

  @override
  String get customRoleStepTemplates => 'Templates';

  @override
  String get customRoleSystemCritical =>
      'System critical – restricted to super admin';

  @override
  String customRoleTemplateError(String error) {
    return 'Error: $error';
  }

  @override
  String customRoleTemplatePreselected(String names) {
    return 'Template pre-selected: $names';
  }

  @override
  String get customRoleUnion => 'Union (Combine All)';

  @override
  String get customRoleUnionDesc =>
      'Include all capabilities from all selected templates';

  @override
  String get customRoleUnsavedBody =>
      'You have unsaved changes. Do you want to leave without saving?';

  @override
  String get customRoleUnsavedTitle => 'Unsaved Changes';

  @override
  String get customRoleUpdateFailed => 'Failed to update role';

  @override
  String customRoleUpdateFailedWithError(String error) {
    return 'Failed to update role: $error';
  }

  @override
  String get customRoleUpdated => 'Role updated successfully';

  @override
  String customRolesActiveMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active members',
      one: '1 active member',
    );
    return '$_temp0';
  }

  @override
  String get customRolesApprove => 'Approve';

  @override
  String get customRolesApproveFailed => 'Failed to approve request';

  @override
  String get customRolesApproveTitle => 'Approve Request';

  @override
  String customRolesApprovedOk(String name) {
    return '$name approved successfully!';
  }

  @override
  String customRolesApprovingFrom(String name) {
    return 'Approving join request from $name.';
  }

  @override
  String get customRolesAssignRole => 'Assign Role:';

  @override
  String customRolesCapabilityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capabilities',
      one: '1 capability',
    );
    return '$_temp0';
  }

  @override
  String get customRolesChangeRole => 'Change Role';

  @override
  String get customRolesChangeRoleTitle => 'Change Member Role';

  @override
  String get customRolesClone => 'Clone';

  @override
  String get customRolesCloneFailed => 'Failed to clone';

  @override
  String get customRolesCloneTitle => 'Clone Role';

  @override
  String get customRolesCloned => 'Role cloned successfully';

  @override
  String get customRolesCreateFirst => 'Create Your First Role';

  @override
  String get customRolesCreateFromTemplate =>
      'Create Custom Role from This Template';

  @override
  String get customRolesCreateRole => 'Create Custom Role';

  @override
  String get customRolesCustomBadge => 'custom';

  @override
  String get customRolesDeleteConfirm =>
      'Are you sure you want to delete this role? This cannot be undone.';

  @override
  String get customRolesDeleteFailed => 'Failed to delete role';

  @override
  String get customRolesDeleteTitle => 'Delete Role';

  @override
  String get customRolesDeleted => 'Role deleted successfully';

  @override
  String get customRolesDescriptionOptional => 'Description (optional)';

  @override
  String get customRolesNewRole => 'New Role:';

  @override
  String get customRolesNewRoleName => 'New Role Name';

  @override
  String get customRolesNoCapabilities => 'No capabilities listed';

  @override
  String get customRolesNoCustomSubtitle =>
      'Create custom roles tailored to your organization';

  @override
  String get customRolesNoCustomTitle => 'No Custom Roles Yet';

  @override
  String get customRolesNoMembersSubtitle =>
      'Approve pending requests to add members to your organization.';

  @override
  String get customRolesNoMembersTitle => 'No Members Yet';

  @override
  String get customRolesNoPendingSubtitle =>
      'All join requests have been processed.';

  @override
  String get customRolesNoPendingTitle => 'No Pending Requests';

  @override
  String get customRolesNoRole => 'No Role';

  @override
  String get customRolesNoRoleRequested => 'No role requested';

  @override
  String get customRolesNoTemplates => 'No predefined templates found';

  @override
  String get customRolesNoTemplatesHint =>
      'Templates are seeded automatically on server startup.';

  @override
  String customRolesPendingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members waiting to join your organization',
      one: '1 member waiting to join your organization',
    );
    return '$_temp0';
  }

  @override
  String get customRolesRefresh => 'Refresh';

  @override
  String get customRolesReject => 'Reject';

  @override
  String customRolesRejectConfirm(String name) {
    return 'Reject join request from $name? They will need to reapply to join.';
  }

  @override
  String get customRolesRejectFailed => 'Failed to reject request';

  @override
  String get customRolesRejectTitle => 'Reject Request';

  @override
  String get customRolesRejected => 'Request rejected.';

  @override
  String get customRolesRoleUpdateFailed => 'Failed to update role';

  @override
  String customRolesRoleUpdated(String name) {
    return 'Role updated for $name';
  }

  @override
  String get customRolesSaveAsTemplate => 'Save as Template';

  @override
  String get customRolesSavedTemplate => 'Saved Template';

  @override
  String get customRolesSelectRole => 'Select role';

  @override
  String get customRolesSubtitle => 'Manage roles, permissions & team members';

  @override
  String get customRolesTabCustom => 'Custom';

  @override
  String get customRolesTabMembers => 'Members';

  @override
  String get customRolesTabPending => 'Pending';

  @override
  String get customRolesTabTemplates => 'Templates';

  @override
  String get customRolesTemplateName => 'Template Name';

  @override
  String get customRolesTemplateSaveFailed => 'Failed to save template';

  @override
  String get customRolesTemplateSaved => 'Saved as template';

  @override
  String customRolesTemplatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Templates',
      one: '1 Template',
    );
    return '$_temp0';
  }

  @override
  String get customRolesTitle => 'Roles & Permissions';

  @override
  String get customRolesUnknown => 'Unknown';

  @override
  String get customRolesUnknownRole => 'Unknown Role';

  @override
  String get customRolesUpdate => 'Update';

  @override
  String customRolesUpdateRoleFor(String name) {
    return 'Update role for $name';
  }

  @override
  String get customRolesUse => 'Use';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsAutoSync => 'Auto-sync Data';

  @override
  String get settingsAutoSyncDesc => 'Sync automatically when online';

  @override
  String get settingsBackgroundTracking => 'Background Tracking';

  @override
  String get settingsBackgroundTrackingDesc =>
      'Continue tracking when app is in background';

  @override
  String get settingsBiometricLock => 'Biometric Lock';

  @override
  String get settingsBiometricLockDesc => 'Fingerprint or Face ID to unlock';

  @override
  String get settingsCacheCleared => 'Cache cleared successfully';

  @override
  String get settingsClearCache => 'Clear Cache';

  @override
  String get settingsClearCacheDesc => 'Free up device storage space';

  @override
  String get settingsClearCacheMessage =>
      'This will clear all cached data and free up storage space. Your account data will not be affected.';

  @override
  String get settingsCompactView => 'Compact View';

  @override
  String get settingsCompactViewDesc => 'Show more items on screen';

  @override
  String get settingsCurrentlyTracking => 'Currently tracking location';

  @override
  String get settingsDangerZone => 'DANGER ZONE';

  @override
  String get settingsDataStorage => 'Data & Storage';

  @override
  String get settingsDefaultName => 'Fleet Manager';

  @override
  String get settingsDisplay => 'Display';

  @override
  String get settingsDriverUpdates => 'Driver Updates';

  @override
  String get settingsDriverUpdatesDesc => 'Driver assignment alerts';

  @override
  String get settingsFreqBalanced => 'Balanced';

  @override
  String get settingsFreqBattery => 'Battery';

  @override
  String get settingsFreqHigh => 'High';

  @override
  String get settingsFreqLow => 'Low';

  @override
  String get settingsGpsTracking => 'GPS Tracking';

  @override
  String get settingsGpsTrackingDescOff =>
      'Contact administrator to enable tracking';

  @override
  String get settingsGpsTrackingDescOn =>
      'Enable location tracking for real-time updates';

  @override
  String get settingsGrant => 'Grant';

  @override
  String get settingsHelpSupport => 'Help & Support';

  @override
  String settingsLocationPermission(String status) {
    return 'Location permission: $status';
  }

  @override
  String get settingsLocationTracking => 'Location & Tracking';

  @override
  String settingsMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsOfflineMode => 'Offline Mode';

  @override
  String get settingsOfflineModeDesc => 'Cache data for offline access';

  @override
  String get settingsPermAlways => 'Always';

  @override
  String get settingsPermDenied => 'Permission Denied';

  @override
  String get settingsPermDeniedForever => 'Permission Permanently Denied';

  @override
  String get settingsPermServiceDisabled => 'Location Service Disabled';

  @override
  String get settingsPermWhileInUse => 'While In Use';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacySecurity => 'Privacy & Security';

  @override
  String get settingsPushNotifications => 'Push Notifications';

  @override
  String get settingsPushNotificationsDesc => 'Receive important app alerts';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get settingsResetDefaults => 'Reset to Default Settings';

  @override
  String get settingsResetDefaultsDesc =>
      'Restore all settings to factory defaults';

  @override
  String get settingsResetDone => 'Settings reset to defaults';

  @override
  String get settingsResetMessage =>
      'This will reset all settings to their default values. Are you sure you want to continue?';

  @override
  String get settingsResetTitle => 'Reset Settings';

  @override
  String settingsSecondsAgo(int count) {
    return '${count}s ago';
  }

  @override
  String get settingsShareAnalytics => 'Share Analytics';

  @override
  String get settingsShareAnalyticsDesc => 'Help improve the app anonymously';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutDesc => 'Sign out of your account';

  @override
  String get settingsSubtitle => 'Preferences & Configuration';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeDesc => 'Choose app appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTrackingAdminOff =>
      'GPS tracking disabled — contact administrator';

  @override
  String get settingsTrackingAdminOn => 'GPS tracking enabled by administrator';

  @override
  String get settingsTripUpdates => 'Trip Updates';

  @override
  String get settingsTripUpdatesDesc => 'Trip status changes';

  @override
  String get settingsUpToDate => 'Up to date';

  @override
  String get settingsUpdateFrequency => 'Update Frequency';

  @override
  String get settingsUpdateFrequencyDesc => 'How often to update location';

  @override
  String get settingsVehicleAlerts => 'Vehicle Alerts';

  @override
  String get settingsVehicleAlertsDesc => 'Maintenance & status alerts';

  @override
  String get settingsViewLiveTracking => 'View Live Tracking';

  @override
  String get settingsViewLiveTrackingDesc => 'See your current location on map';

  @override
  String get vehAddChooseFile => 'Choose File';

  @override
  String get vehAddChoosePhoto => 'Choose Photo';

  @override
  String get vehAddFillRequired => 'Please fill in all required fields';

  @override
  String get vehAddFuelCng => 'CNG';

  @override
  String get vehAddFuelDiesel => 'Diesel';

  @override
  String get vehAddFuelElectric => 'Electric';

  @override
  String get vehAddFuelHybrid => 'Hybrid';

  @override
  String get vehAddFuelLpg => 'LPG';

  @override
  String get vehAddFuelPetrol => 'Petrol';

  @override
  String get vehAddFuelType => 'Fuel Type *';

  @override
  String vehAddHintExample(String value) {
    return 'e.g. $value';
  }

  @override
  String get vehAddInfoNote =>
      'By adding this vehicle, it will be automatically synchronized with your maintenance schedule and fuel tracking logs. Ensure the VIN is correct to receive automated manufacturer recalls.';

  @override
  String get vehAddInvalidYear => 'Please enter a valid year';

  @override
  String get vehAddLicensePlate => 'License Plate *';

  @override
  String get vehAddMake => 'Make *';

  @override
  String get vehAddModel => 'Model *';

  @override
  String get vehAddOdometer => 'Initial Odometer (km)';

  @override
  String vehAddPhotoFailed(String error) {
    return 'Vehicle created, but photo upload failed: $error';
  }

  @override
  String get vehAddPhotoSubtitle => 'Upload or take a high-quality photo';

  @override
  String get vehAddPhotoTitle => 'Vehicle Photo';

  @override
  String get vehAddRegister => 'Register Vehicle';

  @override
  String get vehAddRegistering => 'Registering...';

  @override
  String get vehAddRemovePhoto => 'Remove Photo';

  @override
  String get vehAddSectionIdentification => 'Identification';

  @override
  String get vehAddSectionSpecifications => 'Specifications';

  @override
  String get vehAddSectionTechnical => 'Technical Details';

  @override
  String get vehAddSuccess => 'Vehicle registered successfully!';

  @override
  String get vehAddTakePhoto => 'Take a Photo';

  @override
  String get vehAddTypeBus => 'Bus';

  @override
  String get vehAddTypeCar => 'Car';

  @override
  String get vehAddTypeMotorcycle => 'Motorcycle';

  @override
  String get vehAddTypeOther => 'Other';

  @override
  String get vehAddTypeSuv => 'SUV';

  @override
  String get vehAddTypeTruck => 'Truck';

  @override
  String get vehAddTypeVan => 'Van';

  @override
  String get vehAddVehicleNumber => 'Vehicle Number *';

  @override
  String get vehAddVehicleType => 'Vehicle Type *';

  @override
  String get vehAddVin => 'VIN (optional)';

  @override
  String get vehAddVinHint => '17-character VIN';

  @override
  String get vehAddYear => 'Year *';

  @override
  String get vehListClearFilters => 'Clear Filters';

  @override
  String get vehListEmptyHint => 'Add your first vehicle to get started';

  @override
  String get vehListEmptyTitle => 'No Vehicles Yet';

  @override
  String get vehListFilterAll => 'All Vehicles';

  @override
  String vehListKm(String value) {
    return '$value km';
  }

  @override
  String get vehListNoDriver => 'No driver';

  @override
  String get vehListNoDriverAssigned => 'No driver assigned';

  @override
  String get vehListNotFoundHint => 'Try adjusting your search or filters';

  @override
  String get vehListNotFoundTitle => 'No Vehicles Found';

  @override
  String vehListRegisteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles registered',
      one: '$count vehicle registered',
    );
    return '$_temp0';
  }

  @override
  String get vehListSearchHint => 'Search by registration, make, model...';

  @override
  String get vehListSortMake => 'Make';

  @override
  String get vehListSortMileage => 'Mileage';

  @override
  String get vehListSortRegistration => 'Registration';

  @override
  String get vehListStatusActive => 'Active';

  @override
  String get vehListStatusInactive => 'Inactive';

  @override
  String get vehListStatusMaintenance => 'Maintenance';

  @override
  String get vehListTitle => 'Fleet Vehicles';

  @override
  String get bookingActionFailed => 'Could not complete the action - try again';

  @override
  String get bookingReasonLabel => 'Reason (required)';

  @override
  String get bookingReasonHint => 'Write why this is being cancelled';

  @override
  String get bookingAreYouSure => 'Are you sure?';

  @override
  String get bookingNoGoBack => 'No, go back';

  @override
  String get bookingWeightRecorded =>
      'The truck is loaded (weight recorded), so this booking can\'t be cancelled.';

  @override
  String get bookingCancelTitle => 'Cancel truck booking';

  @override
  String get bookingCancelPointRr =>
      'The booking is cancelled in RR web right away, with your reason.';

  @override
  String get bookingCancelPointTrip =>
      'This trip loses the truck, driver and truck owner, their Stage 1 papers and the Stage 2-3 truck checks. The loading slip, e-way bill and invoice stay.';

  @override
  String get bookingCancelPointNext =>
      'Then book another truck, or cancel the trip.';

  @override
  String get bookingCancelPointNoUndo => 'This cannot be undone.';

  @override
  String bookingCancelSure(String vehicle) {
    return 'Cancel the booking of truck $vehicle? This cannot be undone.';
  }

  @override
  String get bookingCancelYes => 'Yes, cancel booking';

  @override
  String get bookingCancelDone => 'Booking cancelled';

  @override
  String get bookingCancelTripBookedFirst => 'Cancel the booking first';

  @override
  String get bookingCancelTripTitle => 'Cancel trip';

  @override
  String get bookingCancelTripPointRr =>
      'The trip is cancelled in RR web right away.';

  @override
  String get bookingCancelTripPointReason =>
      'Your reason is kept in this app (RR web has no field for it).';

  @override
  String get bookingCancelTripPointNoUndo =>
      'A cancelled trip can never be booked or synced again.';

  @override
  String bookingCancelTripSure(String trip) {
    return 'Cancel trip $trip? This cannot be undone.';
  }

  @override
  String get bookingCancelTripYes => 'Yes, cancel trip';

  @override
  String get bookingCancelTripDone => 'Trip cancelled';

  @override
  String get bookingRebookTitle => 'Book another truck';

  @override
  String bookingRebookIntro(String trip) {
    return 'Trip $trip: pick the truck owner\'s company, the truck, its driver and the booking amount. The truck is booked in RR web right away; then fill Stage 1 for the new truck.';
  }

  @override
  String get bookingRebookProviderPhone => 'Truck provider\'s phone number';

  @override
  String get bookingRebookFind => 'Find';

  @override
  String get bookingRebookCompany => 'Truck owner company';

  @override
  String get bookingRebookNoCompany => 'This person has no company in RR';

  @override
  String get bookingRebookTruck => 'Truck';

  @override
  String get bookingRebookNoCompanyOwnTrucks =>
      'No company in RR — his own trucks are listed below';

  @override
  String get bookingRebookNoOwnTrucks =>
      'This person has no trucks of his own in RR';

  @override
  String get bookingRebookNoTrucks => 'This company has no trucks in RR';

  @override
  String get bookingRebookDriver => 'Driver';

  @override
  String get bookingRebookDriverHint =>
      'This truck has no driver in RR - search a driver by name or phone';

  @override
  String get bookingRebookAmount => 'Booking Amount';

  @override
  String bookingRebookSure(String vehicle, String driver) {
    return 'Book truck $vehicle with driver $driver in RR web now?';
  }

  @override
  String get bookingRebookYes => 'Book truck';

  @override
  String get bookingRebookDone => 'Truck booked - now fill Stage 1';

  @override
  String get bookingMenuCancelBooking => 'Cancel booking';

  @override
  String get bookingMenuNoCancelWeight =>
      'Booking can\'t be cancelled (weight recorded)';

  @override
  String get bookingMenuRebook => 'Book another truck';

  @override
  String get bookingMenuCancelTrip => 'Cancel trip';

  @override
  String get bookingMenuCancelTripDisabled =>
      'Cancel trip (cancel the booking first)';

  @override
  String get bookingMoreActions => 'More actions';

  @override
  String get bookingBannerCancelled => 'Booking cancelled - book another truck';

  @override
  String get bookingHistoryTitle => 'Cancellations';

  @override
  String bookingHistoryWhenBy(String when, String user) {
    return '$when · by $user';
  }

  @override
  String bookingHistoryReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get stageS1AadhaarStart => 'Aadhaar number cannot start with 0 or 1';

  @override
  String get tripCardFeBookingCancelled => 'Truck booking cancelled';

  @override
  String get tripCardFeBookingCancelledHint =>
      'Let another truck be booked first';

  @override
  String get tripCardFeTripCancelled => 'Trip cancelled';

  @override
  String get tripCardFeTripCancelledHint => 'Fill other open trips';

  @override
  String get stageBookingCancelledHint => 'Book another vehicle owner first';

  @override
  String get bookingHistoryTitleAll => 'Booking history';

  @override
  String get rrWebUpdatedEntry => 'Updated on RR web';

  @override
  String rrWebChangedFields(String fields) {
    return 'Changed: $fields';
  }

  @override
  String get rrWebTripCancelled => 'Trip cancelled on RR web';

  @override
  String get rrWebBookingCancelled => 'Booking cancelled on RR web';

  @override
  String get rrWebRebooked => 'Another truck booked on RR web';

  @override
  String get rrWebDriverChanged => 'Driver changed on RR web';

  @override
  String rrWebTruckChange(String oldTruck, String newTruck) {
    return 'Truck: $oldTruck → $newTruck';
  }

  @override
  String rrWebNewDriver(String name) {
    return 'New driver: $name';
  }

  @override
  String get rrWebUpdated => 'Changed on RR web - trip updated';
}
