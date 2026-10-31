import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get commonLoading;

  /// Settings tile title for choosing the app language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Settings tile subtitle for choosing the app language
  ///
  /// In en, this message translates to:
  /// **'Choose English or Hindi'**
  String get settingsLanguageSubtitle;

  /// No description provided for @apiErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get apiErrorCancelled;

  /// No description provided for @apiErrorCannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Please check your connection.'**
  String get apiErrorCannotConnect;

  /// No description provided for @apiErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get apiErrorNetwork;

  /// No description provided for @apiErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error: {code}'**
  String apiErrorServer(String code);

  /// No description provided for @apiErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout. Please try again.'**
  String get apiErrorTimeout;

  /// No description provided for @apiErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get apiErrorUnexpected;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get authBackToLogin;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get authFieldRequired;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneNumber;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get authUnknownError;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get authVerifyEmail;

  /// No description provided for @codeVerifyExpiry.
  ///
  /// In en, this message translates to:
  /// **'Code expires in 24 hours'**
  String get codeVerifyExpiry;

  /// No description provided for @codeVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get codeVerifyFailed;

  /// No description provided for @codeVerifyHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get codeVerifyHeading;

  /// No description provided for @codeVerifyIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code'**
  String get codeVerifyIncomplete;

  /// No description provided for @codeVerifyInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the code below to verify your email'**
  String get codeVerifyInstruction;

  /// No description provided for @codeVerifySentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String codeVerifySentTo(String email);

  /// No description provided for @codeVerifySuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get codeVerifySuccess;

  /// No description provided for @emailVerifyCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email'**
  String get emailVerifyCodeHint;

  /// No description provided for @emailVerifyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get emailVerifyCodeLabel;

  /// No description provided for @emailVerifyCodeTooShort.
  ///
  /// In en, this message translates to:
  /// **'Verification code must be at least 6 characters'**
  String get emailVerifyCodeTooShort;

  /// No description provided for @emailVerifyEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code from your email below.'**
  String get emailVerifyEnterCode;

  /// No description provided for @emailVerifyError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String emailVerifyError(String error);

  /// No description provided for @emailVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get emailVerifyFailed;

  /// No description provided for @emailVerifyHeading.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get emailVerifyHeading;

  /// No description provided for @emailVerifyResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? Resend'**
  String get emailVerifyResend;

  /// No description provided for @emailVerifyResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email resent!'**
  String get emailVerifyResent;

  /// No description provided for @emailVerifySentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to:'**
  String get emailVerifySentTo;

  /// No description provided for @emailVerifyVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully! You can now login.'**
  String get emailVerifyVerified;

  /// No description provided for @loginBiometricSoon.
  ///
  /// In en, this message translates to:
  /// **'Biometric login coming soon'**
  String get loginBiometricSoon;

  /// No description provided for @loginBiometricTooltip.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get loginBiometricTooltip;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login to Fleet'**
  String get loginButton;

  /// No description provided for @loginCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile to continue'**
  String get loginCompleteProfile;

  /// No description provided for @loginCorporateId.
  ///
  /// In en, this message translates to:
  /// **'Corporate ID'**
  String get loginCorporateId;

  /// No description provided for @loginCorporateSoon.
  ///
  /// In en, this message translates to:
  /// **'Corporate SSO coming soon'**
  String get loginCorporateSoon;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginGoogleSoon.
  ///
  /// In en, this message translates to:
  /// **'Google SSO coming soon'**
  String get loginGoogleSoon;

  /// No description provided for @loginHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get loginHelpCenter;

  /// No description provided for @loginNewToFleet.
  ///
  /// In en, this message translates to:
  /// **'New to the fleet? '**
  String get loginNewToFleet;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get loginOrContinueWith;

  /// No description provided for @loginPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Wait for acceptance by company owner.\n\nOnce the company owner accepts your request, you will be able to log in.'**
  String get loginPendingMessage;

  /// No description provided for @loginPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get loginPendingTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Securely access your fleet dashboard'**
  String get loginSubtitle;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get loginUsernameHint;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to RR'**
  String get loginWelcome;

  /// No description provided for @signupAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get signupAcceptTerms;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get signupConfirmPasswordRequired;

  /// No description provided for @signupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupCreateAccount;

  /// No description provided for @signupEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email — e.g. name@company.com'**
  String get signupEmailInvalid;

  /// No description provided for @signupEmailNoAt.
  ///
  /// In en, this message translates to:
  /// **'Email must contain \"@\" — e.g. name@company.com'**
  String get signupEmailNoAt;

  /// No description provided for @signupEmailNoDomain.
  ///
  /// In en, this message translates to:
  /// **'Email must have a domain ending — e.g. .com or .in'**
  String get signupEmailNoDomain;

  /// No description provided for @signupEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get signupEmailRequired;

  /// No description provided for @signupFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupFullName;

  /// Example name shown as placeholder
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get signupFullNameHint;

  /// No description provided for @signupFullNameNoNumbers.
  ///
  /// In en, this message translates to:
  /// **'Do not enter numbers in full name — letters only'**
  String get signupFullNameNoNumbers;

  /// No description provided for @signupFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get signupFullNameRequired;

  /// No description provided for @signupFullNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Full name must be at least 2 characters'**
  String get signupFullNameTooShort;

  /// No description provided for @signupLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get signupLogIn;

  /// No description provided for @signupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match — please re-enter'**
  String get signupPasswordMismatch;

  /// No description provided for @signupPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get signupPasswordRequired;

  /// No description provided for @signupPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get signupPasswordTooShort;

  /// No description provided for @signupPhoneChecking.
  ///
  /// In en, this message translates to:
  /// **'Please wait — checking phone number availability'**
  String get signupPhoneChecking;

  /// No description provided for @signupPhoneLength.
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be exactly 10 digits'**
  String get signupPhoneLength;

  /// No description provided for @signupPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get signupPhoneRequired;

  /// No description provided for @signupPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered'**
  String get signupPhoneTaken;

  /// Short label on a toggle button; full form is "Security Questions"
  ///
  /// In en, this message translates to:
  /// **'Security Q'**
  String get signupSecurityQ;

  /// No description provided for @signupSuccessEmail.
  ///
  /// In en, this message translates to:
  /// **'Signup successful! Please check your email for verification link.'**
  String get signupSuccessEmail;

  /// No description provided for @signupTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signupTermsAnd;

  /// No description provided for @signupTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get signupTermsOfService;

  /// First part of a sentence continued by signupTermsOfService, signupTermsAnd, authPrivacyPolicy and signupTermsSuffix
  ///
  /// In en, this message translates to:
  /// **'By clicking Create Account, you agree to our '**
  String get signupTermsPrefix;

  /// End of the terms sentence; Hindi needs a verb here
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get signupTermsSuffix;

  /// No description provided for @signupUsernameChecking.
  ///
  /// In en, this message translates to:
  /// **'Please wait — checking username availability'**
  String get signupUsernameChecking;

  /// No description provided for @signupUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. johndoe or john99'**
  String get signupUsernameHint;

  /// No description provided for @signupUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get signupUsernameInvalid;

  /// No description provided for @signupUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get signupUsernameRequired;

  /// No description provided for @signupUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get signupUsernameTaken;

  /// No description provided for @signupUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get signupUsernameTooShort;

  /// No description provided for @signupWorkEmail.
  ///
  /// In en, this message translates to:
  /// **'Work Email'**
  String get signupWorkEmail;

  /// No description provided for @authAnswerAllQuestions.
  ///
  /// In en, this message translates to:
  /// **'Please answer all security questions'**
  String get authAnswerAllQuestions;

  /// No description provided for @authAnswerSecurityQuestions.
  ///
  /// In en, this message translates to:
  /// **'Answer Your Security Questions'**
  String get authAnswerSecurityQuestions;

  /// No description provided for @authEnterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Enter your answer'**
  String get authEnterAnswer;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get authNewPassword;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters with uppercase, lowercase, and digit'**
  String get authPasswordRule;

  /// No description provided for @authQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {n}'**
  String authQuestionNumber(int n);

  /// No description provided for @changePwConfirmNew.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePwConfirmNew;

  /// No description provided for @changePwFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get changePwFailed;

  /// No description provided for @changePwIntro.
  ///
  /// In en, this message translates to:
  /// **'Answer your security questions and set a new password. You will be signed out of every device and need to log in again.'**
  String get changePwIntro;

  /// No description provided for @changePwNoUsername.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your username. Please try again.'**
  String get changePwNoUsername;

  /// No description provided for @changePwSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Please log in again.'**
  String get changePwSuccess;

  /// No description provided for @changePwTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePwTitle;

  /// No description provided for @pwRecoveryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get pwRecoveryComingSoon;

  /// No description provided for @pwRecoveryConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get pwRecoveryConfirmPassword;

  /// No description provided for @pwRecoveryEmailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Email-based password recovery is under development. Please use Security Questions to reset your password for now.'**
  String get pwRecoveryEmailComingSoon;

  /// No description provided for @pwRecoveryEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get pwRecoveryEnterUsername;

  /// No description provided for @pwRecoveryHeading.
  ///
  /// In en, this message translates to:
  /// **'Forgot Your Password?'**
  String get pwRecoveryHeading;

  /// No description provided for @pwRecoveryLoadQuestions.
  ///
  /// In en, this message translates to:
  /// **'Load Security Questions'**
  String get pwRecoveryLoadQuestions;

  /// No description provided for @pwRecoveryMethod.
  ///
  /// In en, this message translates to:
  /// **'Recovery Method'**
  String get pwRecoveryMethod;

  /// No description provided for @pwRecoveryMethodEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get pwRecoveryMethodEmail;

  /// No description provided for @pwRecoveryMethodQuestions.
  ///
  /// In en, this message translates to:
  /// **'Security Questions'**
  String get pwRecoveryMethodQuestions;

  /// No description provided for @pwRecoveryResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get pwRecoveryResetButton;

  /// No description provided for @pwRecoveryResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful! Please login with your new password.'**
  String get pwRecoveryResetSuccess;

  /// No description provided for @pwRecoverySessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please start over.'**
  String get pwRecoverySessionExpired;

  /// No description provided for @pwRecoverySetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get pwRecoverySetNewPassword;

  /// No description provided for @pwRecoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password using your security questions'**
  String get pwRecoverySubtitle;

  /// No description provided for @pwRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get pwRecoveryTitle;

  /// No description provided for @pwRecoveryUseQuestions.
  ///
  /// In en, this message translates to:
  /// **'Use Security Questions Instead'**
  String get pwRecoveryUseQuestions;

  /// No description provided for @pwRecoveryUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get pwRecoveryUsername;

  /// No description provided for @pwRecoveryUsernameInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter your username and we\'ll show you your security questions.'**
  String get pwRecoveryUsernameInfo;

  /// No description provided for @pwRecoveryVerifyAnswers.
  ///
  /// In en, this message translates to:
  /// **'Verify Answers'**
  String get pwRecoveryVerifyAnswers;

  /// No description provided for @secQuestionsAnswerMin.
  ///
  /// In en, this message translates to:
  /// **'Answer must be at least 2 characters'**
  String get secQuestionsAnswerMin;

  /// No description provided for @secQuestionsEncrypted.
  ///
  /// In en, this message translates to:
  /// **'END-TO-END ENCRYPTED'**
  String get secQuestionsEncrypted;

  /// No description provided for @secQuestionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose three security questions to verify your identity if you lose access to your account.'**
  String get secQuestionsIntro;

  /// No description provided for @secQuestionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Security questions saved!'**
  String get secQuestionsSaved;

  /// No description provided for @secQuestionsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Please select all 3 security questions'**
  String get secQuestionsSelectAll;

  /// No description provided for @secQuestionsSelectDifferent.
  ///
  /// In en, this message translates to:
  /// **'Please select 3 different security questions'**
  String get secQuestionsSelectDifferent;

  /// No description provided for @secQuestionsSelectError.
  ///
  /// In en, this message translates to:
  /// **'Please select a question'**
  String get secQuestionsSelectError;

  /// No description provided for @secQuestionsSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select a security question'**
  String get secQuestionsSelectHint;

  /// No description provided for @secQuestionsStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4'**
  String secQuestionsStepOf(int step);

  /// No description provided for @secQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Account'**
  String get secQuestionsTitle;

  /// No description provided for @secQuestionsYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get secQuestionsYourAnswer;

  /// No description provided for @userRecoveryAnswerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please answer the following questions to verify your identity'**
  String get userRecoveryAnswerPrompt;

  /// No description provided for @userRecoveryContinueToLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue to Login'**
  String get userRecoveryContinueToLogin;

  /// No description provided for @userRecoveryEnterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Details'**
  String get userRecoveryEnterDetails;

  /// No description provided for @userRecoveryFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get userRecoveryFullName;

  /// No description provided for @userRecoveryFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered full name'**
  String get userRecoveryFullNameHint;

  /// No description provided for @userRecoveryHeading.
  ///
  /// In en, this message translates to:
  /// **'Forgot Your Username?'**
  String get userRecoveryHeading;

  /// No description provided for @userRecoveryInfo.
  ///
  /// In en, this message translates to:
  /// **'You will need to answer your security questions to verify your identity.'**
  String get userRecoveryInfo;

  /// No description provided for @userRecoveryPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get userRecoveryPhone;

  /// No description provided for @userRecoveryPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered phone number'**
  String get userRecoveryPhoneHint;

  /// No description provided for @userRecoveryRecovered.
  ///
  /// In en, this message translates to:
  /// **'Username Recovered!'**
  String get userRecoveryRecovered;

  /// No description provided for @userRecoverySaveNote.
  ///
  /// In en, this message translates to:
  /// **'Please save this username for future reference'**
  String get userRecoverySaveNote;

  /// No description provided for @userRecoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll help you recover your username by verifying your identity'**
  String get userRecoverySubtitle;

  /// No description provided for @userRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Username Recovery'**
  String get userRecoveryTitle;

  /// No description provided for @userRecoveryVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Recover Username'**
  String get userRecoveryVerifyButton;

  /// No description provided for @userRecoveryYourUsernameIs.
  ///
  /// In en, this message translates to:
  /// **'Your username is:'**
  String get userRecoveryYourUsernameIs;

  /// No description provided for @companyCreateAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address *'**
  String get companyCreateAddressLabel;

  /// No description provided for @companyCreateBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type *'**
  String get companyCreateBusinessType;

  /// No description provided for @companyCreateBusinessTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one business type'**
  String get companyCreateBusinessTypeError;

  /// No description provided for @companyCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get companyCreateButton;

  /// No description provided for @companyCreateCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get companyCreateCityLabel;

  /// No description provided for @companyCreateCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country *'**
  String get companyCreateCountryLabel;

  /// No description provided for @companyCreateEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email, for example name@company.com'**
  String get companyCreateEmailInvalid;

  /// No description provided for @companyCreateEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Email *'**
  String get companyCreateEmailLabel;

  /// No description provided for @companyCreateEmailNoAt.
  ///
  /// In en, this message translates to:
  /// **'Email must contain @, for example name@company.com'**
  String get companyCreateEmailNoAt;

  /// No description provided for @companyCreateEmailNoDomain.
  ///
  /// In en, this message translates to:
  /// **'Email must have a domain ending, for example .com or .in'**
  String get companyCreateEmailNoDomain;

  /// No description provided for @companyCreateEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Business email is required'**
  String get companyCreateEmailRequired;

  /// No description provided for @companyCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Company creation failed'**
  String get companyCreateFailed;

  /// No description provided for @companyCreateGstinHint.
  ///
  /// In en, this message translates to:
  /// **'15-character GSTIN'**
  String get companyCreateGstinHint;

  /// No description provided for @companyCreateGstinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid GSTIN format'**
  String get companyCreateGstinInvalid;

  /// No description provided for @companyCreateGstinLabel.
  ///
  /// In en, this message translates to:
  /// **'GSTIN (Optional)'**
  String get companyCreateGstinLabel;

  /// No description provided for @companyCreateGstinLength.
  ///
  /// In en, this message translates to:
  /// **'GSTIN must be exactly 15 characters'**
  String get companyCreateGstinLength;

  /// No description provided for @companyCreateHeading.
  ///
  /// In en, this message translates to:
  /// **'Register Your Company'**
  String get companyCreateHeading;

  /// No description provided for @companyCreateHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get companyCreateHide;

  /// No description provided for @companyCreateInvalidDetails.
  ///
  /// In en, this message translates to:
  /// **'Invalid company details'**
  String get companyCreateInvalidDetails;

  /// No description provided for @companyCreateLegalHint.
  ///
  /// In en, this message translates to:
  /// **'You can add GSTIN and PAN details now or later from company settings'**
  String get companyCreateLegalHint;

  /// No description provided for @companyCreateLoDesc.
  ///
  /// In en, this message translates to:
  /// **'Posts load requirements and seeks transport'**
  String get companyCreateLoDesc;

  /// No description provided for @companyCreateLpDesc.
  ///
  /// In en, this message translates to:
  /// **'Manages a fleet and fulfills load requirements'**
  String get companyCreateLpDesc;

  /// No description provided for @companyCreateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name *'**
  String get companyCreateNameLabel;

  /// No description provided for @companyCreatePanHint.
  ///
  /// In en, this message translates to:
  /// **'10-character PAN'**
  String get companyCreatePanHint;

  /// No description provided for @companyCreatePanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid PAN format'**
  String get companyCreatePanInvalid;

  /// No description provided for @companyCreatePanLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN Number (Optional)'**
  String get companyCreatePanLabel;

  /// No description provided for @companyCreatePanLength.
  ///
  /// In en, this message translates to:
  /// **'PAN must be exactly 10 characters'**
  String get companyCreatePanLength;

  /// No description provided for @companyCreatePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Phone *'**
  String get companyCreatePhoneLabel;

  /// No description provided for @companyCreatePhoneLength.
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be exactly 10 digits'**
  String get companyCreatePhoneLength;

  /// No description provided for @companyCreatePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Business phone is required'**
  String get companyCreatePhoneRequired;

  /// No description provided for @companyCreatePincodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit Indian pincode'**
  String get companyCreatePincodeInvalid;

  /// No description provided for @companyCreatePincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pincode *'**
  String get companyCreatePincodeLabel;

  /// No description provided for @companyCreateSectionAddress.
  ///
  /// In en, this message translates to:
  /// **'Address Information'**
  String get companyCreateSectionAddress;

  /// No description provided for @companyCreateSectionCompany.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyCreateSectionCompany;

  /// No description provided for @companyCreateSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal Information (Optional)'**
  String get companyCreateSectionLegal;

  /// No description provided for @companyCreateShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get companyCreateShow;

  /// No description provided for @companyCreateStateLabel.
  ///
  /// In en, this message translates to:
  /// **'State *'**
  String get companyCreateStateLabel;

  /// No description provided for @companyCreateSubheading.
  ///
  /// In en, this message translates to:
  /// **'You will become the company Owner with full administrative access.'**
  String get companyCreateSubheading;

  /// No description provided for @companyCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company created successfully! You are now the Owner.'**
  String get companyCreateSuccess;

  /// No description provided for @companyCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get companyCreateTitle;

  /// No description provided for @companySearchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters to search'**
  String get companySearchEmptyHint;

  /// No description provided for @companySearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search for a company'**
  String get companySearchEmptyTitle;

  /// No description provided for @companySearchError.
  ///
  /// In en, this message translates to:
  /// **'Error searching companies'**
  String get companySearchError;

  /// No description provided for @companySearchHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Search by company name (min 3 characters)'**
  String get companySearchHintDefault;

  /// No description provided for @companySearchHintLo.
  ///
  /// In en, this message translates to:
  /// **'Search load owner companies...'**
  String get companySearchHintLo;

  /// No description provided for @companySearchHintLp.
  ///
  /// In en, this message translates to:
  /// **'Search logistic partner companies...'**
  String get companySearchHintLp;

  /// Button to join the selected company
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get companySearchJoinButton;

  /// No description provided for @companySearchJoinNotice.
  ///
  /// In en, this message translates to:
  /// **'You will be added as a Pending User. The company owner must approve your request.'**
  String get companySearchJoinNotice;

  /// No description provided for @companySearchJoinPrompt.
  ///
  /// In en, this message translates to:
  /// **'You want to join:'**
  String get companySearchJoinPrompt;

  /// No description provided for @companySearchJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Company'**
  String get companySearchJoinTitle;

  /// No description provided for @companySearchKeepTyping.
  ///
  /// In en, this message translates to:
  /// **'Keep typing...'**
  String get companySearchKeepTyping;

  /// No description provided for @companySearchMinChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 characters required'**
  String get companySearchMinChars;

  /// No description provided for @companySearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get companySearchNoResults;

  /// No description provided for @companySearchRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get companySearchRegisterFailed;

  /// No description provided for @companySearchRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You are now a Pending User. Please wait for approval.'**
  String get companySearchRegisterSuccess;

  /// No description provided for @companySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Company'**
  String get companySearchTitle;

  /// No description provided for @companySearchTryOther.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get companySearchTryOther;

  /// No description provided for @companySelectCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Register your company and become the Owner. You will have full control over your company and can invite team members.'**
  String get companySelectCreateDesc;

  /// No description provided for @companySelectCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Company'**
  String get companySelectCreateTitle;

  /// No description provided for @companySelectHeading.
  ///
  /// In en, this message translates to:
  /// **'Company Association'**
  String get companySelectHeading;

  /// No description provided for @companySelectJoinDesc.
  ///
  /// In en, this message translates to:
  /// **'Search and join an existing company. You will be added as a Pending User until approved by the company owner.'**
  String get companySelectJoinDesc;

  /// No description provided for @companySelectJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Existing Company'**
  String get companySelectJoinTitle;

  /// No description provided for @companySelectSkipDesc.
  ///
  /// In en, this message translates to:
  /// **'Continue as an Independent User without company affiliation. You can join or create a company later from your profile.'**
  String get companySelectSkipDesc;

  /// No description provided for @companySelectSkipDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You will be registered as an Independent User. You can join or create a company later from your profile settings.\n\nContinue?'**
  String get companySelectSkipDialogBody;

  /// No description provided for @companySelectSkipDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip Company Selection'**
  String get companySelectSkipDialogTitle;

  /// No description provided for @companySelectSkipDone.
  ///
  /// In en, this message translates to:
  /// **'Registration completed! You can now login as an Independent User.'**
  String get companySelectSkipDone;

  /// No description provided for @companySelectSkipTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get companySelectSkipTitle;

  /// No description provided for @companySelectSubheading.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to proceed with your account'**
  String get companySelectSubheading;

  /// No description provided for @companySelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Selection'**
  String get companySelectTitle;

  /// No description provided for @profileCompleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileCompleteAddress;

  /// No description provided for @profileCompleteAddressMin.
  ///
  /// In en, this message translates to:
  /// **'Address must be at least 5 characters'**
  String get profileCompleteAddressMin;

  /// No description provided for @profileCompleteBusinessAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Your business address'**
  String get profileCompleteBusinessAddressHint;

  /// No description provided for @profileCompleteBusinessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get profileCompleteBusinessEmail;

  /// No description provided for @profileCompleteBusinessPhone.
  ///
  /// In en, this message translates to:
  /// **'Business Phone'**
  String get profileCompleteBusinessPhone;

  /// No description provided for @profileCompleteButton.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get profileCompleteButton;

  /// No description provided for @profileCompleteCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select the category that best describes your business'**
  String get profileCompleteCategoryHint;

  /// Heading: user picks what kind of account they are
  ///
  /// In en, this message translates to:
  /// **'Choose Your Role'**
  String get profileCompleteChooseRole;

  /// No description provided for @profileCompleteCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCompleteCity;

  /// No description provided for @profileCompleteComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get profileCompleteComingSoon;

  /// No description provided for @profileCompleteCreateCompany.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get profileCompleteCreateCompany;

  /// No description provided for @profileCompleteCreateCompanyDesc.
  ///
  /// In en, this message translates to:
  /// **'Register your company and become the Logistic Partner'**
  String get profileCompleteCreateCompanyDesc;

  /// No description provided for @profileCompleteDriverDesc.
  ///
  /// In en, this message translates to:
  /// **'Register as a driver with license information'**
  String get profileCompleteDriverDesc;

  /// No description provided for @profileCompleteDriverInfo.
  ///
  /// In en, this message translates to:
  /// **'Driver Information'**
  String get profileCompleteDriverInfo;

  /// No description provided for @profileCompleteEnterCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter company name'**
  String get profileCompleteEnterCompanyName;

  /// No description provided for @profileCompleteEnterLicense.
  ///
  /// In en, this message translates to:
  /// **'Please enter your license number'**
  String get profileCompleteEnterLicense;

  /// No description provided for @profileCompleteEnterLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'Please enter your license expiry date'**
  String get profileCompleteEnterLicenseExpiry;

  /// No description provided for @profileCompleteEnterPan.
  ///
  /// In en, this message translates to:
  /// **'Please enter your PAN Card Number'**
  String get profileCompleteEnterPan;

  /// No description provided for @profileCompleteEnterYourCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your company name'**
  String get profileCompleteEnterYourCompanyName;

  /// No description provided for @profileCompleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete profile'**
  String get profileCompleteFailed;

  /// No description provided for @profileCompleteFieldExecutiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage trip stages and fleet status on the ground'**
  String get profileCompleteFieldExecutiveDesc;

  /// No description provided for @profileCompleteGstOptional.
  ///
  /// In en, this message translates to:
  /// **'GST Number (optional)'**
  String get profileCompleteGstOptional;

  /// No description provided for @profileCompleteIndependentDesc.
  ///
  /// In en, this message translates to:
  /// **'Use basic features without company affiliation'**
  String get profileCompleteIndependentDesc;

  /// No description provided for @profileCompleteJoinTransporter.
  ///
  /// In en, this message translates to:
  /// **'Join as Transporter'**
  String get profileCompleteJoinTransporter;

  /// No description provided for @profileCompleteJoinTransporterDesc.
  ///
  /// In en, this message translates to:
  /// **'Register as an independent transporter to upload loading slips for assigned trips'**
  String get profileCompleteJoinTransporterDesc;

  /// No description provided for @profileCompleteJoinWorker.
  ///
  /// In en, this message translates to:
  /// **'Join as Worker'**
  String get profileCompleteJoinWorker;

  /// No description provided for @profileCompleteJoinWorkerDesc.
  ///
  /// In en, this message translates to:
  /// **'Join an existing company as a worker (requires owner approval)'**
  String get profileCompleteJoinWorkerDesc;

  /// User types the date in this exact format; keep YYYY-MM-DD
  ///
  /// In en, this message translates to:
  /// **'License Expiry Date (YYYY-MM-DD) *'**
  String get profileCompleteLicenseExpiry;

  /// No description provided for @profileCompleteLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number *'**
  String get profileCompleteLicenseNumber;

  /// No description provided for @profileCompleteLoCompany.
  ///
  /// In en, this message translates to:
  /// **'Load Owner Company'**
  String get profileCompleteLoCompany;

  /// No description provided for @profileCompleteLoCompanyWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'Work at a cargo/load company'**
  String get profileCompleteLoCompanyWorkDesc;

  /// No description provided for @profileCompleteLoadProviderCompany.
  ///
  /// In en, this message translates to:
  /// **'Load Provider Company'**
  String get profileCompleteLoadProviderCompany;

  /// No description provided for @profileCompleteLoadProviderDesc.
  ///
  /// In en, this message translates to:
  /// **'You have cargo/goods that need to be transported'**
  String get profileCompleteLoadProviderDesc;

  /// No description provided for @profileCompleteLoadReceiverCompany.
  ///
  /// In en, this message translates to:
  /// **'Load Receiver Company'**
  String get profileCompleteLoadReceiverCompany;

  /// No description provided for @profileCompleteLoadReceiverDesc.
  ///
  /// In en, this message translates to:
  /// **'You receive deliveries — you are the consignee'**
  String get profileCompleteLoadReceiverDesc;

  /// No description provided for @profileCompleteLpCompany.
  ///
  /// In en, this message translates to:
  /// **'Logistic Partner Company'**
  String get profileCompleteLpCompany;

  /// No description provided for @profileCompleteLpCompanyCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'You manage a fleet of vehicles for transportation — your role: Logistic Partner'**
  String get profileCompleteLpCompanyCreateDesc;

  /// No description provided for @profileCompleteLpCompanyWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'Work at a fleet/logistics company (Field Executive or RR Operations)'**
  String get profileCompleteLpCompanyWorkDesc;

  /// No description provided for @profileCompletePanLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN Card Number *'**
  String get profileCompletePanLabel;

  /// No description provided for @profileCompletePermanentWarning.
  ///
  /// In en, this message translates to:
  /// **'This decision is permanent and cannot be changed later.'**
  String get profileCompletePermanentWarning;

  /// No description provided for @profileCompletePincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode (6 digits)'**
  String get profileCompletePincode;

  /// No description provided for @profileCompleteRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent! Wait for acceptance by the company owner.'**
  String get profileCompleteRequestSent;

  /// No description provided for @profileCompleteRrOpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Handle RR sync and trip data entry in the RR system'**
  String get profileCompleteRrOpsDesc;

  /// No description provided for @profileCompleteSearchCompany.
  ///
  /// In en, this message translates to:
  /// **'Search Company'**
  String get profileCompleteSearchCompany;

  /// No description provided for @profileCompleteSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to search companies: {error}'**
  String profileCompleteSearchFailed(String error);

  /// No description provided for @profileCompleteSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters'**
  String get profileCompleteSearchHint;

  /// No description provided for @profileCompleteSelectCompanyToJoin.
  ///
  /// In en, this message translates to:
  /// **'Please select a company to join'**
  String get profileCompleteSelectCompanyToJoin;

  /// No description provided for @profileCompleteSelectCompanyType.
  ///
  /// In en, this message translates to:
  /// **'Please select a company type'**
  String get profileCompleteSelectCompanyType;

  /// No description provided for @profileCompleteSelectCompanyTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Company Type'**
  String get profileCompleteSelectCompanyTypeTitle;

  /// No description provided for @profileCompleteSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select a role type'**
  String get profileCompleteSelectRole;

  /// No description provided for @profileCompleteSelectWorkerType.
  ///
  /// In en, this message translates to:
  /// **'Please select your worker type'**
  String get profileCompleteSelectWorkerType;

  /// No description provided for @profileCompleteSelectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get profileCompleteSelectYourRole;

  /// No description provided for @profileCompleteSelectedCompany.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String profileCompleteSelectedCompany(String name);

  /// No description provided for @profileCompleteSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get profileCompleteSessionExpired;

  /// No description provided for @profileCompleteState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get profileCompleteState;

  /// No description provided for @profileCompleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile completed successfully!'**
  String get profileCompleteSuccess;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompleteTransporterCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Your transport company name'**
  String get profileCompleteTransporterCompanyHint;

  /// No description provided for @profileCompleteTransporterDetails.
  ///
  /// In en, this message translates to:
  /// **'Transporter Details'**
  String get profileCompleteTransporterDetails;

  /// No description provided for @profileCompleteTransporterSub.
  ///
  /// In en, this message translates to:
  /// **'Enter your transport business details'**
  String get profileCompleteTransporterSub;

  /// No description provided for @profileCompleteWhatCompanyType.
  ///
  /// In en, this message translates to:
  /// **'What type of company are you registering?'**
  String get profileCompleteWhatCompanyType;

  /// No description provided for @profileCompleteWhatWillYouDo.
  ///
  /// In en, this message translates to:
  /// **'What will you do at the logistics company?'**
  String get profileCompleteWhatWillYouDo;

  /// No description provided for @profileCompleteWorkForWhichType.
  ///
  /// In en, this message translates to:
  /// **'Which type of company do you want to work for?'**
  String get profileCompleteWorkForWhichType;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// Role name: LP worker who handles trips on the ground
  ///
  /// In en, this message translates to:
  /// **'Field Executive'**
  String get roleFieldExecutive;

  /// Role name: user with no company
  ///
  /// In en, this message translates to:
  /// **'Independent User'**
  String get roleIndependentUser;

  /// Role name: company that posts loads
  ///
  /// In en, this message translates to:
  /// **'Load Owner'**
  String get roleLoadOwner;

  /// Role name: company that manages a fleet
  ///
  /// In en, this message translates to:
  /// **'Logistic Partner'**
  String get roleLogisticPartner;

  /// Role name: LP worker who handles RR sync
  ///
  /// In en, this message translates to:
  /// **'RR Operations'**
  String get roleRrOperations;

  /// No description provided for @ongoingCardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ongoingCardActive;

  /// No description provided for @ongoingCardAmount.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get ongoingCardAmount;

  /// No description provided for @ongoingCardBiltyNo.
  ///
  /// In en, this message translates to:
  /// **'BILTY NO.'**
  String get ongoingCardBiltyNo;

  /// No description provided for @ongoingCardCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will mark the trip as completed and notify the load owner. This action cannot be undone.'**
  String get ongoingCardCompleteBody;

  /// No description provided for @ongoingCardCompleteDone.
  ///
  /// In en, this message translates to:
  /// **'Trip marked as completed. Load owner notified.'**
  String get ongoingCardCompleteDone;

  /// No description provided for @ongoingCardCompleteLocked.
  ///
  /// In en, this message translates to:
  /// **'Complete Trip is only available after Stage 5'**
  String get ongoingCardCompleteLocked;

  /// No description provided for @ongoingCardCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Trip?'**
  String get ongoingCardCompleteTitle;

  /// No description provided for @ongoingCardCompleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Complete Trip'**
  String get ongoingCardCompleteTrip;

  /// No description provided for @ongoingCardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ongoingCardConfirm;

  /// No description provided for @ongoingCardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get ongoingCardDone;

  /// No description provided for @ongoingCardFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get ongoingCardFailed;

  /// Button: {stage} is a number 1-5, {name} the stage name
  ///
  /// In en, this message translates to:
  /// **'Go to Stage {stage}  ·  {name}'**
  String ongoingCardGoToStage(String stage, String name);

  /// No description provided for @ongoingCardInTransitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip in transit} other{{count} trips in transit}}'**
  String ongoingCardInTransitCount(int count);

  /// No description provided for @ongoingCardInvoice.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get ongoingCardInvoice;

  /// No description provided for @ongoingCardLoadItem.
  ///
  /// In en, this message translates to:
  /// **'LOAD ITEM'**
  String get ongoingCardLoadItem;

  /// No description provided for @ongoingCardLocateTrip.
  ///
  /// In en, this message translates to:
  /// **'Locate Trip'**
  String get ongoingCardLocateTrip;

  /// No description provided for @ongoingCardNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No Vehicle'**
  String get ongoingCardNoVehicle;

  /// No description provided for @ongoingCardOngoingTrips.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Trips'**
  String get ongoingCardOngoingTrips;

  /// No description provided for @ongoingCardRrSync.
  ///
  /// In en, this message translates to:
  /// **'RR Sync'**
  String get ongoingCardRrSync;

  /// No description provided for @ongoingCardStage0CompleteS1.
  ///
  /// In en, this message translates to:
  /// **'Stage 0 · Complete S1 to sync RR'**
  String get ongoingCardStage0CompleteS1;

  /// No description provided for @ongoingCardStage0NotSynced.
  ///
  /// In en, this message translates to:
  /// **'Stage 0 · Not synced to RR'**
  String get ongoingCardStage0NotSynced;

  /// No description provided for @ongoingCardStageComplianceCheck.
  ///
  /// In en, this message translates to:
  /// **'Compliance Check'**
  String get ongoingCardStageComplianceCheck;

  /// No description provided for @ongoingCardStageDieselReceipt.
  ///
  /// In en, this message translates to:
  /// **'Diesel Receipt'**
  String get ongoingCardStageDieselReceipt;

  /// No description provided for @ongoingCardStageExitCheck.
  ///
  /// In en, this message translates to:
  /// **'Exit Check'**
  String get ongoingCardStageExitCheck;

  /// No description provided for @ongoingCardStageFactoryArrival.
  ///
  /// In en, this message translates to:
  /// **'Factory Arrival'**
  String get ongoingCardStageFactoryArrival;

  /// No description provided for @ongoingCardStageTruckRegistration.
  ///
  /// In en, this message translates to:
  /// **'Truck Registration'**
  String get ongoingCardStageTruckRegistration;

  /// No description provided for @ongoingCardSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'RR sync failed'**
  String get ongoingCardSyncFailed;

  /// No description provided for @ongoingCardTripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get ongoingCardTripCompleted;

  /// No description provided for @ongoingCardTripNumber.
  ///
  /// In en, this message translates to:
  /// **'TRIP NUMBER'**
  String get ongoingCardTripNumber;

  /// No description provided for @ongoingCardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get ongoingCardViewAll;

  /// No description provided for @ongoingCardViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get ongoingCardViewDetails;

  /// No description provided for @ongoingCardWeight.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get ongoingCardWeight;

  /// No description provided for @recvDocsAttachImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please attach the receiving sheet image'**
  String get recvDocsAttachImageRequired;

  /// No description provided for @recvDocsAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach receiving sheet photo'**
  String get recvDocsAttachPhoto;

  /// Card line: who uploaded it
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String recvDocsBy(String name);

  /// No description provided for @recvDocsChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get recvDocsChooseGallery;

  /// No description provided for @recvDocsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get recvDocsDate;

  /// No description provided for @recvDocsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the image and cannot be undone.'**
  String get recvDocsDeleteBody;

  /// No description provided for @recvDocsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String recvDocsDeleteFailed(String error);

  /// No description provided for @recvDocsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete receiving doc?'**
  String get recvDocsDeleteTitle;

  /// No description provided for @recvDocsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Receiving Doc'**
  String get recvDocsEditTitle;

  /// No description provided for @recvDocsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No receiving docs uploaded yet'**
  String get recvDocsEmpty;

  /// No description provided for @recvDocsEmptyForDate.
  ///
  /// In en, this message translates to:
  /// **'No receiving docs found for that date'**
  String get recvDocsEmptyForDate;

  /// No description provided for @recvDocsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String recvDocsLoadFailed(String error);

  /// No description provided for @recvDocsOpenDownload.
  ///
  /// In en, this message translates to:
  /// **'Open / Download'**
  String get recvDocsOpenDownload;

  /// No description provided for @recvDocsPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get recvDocsPickDate;

  /// No description provided for @recvDocsPickDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please pick the date this receiving sheet is for'**
  String get recvDocsPickDateRequired;

  /// No description provided for @recvDocsPickImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image: {error}'**
  String recvDocsPickImageFailed(String error);

  /// No description provided for @recvDocsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get recvDocsSaveChanges;

  /// No description provided for @recvDocsSearchByDate.
  ///
  /// In en, this message translates to:
  /// **'Search by date'**
  String get recvDocsSearchByDate;

  /// No description provided for @recvDocsSheetDate.
  ///
  /// In en, this message translates to:
  /// **'Date this sheet is for'**
  String get recvDocsSheetDate;

  /// No description provided for @recvDocsTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get recvDocsTakePhoto;

  /// List screen title
  ///
  /// In en, this message translates to:
  /// **'Receiving Docs'**
  String get recvDocsTitle;

  /// No description provided for @recvDocsUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get recvDocsUpload;

  /// No description provided for @recvDocsUploadNew.
  ///
  /// In en, this message translates to:
  /// **'Upload New'**
  String get recvDocsUploadNew;

  /// No description provided for @recvDocsUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Receiving Doc'**
  String get recvDocsUploadTitle;

  /// No description provided for @recvDocsUploadedBy.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by'**
  String get recvDocsUploadedBy;

  /// Detail screen title
  ///
  /// In en, this message translates to:
  /// **'Receiving Doc'**
  String get recvDocsViewTitle;

  /// Small action text beside the status badge
  ///
  /// In en, this message translates to:
  /// **'· Connect'**
  String get rrConnectionActionConnect;

  /// Small action text beside the status badge
  ///
  /// In en, this message translates to:
  /// **'· Disconnect'**
  String get rrConnectionActionDisconnect;

  /// Status badge
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get rrConnectionConnected;

  /// Dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get rrConnectionDisconnect;

  /// No description provided for @rrConnectionDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Sync and pre-fill will stop working for everyone at your company until someone reconnects.'**
  String get rrConnectionDisconnectBody;

  /// No description provided for @rrConnectionDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from RR?'**
  String get rrConnectionDisconnectTitle;

  /// Status badge
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get rrConnectionDisconnected;

  /// Status badge: RR session about to expire
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get rrConnectionExpiringSoon;

  /// No description provided for @rrLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get rrLoginButton;

  /// No description provided for @rrLoginEnterCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your RR username and password'**
  String get rrLoginEnterCredentials;

  /// Fallback when the server gives no reason
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get rrLoginFailed;

  /// No description provided for @rrLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your RollingRadius credentials to continue.'**
  String get rrLoginSubtitle;

  /// No description provided for @rrLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to RR'**
  String get rrLoginTitle;

  /// No description provided for @rrLoginUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String rrLoginUnexpectedError(String error);

  /// No description provided for @rrLoginUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username / Phone'**
  String get rrLoginUsernameLabel;

  /// No description provided for @rrSearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get rrSearchNoMatches;

  /// FE = Field Executive
  ///
  /// In en, this message translates to:
  /// **'Allow FE to fill Stage 1'**
  String get tripCardAllowFeStage1;

  /// No description provided for @tripCardAlreadyInRecords.
  ///
  /// In en, this message translates to:
  /// **'Already in Records'**
  String get tripCardAlreadyInRecords;

  /// No description provided for @tripCardAwaitCompanyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Let this trip get confirmed by your company'**
  String get tripCardAwaitCompanyConfirm;

  /// No description provided for @tripCardBiltyNo.
  ///
  /// In en, this message translates to:
  /// **'Bilty No: {number}'**
  String tripCardBiltyNo(String number);

  /// No description provided for @tripCardBookingConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm booking'**
  String get tripCardBookingConfirmFailed;

  /// No description provided for @tripCardBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get tripCardBookingConfirmed;

  /// No description provided for @tripCardBookingNeedsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Booking needs confirmation'**
  String get tripCardBookingNeedsConfirm;

  /// No description provided for @tripCardCompletedViewOnly.
  ///
  /// In en, this message translates to:
  /// **'Completed trips are view only'**
  String get tripCardCompletedViewOnly;

  /// No description provided for @tripCardConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get tripCardConfirmBooking;

  /// {when} is a formatted date/time such as "5 Oct, 3:15 PM"
  ///
  /// In en, this message translates to:
  /// **'Created {when}'**
  String tripCardCreated(String when);

  /// Accessibility label for the dialog backdrop
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get tripCardDismiss;

  /// No description provided for @tripCardEditTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get tripCardEditTrip;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Axle Type'**
  String get tripCardLabelAxleType;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Bilty Number'**
  String get tripCardLabelBiltyNumber;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get tripCardLabelBodyType;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Consignee'**
  String get tripCardLabelConsignee;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Consignee GSTIN'**
  String get tripCardLabelConsigneeGstin;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Consignor'**
  String get tripCardLabelConsignor;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Consignor GSTIN'**
  String get tripCardLabelConsignorGstin;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get tripCardLabelCreatedAt;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Depot Code'**
  String get tripCardLabelDepotCode;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tripCardLabelDescription;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get tripCardLabelMaterial;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Part Load'**
  String get tripCardLabelPartLoad;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Pickup Address'**
  String get tripCardLabelPickupAddress;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Total Invoice Value'**
  String get tripCardLabelTotalInvoiceValue;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Unload Address'**
  String get tripCardLabelUnloadAddress;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get tripCardLabelVehicle;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get tripCardLabelWeight;

  /// Label in the expanded trip info list
  ///
  /// In en, this message translates to:
  /// **'Wheels'**
  String get tripCardLabelWheels;

  /// No description provided for @tripCardMoveToRecords.
  ///
  /// In en, this message translates to:
  /// **'Move to Records'**
  String get tripCardMoveToRecords;

  /// No description provided for @tripCardMoveToRecordsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not move trip to Records'**
  String get tripCardMoveToRecordsFailed;

  /// No description provided for @tripCardMovedToRecords.
  ///
  /// In en, this message translates to:
  /// **'Trip moved to Records'**
  String get tripCardMovedToRecords;

  /// No description provided for @tripCardResumeConflict.
  ///
  /// In en, this message translates to:
  /// **'Cannot resume — {driver} has already been assigned to a new trip'**
  String tripCardResumeConflict(String driver);

  /// No description provided for @tripCardResumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resume driver tracking'**
  String get tripCardResumeFailed;

  /// No description provided for @tripCardResumeTracking.
  ///
  /// In en, this message translates to:
  /// **'Resume Driver Tracking for this Trip'**
  String get tripCardResumeTracking;

  /// No description provided for @tripCardRetryBookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not retry booking — try again'**
  String get tripCardRetryBookingFailed;

  /// No description provided for @tripCardStillFailing.
  ///
  /// In en, this message translates to:
  /// **'Still failing — check back or try again'**
  String get tripCardStillFailing;

  /// {error} is the sync error text from the server
  ///
  /// In en, this message translates to:
  /// **'Still failing: {error}'**
  String tripCardStillFailingWith(String error);

  /// No description provided for @tripCardStopTracking.
  ///
  /// In en, this message translates to:
  /// **'Stop Driver Tracking for this Trip'**
  String get tripCardStopTracking;

  /// {driver} is the driver name, or the fallback tripCardTheDriver
  ///
  /// In en, this message translates to:
  /// **'This will release {driver} from this trip so they can be assigned to a new trip. You can resume tracking for this trip later, but only if this driver has not already been assigned to a new trip by then. Continue?'**
  String tripCardStopTrackingBody(String driver);

  /// No description provided for @tripCardStopTrackingButton.
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking'**
  String get tripCardStopTrackingButton;

  /// No description provided for @tripCardStopTrackingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not stop driver tracking'**
  String get tripCardStopTrackingFailed;

  /// No description provided for @tripCardStopTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Driver Tracking'**
  String get tripCardStopTrackingTitle;

  /// No description provided for @tripCardSyncedToRr.
  ///
  /// In en, this message translates to:
  /// **'Synced to RR'**
  String get tripCardSyncedToRr;

  /// Fallback when the driver name is missing
  ///
  /// In en, this message translates to:
  /// **'the driver'**
  String get tripCardTheDriver;

  /// Fallback when the driver name is missing
  ///
  /// In en, this message translates to:
  /// **'this driver'**
  String get tripCardThisDriver;

  /// No description provided for @tripCardTrackDriver.
  ///
  /// In en, this message translates to:
  /// **'Track Driver Location'**
  String get tripCardTrackDriver;

  /// No description provided for @tripCardTrackingResumed.
  ///
  /// In en, this message translates to:
  /// **'Driver tracking resumed for this trip'**
  String get tripCardTrackingResumed;

  /// No description provided for @tripCardTrackingStopped.
  ///
  /// In en, this message translates to:
  /// **'Driver tracking stopped for this trip'**
  String get tripCardTrackingStopped;

  /// No description provided for @tripCardTripInfo.
  ///
  /// In en, this message translates to:
  /// **'Trip Info'**
  String get tripCardTripInfo;

  /// No description provided for @tripCardUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update — try again'**
  String get tripCardUpdateFailed;

  /// No description provided for @tripSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by trip number'**
  String get tripSearchHint;

  /// Trip status badge
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripStatusCancelled;

  /// Trip status badge
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripStatusCompleted;

  /// Trip status badge
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get tripStatusInTransit;

  /// Trip status badge (trip has started, not yet in transit)
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get tripStatusOngoing;

  /// Trip/stage status; not started yet
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tripStatusPending;

  /// No description provided for @driverAssignedDriver.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get driverAssignedDriver;

  /// No description provided for @driverAssignedGoToTrip.
  ///
  /// In en, this message translates to:
  /// **'Go to Trip Assignment'**
  String get driverAssignedGoToTrip;

  /// No description provided for @driverAssignedHeading.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Assigned Successfully'**
  String get driverAssignedHeading;

  /// No description provided for @driverAssignedReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to Fleet Overview'**
  String get driverAssignedReturn;

  /// No description provided for @driverAssignedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The driver and vehicle are now linked in the system and ready for dispatch.'**
  String get driverAssignedSubtitle;

  /// No description provided for @driverAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get driverAssignedTitle;

  /// No description provided for @driverAssignedUnitId.
  ///
  /// In en, this message translates to:
  /// **'UNIT ID: {id}'**
  String driverAssignedUnitId(String id);

  /// No description provided for @driverAssignedVehicle.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE'**
  String get driverAssignedVehicle;

  /// No description provided for @driverAssignedViewVehicle.
  ///
  /// In en, this message translates to:
  /// **'View Vehicle Details'**
  String get driverAssignedViewVehicle;

  /// No description provided for @driverDashBAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get driverDashBAddress;

  /// No description provided for @driverDashBAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get driverDashBAge;

  /// No description provided for @driverDashBAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String driverDashBAgeYears(int years);

  /// No description provided for @driverDashBAssignedBy.
  ///
  /// In en, this message translates to:
  /// **'Assigned by'**
  String get driverDashBAssignedBy;

  /// No description provided for @driverDashBAssignedOn.
  ///
  /// In en, this message translates to:
  /// **'Assigned on'**
  String get driverDashBAssignedOn;

  /// No description provided for @driverDashBAssignedVehicle.
  ///
  /// In en, this message translates to:
  /// **'Assigned Vehicle'**
  String get driverDashBAssignedVehicle;

  /// No description provided for @driverDashBAuthority.
  ///
  /// In en, this message translates to:
  /// **'Authority'**
  String get driverDashBAuthority;

  /// No description provided for @driverDashBClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get driverDashBClass;

  /// No description provided for @driverDashBCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get driverDashBCountry;

  /// No description provided for @driverDashBDob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get driverDashBDob;

  /// No description provided for @driverDashBEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get driverDashBEmail;

  /// No description provided for @driverDashBEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get driverDashBEmergencyContact;

  /// No description provided for @driverDashBEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get driverDashBEmployeeId;

  /// No description provided for @driverDashBEmployeeIdShort.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String driverDashBEmployeeIdShort(String id);

  /// No description provided for @driverDashBExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get driverDashBExpired;

  /// No description provided for @driverDashBExpiringIn.
  ///
  /// In en, this message translates to:
  /// **'Expiring in {days} days'**
  String driverDashBExpiringIn(int days);

  /// No description provided for @driverDashBExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get driverDashBExpiryDate;

  /// No description provided for @driverDashBFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get driverDashBFuel;

  /// No description provided for @driverDashBFuelReceipt.
  ///
  /// In en, this message translates to:
  /// **'Fuel\nReceipt'**
  String get driverDashBFuelReceipt;

  /// No description provided for @driverDashBFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get driverDashBFullName;

  /// No description provided for @driverDashBIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get driverDashBIssueDate;

  /// No description provided for @driverDashBIssuingState.
  ///
  /// In en, this message translates to:
  /// **'Issuing State'**
  String get driverDashBIssuingState;

  /// No description provided for @driverDashBLicenseDetails.
  ///
  /// In en, this message translates to:
  /// **'License Details'**
  String get driverDashBLicenseDetails;

  /// No description provided for @driverDashBLicenseExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'License expired on {date}'**
  String driverDashBLicenseExpiredOn(String date);

  /// No description provided for @driverDashBLicenseExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'License expires on {date} — renew soon'**
  String driverDashBLicenseExpiresOn(String date);

  /// No description provided for @driverDashBLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get driverDashBLicenseNumber;

  /// No description provided for @driverDashBName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get driverDashBName;

  /// No description provided for @driverDashBNoEmergency.
  ///
  /// In en, this message translates to:
  /// **'No emergency contact on file'**
  String get driverDashBNoEmergency;

  /// No description provided for @driverDashBNoLicense.
  ///
  /// In en, this message translates to:
  /// **'No license on file'**
  String get driverDashBNoLicense;

  /// No description provided for @driverDashBNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No vehicle assigned'**
  String get driverDashBNoVehicle;

  /// No description provided for @driverDashBNotFound.
  ///
  /// In en, this message translates to:
  /// **'Driver not found'**
  String get driverDashBNotFound;

  /// No description provided for @driverDashBPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get driverDashBPersonalInfo;

  /// No description provided for @driverDashBPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get driverDashBPhone;

  /// No description provided for @driverDashBQuickActions.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get driverDashBQuickActions;

  /// No description provided for @driverDashBRegNo.
  ///
  /// In en, this message translates to:
  /// **'Reg No'**
  String get driverDashBRegNo;

  /// No description provided for @driverDashBRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get driverDashBRelationship;

  /// No description provided for @driverDashBReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report\nIssue'**
  String get driverDashBReportIssue;

  /// No description provided for @driverDashBSafetyCheck.
  ///
  /// In en, this message translates to:
  /// **'Safety\nCheck'**
  String get driverDashBSafetyCheck;

  /// No description provided for @driverDashBStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get driverDashBStatus;

  /// No description provided for @driverDashBTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverDashBTitle;

  /// No description provided for @driverDashBType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get driverDashBType;

  /// No description provided for @driverDashBValidDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Valid ({days} days left)'**
  String driverDashBValidDaysLeft(int days);

  /// No description provided for @driverDashBViewVehicle.
  ///
  /// In en, this message translates to:
  /// **'View Vehicle Details'**
  String get driverDashBViewVehicle;

  /// No description provided for @driverOnboardCertDefensive.
  ///
  /// In en, this message translates to:
  /// **'Defensive Driving'**
  String get driverOnboardCertDefensive;

  /// No description provided for @driverOnboardCertDetails.
  ///
  /// In en, this message translates to:
  /// **'CERTIFICATION DETAILS'**
  String get driverOnboardCertDetails;

  /// No description provided for @driverOnboardCertFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First Aid/CPR'**
  String get driverOnboardCertFirstAid;

  /// No description provided for @driverOnboardCertFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel Efficiency Training'**
  String get driverOnboardCertFuel;

  /// No description provided for @driverOnboardCertHazmat.
  ///
  /// In en, this message translates to:
  /// **'HAZMAT Handling'**
  String get driverOnboardCertHazmat;

  /// No description provided for @driverOnboardCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'COMPLETION DATE'**
  String get driverOnboardCompletionDate;

  /// No description provided for @driverOnboardCoreCerts.
  ///
  /// In en, this message translates to:
  /// **'CORE CERTIFICATIONS'**
  String get driverOnboardCoreCerts;

  /// No description provided for @driverOnboardDoneAssignVehicle.
  ///
  /// In en, this message translates to:
  /// **'Assign Vehicle'**
  String get driverOnboardDoneAssignVehicle;

  /// No description provided for @driverOnboardDoneDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get driverOnboardDoneDashboard;

  /// No description provided for @driverOnboardDoneEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'EMPLOYEE ID'**
  String get driverOnboardDoneEmployeeId;

  /// No description provided for @driverOnboardDoneHeading.
  ///
  /// In en, this message translates to:
  /// **'Driver Added Successfully'**
  String get driverOnboardDoneHeading;

  /// No description provided for @driverOnboardDoneNotified.
  ///
  /// In en, this message translates to:
  /// **'Driver has been notified via email and SMS'**
  String get driverOnboardDoneNotified;

  /// No description provided for @driverOnboardDoneReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for Assignment'**
  String get driverOnboardDoneReady;

  /// No description provided for @driverOnboardDoneStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get driverOnboardDoneStatus;

  /// No description provided for @driverOnboardDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The driver registration process is complete and verified.'**
  String get driverOnboardDoneSubtitle;

  /// No description provided for @driverOnboardDoneViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Driver Profile'**
  String get driverOnboardDoneViewProfile;

  /// No description provided for @driverOnboardExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'EXPIRATION DATE'**
  String get driverOnboardExpirationDate;

  /// No description provided for @driverOnboardHeading.
  ///
  /// In en, this message translates to:
  /// **'Training & Certifications'**
  String get driverOnboardHeading;

  /// No description provided for @driverOnboardNextReview.
  ///
  /// In en, this message translates to:
  /// **'Next: Review'**
  String get driverOnboardNextReview;

  /// No description provided for @driverOnboardPercentComplete.
  ///
  /// In en, this message translates to:
  /// **'66% Complete'**
  String get driverOnboardPercentComplete;

  /// No description provided for @driverOnboardSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get driverOnboardSelectDate;

  /// No description provided for @driverOnboardSkills.
  ///
  /// In en, this message translates to:
  /// **'SPECIALIZED SKILLS'**
  String get driverOnboardSkills;

  /// No description provided for @driverOnboardSkillsHelp.
  ///
  /// In en, this message translates to:
  /// **'List any other relevant qualifications or equipment experience (e.g., forklift license, refrigerated cargo handling).'**
  String get driverOnboardSkillsHelp;

  /// No description provided for @driverOnboardSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'Type your additional skills here...'**
  String get driverOnboardSkillsHint;

  /// No description provided for @driverOnboardStep.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 OF 3'**
  String get driverOnboardStep;

  /// No description provided for @driverOnboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please provide details of your professional certifications and specialized skills.'**
  String get driverOnboardSubtitle;

  /// No description provided for @driverOnboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get driverOnboardTitle;

  /// No description provided for @driverOnboardUploadCert.
  ///
  /// In en, this message translates to:
  /// **'Upload Certificate (PDF/JPG)'**
  String get driverOnboardUploadCert;

  /// No description provided for @driverSelectVehicleAssigningTo.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNING TO'**
  String get driverSelectVehicleAssigningTo;

  /// No description provided for @driverSelectVehicleAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Available Vehicles'**
  String driverSelectVehicleAvailableCount(int count);

  /// No description provided for @driverSelectVehicleChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get driverSelectVehicleChange;

  /// No description provided for @driverSelectVehicleFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Units'**
  String get driverSelectVehicleFilterAll;

  /// No description provided for @driverSelectVehicleFilterHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy Duty'**
  String get driverSelectVehicleFilterHeavy;

  /// No description provided for @driverSelectVehicleFilterLowFuel.
  ///
  /// In en, this message translates to:
  /// **'Low Fuel'**
  String get driverSelectVehicleFilterLowFuel;

  /// No description provided for @driverSelectVehicleFilterMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Duty'**
  String get driverSelectVehicleFilterMedium;

  /// No description provided for @driverSelectVehicleFuelLevel.
  ///
  /// In en, this message translates to:
  /// **'FUEL LEVEL'**
  String get driverSelectVehicleFuelLevel;

  /// No description provided for @driverSelectVehicleOdometer.
  ///
  /// In en, this message translates to:
  /// **'ODOMETER'**
  String get driverSelectVehicleOdometer;

  /// No description provided for @driverSelectVehicleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Unit ID, VIN or Model...'**
  String get driverSelectVehicleSearchHint;

  /// No description provided for @driverSelectVehicleSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get driverSelectVehicleSelect;

  /// No description provided for @driverSelectVehicleSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get driverSelectVehicleSort;

  /// No description provided for @driverSelectVehicleStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get driverSelectVehicleStatusAvailable;

  /// No description provided for @driverSelectVehicleStatusLowFuel.
  ///
  /// In en, this message translates to:
  /// **'Low Fuel'**
  String get driverSelectVehicleStatusLowFuel;

  /// No description provided for @driverSelectVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Vehicle'**
  String get driverSelectVehicleTitle;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'ACTIVE TRIP'**
  String get driverDashActiveTripBadge;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get driverDashDetails;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get driverDashFrom;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get driverDashGoodAfternoon;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get driverDashGoodEvening;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get driverDashGoodMorning;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'No Active Trip'**
  String get driverDashNoActiveTrip;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'You have no ongoing trips right now.'**
  String get driverDashNoOngoingTrips;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Your trip is still ongoing — please keep location turned on.'**
  String get driverDashOngoingWarning;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get driverDashProgress;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Tap to Enable'**
  String get driverDashTapToEnable;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get driverDashTo;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Tracking On'**
  String get driverDashTrackingOn;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Current Trip'**
  String get driverHomeCurrentTrip;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'DROPOFF'**
  String get driverHomeDropoff;

  /// No description provided for @driverHomeEta.
  ///
  /// In en, this message translates to:
  /// **'ETA: {time}'**
  String driverHomeEta(String time);

  /// No description provided for @driverHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name} 👋'**
  String driverHomeGreeting(String name);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get driverHomeInProgress;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Navigate to Dropoff'**
  String get driverHomeNavigateDropoff;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'On Duty'**
  String get driverHomeOnDuty;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'PICKUP'**
  String get driverHomePickup;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get driverHomeScheduled;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get driverHomeStatDone;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get driverHomeStatLeft;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get driverHomeStatTotal;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get driverHomeTomorrow;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trips'**
  String get driverHomeUpcomingTrips;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get driverHomeViewAll;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Assigned Unit'**
  String get driverVehicleAssignedUnit;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get driverVehicleAvailable;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get driverVehicleBattery;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Brake Inspection'**
  String get driverVehicleBrakeInspection;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Class A'**
  String get driverVehicleClassA;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get driverVehicleDiesel;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Engine Temp'**
  String get driverVehicleEngineTemp;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Fuel Level'**
  String get driverVehicleFuelLevel;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Heavy Duty'**
  String get driverVehicleHeavyDuty;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Last Oil Change'**
  String get driverVehicleLastOilChange;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Log Refuel'**
  String get driverVehicleLogRefuel;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Maintenance Status'**
  String get driverVehicleMaintenanceStatus;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Next Service Due'**
  String get driverVehicleNextServiceDue;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get driverVehicleNormal;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get driverVehicleOdometer;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Pre-Trip Check'**
  String get driverVehiclePreTripCheck;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get driverVehicleQuickActions;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get driverVehicleReportIssue;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'My Vehicle'**
  String get driverVehicleTitle;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'UP TO DATE'**
  String get driverVehicleUpToDate;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get driverVehicleViewHistory;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'About RR Logistics'**
  String get feDashAboutRr;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Active Trips'**
  String get feDashActiveTrips;

  /// No description provided for @feDashActiveTripsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} active trip} other{{count} active trips}}'**
  String feDashActiveTripsCount(int count);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get feDashClearAll;

  /// No description provided for @feDashDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String feDashDaysAgo(int count);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Help & Support coming soon.'**
  String get feDashHelpComingSoon;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get feDashHelpSupport;

  /// No description provided for @feDashHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String feDashHoursAgo(int count);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get feDashJustNow;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get feDashLive;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Could not load trips'**
  String get feDashLoadTripsFailed;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get feDashLogOut;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get feDashLogout;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get feDashMarkAllRead;

  /// No description provided for @feDashMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String feDashMinutesAgo(int count);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get feDashMore;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get feDashNavDashboard;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get feDashNavProfile;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get feDashNavRecords;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'NAVIGATION'**
  String get feDashNavigation;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'No active trips'**
  String get feDashNoActiveTrips;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'You will be notified when a new trip is assigned'**
  String get feDashNoActiveTripsHint;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get feDashNoNotifications;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'No synced trips yet'**
  String get feDashNoSyncedTrips;

  /// No description provided for @feDashNoTripsMatch.
  ///
  /// In en, this message translates to:
  /// **'No trips match \"{query}\"'**
  String feDashNoTripsMatch(String query);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get feDashNotifications;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'RR Web Records'**
  String get feDashRecordsTitle;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Search by bilty number'**
  String get feDashSearchBilty;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get feDashSettings;

  /// No description provided for @feDashSyncedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} synced'**
  String feDashSyncedCount(int count);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Synced trips'**
  String get feDashSyncedTrips;

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Trips synced to RR web will appear here'**
  String get feDashSyncedTripsHint;

  /// No description provided for @feDashUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'updated {time}'**
  String feDashUpdatedAt(String time);

  /// No description provided for @feDashWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String feDashWelcomeBack(String name);

  /// Driver/FE dashboard label
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get feDashWorkerFallback;

  /// No description provided for @stageCommonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get stageCommonAdd;

  /// No description provided for @stageCommonAlreadyOnRr.
  ///
  /// In en, this message translates to:
  /// **'Already on RR'**
  String get stageCommonAlreadyOnRr;

  /// No description provided for @stageCommonBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get stageCommonBackToDashboard;

  /// No description provided for @stageCommonBrowsePhotos.
  ///
  /// In en, this message translates to:
  /// **'Browse photos'**
  String get stageCommonBrowsePhotos;

  /// No description provided for @stageCommonCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get stageCommonCamera;

  /// No description provided for @stageCommonCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Enable Camera access for this app in Settings and try again.'**
  String get stageCommonCameraDenied;

  /// No description provided for @stageCommonCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open camera. Please try again.'**
  String get stageCommonCameraFailed;

  /// No description provided for @stageCommonCameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or Gallery'**
  String get stageCommonCameraOrGallery;

  /// No description provided for @stageCommonChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get stageCommonChooseGallery;

  /// No description provided for @stageCommonCompleteStage.
  ///
  /// In en, this message translates to:
  /// **'Complete Stage ✓'**
  String get stageCommonCompleteStage;

  /// No description provided for @stageCommonConfirmWeight.
  ///
  /// In en, this message translates to:
  /// **'Confirm Weight'**
  String get stageCommonConfirmWeight;

  /// No description provided for @stageCommonDraftSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Draft save failed ({status}): {detail}'**
  String stageCommonDraftSaveFailed(String status, String detail);

  /// No description provided for @stageCommonDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get stageCommonDriver;

  /// Input hint example
  ///
  /// In en, this message translates to:
  /// **'e.g. {value}'**
  String stageCommonEg(String value);

  /// No description provided for @stageCommonFailedWith.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String stageCommonFailedWith(String error);

  /// No description provided for @stageCommonFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String stageCommonFieldRequired(String label);

  /// No description provided for @stageCommonFilePickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker. Please try again.'**
  String get stageCommonFilePickerFailed;

  /// No description provided for @stageCommonFutureNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'{label} cannot be a future date/time — using current time instead'**
  String stageCommonFutureNotAllowed(String label);

  /// No description provided for @stageCommonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get stageCommonGallery;

  /// No description provided for @stageCommonGalleryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not access gallery. Please try again.'**
  String get stageCommonGalleryFailed;

  /// No description provided for @stageCommonHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String stageCommonHoursAgo(int hours);

  /// No description provided for @stageCommonImageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get stageCommonImageLoadFailed;

  /// No description provided for @stageCommonImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get stageCommonImageSelected;

  /// No description provided for @stageCommonInsideFactory.
  ///
  /// In en, this message translates to:
  /// **'Inside Factory'**
  String get stageCommonInsideFactory;

  /// No description provided for @stageCommonJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get stageCommonJustNow;

  /// No description provided for @stageCommonLastSaved.
  ///
  /// In en, this message translates to:
  /// **'Last saved: {time}'**
  String stageCommonLastSaved(String time);

  /// No description provided for @stageCommonLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get stageCommonLoad;

  /// No description provided for @stageCommonLoadOwner.
  ///
  /// In en, this message translates to:
  /// **'Load Owner'**
  String get stageCommonLoadOwner;

  /// No description provided for @stageCommonLoadOwnerNotified.
  ///
  /// In en, this message translates to:
  /// **'Load owner notified successfully!'**
  String get stageCommonLoadOwnerNotified;

  /// No description provided for @stageCommonLoadTripFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trip details. Please try again.'**
  String get stageCommonLoadTripFailed;

  /// No description provided for @stageCommonLockedSynced.
  ///
  /// In en, this message translates to:
  /// **'Locked — already synced to RR'**
  String get stageCommonLockedSynced;

  /// No description provided for @stageCommonLpTeam.
  ///
  /// In en, this message translates to:
  /// **'LP Team'**
  String get stageCommonLpTeam;

  /// No description provided for @stageCommonLpTeamNotified.
  ///
  /// In en, this message translates to:
  /// **'LP team notified successfully!'**
  String get stageCommonLpTeamNotified;

  /// Validation: input too long
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} characters'**
  String stageCommonMaxChars(int count);

  /// No description provided for @stageCommonMinAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String stageCommonMinAgo(int minutes);

  /// No description provided for @stageCommonNotified.
  ///
  /// In en, this message translates to:
  /// **'{name} Notified'**
  String stageCommonNotified(String name);

  /// No description provided for @stageCommonNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify {name}'**
  String stageCommonNotify(String name);

  /// No description provided for @stageCommonNotifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Notification failed: {error}'**
  String stageCommonNotifyFailed(String error);

  /// No description provided for @stageCommonNumberTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short to be a valid number'**
  String get stageCommonNumberTooShort;

  /// No description provided for @stageCommonOutsideFactory.
  ///
  /// In en, this message translates to:
  /// **'Outside Factory'**
  String get stageCommonOutsideFactory;

  /// No description provided for @stageCommonPdfOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the PDF.'**
  String get stageCommonPdfOpenFailed;

  /// No description provided for @stageCommonPhone10Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 10 digits'**
  String get stageCommonPhone10Digits;

  /// No description provided for @stageCommonPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get stageCommonPhoneRequired;

  /// No description provided for @stageCommonPhotosDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Enable Photos access for this app in Settings and try again.'**
  String get stageCommonPhotosDenied;

  /// Snackbar listing missing required documents
  ///
  /// In en, this message translates to:
  /// **'Please upload: {docs}'**
  String stageCommonPleaseUpload(String docs);

  /// No description provided for @stageCommonReadOnlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Read-only — Completed Trip'**
  String get stageCommonReadOnlyCompleted;

  /// No description provided for @stageCommonReadyToUpload.
  ///
  /// In en, this message translates to:
  /// **'Ready to Upload'**
  String get stageCommonReadyToUpload;

  /// No description provided for @stageCommonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get stageCommonRemove;

  /// No description provided for @stageCommonReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get stageCommonReplace;

  /// No description provided for @stageCommonRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get stageCommonRetake;

  /// No description provided for @stageCommonSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue →'**
  String get stageCommonSaveContinue;

  /// No description provided for @stageCommonSavingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get stageCommonSavingEllipsis;

  /// No description provided for @stageCommonSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select date & time'**
  String get stageCommonSelectDateTime;

  /// No description provided for @stageCommonSendingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get stageCommonSendingEllipsis;

  /// No description provided for @stageCommonStateCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get stageCommonStateCancelled;

  /// No description provided for @stageCommonStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get stageCommonStateCompleted;

  /// No description provided for @stageCommonStateInTransit.
  ///
  /// In en, this message translates to:
  /// **'IN TRANSIT'**
  String get stageCommonStateInTransit;

  /// No description provided for @stageCommonStateOngoing.
  ///
  /// In en, this message translates to:
  /// **'ONGOING'**
  String get stageCommonStateOngoing;

  /// No description provided for @stageCommonStatePending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get stageCommonStatePending;

  /// No description provided for @stageCommonSubmittedBy.
  ///
  /// In en, this message translates to:
  /// **'Submitted by @{username}'**
  String stageCommonSubmittedBy(String username);

  /// No description provided for @stageCommonSubmittingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get stageCommonSubmittingEllipsis;

  /// No description provided for @stageCommonTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get stageCommonTakePhoto;

  /// No description provided for @stageCommonTapToReplace.
  ///
  /// In en, this message translates to:
  /// **'Tap to replace'**
  String get stageCommonTapToReplace;

  /// No description provided for @stageCommonTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get stageCommonTapToView;

  /// No description provided for @stageCommonTrackTruck.
  ///
  /// In en, this message translates to:
  /// **'Track Truck'**
  String get stageCommonTrackTruck;

  /// No description provided for @stageCommonUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get stageCommonUnknownError;

  /// No description provided for @stageCommonUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get stageCommonUploadFailed;

  /// No description provided for @stageCommonUploadWeighSlip.
  ///
  /// In en, this message translates to:
  /// **'Upload Weigh Slip'**
  String get stageCommonUploadWeighSlip;

  /// No description provided for @stageCommonUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get stageCommonUploaded;

  /// No description provided for @stageCommonUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get stageCommonUploading;

  /// No description provided for @stageCommonUploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get stageCommonUploadingEllipsis;

  /// No description provided for @stageCommonUseCamera.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get stageCommonUseCamera;

  /// No description provided for @stageCommonVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get stageCommonVehicle;

  /// No description provided for @stageCommonWeighSlip.
  ///
  /// In en, this message translates to:
  /// **'Weigh Slip'**
  String get stageCommonWeighSlip;

  /// No description provided for @stageCommonWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get stageCommonWeight;

  /// {unit} is kg or tons as stored, not translated
  ///
  /// In en, this message translates to:
  /// **'Weight recorded: {weight} {unit}'**
  String stageCommonWeightRecorded(String weight, String unit);

  /// No description provided for @stageDocAadhaarCard.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card'**
  String get stageDocAadhaarCard;

  /// No description provided for @stageDocBackSide.
  ///
  /// In en, this message translates to:
  /// **'Back Side'**
  String get stageDocBackSide;

  /// No description provided for @stageDocBilty.
  ///
  /// In en, this message translates to:
  /// **'Bilty'**
  String get stageDocBilty;

  /// No description provided for @stageDocCancelledCheque.
  ///
  /// In en, this message translates to:
  /// **'Cancelled Cheque (Owner / Transporter)'**
  String get stageDocCancelledCheque;

  /// No description provided for @stageDocDrivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get stageDocDrivingLicense;

  /// No description provided for @stageDocDrivingLicenseBack.
  ///
  /// In en, this message translates to:
  /// **'Driving License (Back)'**
  String get stageDocDrivingLicenseBack;

  /// No description provided for @stageDocDrivingLicenseFront.
  ///
  /// In en, this message translates to:
  /// **'Driving License (Front)'**
  String get stageDocDrivingLicenseFront;

  /// No description provided for @stageDocEway.
  ///
  /// In en, this message translates to:
  /// **'E-way Bill'**
  String get stageDocEway;

  /// No description provided for @stageDocFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness Certificate'**
  String get stageDocFitness;

  /// No description provided for @stageDocFrontSide.
  ///
  /// In en, this message translates to:
  /// **'Front Side'**
  String get stageDocFrontSide;

  /// No description provided for @stageDocInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get stageDocInsurance;

  /// No description provided for @stageDocInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get stageDocInvoice;

  /// No description provided for @stageDocLoadingSlip.
  ///
  /// In en, this message translates to:
  /// **'Loading Slip'**
  String get stageDocLoadingSlip;

  /// No description provided for @stageDocPermit.
  ///
  /// In en, this message translates to:
  /// **'Permit'**
  String get stageDocPermit;

  /// No description provided for @stageDocPollution.
  ///
  /// In en, this message translates to:
  /// **'Pollution Certificate'**
  String get stageDocPollution;

  /// No description provided for @stageDocRcFull.
  ///
  /// In en, this message translates to:
  /// **'RC (Registration Certificate)'**
  String get stageDocRcFull;

  /// No description provided for @stageDocTaxDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Tax Declaration'**
  String get stageDocTaxDeclaration;

  /// No description provided for @stageRrAllStagesCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'All stages complete'**
  String get stageRrAllStagesCompleteTitle;

  /// No description provided for @stageRrLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get stageRrLater;

  /// No description provided for @stageRrNotSyncedSub.
  ///
  /// In en, this message translates to:
  /// **'Tap retry to push this trip to RR Web'**
  String get stageRrNotSyncedSub;

  /// No description provided for @stageRrNotSyncedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not synced to RR'**
  String get stageRrNotSyncedTitle;

  /// No description provided for @stageRrSendToRr.
  ///
  /// In en, this message translates to:
  /// **'Send to RR'**
  String get stageRrSendToRr;

  /// No description provided for @stageRrSyncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get stageRrSyncComplete;

  /// Snackbar when RR sync fails; {error} is the raw error text
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String stageRrSyncFailed(String error);

  /// No description provided for @stageRrSyncFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get stageRrSyncFailedShort;

  /// No description provided for @stageRrSyncFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'RR sync failed'**
  String get stageRrSyncFailedTitle;

  /// No description provided for @stageRrSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get stageRrSyncNow;

  /// No description provided for @stageRrSyncPromptBody.
  ///
  /// In en, this message translates to:
  /// **'This trip is fully completed. Sync all uploads and data to RR web now?'**
  String get stageRrSyncPromptBody;

  /// No description provided for @stageRrSyncToRrWeb.
  ///
  /// In en, this message translates to:
  /// **'Sync to RR web'**
  String get stageRrSyncToRrWeb;

  /// No description provided for @stageRrSyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync to RR'**
  String get stageRrSyncTooltip;

  /// No description provided for @stageRrSyncedToRrWeb.
  ///
  /// In en, this message translates to:
  /// **'Synced to RR web'**
  String get stageRrSyncedToRrWeb;

  /// No description provided for @stageRrSyncingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get stageRrSyncingEllipsis;

  /// No description provided for @stageRrTripSynced.
  ///
  /// In en, this message translates to:
  /// **'Trip synced'**
  String get stageRrTripSynced;

  /// No description provided for @stageS0Intro.
  ///
  /// In en, this message translates to:
  /// **'Before proceeding to Stage 1, complete the following steps:'**
  String get stageS0Intro;

  /// No description provided for @stageS0Step1Sub.
  ///
  /// In en, this message translates to:
  /// **'Tap Stage 1 in the strip above to enter vehicle & driver details.'**
  String get stageS0Step1Sub;

  /// No description provided for @stageS0Step1Title.
  ///
  /// In en, this message translates to:
  /// **'Fill Stage 1 — Truck Registration'**
  String get stageS0Step1Title;

  /// No description provided for @stageS0Step2Sub.
  ///
  /// In en, this message translates to:
  /// **'Once Stage 1 is complete, use the \"Send to RR\" button above to push the trip.'**
  String get stageS0Step2Sub;

  /// No description provided for @stageS0Step2Title.
  ///
  /// In en, this message translates to:
  /// **'Sync trip to RR'**
  String get stageS0Step2Title;

  /// No description provided for @stageS0Step3Sub.
  ///
  /// In en, this message translates to:
  /// **'After RR sync, proceed with Pre-Arrival Compliance Check.'**
  String get stageS0Step3Sub;

  /// No description provided for @stageS0Step3Title.
  ///
  /// In en, this message translates to:
  /// **'Continue to Stage 2'**
  String get stageS0Step3Title;

  /// No description provided for @stageS0Title.
  ///
  /// In en, this message translates to:
  /// **'Stage 0 — RR Sync'**
  String get stageS0Title;

  /// No description provided for @stageS1AadhaarBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the back of the Aadhaar card'**
  String get stageS1AadhaarBackPhoto;

  /// No description provided for @stageS1AadhaarFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the front of the Aadhaar card'**
  String get stageS1AadhaarFrontPhoto;

  /// No description provided for @stageS1AadhaarLength.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar must be exactly 12 digits'**
  String get stageS1AadhaarLength;

  /// No description provided for @stageS1AadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number (12 digits)'**
  String get stageS1AadhaarNumber;

  /// No description provided for @stageS1AppointNewDriver.
  ///
  /// In en, this message translates to:
  /// **'Appoint New Driver'**
  String get stageS1AppointNewDriver;

  /// No description provided for @stageS1DlBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the back of the driving license'**
  String get stageS1DlBackPhoto;

  /// No description provided for @stageS1DlFormatHint.
  ///
  /// In en, this message translates to:
  /// **'New: RJ1420230012345   Old: RJ14/1234/2009'**
  String get stageS1DlFormatHint;

  /// No description provided for @stageS1DlFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the front of the driving license'**
  String get stageS1DlFrontPhoto;

  /// No description provided for @stageS1DlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid format — e.g. RJ1420230012345 (state+RTO+year+7 digits)'**
  String get stageS1DlInvalid;

  /// No description provided for @stageS1DlNumber.
  ///
  /// In en, this message translates to:
  /// **'Driving License No.'**
  String get stageS1DlNumber;

  /// No description provided for @stageS1DlRequired.
  ///
  /// In en, this message translates to:
  /// **'Driving License is required'**
  String get stageS1DlRequired;

  /// No description provided for @stageS1DriverName.
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get stageS1DriverName;

  /// No description provided for @stageS1DriverNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Driver Name is required'**
  String get stageS1DriverNameRequired;

  /// No description provided for @stageS1DriverReassigned.
  ///
  /// In en, this message translates to:
  /// **'Driver reassigned'**
  String get stageS1DriverReassigned;

  /// No description provided for @stageS1FitnessNumber.
  ///
  /// In en, this message translates to:
  /// **'Fitness Number'**
  String get stageS1FitnessNumber;

  /// No description provided for @stageS1InsuranceNumber.
  ///
  /// In en, this message translates to:
  /// **'Insurance Policy Number'**
  String get stageS1InsuranceNumber;

  /// No description provided for @stageS1NotNecessary.
  ///
  /// In en, this message translates to:
  /// **'Filling S1 is not necessary for this trip.'**
  String get stageS1NotNecessary;

  /// No description provided for @stageS1OnlyAlphabets.
  ///
  /// In en, this message translates to:
  /// **'Only alphabets allowed'**
  String get stageS1OnlyAlphabets;

  /// No description provided for @stageS1PermitNumber.
  ///
  /// In en, this message translates to:
  /// **'Permit Number'**
  String get stageS1PermitNumber;

  /// No description provided for @stageS1PucNumber.
  ///
  /// In en, this message translates to:
  /// **'PUC Number'**
  String get stageS1PucNumber;

  /// No description provided for @stageS1RcBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the back of the RC'**
  String get stageS1RcBackPhoto;

  /// No description provided for @stageS1RcFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the front of the RC'**
  String get stageS1RcFrontPhoto;

  /// No description provided for @stageS1RcInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid RC number — must contain both letters and digits'**
  String get stageS1RcInvalid;

  /// No description provided for @stageS1RcNumber.
  ///
  /// In en, this message translates to:
  /// **'RC Number'**
  String get stageS1RcNumber;

  /// No description provided for @stageS1Reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get stageS1Reassign;

  /// Confirm dialog body; {name} is the selected driver name
  ///
  /// In en, this message translates to:
  /// **'This trip will be reassigned to {name} on RR — the My Trips list and crew records will update to reflect this.'**
  String stageS1ReassignBody(String name);

  /// No description provided for @stageS1ReassignFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reassign driver'**
  String get stageS1ReassignFailed;

  /// No description provided for @stageS1ReassignTitle.
  ///
  /// In en, this message translates to:
  /// **'Reassign Driver?'**
  String get stageS1ReassignTitle;

  /// Button to confirm driver reassignment
  ///
  /// In en, this message translates to:
  /// **'Reassign to {name}'**
  String stageS1ReassignTo(String name);

  /// No description provided for @stageS1Saved.
  ///
  /// In en, this message translates to:
  /// **'Stage 1 saved. Proceed to compliance check.'**
  String get stageS1Saved;

  /// No description provided for @stageS1SearchDriver.
  ///
  /// In en, this message translates to:
  /// **'Search Driver by Name or Phone'**
  String get stageS1SearchDriver;

  /// No description provided for @stageS1SecDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver Details'**
  String get stageS1SecDriver;

  /// No description provided for @stageS1SecOwnerDocs.
  ///
  /// In en, this message translates to:
  /// **'Owner Documents'**
  String get stageS1SecOwnerDocs;

  /// No description provided for @stageS1SecOwnerPayment.
  ///
  /// In en, this message translates to:
  /// **'Truck Owner Payment Details'**
  String get stageS1SecOwnerPayment;

  /// No description provided for @stageS1SecVehicleDocs.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Documents'**
  String get stageS1SecVehicleDocs;

  /// No description provided for @stageS1SelectedDriver.
  ///
  /// In en, this message translates to:
  /// **'the selected driver'**
  String get stageS1SelectedDriver;

  /// No description provided for @stageS1ThisDriver.
  ///
  /// In en, this message translates to:
  /// **'this driver'**
  String get stageS1ThisDriver;

  /// No description provided for @stageS1Updated.
  ///
  /// In en, this message translates to:
  /// **'Stage 1 updated successfully.'**
  String get stageS1Updated;

  /// No description provided for @stageS1UploadCancelledCheque.
  ///
  /// In en, this message translates to:
  /// **'Upload a cancelled cheque'**
  String get stageS1UploadCancelledCheque;

  /// No description provided for @stageS1UploadFitness.
  ///
  /// In en, this message translates to:
  /// **'Upload fitness certificate'**
  String get stageS1UploadFitness;

  /// No description provided for @stageS1UploadInsurance.
  ///
  /// In en, this message translates to:
  /// **'Upload insurance document'**
  String get stageS1UploadInsurance;

  /// No description provided for @stageS1UploadPan.
  ///
  /// In en, this message translates to:
  /// **'Upload PAN card'**
  String get stageS1UploadPan;

  /// No description provided for @stageS1UploadPermit.
  ///
  /// In en, this message translates to:
  /// **'Upload permit document'**
  String get stageS1UploadPermit;

  /// No description provided for @stageS1UploadPollution.
  ///
  /// In en, this message translates to:
  /// **'Upload pollution certificate'**
  String get stageS1UploadPollution;

  /// No description provided for @stageS1UploadTaxDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Upload tax declaration document'**
  String get stageS1UploadTaxDeclaration;

  /// No description provided for @stageS2AttachSlip.
  ///
  /// In en, this message translates to:
  /// **'Attach the loading slip image'**
  String get stageS2AttachSlip;

  /// No description provided for @stageS2CheckDocs.
  ///
  /// In en, this message translates to:
  /// **'All documents uploaded'**
  String get stageS2CheckDocs;

  /// No description provided for @stageS2CheckDriverDocs.
  ///
  /// In en, this message translates to:
  /// **'Driver documents valid'**
  String get stageS2CheckDriverDocs;

  /// No description provided for @stageS2CheckSpecs.
  ///
  /// In en, this message translates to:
  /// **'Truck specifications match requirement'**
  String get stageS2CheckSpecs;

  /// No description provided for @stageS2ChooseSlipSource.
  ///
  /// In en, this message translates to:
  /// **'Choose how to add the slip image'**
  String get stageS2ChooseSlipSource;

  /// No description provided for @stageS2DharamKanta.
  ///
  /// In en, this message translates to:
  /// **'Dharam Kanta (Weighbridge)'**
  String get stageS2DharamKanta;

  /// No description provided for @stageS2DharamKantaWhere.
  ///
  /// In en, this message translates to:
  /// **'Is the weighbridge inside or outside the factory?'**
  String get stageS2DharamKantaWhere;

  /// No description provided for @stageS2Done.
  ///
  /// In en, this message translates to:
  /// **'Entry permission issued. Coordinate truck arrival.'**
  String get stageS2Done;

  /// No description provided for @stageS2EmptyWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Empty Truck Weight Before Loading'**
  String get stageS2EmptyWeightLabel;

  /// No description provided for @stageS2EmptyWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Weight recorded outside factory (before loading).'**
  String get stageS2EmptyWeightNote;

  /// No description provided for @stageS2EntryIssued.
  ///
  /// In en, this message translates to:
  /// **'Truck Entry Permission Issued'**
  String get stageS2EntryIssued;

  /// No description provided for @stageS2EntryIssuedNote.
  ///
  /// In en, this message translates to:
  /// **'Factory logistics team receives truck number + driver details.'**
  String get stageS2EntryIssuedNote;

  /// No description provided for @stageS2ErrCheckEntry.
  ///
  /// In en, this message translates to:
  /// **'Please check \"Truck Entry Permission Issued\" before proceeding.'**
  String get stageS2ErrCheckEntry;

  /// No description provided for @stageS2ErrConfirmAll.
  ///
  /// In en, this message translates to:
  /// **'Please confirm all verification items before proceeding.'**
  String get stageS2ErrConfirmAll;

  /// No description provided for @stageS2ErrEmptyWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid empty truck weight (greater than 0) and confirm it.'**
  String get stageS2ErrEmptyWeight;

  /// No description provided for @stageS2ErrEntryRequired.
  ///
  /// In en, this message translates to:
  /// **'Entry Permission must be issued to proceed.'**
  String get stageS2ErrEntryRequired;

  /// No description provided for @stageS2ErrSelectWeighbridge.
  ///
  /// In en, this message translates to:
  /// **'Please select weighbridge location (Inside or Outside Factory).'**
  String get stageS2ErrSelectWeighbridge;

  /// No description provided for @stageS2IssueEntry.
  ///
  /// In en, this message translates to:
  /// **'Issue Entry Permission →'**
  String get stageS2IssueEntry;

  /// No description provided for @stageS2SlipOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional — tap to attach slip image'**
  String get stageS2SlipOptional;

  /// No description provided for @stageS2SlipRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Upload the loading slip before the truck can proceed to the factory.'**
  String get stageS2SlipRequiredBody;

  /// No description provided for @stageS2SlipRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading Slip Required'**
  String get stageS2SlipRequiredTitle;

  /// No description provided for @stageS2SlipUploadedBadge.
  ///
  /// In en, this message translates to:
  /// **'Slip Uploaded'**
  String get stageS2SlipUploadedBadge;

  /// No description provided for @stageS2SlipUploadedByTransporter.
  ///
  /// In en, this message translates to:
  /// **'Slip uploaded by transporter. Tap image to replace if needed.'**
  String get stageS2SlipUploadedByTransporter;

  /// No description provided for @stageS2SlipUploadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading Slip Uploaded'**
  String get stageS2SlipUploadedTitle;

  /// No description provided for @stageS2SubmitSlip.
  ///
  /// In en, this message translates to:
  /// **'Submit Loading Slip'**
  String get stageS2SubmitSlip;

  /// No description provided for @stageS2TapToUploadSlip.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload loading slip'**
  String get stageS2TapToUploadSlip;

  /// No description provided for @stageS2UploadSlipTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Loading Slip'**
  String get stageS2UploadSlipTitle;

  /// No description provided for @stageS2Verifies.
  ///
  /// In en, this message translates to:
  /// **'RR Executive verifies:'**
  String get stageS2Verifies;

  /// No description provided for @stageS2VerifiesNote.
  ///
  /// In en, this message translates to:
  /// **'All items must be confirmed before issuing entry permission.'**
  String get stageS2VerifiesNote;

  /// No description provided for @stageS3ArrivalSteps.
  ///
  /// In en, this message translates to:
  /// **'Arrival Steps'**
  String get stageS3ArrivalSteps;

  /// No description provided for @stageS3AttachEway.
  ///
  /// In en, this message translates to:
  /// **'Attach the e-way bill document'**
  String get stageS3AttachEway;

  /// No description provided for @stageS3AttachInvoice.
  ///
  /// In en, this message translates to:
  /// **'Attach the invoice document'**
  String get stageS3AttachInvoice;

  /// No description provided for @stageS3Coordinates.
  ///
  /// In en, this message translates to:
  /// **'RR Executive coordinates with driver:'**
  String get stageS3Coordinates;

  /// No description provided for @stageS3DharamKanta.
  ///
  /// In en, this message translates to:
  /// **'Dharma Kanta (Weigh Bridge)'**
  String get stageS3DharamKanta;

  /// No description provided for @stageS3DocsToSecurity.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted to security'**
  String get stageS3DocsToSecurity;

  /// No description provided for @stageS3DriverParks.
  ///
  /// In en, this message translates to:
  /// **'Driver parks outside factory'**
  String get stageS3DriverParks;

  /// No description provided for @stageS3EmptyWeight.
  ///
  /// In en, this message translates to:
  /// **'Empty Truck Weight'**
  String get stageS3EmptyWeight;

  /// No description provided for @stageS3EmptyWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Record the empty truck weight before loading.'**
  String get stageS3EmptyWeightNote;

  /// No description provided for @stageS3ErrLoadingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Please check \"Loading Completed\" before completing the stage.'**
  String get stageS3ErrLoadingCompleted;

  /// No description provided for @stageS3ErrStepsLoading.
  ///
  /// In en, this message translates to:
  /// **'All steps must be completed before marking loading complete.'**
  String get stageS3ErrStepsLoading;

  /// No description provided for @stageS3ErrStepsStage.
  ///
  /// In en, this message translates to:
  /// **'All steps must be completed before completing the stage.'**
  String get stageS3ErrStepsStage;

  /// No description provided for @stageS3EwayExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'E-way Bill Expiry Date'**
  String get stageS3EwayExpiryDate;

  /// No description provided for @stageS3EwayIssueDate.
  ///
  /// In en, this message translates to:
  /// **'E-way Bill Issue Date'**
  String get stageS3EwayIssueDate;

  /// No description provided for @stageS3EwayNumber.
  ///
  /// In en, this message translates to:
  /// **'E-way Bill Number'**
  String get stageS3EwayNumber;

  /// No description provided for @stageS3ExitCabin.
  ///
  /// In en, this message translates to:
  /// **'Driver must exit cabin'**
  String get stageS3ExitCabin;

  /// No description provided for @stageS3ExtraInfo.
  ///
  /// In en, this message translates to:
  /// **'Extra info (optional)'**
  String get stageS3ExtraInfo;

  /// No description provided for @stageS3ExtraInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Anything that helps — a close-up of the plate, a visible phone number, etc.'**
  String get stageS3ExtraInfoHint;

  /// No description provided for @stageS3ExtraPhoto.
  ///
  /// In en, this message translates to:
  /// **'Extra photo'**
  String get stageS3ExtraPhoto;

  /// No description provided for @stageS3InvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Invoice Number'**
  String get stageS3InvoiceNumber;

  /// No description provided for @stageS3InvoiceValue.
  ///
  /// In en, this message translates to:
  /// **'Enter Invoice Value (₹, max 10 digits)'**
  String get stageS3InvoiceValue;

  /// No description provided for @stageS3LoadedWeight.
  ///
  /// In en, this message translates to:
  /// **'Loaded Truck Weight'**
  String get stageS3LoadedWeight;

  /// No description provided for @stageS3LoadedWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Record the truck weight after loading is done.'**
  String get stageS3LoadedWeightNote;

  /// No description provided for @stageS3LoadingCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Loading complete. Proceed to factory exit.'**
  String get stageS3LoadingCompleteBody;

  /// No description provided for @stageS3LoadingCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Truck Loading Complete!'**
  String get stageS3LoadingCompleteTitle;

  /// No description provided for @stageS3LoadingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Loading Completed'**
  String get stageS3LoadingCompleted;

  /// No description provided for @stageS3LoadingTiming.
  ///
  /// In en, this message translates to:
  /// **'Loading Timing'**
  String get stageS3LoadingTiming;

  /// No description provided for @stageS3NextStageExit.
  ///
  /// In en, this message translates to:
  /// **'Next Stage — Truck Exit →'**
  String get stageS3NextStageExit;

  /// No description provided for @stageS3PhotoBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get stageS3PhotoBack;

  /// No description provided for @stageS3PhotoFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get stageS3PhotoFront;

  /// No description provided for @stageS3PhotoLeft.
  ///
  /// In en, this message translates to:
  /// **'Left Side'**
  String get stageS3PhotoLeft;

  /// No description provided for @stageS3PhotoRight.
  ///
  /// In en, this message translates to:
  /// **'Right Side'**
  String get stageS3PhotoRight;

  /// No description provided for @stageS3PhotosAdded.
  ///
  /// In en, this message translates to:
  /// **'{count}/4 photos added'**
  String stageS3PhotosAdded(int count);

  /// No description provided for @stageS3PhotosNeedPhone.
  ///
  /// In en, this message translates to:
  /// **'{count}/4 photos · phone number needed'**
  String stageS3PhotosNeedPhone(int count);

  /// No description provided for @stageS3SafetyGear.
  ///
  /// In en, this message translates to:
  /// **'Safety shoes and helmet required'**
  String get stageS3SafetyGear;

  /// No description provided for @stageS3SafetyRules.
  ///
  /// In en, this message translates to:
  /// **'Driver Safety Rules'**
  String get stageS3SafetyRules;

  /// No description provided for @stageS3SecurityVerifies.
  ///
  /// In en, this message translates to:
  /// **'Security verifies vehicle requirements'**
  String get stageS3SecurityVerifies;

  /// No description provided for @stageS3SendForId.
  ///
  /// In en, this message translates to:
  /// **'Send for Identification'**
  String get stageS3SendForId;

  /// No description provided for @stageS3SentForId.
  ///
  /// In en, this message translates to:
  /// **'Sent for identification'**
  String get stageS3SentForId;

  /// No description provided for @stageS3TruckPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number on the truck'**
  String get stageS3TruckPhone;

  /// No description provided for @stageS3TruckPhotosFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send truck photos: {error}'**
  String stageS3TruckPhotosFailed(String error);

  /// No description provided for @stageS3TruckPhotosSent.
  ///
  /// In en, this message translates to:
  /// **'Truck photos sent for identification.'**
  String get stageS3TruckPhotosSent;

  /// No description provided for @stageS3TruckPictures.
  ///
  /// In en, this message translates to:
  /// **'Truck Pictures'**
  String get stageS3TruckPictures;

  /// No description provided for @stageS3TruckPicturesSub.
  ///
  /// In en, this message translates to:
  /// **'Add photos of all 4 sides of the truck'**
  String get stageS3TruckPicturesSub;

  /// No description provided for @stageS3UploadEway.
  ///
  /// In en, this message translates to:
  /// **'Upload E-way Bill'**
  String get stageS3UploadEway;

  /// No description provided for @stageS3UploadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Upload Invoice'**
  String get stageS3UploadInvoice;

  /// No description provided for @stageS3VehicleReach.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Reach Date And Time'**
  String get stageS3VehicleReach;

  /// No description provided for @stageS3WheelStoppers.
  ///
  /// In en, this message translates to:
  /// **'Wheel stoppers installed'**
  String get stageS3WheelStoppers;

  /// No description provided for @stageS4BiltyDate.
  ///
  /// In en, this message translates to:
  /// **'Bilty Date And Time (Optional)'**
  String get stageS4BiltyDate;

  /// No description provided for @stageS4BiltyNumber.
  ///
  /// In en, this message translates to:
  /// **'Bilty Number (4 digits)'**
  String get stageS4BiltyNumber;

  /// No description provided for @stageS4BiltyNumberError.
  ///
  /// In en, this message translates to:
  /// **'Bilty Number must be exactly 4 digits'**
  String get stageS4BiltyNumberError;

  /// No description provided for @stageS4ChecklistDone.
  ///
  /// In en, this message translates to:
  /// **'Exit checklist complete. Now upload diesel receipt.'**
  String get stageS4ChecklistDone;

  /// No description provided for @stageS4ChooseReceiptSource.
  ///
  /// In en, this message translates to:
  /// **'Choose how to add the receipt image'**
  String get stageS4ChooseReceiptSource;

  /// No description provided for @stageS4ConfirmAllItems.
  ///
  /// In en, this message translates to:
  /// **'Please confirm all items above before proceeding'**
  String get stageS4ConfirmAllItems;

  /// No description provided for @stageS4DieselAndBilty.
  ///
  /// In en, this message translates to:
  /// **'Diesel Receipt and Bilty'**
  String get stageS4DieselAndBilty;

  /// No description provided for @stageS4DieselReceipt.
  ///
  /// In en, this message translates to:
  /// **'Diesel Receipt'**
  String get stageS4DieselReceipt;

  /// No description provided for @stageS4DocsChecked.
  ///
  /// In en, this message translates to:
  /// **'Documents Checked'**
  String get stageS4DocsChecked;

  /// No description provided for @stageS4ExitChecklist.
  ///
  /// In en, this message translates to:
  /// **'Exit Checklist'**
  String get stageS4ExitChecklist;

  /// No description provided for @stageS4ExitProcedure.
  ///
  /// In en, this message translates to:
  /// **'Exit Procedure'**
  String get stageS4ExitProcedure;

  /// No description provided for @stageS4ExitTiming.
  ///
  /// In en, this message translates to:
  /// **'Exit Timing'**
  String get stageS4ExitTiming;

  /// No description provided for @stageS4HeaderDieselSub.
  ///
  /// In en, this message translates to:
  /// **'Upload the diesel receipt to complete Stage 4'**
  String get stageS4HeaderDieselSub;

  /// No description provided for @stageS4HeaderExit.
  ///
  /// In en, this message translates to:
  /// **'Truck Exit From Factory'**
  String get stageS4HeaderExit;

  /// No description provided for @stageS4HeaderExitSub.
  ///
  /// In en, this message translates to:
  /// **'Verify all exit procedures before releasing truck'**
  String get stageS4HeaderExitSub;

  /// No description provided for @stageS4LoadedWeightSlip.
  ///
  /// In en, this message translates to:
  /// **'Loaded Weight Slip'**
  String get stageS4LoadedWeightSlip;

  /// No description provided for @stageS4ManualBilty.
  ///
  /// In en, this message translates to:
  /// **'Manual Bilty Upload'**
  String get stageS4ManualBilty;

  /// No description provided for @stageS4ManualBiltySub.
  ///
  /// In en, this message translates to:
  /// **'Upload the physical bilty document'**
  String get stageS4ManualBiltySub;

  /// No description provided for @stageS4MaterialDocs.
  ///
  /// In en, this message translates to:
  /// **'Material Documents'**
  String get stageS4MaterialDocs;

  /// No description provided for @stageS4MaterialVerification.
  ///
  /// In en, this message translates to:
  /// **'Material Verification Sheet'**
  String get stageS4MaterialVerification;

  /// No description provided for @stageS4MaterialVerificationSub.
  ///
  /// In en, this message translates to:
  /// **'Upload the material verification sheet'**
  String get stageS4MaterialVerificationSub;

  /// No description provided for @stageS4SecurityVerifies.
  ///
  /// In en, this message translates to:
  /// **'Security verifies documents'**
  String get stageS4SecurityVerifies;

  /// No description provided for @stageS4SubmitDiesel.
  ///
  /// In en, this message translates to:
  /// **'Submit Diesel Receipt'**
  String get stageS4SubmitDiesel;

  /// No description provided for @stageS4TapToUploadDiesel.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload diesel receipt'**
  String get stageS4TapToUploadDiesel;

  /// No description provided for @stageS4TruckExits.
  ///
  /// In en, this message translates to:
  /// **'Truck Exits Factory'**
  String get stageS4TruckExits;

  /// No description provided for @stageS4TruckMoves.
  ///
  /// In en, this message translates to:
  /// **'Truck moves to factory exit gate'**
  String get stageS4TruckMoves;

  /// No description provided for @stageS4UploadDiesel.
  ///
  /// In en, this message translates to:
  /// **'Upload Diesel Receipt'**
  String get stageS4UploadDiesel;

  /// No description provided for @stageS4VehicleExit.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Exit Date And Time'**
  String get stageS4VehicleExit;

  /// No description provided for @stageS5AllCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'All stages completed including unloading.'**
  String get stageS5AllCompletedBody;

  /// No description provided for @stageS5AllCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'All Stages Completed!'**
  String get stageS5AllCompletedTitle;

  /// No description provided for @stageS5AllStagesDone.
  ///
  /// In en, this message translates to:
  /// **'All Stages Done'**
  String get stageS5AllStagesDone;

  /// No description provided for @stageS5CameraGalleryPdf.
  ///
  /// In en, this message translates to:
  /// **'Camera, Gallery, or PDF File'**
  String get stageS5CameraGalleryPdf;

  /// No description provided for @stageS5ChoosePodSource.
  ///
  /// In en, this message translates to:
  /// **'Choose how to add the POD document'**
  String get stageS5ChoosePodSource;

  /// No description provided for @stageS5Complete.
  ///
  /// In en, this message translates to:
  /// **'Complete Unloading Stage'**
  String get stageS5Complete;

  /// No description provided for @stageS5FilePdf.
  ///
  /// In en, this message translates to:
  /// **'File (PDF)'**
  String get stageS5FilePdf;

  /// No description provided for @stageS5HaltingCharge.
  ///
  /// In en, this message translates to:
  /// **'Halting Charge (Optional)'**
  String get stageS5HaltingCharge;

  /// No description provided for @stageS5HaltingHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount in ₹ (e.g. 500)'**
  String get stageS5HaltingHint;

  /// No description provided for @stageS5Header.
  ///
  /// In en, this message translates to:
  /// **'Unloading Stage'**
  String get stageS5Header;

  /// No description provided for @stageS5HeaderDone.
  ///
  /// In en, this message translates to:
  /// **'Unloading Stage Complete'**
  String get stageS5HeaderDone;

  /// No description provided for @stageS5HeaderDoneSub.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded. Tap to replace if needed.'**
  String get stageS5HeaderDoneSub;

  /// No description provided for @stageS5HeaderSub.
  ///
  /// In en, this message translates to:
  /// **'Upload POD and enter halting charge if applicable.'**
  String get stageS5HeaderSub;

  /// No description provided for @stageS5PodRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload the Proof of Delivery document'**
  String get stageS5PodRequired;

  /// No description provided for @stageS5PodTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of Delivery (POD)'**
  String get stageS5PodTitle;

  /// No description provided for @stageS5PodUploadedBadge.
  ///
  /// In en, this message translates to:
  /// **'POD Uploaded'**
  String get stageS5PodUploadedBadge;

  /// No description provided for @stageS5TapToUploadPod.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload POD document'**
  String get stageS5TapToUploadPod;

  /// No description provided for @stageS5UnloadingEnd.
  ///
  /// In en, this message translates to:
  /// **'Unloading End Date And Time'**
  String get stageS5UnloadingEnd;

  /// No description provided for @stageS5UnloadingTiming.
  ///
  /// In en, this message translates to:
  /// **'Unloading Timing'**
  String get stageS5UnloadingTiming;

  /// No description provided for @stageS5UploadPod.
  ///
  /// In en, this message translates to:
  /// **'Upload Proof of Delivery'**
  String get stageS5UploadPod;

  /// Short stage-3 name in the stepper (Truck arrival at factory)
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get stageNameArrival;

  /// Short stage-2 name in the stepper (Pre-arrival compliance check)
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get stageNameCompliance;

  /// Short stage-1 name in the stepper (Truck Details)
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stageNameDetails;

  /// Short stage-4 name in the stepper (Truck exit from factory)
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get stageNameExit;

  /// Short stage-5 name in the stepper (Unloading / proof of delivery)
  ///
  /// In en, this message translates to:
  /// **'Unloading'**
  String get stageNameUnloading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
