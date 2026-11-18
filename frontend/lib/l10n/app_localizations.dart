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

  /// Reassign dialog warning: the chosen driver is on another open trip
  ///
  /// In en, this message translates to:
  /// **'This driver has another open trip ({trip}). If you reassign, he will be removed from that trip and tracked on this one.'**
  String stageS1ReassignBusyWarning(String trip);

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

  /// Stage 1 owner documents: the truck owner's PAN number (sent to RR with the PAN photo)
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get stageS1PanNumber;

  /// No description provided for @stageS1PanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid PAN, like ABCDE1234F'**
  String get stageS1PanInvalid;

  /// No description provided for @stageS1PanNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'PAN number is required with the PAN photo'**
  String get stageS1PanNumberRequired;

  /// Stage 1: last date the truck owner's tax declaration (TDS) is valid; RR uses it for TDS
  ///
  /// In en, this message translates to:
  /// **'Tax Declaration Valid Till'**
  String get stageS1TaxValidTill;

  /// No description provided for @stageCommonSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get stageCommonSelectDate;

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

  /// Stage 3 weight box: only the goods weight (dharam kanta), sent to RR as the actual kanta weight
  ///
  /// In en, this message translates to:
  /// **'Only Material Weight'**
  String get stageS3MaterialWeight;

  /// No description provided for @stageS3MaterialWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Enter only the net material (goods) weight from the dharam kanta slip, not the truck weight.'**
  String get stageS3MaterialWeightNote;

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

  /// Stage 4: picked bilty date is earlier than the trip's creation (RR refuses it)
  ///
  /// In en, this message translates to:
  /// **'Bilty date cannot be before the trip was created ({date})'**
  String stageS4BiltyBeforeTrip(String date);

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

  /// No description provided for @createTripAddNewDriver.
  ///
  /// In en, this message translates to:
  /// **'Add New Driver'**
  String get createTripAddNewDriver;

  /// No description provided for @createTripAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get createTripAddressLine1;

  /// No description provided for @createTripAddressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get createTripAddressLine2;

  /// No description provided for @createTripAddressN.
  ///
  /// In en, this message translates to:
  /// **'Address {number}'**
  String createTripAddressN(int number);

  /// No description provided for @createTripAttachingDriver.
  ///
  /// In en, this message translates to:
  /// **'Attaching driver to vehicle on RR…'**
  String get createTripAttachingDriver;

  /// No description provided for @createTripAutoFilledHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled or enter manually'**
  String get createTripAutoFilledHint;

  /// No description provided for @createTripAxleDouble.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get createTripAxleDouble;

  /// No description provided for @createTripAxleMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple'**
  String get createTripAxleMultiple;

  /// No description provided for @createTripAxleSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get createTripAxleSingle;

  /// No description provided for @createTripAxleTriple.
  ///
  /// In en, this message translates to:
  /// **'Triple'**
  String get createTripAxleTriple;

  /// No description provided for @createTripBiddingHint.
  ///
  /// In en, this message translates to:
  /// **'Set your offline bid / booking amount to the vehicle provider'**
  String get createTripBiddingHint;

  /// No description provided for @createTripBodyType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Body Type'**
  String get createTripBodyType;

  /// No description provided for @createTripBookingAmount.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Provider Booking Amount (₹) *'**
  String get createTripBookingAmount;

  /// No description provided for @createTripBookingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 42000  (offline bid sent to vehicle provider)'**
  String get createTripBookingHint;

  /// No description provided for @createTripConsigneeGstin.
  ///
  /// In en, this message translates to:
  /// **'Consignee GSTIN'**
  String get createTripConsigneeGstin;

  /// No description provided for @createTripConsigneeHint.
  ///
  /// In en, this message translates to:
  /// **'Select from Partners to auto fill Consignee details'**
  String get createTripConsigneeHint;

  /// No description provided for @createTripConsigneeName.
  ///
  /// In en, this message translates to:
  /// **'Consignee Name'**
  String get createTripConsigneeName;

  /// No description provided for @createTripConsigneeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. JSW Steel Ltd'**
  String get createTripConsigneeNameHint;

  /// No description provided for @createTripConsignorGstin.
  ///
  /// In en, this message translates to:
  /// **'Consignor GSTIN'**
  String get createTripConsignorGstin;

  /// No description provided for @createTripConsignorHint.
  ///
  /// In en, this message translates to:
  /// **'Select from Partners to auto fill Consignor details'**
  String get createTripConsignorHint;

  /// No description provided for @createTripConsignorName.
  ///
  /// In en, this message translates to:
  /// **'Consignor Name *'**
  String get createTripConsignorName;

  /// No description provided for @createTripConsignorNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tata Steel Ltd'**
  String get createTripConsignorNameHint;

  /// No description provided for @createTripCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get createTripCreateButton;

  /// No description provided for @createTripDepotHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. KNP01'**
  String get createTripDepotHint;

  /// No description provided for @createTripDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get createTripDiscard;

  /// No description provided for @createTripDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits to this trip have not been saved.'**
  String get createTripDiscardBody;

  /// No description provided for @createTripDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get createTripDiscardTitle;

  /// No description provided for @createTripDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver *'**
  String get createTripDriverLabel;

  /// No description provided for @createTripDriverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Full 10-digit phone, or part of the name'**
  String get createTripDriverSearchHint;

  /// No description provided for @createTripDriverSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver Name or Phone Number'**
  String get createTripDriverSearchLabel;

  /// No description provided for @createTripEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip · {ident}'**
  String createTripEditTitle(String ident);

  /// No description provided for @createTripErrAttachDriver.
  ///
  /// In en, this message translates to:
  /// **'Could not attach driver to vehicle on RR: {error}'**
  String createTripErrAttachDriver(String error);

  /// No description provided for @createTripErrCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create trip'**
  String get createTripErrCreateFailed;

  /// No description provided for @createTripErrNoUserFound.
  ///
  /// In en, this message translates to:
  /// **'No user found for this number'**
  String get createTripErrNoUserFound;

  /// No description provided for @createTripErrRrSlow.
  ///
  /// In en, this message translates to:
  /// **'RR is taking too long to respond — please try again'**
  String get createTripErrRrSlow;

  /// No description provided for @createTripErrSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the changes — please try again'**
  String get createTripErrSaveFailed;

  /// No description provided for @createTripExpectedFreight.
  ///
  /// In en, this message translates to:
  /// **'Expected Freight Amount (₹) *'**
  String get createTripExpectedFreight;

  /// No description provided for @createTripFreightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 45000'**
  String get createTripFreightHint;

  /// No description provided for @createTripHandledByPerson.
  ///
  /// In en, this message translates to:
  /// **'Handled by Person *'**
  String get createTripHandledByPerson;

  /// No description provided for @createTripInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 150000'**
  String get createTripInvoiceHint;

  /// No description provided for @createTripInvoiceValue.
  ///
  /// In en, this message translates to:
  /// **'Total Invoice Value (₹) *'**
  String get createTripInvoiceValue;

  /// No description provided for @createTripKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get createTripKeepEditing;

  /// No description provided for @createTripLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark / locality'**
  String get createTripLandmark;

  /// No description provided for @createTripLoadingBodyTypes.
  ///
  /// In en, this message translates to:
  /// **'Loading body types…'**
  String get createTripLoadingBodyTypes;

  /// No description provided for @createTripLoadingCompanies.
  ///
  /// In en, this message translates to:
  /// **'Loading companies…'**
  String get createTripLoadingCompanies;

  /// No description provided for @createTripLoadingPartners.
  ///
  /// In en, this message translates to:
  /// **'Loading partners…'**
  String get createTripLoadingPartners;

  /// No description provided for @createTripLoadingVehicles.
  ///
  /// In en, this message translates to:
  /// **'Loading vehicles…'**
  String get createTripLoadingVehicles;

  /// No description provided for @createTripLoadingWorkers.
  ///
  /// In en, this message translates to:
  /// **'Loading workers…'**
  String get createTripLoadingWorkers;

  /// No description provided for @createTripLookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up…'**
  String get createTripLookingUp;

  /// No description provided for @createTripMarketShort.
  ///
  /// In en, this message translates to:
  /// **'market'**
  String get createTripMarketShort;

  /// No description provided for @createTripMaterialType.
  ///
  /// In en, this message translates to:
  /// **'Material / Product Type *'**
  String get createTripMaterialType;

  /// No description provided for @createTripMaxChars.
  ///
  /// In en, this message translates to:
  /// **'Max {max} characters   {count}/{max}'**
  String createTripMaxChars(int max, int count);

  /// No description provided for @createTripNewTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get createTripNewTrip;

  /// No description provided for @createTripNoCompanies.
  ///
  /// In en, this message translates to:
  /// **'No companies — vehicle from personal fleet below'**
  String get createTripNoCompanies;

  /// No description provided for @createTripNoDriverOnRr.
  ///
  /// In en, this message translates to:
  /// **'This vehicle has no driver assigned on RR — search for one below or add a new driver.'**
  String get createTripNoDriverOnRr;

  /// No description provided for @createTripNoEntryZone.
  ///
  /// In en, this message translates to:
  /// **'No Entry Zone'**
  String get createTripNoEntryZone;

  /// No description provided for @createTripNoVehicles.
  ///
  /// In en, this message translates to:
  /// **'No vehicles found'**
  String get createTripNoVehicles;

  /// No description provided for @createTripNotBookedNotice.
  ///
  /// In en, this message translates to:
  /// **'Not booked on RR yet — changes are saved here and sent to RR when you Confirm Booking.'**
  String get createTripNotBookedNotice;

  /// No description provided for @createTripNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been changed'**
  String get createTripNothingChanged;

  /// No description provided for @createTripParcelDesc.
  ///
  /// In en, this message translates to:
  /// **'Description of Parcel'**
  String get createTripParcelDesc;

  /// No description provided for @createTripParcelDescHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Steel coils'**
  String get createTripParcelDescHint;

  /// No description provided for @createTripPickupCityName.
  ///
  /// In en, this message translates to:
  /// **'Pickup City Name *'**
  String get createTripPickupCityName;

  /// No description provided for @createTripPickupHint.
  ///
  /// In en, this message translates to:
  /// **'Select consignor address to auto fill'**
  String get createTripPickupHint;

  /// No description provided for @createTripPinHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN'**
  String get createTripPinHint;

  /// No description provided for @createTripPinZip.
  ///
  /// In en, this message translates to:
  /// **'Pin / Zip Code'**
  String get createTripPinZip;

  /// No description provided for @createTripSearchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city…'**
  String get createTripSearchCity;

  /// No description provided for @createTripSearchMaterial.
  ///
  /// In en, this message translates to:
  /// **'Search material…'**
  String get createTripSearchMaterial;

  /// No description provided for @createTripSectionBidding.
  ///
  /// In en, this message translates to:
  /// **'Bidding Amount'**
  String get createTripSectionBidding;

  /// No description provided for @createTripSectionConsignee.
  ///
  /// In en, this message translates to:
  /// **'Consignee Info'**
  String get createTripSectionConsignee;

  /// No description provided for @createTripSectionConsignor.
  ///
  /// In en, this message translates to:
  /// **'Consignor Info'**
  String get createTripSectionConsignor;

  /// No description provided for @createTripSectionHandledBy.
  ///
  /// In en, this message translates to:
  /// **'Trip Handled By'**
  String get createTripSectionHandledBy;

  /// No description provided for @createTripSectionParcel.
  ///
  /// In en, this message translates to:
  /// **'Parcel / Load Information'**
  String get createTripSectionParcel;

  /// No description provided for @createTripSectionPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get createTripSectionPickup;

  /// No description provided for @createTripSectionUnload.
  ///
  /// In en, this message translates to:
  /// **'Unload Location'**
  String get createTripSectionUnload;

  /// No description provided for @createTripSectionVehicleProvider.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Provider'**
  String get createTripSectionVehicleProvider;

  /// No description provided for @createTripSectionVehicleSpecs.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Specs'**
  String get createTripSectionVehicleSpecs;

  /// No description provided for @createTripSelectAxle.
  ///
  /// In en, this message translates to:
  /// **'Select axle type'**
  String get createTripSelectAxle;

  /// No description provided for @createTripSelectBodyType.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle body type'**
  String get createTripSelectBodyType;

  /// No description provided for @createTripSelectCompany.
  ///
  /// In en, this message translates to:
  /// **'Select company'**
  String get createTripSelectCompany;

  /// No description provided for @createTripSelectCompanyFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a company above to load vehicles'**
  String get createTripSelectCompanyFirst;

  /// No description provided for @createTripSelectConsigneeAddress.
  ///
  /// In en, this message translates to:
  /// **'Select consignee address (optional)'**
  String get createTripSelectConsigneeAddress;

  /// No description provided for @createTripSelectConsigneeCompany.
  ///
  /// In en, this message translates to:
  /// **'Select Consignee Company'**
  String get createTripSelectConsigneeCompany;

  /// No description provided for @createTripSelectConsignorAddress.
  ///
  /// In en, this message translates to:
  /// **'Select consignor address (optional)'**
  String get createTripSelectConsignorAddress;

  /// No description provided for @createTripSelectConsignorCompany.
  ///
  /// In en, this message translates to:
  /// **'Select Consignor Company *'**
  String get createTripSelectConsignorCompany;

  /// No description provided for @createTripSelectFromPartners.
  ///
  /// In en, this message translates to:
  /// **'Select from Partners (optional)'**
  String get createTripSelectFromPartners;

  /// No description provided for @createTripSelectOpsWorker.
  ///
  /// In en, this message translates to:
  /// **'Select RR Ops worker'**
  String get createTripSelectOpsWorker;

  /// No description provided for @createTripSelectPartner.
  ///
  /// In en, this message translates to:
  /// **'Select partner'**
  String get createTripSelectPartner;

  /// No description provided for @createTripSelectPartnerFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a partner above first'**
  String get createTripSelectPartnerFirst;

  /// No description provided for @createTripSelectProviderCompany.
  ///
  /// In en, this message translates to:
  /// **'Select Provider Company *'**
  String get createTripSelectProviderCompany;

  /// No description provided for @createTripSelectToAutoFill.
  ///
  /// In en, this message translates to:
  /// **'Select to auto-fill address fields'**
  String get createTripSelectToAutoFill;

  /// No description provided for @createTripSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle *'**
  String get createTripSelectVehicle;

  /// No description provided for @createTripSelectVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Select a vehicle'**
  String get createTripSelectVehicleHint;

  /// No description provided for @createTripSelectWheels.
  ///
  /// In en, this message translates to:
  /// **'Select number of wheels'**
  String get createTripSelectWheels;

  /// No description provided for @createTripStepBidding.
  ///
  /// In en, this message translates to:
  /// **'Bidding'**
  String get createTripStepBidding;

  /// No description provided for @createTripStepVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get createTripStepVehicle;

  /// No description provided for @createTripStreetArea.
  ///
  /// In en, this message translates to:
  /// **'Street / area'**
  String get createTripStreetArea;

  /// No description provided for @createTripTabLoadInfo.
  ///
  /// In en, this message translates to:
  /// **'Load Info'**
  String get createTripTabLoadInfo;

  /// No description provided for @createTripTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get createTripTapToSelect;

  /// No description provided for @createTripTotalWeight.
  ///
  /// In en, this message translates to:
  /// **'Total Weight / Quantity *'**
  String get createTripTotalWeight;

  /// No description provided for @createTripUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get createTripUnknown;

  /// No description provided for @createTripUnknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get createTripUnknownError;

  /// No description provided for @createTripUnloadCityName.
  ///
  /// In en, this message translates to:
  /// **'Unload City Name *'**
  String get createTripUnloadCityName;

  /// No description provided for @createTripUnloadHint.
  ///
  /// In en, this message translates to:
  /// **'Select consignee address to auto fill'**
  String get createTripUnloadHint;

  /// No description provided for @createTripUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get createTripUpdate;

  /// No description provided for @createTripUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trip updated'**
  String get createTripUpdated;

  /// No description provided for @createTripValBookingAmount.
  ///
  /// In en, this message translates to:
  /// **'Booking Amount (₹) is required and must be greater than 0'**
  String get createTripValBookingAmount;

  /// No description provided for @createTripValConsignorCompany.
  ///
  /// In en, this message translates to:
  /// **'Must select company from dropdown'**
  String get createTripValConsignorCompany;

  /// No description provided for @createTripValConsignorName.
  ///
  /// In en, this message translates to:
  /// **'Consignor Name is required — pick a partner above or type it in'**
  String get createTripValConsignorName;

  /// No description provided for @createTripValDriver.
  ///
  /// In en, this message translates to:
  /// **'Select a Driver'**
  String get createTripValDriver;

  /// No description provided for @createTripValExpectedFreight.
  ///
  /// In en, this message translates to:
  /// **'Expected Freight Amount (₹) is required by RR create trip'**
  String get createTripValExpectedFreight;

  /// No description provided for @createTripValInvoiceValue.
  ///
  /// In en, this message translates to:
  /// **'Total Invoice Value (₹) is required — used as parcel cost in RR'**
  String get createTripValInvoiceValue;

  /// No description provided for @createTripValMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material / Product Type is required — search and select from the list'**
  String get createTripValMaterial;

  /// No description provided for @createTripValOpsWorker.
  ///
  /// In en, this message translates to:
  /// **'Select the RR Ops worker handling this trip'**
  String get createTripValOpsWorker;

  /// No description provided for @createTripValPickupCity.
  ///
  /// In en, this message translates to:
  /// **'Pickup City is required — search and select from the list'**
  String get createTripValPickupCity;

  /// No description provided for @createTripValUnloadCity.
  ///
  /// In en, this message translates to:
  /// **'Unload City is required — search and select from the list'**
  String get createTripValUnloadCity;

  /// No description provided for @createTripValVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select a Vehicle'**
  String get createTripValVehicle;

  /// No description provided for @createTripValVpCompany.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Provider Company is required — select a company'**
  String get createTripValVpCompany;

  /// No description provided for @createTripValVpPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter Vehicle Provider phone number and tap the result to select'**
  String get createTripValVpPhone;

  /// No description provided for @createTripValWeight.
  ///
  /// In en, this message translates to:
  /// **'Total Weight / Quantity is required'**
  String get createTripValWeight;

  /// No description provided for @createTripVpPhone.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Provider Phone *'**
  String get createTripVpPhone;

  /// No description provided for @createTripVpPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8960281816 — auto-searches at 10 digits'**
  String get createTripVpPhoneHint;

  /// No description provided for @createTripVpSteps.
  ///
  /// In en, this message translates to:
  /// **'Enter provider phone → select user → select company → select vehicle'**
  String get createTripVpSteps;

  /// No description provided for @createTripWarnBusy.
  ///
  /// In en, this message translates to:
  /// **'This driver is already on another open trip — tracking won\'t link to this trip until that one is finished.'**
  String get createTripWarnBusy;

  /// No description provided for @createTripWarnNoApp.
  ///
  /// In en, this message translates to:
  /// **'This driver hasn\'t set up the RR4 app yet — tracking won\'t be available for this trip until they do.'**
  String get createTripWarnNoApp;

  /// No description provided for @createTripWeightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 20'**
  String get createTripWeightHint;

  /// No description provided for @createTripWheelsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} wheels'**
  String createTripWheelsCount(int count);

  /// No description provided for @lpDashAboutRr.
  ///
  /// In en, this message translates to:
  /// **'About RR Logistics'**
  String get lpDashAboutRr;

  /// No description provided for @lpDashAddCompany.
  ///
  /// In en, this message translates to:
  /// **'Add Company'**
  String get lpDashAddCompany;

  /// No description provided for @lpDashAddDriver.
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get lpDashAddDriver;

  /// No description provided for @lpDashAddVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get lpDashAddVehicle;

  /// No description provided for @lpDashBrowseLoads.
  ///
  /// In en, this message translates to:
  /// **'Browse available load requirements'**
  String get lpDashBrowseLoads;

  /// No description provided for @lpDashComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This section is under development\nand will be available soon.'**
  String get lpDashComingSoonBody;

  /// No description provided for @lpDashCreateTrip.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get lpDashCreateTrip;

  /// No description provided for @lpDashEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get lpDashEmployees;

  /// No description provided for @lpDashEmptyTripsHint.
  ///
  /// In en, this message translates to:
  /// **'Create a trip to track it here in real time'**
  String get lpDashEmptyTripsHint;

  /// No description provided for @lpDashFleetHub.
  ///
  /// In en, this message translates to:
  /// **'Fleet Hub'**
  String get lpDashFleetHub;

  /// No description provided for @lpDashFleetStatus.
  ///
  /// In en, this message translates to:
  /// **'Fleet Status'**
  String get lpDashFleetStatus;

  /// No description provided for @lpDashHireTruck.
  ///
  /// In en, this message translates to:
  /// **'Hire Truck'**
  String get lpDashHireTruck;

  /// No description provided for @lpDashLoadFleetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load fleet status'**
  String get lpDashLoadFleetFailed;

  /// No description provided for @lpDashNavFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get lpDashNavFleet;

  /// No description provided for @lpDashNavLoads.
  ///
  /// In en, this message translates to:
  /// **'Loads'**
  String get lpDashNavLoads;

  /// No description provided for @lpDashNavSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get lpDashNavSoon;

  /// No description provided for @lpDashNewTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get lpDashNewTrip;

  /// No description provided for @lpDashNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No RR Web records yet'**
  String get lpDashNoRecords;

  /// No description provided for @lpDashNoRecordsHint.
  ///
  /// In en, this message translates to:
  /// **'Completed RR Web trips will appear here'**
  String get lpDashNoRecordsHint;

  /// No description provided for @lpDashPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Logistic Partner Panel'**
  String get lpDashPanelSubtitle;

  /// No description provided for @lpDashPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String lpDashPendingCount(int count);

  /// No description provided for @lpDashReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get lpDashReconnect;

  /// No description provided for @lpDashRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed RR Web trips'**
  String get lpDashRecordsSubtitle;

  /// No description provided for @lpDashRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get lpDashRequests;

  /// No description provided for @lpDashRrQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'RR QUICK ADD'**
  String get lpDashRrQuickAdd;

  /// No description provided for @lpDashRrSyncFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'RR sync failed: {reason}'**
  String lpDashRrSyncFailedDetail(String reason);

  /// No description provided for @lpDashRrTripNumber.
  ///
  /// In en, this message translates to:
  /// **'RR Trip Number'**
  String get lpDashRrTripNumber;

  /// No description provided for @lpDashS1AllowBody.
  ///
  /// In en, this message translates to:
  /// **'Allow the Field Executive to fill Stage 1 (Truck Detail Registration) docs for this trip?\n\nYou can change this later from the trip card.'**
  String get lpDashS1AllowBody;

  /// No description provided for @lpDashS1AllowTitle.
  ///
  /// In en, this message translates to:
  /// **'Field Executive — Stage 1'**
  String get lpDashS1AllowTitle;

  /// No description provided for @lpDashSearchNewLoads.
  ///
  /// In en, this message translates to:
  /// **'Search New Loads'**
  String get lpDashSearchNewLoads;

  /// No description provided for @lpDashTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get lpDashTrack;

  /// No description provided for @lpDashTripCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip} other{{count} trips}}'**
  String lpDashTripCount(int count);

  /// No description provided for @lpDashTripCreated.
  ///
  /// In en, this message translates to:
  /// **'Trip Created'**
  String get lpDashTripCreated;

  /// No description provided for @lpDashTripNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Trip number copied'**
  String get lpDashTripNumberCopied;

  /// No description provided for @lpDashTripSyncedToRrWeb.
  ///
  /// In en, this message translates to:
  /// **'Trip Synced to RR Web'**
  String get lpDashTripSyncedToRrWeb;

  /// No description provided for @lpDashVehicleHireRequests.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Hire Requests'**
  String get lpDashVehicleHireRequests;

  /// No description provided for @lpOpsAddCompany.
  ///
  /// In en, this message translates to:
  /// **'Add Company'**
  String get lpOpsAddCompany;

  /// No description provided for @lpOpsAddDriver.
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get lpOpsAddDriver;

  /// No description provided for @lpOpsAddVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get lpOpsAddVehicle;

  /// No description provided for @lpOpsDrawerTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get lpOpsDrawerTrack;

  /// No description provided for @lpOpsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No active RR Web trips yet.\nTap \"+ New Trip\" above to get started.'**
  String get lpOpsEmptyBody;

  /// No description provided for @lpOpsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No RR Web trips yet'**
  String get lpOpsEmptyTitle;

  /// No description provided for @lpOpsHireRequests.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Hire Requests'**
  String get lpOpsHireRequests;

  /// No description provided for @lpOpsHireTruck.
  ///
  /// In en, this message translates to:
  /// **'Hire Truck'**
  String get lpOpsHireTruck;

  /// No description provided for @lpOpsNavLoads.
  ///
  /// In en, this message translates to:
  /// **'Loads'**
  String get lpOpsNavLoads;

  /// No description provided for @lpOpsNeedsSlip.
  ///
  /// In en, this message translates to:
  /// **'Needs Slip'**
  String get lpOpsNeedsSlip;

  /// No description provided for @lpOpsNewTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get lpOpsNewTrip;

  /// No description provided for @lpOpsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No trips match \"{query}\"'**
  String lpOpsNoMatch(String query);

  /// No description provided for @lpOpsNoSyncedHint.
  ///
  /// In en, this message translates to:
  /// **'Trips synced to RR web will appear here'**
  String get lpOpsNoSyncedHint;

  /// No description provided for @lpOpsNoSyncedTitle.
  ///
  /// In en, this message translates to:
  /// **'No synced trips yet'**
  String get lpOpsNoSyncedTitle;

  /// No description provided for @lpOpsQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'RR QUICK ADD'**
  String get lpOpsQuickAdd;

  /// No description provided for @lpOpsReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get lpOpsReconnect;

  /// No description provided for @lpOpsRrTripNumber.
  ///
  /// In en, this message translates to:
  /// **'RR Trip Number'**
  String get lpOpsRrTripNumber;

  /// No description provided for @lpOpsS1Body.
  ///
  /// In en, this message translates to:
  /// **'Allow the Field Executive to fill Stage 1 (Truck Detail Registration) docs for this trip?\n\nYou can change this later from the trip card.'**
  String get lpOpsS1Body;

  /// No description provided for @lpOpsS1Title.
  ///
  /// In en, this message translates to:
  /// **'Field Executive — Stage 1'**
  String get lpOpsS1Title;

  /// No description provided for @lpOpsSlipDone.
  ///
  /// In en, this message translates to:
  /// **'Slip Done'**
  String get lpOpsSlipDone;

  /// No description provided for @lpOpsSyncFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'RR sync failed: {error}'**
  String lpOpsSyncFailedMsg(String error);

  /// No description provided for @lpOpsSyncedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} synced'**
  String lpOpsSyncedCount(int count);

  /// No description provided for @lpOpsTripCreated.
  ///
  /// In en, this message translates to:
  /// **'Trip Created'**
  String get lpOpsTripCreated;

  /// No description provided for @lpOpsTripNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Trip number copied'**
  String get lpOpsTripNumberCopied;

  /// No description provided for @lpOpsTripSynced.
  ///
  /// In en, this message translates to:
  /// **'Trip Synced to RR Web'**
  String get lpOpsTripSynced;

  /// No description provided for @lpOpsWebTrips.
  ///
  /// In en, this message translates to:
  /// **'RR Web Trips'**
  String get lpOpsWebTrips;

  /// No description provided for @lpWorkersDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get lpWorkersDaily;

  /// No description provided for @lpWorkersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Active employees in your organisation will appear here.'**
  String get lpWorkersEmptyHint;

  /// No description provided for @lpWorkersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get lpWorkersEmptyTitle;

  /// No description provided for @lpWorkersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get lpWorkersLoadFailed;

  /// No description provided for @lpWorkersMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get lpWorkersMonthly;

  /// No description provided for @lpWorkersNoActivityHint.
  ///
  /// In en, this message translates to:
  /// **'No stage submissions recorded for this period.'**
  String get lpWorkersNoActivityHint;

  /// No description provided for @lpWorkersNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get lpWorkersNoActivityTitle;

  /// No description provided for @lpWorkersPoints.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String lpWorkersPoints(int count);

  /// No description provided for @lpWorkersPtsShort.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get lpWorkersPtsShort;

  /// No description provided for @lpWorkersRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the organization? They will lose access immediately and can request to rejoin later.'**
  String lpWorkersRemoveConfirm(String name);

  /// No description provided for @lpWorkersRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove: {error}'**
  String lpWorkersRemoveFailed(String error);

  /// No description provided for @lpWorkersRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove From Organization'**
  String get lpWorkersRemoveTitle;

  /// No description provided for @lpWorkersRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from the organization'**
  String lpWorkersRemoved(String name);

  /// No description provided for @lpWorkersTabLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get lpWorkersTabLeaderboard;

  /// No description provided for @lpWorkersTabRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get lpWorkersTabRecord;

  /// No description provided for @lpWorkersTitle.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get lpWorkersTitle;

  /// No description provided for @lpWorkersTripsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} trip} other{{count} trips}}'**
  String lpWorkersTripsCount(int count);

  /// No description provided for @rrQuickAddActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get rrQuickAddActionFailed;

  /// No description provided for @rrQuickAddAddCompanyButton.
  ///
  /// In en, this message translates to:
  /// **'Add Company'**
  String get rrQuickAddAddCompanyButton;

  /// No description provided for @rrQuickAddAddDriverButton.
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get rrQuickAddAddDriverButton;

  /// No description provided for @rrQuickAddAddVehicleButton.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get rrQuickAddAddVehicleButton;

  /// No description provided for @rrQuickAddApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get rrQuickAddApprove;

  /// No description provided for @rrQuickAddApprovedEndDate.
  ///
  /// In en, this message translates to:
  /// **'Approved End Date'**
  String get rrQuickAddApprovedEndDate;

  /// No description provided for @rrQuickAddApprovedRange.
  ///
  /// In en, this message translates to:
  /// **'Approved: {start} to {end}'**
  String rrQuickAddApprovedRange(String start, String end);

  /// No description provided for @rrQuickAddApprovedStartDate.
  ///
  /// In en, this message translates to:
  /// **'Approved Start Date'**
  String get rrQuickAddApprovedStartDate;

  /// No description provided for @rrQuickAddBizCommissionAgent.
  ///
  /// In en, this message translates to:
  /// **'Commission Agent'**
  String get rrQuickAddBizCommissionAgent;

  /// No description provided for @rrQuickAddBizDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get rrQuickAddBizDriver;

  /// No description provided for @rrQuickAddBizOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get rrQuickAddBizOther;

  /// No description provided for @rrQuickAddBizParcelReceiver.
  ///
  /// In en, this message translates to:
  /// **'Parcel Receiver - Consignee'**
  String get rrQuickAddBizParcelReceiver;

  /// No description provided for @rrQuickAddBizParcelReceiverAgent.
  ///
  /// In en, this message translates to:
  /// **'Parcel Receiver Agent - Consignee Commission Agent'**
  String get rrQuickAddBizParcelReceiverAgent;

  /// No description provided for @rrQuickAddBizParcelSender.
  ///
  /// In en, this message translates to:
  /// **'Parcel Sender - Consignor'**
  String get rrQuickAddBizParcelSender;

  /// No description provided for @rrQuickAddBizParcelSenderAgent.
  ///
  /// In en, this message translates to:
  /// **'Parcel Sender Agent - Consignor Commission Agent'**
  String get rrQuickAddBizParcelSenderAgent;

  /// No description provided for @rrQuickAddBizTransporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get rrQuickAddBizTransporter;

  /// No description provided for @rrQuickAddBizVehicleAgent.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Agent'**
  String get rrQuickAddBizVehicleAgent;

  /// No description provided for @rrQuickAddBizVehicleOwner.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Owner'**
  String get rrQuickAddBizVehicleOwner;

  /// No description provided for @rrQuickAddBusinessTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Type *'**
  String get rrQuickAddBusinessTypeLabel;

  /// No description provided for @rrQuickAddCheckHistory.
  ///
  /// In en, this message translates to:
  /// **'Check Vehicle History'**
  String get rrQuickAddCheckHistory;

  /// No description provided for @rrQuickAddCompanyAdded.
  ///
  /// In en, this message translates to:
  /// **'Company \"{name}\" added on RR'**
  String rrQuickAddCompanyAdded(String name);

  /// No description provided for @rrQuickAddCompanyFirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Company / Firm Name'**
  String get rrQuickAddCompanyFirmLabel;

  /// No description provided for @rrQuickAddCompanyIntro.
  ///
  /// In en, this message translates to:
  /// **'Register a new vehicle-provider company on RR'**
  String get rrQuickAddCompanyIntro;

  /// No description provided for @rrQuickAddCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get rrQuickAddCompanyNameRequired;

  /// No description provided for @rrQuickAddCompanyOptional.
  ///
  /// In en, this message translates to:
  /// **'Company (optional)'**
  String get rrQuickAddCompanyOptional;

  /// No description provided for @rrQuickAddCompanyOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Owner (search or enter a new 10-digit phone) *'**
  String get rrQuickAddCompanyOwnerLabel;

  /// No description provided for @rrQuickAddCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Company'**
  String get rrQuickAddCompanyTitle;

  /// No description provided for @rrQuickAddContractorLine.
  ///
  /// In en, this message translates to:
  /// **'Contractor: {value}'**
  String rrQuickAddContractorLine(String value);

  /// No description provided for @rrQuickAddDateRangeTo.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String rrQuickAddDateRangeTo(String start, String end);

  /// No description provided for @rrQuickAddDriverAdded.
  ///
  /// In en, this message translates to:
  /// **'Driver \"{name}\" added on RR'**
  String rrQuickAddDriverAdded(String name);

  /// No description provided for @rrQuickAddDriverIntro.
  ///
  /// In en, this message translates to:
  /// **'Register a new driver on RR'**
  String get rrQuickAddDriverIntro;

  /// No description provided for @rrQuickAddDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Driver'**
  String get rrQuickAddDriverTitle;

  /// No description provided for @rrQuickAddEndLine.
  ///
  /// In en, this message translates to:
  /// **'End: {date}'**
  String rrQuickAddEndLine(String date);

  /// No description provided for @rrQuickAddEngineModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Engine Model *'**
  String get rrQuickAddEngineModelLabel;

  /// No description provided for @rrQuickAddFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get rrQuickAddFind;

  /// No description provided for @rrQuickAddFromLine.
  ///
  /// In en, this message translates to:
  /// **'From: {date}'**
  String rrQuickAddFromLine(String date);

  /// No description provided for @rrQuickAddHireApproved.
  ///
  /// In en, this message translates to:
  /// **'Hire request approved'**
  String get rrQuickAddHireApproved;

  /// No description provided for @rrQuickAddHireEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending hire requests'**
  String get rrQuickAddHireEmpty;

  /// No description provided for @rrQuickAddHireLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load hire requests'**
  String get rrQuickAddHireLoadFailed;

  /// No description provided for @rrQuickAddHirePerson.
  ///
  /// In en, this message translates to:
  /// **'Hire Person'**
  String get rrQuickAddHirePerson;

  /// No description provided for @rrQuickAddHirePersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Hire Person *'**
  String get rrQuickAddHirePersonLabel;

  /// No description provided for @rrQuickAddHireRejected.
  ///
  /// In en, this message translates to:
  /// **'Hire request rejected'**
  String get rrQuickAddHireRejected;

  /// No description provided for @rrQuickAddHireSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send hire request. Please try again.'**
  String get rrQuickAddHireSendFailed;

  /// No description provided for @rrQuickAddHireSent.
  ///
  /// In en, this message translates to:
  /// **'Hiring request sent successfully'**
  String get rrQuickAddHireSent;

  /// No description provided for @rrQuickAddHireTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Hire Requests'**
  String get rrQuickAddHireTitle;

  /// No description provided for @rrQuickAddHiringDateFrom.
  ///
  /// In en, this message translates to:
  /// **'Hiring Request Date — From'**
  String get rrQuickAddHiringDateFrom;

  /// No description provided for @rrQuickAddHiringDateTo.
  ///
  /// In en, this message translates to:
  /// **'Hiring Request Date — To'**
  String get rrQuickAddHiringDateTo;

  /// No description provided for @rrQuickAddHiringRequestDate.
  ///
  /// In en, this message translates to:
  /// **'Hiring Request Date'**
  String get rrQuickAddHiringRequestDate;

  /// No description provided for @rrQuickAddHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history. Please try again.'**
  String get rrQuickAddHistoryFailed;

  /// No description provided for @rrQuickAddHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Reference only — look up a vehicle\'s past hires'**
  String get rrQuickAddHistoryHint;

  /// No description provided for @rrQuickAddHistorySelectFirst.
  ///
  /// In en, this message translates to:
  /// **'Search and select a vehicle first'**
  String get rrQuickAddHistorySelectFirst;

  /// No description provided for @rrQuickAddLenderDetail.
  ///
  /// In en, this message translates to:
  /// **'Lender Detail'**
  String get rrQuickAddLenderDetail;

  /// No description provided for @rrQuickAddLenderVehicles.
  ///
  /// In en, this message translates to:
  /// **'Lender Vehicles *'**
  String get rrQuickAddLenderVehicles;

  /// No description provided for @rrQuickAddMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Market Vehicle'**
  String get rrQuickAddMarketTitle;

  /// No description provided for @rrQuickAddNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get rrQuickAddNameLabel;

  /// No description provided for @rrQuickAddNameMin.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get rrQuickAddNameMin;

  /// No description provided for @rrQuickAddNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No hire history found for {vehicle}'**
  String rrQuickAddNoHistory(String vehicle);

  /// No description provided for @rrQuickAddNoOwnerVehicles.
  ///
  /// In en, this message translates to:
  /// **'This owner has no vehicles on RR'**
  String get rrQuickAddNoOwnerVehicles;

  /// No description provided for @rrQuickAddNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get rrQuickAddNotSet;

  /// No description provided for @rrQuickAddOrByPhone.
  ///
  /// In en, this message translates to:
  /// **'— or by phone number —'**
  String get rrQuickAddOrByPhone;

  /// No description provided for @rrQuickAddOwnerLine.
  ///
  /// In en, this message translates to:
  /// **'Owner: {value}'**
  String rrQuickAddOwnerLine(String value);

  /// No description provided for @rrQuickAddOwnerOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Select an existing owner or enter a valid 10-digit phone number'**
  String get rrQuickAddOwnerOrPhone;

  /// No description provided for @rrQuickAddOwnerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Phone Number *'**
  String get rrQuickAddOwnerPhoneLabel;

  /// No description provided for @rrQuickAddPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get rrQuickAddPhoneLabel;

  /// No description provided for @rrQuickAddPhoneSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Full 10-digit phone, or part of the name'**
  String get rrQuickAddPhoneSearchHint;

  /// No description provided for @rrQuickAddRcHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. RJ14'**
  String get rrQuickAddRcHint;

  /// No description provided for @rrQuickAddRcNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'RC Number *'**
  String get rrQuickAddRcNumberLabel;

  /// No description provided for @rrQuickAddRcRequired.
  ///
  /// In en, this message translates to:
  /// **'RC number is required'**
  String get rrQuickAddRcRequired;

  /// No description provided for @rrQuickAddReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rrQuickAddReject;

  /// No description provided for @rrQuickAddRequestInfo.
  ///
  /// In en, this message translates to:
  /// **'Request Information'**
  String get rrQuickAddRequestInfo;

  /// No description provided for @rrQuickAddRequestTimePeriod.
  ///
  /// In en, this message translates to:
  /// **'Request Time Period'**
  String get rrQuickAddRequestTimePeriod;

  /// No description provided for @rrQuickAddRequestedByLine.
  ///
  /// In en, this message translates to:
  /// **'Requested by: {value}'**
  String rrQuickAddRequestedByLine(String value);

  /// No description provided for @rrQuickAddRequestedRangeArrow.
  ///
  /// In en, this message translates to:
  /// **'Requested: {start} → {end}'**
  String rrQuickAddRequestedRangeArrow(String start, String end);

  /// No description provided for @rrQuickAddRequestedRangeTo.
  ///
  /// In en, this message translates to:
  /// **'Requested: {start} to {end}'**
  String rrQuickAddRequestedRangeTo(String start, String end);

  /// No description provided for @rrQuickAddReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Hire Request'**
  String get rrQuickAddReviewTitle;

  /// No description provided for @rrQuickAddSamePerson.
  ///
  /// In en, this message translates to:
  /// **'The hiring person and lender must be different. You cannot hire your own vehicle.'**
  String get rrQuickAddSamePerson;

  /// No description provided for @rrQuickAddSearchByCompany.
  ///
  /// In en, this message translates to:
  /// **'Search by company/firm'**
  String get rrQuickAddSearchByCompany;

  /// No description provided for @rrQuickAddSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select a city from the suggestions'**
  String get rrQuickAddSelectCity;

  /// No description provided for @rrQuickAddSelectEngineModel.
  ///
  /// In en, this message translates to:
  /// **'Select an engine model from the suggestions'**
  String get rrQuickAddSelectEngineModel;

  /// No description provided for @rrQuickAddSelectFleetVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select a vehicle from the owner\'s fleet'**
  String get rrQuickAddSelectFleetVehicle;

  /// No description provided for @rrQuickAddSelectHirePerson.
  ///
  /// In en, this message translates to:
  /// **'Search and select the Vehicle Hire Person'**
  String get rrQuickAddSelectHirePerson;

  /// No description provided for @rrQuickAddSelectOwner.
  ///
  /// In en, this message translates to:
  /// **'Select an owner from the suggestions'**
  String get rrQuickAddSelectOwner;

  /// No description provided for @rrQuickAddSelectVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get rrQuickAddSelectVehicleHint;

  /// No description provided for @rrQuickAddSelectVehicleOwner.
  ///
  /// In en, this message translates to:
  /// **'Search and select the Vehicle Owner'**
  String get rrQuickAddSelectVehicleOwner;

  /// No description provided for @rrQuickAddStartLine.
  ///
  /// In en, this message translates to:
  /// **'Start: {date}'**
  String rrQuickAddStartLine(String date);

  /// No description provided for @rrQuickAddStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get rrQuickAddStatusApproved;

  /// No description provided for @rrQuickAddStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rrQuickAddStatusRejected;

  /// No description provided for @rrQuickAddStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get rrQuickAddStatusRequested;

  /// No description provided for @rrQuickAddStatusTerminated.
  ///
  /// In en, this message translates to:
  /// **'Terminated'**
  String get rrQuickAddStatusTerminated;

  /// No description provided for @rrQuickAddTerminatedLine.
  ///
  /// In en, this message translates to:
  /// **'Terminated: {date}'**
  String rrQuickAddTerminatedLine(String date);

  /// No description provided for @rrQuickAddToLine.
  ///
  /// In en, this message translates to:
  /// **'To: {date}'**
  String rrQuickAddToLine(String date);

  /// No description provided for @rrQuickAddUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get rrQuickAddUnknown;

  /// No description provided for @rrQuickAddVehicleAdded.
  ///
  /// In en, this message translates to:
  /// **'Vehicle \"{rc}\" added on RR'**
  String rrQuickAddVehicleAdded(String rc);

  /// No description provided for @rrQuickAddVehicleDetail.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Detail'**
  String get rrQuickAddVehicleDetail;

  /// No description provided for @rrQuickAddVehicleIntro.
  ///
  /// In en, this message translates to:
  /// **'Register a new vehicle on RR'**
  String get rrQuickAddVehicleIntro;

  /// No description provided for @rrQuickAddVehicleLine.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {value}'**
  String rrQuickAddVehicleLine(String value);

  /// No description provided for @rrQuickAddVehicleOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Owner *'**
  String get rrQuickAddVehicleOwnerLabel;

  /// No description provided for @rrQuickAddVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Vehicle'**
  String get rrQuickAddVehicleTitle;

  /// No description provided for @rrQuickAddYourFleet.
  ///
  /// In en, this message translates to:
  /// **'Your fleet'**
  String get rrQuickAddYourFleet;

  /// No description provided for @loadsBrowserCompany.
  ///
  /// In en, this message translates to:
  /// **'Company: {name}'**
  String loadsBrowserCompany(String name);

  /// No description provided for @loadsBrowserCopiedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Load requirement copied to clipboard} other{{count} load requirements copied to clipboard}}'**
  String loadsBrowserCopiedCount(int count);

  /// No description provided for @loadsBrowserCopyDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy Details'**
  String get loadsBrowserCopyDetails;

  /// No description provided for @loadsBrowserCopySelected.
  ///
  /// In en, this message translates to:
  /// **'Copy Selected ({count})'**
  String loadsBrowserCopySelected(int count);

  /// No description provided for @loadsBrowserDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Load details copied to clipboard'**
  String get loadsBrowserDetailsCopied;

  /// No description provided for @loadsBrowserDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drop city…'**
  String get loadsBrowserDropHint;

  /// No description provided for @loadsBrowserEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending load requirements'**
  String get loadsBrowserEmpty;

  /// No description provided for @loadsBrowserLogisticPartner.
  ///
  /// In en, this message translates to:
  /// **'Logistic Partner: {name}'**
  String loadsBrowserLogisticPartner(String name);

  /// No description provided for @loadsBrowserMaterialWeight.
  ///
  /// In en, this message translates to:
  /// **'Material: {weight}'**
  String loadsBrowserMaterialWeight(String weight);

  /// No description provided for @loadsBrowserPickupHint.
  ///
  /// In en, this message translates to:
  /// **'Pickup city…'**
  String get loadsBrowserPickupHint;

  /// No description provided for @loadsBrowserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse pending requirements from load owners'**
  String get loadsBrowserSubtitle;

  /// No description provided for @loadsBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Loads'**
  String get loadsBrowserTitle;

  /// No description provided for @loadsBrowserTruckUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{truck} other{trucks}}'**
  String loadsBrowserTruckUnit(int count);

  /// No description provided for @loadsBrowserTruckWeight.
  ///
  /// In en, this message translates to:
  /// **'Truck: {weight}'**
  String loadsBrowserTruckWeight(String weight);

  /// No description provided for @loadsBrowserTrucksNeeded.
  ///
  /// In en, this message translates to:
  /// **'Trucks Needed:'**
  String get loadsBrowserTrucksNeeded;

  /// No description provided for @loadsBrowserWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get loadsBrowserWhatsApp;

  /// No description provided for @loadsBrowserWhatsAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get loadsBrowserWhatsAppFailed;

  /// No description provided for @tripDetailCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get tripDetailCreated;

  /// No description provided for @tripDetailEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get tripDetailEndDate;

  /// No description provided for @tripDetailFetchingGps.
  ///
  /// In en, this message translates to:
  /// **'Fetching GPS location…'**
  String get tripDetailFetchingGps;

  /// No description provided for @tripDetailGoToStage.
  ///
  /// In en, this message translates to:
  /// **'GO TO PRESENT STAGE'**
  String get tripDetailGoToStage;

  /// No description provided for @tripDetailInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get tripDetailInvoiceNumber;

  /// No description provided for @tripDetailLoadItem.
  ///
  /// In en, this message translates to:
  /// **'Load Item'**
  String get tripDetailLoadItem;

  /// No description provided for @tripDetailRoute.
  ///
  /// In en, this message translates to:
  /// **'ROUTE'**
  String get tripDetailRoute;

  /// No description provided for @tripDetailSectionCargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo Details'**
  String get tripDetailSectionCargo;

  /// No description provided for @tripDetailSectionFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial Details'**
  String get tripDetailSectionFinancial;

  /// No description provided for @tripDetailSectionIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Identifiers'**
  String get tripDetailSectionIdentifiers;

  /// No description provided for @tripDetailSectionLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get tripDetailSectionLogistics;

  /// No description provided for @tripDetailStageLine.
  ///
  /// In en, this message translates to:
  /// **'Stage {number}: {name}'**
  String tripDetailStageLine(int number, String name);

  /// No description provided for @tripDetailStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get tripDetailStartDate;

  /// No description provided for @tripDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get tripDetailTitle;

  /// No description provided for @tripDetailTripAmount.
  ///
  /// In en, this message translates to:
  /// **'Trip Amount'**
  String get tripDetailTripAmount;

  /// No description provided for @tripDetailTripNumber.
  ///
  /// In en, this message translates to:
  /// **'Trip Number'**
  String get tripDetailTripNumber;

  /// No description provided for @tripDetailViewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View vehicle on live map'**
  String get tripDetailViewOnMap;

  /// No description provided for @tripLocateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String tripLocateDaysAgo(int days);

  /// No description provided for @tripLocateGapLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location off · {time}'**
  String tripLocateGapLocationOff(String time);

  /// No description provided for @tripLocateGapNearDetail.
  ///
  /// In en, this message translates to:
  /// **'The vehicle stayed in the same area.'**
  String get tripLocateGapNearDetail;

  /// No description provided for @tripLocateGapNoTracking.
  ///
  /// In en, this message translates to:
  /// **'No tracking for this trip · {time}'**
  String tripLocateGapNoTracking(String time);

  /// No description provided for @tripLocateGapOkDetail.
  ///
  /// In en, this message translates to:
  /// **'About {km} km by road. Approximate route, minimum distance.'**
  String tripLocateGapOkDetail(String km);

  /// No description provided for @tripLocateGapOkDetailMode.
  ///
  /// In en, this message translates to:
  /// **'About {km} km by road. Approximate route, minimum distance ({mode}).'**
  String tripLocateGapOkDetailMode(String km, String mode);

  /// No description provided for @tripLocateGapReleasedDetail.
  ///
  /// In en, this message translates to:
  /// **'Tracking was paused for this trip or the driver changed. No route is drawn.'**
  String get tripLocateGapReleasedDetail;

  /// No description provided for @tripLocateGapSemanticsOff.
  ///
  /// In en, this message translates to:
  /// **'Location off for {label}. Tap for details.'**
  String tripLocateGapSemanticsOff(String label);

  /// No description provided for @tripLocateGapSemanticsReleased.
  ///
  /// In en, this message translates to:
  /// **'No tracking for this trip for {label}. Tap for details.'**
  String tripLocateGapSemanticsReleased(String label);

  /// No description provided for @tripLocateGapSuspiciousDetail.
  ///
  /// In en, this message translates to:
  /// **'The vehicle moved {km} km in a straight line, which is too far for this time. No route is drawn.'**
  String tripLocateGapSuspiciousDetail(String km);

  /// No description provided for @tripLocateGapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route not available yet.'**
  String get tripLocateGapUnavailable;

  /// No description provided for @tripLocateGpsActive.
  ///
  /// In en, this message translates to:
  /// **'GPS Active'**
  String get tripLocateGpsActive;

  /// No description provided for @tripLocateHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String tripLocateHoursAgo(int hours);

  /// No description provided for @tripLocateHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String tripLocateHoursMinutes(int hours, int minutes);

  /// No description provided for @tripLocateJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get tripLocateJustNow;

  /// No description provided for @tripLocateLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {ago} ({time})'**
  String tripLocateLastUpdated(String ago, String time);

  /// No description provided for @tripLocateLegendLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location off'**
  String get tripLocateLegendLocationOff;

  /// No description provided for @tripLocateLegendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Map key. Orange line: tracked route. Grey dotted line: location was off.'**
  String get tripLocateLegendSemantics;

  /// No description provided for @tripLocateLegendTracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked'**
  String get tripLocateLegendTracked;

  /// No description provided for @tripLocateLoadingTrail.
  ///
  /// In en, this message translates to:
  /// **'Loading trail…'**
  String get tripLocateLoadingTrail;

  /// No description provided for @tripLocateLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating {tripNumber}'**
  String tripLocateLocating(String tripNumber);

  /// No description provided for @tripLocateMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String tripLocateMinutes(int minutes);

  /// No description provided for @tripLocateMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String tripLocateMinutesAgo(int minutes);

  /// No description provided for @tripLocateModeCar.
  ///
  /// In en, this message translates to:
  /// **'car route'**
  String get tripLocateModeCar;

  /// No description provided for @tripLocateModeHeavyTruck.
  ///
  /// In en, this message translates to:
  /// **'heavy truck route'**
  String get tripLocateModeHeavyTruck;

  /// No description provided for @tripLocateModeLightTruck.
  ///
  /// In en, this message translates to:
  /// **'light truck route'**
  String get tripLocateModeLightTruck;

  /// No description provided for @tripLocateModeMediumTruck.
  ///
  /// In en, this message translates to:
  /// **'medium truck route'**
  String get tripLocateModeMediumTruck;

  /// No description provided for @tripLocateModeTruck.
  ///
  /// In en, this message translates to:
  /// **'truck route'**
  String get tripLocateModeTruck;

  /// No description provided for @tripLocateNoGpsMessage.
  ///
  /// In en, this message translates to:
  /// **'The driver app has not shared a location yet for this trip.'**
  String get tripLocateNoGpsMessage;

  /// No description provided for @tripLocateNoGpsTitle.
  ///
  /// In en, this message translates to:
  /// **'No GPS Location Available'**
  String get tripLocateNoGpsTitle;

  /// No description provided for @tripLocateNoSignal.
  ///
  /// In en, this message translates to:
  /// **'No Signal'**
  String get tripLocateNoSignal;

  /// No description provided for @tripLocateOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get tripLocateOpenMaps;

  /// No description provided for @tripLocateStale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get tripLocateStale;

  /// No description provided for @tripLocateTimeMismatch.
  ///
  /// In en, this message translates to:
  /// **'time mismatch'**
  String get tripLocateTimeMismatch;

  /// No description provided for @tripLocateTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tripLocateTryAgain;

  /// No description provided for @tripLocateVehicleFallback.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE'**
  String get tripLocateVehicleFallback;

  /// No description provided for @workerReqAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get workerReqAccept;

  /// No description provided for @workerReqAccepted.
  ///
  /// In en, this message translates to:
  /// **'Worker accepted!'**
  String get workerReqAccepted;

  /// No description provided for @workerReqAssignRole.
  ///
  /// In en, this message translates to:
  /// **'Assign Role'**
  String get workerReqAssignRole;

  /// No description provided for @workerReqCurrentRole.
  ///
  /// In en, this message translates to:
  /// **'Currently: {role}'**
  String workerReqCurrentRole(String role);

  /// No description provided for @workerReqJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String workerReqJoined(String date);

  /// No description provided for @workerReqJoinedBy.
  ///
  /// In en, this message translates to:
  /// **'Joined {date} by {name}'**
  String workerReqJoinedBy(String date, String name);

  /// No description provided for @workerReqLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load requests'**
  String get workerReqLoadFailed;

  /// No description provided for @workerReqNoAccepted.
  ///
  /// In en, this message translates to:
  /// **'No accepted employees yet'**
  String get workerReqNoAccepted;

  /// No description provided for @workerReqNoAcceptedHint.
  ///
  /// In en, this message translates to:
  /// **'Accepted employees will appear here.'**
  String get workerReqNoAcceptedHint;

  /// No description provided for @workerReqNoPending.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get workerReqNoPending;

  /// No description provided for @workerReqNoPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Worker requests will appear here.'**
  String get workerReqNoPendingHint;

  /// No description provided for @workerReqNoRolePicked.
  ///
  /// In en, this message translates to:
  /// **'This worker didn\'t pick a role at signup — choose one below.'**
  String get workerReqNoRolePicked;

  /// No description provided for @workerReqNoRoleRequested.
  ///
  /// In en, this message translates to:
  /// **'No role requested yet'**
  String get workerReqNoRoleRequested;

  /// No description provided for @workerReqReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get workerReqReject;

  /// No description provided for @workerReqRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this worker request?'**
  String get workerReqRejectConfirm;

  /// No description provided for @workerReqRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get workerReqRejectTitle;

  /// No description provided for @workerReqRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected.'**
  String get workerReqRejected;

  /// No description provided for @workerReqRequestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested: {date}'**
  String workerReqRequestedOn(String date);

  /// No description provided for @workerReqRoleFeDesc.
  ///
  /// In en, this message translates to:
  /// **'Manages trip stages and fleet status on the ground'**
  String get workerReqRoleFeDesc;

  /// No description provided for @workerReqRoleLoadOwnerWorker.
  ///
  /// In en, this message translates to:
  /// **'Load Owner Worker'**
  String get workerReqRoleLoadOwnerWorker;

  /// No description provided for @workerReqRoleLoadOwnerWorkerDesc.
  ///
  /// In en, this message translates to:
  /// **'Manages load postings and shipment tracking'**
  String get workerReqRoleLoadOwnerWorkerDesc;

  /// No description provided for @workerReqRoleNotSet.
  ///
  /// In en, this message translates to:
  /// **'Role not set — tap to assign'**
  String get workerReqRoleNotSet;

  /// No description provided for @workerReqRoleRrOpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Handles RR sync and trip data entry in the RR system'**
  String get workerReqRoleRrOpsDesc;

  /// No description provided for @workerReqTabAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get workerReqTabAccepted;

  /// No description provided for @workerReqTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get workerReqTabPending;

  /// No description provided for @workerReqTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Requests'**
  String get workerReqTitle;

  /// No description provided for @workerReqUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get workerReqUnknown;

  /// No description provided for @loadSpecAxleFullTrailer.
  ///
  /// In en, this message translates to:
  /// **'Full Trailer'**
  String get loadSpecAxleFullTrailer;

  /// No description provided for @loadSpecAxleMulti.
  ///
  /// In en, this message translates to:
  /// **'Multi-Axle'**
  String get loadSpecAxleMulti;

  /// No description provided for @loadSpecAxleSemiTrailer.
  ///
  /// In en, this message translates to:
  /// **'Semi-Trailer'**
  String get loadSpecAxleSemiTrailer;

  /// No description provided for @loadSpecAxleSingle.
  ///
  /// In en, this message translates to:
  /// **'Single Axle'**
  String get loadSpecAxleSingle;

  /// No description provided for @loadSpecAxleTandem.
  ///
  /// In en, this message translates to:
  /// **'Tandem Axle'**
  String get loadSpecAxleTandem;

  /// No description provided for @loadSpecAxleTri.
  ///
  /// In en, this message translates to:
  /// **'Tri-Axle'**
  String get loadSpecAxleTri;

  /// No description provided for @loadSpecBodyCarCarrier.
  ///
  /// In en, this message translates to:
  /// **'Car Carrier'**
  String get loadSpecBodyCarCarrier;

  /// No description provided for @loadSpecBodyClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed Body'**
  String get loadSpecBodyClosed;

  /// No description provided for @loadSpecBodyContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get loadSpecBodyContainer;

  /// No description provided for @loadSpecBodyFlatbed.
  ///
  /// In en, this message translates to:
  /// **'Flatbed'**
  String get loadSpecBodyFlatbed;

  /// No description provided for @loadSpecBodyLowBed.
  ///
  /// In en, this message translates to:
  /// **'Low Bed'**
  String get loadSpecBodyLowBed;

  /// No description provided for @loadSpecBodyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Body'**
  String get loadSpecBodyOpen;

  /// No description provided for @loadSpecBodyRefrigerated.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated'**
  String get loadSpecBodyRefrigerated;

  /// No description provided for @loadSpecBodySideWall.
  ///
  /// In en, this message translates to:
  /// **'Side Wall'**
  String get loadSpecBodySideWall;

  /// No description provided for @loadSpecBodyTanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get loadSpecBodyTanker;

  /// No description provided for @loadSpecBodyTipper.
  ///
  /// In en, this message translates to:
  /// **'Tipper / Dumper'**
  String get loadSpecBodyTipper;

  /// No description provided for @loadSpecFloorAluminium.
  ///
  /// In en, this message translates to:
  /// **'Aluminium'**
  String get loadSpecFloorAluminium;

  /// No description provided for @loadSpecFloorBamboo.
  ///
  /// In en, this message translates to:
  /// **'Bamboo'**
  String get loadSpecFloorBamboo;

  /// No description provided for @loadSpecFloorCorrugated.
  ///
  /// In en, this message translates to:
  /// **'Corrugated'**
  String get loadSpecFloorCorrugated;

  /// No description provided for @loadSpecFloorPlain.
  ///
  /// In en, this message translates to:
  /// **'Plain Floor'**
  String get loadSpecFloorPlain;

  /// No description provided for @loadSpecFloorRubberMatted.
  ///
  /// In en, this message translates to:
  /// **'Rubber Matted'**
  String get loadSpecFloorRubberMatted;

  /// No description provided for @loadSpecFloorSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get loadSpecFloorSteel;

  /// No description provided for @loadSpecFloorWooden.
  ///
  /// In en, this message translates to:
  /// **'Wooden'**
  String get loadSpecFloorWooden;

  /// No description provided for @loadSpecMatAgri.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Produce'**
  String get loadSpecMatAgri;

  /// No description provided for @loadSpecMatAutoParts.
  ///
  /// In en, this message translates to:
  /// **'Automotive Parts'**
  String get loadSpecMatAutoParts;

  /// No description provided for @loadSpecMatChemicals.
  ///
  /// In en, this message translates to:
  /// **'Chemicals'**
  String get loadSpecMatChemicals;

  /// No description provided for @loadSpecMatConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction Materials'**
  String get loadSpecMatConstruction;

  /// No description provided for @loadSpecMatElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get loadSpecMatElectronics;

  /// No description provided for @loadSpecMatFmcg.
  ///
  /// In en, this message translates to:
  /// **'FMCG / Packaged Goods'**
  String get loadSpecMatFmcg;

  /// No description provided for @loadSpecMatFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get loadSpecMatFurniture;

  /// No description provided for @loadSpecMatGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass & Ceramics'**
  String get loadSpecMatGlass;

  /// No description provided for @loadSpecMatHazardous.
  ///
  /// In en, this message translates to:
  /// **'Hazardous Goods'**
  String get loadSpecMatHazardous;

  /// No description provided for @loadSpecMatIndustrial.
  ///
  /// In en, this message translates to:
  /// **'Industrial'**
  String get loadSpecMatIndustrial;

  /// No description provided for @loadSpecMatLiquids.
  ///
  /// In en, this message translates to:
  /// **'Liquids / Beverages'**
  String get loadSpecMatLiquids;

  /// No description provided for @loadSpecMatMachinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery & Equipment'**
  String get loadSpecMatMachinery;

  /// No description provided for @loadSpecMatOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get loadSpecMatOthers;

  /// No description provided for @loadSpecMatPaints.
  ///
  /// In en, this message translates to:
  /// **'Paints & Coatings'**
  String get loadSpecMatPaints;

  /// No description provided for @loadSpecMatPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper & Printing'**
  String get loadSpecMatPaper;

  /// No description provided for @loadSpecMatPerishables.
  ///
  /// In en, this message translates to:
  /// **'Perishables'**
  String get loadSpecMatPerishables;

  /// No description provided for @loadSpecMatPharma.
  ///
  /// In en, this message translates to:
  /// **'Pharmaceuticals'**
  String get loadSpecMatPharma;

  /// No description provided for @loadSpecMatPlastics.
  ///
  /// In en, this message translates to:
  /// **'Plastics & Rubber'**
  String get loadSpecMatPlastics;

  /// No description provided for @loadSpecMatSteelCoils.
  ///
  /// In en, this message translates to:
  /// **'Steel Coils'**
  String get loadSpecMatSteelCoils;

  /// No description provided for @loadSpecMatTextiles.
  ///
  /// In en, this message translates to:
  /// **'Textiles & Fabrics'**
  String get loadSpecMatTextiles;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'DASHBOARD'**
  String get loDashBottomDashboard;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'DOCS'**
  String get loDashBottomDocs;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'LOADS'**
  String get loDashBottomLoads;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'MY TRIPS'**
  String get loDashBottomMyTrips;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get loDashBottomProfile;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'SOON'**
  String get loDashBottomSoon;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get loDashClearAll;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all notifications.'**
  String get loDashClearAllBody;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get loDashClearAllTitle;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Create Load Requirement'**
  String get loDashCreateLoadButton;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'My Loads'**
  String get loDashNavMyLoads;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get loDashNoNotifications;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Load Owner Panel'**
  String get loDashPanelTitle;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Send your load details to your preferred logistic partner and get it moving.'**
  String get loDashPostLoadBody;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Post a Load Requirement'**
  String get loDashPostLoadTitle;

  /// No description provided for @loDashSoonSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label} (Soon)'**
  String loDashSoonSuffix(String label);

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get loDashTabDocuments;

  /// Load owner dashboard label
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get loDashTabTracking;

  /// Title of the page-not-found screen
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get appRouterErrorTitle;

  /// Page-not-found message
  ///
  /// In en, this message translates to:
  /// **'Page not found: {location}'**
  String appRouterPageNotFound(String location);

  /// Avatar menu item
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get mainNavCreateOrganization;

  /// Maintenance supervisor nav tab
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get mainNavInventory;

  /// Snackbar error
  ///
  /// In en, this message translates to:
  /// **'Error loading organizations: {error}'**
  String mainNavLoadOrganizationsError(String error);

  /// Snackbar while organizations load
  ///
  /// In en, this message translates to:
  /// **'Loading organizations...'**
  String get mainNavLoadingOrganizations;

  /// Logout dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get mainNavLogoutConfirm;

  /// Avatar menu item
  ///
  /// In en, this message translates to:
  /// **'Manage Organization'**
  String get mainNavManageOrganization;

  /// Avatar menu item
  ///
  /// In en, this message translates to:
  /// **'My Organizations'**
  String get mainNavMyOrganizations;

  /// Avatar menu item
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get mainNavMyProfile;

  /// Maintenance supervisor nav tab
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get mainNavMyTasks;

  /// Snackbar when user has no organization
  ///
  /// In en, this message translates to:
  /// **'No organization found. Please join or create one first.'**
  String get mainNavNoOrganization;

  /// Fallback title when the organization has no name
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get mainNavOrganizationFallback;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get mainNavReports;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get mainNavRoles;

  /// Maintenance supervisor nav tab
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get mainNavSchedule;

  /// Avatar menu item
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get mainNavSignOut;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get mainNavTasks;

  /// Name shown when the user has no name or username
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get mainNavUserFallback;

  /// No description provided for @loReceiverDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Receiver Dashboard'**
  String get loReceiverDashboardTitle;

  /// No description provided for @loReceiverEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your incoming deliveries will appear here.'**
  String get loReceiverEmpty;

  /// No description provided for @loReceiverRole.
  ///
  /// In en, this message translates to:
  /// **'Load Receiver'**
  String get loReceiverRole;

  /// No description provided for @loUploadBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get loUploadBody;

  /// No description provided for @loUploadBroadcastHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to broadcast to all'**
  String get loUploadBroadcastHint;

  /// No description provided for @loUploadDropHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Destination'**
  String get loUploadDropHint;

  /// No description provided for @loUploadDropLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop Location'**
  String get loUploadDropLocation;

  /// No description provided for @loUploadEntryDate.
  ///
  /// In en, this message translates to:
  /// **'Entry Date'**
  String get loUploadEntryDate;

  /// No description provided for @loUploadEntryMethod.
  ///
  /// In en, this message translates to:
  /// **'Entry Method'**
  String get loUploadEntryMethod;

  /// No description provided for @loUploadExpectedContact.
  ///
  /// In en, this message translates to:
  /// **'Expected Contact'**
  String get loUploadExpectedContact;

  /// No description provided for @loUploadExpectedContactBody.
  ///
  /// In en, this message translates to:
  /// **'Our logistics coordinator will reach out within 15 minutes for final verification.'**
  String get loUploadExpectedContactBody;

  /// No description provided for @loUploadExpectedContactHighlight.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get loUploadExpectedContactHighlight;

  /// No description provided for @loUploadFleetStatus.
  ///
  /// In en, this message translates to:
  /// **'Fleet Status'**
  String get loUploadFleetStatus;

  /// No description provided for @loUploadFleetStatusBody.
  ///
  /// In en, this message translates to:
  /// **'4 heavy-duty trailers are currently available in your pickup zone.'**
  String get loUploadFleetStatusBody;

  /// No description provided for @loUploadFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get loUploadFloor;

  /// No description provided for @loUploadMaterialType.
  ///
  /// In en, this message translates to:
  /// **'Material Type'**
  String get loUploadMaterialType;

  /// No description provided for @loUploadMaterialWeight.
  ///
  /// In en, this message translates to:
  /// **'Material Weight'**
  String get loUploadMaterialWeight;

  /// No description provided for @loUploadMethodBulk.
  ///
  /// In en, this message translates to:
  /// **'BULK'**
  String get loUploadMethodBulk;

  /// No description provided for @loUploadMethodManual.
  ///
  /// In en, this message translates to:
  /// **'MANUAL'**
  String get loUploadMethodManual;

  /// No description provided for @loUploadMethodPhoto.
  ///
  /// In en, this message translates to:
  /// **'PHOTO'**
  String get loUploadMethodPhoto;

  /// No description provided for @loUploadNavDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get loUploadNavDocs;

  /// No description provided for @loUploadNavTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get loUploadNavTracking;

  /// No description provided for @loUploadNewLoad.
  ///
  /// In en, this message translates to:
  /// **'New Load'**
  String get loUploadNewLoad;

  /// No description provided for @loUploadNewLoadRequirement.
  ///
  /// In en, this message translates to:
  /// **'New Load Requirement'**
  String get loUploadNewLoadRequirement;

  /// No description provided for @loUploadPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get loUploadPickDate;

  /// No description provided for @loUploadPickupHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Origin Hub'**
  String get loUploadPickupHint;

  /// No description provided for @loUploadProcessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Process Update'**
  String get loUploadProcessUpdate;

  /// No description provided for @loUploadProcessUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'Fleet optimization algorithms are calculating the most efficient route for your cargo.'**
  String get loUploadProcessUpdateBody;

  /// No description provided for @loUploadReferenceId.
  ///
  /// In en, this message translates to:
  /// **'Reference ID'**
  String get loUploadReferenceId;

  /// No description provided for @loUploadSearchPartnerHint.
  ///
  /// In en, this message translates to:
  /// **'Search Logistic Partner here'**
  String get loUploadSearchPartnerHint;

  /// No description provided for @loUploadSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get loUploadSelect;

  /// No description provided for @loUploadSelectMaterial.
  ///
  /// In en, this message translates to:
  /// **'Select material'**
  String get loUploadSelectMaterial;

  /// No description provided for @loUploadSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get loUploadSelected;

  /// No description provided for @loUploadSendTo.
  ///
  /// In en, this message translates to:
  /// **'Send To'**
  String get loUploadSendTo;

  /// No description provided for @loUploadSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'SOON'**
  String get loUploadSoonBadge;

  /// No description provided for @loUploadSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Load Requirement'**
  String get loUploadSubmitButton;

  /// No description provided for @loUploadSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed. Please try again.'**
  String get loUploadSubmitFailed;

  /// No description provided for @loUploadSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your load requirement for {count, plural, =1{1 unit} other{{count} units}} of {material} has been received. Our team is now assigning the fleet.'**
  String loUploadSuccessBody(int count, String material);

  /// No description provided for @loUploadSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Successful'**
  String get loUploadSuccessTitle;

  /// No description provided for @loUploadTargetPartners.
  ///
  /// In en, this message translates to:
  /// **'Target Partners'**
  String get loUploadTargetPartners;

  /// No description provided for @loUploadTrackInTrips.
  ///
  /// In en, this message translates to:
  /// **'Track in My Trips'**
  String get loUploadTrackInTrips;

  /// No description provided for @loUploadTruckCount.
  ///
  /// In en, this message translates to:
  /// **'Truck Count'**
  String get loUploadTruckCount;

  /// No description provided for @loUploadTruckRequirements.
  ///
  /// In en, this message translates to:
  /// **'Truck Requirements'**
  String get loUploadTruckRequirements;

  /// No description provided for @loUploadTruckWeightOptional.
  ///
  /// In en, this message translates to:
  /// **'Truck Weight (Optional)'**
  String get loUploadTruckWeightOptional;

  /// No description provided for @loUploadUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get loUploadUnits;

  /// No description provided for @loUploadValAxle.
  ///
  /// In en, this message translates to:
  /// **'Please select an axle type'**
  String get loUploadValAxle;

  /// No description provided for @loUploadValBody.
  ///
  /// In en, this message translates to:
  /// **'Please select a body type'**
  String get loUploadValBody;

  /// No description provided for @loUploadValDate.
  ///
  /// In en, this message translates to:
  /// **'Please select an entry date'**
  String get loUploadValDate;

  /// No description provided for @loUploadValDrop.
  ///
  /// In en, this message translates to:
  /// **'Please enter a drop location'**
  String get loUploadValDrop;

  /// No description provided for @loUploadValFloor.
  ///
  /// In en, this message translates to:
  /// **'Please select a floor type'**
  String get loUploadValFloor;

  /// No description provided for @loUploadValMaterial.
  ///
  /// In en, this message translates to:
  /// **'Please select a material type'**
  String get loUploadValMaterial;

  /// No description provided for @loUploadValMaterialWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter the material weight'**
  String get loUploadValMaterialWeight;

  /// No description provided for @loUploadValPartner.
  ///
  /// In en, this message translates to:
  /// **'Please select a logistic partner'**
  String get loUploadValPartner;

  /// No description provided for @loUploadValPickup.
  ///
  /// In en, this message translates to:
  /// **'Please enter a pickup location'**
  String get loUploadValPickup;

  /// No description provided for @loUploadValTruckCount.
  ///
  /// In en, this message translates to:
  /// **'Truck count can\'t be zero'**
  String get loUploadValTruckCount;

  /// No description provided for @loUploadValTruckWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid truck weight, or leave it blank'**
  String get loUploadValTruckWeight;

  /// No description provided for @loWorkerHomeBuilding.
  ///
  /// In en, this message translates to:
  /// **'Your load owner worker workspace is being built. Check back soon.'**
  String get loWorkerHomeBuilding;

  /// No description provided for @loWorkerHomeFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get loWorkerHomeFallbackName;

  /// No description provided for @loWorkerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Owner Worker Dashboard'**
  String get loWorkerHomeTitle;

  /// No description provided for @loWorkerHomeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String loWorkerHomeWelcome(String name);

  /// Body of the transporter coming-soon dashboard
  ///
  /// In en, this message translates to:
  /// **'This dashboard is currently under\ndevelopment and will be available soon.'**
  String get transporterComingSoonBody;

  /// Title of the transporter placeholder dashboard
  ///
  /// In en, this message translates to:
  /// **'Transporter Dashboard'**
  String get transporterDashboardTitle;

  /// No description provided for @drvAddAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding Driver...'**
  String get drvAddAdding;

  /// No description provided for @drvAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Driver to Fleet'**
  String get drvAddButton;

  /// No description provided for @drvAddCancelReturn.
  ///
  /// In en, this message translates to:
  /// **'Cancel and return'**
  String get drvAddCancelReturn;

  /// No description provided for @drvAddDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'License issue date and expiry date are required'**
  String get drvAddDatesRequired;

  /// No description provided for @drvAddEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get drvAddEmail;

  /// No description provided for @drvAddEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get drvAddEmailInvalid;

  /// No description provided for @drvAddExpiryAfterIssue.
  ///
  /// In en, this message translates to:
  /// **'License expiry date must be after issue date'**
  String get drvAddExpiryAfterIssue;

  /// No description provided for @drvAddExpiryFuture.
  ///
  /// In en, this message translates to:
  /// **'License expiry date must be in the future'**
  String get drvAddExpiryFuture;

  /// No description provided for @drvAddFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String drvAddFieldRequired(String field);

  /// No description provided for @drvAddFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get drvAddFirstName;

  /// No description provided for @drvAddFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors in the form'**
  String get drvAddFixErrors;

  /// No description provided for @drvAddHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. {value}'**
  String drvAddHintExample(String value);

  /// No description provided for @drvAddJoinDate.
  ///
  /// In en, this message translates to:
  /// **'Join Date'**
  String get drvAddJoinDate;

  /// No description provided for @drvAddJoinFuture.
  ///
  /// In en, this message translates to:
  /// **'Join date cannot be in the future'**
  String get drvAddJoinFuture;

  /// No description provided for @drvAddLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get drvAddLastName;

  /// No description provided for @drvAddLicenseClass.
  ///
  /// In en, this message translates to:
  /// **'License Class'**
  String get drvAddLicenseClass;

  /// No description provided for @drvAddLicenseFormat.
  ///
  /// In en, this message translates to:
  /// **'License must be 10-50 alphanumeric characters'**
  String get drvAddLicenseFormat;

  /// No description provided for @drvAddLicenseHmv.
  ///
  /// In en, this message translates to:
  /// **'HMV (Heavy Motor Vehicle)'**
  String get drvAddLicenseHmv;

  /// No description provided for @drvAddLicenseHpmv.
  ///
  /// In en, this message translates to:
  /// **'HPMV (Heavy Passenger Motor Vehicle)'**
  String get drvAddLicenseHpmv;

  /// No description provided for @drvAddLicenseLmv.
  ///
  /// In en, this message translates to:
  /// **'LMV (Light Motor Vehicle)'**
  String get drvAddLicenseLmv;

  /// No description provided for @drvAddLicenseMcwg.
  ///
  /// In en, this message translates to:
  /// **'MCWG (Motorcycle with Gear)'**
  String get drvAddLicenseMcwg;

  /// No description provided for @drvAddLicenseRequired.
  ///
  /// In en, this message translates to:
  /// **'License number is required'**
  String get drvAddLicenseRequired;

  /// No description provided for @drvAddLicenseScan.
  ///
  /// In en, this message translates to:
  /// **'License Document Scan'**
  String get drvAddLicenseScan;

  /// No description provided for @drvAddLicenseScanHint.
  ///
  /// In en, this message translates to:
  /// **'Upload clear scan or photo'**
  String get drvAddLicenseScanHint;

  /// No description provided for @drvAddPasswordDigit.
  ///
  /// In en, this message translates to:
  /// **'Must include a digit'**
  String get drvAddPasswordDigit;

  /// No description provided for @drvAddPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars, with uppercase & digit'**
  String get drvAddPasswordHint;

  /// No description provided for @drvAddPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get drvAddPasswordLength;

  /// No description provided for @drvAddPasswordLower.
  ///
  /// In en, this message translates to:
  /// **'Must include a lowercase letter'**
  String get drvAddPasswordLower;

  /// No description provided for @drvAddPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get drvAddPasswordRequired;

  /// No description provided for @drvAddPasswordUpper.
  ///
  /// In en, this message translates to:
  /// **'Must include an uppercase letter'**
  String get drvAddPasswordUpper;

  /// No description provided for @drvAddPhoneDigits.
  ///
  /// In en, this message translates to:
  /// **'Phone must be 10 digits'**
  String get drvAddPhoneDigits;

  /// No description provided for @drvAddPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get drvAddPhoneRequired;

  /// No description provided for @drvAddPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Driver added, but photo upload failed: {error}'**
  String drvAddPhotoFailed(String error);

  /// No description provided for @drvAddPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 5MB'**
  String get drvAddPhotoHint;

  /// No description provided for @drvAddPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected — tap to change'**
  String get drvAddPhotoSelected;

  /// No description provided for @drvAddProgress.
  ///
  /// In en, this message translates to:
  /// **'REGISTRATION PROGRESS'**
  String get drvAddProgress;

  /// No description provided for @drvAddRoleLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get drvAddRoleLogistics;

  /// No description provided for @drvAddRoleSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get drvAddRoleSupport;

  /// No description provided for @drvAddSectionLogin.
  ///
  /// In en, this message translates to:
  /// **'Login Credentials'**
  String get drvAddSectionLogin;

  /// No description provided for @drvAddSectionRole.
  ///
  /// In en, this message translates to:
  /// **'Assignment & Role'**
  String get drvAddSectionRole;

  /// No description provided for @drvAddSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get drvAddSelect;

  /// No description provided for @drvAddStep.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3'**
  String get drvAddStep;

  /// No description provided for @drvAddSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver added successfully!'**
  String get drvAddSuccess;

  /// No description provided for @drvAddSystemRole.
  ///
  /// In en, this message translates to:
  /// **'System Role'**
  String get drvAddSystemRole;

  /// No description provided for @drvAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Driver'**
  String get drvAddTitle;

  /// No description provided for @drvAddUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Photo'**
  String get drvAddUploadPhoto;

  /// No description provided for @drvAddUsernameFormat.
  ///
  /// In en, this message translates to:
  /// **'Username: 3-50 chars (letters, numbers, underscore)'**
  String get drvAddUsernameFormat;

  /// No description provided for @drvAddUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get drvAddUsernameRequired;

  /// No description provided for @drvMgmtAddFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first driver'**
  String get drvMgmtAddFirstHint;

  /// No description provided for @drvMgmtCurrentlyOnLeave.
  ///
  /// In en, this message translates to:
  /// **'Currently on leave'**
  String get drvMgmtCurrentlyOnLeave;

  /// No description provided for @drvMgmtMainDepot.
  ///
  /// In en, this message translates to:
  /// **'Main Depot'**
  String get drvMgmtMainDepot;

  /// No description provided for @drvMgmtNoDrivers.
  ///
  /// In en, this message translates to:
  /// **'No drivers yet'**
  String get drvMgmtNoDrivers;

  /// No description provided for @drvMgmtNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No drivers match your filter'**
  String get drvMgmtNoMatch;

  /// No description provided for @drvMgmtSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search drivers, employee ID...'**
  String get drvMgmtSearchHint;

  /// No description provided for @drvMgmtStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get drvMgmtStatusActive;

  /// No description provided for @drvMgmtStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get drvMgmtStatusAll;

  /// No description provided for @drvMgmtStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get drvMgmtStatusAvailable;

  /// No description provided for @drvMgmtStatusOnLeave.
  ///
  /// In en, this message translates to:
  /// **'On Leave'**
  String get drvMgmtStatusOnLeave;

  /// No description provided for @drvMgmtStatusTerminated.
  ///
  /// In en, this message translates to:
  /// **'Terminated'**
  String get drvMgmtStatusTerminated;

  /// No description provided for @drvMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drvMgmtTitle;

  /// No description provided for @drvMgmtTotalMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} total fleet members'**
  String drvMgmtTotalMembers(int count);

  /// No description provided for @helpCenterArticleAddVehicle.
  ///
  /// In en, this message translates to:
  /// **'How to add a new vehicle'**
  String get helpCenterArticleAddVehicle;

  /// No description provided for @helpCenterArticleAddVehicleDesc.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step guide to adding vehicles to your fleet'**
  String get helpCenterArticleAddVehicleDesc;

  /// No description provided for @helpCenterArticleDetailIntro.
  ///
  /// In en, this message translates to:
  /// **'This is a detailed article about: {title}'**
  String helpCenterArticleDetailIntro(String title);

  /// No description provided for @helpCenterArticleDriverPerms.
  ///
  /// In en, this message translates to:
  /// **'Managing driver permissions'**
  String get helpCenterArticleDriverPerms;

  /// No description provided for @helpCenterArticleDriverPermsDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn how to assign and manage driver roles and permissions'**
  String get helpCenterArticleDriverPermsDesc;

  /// No description provided for @helpCenterArticleMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Creating maintenance schedules'**
  String get helpCenterArticleMaintenance;

  /// No description provided for @helpCenterArticleMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep your fleet running smoothly with scheduled maintenance'**
  String get helpCenterArticleMaintenanceDesc;

  /// No description provided for @helpCenterArticlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Article content would go here with step-by-step instructions, screenshots, and helpful tips.'**
  String get helpCenterArticlePlaceholder;

  /// No description provided for @helpCenterArticleRealtimeTracking.
  ///
  /// In en, this message translates to:
  /// **'Setting up real-time tracking'**
  String get helpCenterArticleRealtimeTracking;

  /// No description provided for @helpCenterArticleRealtimeTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure GPS tracking for your fleet vehicles'**
  String get helpCenterArticleRealtimeTrackingDesc;

  /// No description provided for @helpCenterAvgResponse.
  ///
  /// In en, this message translates to:
  /// **'Average response time: 2 minutes'**
  String get helpCenterAvgResponse;

  /// No description provided for @helpCenterBrowseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Browse by Category'**
  String get helpCenterBrowseByCategory;

  /// No description provided for @helpCenterCatDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver Management'**
  String get helpCenterCatDriver;

  /// No description provided for @helpCenterCatDriverDesc.
  ///
  /// In en, this message translates to:
  /// **'Driver profiles, licenses, and assignments'**
  String get helpCenterCatDriverDesc;

  /// No description provided for @helpCenterCatFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial Management'**
  String get helpCenterCatFinancial;

  /// No description provided for @helpCenterCatFinancialDesc.
  ///
  /// In en, this message translates to:
  /// **'Expenses, invoices, and payments'**
  String get helpCenterCatFinancialDesc;

  /// No description provided for @helpCenterCatMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get helpCenterCatMaintenance;

  /// No description provided for @helpCenterCatMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedules, repairs, and inspections'**
  String get helpCenterCatMaintenanceDesc;

  /// No description provided for @helpCenterCatReports.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get helpCenterCatReports;

  /// No description provided for @helpCenterCatReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Generating and exporting reports'**
  String get helpCenterCatReportsDesc;

  /// No description provided for @helpCenterCatRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get helpCenterCatRoles;

  /// No description provided for @helpCenterCatRolesDesc.
  ///
  /// In en, this message translates to:
  /// **'User roles and access control'**
  String get helpCenterCatRolesDesc;

  /// No description provided for @helpCenterCatTracking.
  ///
  /// In en, this message translates to:
  /// **'Real-time Tracking'**
  String get helpCenterCatTracking;

  /// No description provided for @helpCenterCatTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking and location services'**
  String get helpCenterCatTrackingDesc;

  /// No description provided for @helpCenterCatTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip Management'**
  String get helpCenterCatTrip;

  /// No description provided for @helpCenterCatTripDesc.
  ///
  /// In en, this message translates to:
  /// **'Creating and monitoring trips'**
  String get helpCenterCatTripDesc;

  /// No description provided for @helpCenterCatVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Management'**
  String get helpCenterCatVehicle;

  /// No description provided for @helpCenterCatVehicleDesc.
  ///
  /// In en, this message translates to:
  /// **'Adding, editing, and managing vehicles'**
  String get helpCenterCatVehicleDesc;

  /// No description provided for @helpCenterChatWithTeam.
  ///
  /// In en, this message translates to:
  /// **'Chat with our support team'**
  String get helpCenterChatWithTeam;

  /// No description provided for @helpCenterContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get helpCenterContactSupport;

  /// No description provided for @helpCenterEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get helpCenterEmailSupport;

  /// No description provided for @helpCenterEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get helpCenterEmailUs;

  /// No description provided for @helpCenterGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get helpCenterGettingStarted;

  /// No description provided for @helpCenterGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting Started Guide'**
  String get helpCenterGuideTitle;

  /// No description provided for @helpCenterIssueDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get helpCenterIssueDescription;

  /// No description provided for @helpCenterIssueReported.
  ///
  /// In en, this message translates to:
  /// **'Issue reported successfully'**
  String get helpCenterIssueReported;

  /// No description provided for @helpCenterIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Title'**
  String get helpCenterIssueTitle;

  /// No description provided for @helpCenterLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get helpCenterLiveChat;

  /// No description provided for @helpCenterMarkedHelpful.
  ///
  /// In en, this message translates to:
  /// **'Article marked as helpful'**
  String get helpCenterMarkedHelpful;

  /// No description provided for @helpCenterNeedMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need More Help?'**
  String get helpCenterNeedMoreHelp;

  /// No description provided for @helpCenterNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String helpCenterNoResults(String query);

  /// No description provided for @helpCenterNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or browse categories below'**
  String get helpCenterNoResultsHint;

  /// No description provided for @helpCenterOpeningCategory.
  ///
  /// In en, this message translates to:
  /// **'Opening {category} articles...'**
  String helpCenterOpeningCategory(String category);

  /// No description provided for @helpCenterOpeningChat.
  ///
  /// In en, this message translates to:
  /// **'Opening live chat...'**
  String get helpCenterOpeningChat;

  /// No description provided for @helpCenterPhoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get helpCenterPhoneSupport;

  /// No description provided for @helpCenterPopularArticles.
  ///
  /// In en, this message translates to:
  /// **'Popular Articles'**
  String get helpCenterPopularArticles;

  /// No description provided for @helpCenterQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get helpCenterQuickActions;

  /// No description provided for @helpCenterReadMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min read'**
  String helpCenterReadMinutes(int minutes);

  /// No description provided for @helpCenterReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get helpCenterReportIssue;

  /// No description provided for @helpCenterReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get helpCenterReportTitle;

  /// No description provided for @helpCenterResultsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result found} other{{count} results found}}'**
  String helpCenterResultsFound(int count);

  /// No description provided for @helpCenterSearchDriverPermsDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn how to assign and manage driver roles'**
  String get helpCenterSearchDriverPermsDesc;

  /// No description provided for @helpCenterSearchGpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure real-time vehicle tracking'**
  String get helpCenterSearchGpsDesc;

  /// No description provided for @helpCenterSearchGpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Setting up GPS tracking'**
  String get helpCenterSearchGpsTitle;

  /// No description provided for @helpCenterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for help articles, guides, FAQs...'**
  String get helpCenterSearchHint;

  /// No description provided for @helpCenterSearchMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedule regular vehicle maintenance'**
  String get helpCenterSearchMaintenanceDesc;

  /// No description provided for @helpCenterSearchReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create and export financial reports'**
  String get helpCenterSearchReportsDesc;

  /// No description provided for @helpCenterSearchReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Generating financial reports'**
  String get helpCenterSearchReportsTitle;

  /// No description provided for @helpCenterShowingAll.
  ///
  /// In en, this message translates to:
  /// **'Showing all articles...'**
  String get helpCenterShowingAll;

  /// No description provided for @helpCenterStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Sign up with your details'**
  String get helpCenterStep1Desc;

  /// No description provided for @helpCenterStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get helpCenterStep1Title;

  /// No description provided for @helpCenterStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Create or join an organization'**
  String get helpCenterStep2Desc;

  /// No description provided for @helpCenterStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Organization'**
  String get helpCenterStep2Title;

  /// No description provided for @helpCenterStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Add vehicles to the system'**
  String get helpCenterStep3Desc;

  /// No description provided for @helpCenterStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Add Your Fleet'**
  String get helpCenterStep3Title;

  /// No description provided for @helpCenterStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'Add drivers and staff'**
  String get helpCenterStep4Desc;

  /// No description provided for @helpCenterStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Invite Team Members'**
  String get helpCenterStep4Title;

  /// No description provided for @helpCenterStep5Desc.
  ///
  /// In en, this message translates to:
  /// **'Begin tracking and managing your fleet'**
  String get helpCenterStep5Desc;

  /// No description provided for @helpCenterStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Start Managing'**
  String get helpCenterStep5Title;

  /// No description provided for @helpCenterSupport247.
  ///
  /// In en, this message translates to:
  /// **'Our support team is available 24/7 to assist you'**
  String get helpCenterSupport247;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterVideoComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Video tutorials coming soon!'**
  String get helpCenterVideoComingSoon;

  /// No description provided for @helpCenterVideoTutorials.
  ///
  /// In en, this message translates to:
  /// **'Video Tutorials'**
  String get helpCenterVideoTutorials;

  /// No description provided for @helpCenterViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get helpCenterViewAll;

  /// No description provided for @helpCenterWasHelpful.
  ///
  /// In en, this message translates to:
  /// **'Was this helpful?'**
  String get helpCenterWasHelpful;

  /// No description provided for @orgCreate10Chars.
  ///
  /// In en, this message translates to:
  /// **'10 characters'**
  String get orgCreate10Chars;

  /// No description provided for @orgCreate15Chars.
  ///
  /// In en, this message translates to:
  /// **'15 characters'**
  String get orgCreate15Chars;

  /// No description provided for @orgCreateAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get orgCreateAdd;

  /// No description provided for @orgCreateAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get orgCreateAddressRequired;

  /// No description provided for @orgCreateBusinessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get orgCreateBusinessEmail;

  /// No description provided for @orgCreateBusinessPhone.
  ///
  /// In en, this message translates to:
  /// **'Business Phone'**
  String get orgCreateBusinessPhone;

  /// No description provided for @orgCreateBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get orgCreateBusinessType;

  /// No description provided for @orgCreateBusinessTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Transportation, Logistics'**
  String get orgCreateBusinessTypeHint;

  /// No description provided for @orgCreateBusinessTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Business type is required'**
  String get orgCreateBusinessTypeRequired;

  /// No description provided for @orgCreateCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get orgCreateCity;

  /// No description provided for @orgCreateCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get orgCreateCompanyName;

  /// No description provided for @orgCreateCompanyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Acme Logistics Pvt. Ltd.'**
  String get orgCreateCompanyNameHint;

  /// No description provided for @orgCreateCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get orgCreateCompanyNameRequired;

  /// No description provided for @orgCreateCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get orgCreateCountry;

  /// No description provided for @orgCreateEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get orgCreateEmailInvalid;

  /// No description provided for @orgCreateEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Business email is required'**
  String get orgCreateEmailRequired;

  /// No description provided for @orgCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create organization: {error}'**
  String orgCreateFailed(String error);

  /// No description provided for @orgCreateGstinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid GSTIN format'**
  String get orgCreateGstinInvalid;

  /// No description provided for @orgCreateGstinLength.
  ///
  /// In en, this message translates to:
  /// **'GSTIN must be exactly 15 characters'**
  String get orgCreateGstinLength;

  /// No description provided for @orgCreateHeaderSub.
  ///
  /// In en, this message translates to:
  /// **'Set up your fleet workspace'**
  String get orgCreateHeaderSub;

  /// No description provided for @orgCreateHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Organization'**
  String get orgCreateHeaderTitle;

  /// No description provided for @orgCreateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get orgCreateInvalid;

  /// No description provided for @orgCreateLegalSub.
  ///
  /// In en, this message translates to:
  /// **'GSTIN & PAN — Optional'**
  String get orgCreateLegalSub;

  /// No description provided for @orgCreateMin10Digits.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 10 digits'**
  String get orgCreateMin10Digits;

  /// No description provided for @orgCreateMin2Chars.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 2 characters'**
  String get orgCreateMin2Chars;

  /// No description provided for @orgCreateOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} (Optional)'**
  String orgCreateOptionalLabel(String label);

  /// No description provided for @orgCreatePanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid PAN format'**
  String get orgCreatePanInvalid;

  /// No description provided for @orgCreatePanLength.
  ///
  /// In en, this message translates to:
  /// **'PAN must be exactly 10 characters'**
  String get orgCreatePanLength;

  /// No description provided for @orgCreatePanNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get orgCreatePanNumber;

  /// No description provided for @orgCreatePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Business phone is required'**
  String get orgCreatePhoneRequired;

  /// No description provided for @orgCreatePincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get orgCreatePincode;

  /// No description provided for @orgCreateRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get orgCreateRequired;

  /// No description provided for @orgCreateSecAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orgCreateSecAddress;

  /// No description provided for @orgCreateSecCompany.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get orgCreateSecCompany;

  /// No description provided for @orgCreateSecContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get orgCreateSecContact;

  /// No description provided for @orgCreateSecLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get orgCreateSecLegal;

  /// No description provided for @orgCreateState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get orgCreateState;

  /// No description provided for @orgCreateStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get orgCreateStreetAddress;

  /// No description provided for @orgCreateStreetAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Building, street, area…'**
  String get orgCreateStreetAddressHint;

  /// No description provided for @orgCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Organization \"{name}\" created successfully!'**
  String orgCreateSuccess(String name);

  /// No description provided for @orgCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get orgCreateTitle;

  /// No description provided for @orgManageAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get orgManageAllCaughtUp;

  /// No description provided for @orgManageApproveAssign.
  ///
  /// In en, this message translates to:
  /// **'Approve & Assign Role'**
  String get orgManageApproveAssign;

  /// No description provided for @orgManageApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve user: {error}'**
  String orgManageApproveFailed(String error);

  /// No description provided for @orgManageApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve {username}'**
  String orgManageApproveTitle(String username);

  /// No description provided for @orgManageApproved.
  ///
  /// In en, this message translates to:
  /// **'{username} approved successfully'**
  String orgManageApproved(String username);

  /// No description provided for @orgManageAssignRole.
  ///
  /// In en, this message translates to:
  /// **'Assign Role'**
  String get orgManageAssignRole;

  /// No description provided for @orgManageChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get orgManageChangeRole;

  /// No description provided for @orgManageHeaderSummary.
  ///
  /// In en, this message translates to:
  /// **'{members} members · {pending} pending'**
  String orgManageHeaderSummary(int members, int pending);

  /// No description provided for @orgManageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load organization data.'**
  String get orgManageLoadFailed;

  /// No description provided for @orgManageMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Members will appear here'**
  String get orgManageMembersHint;

  /// No description provided for @orgManageMembersTab.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String orgManageMembersTab(int count);

  /// No description provided for @orgManageNewRoleFor.
  ///
  /// In en, this message translates to:
  /// **'New role for {username}'**
  String orgManageNewRoleFor(String username);

  /// No description provided for @orgManageNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get orgManageNoMembers;

  /// No description provided for @orgManageNoPending.
  ///
  /// In en, this message translates to:
  /// **'No pending join requests'**
  String get orgManageNoPending;

  /// No description provided for @orgManageNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String orgManageNoResults(String query);

  /// No description provided for @orgManageNoRole.
  ///
  /// In en, this message translates to:
  /// **'No Role'**
  String get orgManageNoRole;

  /// No description provided for @orgManageOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get orgManageOwner;

  /// No description provided for @orgManagePendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orgManagePendingBadge;

  /// No description provided for @orgManagePendingTab.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String orgManagePendingTab(int count);

  /// No description provided for @orgManageRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get orgManageRefresh;

  /// No description provided for @orgManageReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get orgManageReject;

  /// No description provided for @orgManageRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject {username}\'s request to join?'**
  String orgManageRejectConfirm(String username);

  /// No description provided for @orgManageRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject: {error}'**
  String orgManageRejectFailed(String error);

  /// No description provided for @orgManageRejectUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject User'**
  String get orgManageRejectUserTitle;

  /// No description provided for @orgManageRejected.
  ///
  /// In en, this message translates to:
  /// **'{username} rejected'**
  String orgManageRejected(String username);

  /// No description provided for @orgManageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get orgManageRemove;

  /// No description provided for @orgManageRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {username} from {orgName}? They will lose access immediately.'**
  String orgManageRemoveConfirm(String username, String orgName);

  /// No description provided for @orgManageRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove: {error}'**
  String orgManageRemoveFailed(String error);

  /// No description provided for @orgManageRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get orgManageRemoveTitle;

  /// No description provided for @orgManageRemoved.
  ///
  /// In en, this message translates to:
  /// **'{username} removed'**
  String orgManageRemoved(String username);

  /// No description provided for @orgManageRequestedRole.
  ///
  /// In en, this message translates to:
  /// **'Requested: {role}'**
  String orgManageRequestedRole(String role);

  /// No description provided for @orgManageRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get orgManageRoleAdmin;

  /// No description provided for @orgManageRoleAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage members & settings'**
  String get orgManageRoleAdminDesc;

  /// No description provided for @orgManageRoleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get orgManageRoleDispatcher;

  /// No description provided for @orgManageRoleDispatcherDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage trips & assignments'**
  String get orgManageRoleDispatcherDesc;

  /// No description provided for @orgManageRoleUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role: {error}'**
  String orgManageRoleUpdateFailed(String error);

  /// No description provided for @orgManageRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get orgManageRoleUpdated;

  /// No description provided for @orgManageRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get orgManageRoleUser;

  /// No description provided for @orgManageRoleUserDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard access to features'**
  String get orgManageRoleUserDesc;

  /// No description provided for @orgManageRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get orgManageRoleViewer;

  /// No description provided for @orgManageRoleViewerDesc.
  ///
  /// In en, this message translates to:
  /// **'Read-only access'**
  String get orgManageRoleViewerDesc;

  /// No description provided for @orgManageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search members…'**
  String get orgManageSearchHint;

  /// No description provided for @orgManageSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Select a role to assign'**
  String get orgManageSelectRole;

  /// No description provided for @orgSelectCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get orgSelectCreate;

  /// No description provided for @orgSelectCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New Organization'**
  String get orgSelectCreateNew;

  /// No description provided for @orgSelectCreateNewSub.
  ///
  /// In en, this message translates to:
  /// **'Set up your own fleet organization'**
  String get orgSelectCreateNewSub;

  /// No description provided for @orgSelectNoOrgs.
  ///
  /// In en, this message translates to:
  /// **'No Organizations Yet'**
  String get orgSelectNoOrgs;

  /// No description provided for @orgSelectNoOrgsBody.
  ///
  /// In en, this message translates to:
  /// **'Create your own or ask an admin to add you to an existing organization.'**
  String get orgSelectNoOrgsBody;

  /// No description provided for @orgSelectNoRole.
  ///
  /// In en, this message translates to:
  /// **'No Role'**
  String get orgSelectNoRole;

  /// No description provided for @orgSelectSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to switch organization'**
  String get orgSelectSwitchFailed;

  /// No description provided for @orgSelectSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String orgSelectSwitched(String name);

  /// No description provided for @orgSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Organization'**
  String get orgSelectTitle;

  /// No description provided for @orgSelectTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get orgSelectTryAgain;

  /// No description provided for @orgSelectUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get orgSelectUser;

  /// No description provided for @orgSelectWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get orgSelectWelcome;

  /// No description provided for @orgSelectWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get orgSelectWrong;

  /// No description provided for @orgSelectYourOrgs.
  ///
  /// In en, this message translates to:
  /// **'Your Organizations'**
  String get orgSelectYourOrgs;

  /// No description provided for @profileAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get profileAccountStatus;

  /// No description provided for @profileAuthEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email & Password'**
  String get profileAuthEmailPassword;

  /// No description provided for @profileAuthMethod.
  ///
  /// In en, this message translates to:
  /// **'Auth Method'**
  String get profileAuthMethod;

  /// No description provided for @profileAuthSecurityQuestions.
  ///
  /// In en, this message translates to:
  /// **'Security Questions'**
  String get profileAuthSecurityQuestions;

  /// No description provided for @profileBecameDriver.
  ///
  /// In en, this message translates to:
  /// **'Role changed to Driver successfully!'**
  String get profileBecameDriver;

  /// No description provided for @profileBecomeDriver.
  ///
  /// In en, this message translates to:
  /// **'Become Driver'**
  String get profileBecomeDriver;

  /// No description provided for @profileBecomeDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a Driver'**
  String get profileBecomeDriverTitle;

  /// No description provided for @profileCancelPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'This will cancel your pending organization request and return you to Independent User status. You can join or create an organization again at any time.'**
  String get profileCancelPendingMessage;

  /// No description provided for @profileCancelPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Pending Request?'**
  String get profileCancelPendingTitle;

  /// No description provided for @profileChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get profileChange;

  /// No description provided for @profileChangeOrganization.
  ///
  /// In en, this message translates to:
  /// **'Change Organization'**
  String get profileChangeOrganization;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profileChangeRoleChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to change your role:'**
  String get profileChangeRoleChoose;

  /// No description provided for @profileChangeRoleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change role'**
  String get profileChangeRoleFailed;

  /// No description provided for @profileChangeRolePending.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending. What would you like to do?'**
  String get profileChangeRolePending;

  /// No description provided for @profileChangeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get profileChangeRoleTitle;

  /// No description provided for @profileCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get profileCompany;

  /// No description provided for @profileCreateOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get profileCreateOrganization;

  /// No description provided for @profileDefaultUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileDefaultUser;

  /// No description provided for @profileDriverLicenseIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your driver license details:'**
  String get profileDriverLicenseIntro;

  /// No description provided for @profileEditBanner.
  ///
  /// In en, this message translates to:
  /// **'Edit mode — tap ✓ in the toolbar to save changes'**
  String get profileEditBanner;

  /// No description provided for @profileEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTooltip;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileEnterLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'Please enter license expiry date'**
  String get profileEnterLicenseExpiry;

  /// No description provided for @profileEnterLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter license number'**
  String get profileEnterLicenseNumber;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profileFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get profileFullNameRequired;

  /// No description provided for @profileGoIndependent.
  ///
  /// In en, this message translates to:
  /// **'Go Independent'**
  String get profileGoIndependent;

  /// No description provided for @profileImageReadError.
  ///
  /// In en, this message translates to:
  /// **'Error reading image: {error}'**
  String profileImageReadError(String error);

  /// No description provided for @profileImageSelectError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String profileImageSelectError(String error);

  /// No description provided for @profileIndependentOptions.
  ///
  /// In en, this message translates to:
  /// **'As an Independent User, you can:'**
  String get profileIndependentOptions;

  /// No description provided for @profileJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to join organization'**
  String get profileJoinFailed;

  /// No description provided for @profileJoinOrganization.
  ///
  /// In en, this message translates to:
  /// **'Join Organization'**
  String get profileJoinOrganization;

  /// No description provided for @profileJoinSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Join request submitted! Awaiting approval.'**
  String get profileJoinSubmitted;

  /// No description provided for @profileKeepPending.
  ///
  /// In en, this message translates to:
  /// **'Keep Pending'**
  String get profileKeepPending;

  /// No description provided for @profileLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'License Expiry (YYYY-MM-DD)'**
  String get profileLicenseExpiry;

  /// No description provided for @profileLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get profileLicenseNumber;

  /// No description provided for @profileNewPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'New photo selected · tap Save to apply'**
  String get profileNewPhotoSelected;

  /// No description provided for @profileNoPreference.
  ///
  /// In en, this message translates to:
  /// **'No preference'**
  String get profileNoPreference;

  /// No description provided for @profileNoRole.
  ///
  /// In en, this message translates to:
  /// **'No Role'**
  String get profileNoRole;

  /// No description provided for @profileNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get profileNone;

  /// No description provided for @profileNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get profileNotAssigned;

  /// No description provided for @profileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get profileNotAvailable;

  /// No description provided for @profileNowIndependent.
  ///
  /// In en, this message translates to:
  /// **'You are now an Independent User.'**
  String get profileNowIndependent;

  /// No description provided for @profilePendingOptions.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending approval. You can:'**
  String get profilePendingOptions;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInfo;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profilePhotoAddHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo'**
  String get profilePhotoAddHint;

  /// No description provided for @profilePhotoChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo · long-press to remove'**
  String get profilePhotoChangeHint;

  /// No description provided for @profileRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profileRemove;

  /// No description provided for @profileRemovePictureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove profile picture'**
  String get profileRemovePictureFailed;

  /// No description provided for @profileRemovePictureMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove your profile picture?'**
  String get profileRemovePictureMessage;

  /// No description provided for @profileRemovePictureTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Profile Picture'**
  String get profileRemovePictureTitle;

  /// No description provided for @profileRequestedRole.
  ///
  /// In en, this message translates to:
  /// **'Requested Role (Optional)'**
  String get profileRequestedRole;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// No description provided for @profileRoleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get profileRoleAccountant;

  /// No description provided for @profileRoleComplianceOfficer.
  ///
  /// In en, this message translates to:
  /// **'Compliance Officer'**
  String get profileRoleComplianceOfficer;

  /// No description provided for @profileRoleCustomerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get profileRoleCustomerService;

  /// No description provided for @profileRoleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get profileRoleDispatcher;

  /// No description provided for @profileRoleFleetManager.
  ///
  /// In en, this message translates to:
  /// **'Fleet Manager'**
  String get profileRoleFleetManager;

  /// No description provided for @profileRoleMaintenanceManager.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Manager'**
  String get profileRoleMaintenanceManager;

  /// No description provided for @profileRoleMaintenanceTechnician.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Technician'**
  String get profileRoleMaintenanceTechnician;

  /// No description provided for @profileRoleManaged.
  ///
  /// In en, this message translates to:
  /// **'Your role is managed by your organization.'**
  String get profileRoleManaged;

  /// No description provided for @profileRoleOperationsManager.
  ///
  /// In en, this message translates to:
  /// **'Operations Manager'**
  String get profileRoleOperationsManager;

  /// No description provided for @profileRoleOrg.
  ///
  /// In en, this message translates to:
  /// **'Role & Organization'**
  String get profileRoleOrg;

  /// No description provided for @profileRoleUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role'**
  String get profileRoleUpdateFailed;

  /// No description provided for @profileRoleViewerAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Viewer / Analyst'**
  String get profileRoleViewerAnalyst;

  /// No description provided for @profileStatus.
  ///
  /// In en, this message translates to:
  /// **'Profile Status'**
  String get profileStatus;

  /// No description provided for @profileStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get profileStatusCompleted;

  /// No description provided for @profileStatusIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get profileStatusIncomplete;

  /// No description provided for @profileStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get profileStatusLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get profileUnknown;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @profileUploadPictureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile picture'**
  String get profileUploadPictureFailed;

  /// No description provided for @profileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsername;

  /// No description provided for @customRoleAfterCreateNote.
  ///
  /// In en, this message translates to:
  /// **'After creation, you\'ll be taken to the role editor to configure capabilities.'**
  String get customRoleAfterCreateNote;

  /// No description provided for @customRoleCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get customRoleCapabilities;

  /// No description provided for @customRoleCapabilityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 capability} other{{count} capabilities}}'**
  String customRoleCapabilityCount(int count);

  /// No description provided for @customRoleCatCompliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance & Safety'**
  String get customRoleCatCompliance;

  /// No description provided for @customRoleCatCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer Management'**
  String get customRoleCatCustomer;

  /// No description provided for @customRoleCatDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver Management'**
  String get customRoleCatDriver;

  /// No description provided for @customRoleCatFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial Management'**
  String get customRoleCatFinancial;

  /// No description provided for @customRoleCatMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get customRoleCatMaintenance;

  /// No description provided for @customRoleCatReporting.
  ///
  /// In en, this message translates to:
  /// **'Reporting & Analytics'**
  String get customRoleCatReporting;

  /// No description provided for @customRoleCatRole.
  ///
  /// In en, this message translates to:
  /// **'Role Management'**
  String get customRoleCatRole;

  /// No description provided for @customRoleCatSystem.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get customRoleCatSystem;

  /// No description provided for @customRoleCatTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking & Monitoring'**
  String get customRoleCatTracking;

  /// No description provided for @customRoleCatTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip Management'**
  String get customRoleCatTrip;

  /// No description provided for @customRoleCatUser.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get customRoleCatUser;

  /// No description provided for @customRoleCatVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Management'**
  String get customRoleCatVehicle;

  /// No description provided for @customRoleCategoryEnabled.
  ///
  /// In en, this message translates to:
  /// **'{enabled} / {total} capabilities enabled'**
  String customRoleCategoryEnabled(int enabled, int total);

  /// No description provided for @customRoleChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose creation method'**
  String get customRoleChooseMethod;

  /// No description provided for @customRoleChooseMethodHint.
  ///
  /// In en, this message translates to:
  /// **'Start from a predefined template or build from scratch'**
  String get customRoleChooseMethodHint;

  /// No description provided for @customRoleCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get customRoleCreateButton;

  /// No description provided for @customRoleCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create role: {error}'**
  String customRoleCreateFailed(String error);

  /// No description provided for @customRoleCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Role'**
  String get customRoleCreateTitle;

  /// No description provided for @customRoleCreated.
  ///
  /// In en, this message translates to:
  /// **'Custom role created successfully'**
  String get customRoleCreated;

  /// No description provided for @customRoleCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get customRoleCreating;

  /// No description provided for @customRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get customRoleDescription;

  /// No description provided for @customRoleDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the purpose of this role'**
  String get customRoleDescriptionHint;

  /// No description provided for @customRoleDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get customRoleDescriptionOptional;

  /// No description provided for @customRoleDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Give your custom role a name and description'**
  String get customRoleDetailsHint;

  /// No description provided for @customRoleDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Details'**
  String get customRoleDetailsTitle;

  /// No description provided for @customRoleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Role'**
  String get customRoleEditTitle;

  /// No description provided for @customRoleEnabledCount.
  ///
  /// In en, this message translates to:
  /// **'{enabled} / {total} enabled'**
  String customRoleEnabledCount(int enabled, int total);

  /// No description provided for @customRoleFromScratch.
  ///
  /// In en, this message translates to:
  /// **'From Scratch'**
  String get customRoleFromScratch;

  /// No description provided for @customRoleFromScratchDesc.
  ///
  /// In en, this message translates to:
  /// **'Build a completely custom role with your own capabilities. Configure everything manually.'**
  String get customRoleFromScratchDesc;

  /// No description provided for @customRoleFromScratchTitle.
  ///
  /// In en, this message translates to:
  /// **'Start from Scratch'**
  String get customRoleFromScratchTitle;

  /// No description provided for @customRoleFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From Template'**
  String get customRoleFromTemplate;

  /// No description provided for @customRoleFromTemplateDesc.
  ///
  /// In en, this message translates to:
  /// **'Use predefined role templates as a starting point. Inherit capabilities and customize.'**
  String get customRoleFromTemplateDesc;

  /// No description provided for @customRoleFromTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Start from Template'**
  String get customRoleFromTemplateTitle;

  /// No description provided for @customRoleInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Information'**
  String get customRoleInfoTitle;

  /// No description provided for @customRoleIntersection.
  ///
  /// In en, this message translates to:
  /// **'Intersection (Only Common)'**
  String get customRoleIntersection;

  /// No description provided for @customRoleIntersectionCommon.
  ///
  /// In en, this message translates to:
  /// **'Intersection (Common Only)'**
  String get customRoleIntersectionCommon;

  /// No description provided for @customRoleIntersectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Include only capabilities shared by all selected templates'**
  String get customRoleIntersectionDesc;

  /// No description provided for @customRoleLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get customRoleLeave;

  /// No description provided for @customRoleLevelFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get customRoleLevelFull;

  /// No description provided for @customRoleLevelLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get customRoleLevelLimited;

  /// No description provided for @customRoleLevelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get customRoleLevelNone;

  /// No description provided for @customRoleLevelView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get customRoleLevelView;

  /// No description provided for @customRoleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load role'**
  String get customRoleLoadFailed;

  /// No description provided for @customRoleMergeStrategy.
  ///
  /// In en, this message translates to:
  /// **'Merge Strategy'**
  String get customRoleMergeStrategy;

  /// No description provided for @customRoleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Regional Manager - West Coast'**
  String get customRoleNameHint;

  /// No description provided for @customRoleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get customRoleNameLabel;

  /// No description provided for @customRoleNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a role name'**
  String get customRoleNameRequired;

  /// No description provided for @customRoleNameRequiredShort.
  ///
  /// In en, this message translates to:
  /// **'Role name required'**
  String get customRoleNameRequiredShort;

  /// No description provided for @customRoleNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get customRoleNoDescription;

  /// No description provided for @customRoleNotSet.
  ///
  /// In en, this message translates to:
  /// **'(not set)'**
  String get customRoleNotSet;

  /// No description provided for @customRoleQuickAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get customRoleQuickAll;

  /// No description provided for @customRoleReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your custom role details before creating'**
  String get customRoleReviewHint;

  /// No description provided for @customRoleReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Create'**
  String get customRoleReviewTitle;

  /// No description provided for @customRoleSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get customRoleSaveChanges;

  /// No description provided for @customRoleSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get customRoleSaving;

  /// No description provided for @customRoleSelectOneTemplate.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one template'**
  String get customRoleSelectOneTemplate;

  /// No description provided for @customRoleSelectTemplates.
  ///
  /// In en, this message translates to:
  /// **'Select Templates'**
  String get customRoleSelectTemplates;

  /// No description provided for @customRoleSelectTemplatesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more templates to combine'**
  String get customRoleSelectTemplatesHint;

  /// No description provided for @customRoleSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String customRoleSelectedCount(int count);

  /// No description provided for @customRoleStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get customRoleStay;

  /// No description provided for @customRoleStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get customRoleStepDetails;

  /// No description provided for @customRoleStepMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get customRoleStepMethod;

  /// No description provided for @customRoleStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get customRoleStepReview;

  /// No description provided for @customRoleStepTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get customRoleStepTemplates;

  /// No description provided for @customRoleSystemCritical.
  ///
  /// In en, this message translates to:
  /// **'System critical – restricted to super admin'**
  String get customRoleSystemCritical;

  /// No description provided for @customRoleTemplateError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String customRoleTemplateError(String error);

  /// No description provided for @customRoleTemplatePreselected.
  ///
  /// In en, this message translates to:
  /// **'Template pre-selected: {names}'**
  String customRoleTemplatePreselected(String names);

  /// No description provided for @customRoleUnion.
  ///
  /// In en, this message translates to:
  /// **'Union (Combine All)'**
  String get customRoleUnion;

  /// No description provided for @customRoleUnionDesc.
  ///
  /// In en, this message translates to:
  /// **'Include all capabilities from all selected templates'**
  String get customRoleUnionDesc;

  /// No description provided for @customRoleUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to leave without saving?'**
  String get customRoleUnsavedBody;

  /// No description provided for @customRoleUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get customRoleUnsavedTitle;

  /// No description provided for @customRoleUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role'**
  String get customRoleUpdateFailed;

  /// No description provided for @customRoleUpdateFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role: {error}'**
  String customRoleUpdateFailedWithError(String error);

  /// No description provided for @customRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get customRoleUpdated;

  /// No description provided for @customRolesActiveMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active member} other{{count} active members}}'**
  String customRolesActiveMembers(int count);

  /// No description provided for @customRolesApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get customRolesApprove;

  /// No description provided for @customRolesApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve request'**
  String get customRolesApproveFailed;

  /// No description provided for @customRolesApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Request'**
  String get customRolesApproveTitle;

  /// No description provided for @customRolesApprovedOk.
  ///
  /// In en, this message translates to:
  /// **'{name} approved successfully!'**
  String customRolesApprovedOk(String name);

  /// No description provided for @customRolesApprovingFrom.
  ///
  /// In en, this message translates to:
  /// **'Approving join request from {name}.'**
  String customRolesApprovingFrom(String name);

  /// No description provided for @customRolesAssignRole.
  ///
  /// In en, this message translates to:
  /// **'Assign Role:'**
  String get customRolesAssignRole;

  /// No description provided for @customRolesCapabilityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 capability} other{{count} capabilities}}'**
  String customRolesCapabilityCount(int count);

  /// No description provided for @customRolesChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get customRolesChangeRole;

  /// No description provided for @customRolesChangeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Member Role'**
  String get customRolesChangeRoleTitle;

  /// No description provided for @customRolesClone.
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get customRolesClone;

  /// No description provided for @customRolesCloneFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clone'**
  String get customRolesCloneFailed;

  /// No description provided for @customRolesCloneTitle.
  ///
  /// In en, this message translates to:
  /// **'Clone Role'**
  String get customRolesCloneTitle;

  /// No description provided for @customRolesCloned.
  ///
  /// In en, this message translates to:
  /// **'Role cloned successfully'**
  String get customRolesCloned;

  /// No description provided for @customRolesCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Role'**
  String get customRolesCreateFirst;

  /// No description provided for @customRolesCreateFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Role from This Template'**
  String get customRolesCreateFromTemplate;

  /// No description provided for @customRolesCreateRole.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Role'**
  String get customRolesCreateRole;

  /// No description provided for @customRolesCustomBadge.
  ///
  /// In en, this message translates to:
  /// **'custom'**
  String get customRolesCustomBadge;

  /// No description provided for @customRolesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this role? This cannot be undone.'**
  String get customRolesDeleteConfirm;

  /// No description provided for @customRolesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete role'**
  String get customRolesDeleteFailed;

  /// No description provided for @customRolesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Role'**
  String get customRolesDeleteTitle;

  /// No description provided for @customRolesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Role deleted successfully'**
  String get customRolesDeleted;

  /// No description provided for @customRolesDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get customRolesDescriptionOptional;

  /// No description provided for @customRolesNewRole.
  ///
  /// In en, this message translates to:
  /// **'New Role:'**
  String get customRolesNewRole;

  /// No description provided for @customRolesNewRoleName.
  ///
  /// In en, this message translates to:
  /// **'New Role Name'**
  String get customRolesNewRoleName;

  /// No description provided for @customRolesNoCapabilities.
  ///
  /// In en, this message translates to:
  /// **'No capabilities listed'**
  String get customRolesNoCapabilities;

  /// No description provided for @customRolesNoCustomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create custom roles tailored to your organization'**
  String get customRolesNoCustomSubtitle;

  /// No description provided for @customRolesNoCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'No Custom Roles Yet'**
  String get customRolesNoCustomTitle;

  /// No description provided for @customRolesNoMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approve pending requests to add members to your organization.'**
  String get customRolesNoMembersSubtitle;

  /// No description provided for @customRolesNoMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No Members Yet'**
  String get customRolesNoMembersTitle;

  /// No description provided for @customRolesNoPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All join requests have been processed.'**
  String get customRolesNoPendingSubtitle;

  /// No description provided for @customRolesNoPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'No Pending Requests'**
  String get customRolesNoPendingTitle;

  /// No description provided for @customRolesNoRole.
  ///
  /// In en, this message translates to:
  /// **'No Role'**
  String get customRolesNoRole;

  /// No description provided for @customRolesNoRoleRequested.
  ///
  /// In en, this message translates to:
  /// **'No role requested'**
  String get customRolesNoRoleRequested;

  /// No description provided for @customRolesNoTemplates.
  ///
  /// In en, this message translates to:
  /// **'No predefined templates found'**
  String get customRolesNoTemplates;

  /// No description provided for @customRolesNoTemplatesHint.
  ///
  /// In en, this message translates to:
  /// **'Templates are seeded automatically on server startup.'**
  String get customRolesNoTemplatesHint;

  /// No description provided for @customRolesPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member waiting to join your organization} other{{count} members waiting to join your organization}}'**
  String customRolesPendingBanner(int count);

  /// No description provided for @customRolesRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get customRolesRefresh;

  /// No description provided for @customRolesReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get customRolesReject;

  /// No description provided for @customRolesRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject join request from {name}? They will need to reapply to join.'**
  String customRolesRejectConfirm(String name);

  /// No description provided for @customRolesRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject request'**
  String get customRolesRejectFailed;

  /// No description provided for @customRolesRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get customRolesRejectTitle;

  /// No description provided for @customRolesRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected.'**
  String get customRolesRejected;

  /// No description provided for @customRolesRoleUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role'**
  String get customRolesRoleUpdateFailed;

  /// No description provided for @customRolesRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated for {name}'**
  String customRolesRoleUpdated(String name);

  /// No description provided for @customRolesSaveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as Template'**
  String get customRolesSaveAsTemplate;

  /// No description provided for @customRolesSavedTemplate.
  ///
  /// In en, this message translates to:
  /// **'Saved Template'**
  String get customRolesSavedTemplate;

  /// No description provided for @customRolesSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Select role'**
  String get customRolesSelectRole;

  /// No description provided for @customRolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage roles, permissions & team members'**
  String get customRolesSubtitle;

  /// No description provided for @customRolesTabCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customRolesTabCustom;

  /// No description provided for @customRolesTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get customRolesTabMembers;

  /// No description provided for @customRolesTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get customRolesTabPending;

  /// No description provided for @customRolesTabTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get customRolesTabTemplates;

  /// No description provided for @customRolesTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get customRolesTemplateName;

  /// No description provided for @customRolesTemplateSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save template'**
  String get customRolesTemplateSaveFailed;

  /// No description provided for @customRolesTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as template'**
  String get customRolesTemplateSaved;

  /// No description provided for @customRolesTemplatesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Template} other{{count} Templates}}'**
  String customRolesTemplatesCount(int count);

  /// No description provided for @customRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get customRolesTitle;

  /// No description provided for @customRolesUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get customRolesUnknown;

  /// No description provided for @customRolesUnknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown Role'**
  String get customRolesUnknownRole;

  /// No description provided for @customRolesUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get customRolesUpdate;

  /// No description provided for @customRolesUpdateRoleFor.
  ///
  /// In en, this message translates to:
  /// **'Update role for {name}'**
  String customRolesUpdateRoleFor(String name);

  /// No description provided for @customRolesUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get customRolesUse;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// No description provided for @settingsAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync Data'**
  String get settingsAutoSync;

  /// No description provided for @settingsAutoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync automatically when online'**
  String get settingsAutoSyncDesc;

  /// No description provided for @settingsBackgroundTracking.
  ///
  /// In en, this message translates to:
  /// **'Background Tracking'**
  String get settingsBackgroundTracking;

  /// No description provided for @settingsBackgroundTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Continue tracking when app is in background'**
  String get settingsBackgroundTrackingDesc;

  /// No description provided for @settingsBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get settingsBiometricLock;

  /// No description provided for @settingsBiometricLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or Face ID to unlock'**
  String get settingsBiometricLockDesc;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get settingsCacheCleared;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Free up device storage space'**
  String get settingsClearCacheDesc;

  /// No description provided for @settingsClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will clear all cached data and free up storage space. Your account data will not be affected.'**
  String get settingsClearCacheMessage;

  /// No description provided for @settingsCompactView.
  ///
  /// In en, this message translates to:
  /// **'Compact View'**
  String get settingsCompactView;

  /// No description provided for @settingsCompactViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Show more items on screen'**
  String get settingsCompactViewDesc;

  /// No description provided for @settingsCurrentlyTracking.
  ///
  /// In en, this message translates to:
  /// **'Currently tracking location'**
  String get settingsCurrentlyTracking;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get settingsDangerZone;

  /// No description provided for @settingsDataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get settingsDataStorage;

  /// No description provided for @settingsDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Fleet Manager'**
  String get settingsDefaultName;

  /// No description provided for @settingsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsDisplay;

  /// No description provided for @settingsDriverUpdates.
  ///
  /// In en, this message translates to:
  /// **'Driver Updates'**
  String get settingsDriverUpdates;

  /// No description provided for @settingsDriverUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Driver assignment alerts'**
  String get settingsDriverUpdatesDesc;

  /// No description provided for @settingsFreqBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get settingsFreqBalanced;

  /// No description provided for @settingsFreqBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get settingsFreqBattery;

  /// No description provided for @settingsFreqHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsFreqHigh;

  /// No description provided for @settingsFreqLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsFreqLow;

  /// No description provided for @settingsGpsTracking.
  ///
  /// In en, this message translates to:
  /// **'GPS Tracking'**
  String get settingsGpsTracking;

  /// No description provided for @settingsGpsTrackingDescOff.
  ///
  /// In en, this message translates to:
  /// **'Contact administrator to enable tracking'**
  String get settingsGpsTrackingDescOff;

  /// No description provided for @settingsGpsTrackingDescOn.
  ///
  /// In en, this message translates to:
  /// **'Enable location tracking for real-time updates'**
  String get settingsGpsTrackingDescOn;

  /// No description provided for @settingsGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get settingsGrant;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission: {status}'**
  String settingsLocationPermission(String status);

  /// No description provided for @settingsLocationTracking.
  ///
  /// In en, this message translates to:
  /// **'Location & Tracking'**
  String get settingsLocationTracking;

  /// No description provided for @settingsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String settingsMinutesAgo(int count);

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get settingsOfflineMode;

  /// No description provided for @settingsOfflineModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Cache data for offline access'**
  String get settingsOfflineModeDesc;

  /// No description provided for @settingsPermAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get settingsPermAlways;

  /// No description provided for @settingsPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get settingsPermDenied;

  /// No description provided for @settingsPermDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Permission Permanently Denied'**
  String get settingsPermDeniedForever;

  /// No description provided for @settingsPermServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location Service Disabled'**
  String get settingsPermServiceDisabled;

  /// No description provided for @settingsPermWhileInUse.
  ///
  /// In en, this message translates to:
  /// **'While In Use'**
  String get settingsPermWhileInUse;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsPrivacySecurity;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsPushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive important app alerts'**
  String get settingsPushNotificationsDesc;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetConfirm;

  /// No description provided for @settingsResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default Settings'**
  String get settingsResetDefaults;

  /// No description provided for @settingsResetDefaultsDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore all settings to factory defaults'**
  String get settingsResetDefaultsDesc;

  /// No description provided for @settingsResetDone.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsResetDone;

  /// No description provided for @settingsResetMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset all settings to their default values. Are you sure you want to continue?'**
  String get settingsResetMessage;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get settingsResetTitle;

  /// No description provided for @settingsSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String settingsSecondsAgo(int count);

  /// No description provided for @settingsShareAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Share Analytics'**
  String get settingsShareAnalytics;

  /// No description provided for @settingsShareAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app anonymously'**
  String get settingsShareAnalyticsDesc;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get settingsSignOutDesc;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Configuration'**
  String get settingsSubtitle;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose app appearance'**
  String get settingsThemeDesc;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTrackingAdminOff.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking disabled — contact administrator'**
  String get settingsTrackingAdminOff;

  /// No description provided for @settingsTrackingAdminOn.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking enabled by administrator'**
  String get settingsTrackingAdminOn;

  /// No description provided for @settingsTripUpdates.
  ///
  /// In en, this message translates to:
  /// **'Trip Updates'**
  String get settingsTripUpdates;

  /// No description provided for @settingsTripUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Trip status changes'**
  String get settingsTripUpdatesDesc;

  /// No description provided for @settingsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get settingsUpToDate;

  /// No description provided for @settingsUpdateFrequency.
  ///
  /// In en, this message translates to:
  /// **'Update Frequency'**
  String get settingsUpdateFrequency;

  /// No description provided for @settingsUpdateFrequencyDesc.
  ///
  /// In en, this message translates to:
  /// **'How often to update location'**
  String get settingsUpdateFrequencyDesc;

  /// No description provided for @settingsVehicleAlerts.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Alerts'**
  String get settingsVehicleAlerts;

  /// No description provided for @settingsVehicleAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Maintenance & status alerts'**
  String get settingsVehicleAlertsDesc;

  /// No description provided for @settingsViewLiveTracking.
  ///
  /// In en, this message translates to:
  /// **'View Live Tracking'**
  String get settingsViewLiveTracking;

  /// No description provided for @settingsViewLiveTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'See your current location on map'**
  String get settingsViewLiveTrackingDesc;

  /// No description provided for @vehAddChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get vehAddChooseFile;

  /// No description provided for @vehAddChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get vehAddChoosePhoto;

  /// No description provided for @vehAddFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get vehAddFillRequired;

  /// No description provided for @vehAddFuelCng.
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get vehAddFuelCng;

  /// No description provided for @vehAddFuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get vehAddFuelDiesel;

  /// No description provided for @vehAddFuelElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get vehAddFuelElectric;

  /// No description provided for @vehAddFuelHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get vehAddFuelHybrid;

  /// No description provided for @vehAddFuelLpg.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get vehAddFuelLpg;

  /// No description provided for @vehAddFuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get vehAddFuelPetrol;

  /// No description provided for @vehAddFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type *'**
  String get vehAddFuelType;

  /// No description provided for @vehAddHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. {value}'**
  String vehAddHintExample(String value);

  /// No description provided for @vehAddInfoNote.
  ///
  /// In en, this message translates to:
  /// **'By adding this vehicle, it will be automatically synchronized with your maintenance schedule and fuel tracking logs. Ensure the VIN is correct to receive automated manufacturer recalls.'**
  String get vehAddInfoNote;

  /// No description provided for @vehAddInvalidYear.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid year'**
  String get vehAddInvalidYear;

  /// No description provided for @vehAddLicensePlate.
  ///
  /// In en, this message translates to:
  /// **'License Plate *'**
  String get vehAddLicensePlate;

  /// No description provided for @vehAddMake.
  ///
  /// In en, this message translates to:
  /// **'Make *'**
  String get vehAddMake;

  /// No description provided for @vehAddModel.
  ///
  /// In en, this message translates to:
  /// **'Model *'**
  String get vehAddModel;

  /// No description provided for @vehAddOdometer.
  ///
  /// In en, this message translates to:
  /// **'Initial Odometer (km)'**
  String get vehAddOdometer;

  /// No description provided for @vehAddPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Vehicle created, but photo upload failed: {error}'**
  String vehAddPhotoFailed(String error);

  /// No description provided for @vehAddPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload or take a high-quality photo'**
  String get vehAddPhotoSubtitle;

  /// No description provided for @vehAddPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Photo'**
  String get vehAddPhotoTitle;

  /// No description provided for @vehAddRegister.
  ///
  /// In en, this message translates to:
  /// **'Register Vehicle'**
  String get vehAddRegister;

  /// No description provided for @vehAddRegistering.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get vehAddRegistering;

  /// No description provided for @vehAddRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get vehAddRemovePhoto;

  /// No description provided for @vehAddSectionIdentification.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get vehAddSectionIdentification;

  /// No description provided for @vehAddSectionSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get vehAddSectionSpecifications;

  /// No description provided for @vehAddSectionTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get vehAddSectionTechnical;

  /// No description provided for @vehAddSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registered successfully!'**
  String get vehAddSuccess;

  /// No description provided for @vehAddTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get vehAddTakePhoto;

  /// No description provided for @vehAddTypeBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get vehAddTypeBus;

  /// No description provided for @vehAddTypeCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get vehAddTypeCar;

  /// No description provided for @vehAddTypeMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get vehAddTypeMotorcycle;

  /// No description provided for @vehAddTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vehAddTypeOther;

  /// No description provided for @vehAddTypeSuv.
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get vehAddTypeSuv;

  /// No description provided for @vehAddTypeTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get vehAddTypeTruck;

  /// No description provided for @vehAddTypeVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehAddTypeVan;

  /// No description provided for @vehAddVehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number *'**
  String get vehAddVehicleNumber;

  /// No description provided for @vehAddVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type *'**
  String get vehAddVehicleType;

  /// No description provided for @vehAddVin.
  ///
  /// In en, this message translates to:
  /// **'VIN (optional)'**
  String get vehAddVin;

  /// No description provided for @vehAddVinHint.
  ///
  /// In en, this message translates to:
  /// **'17-character VIN'**
  String get vehAddVinHint;

  /// No description provided for @vehAddYear.
  ///
  /// In en, this message translates to:
  /// **'Year *'**
  String get vehAddYear;

  /// No description provided for @vehListClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get vehListClearFilters;

  /// No description provided for @vehListEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first vehicle to get started'**
  String get vehListEmptyHint;

  /// No description provided for @vehListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Vehicles Yet'**
  String get vehListEmptyTitle;

  /// No description provided for @vehListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Vehicles'**
  String get vehListFilterAll;

  /// No description provided for @vehListKm.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String vehListKm(String value);

  /// No description provided for @vehListNoDriver.
  ///
  /// In en, this message translates to:
  /// **'No driver'**
  String get vehListNoDriver;

  /// No description provided for @vehListNoDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'No driver assigned'**
  String get vehListNoDriverAssigned;

  /// No description provided for @vehListNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get vehListNotFoundHint;

  /// No description provided for @vehListNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Vehicles Found'**
  String get vehListNotFoundTitle;

  /// No description provided for @vehListRegisteredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} vehicle registered} other{{count} vehicles registered}}'**
  String vehListRegisteredCount(int count);

  /// No description provided for @vehListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by registration, make, model...'**
  String get vehListSearchHint;

  /// No description provided for @vehListSortMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get vehListSortMake;

  /// No description provided for @vehListSortMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get vehListSortMileage;

  /// No description provided for @vehListSortRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get vehListSortRegistration;

  /// No description provided for @vehListStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get vehListStatusActive;

  /// No description provided for @vehListStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get vehListStatusInactive;

  /// No description provided for @vehListStatusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get vehListStatusMaintenance;

  /// No description provided for @vehListTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet Vehicles'**
  String get vehListTitle;
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
