// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonSave => 'सेव करें';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonNext => 'आगे';

  @override
  String get commonRetry => 'फिर कोशिश करें';

  @override
  String get commonSubmit => 'सबमिट करें';

  @override
  String get commonYes => 'हाँ';

  @override
  String get commonNo => 'नहीं';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonDelete => 'हटाएं';

  @override
  String get commonEdit => 'एडिट करें';

  @override
  String get commonSearch => 'खोजें';

  @override
  String get commonLoading => 'कृपया प्रतीक्षा करें...';

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsLanguageSubtitle => 'अंग्रेज़ी या हिंदी चुनें';

  @override
  String get apiErrorCancelled => 'रिक्वेस्ट रद्द कर दी गई';

  @override
  String get apiErrorCannotConnect =>
      'सर्वर से कनेक्ट नहीं हो पा रहा। कृपया अपना इंटरनेट कनेक्शन जांचें।';

  @override
  String get apiErrorNetwork =>
      'नेटवर्क में समस्या। कृपया अपना इंटरनेट कनेक्शन जांचें।';

  @override
  String apiErrorServer(String code) {
    return 'सर्वर में समस्या: $code';
  }

  @override
  String get apiErrorTimeout => 'कनेक्शन टाइमआउट हो गया। कृपया फिर कोशिश करें।';

  @override
  String get apiErrorUnexpected => 'कोई अनपेक्षित समस्या आई';

  @override
  String get authBackToLogin => 'लॉगिन पर वापस जाएं';

  @override
  String get authEmail => 'ईमेल';

  @override
  String get authFieldRequired => 'यह जानकारी भरना ज़रूरी है';

  @override
  String get authPassword => 'पासवर्ड';

  @override
  String get authPhoneNumber => 'फ़ोन नंबर';

  @override
  String get authPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get authSignUp => 'साइन अप';

  @override
  String get authUnknownError => 'कुछ गड़बड़ हो गई। कृपया दोबारा कोशिश करें।';

  @override
  String get authUsername => 'यूज़रनेम';

  @override
  String get authVerifyEmail => 'ईमेल वेरिफ़ाई करें';

  @override
  String get codeVerifyExpiry => 'कोड 24 घंटे में खत्म हो जाएगा';

  @override
  String get codeVerifyFailed => 'वेरिफ़िकेशन नहीं हुआ';

  @override
  String get codeVerifyHeading => 'वेरिफ़िकेशन कोड डालें';

  @override
  String get codeVerifyIncomplete => 'कृपया पूरा 6 अंकों का कोड डालें';

  @override
  String get codeVerifyInstruction =>
      'अपना ईमेल वेरिफ़ाई करने के लिए नीचे कोड डालें';

  @override
  String codeVerifySentTo(String email) {
    return 'हमने 6 अंकों का कोड $email पर भेजा है';
  }

  @override
  String get codeVerifySuccess => 'ईमेल वेरिफ़ाई हो गया!';

  @override
  String get emailVerifyCodeHint => 'ईमेल में आया कोड डालें';

  @override
  String get emailVerifyCodeLabel => 'वेरिफ़िकेशन कोड';

  @override
  String get emailVerifyCodeTooShort =>
      'वेरिफ़िकेशन कोड कम से कम 6 अक्षर का होना चाहिए';

  @override
  String get emailVerifyEnterCode =>
      'अपने ईमेल में आया वेरिफ़िकेशन कोड नीचे डालें।';

  @override
  String emailVerifyError(String error) {
    return 'समस्या: $error';
  }

  @override
  String get emailVerifyFailed =>
      'वेरिफ़िकेशन नहीं हुआ। कृपया दोबारा कोशिश करें।';

  @override
  String get emailVerifyHeading => 'अपना ईमेल वेरिफ़ाई करें';

  @override
  String get emailVerifyResend => 'कोड नहीं मिला? दोबारा भेजें';

  @override
  String get emailVerifyResent => 'वेरिफ़िकेशन ईमेल दोबारा भेज दिया!';

  @override
  String get emailVerifySentTo => 'हमने वेरिफ़िकेशन कोड यहां भेजा है:';

  @override
  String get emailVerifyVerified =>
      'ईमेल वेरिफ़ाई हो गया! अब आप लॉगिन कर सकते हैं।';

  @override
  String get loginBiometricSoon => 'यह फीचर जल्द आ रहा है।';

  @override
  String get loginBiometricTooltip => 'बायोमेट्रिक लॉगिन';

  @override
  String get loginButton => 'फ्लीट में लॉगिन करें';

  @override
  String get loginCompleteProfile =>
      'आगे बढ़ने के लिए अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get loginCorporateId => 'कॉर्पोरेट आईडी';

  @override
  String get loginCorporateSoon => 'यह फीचर जल्द आ रहा है।';

  @override
  String get loginForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get loginGoogleSoon => 'यह फीचर जल्द आ रहा है।';

  @override
  String get loginHelpCenter => 'हेल्प सेंटर';

  @override
  String get loginNewToFleet => 'फ्लीट में नए हैं? ';

  @override
  String get loginOrContinueWith => 'या इससे जारी रखें';

  @override
  String get loginPendingMessage =>
      'कंपनी ओनर के स्वीकार करने का इंतज़ार करें।\n\nकंपनी ओनर आपकी रिक्वेस्ट स्वीकार कर लेंगे, तब आप लॉगिन कर पाएंगे।';

  @override
  String get loginPendingTitle => 'मंज़ूरी पेंडिंग है';

  @override
  String get loginSubtitle => 'अपने फ्लीट डैशबोर्ड में सुरक्षित तरीके से जाएं';

  @override
  String get loginSuccess => 'लॉगिन हो गया!';

  @override
  String get loginTitle => 'लॉगिन';

  @override
  String get loginUsernameHint => 'अपना यूज़रनेम डालें';

  @override
  String get loginWelcome => 'RR में आपका फिर से स्वागत है';

  @override
  String get signupAcceptTerms => 'कृपया नियम और शर्तें मानें';

  @override
  String get signupAlreadyHaveAccount => 'पहले से अकाउंट है? ';

  @override
  String get signupConfirmPassword => 'पासवर्ड दोबारा डालें';

  @override
  String get signupConfirmPasswordRequired => 'कृपया पासवर्ड दोबारा डालें';

  @override
  String get signupCreateAccount => 'अकाउंट बनाएं';

  @override
  String get signupEmailInvalid => 'सही ईमेल डालें — जैसे name@company.com';

  @override
  String get signupEmailNoAt =>
      'ईमेल में \"@\" होना चाहिए — जैसे name@company.com';

  @override
  String get signupEmailNoDomain =>
      'ईमेल में डोमेन का अंत होना चाहिए — जैसे .com या .in';

  @override
  String get signupEmailRequired => 'ईमेल ज़रूरी है';

  @override
  String get signupFullName => 'पूरा नाम';

  @override
  String get signupFullNameHint => 'राम कुमार';

  @override
  String get signupFullNameNoNumbers => 'नाम में अंक न डालें — सिर्फ़ अक्षर';

  @override
  String get signupFullNameRequired => 'पूरा नाम ज़रूरी है';

  @override
  String get signupFullNameTooShort => 'नाम कम से कम 2 अक्षर का होना चाहिए';

  @override
  String get signupLogIn => 'लॉगिन करें';

  @override
  String get signupPasswordMismatch => 'पासवर्ड मेल नहीं खाते — दोबारा डालें';

  @override
  String get signupPasswordRequired => 'पासवर्ड ज़रूरी है';

  @override
  String get signupPasswordTooShort => 'पासवर्ड कम से कम 8 अक्षर का होना चाहिए';

  @override
  String get signupPhoneChecking => 'कृपया रुकें — फ़ोन नंबर चेक हो रहा है';

  @override
  String get signupPhoneLength => 'मोबाइल नंबर ठीक 10 अंकों का होना चाहिए';

  @override
  String get signupPhoneRequired => 'फ़ोन नंबर ज़रूरी है';

  @override
  String get signupPhoneTaken => 'यह फ़ोन नंबर पहले से रजिस्टर है';

  @override
  String get signupSecurityQ => 'सुरक्षा सवाल';

  @override
  String get signupSuccessEmail =>
      'साइन अप हो गया! वेरिफ़िकेशन लिंक के लिए अपना ईमेल देखें।';

  @override
  String get signupTermsAnd => ' और ';

  @override
  String get signupTermsOfService => 'सेवा की शर्तों';

  @override
  String get signupTermsPrefix => '\"अकाउंट बनाएं\" पर क्लिक करके आप हमारी ';

  @override
  String get signupTermsSuffix => ' से सहमत होते हैं।';

  @override
  String get signupUsernameChecking => 'कृपया रुकें — यूज़रनेम चेक हो रहा है';

  @override
  String get signupUsernameHint => 'जैसे johndoe या john99';

  @override
  String get signupUsernameInvalid =>
      'यूज़रनेम में सिर्फ़ अक्षर, अंक और अंडरस्कोर हो सकते हैं';

  @override
  String get signupUsernameRequired => 'यूज़रनेम ज़रूरी है';

  @override
  String get signupUsernameTaken => 'यह यूज़रनेम पहले से लिया जा चुका है';

  @override
  String get signupUsernameTooShort =>
      'यूज़रनेम कम से कम 3 अक्षर का होना चाहिए';

  @override
  String get signupWorkEmail => 'ऑफ़िस ईमेल';

  @override
  String get authAnswerAllQuestions => 'कृपया सभी सुरक्षा सवालों के जवाब दें';

  @override
  String get authAnswerSecurityQuestions => 'अपने सुरक्षा सवालों के जवाब दें';

  @override
  String get authEnterAnswer => 'अपना जवाब लिखें';

  @override
  String get authNewPassword => 'नया पासवर्ड';

  @override
  String get authPasswordMismatch => 'पासवर्ड एक जैसे नहीं हैं';

  @override
  String get authPasswordRule =>
      'पासवर्ड कम से कम 8 अक्षर का हो, जिसमें बड़ा अक्षर, छोटा अक्षर और अंक हो';

  @override
  String authQuestionNumber(int n) {
    return 'सवाल $n';
  }

  @override
  String get changePwConfirmNew => 'नया पासवर्ड दोबारा लिखें';

  @override
  String get changePwFailed => 'पासवर्ड नहीं बदल सका';

  @override
  String get changePwIntro =>
      'अपने सुरक्षा सवालों के जवाब दें और नया पासवर्ड बनाएं। आप सभी डिवाइस से लॉग आउट हो जाएंगे और दोबारा लॉगिन करना होगा।';

  @override
  String get changePwNoUsername =>
      'आपका यूज़रनेम पता नहीं चल सका। कृपया दोबारा कोशिश करें।';

  @override
  String get changePwSuccess => 'पासवर्ड बदल गया। कृपया दोबारा लॉगिन करें।';

  @override
  String get changePwTitle => 'पासवर्ड बदलें';

  @override
  String get pwRecoveryComingSoon => 'जल्द आ रहा है';

  @override
  String get pwRecoveryConfirmPassword => 'पासवर्ड दोबारा लिखें';

  @override
  String get pwRecoveryEmailComingSoon =>
      'ईमेल से पासवर्ड रिकवरी अभी बन रही है। अभी पासवर्ड रीसेट करने के लिए सुरक्षा सवालों का इस्तेमाल करें।';

  @override
  String get pwRecoveryEnterUsername => 'कृपया अपना यूज़रनेम लिखें';

  @override
  String get pwRecoveryHeading => 'पासवर्ड भूल गए?';

  @override
  String get pwRecoveryLoadQuestions => 'सुरक्षा सवाल दिखाएं';

  @override
  String get pwRecoveryMethod => 'रिकवरी का तरीका';

  @override
  String get pwRecoveryMethodEmail => 'ईमेल';

  @override
  String get pwRecoveryMethodQuestions => 'सुरक्षा सवाल';

  @override
  String get pwRecoveryResetButton => 'पासवर्ड रीसेट करें';

  @override
  String get pwRecoveryResetSuccess =>
      'पासवर्ड रीसेट हो गया! कृपया नए पासवर्ड से लॉगिन करें।';

  @override
  String get pwRecoverySessionExpired =>
      'सेशन खत्म हो गया। कृपया दोबारा शुरू करें।';

  @override
  String get pwRecoverySetNewPassword => 'नया पासवर्ड बनाएं';

  @override
  String get pwRecoverySubtitle => 'अपने सुरक्षा सवालों से पासवर्ड रीसेट करें';

  @override
  String get pwRecoveryTitle => 'पासवर्ड रिकवरी';

  @override
  String get pwRecoveryUseQuestions => 'इसकी जगह सुरक्षा सवाल इस्तेमाल करें';

  @override
  String get pwRecoveryUsername => 'यूज़रनेम';

  @override
  String get pwRecoveryUsernameInfo =>
      'अपना यूज़रनेम लिखें, हम आपके सुरक्षा सवाल दिखाएंगे।';

  @override
  String get pwRecoveryVerifyAnswers => 'जवाब जांचें';

  @override
  String get secQuestionsAnswerMin => 'जवाब कम से कम 2 अक्षर का होना चाहिए';

  @override
  String get secQuestionsEncrypted => 'एंड-टू-एंड एन्क्रिप्टेड';

  @override
  String get secQuestionsIntro =>
      'तीन सुरक्षा सवाल चुनें, ताकि अकाउंट खुलना बंद होने पर आपकी पहचान जांची जा सके।';

  @override
  String get secQuestionsSaved => 'सुरक्षा सवाल सेव हो गए!';

  @override
  String get secQuestionsSelectAll => 'कृपया तीनों सुरक्षा सवाल चुनें';

  @override
  String get secQuestionsSelectDifferent =>
      'कृपया 3 अलग-अलग सुरक्षा सवाल चुनें';

  @override
  String get secQuestionsSelectError => 'कृपया एक सवाल चुनें';

  @override
  String get secQuestionsSelectHint => 'सुरक्षा सवाल चुनें';

  @override
  String secQuestionsStepOf(int step) {
    return 'चरण $step / 4';
  }

  @override
  String get secQuestionsTitle => 'अपना अकाउंट सुरक्षित करें';

  @override
  String get secQuestionsYourAnswer => 'आपका जवाब';

  @override
  String get userRecoveryAnswerPrompt =>
      'पहचान की जांच के लिए नीचे दिए सवालों के जवाब दें';

  @override
  String get userRecoveryContinueToLogin => 'लॉगिन पर जाएं';

  @override
  String get userRecoveryEnterDetails => 'अपनी जानकारी भरें';

  @override
  String get userRecoveryFullName => 'पूरा नाम';

  @override
  String get userRecoveryFullNameHint => 'रजिस्टर किया हुआ पूरा नाम लिखें';

  @override
  String get userRecoveryHeading => 'यूज़रनेम भूल गए?';

  @override
  String get userRecoveryInfo =>
      'पहचान की जांच के लिए आपको अपने सुरक्षा सवालों के जवाब देने होंगे।';

  @override
  String get userRecoveryPhone => 'फ़ोन नंबर';

  @override
  String get userRecoveryPhoneHint => 'रजिस्टर किया हुआ फ़ोन नंबर लिखें';

  @override
  String get userRecoveryRecovered => 'यूज़रनेम मिल गया!';

  @override
  String get userRecoverySaveNote => 'कृपया यह यूज़रनेम आगे के लिए सहेज लें';

  @override
  String get userRecoverySubtitle =>
      'पहचान की जांच करके हम आपका यूज़रनेम वापस पाने में मदद करेंगे';

  @override
  String get userRecoveryTitle => 'यूज़रनेम रिकवरी';

  @override
  String get userRecoveryVerifyButton => 'जांचें और यूज़रनेम पाएं';

  @override
  String get userRecoveryYourUsernameIs => 'आपका यूज़रनेम है:';

  @override
  String get companyCreateAddressLabel => 'पता *';

  @override
  String get companyCreateBusinessType => 'बिज़नेस का प्रकार *';

  @override
  String get companyCreateBusinessTypeError =>
      'कम से कम एक बिज़नेस प्रकार चुनें';

  @override
  String get companyCreateButton => 'कंपनी बनाएं';

  @override
  String get companyCreateCityLabel => 'शहर *';

  @override
  String get companyCreateCountryLabel => 'देश *';

  @override
  String get companyCreateEmailInvalid =>
      'सही ईमेल लिखें, जैसे name@company.com';

  @override
  String get companyCreateEmailLabel => 'बिज़नेस ईमेल *';

  @override
  String get companyCreateEmailNoAt =>
      'ईमेल में @ होना चाहिए, जैसे name@company.com';

  @override
  String get companyCreateEmailNoDomain =>
      'ईमेल के अंत में डोमेन होना चाहिए, जैसे .com या .in';

  @override
  String get companyCreateEmailRequired => 'बिज़नेस ईमेल ज़रूरी है';

  @override
  String get companyCreateFailed => 'कंपनी नहीं बन पाई';

  @override
  String get companyCreateGstinHint => '15 अक्षरों का GSTIN';

  @override
  String get companyCreateGstinInvalid => 'GSTIN का फ़ॉर्मेट सही नहीं है';

  @override
  String get companyCreateGstinLabel => 'GSTIN (ज़रूरी नहीं)';

  @override
  String get companyCreateGstinLength => 'GSTIN ठीक 15 अक्षरों का होना चाहिए';

  @override
  String get companyCreateHeading => 'अपनी कंपनी रजिस्टर करें';

  @override
  String get companyCreateHide => 'छुपाएं';

  @override
  String get companyCreateInvalidDetails => 'कंपनी की जानकारी सही नहीं है';

  @override
  String get companyCreateLegalHint =>
      'GSTIN और PAN की जानकारी अभी या बाद में कंपनी सेटिंग से जोड़ सकते हैं';

  @override
  String get companyCreateLoDesc => 'लोड की ज़रूरत डालता है और ढुलाई चाहता है';

  @override
  String get companyCreateLpDesc =>
      'फ्लीट चलाता है और लोड की ज़रूरत पूरी करता है';

  @override
  String get companyCreateNameLabel => 'कंपनी का नाम *';

  @override
  String get companyCreatePanHint => '10 अक्षरों का PAN';

  @override
  String get companyCreatePanInvalid => 'PAN का फ़ॉर्मेट सही नहीं है';

  @override
  String get companyCreatePanLabel => 'PAN नंबर (ज़रूरी नहीं)';

  @override
  String get companyCreatePanLength => 'PAN ठीक 10 अक्षरों का होना चाहिए';

  @override
  String get companyCreatePhoneLabel => 'बिज़नेस फ़ोन *';

  @override
  String get companyCreatePhoneLength =>
      'मोबाइल नंबर ठीक 10 अंकों का होना चाहिए';

  @override
  String get companyCreatePhoneRequired => 'बिज़नेस फ़ोन नंबर ज़रूरी है';

  @override
  String get companyCreatePincodeInvalid =>
      'भारत का सही 6 अंकों का पिनकोड लिखें';

  @override
  String get companyCreatePincodeLabel => 'पिनकोड *';

  @override
  String get companyCreateSectionAddress => 'पते की जानकारी';

  @override
  String get companyCreateSectionCompany => 'कंपनी की जानकारी';

  @override
  String get companyCreateSectionLegal => 'कानूनी जानकारी (ज़रूरी नहीं)';

  @override
  String get companyCreateShow => 'दिखाएं';

  @override
  String get companyCreateStateLabel => 'राज्य *';

  @override
  String get companyCreateSubheading =>
      'आप कंपनी के ओनर बनेंगे और आपके पास पूरा एडमिन एक्सेस रहेगा।';

  @override
  String get companyCreateSuccess => 'कंपनी बन गई! अब आप ओनर हैं।';

  @override
  String get companyCreateTitle => 'कंपनी बनाएं';

  @override
  String get companySearchEmptyHint => 'खोजने के लिए कम से कम 3 अक्षर लिखें';

  @override
  String get companySearchEmptyTitle => 'कंपनी खोजें';

  @override
  String get companySearchError => 'कंपनियां खोजने में गड़बड़ी हुई';

  @override
  String get companySearchHintDefault =>
      'कंपनी के नाम से खोजें (कम से कम 3 अक्षर)';

  @override
  String get companySearchHintLo => 'लोड मालिक कंपनियां खोजें...';

  @override
  String get companySearchHintLp => 'लॉजिस्टिक पार्टनर कंपनियां खोजें...';

  @override
  String get companySearchJoinButton => 'जुड़ें';

  @override
  String get companySearchJoinNotice =>
      'आप पेंडिंग यूज़र के रूप में जुड़ेंगे। कंपनी ओनर को आपकी रिक्वेस्ट मंज़ूर करनी होगी।';

  @override
  String get companySearchJoinPrompt => 'आप इससे जुड़ना चाहते हैं:';

  @override
  String get companySearchJoinTitle => 'कंपनी से जुड़ें';

  @override
  String get companySearchKeepTyping => 'लिखते रहें...';

  @override
  String get companySearchMinChars => 'कम से कम 3 अक्षर ज़रूरी हैं';

  @override
  String get companySearchNoResults => 'कोई कंपनी नहीं मिली';

  @override
  String get companySearchRegisterFailed => 'रजिस्ट्रेशन नहीं हो पाया';

  @override
  String get companySearchRegisterSuccess =>
      'रजिस्ट्रेशन हो गया! आप अभी पेंडिंग यूज़र हैं। मंज़ूरी का इंतज़ार करें।';

  @override
  String get companySearchTitle => 'कंपनी खोजें';

  @override
  String get companySearchTryOther => 'कोई और शब्द आज़माएं';

  @override
  String get companySelectCreateDesc =>
      'अपनी कंपनी रजिस्टर करें और ओनर बनें। कंपनी पर आपका पूरा कंट्रोल रहेगा और आप टीम के लोगों को बुला सकेंगे।';

  @override
  String get companySelectCreateTitle => 'नई कंपनी बनाएं';

  @override
  String get companySelectHeading => 'कंपनी से जुड़ाव';

  @override
  String get companySelectJoinDesc =>
      'मौजूदा कंपनी खोजकर उससे जुड़ें। कंपनी ओनर के मंज़ूर करने तक आप पेंडिंग यूज़र रहेंगे।';

  @override
  String get companySelectJoinTitle => 'मौजूदा कंपनी से जुड़ें';

  @override
  String get companySelectSkipDesc =>
      'बिना कंपनी के इंडिपेंडेंट यूज़र के रूप में आगे बढ़ें। कंपनी से जुड़ना या बनाना बाद में प्रोफ़ाइल से कर सकते हैं।';

  @override
  String get companySelectSkipDialogBody =>
      'आपका रजिस्ट्रेशन इंडिपेंडेंट यूज़र के रूप में होगा। कंपनी से जुड़ना या बनाना बाद में प्रोफ़ाइल सेटिंग से कर सकते हैं।\n\nआगे बढ़ें?';

  @override
  String get companySelectSkipDialogTitle => 'कंपनी चुनना छोड़ें';

  @override
  String get companySelectSkipDone =>
      'रजिस्ट्रेशन पूरा हुआ! अब आप इंडिपेंडेंट यूज़र के रूप में लॉगिन कर सकते हैं।';

  @override
  String get companySelectSkipTitle => 'अभी छोड़ें';

  @override
  String get companySelectSubheading => 'अपना अकाउंट आगे कैसे चलाना है, चुनें';

  @override
  String get companySelectTitle => 'कंपनी चुनें';

  @override
  String get profileCompleteAddress => 'पता';

  @override
  String get profileCompleteAddressMin =>
      'पता कम से कम 5 अक्षरों का होना चाहिए';

  @override
  String get profileCompleteBusinessAddressHint => 'आपके बिज़नेस का पता';

  @override
  String get profileCompleteBusinessEmail => 'बिज़नेस ईमेल';

  @override
  String get profileCompleteBusinessPhone => 'बिज़नेस फ़ोन';

  @override
  String get profileCompleteButton => 'प्रोफ़ाइल पूरी करें';

  @override
  String get profileCompleteCategoryHint =>
      'अपने बिज़नेस से मिलती-जुलती श्रेणी चुनें';

  @override
  String get profileCompleteChooseRole => 'अपनी भूमिका चुनें';

  @override
  String get profileCompleteCity => 'शहर';

  @override
  String get profileCompleteComingSoon => 'जल्द आ रहा है';

  @override
  String get profileCompleteCreateCompany => 'कंपनी बनाएं';

  @override
  String get profileCompleteCreateCompanyDesc =>
      'अपनी कंपनी रजिस्टर करें और लॉजिस्टिक पार्टनर बनें';

  @override
  String get profileCompleteDriverDesc =>
      'लाइसेंस की जानकारी के साथ चालक के रूप में रजिस्टर करें';

  @override
  String get profileCompleteDriverInfo => 'चालक की जानकारी';

  @override
  String get profileCompleteEnterCompanyName => 'कंपनी का नाम लिखें';

  @override
  String get profileCompleteEnterLicense => 'अपना लाइसेंस नंबर लिखें';

  @override
  String get profileCompleteEnterLicenseExpiry =>
      'अपने लाइसेंस की समाप्ति तारीख लिखें';

  @override
  String get profileCompleteEnterPan => 'अपना PAN कार्ड नंबर लिखें';

  @override
  String get profileCompleteEnterYourCompanyName => 'अपनी कंपनी का नाम लिखें';

  @override
  String get profileCompleteFailed => 'प्रोफ़ाइल पूरी नहीं हो पाई';

  @override
  String get profileCompleteFieldExecutiveDesc =>
      'मौके पर ट्रिप के स्टेज और वाहनों की स्थिति संभालें';

  @override
  String get profileCompleteGstOptional => 'GST नंबर (ज़रूरी नहीं)';

  @override
  String get profileCompleteIndependentDesc =>
      'बिना कंपनी के बुनियादी सुविधाएं इस्तेमाल करें';

  @override
  String get profileCompleteJoinTransporter => 'ट्रांसपोर्टर के रूप में जुड़ें';

  @override
  String get profileCompleteJoinTransporterDesc =>
      'इंडिपेंडेंट ट्रांसपोर्टर के रूप में रजिस्टर करें और दिए गए ट्रिप की लोडिंग स्लिप अपलोड करें';

  @override
  String get profileCompleteJoinWorker => 'वर्कर के रूप में जुड़ें';

  @override
  String get profileCompleteJoinWorkerDesc =>
      'मौजूदा कंपनी में वर्कर के रूप में जुड़ें (ओनर की मंज़ूरी ज़रूरी)';

  @override
  String get profileCompleteLicenseExpiry =>
      'लाइसेंस की समाप्ति तारीख (YYYY-MM-DD) *';

  @override
  String get profileCompleteLicenseNumber => 'लाइसेंस नंबर *';

  @override
  String get profileCompleteLoCompany => 'लोड मालिक कंपनी';

  @override
  String get profileCompleteLoCompanyWorkDesc => 'लोड वाली कंपनी में काम करें';

  @override
  String get profileCompleteLoadProviderCompany => 'लोड देने वाली कंपनी';

  @override
  String get profileCompleteLoadProviderDesc => 'आपके पास ढुलाई के लिए माल है';

  @override
  String get profileCompleteLoadReceiverCompany => 'लोड पाने वाली कंपनी';

  @override
  String get profileCompleteLoadReceiverDesc =>
      'आप माल पाते हैं — आप कंसाइनी हैं';

  @override
  String get profileCompleteLpCompany => 'लॉजिस्टिक पार्टनर कंपनी';

  @override
  String get profileCompleteLpCompanyCreateDesc =>
      'आप ढुलाई के लिए वाहनों का फ्लीट चलाते हैं — आपकी भूमिका: लॉजिस्टिक पार्टनर';

  @override
  String get profileCompleteLpCompanyWorkDesc =>
      'वाहन/लॉजिस्टिक कंपनी में काम करें (फील्ड एक्ज़ीक्यूटिव या RR ऑपरेशंस)';

  @override
  String get profileCompletePanLabel => 'PAN कार्ड नंबर *';

  @override
  String get profileCompletePermanentWarning =>
      'यह फ़ैसला पक्का है, बाद में बदला नहीं जा सकेगा।';

  @override
  String get profileCompletePincode => 'पिनकोड (6 अंक)';

  @override
  String get profileCompleteRequestSent =>
      'रिक्वेस्ट भेज दी गई! कंपनी ओनर के स्वीकार करने का इंतज़ार करें।';

  @override
  String get profileCompleteRrOpsDesc =>
      'RR सिंक और RR सिस्टम में ट्रिप का डेटा भरने का काम संभालें';

  @override
  String get profileCompleteSearchCompany => 'कंपनी खोजें';

  @override
  String profileCompleteSearchFailed(String error) {
    return 'कंपनियां खोजने में गड़बड़ी: $error';
  }

  @override
  String get profileCompleteSearchHint => 'कम से कम 3 अक्षर लिखें';

  @override
  String get profileCompleteSelectCompanyToJoin => 'जुड़ने के लिए कंपनी चुनें';

  @override
  String get profileCompleteSelectCompanyType => 'कंपनी का प्रकार चुनें';

  @override
  String get profileCompleteSelectCompanyTypeTitle => 'कंपनी का प्रकार चुनें';

  @override
  String get profileCompleteSelectRole => 'अपनी भूमिका चुनें';

  @override
  String get profileCompleteSelectWorkerType => 'अपना वर्कर प्रकार चुनें';

  @override
  String get profileCompleteSelectYourRole => 'अपनी भूमिका चुनें';

  @override
  String profileCompleteSelectedCompany(String name) {
    return 'चुनी गई: $name';
  }

  @override
  String get profileCompleteSessionExpired =>
      'सेशन खत्म हो गया। फिर से लॉगिन करें।';

  @override
  String get profileCompleteState => 'राज्य';

  @override
  String get profileCompleteSuccess => 'प्रोफ़ाइल पूरी हो गई!';

  @override
  String get profileCompleteTitle => 'प्रोफ़ाइल पूरी करें';

  @override
  String get profileCompleteTransporterCompanyHint =>
      'आपकी ट्रांसपोर्ट कंपनी का नाम';

  @override
  String get profileCompleteTransporterDetails => 'ट्रांसपोर्टर की जानकारी';

  @override
  String get profileCompleteTransporterSub =>
      'अपने ट्रांसपोर्ट बिज़नेस की जानकारी लिखें';

  @override
  String get profileCompleteWhatCompanyType =>
      'आप किस तरह की कंपनी रजिस्टर कर रहे हैं?';

  @override
  String get profileCompleteWhatWillYouDo =>
      'लॉजिस्टिक कंपनी में आप क्या काम करेंगे?';

  @override
  String get profileCompleteWorkForWhichType =>
      'आप किस तरह की कंपनी में काम करना चाहते हैं?';

  @override
  String get roleDriver => 'चालक';

  @override
  String get roleFieldExecutive => 'फील्ड एक्ज़ीक्यूटिव';

  @override
  String get roleIndependentUser => 'इंडिपेंडेंट यूज़र';

  @override
  String get roleLoadOwner => 'लोड मालिक';

  @override
  String get roleLogisticPartner => 'लॉजिस्टिक पार्टनर';

  @override
  String get roleRrOperations => 'RR ऑपरेशंस';

  @override
  String get ongoingCardActive => 'चालू';

  @override
  String get ongoingCardAmount => 'रकम';

  @override
  String get ongoingCardBiltyNo => 'बिल्टी नं.';

  @override
  String get ongoingCardCompleteBody =>
      'इससे ट्रिप पूरी मानी जाएगी और लोड मालिक को खबर जाएगी। इसे वापस नहीं किया जा सकता।';

  @override
  String get ongoingCardCompleteDone =>
      'ट्रिप पूरी हो गई। लोड मालिक को खबर दे दी गई।';

  @override
  String get ongoingCardCompleteLocked =>
      'ट्रिप पूरी करने का बटन स्टेज 5 के बाद ही चलेगा';

  @override
  String get ongoingCardCompleteTitle => 'ट्रिप पूरी करें?';

  @override
  String get ongoingCardCompleteTrip => 'ट्रिप पूरी करें';

  @override
  String get ongoingCardConfirm => 'पक्का करें';

  @override
  String get ongoingCardDone => 'पूरा';

  @override
  String get ongoingCardFailed => 'फेल';

  @override
  String ongoingCardGoToStage(String stage, String name) {
    return 'स्टेज $stage पर जाएं  ·  $name';
  }

  @override
  String ongoingCardInTransitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रिप रास्ते में',
      one: '1 ट्रिप रास्ते में',
    );
    return '$_temp0';
  }

  @override
  String get ongoingCardInvoice => 'इनवॉइस';

  @override
  String get ongoingCardLoadItem => 'लोड आइटम';

  @override
  String get ongoingCardLocateTrip => 'ट्रिप का लोकेशन देखें';

  @override
  String get ongoingCardNoVehicle => 'वाहन नहीं है';

  @override
  String get ongoingCardOngoingTrips => 'चालू ट्रिप';

  @override
  String get ongoingCardRrSync => 'RR सिंक';

  @override
  String get ongoingCardStage0CompleteS1 =>
      'स्टेज 0 · RR सिंक के लिए स्टेज 1 पूरा करें';

  @override
  String get ongoingCardStage0NotSynced => 'स्टेज 0 · RR में सिंक नहीं हुआ';

  @override
  String get ongoingCardStageComplianceCheck => 'कंप्लायंस जांच';

  @override
  String get ongoingCardStageDieselReceipt => 'डीज़ल रसीद';

  @override
  String get ongoingCardStageExitCheck => 'निकासी जांच';

  @override
  String get ongoingCardStageFactoryArrival => 'फैक्ट्री में आगमन';

  @override
  String get ongoingCardStageTruckRegistration => 'ट्रक रजिस्ट्रेशन';

  @override
  String get ongoingCardSyncFailed => 'RR सिंक नहीं हो पाया';

  @override
  String get ongoingCardTripCompleted => 'ट्रिप पूरी हुई';

  @override
  String get ongoingCardTripNumber => 'ट्रिप नंबर';

  @override
  String get ongoingCardViewAll => 'सभी देखें';

  @override
  String get ongoingCardViewDetails => 'विवरण देखें';

  @override
  String get ongoingCardWeight => 'वज़न';

  @override
  String get recvDocsAttachImageRequired => 'कृपया रिसीविंग शीट की फ़ोटो लगाएं';

  @override
  String get recvDocsAttachPhoto => 'रिसीविंग शीट की फ़ोटो लगाएं';

  @override
  String recvDocsBy(String name) {
    return 'अपलोड करने वाला: $name';
  }

  @override
  String get recvDocsChooseGallery => 'गैलरी से चुनें';

  @override
  String get recvDocsDate => 'तारीख';

  @override
  String get recvDocsDeleteBody =>
      'इससे फ़ोटो हमेशा के लिए हट जाएगी और वापस नहीं आएगी।';

  @override
  String recvDocsDeleteFailed(String error) {
    return 'हटा नहीं पाए: $error';
  }

  @override
  String get recvDocsDeleteTitle => 'रिसीविंग डॉक हटाएं?';

  @override
  String get recvDocsEditTitle => 'रिसीविंग डॉक एडिट करें';

  @override
  String get recvDocsEmpty => 'अभी कोई रिसीविंग डॉक अपलोड नहीं हुआ';

  @override
  String get recvDocsEmptyForDate => 'उस तारीख का कोई रिसीविंग डॉक नहीं मिला';

  @override
  String recvDocsLoadFailed(String error) {
    return 'लोड नहीं हो पाया: $error';
  }

  @override
  String get recvDocsOpenDownload => 'खोलें / डाउनलोड करें';

  @override
  String get recvDocsPickDate => 'तारीख चुनें';

  @override
  String get recvDocsPickDateRequired =>
      'कृपया वह तारीख चुनें जिसकी यह रिसीविंग शीट है';

  @override
  String recvDocsPickImageFailed(String error) {
    return 'फ़ोटो नहीं चुन पाए: $error';
  }

  @override
  String get recvDocsSaveChanges => 'बदलाव सेव करें';

  @override
  String get recvDocsSearchByDate => 'तारीख से खोजें';

  @override
  String get recvDocsSheetDate => 'यह शीट किस तारीख की है';

  @override
  String get recvDocsTakePhoto => 'फ़ोटो खींचें';

  @override
  String get recvDocsTitle => 'रिसीविंग डॉक्स';

  @override
  String get recvDocsUpload => 'अपलोड करें';

  @override
  String get recvDocsUploadNew => 'नया अपलोड करें';

  @override
  String get recvDocsUploadTitle => 'रिसीविंग डॉक अपलोड करें';

  @override
  String get recvDocsUploadedBy => 'अपलोड करने वाला';

  @override
  String get recvDocsViewTitle => 'रिसीविंग डॉक';

  @override
  String get rrConnectionActionConnect => '· कनेक्ट';

  @override
  String get rrConnectionActionDisconnect => '· डिसकनेक्ट';

  @override
  String get rrConnectionConnected => 'कनेक्टेड';

  @override
  String get rrConnectionDisconnect => 'डिसकनेक्ट करें';

  @override
  String get rrConnectionDisconnectBody =>
      'जब तक कोई दोबारा कनेक्ट नहीं करता, आपकी कंपनी में सभी के लिए सिंक और प्री-फ़िल बंद रहेगा।';

  @override
  String get rrConnectionDisconnectTitle => 'RR से डिसकनेक्ट करें?';

  @override
  String get rrConnectionDisconnected => 'डिसकनेक्टेड';

  @override
  String get rrConnectionExpiringSoon => 'जल्द खत्म होगा';

  @override
  String get rrLoginButton => 'साइन इन';

  @override
  String get rrLoginEnterCredentials => 'अपना RR यूज़रनेम और पासवर्ड डालें';

  @override
  String get rrLoginFailed => 'लॉगिन नहीं हो पाया';

  @override
  String get rrLoginSubtitle =>
      'आगे बढ़ने के लिए अपना RollingRadius यूज़रनेम और पासवर्ड डालें।';

  @override
  String get rrLoginTitle => 'RR में साइन इन करें';

  @override
  String rrLoginUnexpectedError(String error) {
    return 'कुछ गड़बड़ हो गई: $error';
  }

  @override
  String get rrLoginUsernameLabel => 'यूज़रनेम / फ़ोन';

  @override
  String get rrSearchNoMatches => 'कोई नतीजा नहीं मिला';

  @override
  String get tripCardAllowFeStage1 => 'फील्ड एक्ज़ीक्यूटिव को स्टेज 1 भरने दें';

  @override
  String get tripCardAlreadyInRecords => 'पहले से रिकॉर्ड्स में है';

  @override
  String get tripCardAwaitCompanyConfirm =>
      'इस ट्रिप को अपनी कंपनी से कन्फ़र्म होने दें';

  @override
  String tripCardBiltyNo(String number) {
    return 'बिल्टी नं: $number';
  }

  @override
  String get tripCardBookingConfirmFailed => 'बुकिंग कन्फ़र्म नहीं हो पाई';

  @override
  String get tripCardBookingConfirmed => 'बुकिंग कन्फ़र्म हो गई';

  @override
  String get tripCardBookingNeedsConfirm => 'बुकिंग कन्फ़र्म करनी है';

  @override
  String get tripCardCompletedViewOnly =>
      'पूरी हो चुकी ट्रिप सिर्फ़ देख सकते हैं';

  @override
  String get tripCardConfirmBooking => 'बुकिंग कन्फ़र्म करें';

  @override
  String tripCardCreated(String when) {
    return 'बनाई गई $when';
  }

  @override
  String get tripCardDismiss => 'बंद करें';

  @override
  String get tripCardEditTrip => 'ट्रिप एडिट करें';

  @override
  String get tripCardLabelAxleType => 'एक्सल टाइप';

  @override
  String get tripCardLabelBiltyNumber => 'बिल्टी नंबर';

  @override
  String get tripCardLabelBodyType => 'बॉडी टाइप';

  @override
  String get tripCardLabelConsignee => 'कंसाइनी';

  @override
  String get tripCardLabelConsigneeGstin => 'कंसाइनी GSTIN';

  @override
  String get tripCardLabelConsignor => 'कंसाइनर';

  @override
  String get tripCardLabelConsignorGstin => 'कंसाइनर GSTIN';

  @override
  String get tripCardLabelCreatedAt => 'बनाने का समय';

  @override
  String get tripCardLabelDepotCode => 'डिपो कोड';

  @override
  String get tripCardLabelDescription => 'विवरण';

  @override
  String get tripCardLabelMaterial => 'माल';

  @override
  String get tripCardLabelPartLoad => 'पार्ट लोड';

  @override
  String get tripCardLabelPickupAddress => 'पिकअप का पता';

  @override
  String get tripCardLabelTotalInvoiceValue => 'कुल इनवॉइस वैल्यू';

  @override
  String get tripCardLabelUnloadAddress => 'अनलोड का पता';

  @override
  String get tripCardLabelVehicle => 'वाहन';

  @override
  String get tripCardLabelWeight => 'वज़न';

  @override
  String get tripCardLabelWheels => 'पहिए';

  @override
  String get tripCardMoveToRecords => 'रिकॉर्ड्स में भेजें';

  @override
  String get tripCardMoveToRecordsFailed => 'ट्रिप रिकॉर्ड्स में नहीं जा पाई';

  @override
  String get tripCardMovedToRecords => 'ट्रिप रिकॉर्ड्स में चली गई';

  @override
  String tripCardResumeConflict(String driver) {
    return 'फिर शुरू नहीं हो सकती — $driver को पहले ही नई ट्रिप दी जा चुकी है';
  }

  @override
  String get tripCardResumeFailed => 'चालक की ट्रैकिंग फिर शुरू नहीं हो पाई';

  @override
  String get tripCardResumeTracking =>
      'इस ट्रिप की चालक ट्रैकिंग फिर शुरू करें';

  @override
  String get tripCardRetryBookingFailed =>
      'बुकिंग दोबारा नहीं हो पाई — फिर कोशिश करें';

  @override
  String get tripCardStillFailing =>
      'अभी भी नहीं हो रहा — थोड़ी देर बाद देखें या दोबारा कोशिश करें';

  @override
  String tripCardStillFailingWith(String error) {
    return 'अभी भी नहीं हो रहा: $error';
  }

  @override
  String get tripCardStopTracking => 'इस ट्रिप की चालक ट्रैकिंग बंद करें';

  @override
  String tripCardStopTrackingBody(String driver) {
    return 'इससे $driver इस ट्रिप से मुक्त हो जाएंगे और उन्हें नई ट्रिप दी जा सकेगी। आप बाद में इस ट्रिप की ट्रैकिंग फिर शुरू कर सकते हैं, पर तभी जब तब तक इस चालक को कोई नई ट्रिप न मिली हो। आगे बढ़ें?';
  }

  @override
  String get tripCardStopTrackingButton => 'ट्रैकिंग बंद करें';

  @override
  String get tripCardStopTrackingFailed => 'चालक की ट्रैकिंग बंद नहीं हो पाई';

  @override
  String get tripCardStopTrackingTitle => 'चालक की ट्रैकिंग बंद करें';

  @override
  String get tripCardSyncedToRr => 'RR में सिंक हो गया';

  @override
  String get tripCardTheDriver => 'चालक';

  @override
  String get tripCardThisDriver => 'यह चालक';

  @override
  String get tripCardTrackDriver => 'चालक का लोकेशन देखें';

  @override
  String get tripCardTrackingResumed =>
      'इस ट्रिप के लिए चालक की ट्रैकिंग फिर शुरू हो गई';

  @override
  String get tripCardTrackingStopped =>
      'इस ट्रिप के लिए चालक की ट्रैकिंग बंद हो गई';

  @override
  String get tripCardTripInfo => 'ट्रिप की जानकारी';

  @override
  String get tripCardUpdateFailed => 'अपडेट नहीं हो पाया — फिर कोशिश करें';

  @override
  String get tripSearchHint => 'ट्रिप नंबर से खोजें';

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
  String get driverAssignedDriver => 'चालक';

  @override
  String get driverAssignedGoToTrip => 'ट्रिप असाइनमेंट पर जाएं';

  @override
  String get driverAssignedHeading => 'वाहन सफलतापूर्वक असाइन हुआ';

  @override
  String get driverAssignedReturn => 'फ्लीट ओवरव्यू पर लौटें';

  @override
  String get driverAssignedSubtitle =>
      'चालक और वाहन अब सिस्टम में जुड़ गए हैं और डिस्पैच के लिए तैयार हैं।';

  @override
  String get driverAssignedTitle => 'पुष्टि';

  @override
  String driverAssignedUnitId(String id) {
    return 'यूनिट ID: $id';
  }

  @override
  String get driverAssignedVehicle => 'वाहन';

  @override
  String get driverAssignedViewVehicle => 'वाहन की जानकारी देखें';

  @override
  String get driverDashBAddress => 'पता';

  @override
  String get driverDashBAge => 'उम्र';

  @override
  String driverDashBAgeYears(int years) {
    return '$years साल';
  }

  @override
  String get driverDashBAssignedBy => 'असाइन करने वाला';

  @override
  String get driverDashBAssignedOn => 'असाइन की तारीख';

  @override
  String get driverDashBAssignedVehicle => 'असाइन किया गया वाहन';

  @override
  String get driverDashBAuthority => 'जारी करने वाला प्राधिकरण';

  @override
  String get driverDashBClass => 'श्रेणी';

  @override
  String get driverDashBCountry => 'देश';

  @override
  String get driverDashBDob => 'जन्म तिथि';

  @override
  String get driverDashBEmail => 'ईमेल';

  @override
  String get driverDashBEmergencyContact => 'आपातकालीन संपर्क';

  @override
  String get driverDashBEmployeeId => 'कर्मचारी ID';

  @override
  String driverDashBEmployeeIdShort(String id) {
    return 'ID: $id';
  }

  @override
  String get driverDashBExpired => 'समाप्त';

  @override
  String driverDashBExpiringIn(int days) {
    return '$days दिन में समाप्त';
  }

  @override
  String get driverDashBExpiryDate => 'समाप्ति की तारीख';

  @override
  String get driverDashBFuel => 'ईंधन';

  @override
  String get driverDashBFuelReceipt => 'डीज़ल\nरसीद';

  @override
  String get driverDashBFullName => 'पूरा नाम';

  @override
  String get driverDashBIssueDate => 'जारी होने की तारीख';

  @override
  String get driverDashBIssuingState => 'जारी करने वाला राज्य';

  @override
  String get driverDashBLicenseDetails => 'लाइसेंस की जानकारी';

  @override
  String driverDashBLicenseExpiredOn(String date) {
    return 'लाइसेंस $date को खत्म हो गया';
  }

  @override
  String driverDashBLicenseExpiresOn(String date) {
    return 'लाइसेंस $date को खत्म होगा — जल्दी रिन्यू करें';
  }

  @override
  String get driverDashBLicenseNumber => 'लाइसेंस नंबर';

  @override
  String get driverDashBName => 'नाम';

  @override
  String get driverDashBNoEmergency => 'कोई आपातकालीन संपर्क दर्ज नहीं है';

  @override
  String get driverDashBNoLicense => 'कोई लाइसेंस दर्ज नहीं है';

  @override
  String get driverDashBNoVehicle => 'कोई वाहन असाइन नहीं है';

  @override
  String get driverDashBNotFound => 'चालक नहीं मिला';

  @override
  String get driverDashBPersonalInfo => 'व्यक्तिगत जानकारी';

  @override
  String get driverDashBPhone => 'फ़ोन';

  @override
  String get driverDashBQuickActions => 'क्विक एक्शन';

  @override
  String get driverDashBRegNo => 'रजिस्ट्रेशन नं.';

  @override
  String get driverDashBRelationship => 'रिश्ता';

  @override
  String get driverDashBReportIssue => 'समस्या\nबताएं';

  @override
  String get driverDashBSafetyCheck => 'सुरक्षा\nजांच';

  @override
  String get driverDashBStatus => 'स्थिति';

  @override
  String get driverDashBTitle => 'चालक';

  @override
  String get driverDashBType => 'प्रकार';

  @override
  String driverDashBValidDaysLeft(int days) {
    return 'मान्य ($days दिन बाकी)';
  }

  @override
  String get driverDashBViewVehicle => 'वाहन की जानकारी देखें';

  @override
  String get driverOnboardCertDefensive => 'डिफ़ेंसिव ड्राइविंग';

  @override
  String get driverOnboardCertDetails => 'सर्टिफ़िकेशन की जानकारी';

  @override
  String get driverOnboardCertFirstAid => 'फ़र्स्ट एड/सीपीआर';

  @override
  String get driverOnboardCertFuel => 'ईंधन बचत ट्रेनिंग';

  @override
  String get driverOnboardCertHazmat => 'हैज़मैट हैंडलिंग';

  @override
  String get driverOnboardCompletionDate => 'पूरा होने की तारीख';

  @override
  String get driverOnboardCoreCerts => 'मुख्य सर्टिफ़िकेशन';

  @override
  String get driverOnboardDoneAssignVehicle => 'वाहन असाइन करें';

  @override
  String get driverOnboardDoneDashboard => 'डैशबोर्ड पर जाएं';

  @override
  String get driverOnboardDoneEmployeeId => 'कर्मचारी ID';

  @override
  String get driverOnboardDoneHeading => 'चालक सफलतापूर्वक जोड़ा गया';

  @override
  String get driverOnboardDoneNotified =>
      'चालक को ईमेल और SMS से सूचित कर दिया गया है';

  @override
  String get driverOnboardDoneReady => 'असाइनमेंट के लिए तैयार';

  @override
  String get driverOnboardDoneStatus => 'स्थिति';

  @override
  String get driverOnboardDoneSubtitle =>
      'चालक का रजिस्ट्रेशन पूरा और वेरिफ़ाई हो गया है।';

  @override
  String get driverOnboardDoneViewProfile => 'चालक की प्रोफ़ाइल देखें';

  @override
  String get driverOnboardExpirationDate => 'समाप्ति की तारीख';

  @override
  String get driverOnboardHeading => 'ट्रेनिंग और सर्टिफ़िकेशन';

  @override
  String get driverOnboardNextReview => 'आगे: रिव्यू';

  @override
  String get driverOnboardPercentComplete => '66% पूरा';

  @override
  String get driverOnboardSelectDate => 'तारीख चुनें';

  @override
  String get driverOnboardSkills => 'खास स्किल';

  @override
  String get driverOnboardSkillsHelp =>
      'कोई और संबंधित योग्यता या उपकरण का अनुभव लिखें (जैसे फ़ोर्कलिफ़्ट लाइसेंस, रेफ्रिजरेटेड माल की हैंडलिंग)।';

  @override
  String get driverOnboardSkillsHint => 'अपनी अतिरिक्त स्किल यहाँ लिखें...';

  @override
  String get driverOnboardStep => 'चरण 2 / 3';

  @override
  String get driverOnboardSubtitle =>
      'कृपया अपने प्रोफ़ेशनल सर्टिफ़िकेशन और खास स्किल की जानकारी दें।';

  @override
  String get driverOnboardTitle => 'ऑनबोर्डिंग';

  @override
  String get driverOnboardUploadCert => 'सर्टिफ़िकेट अपलोड करें (PDF/JPG)';

  @override
  String get driverSelectVehicleAssigningTo => 'असाइन किया जा रहा है';

  @override
  String driverSelectVehicleAvailableCount(int count) {
    return '$count उपलब्ध वाहन';
  }

  @override
  String get driverSelectVehicleChange => 'बदलें';

  @override
  String get driverSelectVehicleFilterAll => 'सभी यूनिट';

  @override
  String get driverSelectVehicleFilterHeavy => 'हेवी ड्यूटी';

  @override
  String get driverSelectVehicleFilterLowFuel => 'कम ईंधन';

  @override
  String get driverSelectVehicleFilterMedium => 'मीडियम ड्यूटी';

  @override
  String get driverSelectVehicleFuelLevel => 'ईंधन स्तर';

  @override
  String get driverSelectVehicleOdometer => 'ओडोमीटर';

  @override
  String get driverSelectVehicleSearchHint => 'यूनिट ID, VIN या मॉडल खोजें...';

  @override
  String get driverSelectVehicleSelect => 'वाहन चुनें';

  @override
  String get driverSelectVehicleSort => 'क्रम';

  @override
  String get driverSelectVehicleStatusAvailable => 'उपलब्ध';

  @override
  String get driverSelectVehicleStatusLowFuel => 'कम ईंधन';

  @override
  String get driverSelectVehicleTitle => 'वाहन असाइन करें';

  @override
  String get driverDashActiveTripBadge => 'एक्टिव ट्रिप';

  @override
  String get driverDashDetails => 'जानकारी';

  @override
  String get driverDashFrom => 'से';

  @override
  String get driverDashGoodAfternoon => 'शुभ दोपहर';

  @override
  String get driverDashGoodEvening => 'शुभ संध्या';

  @override
  String get driverDashGoodMorning => 'सुप्रभात';

  @override
  String get driverDashNoActiveTrip => 'कोई एक्टिव ट्रिप नहीं';

  @override
  String get driverDashNoOngoingTrips => 'अभी आपकी कोई ट्रिप जारी नहीं है।';

  @override
  String get driverDashOngoingWarning =>
      'आपकी ट्रिप अभी जारी है — कृपया लोकेशन चालू रखें।';

  @override
  String get driverDashProgress => 'प्रगति';

  @override
  String get driverDashTapToEnable => 'चालू करने के लिए टैप करें';

  @override
  String get driverDashTo => 'तक';

  @override
  String get driverDashTrackingOn => 'ट्रैकिंग चालू';

  @override
  String get driverHomeCurrentTrip => 'मौजूदा ट्रिप';

  @override
  String get driverHomeDropoff => 'ड्रॉपऑफ़';

  @override
  String driverHomeEta(String time) {
    return 'पहुंचने का समय: $time';
  }

  @override
  String driverHomeGreeting(String name) {
    return 'सुप्रभात, $name 👋';
  }

  @override
  String get driverHomeInProgress => 'जारी है';

  @override
  String get driverHomeNavigateDropoff => 'ड्रॉपऑफ़ तक नेविगेट करें';

  @override
  String get driverHomeOnDuty => 'ड्यूटी पर';

  @override
  String get driverHomePickup => 'पिकअप';

  @override
  String get driverHomeScheduled => 'निर्धारित';

  @override
  String get driverHomeStatDone => 'पूरी';

  @override
  String get driverHomeStatLeft => 'बाकी';

  @override
  String get driverHomeStatTotal => 'कुल';

  @override
  String get driverHomeTomorrow => 'कल';

  @override
  String get driverHomeUpcomingTrips => 'आने वाली ट्रिप';

  @override
  String get driverHomeViewAll => 'सभी देखें';

  @override
  String get driverVehicleAssignedUnit => 'सौंपा गया वाहन';

  @override
  String get driverVehicleAvailable => 'उपलब्ध';

  @override
  String get driverVehicleBattery => 'बैटरी';

  @override
  String get driverVehicleBrakeInspection => 'ब्रेक जाँच';

  @override
  String get driverVehicleClassA => 'क्लास A';

  @override
  String get driverVehicleDiesel => 'डीज़ल';

  @override
  String get driverVehicleEngineTemp => 'इंजन तापमान';

  @override
  String get driverVehicleFuelLevel => 'फ्यूल लेवल';

  @override
  String get driverVehicleHeavyDuty => 'हेवी ड्यूटी';

  @override
  String get driverVehicleLastOilChange => 'पिछली बार तेल बदला';

  @override
  String get driverVehicleLogRefuel => 'ईंधन भरना दर्ज करें';

  @override
  String get driverVehicleMaintenanceStatus => 'मेंटेनेंस स्थिति';

  @override
  String get driverVehicleNextServiceDue => 'अगली सर्विस';

  @override
  String get driverVehicleNormal => 'सामान्य';

  @override
  String get driverVehicleOdometer => 'ओडोमीटर';

  @override
  String get driverVehiclePreTripCheck => 'ट्रिप से पहले जाँच';

  @override
  String get driverVehicleQuickActions => 'क्विक एक्शन';

  @override
  String get driverVehicleReportIssue => 'समस्या बताएं';

  @override
  String get driverVehicleTitle => 'मेरा वाहन';

  @override
  String get driverVehicleUpToDate => 'अप टू डेट';

  @override
  String get driverVehicleViewHistory => 'हिस्ट्री देखें';

  @override
  String get feDashAboutRr => 'RR Logistics के बारे में';

  @override
  String get feDashActiveTrips => 'एक्टिव ट्रिप';

  @override
  String feDashActiveTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एक्टिव ट्रिप',
    );
    return '$_temp0';
  }

  @override
  String get feDashClearAll => 'सभी हटाएं';

  @override
  String feDashDaysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get feDashHelpComingSoon => 'यह फीचर जल्द आ रहा है।';

  @override
  String get feDashHelpSupport => 'सहायता';

  @override
  String feDashHoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String get feDashJustNow => 'अभी';

  @override
  String get feDashLive => 'लाइव';

  @override
  String get feDashLoadTripsFailed => 'ट्रिप लोड नहीं हो सकीं';

  @override
  String get feDashLogOut => 'लॉग आउट';

  @override
  String get feDashLogout => 'लॉग आउट';

  @override
  String get feDashMarkAllRead => 'सभी पढ़ा हुआ करें';

  @override
  String feDashMinutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String get feDashMore => 'और';

  @override
  String get feDashNavDashboard => 'डैशबोर्ड';

  @override
  String get feDashNavProfile => 'प्रोफ़ाइल';

  @override
  String get feDashNavRecords => 'रिकॉर्ड्स';

  @override
  String get feDashNavigation => 'नेविगेशन';

  @override
  String get feDashNoActiveTrips => 'कोई एक्टिव ट्रिप नहीं';

  @override
  String get feDashNoActiveTripsHint => 'नई ट्रिप मिलने पर आपको सूचना मिलेगी';

  @override
  String get feDashNoNotifications => 'कोई सूचना नहीं';

  @override
  String get feDashNoSyncedTrips => 'अभी तक कोई सिंक ट्रिप नहीं';

  @override
  String feDashNoTripsMatch(String query) {
    return '\"$query\" से कोई ट्रिप नहीं मिली';
  }

  @override
  String get feDashNotifications => 'सूचनाएं';

  @override
  String get feDashRecordsTitle => 'RR वेब रिकॉर्ड्स';

  @override
  String get feDashSearchBilty => 'बिल्टी नंबर से खोजें';

  @override
  String get feDashSettings => 'सेटिंग्स';

  @override
  String feDashSyncedCount(int count) {
    return '$count सिंक हुईं';
  }

  @override
  String get feDashSyncedTrips => 'सिंक हुई ट्रिप';

  @override
  String get feDashSyncedTripsHint => 'RR वेब पर सिंक हुई ट्रिप यहां दिखेंगी';

  @override
  String feDashUpdatedAt(String time) {
    return 'अपडेट $time';
  }

  @override
  String feDashWelcomeBack(String name) {
    return 'वापसी पर स्वागत है, $name';
  }

  @override
  String get feDashWorkerFallback => 'वर्कर';

  @override
  String get stageCommonAdd => 'जोड़ें';

  @override
  String get stageCommonAlreadyOnRr => 'RR पर पहले से है';

  @override
  String get stageCommonBackToDashboard => 'डैशबोर्ड पर वापस जाएं';

  @override
  String get stageCommonBrowsePhotos => 'फ़ोटो में से चुनें';

  @override
  String get stageCommonCamera => 'कैमरा';

  @override
  String get stageCommonCameraDenied =>
      'अनुमति नहीं मिली। सेटिंग्स में इस ऐप के लिए कैमरा की अनुमति दें और फिर कोशिश करें।';

  @override
  String get stageCommonCameraFailed =>
      'कैमरा नहीं खुल सका। कृपया दोबारा कोशिश करें।';

  @override
  String get stageCommonCameraOrGallery => 'कैमरा या गैलरी';

  @override
  String get stageCommonChooseGallery => 'गैलरी से चुनें';

  @override
  String get stageCommonCompleteStage => 'स्टेज पूरा करें ✓';

  @override
  String get stageCommonConfirmWeight => 'वज़न कन्फर्म करें';

  @override
  String stageCommonDraftSaveFailed(String status, String detail) {
    return 'ड्राफ्ट सेव नहीं हुआ ($status): $detail';
  }

  @override
  String get stageCommonDriver => 'चालक';

  @override
  String stageCommonEg(String value) {
    return 'जैसे $value';
  }

  @override
  String stageCommonFailedWith(String error) {
    return 'नहीं हो सका: $error';
  }

  @override
  String stageCommonFieldRequired(String label) {
    return '$label ज़रूरी है';
  }

  @override
  String get stageCommonFilePickerFailed =>
      'फ़ाइल नहीं चुनी जा सकी। कृपया दोबारा कोशिश करें।';

  @override
  String stageCommonFutureNotAllowed(String label) {
    return '$label आने वाली तारीख/समय नहीं हो सकता — अभी का समय लगाया गया';
  }

  @override
  String get stageCommonGallery => 'गैलरी';

  @override
  String get stageCommonGalleryFailed =>
      'गैलरी नहीं खुल सकी। कृपया दोबारा कोशिश करें।';

  @override
  String stageCommonHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String get stageCommonImageLoadFailed => 'फ़ोटो लोड नहीं हो सकी';

  @override
  String get stageCommonImageSelected => 'फ़ोटो चुन ली गई';

  @override
  String get stageCommonInsideFactory => 'फैक्ट्री के अंदर';

  @override
  String get stageCommonJustNow => 'अभी अभी';

  @override
  String stageCommonLastSaved(String time) {
    return 'आख़िरी बार सेव: $time';
  }

  @override
  String get stageCommonLoad => 'लोड';

  @override
  String get stageCommonLoadOwner => 'लोड मालिक';

  @override
  String get stageCommonLoadOwnerNotified => 'लोड मालिक को बता दिया गया!';

  @override
  String get stageCommonLoadTripFailed =>
      'ट्रिप की जानकारी लोड नहीं हो सकी। कृपया दोबारा कोशिश करें।';

  @override
  String get stageCommonLockedSynced => 'लॉक है — RR में पहले ही सिंक हो चुका';

  @override
  String get stageCommonLpTeam => 'लॉजिस्टिक पार्टनर टीम';

  @override
  String get stageCommonLpTeamNotified =>
      'लॉजिस्टिक पार्टनर टीम को बता दिया गया!';

  @override
  String stageCommonMaxChars(int count) {
    return 'ज़्यादा से ज़्यादा $count अक्षर';
  }

  @override
  String stageCommonMinAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String stageCommonNotified(String name) {
    return '$name को बता दिया';
  }

  @override
  String stageCommonNotify(String name) {
    return '$name को बताएं';
  }

  @override
  String stageCommonNotifyFailed(String error) {
    return 'सूचना नहीं भेजी जा सकी: $error';
  }

  @override
  String get stageCommonNumberTooShort => 'नंबर बहुत छोटा है';

  @override
  String get stageCommonOutsideFactory => 'फैक्ट्री के बाहर';

  @override
  String get stageCommonPdfOpenFailed => 'PDF नहीं खुल सकी।';

  @override
  String get stageCommonPhone10Digits => 'ठीक 10 अंक डालें';

  @override
  String get stageCommonPhoneRequired => 'फ़ोन नंबर ज़रूरी है';

  @override
  String get stageCommonPhotosDenied =>
      'अनुमति नहीं मिली। सेटिंग्स में इस ऐप के लिए फ़ोटो की अनुमति दें और फिर कोशिश करें।';

  @override
  String stageCommonPleaseUpload(String docs) {
    return 'कृपया अपलोड करें: $docs';
  }

  @override
  String get stageCommonReadOnlyCompleted =>
      'सिर्फ़ देखने के लिए — पूरी हुई ट्रिप';

  @override
  String get stageCommonReadyToUpload => 'अपलोड के लिए तैयार';

  @override
  String get stageCommonRemove => 'हटाएं';

  @override
  String get stageCommonReplace => 'बदलें';

  @override
  String get stageCommonRetake => 'दोबारा लें';

  @override
  String get stageCommonSaveContinue => 'सेव करें और आगे बढ़ें →';

  @override
  String get stageCommonSavingEllipsis => 'सेव हो रहा है…';

  @override
  String get stageCommonSelectDateTime => 'तारीख और समय चुनें';

  @override
  String get stageCommonSendingEllipsis => 'भेज रहे हैं…';

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
    return '@$username ने सबमिट किया';
  }

  @override
  String get stageCommonSubmittingEllipsis => 'सबमिट हो रहा है…';

  @override
  String get stageCommonTakePhoto => 'फ़ोटो खींचें';

  @override
  String get stageCommonTapToReplace => 'बदलने के लिए टैप करें';

  @override
  String get stageCommonTapToView => 'देखने के लिए टैप करें';

  @override
  String get stageCommonTrackTruck => 'ट्रक ट्रैक करें';

  @override
  String get stageCommonUnknownError => 'कोई अज्ञात गड़बड़';

  @override
  String get stageCommonUploadFailed => 'अपलोड नहीं हो सका';

  @override
  String get stageCommonUploadWeighSlip => 'वज़न की पर्ची अपलोड करें';

  @override
  String get stageCommonUploaded => 'अपलोड हो गया';

  @override
  String get stageCommonUploading => 'अपलोड हो रहा है...';

  @override
  String get stageCommonUploadingEllipsis => 'अपलोड हो रहा है…';

  @override
  String get stageCommonUseCamera => 'कैमरा इस्तेमाल करें';

  @override
  String get stageCommonVehicle => 'वाहन';

  @override
  String get stageCommonWeighSlip => 'वज़न की पर्ची';

  @override
  String get stageCommonWeight => 'वज़न';

  @override
  String stageCommonWeightRecorded(String weight, String unit) {
    return 'वज़न दर्ज: $weight $unit';
  }

  @override
  String get stageDocAadhaarCard => 'आधार कार्ड';

  @override
  String get stageDocBackSide => 'पीछे की तरफ़';

  @override
  String get stageDocBilty => 'बिल्टी';

  @override
  String get stageDocCancelledCheque => 'कैंसिल चेक (ओनर / ट्रांसपोर्टर)';

  @override
  String get stageDocDrivingLicense => 'ड्राइविंग लाइसेंस';

  @override
  String get stageDocDrivingLicenseBack => 'ड्राइविंग लाइसेंस (पीछे)';

  @override
  String get stageDocDrivingLicenseFront => 'ड्राइविंग लाइसेंस (सामने)';

  @override
  String get stageDocEway => 'ई-वे बिल';

  @override
  String get stageDocFitness => 'फिटनेस सर्टिफिकेट';

  @override
  String get stageDocFrontSide => 'सामने की तरफ़';

  @override
  String get stageDocInsurance => 'बीमा';

  @override
  String get stageDocInvoice => 'इनवॉइस';

  @override
  String get stageDocLoadingSlip => 'लोडिंग स्लिप';

  @override
  String get stageDocPermit => 'परमिट';

  @override
  String get stageDocPollution => 'प्रदूषण सर्टिफिकेट';

  @override
  String get stageDocRcFull => 'RC (रजिस्ट्रेशन सर्टिफिकेट)';

  @override
  String get stageDocTaxDeclaration => 'टैक्स डिक्लेरेशन';

  @override
  String get stageRrAllStagesCompleteTitle => 'सभी स्टेज पूरे';

  @override
  String get stageRrLater => 'बाद में';

  @override
  String get stageRrNotSyncedSub =>
      'इस ट्रिप को RR वेब भेजने के लिए दोबारा कोशिश पर टैप करें';

  @override
  String get stageRrNotSyncedTitle => 'RR में सिंक नहीं हुआ';

  @override
  String get stageRrSendToRr => 'RR को भेजें';

  @override
  String get stageRrSyncComplete => 'सिंक पूरा हुआ';

  @override
  String stageRrSyncFailed(String error) {
    return 'सिंक नहीं हो सका: $error';
  }

  @override
  String get stageRrSyncFailedShort => 'सिंक नहीं हो सका';

  @override
  String get stageRrSyncFailedTitle => 'RR सिंक नहीं हुआ';

  @override
  String get stageRrSyncNow => 'अभी सिंक करें';

  @override
  String get stageRrSyncPromptBody =>
      'यह ट्रिप पूरी हो गई है। अभी सारे अपलोड और डेटा RR वेब में सिंक करें?';

  @override
  String get stageRrSyncToRrWeb => 'RR वेब में सिंक करें';

  @override
  String get stageRrSyncTooltip => 'RR में सिंक करें';

  @override
  String get stageRrSyncedToRrWeb => 'RR वेब में सिंक हो गया';

  @override
  String get stageRrSyncingEllipsis => 'सिंक हो रहा है…';

  @override
  String get stageRrTripSynced => 'ट्रिप सिंक हो गई';

  @override
  String get stageS0Intro => 'स्टेज 1 पर जाने से पहले ये स्टेप पूरे करें:';

  @override
  String get stageS0Step1Sub =>
      'वाहन और चालक की जानकारी भरने के लिए ऊपर की पट्टी में स्टेज 1 पर टैप करें।';

  @override
  String get stageS0Step1Title => 'स्टेज 1 भरें — ट्रक रजिस्ट्रेशन';

  @override
  String get stageS0Step2Sub =>
      'स्टेज 1 पूरा होने के बाद ऊपर के \"RR को भेजें\" बटन से ट्रिप भेजें।';

  @override
  String get stageS0Step2Title => 'ट्रिप को RR में सिंक करें';

  @override
  String get stageS0Step3Sub => 'RR सिंक के बाद पहुंचने से पहले की जांच करें।';

  @override
  String get stageS0Step3Title => 'स्टेज 2 पर जाएं';

  @override
  String get stageS0Title => 'स्टेज 0 — RR सिंक';

  @override
  String get stageS1AadhaarBackPhoto => 'आधार कार्ड के पीछे की फ़ोटो';

  @override
  String get stageS1AadhaarFrontPhoto => 'आधार कार्ड के आगे की फ़ोटो';

  @override
  String get stageS1AadhaarLength => 'आधार में ठीक 12 अंक होने चाहिए';

  @override
  String get stageS1AadhaarNumber => 'आधार नंबर (12 अंक)';

  @override
  String get stageS1AppointNewDriver => 'नया चालक लगाएं';

  @override
  String get stageS1DlBackPhoto => 'ड्राइविंग लाइसेंस के पीछे की फ़ोटो';

  @override
  String get stageS1DlFormatHint =>
      'नया: RJ1420230012345   पुराना: RJ14/1234/2009';

  @override
  String get stageS1DlFrontPhoto => 'ड्राइविंग लाइसेंस के आगे की फ़ोटो';

  @override
  String get stageS1DlInvalid =>
      'गलत फ़ॉर्मेट — जैसे RJ1420230012345 (राज्य+RTO+साल+7 अंक)';

  @override
  String get stageS1DlNumber => 'ड्राइविंग लाइसेंस नंबर';

  @override
  String get stageS1DlRequired => 'ड्राइविंग लाइसेंस ज़रूरी है';

  @override
  String get stageS1DriverName => 'चालक का नाम';

  @override
  String get stageS1DriverNameRequired => 'चालक का नाम ज़रूरी है';

  @override
  String get stageS1DriverReassigned => 'चालक बदल दिया गया';

  @override
  String get stageS1FitnessNumber => 'फिटनेस नंबर';

  @override
  String get stageS1InsuranceNumber => 'बीमा पॉलिसी नंबर';

  @override
  String get stageS1NotNecessary => 'इस ट्रिप के लिए S1 भरना ज़रूरी नहीं है।';

  @override
  String get stageS1OnlyAlphabets => 'सिर्फ़ अंग्रेज़ी अक्षर लिखें';

  @override
  String get stageS1PermitNumber => 'परमिट नंबर';

  @override
  String get stageS1PucNumber => 'PUC नंबर';

  @override
  String get stageS1RcBackPhoto => 'RC के पीछे की फ़ोटो';

  @override
  String get stageS1RcFrontPhoto => 'RC के आगे की फ़ोटो';

  @override
  String get stageS1RcInvalid =>
      'RC नंबर गलत है — इसमें अक्षर और अंक दोनों होने चाहिए';

  @override
  String get stageS1RcNumber => 'RC नंबर';

  @override
  String get stageS1Reassign => 'बदलें';

  @override
  String stageS1ReassignBusyWarning(String trip) {
    return 'यह चालक दूसरी चालू ट्रिप ($trip) पर है। बदलने पर उसे उस ट्रिप से हटाकर इस ट्रिप पर ट्रैक किया जाएगा।';
  }

  @override
  String stageS1ReassignBody(String name) {
    return 'यह ट्रिप RR पर $name को सौंप दी जाएगी — मेरी ट्रिप्स की सूची और क्रू रिकॉर्ड इसी हिसाब से बदल जाएंगे।';
  }

  @override
  String get stageS1ReassignFailed => 'चालक नहीं बदला जा सका';

  @override
  String get stageS1ReassignTitle => 'चालक बदलें?';

  @override
  String stageS1ReassignPending(String name) {
    return 'नया चालक $name चुना है पर अभी बदला नहीं गया। आगे बढ़ने के लिए \"$name को चालक बनाएं\" दबाएं, फिर सेव करें।';
  }

  @override
  String stageS1ReassignTo(String name) {
    return '$name को चालक बनाएं';
  }

  @override
  String get stageS1Saved => 'स्टेज 1 सेव हो गया। अब जांच पर जाएं।';

  @override
  String get stageS1SearchDriver => 'नाम या फ़ोन से चालक खोजें';

  @override
  String get stageS1SecDriver => 'चालक की जानकारी';

  @override
  String get stageS1SecOwnerDocs => 'ओनर के डॉक्यूमेंट';

  @override
  String get stageS1SecOwnerPayment => 'ट्रक ओनर की पेमेंट जानकारी';

  @override
  String get stageS1SecVehicleDocs => 'वाहन के डॉक्यूमेंट';

  @override
  String get stageS1SelectedDriver => 'चुने गए चालक';

  @override
  String get stageS1ThisDriver => 'इस चालक';

  @override
  String get stageS1Updated => 'स्टेज 1 अपडेट हो गया।';

  @override
  String get stageS1UploadCancelledCheque => 'कैंसिल चेक अपलोड करें';

  @override
  String get stageS1UploadFitness => 'फिटनेस सर्टिफिकेट अपलोड करें';

  @override
  String get stageS1UploadInsurance => 'बीमा डॉक्यूमेंट अपलोड करें';

  @override
  String get stageS1UploadPan => 'PAN कार्ड अपलोड करें';

  @override
  String get stageS1PanNumber => 'PAN नंबर';

  @override
  String get stageS1PanInvalid => 'सही PAN डालें, जैसे ABCDE1234F';

  @override
  String get stageS1PanNumberRequired => 'PAN फ़ोटो के साथ PAN नंबर ज़रूरी है';

  @override
  String get stageS1TaxValidTill => 'टैक्स डिक्लेरेशन कब तक मान्य है';

  @override
  String get stageCommonSelectDate => 'तारीख चुनें';

  @override
  String get stageS1UploadPermit => 'परमिट डॉक्यूमेंट अपलोड करें';

  @override
  String get stageS1UploadPollution => 'प्रदूषण सर्टिफिकेट अपलोड करें';

  @override
  String get stageS1UploadTaxDeclaration =>
      'टैक्स डिक्लेरेशन डॉक्यूमेंट अपलोड करें';

  @override
  String get stageS2AttachSlip => 'लोडिंग स्लिप की फ़ोटो लगाएं';

  @override
  String get stageS2CheckDocs => 'सभी डॉक्यूमेंट अपलोड हो गए हैं';

  @override
  String get stageS2CheckDriverDocs => 'चालक के डॉक्यूमेंट सही हैं';

  @override
  String get stageS2CheckSpecs => 'ट्रक के स्पेसिफिकेशन ज़रूरत से मेल खाते हैं';

  @override
  String get stageS2ChooseSlipSource => 'स्लिप की फ़ोटो कैसे जोड़नी है, चुनें';

  @override
  String get stageS2DharamKanta => 'धर्मकांटा (वेब्रिज)';

  @override
  String get stageS2DharamKantaWhere =>
      'धर्मकांटा फैक्ट्री के अंदर है या बाहर?';

  @override
  String get stageS2Done =>
      'एंट्री की अनुमति दे दी गई। ट्रक के आने का इंतज़ाम करें।';

  @override
  String get stageS2EmptyWeightLabel => 'लोडिंग से पहले खाली ट्रक का वज़न';

  @override
  String get stageS2EmptyWeightNote =>
      'फैक्ट्री के बाहर दर्ज किया गया वज़न (लोडिंग से पहले)।';

  @override
  String get stageS2EntryIssued => 'ट्रक की एंट्री की अनुमति मिल गई';

  @override
  String get stageS2EntryIssuedNote =>
      'फैक्ट्री की लॉजिस्टिक टीम को ट्रक नंबर और चालक की जानकारी मिल जाती है।';

  @override
  String get stageS2ErrCheckEntry =>
      'आगे बढ़ने से पहले \"ट्रक की एंट्री की अनुमति मिल गई\" पर टिक करें।';

  @override
  String get stageS2ErrConfirmAll =>
      'आगे बढ़ने से पहले सभी जांच की चीज़ें कन्फर्म करें।';

  @override
  String get stageS2ErrEmptyWeight =>
      'कृपया खाली ट्रक का सही वज़न (0 से ज़्यादा) डालें और कन्फर्म करें।';

  @override
  String get stageS2ErrEntryRequired =>
      'आगे बढ़ने के लिए एंट्री की अनुमति देना ज़रूरी है।';

  @override
  String get stageS2ErrSelectWeighbridge =>
      'कृपया धर्मकांटे की जगह चुनें (फैक्ट्री के अंदर या बाहर)।';

  @override
  String get stageS2IssueEntry => 'एंट्री की अनुमति दें →';

  @override
  String get stageS2SlipOptional =>
      'ज़रूरी नहीं — स्लिप की फ़ोटो लगाने के लिए टैप करें';

  @override
  String get stageS2SlipRequiredBody =>
      'ट्रक को फैक्ट्री भेजने से पहले लोडिंग स्लिप अपलोड करें।';

  @override
  String get stageS2SlipRequiredTitle => 'लोडिंग स्लिप ज़रूरी है';

  @override
  String get stageS2SlipUploadedBadge => 'स्लिप अपलोड हो गई';

  @override
  String get stageS2SlipUploadedByTransporter =>
      'स्लिप ट्रांसपोर्टर ने अपलोड की है। ज़रूरत हो तो फ़ोटो पर टैप करके बदलें।';

  @override
  String get stageS2SlipUploadedTitle => 'लोडिंग स्लिप अपलोड हो गई';

  @override
  String get stageS2SubmitSlip => 'लोडिंग स्लिप सबमिट करें';

  @override
  String get stageS2TapToUploadSlip =>
      'लोडिंग स्लिप अपलोड करने के लिए टैप करें';

  @override
  String get stageS2UploadSlipTitle => 'लोडिंग स्लिप अपलोड करें';

  @override
  String get stageS2Verifies => 'RR एक्ज़ीक्यूटिव जांचते हैं:';

  @override
  String get stageS2VerifiesNote =>
      'एंट्री की अनुमति देने से पहले सभी चीज़ें कन्फर्म होनी चाहिए।';

  @override
  String get stageS3ArrivalSteps => 'पहुंचने के स्टेप';

  @override
  String get stageS3AttachEway => 'ई-वे बिल का डॉक्यूमेंट लगाएं';

  @override
  String get stageS3AttachInvoice => 'इनवॉइस का डॉक्यूमेंट लगाएं';

  @override
  String get stageS3Coordinates => 'RR एक्ज़ीक्यूटिव चालक से तालमेल करते हैं:';

  @override
  String get stageS3DharamKanta => 'धर्मकांटा (वेब्रिज)';

  @override
  String get stageS3DocsToSecurity => 'डॉक्यूमेंट सिक्योरिटी को दिए गए';

  @override
  String get stageS3DriverParks => 'चालक ट्रक फैक्ट्री के बाहर खड़ा करता है';

  @override
  String get stageS3EmptyWeight => 'खाली ट्रक का वज़न';

  @override
  String get stageS3EmptyWeightNote =>
      'लोडिंग से पहले खाली ट्रक का वज़न दर्ज करें।';

  @override
  String get stageS3ErrLoadingCompleted =>
      'स्टेज पूरा करने से पहले \"लोडिंग पूरी हुई\" पर टिक करें।';

  @override
  String get stageS3ErrStepsLoading =>
      'लोडिंग पूरी करने से पहले सभी स्टेप पूरे करें।';

  @override
  String get stageS3ErrStepsStage =>
      'स्टेज पूरा करने से पहले सभी स्टेप पूरे करें।';

  @override
  String get stageS3EwayExpiryDate => 'ई-वे बिल की एक्सपायरी तारीख';

  @override
  String get stageS3EwayIssueDate => 'ई-वे बिल जारी होने की तारीख';

  @override
  String get stageS3EwayNumber => 'ई-वे बिल नंबर';

  @override
  String get stageS3ExitCabin => 'चालक को केबिन से बाहर निकलना होगा';

  @override
  String get stageS3ExtraInfo => 'अतिरिक्त जानकारी (ज़रूरी नहीं)';

  @override
  String get stageS3ExtraInfoHint =>
      'कुछ भी जो काम आए — नंबर प्लेट की नज़दीक से फ़ोटो, दिखता हुआ फ़ोन नंबर वगैरह।';

  @override
  String get stageS3ExtraPhoto => 'अतिरिक्त फ़ोटो';

  @override
  String get stageS3InvoiceNumber => 'इनवॉइस नंबर डालें';

  @override
  String get stageS3InvoiceValue =>
      'इनवॉइस की रकम डालें (₹, ज़्यादा से ज़्यादा 10 अंक)';

  @override
  String get stageS3LoadedWeight => 'भरे ट्रक का वज़न';

  @override
  String get stageS3LoadedWeightNote => 'लोडिंग के बाद ट्रक का वज़न दर्ज करें।';

  @override
  String get stageS3MaterialWeight => 'सिर्फ़ माल का वज़न';

  @override
  String get stageS3MaterialWeightNote =>
      'धर्मकांटा पर्ची से सिर्फ़ माल का वज़न डालें, ट्रक का वज़न नहीं।';

  @override
  String get stageS3LoadingCompleteBody =>
      'लोडिंग पूरी हुई। अब फैक्ट्री से निकासी पर जाएं।';

  @override
  String get stageS3LoadingCompleteTitle => 'ट्रक की लोडिंग पूरी हुई!';

  @override
  String get stageS3LoadingCompleted => 'लोडिंग पूरी हुई';

  @override
  String get stageS3LoadingTiming => 'लोडिंग का समय';

  @override
  String get stageS3NextStageExit => 'अगला स्टेज — ट्रक की निकासी →';

  @override
  String get stageS3PhotoBack => 'पीछे';

  @override
  String get stageS3PhotoFront => 'सामने';

  @override
  String get stageS3PhotoLeft => 'बाईं तरफ़';

  @override
  String get stageS3PhotoRight => 'दाईं तरफ़';

  @override
  String stageS3PhotosAdded(int count) {
    return '$count/4 फ़ोटो जोड़ी गईं';
  }

  @override
  String stageS3PhotosNeedPhone(int count) {
    return '$count/4 फ़ोटो · फ़ोन नंबर चाहिए';
  }

  @override
  String get stageS3SafetyGear => 'सेफ्टी शूज़ और हेलमेट ज़रूरी हैं';

  @override
  String get stageS3SafetyRules => 'चालक के लिए सुरक्षा नियम';

  @override
  String get stageS3SecurityVerifies => 'सिक्योरिटी वाहन की ज़रूरतें जांचती है';

  @override
  String get stageS3SendForId => 'पहचान के लिए भेजें';

  @override
  String get stageS3SentForId => 'पहचान के लिए भेज दिया गया';

  @override
  String get stageS3TruckPhone => 'ट्रक पर लिखा फ़ोन नंबर';

  @override
  String stageS3TruckPhotosFailed(String error) {
    return 'ट्रक की फ़ोटो नहीं भेजी जा सकीं: $error';
  }

  @override
  String get stageS3TruckPhotosSent => 'ट्रक की फ़ोटो पहचान के लिए भेज दी गईं।';

  @override
  String get stageS3TruckPictures => 'ट्रक की फ़ोटो';

  @override
  String get stageS3TruckPicturesSub => 'ट्रक की चारों तरफ़ की फ़ोटो जोड़ें';

  @override
  String get stageS3UploadEway => 'ई-वे बिल अपलोड करें';

  @override
  String get stageS3UploadInvoice => 'इनवॉइस अपलोड करें';

  @override
  String get stageS3VehicleReach => 'वाहन पहुंचने की तारीख और समय';

  @override
  String get stageS3WheelStoppers => 'पहियों के स्टॉपर लगाए गए';

  @override
  String get stageS4BiltyDate => 'बिल्टी की तारीख और समय (ज़रूरी नहीं)';

  @override
  String stageS4BiltyBeforeTrip(String date) {
    return 'बिल्टी की तारीख ट्रिप बनने ($date) से पहले की नहीं हो सकती';
  }

  @override
  String get stageS4BiltyNumber => 'बिल्टी नंबर (4 अंक)';

  @override
  String get stageS4BiltyNumberError => 'बिल्टी नंबर में ठीक 4 अंक होने चाहिए';

  @override
  String get stageS4ChecklistDone =>
      'निकासी की चेकलिस्ट पूरी हुई। अब डीज़ल रसीद अपलोड करें।';

  @override
  String get stageS4ChooseReceiptSource =>
      'रसीद की फ़ोटो कैसे जोड़नी है, चुनें';

  @override
  String get stageS4ConfirmAllItems =>
      'आगे बढ़ने से पहले ऊपर की सभी चीज़ें कन्फर्म करें';

  @override
  String get stageS4DieselAndBilty => 'डीज़ल रसीद और बिल्टी';

  @override
  String get stageS4DieselReceipt => 'डीज़ल रसीद';

  @override
  String get stageS4DocsChecked => 'जांचे गए डॉक्यूमेंट';

  @override
  String get stageS4ExitChecklist => 'निकासी की चेकलिस्ट';

  @override
  String get stageS4ExitProcedure => 'निकासी की प्रक्रिया';

  @override
  String get stageS4ExitTiming => 'निकासी का समय';

  @override
  String get stageS4HeaderDieselSub =>
      'स्टेज 4 पूरा करने के लिए डीज़ल रसीद अपलोड करें';

  @override
  String get stageS4HeaderExit => 'फैक्ट्री से ट्रक की निकासी';

  @override
  String get stageS4HeaderExitSub =>
      'ट्रक छोड़ने से पहले निकासी की सारी प्रक्रिया जांच लें';

  @override
  String get stageS4LoadedWeightSlip => 'भरे ट्रक के वज़न की पर्ची';

  @override
  String get stageS4ManualBilty => 'मैनुअल बिल्टी अपलोड';

  @override
  String get stageS4ManualBiltySub =>
      'कागज़ वाली बिल्टी का डॉक्यूमेंट अपलोड करें';

  @override
  String get stageS4MaterialDocs => 'माल के डॉक्यूमेंट';

  @override
  String get stageS4MaterialVerification => 'माल वेरिफ़िकेशन शीट';

  @override
  String get stageS4MaterialVerificationSub => 'माल वेरिफ़िकेशन शीट अपलोड करें';

  @override
  String get stageS4SecurityVerifies => 'सिक्योरिटी डॉक्यूमेंट जांचती है';

  @override
  String get stageS4SubmitDiesel => 'डीज़ल रसीद सबमिट करें';

  @override
  String get stageS4TapToUploadDiesel =>
      'डीज़ल रसीद अपलोड करने के लिए टैप करें';

  @override
  String get stageS4TruckExits => 'ट्रक फैक्ट्री से निकला';

  @override
  String get stageS4TruckMoves => 'ट्रक फैक्ट्री के एग्ज़िट गेट पर जाता है';

  @override
  String get stageS4UploadDiesel => 'डीज़ल रसीद अपलोड करें';

  @override
  String get stageS4VehicleExit => 'वाहन की निकासी की तारीख और समय';

  @override
  String get stageS5AllCompletedBody => 'अनलोडिंग समेत सभी स्टेज पूरे हो गए।';

  @override
  String get stageS5AllCompletedTitle => 'सभी स्टेज पूरे हुए!';

  @override
  String get stageS5AllStagesDone => 'सभी स्टेज पूरे';

  @override
  String get stageS5CameraGalleryPdf => 'कैमरा, गैलरी या PDF फ़ाइल';

  @override
  String get stageS5ChoosePodSource => 'पीओडी डॉक्यूमेंट कैसे जोड़ना है, चुनें';

  @override
  String get stageS5Complete => 'अनलोडिंग स्टेज पूरा करें';

  @override
  String get stageS5FilePdf => 'फ़ाइल (PDF)';

  @override
  String get stageS5HaltingCharge => 'हॉल्टिंग चार्ज (ज़रूरी नहीं)';

  @override
  String get stageS5HaltingHint => 'रकम ₹ में डालें (जैसे 500)';

  @override
  String get stageS5Header => 'अनलोडिंग स्टेज';

  @override
  String get stageS5HeaderDone => 'अनलोडिंग स्टेज पूरा हुआ';

  @override
  String get stageS5HeaderDoneSub =>
      'पीओडी अपलोड हो गया। ज़रूरत हो तो बदलने के लिए टैप करें।';

  @override
  String get stageS5HeaderSub =>
      'पीओडी अपलोड करें और लागू हो तो हॉल्टिंग चार्ज डालें।';

  @override
  String get stageS5PodRequired =>
      'कृपया डिलीवरी के सबूत (पीओडी) का डॉक्यूमेंट अपलोड करें';

  @override
  String get stageS5PodTitle => 'डिलीवरी का सबूत (पीओडी)';

  @override
  String get stageS5PodUploadedBadge => 'पीओडी अपलोड हो गया';

  @override
  String get stageS5TapToUploadPod =>
      'पीओडी डॉक्यूमेंट अपलोड करने के लिए टैप करें';

  @override
  String get stageS5UnloadingEnd => 'अनलोडिंग ख़त्म होने की तारीख और समय';

  @override
  String get stageS5UnloadingTiming => 'अनलोडिंग का समय';

  @override
  String get stageS5UploadPod => 'डिलीवरी का सबूत अपलोड करें';

  @override
  String get stageNameArrival => 'आगमन';

  @override
  String get stageNameCompliance => 'जांच';

  @override
  String get stageNameDetails => 'जानकारी';

  @override
  String get stageNameExit => 'निकासी';

  @override
  String get stageNameUnloading => 'अनलोडिंग';

  @override
  String get createTripAddNewDriver => 'नया चालक जोड़ें';

  @override
  String get createTripAddressLine1 => 'पता लाइन 1';

  @override
  String get createTripAddressLine2 => 'पता लाइन 2';

  @override
  String createTripAddressN(int number) {
    return 'पता $number';
  }

  @override
  String get createTripAttachingDriver => 'RR पर वाहन से चालक जोड़ रहे हैं…';

  @override
  String get createTripAutoFilledHint => 'अपने आप भरेगा या खुद लिखें';

  @override
  String get createTripAxleDouble => 'डबल';

  @override
  String get createTripAxleMultiple => 'मल्टीपल';

  @override
  String get createTripAxleSingle => 'सिंगल';

  @override
  String get createTripAxleTriple => 'ट्रिपल';

  @override
  String get createTripBiddingHint =>
      'वाहन देने वाले को अपनी ऑफ़लाइन बिड / बुकिंग रकम तय करें';

  @override
  String get createTripBodyType => 'वाहन का बॉडी टाइप';

  @override
  String get createTripBookingAmount => 'वाहन देने वाले की बुकिंग रकम (₹) *';

  @override
  String get createTripBookingHint =>
      'जैसे 42000  (वाहन देने वाले को भेजी गई ऑफ़लाइन बिड)';

  @override
  String get createTripConsigneeGstin => 'कंसाइनी का GSTIN';

  @override
  String get createTripConsigneeHint =>
      'कंसाइनी की जानकारी अपने आप भरने के लिए पार्टनर में से चुनें';

  @override
  String get createTripConsigneeName => 'कंसाइनी का नाम';

  @override
  String get createTripConsigneeNameHint => 'जैसे JSW Steel Ltd';

  @override
  String get createTripConsignorGstin => 'कंसाइनर का GSTIN';

  @override
  String get createTripConsignorHint =>
      'कंसाइनर की जानकारी अपने आप भरने के लिए पार्टनर में से चुनें';

  @override
  String get createTripConsignorName => 'कंसाइनर का नाम *';

  @override
  String get createTripConsignorNameHint => 'जैसे Tata Steel Ltd';

  @override
  String get createTripCreateButton => 'ट्रिप बनाएं';

  @override
  String get createTripDepotHint => 'जैसे KNP01';

  @override
  String get createTripDiscard => 'छोड़ दें';

  @override
  String get createTripDiscardBody =>
      'इस ट्रिप के आपके बदलाव सेव नहीं हुए हैं।';

  @override
  String get createTripDiscardTitle => 'बदलाव छोड़ दें?';

  @override
  String get createTripDriverLabel => 'चालक *';

  @override
  String get createTripDriverSearchHint =>
      'पूरा 10 अंकों का फ़ोन, या नाम का कुछ हिस्सा';

  @override
  String get createTripDriverSearchLabel => 'चालक का नाम या फ़ोन नंबर';

  @override
  String createTripEditTitle(String ident) {
    return 'ट्रिप एडिट करें · $ident';
  }

  @override
  String createTripErrAttachDriver(String error) {
    return 'RR पर वाहन से चालक नहीं जुड़ सका: $error';
  }

  @override
  String get createTripErrCreateFailed => 'ट्रिप नहीं बन सकी';

  @override
  String get createTripErrNoUserFound => 'इस नंबर का कोई यूज़र नहीं मिला';

  @override
  String get createTripErrRrSlow =>
      'RR जवाब देने में बहुत समय ले रहा है — फिर कोशिश करें';

  @override
  String get createTripErrSaveFailed =>
      'बदलाव सेव नहीं हो सके — फिर कोशिश करें';

  @override
  String get createTripExpectedFreight => 'अनुमानित भाड़ा (₹) *';

  @override
  String get createTripFreightHint => 'जैसे 45000';

  @override
  String get createTripHandledByPerson => 'संभालने वाला *';

  @override
  String get createTripInvoiceHint => 'जैसे 150000';

  @override
  String get createTripInvoiceValue => 'कुल इनवॉइस वैल्यू (₹) *';

  @override
  String get createTripKeepEditing => 'बदलते रहें';

  @override
  String get createTripLandmark => 'लैंडमार्क / मोहल्ला';

  @override
  String get createTripLoadingBodyTypes => 'बॉडी टाइप लोड हो रहे हैं…';

  @override
  String get createTripLoadingCompanies => 'कंपनियां लोड हो रही हैं…';

  @override
  String get createTripLoadingPartners => 'पार्टनर लोड हो रहे हैं…';

  @override
  String get createTripLoadingVehicles => 'वाहन लोड हो रहे हैं…';

  @override
  String get createTripLoadingWorkers => 'वर्कर लोड हो रहे हैं…';

  @override
  String get createTripLookingUp => 'खोज रहे हैं…';

  @override
  String get createTripMarketShort => 'मार्केट';

  @override
  String get createTripMaterialType => 'माल / प्रोडक्ट टाइप *';

  @override
  String createTripMaxChars(int max, int count) {
    return 'ज़्यादा से ज़्यादा $max अक्षर   $count/$max';
  }

  @override
  String get createTripNewTrip => 'नई ट्रिप';

  @override
  String get createTripNoCompanies =>
      'कोई कंपनी नहीं — नीचे निजी फ्लीट का वाहन चुनें';

  @override
  String get createTripNoDriverOnRr =>
      'RR पर इस वाहन में कोई चालक नहीं है — नीचे खोजें या नया चालक जोड़ें।';

  @override
  String get createTripNoEntryZone => 'नो एंट्री ज़ोन';

  @override
  String get createTripNoVehicles => 'कोई वाहन नहीं मिला';

  @override
  String get createTripNotBookedNotice =>
      'अभी RR पर बुक नहीं हुई — बदलाव यहां सेव हैं और बुकिंग पक्की करने पर RR को भेजे जाएंगे।';

  @override
  String get createTripNothingChanged => 'कुछ बदला नहीं है';

  @override
  String get createTripParcelDesc => 'पार्सल का विवरण';

  @override
  String get createTripParcelDescHint => 'जैसे स्टील कॉइल';

  @override
  String get createTripPickupCityName => 'पिकअप शहर का नाम *';

  @override
  String get createTripPickupHint => 'अपने आप भरने के लिए कंसाइनर का पता चुनें';

  @override
  String get createTripPinHint => '6 अंकों का पिनकोड';

  @override
  String get createTripPinZip => 'पिनकोड';

  @override
  String get createTripSearchCity => 'शहर खोजें…';

  @override
  String get createTripSearchMaterial => 'माल खोजें…';

  @override
  String get createTripSectionBidding => 'बिडिंग रकम';

  @override
  String get createTripSectionConsignee => 'कंसाइनी की जानकारी';

  @override
  String get createTripSectionConsignor => 'कंसाइनर की जानकारी';

  @override
  String get createTripSectionHandledBy => 'ट्रिप हैंडल करने वाले';

  @override
  String get createTripSectionParcel => 'पार्सल / लोड की जानकारी';

  @override
  String get createTripSectionPickup => 'पिकअप लोकेशन';

  @override
  String get createTripSectionUnload => 'अनलोड लोकेशन';

  @override
  String get createTripSectionVehicleProvider => 'वाहन देने वाला';

  @override
  String get createTripSectionVehicleSpecs => 'वाहन की डिटेल';

  @override
  String get createTripSelectAxle => 'एक्सल टाइप चुनें';

  @override
  String get createTripSelectBodyType => 'वाहन का बॉडी टाइप चुनें';

  @override
  String get createTripSelectCompany => 'कंपनी चुनें';

  @override
  String get createTripSelectCompanyFirst =>
      'वाहन देखने के लिए पहले ऊपर से कंपनी चुनें';

  @override
  String get createTripSelectConsigneeAddress =>
      'कंसाइनी का पता चुनें (ज़रूरी नहीं)';

  @override
  String get createTripSelectConsigneeCompany => 'कंसाइनी की कंपनी चुनें';

  @override
  String get createTripSelectConsignorAddress =>
      'कंसाइनर का पता चुनें (ज़रूरी नहीं)';

  @override
  String get createTripSelectConsignorCompany => 'कंसाइनर की कंपनी चुनें *';

  @override
  String get createTripSelectFromPartners =>
      'पार्टनर में से चुनें (ज़रूरी नहीं)';

  @override
  String get createTripSelectOpsWorker => 'RR Ops वर्कर चुनें';

  @override
  String get createTripSelectPartner => 'पार्टनर चुनें';

  @override
  String get createTripSelectPartnerFirst => 'पहले ऊपर से पार्टनर चुनें';

  @override
  String get createTripSelectProviderCompany =>
      'वाहन देने वाले की कंपनी चुनें *';

  @override
  String get createTripSelectToAutoFill => 'पता अपने आप भरने के लिए चुनें';

  @override
  String get createTripSelectVehicle => 'वाहन चुनें *';

  @override
  String get createTripSelectVehicleHint => 'वाहन चुनें';

  @override
  String get createTripSelectWheels => 'पहियों की संख्या चुनें';

  @override
  String get createTripStepBidding => 'बिडिंग';

  @override
  String get createTripStepVehicle => 'वाहन';

  @override
  String get createTripStreetArea => 'गली / इलाका';

  @override
  String get createTripTabLoadInfo => 'लोड की जानकारी';

  @override
  String get createTripTapToSelect => 'चुनने के लिए टैप करें';

  @override
  String get createTripTotalWeight => 'कुल वज़न / मात्रा *';

  @override
  String get createTripUnknown => 'अज्ञात';

  @override
  String get createTripUnknownError => 'कोई अज्ञात गड़बड़';

  @override
  String get createTripUnloadCityName => 'अनलोड शहर का नाम *';

  @override
  String get createTripUnloadHint => 'अपने आप भरने के लिए कंसाइनी का पता चुनें';

  @override
  String get createTripUpdate => 'अपडेट करें';

  @override
  String get createTripUpdated => 'ट्रिप अपडेट हो गई';

  @override
  String get createTripValBookingAmount =>
      'बुकिंग रकम (₹) ज़रूरी है और 0 से ज़्यादा होनी चाहिए';

  @override
  String get createTripValConsignorCompany =>
      'लिस्ट में से कंपनी चुनना ज़रूरी है';

  @override
  String get createTripValConsignorName =>
      'कंसाइनर का नाम ज़रूरी है — ऊपर से पार्टनर चुनें या नाम लिखें';

  @override
  String get createTripValDriver => 'चालक चुनें';

  @override
  String get createTripValExpectedFreight =>
      'RR में ट्रिप बनाने के लिए अनुमानित भाड़ा (₹) ज़रूरी है';

  @override
  String get createTripValInvoiceValue =>
      'कुल इनवॉइस वैल्यू (₹) ज़रूरी है — RR में पार्सल की कीमत के तौर पर लगेगी';

  @override
  String get createTripValMaterial =>
      'माल / प्रोडक्ट टाइप ज़रूरी है — खोजकर लिस्ट में से चुनें';

  @override
  String get createTripValOpsWorker =>
      'इस ट्रिप को संभालने वाला RR Ops वर्कर चुनें';

  @override
  String get createTripValPickupCity =>
      'पिकअप शहर ज़रूरी है — खोजकर लिस्ट में से चुनें';

  @override
  String get createTripValUnloadCity =>
      'अनलोड शहर ज़रूरी है — खोजकर लिस्ट में से चुनें';

  @override
  String get createTripValVehicle => 'वाहन चुनें';

  @override
  String get createTripValVpCompany =>
      'वाहन देने वाले की कंपनी ज़रूरी है — कंपनी चुनें';

  @override
  String get createTripValVpPhone =>
      'वाहन देने वाले का फ़ोन नंबर डालें और नतीजे पर टैप करके चुनें';

  @override
  String get createTripValWeight => 'कुल वज़न / मात्रा ज़रूरी है';

  @override
  String get createTripVpPhone => 'वाहन देने वाले का फ़ोन *';

  @override
  String get createTripVpPhoneHint =>
      'जैसे 8960281816 — 10 अंक होते ही अपने आप खोजेगा';

  @override
  String get createTripVpSteps =>
      'वाहन देने वाले का फ़ोन डालें → यूज़र चुनें → कंपनी चुनें → वाहन चुनें';

  @override
  String get createTripWarnBusy =>
      'यह चालक पहले से दूसरी चालू ट्रिप पर है — वह ट्रिप पूरी होने तक ट्रैकिंग इस ट्रिप से नहीं जुड़ेगी।';

  @override
  String get createTripWarnNoApp =>
      'इस चालक ने अभी RR4 ऐप सेट अप नहीं किया है — जब तक वे नहीं करते, इस ट्रिप की ट्रैकिंग नहीं होगी।';

  @override
  String get createTripWeightHint => 'जैसे 20';

  @override
  String createTripWheelsCount(int count) {
    return '$count पहिए';
  }

  @override
  String get lpDashAboutRr => 'RR Logistics के बारे में';

  @override
  String get lpDashAddCompany => 'कंपनी जोड़ें';

  @override
  String get lpDashAddDriver => 'चालक जोड़ें';

  @override
  String get lpDashAddVehicle => 'वाहन जोड़ें';

  @override
  String get lpDashBrowseLoads => 'उपलब्ध लोड रिक्वायरमेंट देखें';

  @override
  String get lpDashComingSoonBody =>
      'यह सेक्शन तैयार हो रहा है\nऔर जल्द ही उपलब्ध होगा।';

  @override
  String get lpDashCreateTrip => 'ट्रिप बनाएं';

  @override
  String get lpDashEmployees => 'कर्मचारी';

  @override
  String get lpDashEmptyTripsHint => 'ट्रिप बनाएं और उसे यहां लाइव ट्रैक करें';

  @override
  String get lpDashFleetHub => 'फ्लीट हब';

  @override
  String get lpDashFleetStatus => 'फ्लीट की स्थिति';

  @override
  String get lpDashHireTruck => 'ट्रक हायर करें';

  @override
  String get lpDashLoadFleetFailed => 'फ्लीट की स्थिति लोड नहीं हो सकी';

  @override
  String get lpDashNavFleet => 'फ्लीट';

  @override
  String get lpDashNavLoads => 'लोड';

  @override
  String get lpDashNavSoon => 'जल्द';

  @override
  String get lpDashNewTrip => 'नई ट्रिप';

  @override
  String get lpDashNoRecords => 'अभी कोई RR Web रिकॉर्ड नहीं है';

  @override
  String get lpDashNoRecordsHint => 'पूरी हुई RR Web ट्रिप यहां दिखेंगी';

  @override
  String get lpDashPanelSubtitle => 'लॉजिस्टिक पार्टनर पैनल';

  @override
  String lpDashPendingCount(int count) {
    return '$count पेंडिंग';
  }

  @override
  String get lpDashReconnect => 'फिर से जोड़ें';

  @override
  String get lpDashRecordsSubtitle => 'पूरी हुई RR Web ट्रिप';

  @override
  String get lpDashRequests => 'रिक्वेस्ट';

  @override
  String get lpDashRrQuickAdd => 'RR क्विक ऐड';

  @override
  String lpDashRrSyncFailedDetail(String reason) {
    return 'RR सिंक नहीं हुआ: $reason';
  }

  @override
  String get lpDashRrTripNumber => 'RR ट्रिप नंबर';

  @override
  String get lpDashS1AllowBody =>
      'क्या फील्ड एक्ज़ीक्यूटिव इस ट्रिप के स्टेज 1 (ट्रक डिटेल रजिस्ट्रेशन) के डॉक्यूमेंट भर सकता है?\n\nआप इसे बाद में ट्रिप कार्ड से बदल सकते हैं।';

  @override
  String get lpDashS1AllowTitle => 'फील्ड एक्ज़ीक्यूटिव — स्टेज 1';

  @override
  String get lpDashSearchNewLoads => 'नए लोड खोजें';

  @override
  String get lpDashTrack => 'ट्रैक';

  @override
  String lpDashTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रिप',
    );
    return '$_temp0';
  }

  @override
  String get lpDashTripCreated => 'ट्रिप बन गई';

  @override
  String get lpDashTripNumberCopied => 'ट्रिप नंबर कॉपी हो गया';

  @override
  String get lpDashTripSyncedToRrWeb => 'ट्रिप RR Web में सिंक हो गई';

  @override
  String get lpDashVehicleHireRequests => 'वाहन हायर रिक्वेस्ट';

  @override
  String get lpOpsAddCompany => 'कंपनी जोड़ें';

  @override
  String get lpOpsAddDriver => 'चालक जोड़ें';

  @override
  String get lpOpsAddVehicle => 'वाहन जोड़ें';

  @override
  String get lpOpsDrawerTrack => 'ट्रैक';

  @override
  String get lpOpsEmptyBody =>
      'अभी कोई चालू RR Web ट्रिप नहीं है।\nशुरू करने के लिए ऊपर \"+ नई ट्रिप\" दबाएं।';

  @override
  String get lpOpsEmptyTitle => 'अभी कोई RR Web ट्रिप नहीं';

  @override
  String get lpOpsHireRequests => 'वाहन हायर रिक्वेस्ट';

  @override
  String get lpOpsHireTruck => 'ट्रक हायर करें';

  @override
  String get lpOpsNavLoads => 'लोड';

  @override
  String get lpOpsNeedsSlip => 'स्लिप बाकी';

  @override
  String get lpOpsNewTrip => 'नई ट्रिप';

  @override
  String lpOpsNoMatch(String query) {
    return '\"$query\" से कोई ट्रिप नहीं मिली';
  }

  @override
  String get lpOpsNoSyncedHint => 'RR web में सिंक हुई ट्रिप यहां दिखेंगी';

  @override
  String get lpOpsNoSyncedTitle => 'अभी कोई सिंक हुई ट्रिप नहीं';

  @override
  String get lpOpsQuickAdd => 'RR क्विक ऐड';

  @override
  String get lpOpsReconnect => 'फिर से जोड़ें';

  @override
  String get lpOpsRrTripNumber => 'RR ट्रिप नंबर';

  @override
  String get lpOpsS1Body =>
      'क्या फील्ड एक्ज़ीक्यूटिव इस ट्रिप के स्टेज 1 (ट्रक डिटेल रजिस्ट्रेशन) के डॉक्यूमेंट भरे?\n\nआप इसे बाद में ट्रिप कार्ड से बदल सकते हैं।';

  @override
  String get lpOpsS1Title => 'फील्ड एक्ज़ीक्यूटिव — स्टेज 1';

  @override
  String get lpOpsSlipDone => 'स्लिप हो गई';

  @override
  String lpOpsSyncFailedMsg(String error) {
    return 'RR सिंक नहीं हुआ: $error';
  }

  @override
  String lpOpsSyncedCount(int count) {
    return '$count सिंक हुईं';
  }

  @override
  String get lpOpsTripCreated => 'ट्रिप बन गई';

  @override
  String get lpOpsTripNumberCopied => 'ट्रिप नंबर कॉपी हो गया';

  @override
  String get lpOpsTripSynced => 'ट्रिप RR Web में सिंक हो गई';

  @override
  String get lpOpsWebTrips => 'RR Web ट्रिप';

  @override
  String get lpWorkersDaily => 'दैनिक';

  @override
  String get lpWorkersEmptyHint =>
      'आपकी कंपनी के सक्रिय कर्मचारी यहां दिखेंगे।';

  @override
  String get lpWorkersEmptyTitle => 'कोई कर्मचारी नहीं मिला';

  @override
  String get lpWorkersLoadFailed => 'लोड नहीं हो सका';

  @override
  String get lpWorkersMonthly => 'मासिक';

  @override
  String get lpWorkersNoActivityHint =>
      'इस अवधि में कोई स्टेज सबमिशन दर्ज नहीं हुआ।';

  @override
  String get lpWorkersNoActivityTitle => 'अभी कोई गतिविधि नहीं';

  @override
  String lpWorkersPoints(int count) {
    return '$count अंक';
  }

  @override
  String get lpWorkersPtsShort => 'अंक';

  @override
  String lpWorkersRemoveConfirm(String name) {
    return '$name को कंपनी से हटाएं? उनका एक्सेस अभी बंद हो जाएगा और वे बाद में दोबारा जुड़ने की रिक्वेस्ट कर सकते हैं।';
  }

  @override
  String lpWorkersRemoveFailed(String error) {
    return 'हटाना नहीं हो सका: $error';
  }

  @override
  String get lpWorkersRemoveTitle => 'कंपनी से हटाएं';

  @override
  String lpWorkersRemoved(String name) {
    return '$name को कंपनी से हटा दिया गया';
  }

  @override
  String get lpWorkersTabLeaderboard => 'लीडरबोर्ड';

  @override
  String get lpWorkersTabRecord => 'रिकॉर्ड';

  @override
  String get lpWorkersTitle => 'कर्मचारी';

  @override
  String lpWorkersTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रिप',
      one: '$count ट्रिप',
    );
    return '$_temp0';
  }

  @override
  String get rrQuickAddActionFailed =>
      'काम नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get rrQuickAddAddCompanyButton => 'कंपनी जोड़ें';

  @override
  String get rrQuickAddAddDriverButton => 'चालक जोड़ें';

  @override
  String get rrQuickAddAddVehicleButton => 'वाहन जोड़ें';

  @override
  String get rrQuickAddApprove => 'मंज़ूर करें';

  @override
  String get rrQuickAddApprovedEndDate => 'मंज़ूर खत्म तारीख';

  @override
  String rrQuickAddApprovedRange(String start, String end) {
    return 'मंज़ूर: $start से $end';
  }

  @override
  String get rrQuickAddApprovedStartDate => 'मंज़ूर शुरू तारीख';

  @override
  String get rrQuickAddBizCommissionAgent => 'कमीशन एजेंट';

  @override
  String get rrQuickAddBizDriver => 'चालक';

  @override
  String get rrQuickAddBizOther => 'अन्य';

  @override
  String get rrQuickAddBizParcelReceiver => 'पार्सल पाने वाला - कंसाइनी';

  @override
  String get rrQuickAddBizParcelReceiverAgent =>
      'पार्सल पाने वाले का एजेंट - कंसाइनी कमीशन एजेंट';

  @override
  String get rrQuickAddBizParcelSender => 'पार्सल भेजने वाला - कंसाइनर';

  @override
  String get rrQuickAddBizParcelSenderAgent =>
      'पार्सल भेजने वाले का एजेंट - कंसाइनर कमीशन एजेंट';

  @override
  String get rrQuickAddBizTransporter => 'ट्रांसपोर्टर';

  @override
  String get rrQuickAddBizVehicleAgent => 'वाहन एजेंट';

  @override
  String get rrQuickAddBizVehicleOwner => 'वाहन ओनर';

  @override
  String get rrQuickAddBusinessTypeLabel => 'बिज़नेस टाइप *';

  @override
  String get rrQuickAddCheckHistory => 'वाहन की हिस्ट्री देखें';

  @override
  String rrQuickAddCompanyAdded(String name) {
    return 'कंपनी \"$name\" RR पर जोड़ दी गई';
  }

  @override
  String get rrQuickAddCompanyFirmLabel => 'कंपनी / फर्म का नाम';

  @override
  String get rrQuickAddCompanyIntro =>
      'RR पर नई वाहन देने वाली कंपनी रजिस्टर करें';

  @override
  String get rrQuickAddCompanyNameRequired => 'कंपनी का नाम ज़रूरी है';

  @override
  String get rrQuickAddCompanyOptional => 'कंपनी (ज़रूरी नहीं)';

  @override
  String get rrQuickAddCompanyOwnerLabel =>
      'कंपनी ओनर (खोजें या नया 10 अंकों का फ़ोन डालें) *';

  @override
  String get rrQuickAddCompanyTitle => 'नई कंपनी जोड़ें';

  @override
  String rrQuickAddContractorLine(String value) {
    return 'कॉन्ट्रैक्टर: $value';
  }

  @override
  String rrQuickAddDateRangeTo(String start, String end) {
    return '$start से $end';
  }

  @override
  String rrQuickAddDriverAdded(String name) {
    return 'चालक \"$name\" RR पर जोड़ दिया गया';
  }

  @override
  String get rrQuickAddDriverIntro => 'RR पर नया चालक रजिस्टर करें';

  @override
  String get rrQuickAddDriverTitle => 'नया चालक जोड़ें';

  @override
  String rrQuickAddEndLine(String date) {
    return 'खत्म: $date';
  }

  @override
  String get rrQuickAddEngineModelLabel => 'इंजन मॉडल *';

  @override
  String get rrQuickAddFind => 'खोजें';

  @override
  String rrQuickAddFromLine(String date) {
    return 'से: $date';
  }

  @override
  String get rrQuickAddHireApproved => 'हायर रिक्वेस्ट मंज़ूर हो गई';

  @override
  String get rrQuickAddHireEmpty => 'कोई पेंडिंग हायर रिक्वेस्ट नहीं';

  @override
  String get rrQuickAddHireLoadFailed => 'हायर रिक्वेस्ट लोड नहीं हो सकीं';

  @override
  String get rrQuickAddHirePerson => 'हायर करने वाला';

  @override
  String get rrQuickAddHirePersonLabel => 'वाहन हायर करने वाला *';

  @override
  String get rrQuickAddHireRejected => 'हायर रिक्वेस्ट अस्वीकार कर दी गई';

  @override
  String get rrQuickAddHireSendFailed =>
      'हायर रिक्वेस्ट नहीं भेजी जा सकी। कृपया फिर से कोशिश करें।';

  @override
  String get rrQuickAddHireSent => 'हायरिंग रिक्वेस्ट भेज दी गई';

  @override
  String get rrQuickAddHireTitle => 'वाहन हायर रिक्वेस्ट';

  @override
  String get rrQuickAddHiringDateFrom => 'हायरिंग रिक्वेस्ट की तारीख — से';

  @override
  String get rrQuickAddHiringDateTo => 'हायरिंग रिक्वेस्ट की तारीख — तक';

  @override
  String get rrQuickAddHiringRequestDate => 'हायरिंग रिक्वेस्ट की तारीख';

  @override
  String get rrQuickAddHistoryFailed =>
      'हिस्ट्री लोड नहीं हो सकी। कृपया फिर से कोशिश करें।';

  @override
  String get rrQuickAddHistoryHint =>
      'सिर्फ़ जानकारी के लिए — वाहन के पुराने हायर देखें';

  @override
  String get rrQuickAddHistorySelectFirst => 'पहले वाहन खोजकर चुनें';

  @override
  String get rrQuickAddLenderDetail => 'वाहन देने वाले की जानकारी';

  @override
  String get rrQuickAddLenderVehicles => 'वाहन देने वाले के वाहन *';

  @override
  String get rrQuickAddMarketTitle => 'मार्केट वाहन जोड़ें';

  @override
  String get rrQuickAddNameLabel => 'नाम *';

  @override
  String get rrQuickAddNameMin => 'कम से कम 2 अक्षर डालें';

  @override
  String rrQuickAddNoHistory(String vehicle) {
    return '$vehicle की कोई हायर हिस्ट्री नहीं मिली';
  }

  @override
  String get rrQuickAddNoOwnerVehicles => 'इस ओनर का RR पर कोई वाहन नहीं है';

  @override
  String get rrQuickAddNotSet => 'सेट नहीं है';

  @override
  String get rrQuickAddOrByPhone => '— या फ़ोन नंबर से —';

  @override
  String rrQuickAddOwnerLine(String value) {
    return 'ओनर: $value';
  }

  @override
  String get rrQuickAddOwnerOrPhone =>
      'मौजूदा ओनर चुनें या सही 10 अंकों का फ़ोन नंबर डालें';

  @override
  String get rrQuickAddOwnerPhoneLabel => 'ओनर का फ़ोन नंबर *';

  @override
  String get rrQuickAddPhoneLabel => 'फ़ोन नंबर *';

  @override
  String get rrQuickAddPhoneSearchHint =>
      'पूरा 10 अंकों का फ़ोन, या नाम का कुछ हिस्सा';

  @override
  String get rrQuickAddRcHint => 'जैसे RJ14';

  @override
  String get rrQuickAddRcNumberLabel => 'RC नंबर *';

  @override
  String get rrQuickAddRcRequired => 'RC नंबर ज़रूरी है';

  @override
  String get rrQuickAddReject => 'अस्वीकार करें';

  @override
  String get rrQuickAddRequestInfo => 'रिक्वेस्ट की जानकारी';

  @override
  String get rrQuickAddRequestTimePeriod => 'रिक्वेस्ट की अवधि';

  @override
  String rrQuickAddRequestedByLine(String value) {
    return 'रिक्वेस्ट करने वाला: $value';
  }

  @override
  String rrQuickAddRequestedRangeArrow(String start, String end) {
    return 'रिक्वेस्ट: $start → $end';
  }

  @override
  String rrQuickAddRequestedRangeTo(String start, String end) {
    return 'रिक्वेस्ट: $start से $end';
  }

  @override
  String get rrQuickAddReviewTitle => 'हायर रिक्वेस्ट का रिव्यू';

  @override
  String get rrQuickAddSamePerson =>
      'हायर करने वाला और वाहन देने वाला अलग होने चाहिए। आप अपना ही वाहन हायर नहीं कर सकते।';

  @override
  String get rrQuickAddSearchByCompany => 'कंपनी/फर्म से खोजें';

  @override
  String get rrQuickAddSelectCity => 'सुझावों में से शहर चुनें';

  @override
  String get rrQuickAddSelectEngineModel => 'सुझावों में से इंजन मॉडल चुनें';

  @override
  String get rrQuickAddSelectFleetVehicle => 'ओनर के फ्लीट से वाहन चुनें';

  @override
  String get rrQuickAddSelectHirePerson => 'वाहन हायर करने वाले को खोजकर चुनें';

  @override
  String get rrQuickAddSelectOwner => 'सुझावों में से ओनर चुनें';

  @override
  String get rrQuickAddSelectVehicleHint => 'वाहन चुनें';

  @override
  String get rrQuickAddSelectVehicleOwner => 'वाहन ओनर को खोजकर चुनें';

  @override
  String rrQuickAddStartLine(String date) {
    return 'शुरू: $date';
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
    return 'समाप्त: $date';
  }

  @override
  String rrQuickAddToLine(String date) {
    return 'तक: $date';
  }

  @override
  String get rrQuickAddUnknown => 'अज्ञात';

  @override
  String rrQuickAddVehicleAdded(String rc) {
    return 'वाहन \"$rc\" RR पर जोड़ दिया गया';
  }

  @override
  String get rrQuickAddVehicleDetail => 'वाहन की जानकारी';

  @override
  String get rrQuickAddVehicleIntro => 'RR पर नया वाहन रजिस्टर करें';

  @override
  String rrQuickAddVehicleLine(String value) {
    return 'वाहन: $value';
  }

  @override
  String get rrQuickAddVehicleOwnerLabel => 'वाहन ओनर *';

  @override
  String get rrQuickAddVehicleTitle => 'नया वाहन जोड़ें';

  @override
  String get rrQuickAddYourFleet => 'आपका फ्लीट';

  @override
  String loadsBrowserCompany(String name) {
    return 'कंपनी: $name';
  }

  @override
  String loadsBrowserCopiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोड रिक्वायरमेंट क्लिपबोर्ड पर कॉपी हो गईं',
      one: 'लोड रिक्वायरमेंट क्लिपबोर्ड पर कॉपी हो गई',
    );
    return '$_temp0';
  }

  @override
  String get loadsBrowserCopyDetails => 'जानकारी कॉपी करें';

  @override
  String loadsBrowserCopySelected(int count) {
    return 'चुने हुए कॉपी करें ($count)';
  }

  @override
  String get loadsBrowserDetailsCopied =>
      'लोड की जानकारी क्लिपबोर्ड पर कॉपी हो गई';

  @override
  String get loadsBrowserDropHint => 'ड्रॉप शहर…';

  @override
  String get loadsBrowserEmpty => 'कोई लोड रिक्वायरमेंट पेंडिंग नहीं';

  @override
  String loadsBrowserLogisticPartner(String name) {
    return 'लॉजिस्टिक पार्टनर: $name';
  }

  @override
  String loadsBrowserMaterialWeight(String weight) {
    return 'माल: $weight';
  }

  @override
  String get loadsBrowserPickupHint => 'पिकअप शहर…';

  @override
  String get loadsBrowserSubtitle =>
      'लोड मालिकों की पेंडिंग रिक्वायरमेंट देखें';

  @override
  String get loadsBrowserTitle => 'लोड खोजें';

  @override
  String loadsBrowserTruckUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ट्रक',
      one: 'ट्रक',
    );
    return '$_temp0';
  }

  @override
  String loadsBrowserTruckWeight(String weight) {
    return 'ट्रक: $weight';
  }

  @override
  String get loadsBrowserTrucksNeeded => 'ट्रक चाहिए:';

  @override
  String get loadsBrowserWhatsApp => 'WhatsApp';

  @override
  String get loadsBrowserWhatsAppFailed => 'WhatsApp नहीं खुल पाया';

  @override
  String get tripDetailCreated => 'बनने की तारीख';

  @override
  String get tripDetailEndDate => 'ख़त्म होने की तारीख';

  @override
  String get tripDetailFetchingGps => 'GPS लोकेशन ली जा रही है…';

  @override
  String get tripDetailGoToStage => 'मौजूदा स्टेज पर जाएं';

  @override
  String get tripDetailInvoiceNumber => 'इनवॉइस नंबर';

  @override
  String get tripDetailLoadItem => 'लोड आइटम';

  @override
  String get tripDetailRoute => 'रूट';

  @override
  String get tripDetailSectionCargo => 'माल की जानकारी';

  @override
  String get tripDetailSectionFinancial => 'पैसों की जानकारी';

  @override
  String get tripDetailSectionIdentifiers => 'पहचान की जानकारी';

  @override
  String get tripDetailSectionLogistics => 'लॉजिस्टिक्स';

  @override
  String tripDetailStageLine(int number, String name) {
    return 'स्टेज $number: $name';
  }

  @override
  String get tripDetailStartDate => 'शुरू होने की तारीख';

  @override
  String get tripDetailTitle => 'ट्रिप की जानकारी';

  @override
  String get tripDetailTripAmount => 'ट्रिप की रकम';

  @override
  String get tripDetailTripNumber => 'ट्रिप नंबर';

  @override
  String get tripDetailViewOnMap => 'वाहन को लाइव मैप पर देखें';

  @override
  String tripLocateDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String tripLocateGapLocationOff(String time) {
    return 'लोकेशन बंद थी · $time';
  }

  @override
  String get tripLocateGapNearDetail => 'वाहन उसी इलाके में रहा।';

  @override
  String tripLocateGapNoTracking(String time) {
    return 'इस ट्रिप की ट्रैकिंग नहीं हुई · $time';
  }

  @override
  String tripLocateGapOkDetail(String km) {
    return 'सड़क से लगभग $km किमी। अंदाज़न रूट, कम से कम दूरी।';
  }

  @override
  String tripLocateGapOkDetailMode(String km, String mode) {
    return 'सड़क से लगभग $km किमी। अंदाज़न रूट, कम से कम दूरी ($mode)।';
  }

  @override
  String get tripLocateGapReleasedDetail =>
      'इस ट्रिप की ट्रैकिंग रोकी गई थी या चालक बदल गया। कोई रूट नहीं दिखाया गया।';

  @override
  String tripLocateGapSemanticsOff(String label) {
    return 'लोकेशन $label तक बंद थी। जानकारी के लिए टैप करें।';
  }

  @override
  String tripLocateGapSemanticsReleased(String label) {
    return 'इस ट्रिप की ट्रैकिंग $label तक नहीं हुई। जानकारी के लिए टैप करें।';
  }

  @override
  String tripLocateGapSuspiciousDetail(String km) {
    return 'वाहन सीधी लाइन में $km किमी चला, जो इस समय के हिसाब से बहुत ज़्यादा है। कोई रूट नहीं दिखाया गया।';
  }

  @override
  String get tripLocateGapUnavailable => 'रूट अभी उपलब्ध नहीं है।';

  @override
  String get tripLocateGpsActive => 'GPS चालू';

  @override
  String tripLocateHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String tripLocateHoursMinutes(int hours, int minutes) {
    return '$hours घंटे $minutes मिनट';
  }

  @override
  String get tripLocateJustNow => 'अभी';

  @override
  String tripLocateLastUpdated(String ago, String time) {
    return 'आख़िरी अपडेट: $ago ($time)';
  }

  @override
  String get tripLocateLegendLocationOff => 'लोकेशन बंद';

  @override
  String get tripLocateLegendSemantics =>
      'मैप का संकेत। नारंगी लाइन: ट्रैक हुआ रूट। स्लेटी बिंदु वाली लाइन: लोकेशन बंद थी।';

  @override
  String get tripLocateLegendTracked => 'ट्रैक हुआ';

  @override
  String get tripLocateLoadingTrail => 'सफ़र का रूट लोड हो रहा है…';

  @override
  String tripLocateLocating(String tripNumber) {
    return '$tripNumber का लोकेशन देखा जा रहा है';
  }

  @override
  String tripLocateMinutes(int minutes) {
    return '$minutes मिनट';
  }

  @override
  String tripLocateMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String get tripLocateModeCar => 'कार का रूट';

  @override
  String get tripLocateModeHeavyTruck => 'भारी ट्रक का रूट';

  @override
  String get tripLocateModeLightTruck => 'हल्के ट्रक का रूट';

  @override
  String get tripLocateModeMediumTruck => 'मीडियम ट्रक का रूट';

  @override
  String get tripLocateModeTruck => 'ट्रक का रूट';

  @override
  String get tripLocateNoGpsMessage =>
      'इस ट्रिप के लिए चालक के ऐप से अभी तक लोकेशन नहीं आई।';

  @override
  String get tripLocateNoGpsTitle => 'GPS लोकेशन उपलब्ध नहीं';

  @override
  String get tripLocateNoSignal => 'सिग्नल नहीं';

  @override
  String get tripLocateOpenMaps => 'Google Maps में खोलें';

  @override
  String get tripLocateStale => 'पुरानी लोकेशन';

  @override
  String get tripLocateTimeMismatch => 'समय में गड़बड़';

  @override
  String get tripLocateTryAgain => 'फिर कोशिश करें';

  @override
  String get tripLocateVehicleFallback => 'वाहन';

  @override
  String get workerReqAccept => 'स्वीकार करें';

  @override
  String get workerReqAccepted => 'वर्कर को स्वीकार कर लिया गया!';

  @override
  String get workerReqAssignRole => 'भूमिका दें';

  @override
  String workerReqCurrentRole(String role) {
    return 'अभी: $role';
  }

  @override
  String workerReqJoined(String date) {
    return '$date को जुड़े';
  }

  @override
  String workerReqJoinedBy(String date, String name) {
    return '$name द्वारा $date को जुड़े';
  }

  @override
  String get workerReqLoadFailed => 'रिक्वेस्ट लोड नहीं हो पाईं';

  @override
  String get workerReqNoAccepted => 'अभी कोई कर्मचारी स्वीकार नहीं किया गया';

  @override
  String get workerReqNoAcceptedHint => 'स्वीकार किए गए कर्मचारी यहां दिखेंगे।';

  @override
  String get workerReqNoPending => 'कोई रिक्वेस्ट पेंडिंग नहीं';

  @override
  String get workerReqNoPendingHint => 'वर्कर रिक्वेस्ट यहां दिखेंगी।';

  @override
  String get workerReqNoRolePicked =>
      'इस वर्कर ने साइनअप पर भूमिका नहीं चुनी — नीचे से चुनें।';

  @override
  String get workerReqNoRoleRequested => 'अभी कोई भूमिका नहीं मांगी गई';

  @override
  String get workerReqReject => 'अस्वीकार करें';

  @override
  String get workerReqRejectConfirm =>
      'क्या आप इस वर्कर रिक्वेस्ट को अस्वीकार करना चाहते हैं?';

  @override
  String get workerReqRejectTitle => 'रिक्वेस्ट अस्वीकार करें';

  @override
  String get workerReqRejected => 'रिक्वेस्ट अस्वीकार कर दी गई।';

  @override
  String workerReqRequestedOn(String date) {
    return 'रिक्वेस्ट की तारीख: $date';
  }

  @override
  String get workerReqRoleFeDesc =>
      'ज़मीन पर ट्रिप के स्टेज और फ्लीट की स्थिति संभालता है';

  @override
  String get workerReqRoleLoadOwnerWorker => 'लोड मालिक वर्कर';

  @override
  String get workerReqRoleLoadOwnerWorkerDesc =>
      'लोड पोस्टिंग और शिपमेंट ट्रैकिंग संभालता है';

  @override
  String get workerReqRoleNotSet => 'भूमिका तय नहीं — चुनने के लिए टैप करें';

  @override
  String get workerReqRoleRrOpsDesc =>
      'RR सिंक और RR सिस्टम में ट्रिप का डेटा एंट्री संभालता है';

  @override
  String get workerReqTabAccepted => 'स्वीकृत';

  @override
  String get workerReqTabPending => 'पेंडिंग';

  @override
  String get workerReqTitle => 'कर्मचारी रिक्वेस्ट';

  @override
  String get workerReqUnknown => 'अज्ञात';

  @override
  String get loadSpecAxleFullTrailer => 'फुल ट्रेलर';

  @override
  String get loadSpecAxleMulti => 'मल्टी-एक्सल';

  @override
  String get loadSpecAxleSemiTrailer => 'सेमी-ट्रेलर';

  @override
  String get loadSpecAxleSingle => 'सिंगल एक्सल';

  @override
  String get loadSpecAxleTandem => 'टैंडम एक्सल';

  @override
  String get loadSpecAxleTri => 'ट्राई-एक्सल';

  @override
  String get loadSpecBodyCarCarrier => 'कार कैरियर';

  @override
  String get loadSpecBodyClosed => 'क्लोज़्ड बॉडी';

  @override
  String get loadSpecBodyContainer => 'कंटेनर';

  @override
  String get loadSpecBodyFlatbed => 'फ्लैटबेड';

  @override
  String get loadSpecBodyLowBed => 'लो बेड';

  @override
  String get loadSpecBodyOpen => 'ओपन बॉडी';

  @override
  String get loadSpecBodyRefrigerated => 'रेफ्रिजरेटेड';

  @override
  String get loadSpecBodySideWall => 'साइड वॉल';

  @override
  String get loadSpecBodyTanker => 'टैंकर';

  @override
  String get loadSpecBodyTipper => 'टिपर / डंपर';

  @override
  String get loadSpecFloorAluminium => 'एल्युमिनियम';

  @override
  String get loadSpecFloorBamboo => 'बांस';

  @override
  String get loadSpecFloorCorrugated => 'कोरुगेटेड';

  @override
  String get loadSpecFloorPlain => 'प्लेन फ्लोर';

  @override
  String get loadSpecFloorRubberMatted => 'रबर मैटेड';

  @override
  String get loadSpecFloorSteel => 'स्टील';

  @override
  String get loadSpecFloorWooden => 'लकड़ी का';

  @override
  String get loadSpecMatAgri => 'खेती की उपज';

  @override
  String get loadSpecMatAutoParts => 'ऑटोमोटिव पार्ट्स';

  @override
  String get loadSpecMatChemicals => 'केमिकल';

  @override
  String get loadSpecMatConstruction => 'कंस्ट्रक्शन मटेरियल';

  @override
  String get loadSpecMatElectronics => 'इलेक्ट्रॉनिक्स';

  @override
  String get loadSpecMatFmcg => 'FMCG / पैकेज्ड माल';

  @override
  String get loadSpecMatFurniture => 'फर्नीचर';

  @override
  String get loadSpecMatGlass => 'कांच और सिरेमिक';

  @override
  String get loadSpecMatHazardous => 'खतरनाक माल';

  @override
  String get loadSpecMatIndustrial => 'इंडस्ट्रियल माल';

  @override
  String get loadSpecMatLiquids => 'लिक्विड / पेय पदार्थ';

  @override
  String get loadSpecMatMachinery => 'मशीनरी और इक्विपमेंट';

  @override
  String get loadSpecMatOthers => 'अन्य';

  @override
  String get loadSpecMatPaints => 'पेंट और कोटिंग';

  @override
  String get loadSpecMatPaper => 'कागज़ और प्रिंटिंग';

  @override
  String get loadSpecMatPerishables => 'जल्दी खराब होने वाला माल';

  @override
  String get loadSpecMatPharma => 'दवाइयां (फ़ार्मा)';

  @override
  String get loadSpecMatPlastics => 'प्लास्टिक और रबर';

  @override
  String get loadSpecMatSteelCoils => 'स्टील कॉइल';

  @override
  String get loadSpecMatTextiles => 'कपड़ा और फैब्रिक';

  @override
  String get loDashBottomDashboard => 'डैशबोर्ड';

  @override
  String get loDashBottomDocs => 'दस्तावेज़';

  @override
  String get loDashBottomLoads => 'लोड';

  @override
  String get loDashBottomMyTrips => 'मेरी ट्रिप';

  @override
  String get loDashBottomProfile => 'प्रोफ़ाइल';

  @override
  String get loDashBottomSoon => 'जल्द';

  @override
  String get loDashClearAll => 'सब हटाएं';

  @override
  String get loDashClearAllBody => 'सभी सूचनाएं हमेशा के लिए हट जाएंगी।';

  @override
  String get loDashClearAllTitle => 'सभी सूचनाएं हटाएं?';

  @override
  String get loDashCreateLoadButton => 'लोड रिक्वायरमेंट बनाएं';

  @override
  String get loDashNavMyLoads => 'मेरे लोड';

  @override
  String get loDashNoNotifications => 'अभी कोई सूचना नहीं';

  @override
  String get loDashPanelTitle => 'लोड मालिक पैनल';

  @override
  String get loDashPostLoadBody =>
      'अपने पसंदीदा लॉजिस्टिक पार्टनर को लोड की जानकारी भेजें और माल रवाना करवाएं।';

  @override
  String get loDashPostLoadTitle => 'लोड रिक्वायरमेंट पोस्ट करें';

  @override
  String loDashSoonSuffix(String label) {
    return '$label (जल्द)';
  }

  @override
  String get loDashTabDocuments => 'दस्तावेज़';

  @override
  String get loDashTabTracking => 'ट्रैकिंग';

  @override
  String get appRouterErrorTitle => 'गड़बड़ी';

  @override
  String appRouterPageNotFound(String location) {
    return 'पेज नहीं मिला: $location';
  }

  @override
  String get mainNavCreateOrganization => 'कंपनी बनाएं';

  @override
  String get mainNavInventory => 'इन्वेंटरी';

  @override
  String mainNavLoadOrganizationsError(String error) {
    return 'कंपनियां लोड करने में गड़बड़ी: $error';
  }

  @override
  String get mainNavLoadingOrganizations => 'कंपनियां लोड हो रही हैं...';

  @override
  String get mainNavLogoutConfirm => 'क्या आप लॉग आउट करना चाहते हैं?';

  @override
  String get mainNavManageOrganization => 'कंपनी मैनेज करें';

  @override
  String get mainNavMyOrganizations => 'मेरी कंपनियां';

  @override
  String get mainNavMyProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get mainNavMyTasks => 'मेरे टास्क';

  @override
  String get mainNavNoOrganization =>
      'कोई कंपनी नहीं मिली। पहले किसी कंपनी से जुड़ें या नई बनाएं।';

  @override
  String get mainNavOrganizationFallback => 'कंपनी';

  @override
  String get mainNavReports => 'रिपोर्ट';

  @override
  String get mainNavRoles => 'भूमिका';

  @override
  String get mainNavSchedule => 'शेड्यूल';

  @override
  String get mainNavSignOut => 'साइन आउट';

  @override
  String get mainNavTasks => 'टास्क';

  @override
  String get mainNavUserFallback => 'यूज़र';

  @override
  String get loReceiverDashboardTitle => 'लोड रिसीवर डैशबोर्ड';

  @override
  String get loReceiverEmpty => 'आपकी आने वाली डिलीवरी यहां दिखेंगी।';

  @override
  String get loReceiverRole => 'लोड रिसीवर';

  @override
  String get loUploadBody => 'बॉडी';

  @override
  String get loUploadBroadcastHint => 'सबको भेजने के लिए खाली छोड़ें';

  @override
  String get loUploadDropHint => 'मंज़िल डालें';

  @override
  String get loUploadDropLocation => 'ड्रॉप लोकेशन';

  @override
  String get loUploadEntryDate => 'एंट्री की तारीख';

  @override
  String get loUploadEntryMethod => 'एंट्री का तरीका';

  @override
  String get loUploadExpectedContact => 'संपर्क कब होगा';

  @override
  String get loUploadExpectedContactBody =>
      'हमारे लॉजिस्टिक कोऑर्डिनेटर आखिरी वेरिफ़िकेशन के लिए 15 मिनट में आपसे संपर्क करेंगे।';

  @override
  String get loUploadExpectedContactHighlight => '15 मिनट';

  @override
  String get loUploadFleetStatus => 'फ्लीट की स्थिति';

  @override
  String get loUploadFleetStatusBody =>
      'आपके पिकअप ज़ोन में अभी 4 हैवी-ड्यूटी ट्रेलर उपलब्ध हैं।';

  @override
  String get loUploadFloor => 'फ्लोर';

  @override
  String get loUploadMaterialType => 'माल का प्रकार';

  @override
  String get loUploadMaterialWeight => 'माल का वज़न';

  @override
  String get loUploadMethodBulk => 'बल्क';

  @override
  String get loUploadMethodManual => 'मैनुअल';

  @override
  String get loUploadMethodPhoto => 'फोटो';

  @override
  String get loUploadNavDocs => 'डॉक्स';

  @override
  String get loUploadNavTracking => 'ट्रैकिंग';

  @override
  String get loUploadNewLoad => 'नया लोड';

  @override
  String get loUploadNewLoadRequirement => 'नई लोड रिक्वायरमेंट';

  @override
  String get loUploadPickDate => 'तारीख चुनें';

  @override
  String get loUploadPickupHint => 'शुरुआती हब डालें';

  @override
  String get loUploadProcessUpdate => 'प्रोसेस अपडेट';

  @override
  String get loUploadProcessUpdateBody =>
      'फ्लीट ऑप्टिमाइज़ेशन आपके माल के लिए सबसे अच्छा रूट निकाल रहा है।';

  @override
  String get loUploadReferenceId => 'रेफ़रेंस आईडी';

  @override
  String get loUploadSearchPartnerHint => 'यहां लॉजिस्टिक पार्टनर खोजें';

  @override
  String get loUploadSelect => 'चुनें';

  @override
  String get loUploadSelectMaterial => 'माल चुनें';

  @override
  String get loUploadSelected => 'चुना हुआ';

  @override
  String get loUploadSendTo => 'किसे भेजें';

  @override
  String get loUploadSoonBadge => 'जल्द';

  @override
  String get loUploadSubmitButton => 'लोड रिक्वायरमेंट सबमिट करें';

  @override
  String get loUploadSubmitFailed => 'सबमिट नहीं हो सका। दोबारा कोशिश करें।';

  @override
  String loUploadSuccessBody(int count, String material) {
    return '$material के $count यूनिट के लिए आपकी लोड रिक्वायरमेंट मिल गई है। हमारी टीम अब फ्लीट असाइन कर रही है।';
  }

  @override
  String get loUploadSuccessTitle => 'सबमिट हो गया';

  @override
  String get loUploadTargetPartners => 'टारगेट पार्टनर';

  @override
  String get loUploadTrackInTrips => 'मेरी ट्रिप में ट्रैक करें';

  @override
  String get loUploadTruckCount => 'ट्रकों की संख्या';

  @override
  String get loUploadTruckRequirements => 'ट्रक रिक्वायरमेंट';

  @override
  String get loUploadTruckWeightOptional => 'ट्रक का वज़न (ज़रूरी नहीं)';

  @override
  String get loUploadUnits => 'यूनिट';

  @override
  String get loUploadValAxle => 'एक्सल टाइप चुनें';

  @override
  String get loUploadValBody => 'बॉडी टाइप चुनें';

  @override
  String get loUploadValDate => 'एंट्री की तारीख चुनें';

  @override
  String get loUploadValDrop => 'ड्रॉप लोकेशन डालें';

  @override
  String get loUploadValFloor => 'फ्लोर टाइप चुनें';

  @override
  String get loUploadValMaterial => 'माल का प्रकार चुनें';

  @override
  String get loUploadValMaterialWeight => 'माल का वज़न डालें';

  @override
  String get loUploadValPartner => 'लॉजिस्टिक पार्टनर चुनें';

  @override
  String get loUploadValPickup => 'पिकअप लोकेशन डालें';

  @override
  String get loUploadValTruckCount => 'ट्रकों की संख्या 0 नहीं हो सकती';

  @override
  String get loUploadValTruckWeight => 'सही ट्रक वज़न डालें, या खाली छोड़ दें';

  @override
  String get loWorkerHomeBuilding =>
      'आपका लोड मालिक वर्कर वर्कस्पेस तैयार हो रहा है। जल्द दोबारा देखें।';

  @override
  String get loWorkerHomeFallbackName => 'वर्कर';

  @override
  String get loWorkerHomeTitle => 'लोड मालिक वर्कर डैशबोर्ड';

  @override
  String loWorkerHomeWelcome(String name) {
    return 'स्वागत है, $name!';
  }

  @override
  String get transporterComingSoonBody =>
      'यह डैशबोर्ड अभी तैयार हो रहा है\nऔर जल्द ही उपलब्ध होगा।';

  @override
  String get transporterDashboardTitle => 'ट्रांसपोर्टर डैशबोर्ड';

  @override
  String get drvAddAdding => 'चालक जोड़ा जा रहा है...';

  @override
  String get drvAddButton => 'फ्लीट में चालक जोड़ें';

  @override
  String get drvAddCancelReturn => 'रद्द करें और वापस जाएं';

  @override
  String get drvAddDatesRequired =>
      'लाइसेंस जारी होने और समाप्ति की तारीख ज़रूरी है';

  @override
  String get drvAddEmail => 'ईमेल पता';

  @override
  String get drvAddEmailInvalid => 'सही ईमेल पता डालें';

  @override
  String get drvAddExpiryAfterIssue =>
      'लाइसेंस की समाप्ति की तारीख जारी होने की तारीख के बाद की होनी चाहिए';

  @override
  String get drvAddExpiryFuture =>
      'लाइसेंस की समाप्ति की तारीख आगे की होनी चाहिए';

  @override
  String drvAddFieldRequired(String field) {
    return '$field ज़रूरी है';
  }

  @override
  String get drvAddFirstName => 'पहला नाम';

  @override
  String get drvAddFixErrors => 'कृपया फ़ॉर्म की गलतियां ठीक करें';

  @override
  String drvAddHintExample(String value) {
    return 'जैसे $value';
  }

  @override
  String get drvAddJoinDate => 'जॉइनिंग की तारीख';

  @override
  String get drvAddJoinFuture => 'जॉइनिंग की तारीख आगे की नहीं हो सकती';

  @override
  String get drvAddLastName => 'सरनेम';

  @override
  String get drvAddLicenseClass => 'लाइसेंस क्लास';

  @override
  String get drvAddLicenseFormat =>
      'लाइसेंस नंबर 10-50 अक्षर या अंक का होना चाहिए';

  @override
  String get drvAddLicenseHmv => 'HMV (हेवी मोटर व्हीकल)';

  @override
  String get drvAddLicenseHpmv => 'HPMV (हेवी पैसेंजर मोटर व्हीकल)';

  @override
  String get drvAddLicenseLmv => 'LMV (लाइट मोटर व्हीकल)';

  @override
  String get drvAddLicenseMcwg => 'MCWG (गियर वाली मोटरसाइकिल)';

  @override
  String get drvAddLicenseRequired => 'लाइसेंस नंबर ज़रूरी है';

  @override
  String get drvAddLicenseScan => 'लाइसेंस दस्तावेज़ का स्कैन';

  @override
  String get drvAddLicenseScanHint => 'साफ़ स्कैन या फोटो अपलोड करें';

  @override
  String get drvAddPasswordDigit => 'एक अंक ज़रूर हो';

  @override
  String get drvAddPasswordHint => 'कम से कम 8 अक्षर, बड़े अक्षर और अंक के साथ';

  @override
  String get drvAddPasswordLength => 'पासवर्ड कम से कम 8 अक्षर का होना चाहिए';

  @override
  String get drvAddPasswordLower => 'एक छोटा अक्षर (a-z) ज़रूर हो';

  @override
  String get drvAddPasswordRequired => 'पासवर्ड ज़रूरी है';

  @override
  String get drvAddPasswordUpper => 'एक बड़ा अक्षर (A-Z) ज़रूर हो';

  @override
  String get drvAddPhoneDigits => 'फ़ोन नंबर 10 अंकों का होना चाहिए';

  @override
  String get drvAddPhoneRequired => 'फ़ोन नंबर ज़रूरी है';

  @override
  String drvAddPhotoFailed(String error) {
    return 'चालक जुड़ गया, लेकिन फोटो अपलोड नहीं हो सकी: $error';
  }

  @override
  String get drvAddPhotoHint => 'PNG, JPG, 5MB तक';

  @override
  String get drvAddPhotoSelected => 'फोटो चुन ली गई — बदलने के लिए टैप करें';

  @override
  String get drvAddProgress => 'रजिस्ट्रेशन की प्रगति';

  @override
  String get drvAddRoleLogistics => 'लॉजिस्टिक्स';

  @override
  String get drvAddRoleSupport => 'सपोर्ट';

  @override
  String get drvAddSectionLogin => 'लॉगिन की जानकारी';

  @override
  String get drvAddSectionRole => 'असाइनमेंट और भूमिका';

  @override
  String get drvAddSelect => 'चुनें';

  @override
  String get drvAddStep => '3 में से स्टेप 1';

  @override
  String get drvAddSuccess => 'चालक सफलतापूर्वक जुड़ गया!';

  @override
  String get drvAddSystemRole => 'सिस्टम भूमिका';

  @override
  String get drvAddTitle => 'नया चालक जोड़ें';

  @override
  String get drvAddUploadPhoto => 'प्रोफ़ाइल फोटो अपलोड करें';

  @override
  String get drvAddUsernameFormat =>
      'यूज़रनेम: 3-50 अक्षर (अक्षर, अंक, अंडरस्कोर)';

  @override
  String get drvAddUsernameRequired => 'यूज़रनेम ज़रूरी है';

  @override
  String get drvMgmtAddFirstHint => 'पहला चालक जोड़ने के लिए + दबाएं';

  @override
  String get drvMgmtCurrentlyOnLeave => 'अभी छुट्टी पर हैं';

  @override
  String get drvMgmtMainDepot => 'मुख्य डिपो';

  @override
  String get drvMgmtNoDrivers => 'अभी कोई चालक नहीं';

  @override
  String get drvMgmtNoMatch => 'आपके फ़िल्टर से कोई चालक नहीं मिला';

  @override
  String get drvMgmtSearchHint => 'चालक, कर्मचारी ID खोजें...';

  @override
  String get drvMgmtStatusActive => 'एक्टिव';

  @override
  String get drvMgmtStatusAll => 'सभी';

  @override
  String get drvMgmtStatusAvailable => 'उपलब्ध';

  @override
  String get drvMgmtStatusOnLeave => 'छुट्टी पर';

  @override
  String get drvMgmtStatusTerminated => 'सेवा समाप्त';

  @override
  String get drvMgmtTitle => 'चालक';

  @override
  String drvMgmtTotalMembers(int count) {
    return 'कुल $count फ्लीट सदस्य';
  }

  @override
  String get helpCenterArticleAddVehicle => 'नया वाहन कैसे जोड़ें';

  @override
  String get helpCenterArticleAddVehicleDesc =>
      'अपने फ्लीट में वाहन जोड़ने की स्टेप-बाय-स्टेप गाइड';

  @override
  String helpCenterArticleDetailIntro(String title) {
    return 'यह इस बारे में विस्तृत आर्टिकल है: $title';
  }

  @override
  String get helpCenterArticleDriverPerms => 'चालक की अनुमतियां मैनेज करना';

  @override
  String get helpCenterArticleDriverPermsDesc =>
      'चालक की भूमिकाएं और अनुमतियां देना और मैनेज करना सीखें';

  @override
  String get helpCenterArticleMaintenance => 'मेंटेनेंस शेड्यूल बनाना';

  @override
  String get helpCenterArticleMaintenanceDesc =>
      'समय पर मेंटेनेंस करके अपना फ्लीट अच्छे से चलाते रहें';

  @override
  String get helpCenterArticlePlaceholder =>
      'यहां आर्टिकल की सामग्री होगी, जिसमें स्टेप-बाय-स्टेप निर्देश, स्क्रीनशॉट और काम की टिप्स होंगी।';

  @override
  String get helpCenterArticleRealtimeTracking => 'रियल-टाइम ट्रैकिंग सेट करना';

  @override
  String get helpCenterArticleRealtimeTrackingDesc =>
      'अपने फ्लीट के वाहनों के लिए GPS ट्रैकिंग सेट करें';

  @override
  String get helpCenterAvgResponse => 'औसत जवाब का समय: 2 मिनट';

  @override
  String get helpCenterBrowseByCategory => 'कैटेगरी के हिसाब से देखें';

  @override
  String get helpCenterCatDriver => 'चालक मैनेजमेंट';

  @override
  String get helpCenterCatDriverDesc =>
      'चालक की प्रोफ़ाइल, लाइसेंस और असाइनमेंट';

  @override
  String get helpCenterCatFinancial => 'फाइनेंशियल मैनेजमेंट';

  @override
  String get helpCenterCatFinancialDesc => 'खर्चे, इनवॉइस और पेमेंट';

  @override
  String get helpCenterCatMaintenance => 'मेंटेनेंस';

  @override
  String get helpCenterCatMaintenanceDesc => 'शेड्यूल, मरम्मत और इंस्पेक्शन';

  @override
  String get helpCenterCatReports => 'रिपोर्ट और एनालिटिक्स';

  @override
  String get helpCenterCatReportsDesc => 'रिपोर्ट बनाना और एक्सपोर्ट करना';

  @override
  String get helpCenterCatRoles => 'भूमिकाएं और अनुमतियां';

  @override
  String get helpCenterCatRolesDesc => 'यूज़र की भूमिकाएं और एक्सेस कंट्रोल';

  @override
  String get helpCenterCatTracking => 'रियल-टाइम ट्रैकिंग';

  @override
  String get helpCenterCatTrackingDesc => 'GPS ट्रैकिंग और लोकेशन सर्विस';

  @override
  String get helpCenterCatTrip => 'ट्रिप मैनेजमेंट';

  @override
  String get helpCenterCatTripDesc => 'ट्रिप बनाना और उन पर नज़र रखना';

  @override
  String get helpCenterCatVehicle => 'वाहन मैनेजमेंट';

  @override
  String get helpCenterCatVehicleDesc => 'वाहन जोड़ना, एडिट करना और मैनेज करना';

  @override
  String get helpCenterChatWithTeam => 'हमारी सपोर्ट टीम से चैट करें';

  @override
  String get helpCenterContactSupport => 'सपोर्ट से संपर्क करें';

  @override
  String get helpCenterEmailSupport => 'ईमेल सपोर्ट';

  @override
  String get helpCenterEmailUs => 'हमें ईमेल करें';

  @override
  String get helpCenterGettingStarted => 'शुरुआत कैसे करें';

  @override
  String get helpCenterGuideTitle => 'शुरुआत की गाइड';

  @override
  String get helpCenterIssueDescription => 'विवरण';

  @override
  String get helpCenterIssueReported => 'समस्या की रिपोर्ट हो गई';

  @override
  String get helpCenterIssueTitle => 'समस्या का शीर्षक';

  @override
  String get helpCenterLiveChat => 'लाइव चैट';

  @override
  String get helpCenterMarkedHelpful => 'आर्टिकल को काम का बताया गया';

  @override
  String get helpCenterNeedMoreHelp => 'और मदद चाहिए?';

  @override
  String helpCenterNoResults(String query) {
    return '\"$query\" के लिए कोई नतीजा नहीं मिला';
  }

  @override
  String get helpCenterNoResultsHint =>
      'दूसरे शब्द आज़माएं या नीचे कैटेगरी देखें';

  @override
  String helpCenterOpeningCategory(String category) {
    return '$category के आर्टिकल खोल रहे हैं...';
  }

  @override
  String get helpCenterOpeningChat => 'लाइव चैट खोल रहे हैं...';

  @override
  String get helpCenterPhoneSupport => 'फोन सपोर्ट';

  @override
  String get helpCenterPopularArticles => 'लोकप्रिय आर्टिकल';

  @override
  String get helpCenterQuickActions => 'क्विक एक्शन';

  @override
  String helpCenterReadMinutes(int minutes) {
    return '$minutes मिनट में पढ़ें';
  }

  @override
  String get helpCenterReportIssue => 'समस्या बताएं';

  @override
  String get helpCenterReportTitle => 'समस्या की रिपोर्ट करें';

  @override
  String helpCenterResultsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नतीजे मिले',
    );
    return '$_temp0';
  }

  @override
  String get helpCenterSearchDriverPermsDesc =>
      'चालक की भूमिकाएं देना और मैनेज करना सीखें';

  @override
  String get helpCenterSearchGpsDesc => 'वाहन की रियल-टाइम ट्रैकिंग सेट करें';

  @override
  String get helpCenterSearchGpsTitle => 'GPS ट्रैकिंग सेट करना';

  @override
  String get helpCenterSearchHint => 'हेल्प आर्टिकल, गाइड, FAQ खोजें...';

  @override
  String get helpCenterSearchMaintenanceDesc =>
      'वाहन का नियमित मेंटेनेंस शेड्यूल करें';

  @override
  String get helpCenterSearchReportsDesc =>
      'फाइनेंशियल रिपोर्ट बनाएं और एक्सपोर्ट करें';

  @override
  String get helpCenterSearchReportsTitle => 'फाइनेंशियल रिपोर्ट बनाना';

  @override
  String get helpCenterShowingAll => 'सभी आर्टिकल दिखा रहे हैं...';

  @override
  String get helpCenterStep1Desc => 'अपनी जानकारी से साइन अप करें';

  @override
  String get helpCenterStep1Title => 'अपना अकाउंट बनाएं';

  @override
  String get helpCenterStep2Desc => 'कंपनी बनाएं या किसी कंपनी से जुड़ें';

  @override
  String get helpCenterStep2Title => 'अपनी कंपनी सेट करें';

  @override
  String get helpCenterStep3Desc => 'सिस्टम में वाहन जोड़ें';

  @override
  String get helpCenterStep3Title => 'अपना फ्लीट जोड़ें';

  @override
  String get helpCenterStep4Desc => 'चालक और स्टाफ जोड़ें';

  @override
  String get helpCenterStep4Title => 'टीम के सदस्यों को बुलाएं';

  @override
  String get helpCenterStep5Desc => 'अपना फ्लीट ट्रैक और मैनेज करना शुरू करें';

  @override
  String get helpCenterStep5Title => 'मैनेज करना शुरू करें';

  @override
  String get helpCenterSupport247 =>
      'हमारी सपोर्ट टीम 24/7 आपकी मदद के लिए मौजूद है';

  @override
  String get helpCenterTitle => 'हेल्प सेंटर';

  @override
  String get helpCenterVideoComingSoon => 'यह फीचर जल्द आ रहा है।';

  @override
  String get helpCenterVideoTutorials => 'वीडियो ट्यूटोरियल';

  @override
  String get helpCenterViewAll => 'सभी देखें';

  @override
  String get helpCenterWasHelpful => 'क्या यह काम का था?';

  @override
  String get orgCreate10Chars => '10 अक्षर';

  @override
  String get orgCreate15Chars => '15 अक्षर';

  @override
  String get orgCreateAdd => 'जोड़ें';

  @override
  String get orgCreateAddressRequired => 'पता ज़रूरी है';

  @override
  String get orgCreateBusinessEmail => 'बिज़नेस ईमेल';

  @override
  String get orgCreateBusinessPhone => 'बिज़नेस फ़ोन';

  @override
  String get orgCreateBusinessType => 'बिज़नेस टाइप';

  @override
  String get orgCreateBusinessTypeHint => 'जैसे: ट्रांसपोर्टेशन, लॉजिस्टिक्स';

  @override
  String get orgCreateBusinessTypeRequired => 'बिज़नेस टाइप ज़रूरी है';

  @override
  String get orgCreateCity => 'शहर';

  @override
  String get orgCreateCompanyName => 'कंपनी का नाम';

  @override
  String get orgCreateCompanyNameHint => 'जैसे: Acme Logistics Pvt. Ltd.';

  @override
  String get orgCreateCompanyNameRequired => 'कंपनी का नाम ज़रूरी है';

  @override
  String get orgCreateCountry => 'देश';

  @override
  String get orgCreateEmailInvalid => 'ईमेल का फ़ॉर्मेट सही नहीं है';

  @override
  String get orgCreateEmailRequired => 'बिज़नेस ईमेल ज़रूरी है';

  @override
  String orgCreateFailed(String error) {
    return 'कंपनी नहीं बन सकी: $error';
  }

  @override
  String get orgCreateGstinInvalid => 'GSTIN का फ़ॉर्मेट सही नहीं है';

  @override
  String get orgCreateGstinLength => 'GSTIN ठीक 15 अक्षर का होना चाहिए';

  @override
  String get orgCreateHeaderSub => 'अपना फ्लीट वर्कस्पेस सेट करें';

  @override
  String get orgCreateHeaderTitle => 'नई कंपनी';

  @override
  String get orgCreateInvalid => 'सही नहीं है';

  @override
  String get orgCreateLegalSub => 'GSTIN और PAN — ज़रूरी नहीं';

  @override
  String get orgCreateMin10Digits => 'कम से कम 10 अंक होने चाहिए';

  @override
  String get orgCreateMin2Chars => 'कम से कम 2 अक्षर होने चाहिए';

  @override
  String orgCreateOptionalLabel(String label) {
    return '$label (ज़रूरी नहीं)';
  }

  @override
  String get orgCreatePanInvalid => 'PAN का फ़ॉर्मेट सही नहीं है';

  @override
  String get orgCreatePanLength => 'PAN ठीक 10 अक्षर का होना चाहिए';

  @override
  String get orgCreatePanNumber => 'PAN नंबर';

  @override
  String get orgCreatePhoneRequired => 'बिज़नेस फ़ोन ज़रूरी है';

  @override
  String get orgCreatePincode => 'पिनकोड';

  @override
  String get orgCreateRequired => 'ज़रूरी';

  @override
  String get orgCreateSecAddress => 'पता';

  @override
  String get orgCreateSecCompany => 'कंपनी की जानकारी';

  @override
  String get orgCreateSecContact => 'संपर्क की जानकारी';

  @override
  String get orgCreateSecLegal => 'कानूनी जानकारी';

  @override
  String get orgCreateState => 'राज्य';

  @override
  String get orgCreateStreetAddress => 'पूरा पता';

  @override
  String get orgCreateStreetAddressHint => 'बिल्डिंग, गली, इलाका…';

  @override
  String orgCreateSuccess(String name) {
    return 'कंपनी \"$name\" बन गई!';
  }

  @override
  String get orgCreateTitle => 'कंपनी बनाएं';

  @override
  String get orgManageAllCaughtUp => 'सब निपट गया!';

  @override
  String get orgManageApproveAssign => 'मंज़ूर करें और भूमिका दें';

  @override
  String orgManageApproveFailed(String error) {
    return 'यूज़र को मंज़ूर नहीं किया जा सका: $error';
  }

  @override
  String orgManageApproveTitle(String username) {
    return '$username को मंज़ूर करें';
  }

  @override
  String orgManageApproved(String username) {
    return '$username को मंज़ूर कर दिया गया';
  }

  @override
  String get orgManageAssignRole => 'भूमिका दें';

  @override
  String get orgManageChangeRole => 'भूमिका बदलें';

  @override
  String orgManageHeaderSummary(int members, int pending) {
    return '$members सदस्य · $pending पेंडिंग';
  }

  @override
  String get orgManageLoadFailed => 'कंपनी का डेटा लोड नहीं हो सका।';

  @override
  String get orgManageMembersHint => 'सदस्य यहां दिखेंगे';

  @override
  String orgManageMembersTab(int count) {
    return 'सदस्य ($count)';
  }

  @override
  String orgManageNewRoleFor(String username) {
    return '$username के लिए नई भूमिका';
  }

  @override
  String get orgManageNoMembers => 'अभी कोई सदस्य नहीं है';

  @override
  String get orgManageNoPending => 'कोई पेंडिंग जुड़ने की रिक्वेस्ट नहीं है';

  @override
  String orgManageNoResults(String query) {
    return '\"$query\" के लिए कुछ नहीं मिला';
  }

  @override
  String get orgManageNoRole => 'कोई भूमिका नहीं';

  @override
  String get orgManageOwner => 'ओनर';

  @override
  String get orgManagePendingBadge => 'पेंडिंग';

  @override
  String orgManagePendingTab(int count) {
    return 'पेंडिंग ($count)';
  }

  @override
  String get orgManageRefresh => 'रीफ़्रेश करें';

  @override
  String get orgManageReject => 'अस्वीकार करें';

  @override
  String orgManageRejectConfirm(String username) {
    return '$username की जुड़ने की रिक्वेस्ट अस्वीकार करें?';
  }

  @override
  String orgManageRejectFailed(String error) {
    return 'अस्वीकार नहीं हो सका: $error';
  }

  @override
  String get orgManageRejectUserTitle => 'यूज़र को अस्वीकार करें';

  @override
  String orgManageRejected(String username) {
    return '$username को अस्वीकार कर दिया गया';
  }

  @override
  String get orgManageRemove => 'हटाएं';

  @override
  String orgManageRemoveConfirm(String username, String orgName) {
    return '$username को $orgName से हटाएं? उनका एक्सेस तुरंत बंद हो जाएगा।';
  }

  @override
  String orgManageRemoveFailed(String error) {
    return 'हटाया नहीं जा सका: $error';
  }

  @override
  String get orgManageRemoveTitle => 'सदस्य हटाएं';

  @override
  String orgManageRemoved(String username) {
    return '$username को हटा दिया गया';
  }

  @override
  String orgManageRequestedRole(String role) {
    return 'मांगी गई भूमिका: $role';
  }

  @override
  String get orgManageRoleAdmin => 'एडमिन';

  @override
  String get orgManageRoleAdminDesc => 'सदस्य और सेटिंग संभालें';

  @override
  String get orgManageRoleDispatcher => 'डिस्पैचर';

  @override
  String get orgManageRoleDispatcherDesc => 'ट्रिप और असाइनमेंट संभालें';

  @override
  String orgManageRoleUpdateFailed(String error) {
    return 'भूमिका अपडेट नहीं हो सकी: $error';
  }

  @override
  String get orgManageRoleUpdated => 'भूमिका अपडेट हो गई';

  @override
  String get orgManageRoleUser => 'यूज़र';

  @override
  String get orgManageRoleUserDesc => 'फ़ीचर का सामान्य एक्सेस';

  @override
  String get orgManageRoleViewer => 'व्यूअर';

  @override
  String get orgManageRoleViewerDesc => 'सिर्फ़ देखने का एक्सेस';

  @override
  String get orgManageSearchHint => 'सदस्य खोजें…';

  @override
  String get orgManageSelectRole => 'देने के लिए भूमिका चुनें';

  @override
  String get orgSelectCreate => 'कंपनी बनाएं';

  @override
  String get orgSelectCreateNew => 'नई कंपनी बनाएं';

  @override
  String get orgSelectCreateNewSub => 'अपनी खुद की फ्लीट कंपनी सेट करें';

  @override
  String get orgSelectNoOrgs => 'अभी कोई कंपनी नहीं है';

  @override
  String get orgSelectNoOrgsBody =>
      'अपनी कंपनी बनाएं या किसी एडमिन से कहें कि वो आपको किसी मौजूदा कंपनी में जोड़ दें।';

  @override
  String get orgSelectNoRole => 'कोई भूमिका नहीं';

  @override
  String get orgSelectSwitchFailed => 'कंपनी स्विच नहीं हो सकी';

  @override
  String orgSelectSwitched(String name) {
    return '$name पर स्विच हो गया';
  }

  @override
  String get orgSelectTitle => 'कंपनी चुनें';

  @override
  String get orgSelectTryAgain => 'दोबारा कोशिश करें';

  @override
  String get orgSelectUser => 'यूज़र';

  @override
  String get orgSelectWelcome => 'फिर से स्वागत है,';

  @override
  String get orgSelectWrong => 'कुछ गड़बड़ हो गई';

  @override
  String get orgSelectYourOrgs => 'आपकी कंपनियां';

  @override
  String get profileAccountStatus => 'अकाउंट की स्थिति';

  @override
  String get profileAuthEmailPassword => 'ईमेल और पासवर्ड';

  @override
  String get profileAuthMethod => 'लॉगिन का तरीका';

  @override
  String get profileAuthSecurityQuestions => 'सुरक्षा सवाल';

  @override
  String get profileBecameDriver => 'भूमिका बदलकर चालक हो गई!';

  @override
  String get profileBecomeDriver => 'चालक बनें';

  @override
  String get profileBecomeDriverTitle => 'चालक बनें';

  @override
  String get profileCancelPendingMessage =>
      'इससे आपकी पेंडिंग रिक्वेस्ट रद्द हो जाएगी और आप फिर से इंडिपेंडेंट यूज़र बन जाएंगे। आप कभी भी दोबारा किसी कंपनी से जुड़ सकते हैं या नई कंपनी बना सकते हैं।';

  @override
  String get profileCancelPendingTitle => 'पेंडिंग रिक्वेस्ट रद्द करें?';

  @override
  String get profileChange => 'बदलें';

  @override
  String get profileChangeOrganization => 'कंपनी बदलें';

  @override
  String get profileChangePassword => 'पासवर्ड बदलें';

  @override
  String get profileChangeRoleChoose => 'भूमिका बदलने का तरीका चुनें:';

  @override
  String get profileChangeRoleFailed => 'भूमिका बदली नहीं जा सकी';

  @override
  String get profileChangeRolePending =>
      'आपकी रिक्वेस्ट पेंडिंग है। आप क्या करना चाहेंगे?';

  @override
  String get profileChangeRoleTitle => 'भूमिका बदलें';

  @override
  String get profileCompany => 'कंपनी';

  @override
  String get profileCreateOrganization => 'कंपनी बनाएं';

  @override
  String get profileDefaultUser => 'यूज़र';

  @override
  String get profileDriverLicenseIntro =>
      'अपने ड्राइविंग लाइसेंस की जानकारी भरें:';

  @override
  String get profileEditBanner =>
      'एडिट मोड — बदलाव सेव करने के लिए टूलबार में ✓ दबाएं';

  @override
  String get profileEditTooltip => 'प्रोफ़ाइल एडिट करें';

  @override
  String get profileEmail => 'ईमेल';

  @override
  String get profileEnterLicenseExpiry =>
      'कृपया लाइसेंस एक्सपायरी की तारीख डालें';

  @override
  String get profileEnterLicenseNumber => 'कृपया लाइसेंस नंबर डालें';

  @override
  String get profileFullName => 'पूरा नाम';

  @override
  String get profileFullNameRequired => 'पूरा नाम ज़रूरी है';

  @override
  String get profileGoIndependent => 'इंडिपेंडेंट बनें';

  @override
  String profileImageReadError(String error) {
    return 'फ़ोटो पढ़ने में दिक्कत: $error';
  }

  @override
  String profileImageSelectError(String error) {
    return 'फ़ोटो चुनने में दिक्कत: $error';
  }

  @override
  String get profileIndependentOptions =>
      'इंडिपेंडेंट यूज़र के तौर पर आप ये कर सकते हैं:';

  @override
  String get profileJoinFailed => 'कंपनी से जुड़ नहीं सके';

  @override
  String get profileJoinOrganization => 'कंपनी से जुड़ें';

  @override
  String get profileJoinSubmitted =>
      'जॉइन रिक्वेस्ट भेज दी गई! मंज़ूरी का इंतज़ार है।';

  @override
  String get profileKeepPending => 'पेंडिंग रहने दें';

  @override
  String get profileLicenseExpiry => 'लाइसेंस एक्सपायरी (YYYY-MM-DD)';

  @override
  String get profileLicenseNumber => 'लाइसेंस नंबर';

  @override
  String get profileNewPhotoSelected =>
      'नई फ़ोटो चुनी गई · लागू करने के लिए सेव करें दबाएं';

  @override
  String get profileNoPreference => 'कोई पसंद नहीं';

  @override
  String get profileNoRole => 'कोई भूमिका नहीं';

  @override
  String get profileNone => 'कोई नहीं';

  @override
  String get profileNotAssigned => 'असाइन नहीं हुई';

  @override
  String get profileNotAvailable => 'उपलब्ध नहीं';

  @override
  String get profileNowIndependent => 'अब आप इंडिपेंडेंट यूज़र हैं।';

  @override
  String get profilePendingOptions =>
      'आपकी रिक्वेस्ट मंज़ूरी के लिए पेंडिंग है। आप ये कर सकते हैं:';

  @override
  String get profilePersonalInfo => 'निजी जानकारी';

  @override
  String get profilePhone => 'फ़ोन';

  @override
  String get profilePhotoAddHint => 'फ़ोटो जोड़ने के लिए टैप करें';

  @override
  String get profilePhotoChangeHint =>
      'फ़ोटो बदलने के लिए टैप करें · हटाने के लिए देर तक दबाएं';

  @override
  String get profileRemove => 'हटाएं';

  @override
  String get profileRemovePictureFailed => 'प्रोफ़ाइल फ़ोटो हटाई नहीं जा सकी';

  @override
  String get profileRemovePictureMessage =>
      'क्या आप अपनी प्रोफ़ाइल फ़ोटो हटाना चाहते हैं?';

  @override
  String get profileRemovePictureTitle => 'प्रोफ़ाइल फ़ोटो हटाएं';

  @override
  String get profileRequestedRole => 'मांगी गई भूमिका (ज़रूरी नहीं)';

  @override
  String get profileRole => 'भूमिका';

  @override
  String get profileRoleAccountant => 'अकाउंटेंट';

  @override
  String get profileRoleComplianceOfficer => 'कंप्लायंस ऑफ़िसर';

  @override
  String get profileRoleCustomerService => 'कस्टमर सर्विस';

  @override
  String get profileRoleDispatcher => 'डिस्पैचर';

  @override
  String get profileRoleFleetManager => 'फ्लीट मैनेजर';

  @override
  String get profileRoleMaintenanceManager => 'मेंटेनेंस मैनेजर';

  @override
  String get profileRoleMaintenanceTechnician => 'मेंटेनेंस टेक्नीशियन';

  @override
  String get profileRoleManaged => 'आपकी भूमिका आपकी कंपनी तय करती है।';

  @override
  String get profileRoleOperationsManager => 'ऑपरेशंस मैनेजर';

  @override
  String get profileRoleOrg => 'भूमिका और कंपनी';

  @override
  String get profileRoleUpdateFailed => 'भूमिका अपडेट नहीं हो सकी';

  @override
  String get profileRoleViewerAnalyst => 'व्यूअर / एनालिस्ट';

  @override
  String get profileStatus => 'प्रोफ़ाइल की स्थिति';

  @override
  String get profileStatusCompleted => 'पूरी हो गई';

  @override
  String get profileStatusIncomplete => 'अधूरी';

  @override
  String get profileStatusLabel => 'स्थिति';

  @override
  String get profileTitle => 'मेरी प्रोफ़ाइल';

  @override
  String get profileUnknown => 'अज्ञात';

  @override
  String get profileUpdateFailed => 'प्रोफ़ाइल अपडेट नहीं हो सकी';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट हो गई!';

  @override
  String get profileUploadPictureFailed => 'प्रोफ़ाइल फ़ोटो अपलोड नहीं हो सकी';

  @override
  String get profileUsername => 'यूज़रनेम';

  @override
  String get customRoleAfterCreateNote =>
      'भूमिका बनने के बाद आपको भूमिका एडिटर में ले जाया जाएगा, जहां आप अनुमतियां सेट कर सकते हैं।';

  @override
  String get customRoleCapabilities => 'अनुमतियां';

  @override
  String customRoleCapabilityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count अनुमतियां',
    );
    return '$_temp0';
  }

  @override
  String get customRoleCatCompliance => 'कंप्लायंस और सेफ्टी';

  @override
  String get customRoleCatCustomer => 'कस्टमर मैनेजमेंट';

  @override
  String get customRoleCatDriver => 'चालक मैनेजमेंट';

  @override
  String get customRoleCatFinancial => 'फाइनेंशियल मैनेजमेंट';

  @override
  String get customRoleCatMaintenance => 'मेंटेनेंस';

  @override
  String get customRoleCatReporting => 'रिपोर्टिंग और एनालिटिक्स';

  @override
  String get customRoleCatRole => 'भूमिका मैनेजमेंट';

  @override
  String get customRoleCatSystem => 'सिस्टम सेटिंग्स';

  @override
  String get customRoleCatTracking => 'ट्रैकिंग और मॉनिटरिंग';

  @override
  String get customRoleCatTrip => 'ट्रिप मैनेजमेंट';

  @override
  String get customRoleCatUser => 'यूज़र मैनेजमेंट';

  @override
  String get customRoleCatVehicle => 'वाहन मैनेजमेंट';

  @override
  String customRoleCategoryEnabled(int enabled, int total) {
    return '$enabled / $total अनुमतियां चालू';
  }

  @override
  String get customRoleChooseMethod => 'बनाने का तरीका चुनें';

  @override
  String get customRoleChooseMethodHint =>
      'पहले से बने टेम्पलेट से शुरू करें या शुरू से बनाएं';

  @override
  String get customRoleCreateButton => 'भूमिका बनाएं';

  @override
  String customRoleCreateFailed(String error) {
    return 'भूमिका नहीं बन सकी: $error';
  }

  @override
  String get customRoleCreateTitle => 'कस्टम भूमिका बनाएं';

  @override
  String get customRoleCreated => 'कस्टम भूमिका बन गई';

  @override
  String get customRoleCreating => 'बना रहे हैं...';

  @override
  String get customRoleDescription => 'विवरण';

  @override
  String get customRoleDescriptionHint => 'इस भूमिका का मकसद बताएं';

  @override
  String get customRoleDescriptionOptional => 'विवरण (ज़रूरी नहीं)';

  @override
  String get customRoleDetailsHint => 'अपनी कस्टम भूमिका का नाम और विवरण दें';

  @override
  String get customRoleDetailsTitle => 'भूमिका की जानकारी';

  @override
  String get customRoleEditTitle => 'कस्टम भूमिका एडिट करें';

  @override
  String customRoleEnabledCount(int enabled, int total) {
    return '$enabled / $total चालू';
  }

  @override
  String get customRoleFromScratch => 'शुरू से';

  @override
  String get customRoleFromScratchDesc =>
      'अपनी अनुमतियों के साथ पूरी तरह कस्टम भूमिका बनाएं। सब कुछ खुद सेट करें।';

  @override
  String get customRoleFromScratchTitle => 'शुरू से बनाएं';

  @override
  String get customRoleFromTemplate => 'टेम्पलेट से';

  @override
  String get customRoleFromTemplateDesc =>
      'शुरुआत के लिए पहले से बने भूमिका टेम्पलेट इस्तेमाल करें। उनकी अनुमतियां लें और अपने हिसाब से बदलें।';

  @override
  String get customRoleFromTemplateTitle => 'टेम्पलेट से शुरू करें';

  @override
  String get customRoleInfoTitle => 'भूमिका की जानकारी';

  @override
  String get customRoleIntersection => 'इंटरसेक्शन (सिर्फ़ कॉमन)';

  @override
  String get customRoleIntersectionCommon => 'इंटरसेक्शन (सिर्फ़ कॉमन)';

  @override
  String get customRoleIntersectionDesc =>
      'सिर्फ़ वही अनुमतियां शामिल करें जो सभी चुने गए टेम्पलेट में हैं';

  @override
  String get customRoleLeave => 'बाहर जाएं';

  @override
  String get customRoleLevelFull => 'पूरा';

  @override
  String get customRoleLevelLimited => 'सीमित';

  @override
  String get customRoleLevelNone => 'कोई नहीं';

  @override
  String get customRoleLevelView => 'देखें';

  @override
  String get customRoleLoadFailed => 'भूमिका लोड नहीं हो सकी';

  @override
  String get customRoleMergeStrategy => 'मिलाने का तरीका';

  @override
  String get customRoleNameHint => 'जैसे, रीजनल मैनेजर - वेस्ट कोस्ट';

  @override
  String get customRoleNameLabel => 'भूमिका का नाम';

  @override
  String get customRoleNameRequired => 'कृपया भूमिका का नाम डालें';

  @override
  String get customRoleNameRequiredShort => 'भूमिका का नाम ज़रूरी है';

  @override
  String get customRoleNoDescription => 'कोई विवरण नहीं';

  @override
  String get customRoleNotSet => '(सेट नहीं है)';

  @override
  String get customRoleQuickAll => 'सभी';

  @override
  String get customRoleReviewHint =>
      'बनाने से पहले अपनी कस्टम भूमिका की जानकारी जांच लें';

  @override
  String get customRoleReviewTitle => 'रिव्यू करें और बनाएं';

  @override
  String get customRoleSaveChanges => 'बदलाव सेव करें';

  @override
  String get customRoleSaving => 'सेव हो रहा है...';

  @override
  String get customRoleSelectOneTemplate => 'कृपया कम से कम एक टेम्पलेट चुनें';

  @override
  String get customRoleSelectTemplates => 'टेम्पलेट चुनें';

  @override
  String get customRoleSelectTemplatesHint =>
      'मिलाने के लिए एक या ज़्यादा टेम्पलेट चुनें';

  @override
  String customRoleSelectedCount(int count) {
    return '$count चुने गए';
  }

  @override
  String get customRoleStay => 'यहीं रुकें';

  @override
  String get customRoleStepDetails => 'जानकारी';

  @override
  String get customRoleStepMethod => 'तरीका';

  @override
  String get customRoleStepReview => 'रिव्यू';

  @override
  String get customRoleStepTemplates => 'टेम्पलेट';

  @override
  String get customRoleSystemCritical =>
      'सिस्टम के लिए अहम – सिर्फ़ सुपर एडमिन के लिए';

  @override
  String customRoleTemplateError(String error) {
    return 'गड़बड़ी: $error';
  }

  @override
  String customRoleTemplatePreselected(String names) {
    return 'टेम्पलेट पहले से चुना गया: $names';
  }

  @override
  String get customRoleUnion => 'यूनियन (सब मिलाएं)';

  @override
  String get customRoleUnionDesc =>
      'चुने गए सभी टेम्पलेट की सभी अनुमतियां शामिल करें';

  @override
  String get customRoleUnsavedBody =>
      'आपके बदलाव सेव नहीं हुए हैं। क्या आप बिना सेव किए बाहर जाना चाहते हैं?';

  @override
  String get customRoleUnsavedTitle => 'बिना सेव किए बदलाव';

  @override
  String get customRoleUpdateFailed => 'भूमिका अपडेट नहीं हो सकी';

  @override
  String customRoleUpdateFailedWithError(String error) {
    return 'भूमिका अपडेट नहीं हो सकी: $error';
  }

  @override
  String get customRoleUpdated => 'भूमिका अपडेट हो गई';

  @override
  String customRolesActiveMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एक्टिव सदस्य',
    );
    return '$_temp0';
  }

  @override
  String get customRolesApprove => 'मंज़ूर करें';

  @override
  String get customRolesApproveFailed => 'रिक्वेस्ट मंज़ूर नहीं हो सकी';

  @override
  String get customRolesApproveTitle => 'रिक्वेस्ट मंज़ूर करें';

  @override
  String customRolesApprovedOk(String name) {
    return '$name को मंज़ूर कर दिया गया!';
  }

  @override
  String customRolesApprovingFrom(String name) {
    return '$name की जॉइन रिक्वेस्ट मंज़ूर की जा रही है।';
  }

  @override
  String get customRolesAssignRole => 'भूमिका दें:';

  @override
  String customRolesCapabilityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count अनुमतियां',
    );
    return '$_temp0';
  }

  @override
  String get customRolesChangeRole => 'भूमिका बदलें';

  @override
  String get customRolesChangeRoleTitle => 'सदस्य की भूमिका बदलें';

  @override
  String get customRolesClone => 'क्लोन करें';

  @override
  String get customRolesCloneFailed => 'क्लोन नहीं हो सका';

  @override
  String get customRolesCloneTitle => 'भूमिका क्लोन करें';

  @override
  String get customRolesCloned => 'भूमिका क्लोन हो गई';

  @override
  String get customRolesCreateFirst => 'अपनी पहली भूमिका बनाएं';

  @override
  String get customRolesCreateFromTemplate =>
      'इस टेम्पलेट से कस्टम भूमिका बनाएं';

  @override
  String get customRolesCreateRole => 'कस्टम भूमिका बनाएं';

  @override
  String get customRolesCustomBadge => 'कस्टम';

  @override
  String get customRolesDeleteConfirm =>
      'क्या आप यह भूमिका हटाना चाहते हैं? इसे वापस नहीं लाया जा सकेगा।';

  @override
  String get customRolesDeleteFailed => 'भूमिका हटाई नहीं जा सकी';

  @override
  String get customRolesDeleteTitle => 'भूमिका हटाएं';

  @override
  String get customRolesDeleted => 'भूमिका हटा दी गई';

  @override
  String get customRolesDescriptionOptional => 'विवरण (ज़रूरी नहीं)';

  @override
  String get customRolesNewRole => 'नई भूमिका:';

  @override
  String get customRolesNewRoleName => 'नई भूमिका का नाम';

  @override
  String get customRolesNoCapabilities => 'कोई अनुमति नहीं दी गई है';

  @override
  String get customRolesNoCustomSubtitle =>
      'अपनी कंपनी के हिसाब से कस्टम भूमिकाएं बनाएं';

  @override
  String get customRolesNoCustomTitle => 'अभी कोई कस्टम भूमिका नहीं है';

  @override
  String get customRolesNoMembersSubtitle =>
      'अपनी कंपनी में सदस्य जोड़ने के लिए पेंडिंग रिक्वेस्ट मंज़ूर करें।';

  @override
  String get customRolesNoMembersTitle => 'अभी कोई सदस्य नहीं है';

  @override
  String get customRolesNoPendingSubtitle =>
      'सभी जॉइन रिक्वेस्ट निपटा दी गई हैं।';

  @override
  String get customRolesNoPendingTitle => 'कोई पेंडिंग रिक्वेस्ट नहीं';

  @override
  String get customRolesNoRole => 'कोई भूमिका नहीं';

  @override
  String get customRolesNoRoleRequested => 'कोई भूमिका नहीं मांगी गई';

  @override
  String get customRolesNoTemplates => 'पहले से बने कोई टेम्पलेट नहीं मिले';

  @override
  String get customRolesNoTemplatesHint =>
      'सर्वर चालू होने पर टेम्पलेट अपने आप जुड़ जाते हैं।';

  @override
  String customRolesPendingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य आपकी कंपनी से जुड़ने का इंतज़ार कर रहे हैं',
    );
    return '$_temp0';
  }

  @override
  String get customRolesRefresh => 'रिफ्रेश करें';

  @override
  String get customRolesReject => 'अस्वीकार करें';

  @override
  String customRolesRejectConfirm(String name) {
    return '$name की जॉइन रिक्वेस्ट अस्वीकार करें? जुड़ने के लिए उन्हें दोबारा अप्लाई करना होगा।';
  }

  @override
  String get customRolesRejectFailed => 'रिक्वेस्ट अस्वीकार नहीं हो सकी';

  @override
  String get customRolesRejectTitle => 'रिक्वेस्ट अस्वीकार करें';

  @override
  String get customRolesRejected => 'रिक्वेस्ट अस्वीकार कर दी गई।';

  @override
  String get customRolesRoleUpdateFailed => 'भूमिका अपडेट नहीं हो सकी';

  @override
  String customRolesRoleUpdated(String name) {
    return '$name की भूमिका अपडेट हो गई';
  }

  @override
  String get customRolesSaveAsTemplate => 'टेम्पलेट के रूप में सेव करें';

  @override
  String get customRolesSavedTemplate => 'सेव किया हुआ टेम्पलेट';

  @override
  String get customRolesSelectRole => 'भूमिका चुनें';

  @override
  String get customRolesSubtitle =>
      'भूमिकाएं, अनुमतियां और टीम के सदस्य मैनेज करें';

  @override
  String get customRolesTabCustom => 'कस्टम';

  @override
  String get customRolesTabMembers => 'सदस्य';

  @override
  String get customRolesTabPending => 'पेंडिंग';

  @override
  String get customRolesTabTemplates => 'टेम्पलेट';

  @override
  String get customRolesTemplateName => 'टेम्पलेट का नाम';

  @override
  String get customRolesTemplateSaveFailed => 'टेम्पलेट सेव नहीं हो सका';

  @override
  String get customRolesTemplateSaved => 'टेम्पलेट के रूप में सेव हो गया';

  @override
  String customRolesTemplatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count टेम्पलेट',
    );
    return '$_temp0';
  }

  @override
  String get customRolesTitle => 'भूमिकाएं और अनुमतियां';

  @override
  String get customRolesUnknown => 'अज्ञात';

  @override
  String get customRolesUnknownRole => 'अज्ञात भूमिका';

  @override
  String get customRolesUpdate => 'अपडेट करें';

  @override
  String customRolesUpdateRoleFor(String name) {
    return '$name की भूमिका अपडेट करें';
  }

  @override
  String get customRolesUse => 'इस्तेमाल करें';

  @override
  String get settingsAbout => 'ऐप के बारे में';

  @override
  String get settingsAppVersion => 'ऐप वर्ज़न';

  @override
  String get settingsAutoSync => 'ऑटो-सिंक डेटा';

  @override
  String get settingsAutoSyncDesc => 'ऑनलाइन होने पर अपने आप सिंक करें';

  @override
  String get settingsBackgroundTracking => 'बैकग्राउंड ट्रैकिंग';

  @override
  String get settingsBackgroundTrackingDesc =>
      'ऐप बैकग्राउंड में हो तब भी ट्रैकिंग जारी रखें';

  @override
  String get settingsBiometricLock => 'बायोमेट्रिक लॉक';

  @override
  String get settingsBiometricLockDesc =>
      'फ़िंगरप्रिंट या Face ID से अनलॉक करें';

  @override
  String get settingsCacheCleared => 'कैश साफ़ हो गया';

  @override
  String get settingsClearCache => 'कैश साफ़ करें';

  @override
  String get settingsClearCacheDesc => 'फ़ोन की स्टोरेज खाली करें';

  @override
  String get settingsClearCacheMessage =>
      'इससे सारा कैश्ड डेटा हट जाएगा और स्टोरेज खाली होगी। आपके अकाउंट का डेटा सुरक्षित रहेगा।';

  @override
  String get settingsCompactView => 'कॉम्पैक्ट व्यू';

  @override
  String get settingsCompactViewDesc => 'स्क्रीन पर ज़्यादा आइटम दिखाएं';

  @override
  String get settingsCurrentlyTracking => 'लोकेशन ट्रैक हो रही है';

  @override
  String get settingsDangerZone => 'ख़तरे का क्षेत्र';

  @override
  String get settingsDataStorage => 'डेटा और स्टोरेज';

  @override
  String get settingsDefaultName => 'फ्लीट मैनेजर';

  @override
  String get settingsDisplay => 'डिस्प्ले';

  @override
  String get settingsDriverUpdates => 'चालक अपडेट';

  @override
  String get settingsDriverUpdatesDesc => 'चालक असाइन होने के अलर्ट';

  @override
  String get settingsFreqBalanced => 'संतुलित';

  @override
  String get settingsFreqBattery => 'बैटरी';

  @override
  String get settingsFreqHigh => 'ज़्यादा';

  @override
  String get settingsFreqLow => 'कम';

  @override
  String get settingsGpsTracking => 'GPS ट्रैकिंग';

  @override
  String get settingsGpsTrackingDescOff =>
      'ट्रैकिंग चालू करने के लिए एडमिनिस्ट्रेटर से संपर्क करें';

  @override
  String get settingsGpsTrackingDescOn =>
      'रियल-टाइम अपडेट के लिए लोकेशन ट्रैकिंग चालू करें';

  @override
  String get settingsGrant => 'अनुमति दें';

  @override
  String get settingsHelpSupport => 'मदद और सहायता';

  @override
  String settingsLocationPermission(String status) {
    return 'लोकेशन की अनुमति: $status';
  }

  @override
  String get settingsLocationTracking => 'लोकेशन और ट्रैकिंग';

  @override
  String settingsMinutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String get settingsNotifications => 'नोटिफ़िकेशन';

  @override
  String get settingsOfflineMode => 'ऑफ़लाइन मोड';

  @override
  String get settingsOfflineModeDesc => 'ऑफ़लाइन इस्तेमाल के लिए डेटा सेव रखें';

  @override
  String get settingsPermAlways => 'हमेशा';

  @override
  String get settingsPermDenied => 'अनुमति नहीं मिली';

  @override
  String get settingsPermDeniedForever => 'अनुमति हमेशा के लिए रोकी गई';

  @override
  String get settingsPermServiceDisabled => 'लोकेशन सर्विस बंद है';

  @override
  String get settingsPermWhileInUse => 'ऐप इस्तेमाल के दौरान';

  @override
  String get settingsPrivacyPolicy => 'प्राइवेसी पॉलिसी';

  @override
  String get settingsPrivacySecurity => 'प्राइवेसी और सिक्योरिटी';

  @override
  String get settingsPushNotifications => 'पुश नोटिफ़िकेशन';

  @override
  String get settingsPushNotificationsDesc => 'ज़रूरी ऐप अलर्ट पाएं';

  @override
  String get settingsResetConfirm => 'रीसेट करें';

  @override
  String get settingsResetDefaults => 'डिफ़ॉल्ट सेटिंग्स पर रीसेट करें';

  @override
  String get settingsResetDefaultsDesc =>
      'सभी सेटिंग्स फ़ैक्टरी डिफ़ॉल्ट पर लौटाएं';

  @override
  String get settingsResetDone => 'सेटिंग्स डिफ़ॉल्ट पर रीसेट हो गईं';

  @override
  String get settingsResetMessage =>
      'इससे सभी सेटिंग्स अपने डिफ़ॉल्ट पर लौट जाएंगी। क्या आप जारी रखना चाहते हैं?';

  @override
  String get settingsResetTitle => 'सेटिंग्स रीसेट करें';

  @override
  String settingsSecondsAgo(int count) {
    return '$count सेकंड पहले';
  }

  @override
  String get settingsShareAnalytics => 'एनालिटिक्स शेयर करें';

  @override
  String get settingsShareAnalyticsDesc =>
      'बिना नाम बताए ऐप को बेहतर बनाने में मदद करें';

  @override
  String get settingsSignOut => 'साइन आउट';

  @override
  String get settingsSignOutDesc => 'अपने अकाउंट से साइन आउट करें';

  @override
  String get settingsSubtitle => 'पसंद और कॉन्फ़िगरेशन';

  @override
  String get settingsTermsOfService => 'सेवा की शर्तें';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeDark => 'डार्क';

  @override
  String get settingsThemeDesc => 'ऐप का रूप चुनें';

  @override
  String get settingsThemeLight => 'लाइट';

  @override
  String get settingsThemeSystem => 'सिस्टम';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsTrackingAdminOff =>
      'GPS ट्रैकिंग बंद है — एडमिनिस्ट्रेटर से संपर्क करें';

  @override
  String get settingsTrackingAdminOn =>
      'एडमिनिस्ट्रेटर ने GPS ट्रैकिंग चालू की है';

  @override
  String get settingsTripUpdates => 'ट्रिप अपडेट';

  @override
  String get settingsTripUpdatesDesc => 'ट्रिप की स्थिति में बदलाव';

  @override
  String get settingsUpToDate => 'अप टू डेट';

  @override
  String get settingsUpdateFrequency => 'अपडेट कितनी बार';

  @override
  String get settingsUpdateFrequencyDesc => 'लोकेशन कितनी बार अपडेट हो';

  @override
  String get settingsVehicleAlerts => 'वाहन अलर्ट';

  @override
  String get settingsVehicleAlertsDesc => 'मेंटेनेंस और स्थिति के अलर्ट';

  @override
  String get settingsViewLiveTracking => 'लाइव ट्रैकिंग देखें';

  @override
  String get settingsViewLiveTrackingDesc =>
      'नक्शे पर अपनी मौजूदा लोकेशन देखें';

  @override
  String get vehAddChooseFile => 'फ़ाइल चुनें';

  @override
  String get vehAddChoosePhoto => 'फोटो चुनें';

  @override
  String get vehAddFillRequired => 'कृपया सभी ज़रूरी जानकारी भरें';

  @override
  String get vehAddFuelCng => 'CNG';

  @override
  String get vehAddFuelDiesel => 'डीज़ल';

  @override
  String get vehAddFuelElectric => 'इलेक्ट्रिक';

  @override
  String get vehAddFuelHybrid => 'हाइब्रिड';

  @override
  String get vehAddFuelLpg => 'LPG';

  @override
  String get vehAddFuelPetrol => 'पेट्रोल';

  @override
  String get vehAddFuelType => 'ईंधन का प्रकार *';

  @override
  String vehAddHintExample(String value) {
    return 'जैसे $value';
  }

  @override
  String get vehAddInfoNote =>
      'यह वाहन जोड़ने पर वह अपने आप आपके मेंटेनेंस शेड्यूल और ईंधन ट्रैकिंग लॉग से जुड़ जाएगा। निर्माता की ओर से रिकॉल की सूचना पाने के लिए VIN सही डालें।';

  @override
  String get vehAddInvalidYear => 'कृपया सही साल डालें';

  @override
  String get vehAddLicensePlate => 'नंबर प्लेट *';

  @override
  String get vehAddMake => 'मेक *';

  @override
  String get vehAddModel => 'मॉडल *';

  @override
  String get vehAddOdometer => 'शुरुआती ओडोमीटर (किमी)';

  @override
  String vehAddPhotoFailed(String error) {
    return 'वाहन बन गया, लेकिन फोटो अपलोड नहीं हो सकी: $error';
  }

  @override
  String get vehAddPhotoSubtitle =>
      'अच्छी क्वालिटी की फोटो अपलोड करें या खींचें';

  @override
  String get vehAddPhotoTitle => 'वाहन की फोटो';

  @override
  String get vehAddRegister => 'वाहन रजिस्टर करें';

  @override
  String get vehAddRegistering => 'रजिस्टर हो रहा है...';

  @override
  String get vehAddRemovePhoto => 'फोटो हटाएं';

  @override
  String get vehAddSectionIdentification => 'पहचान';

  @override
  String get vehAddSectionSpecifications => 'स्पेसिफिकेशन';

  @override
  String get vehAddSectionTechnical => 'तकनीकी जानकारी';

  @override
  String get vehAddSuccess => 'वाहन सफलतापूर्वक रजिस्टर हो गया!';

  @override
  String get vehAddTakePhoto => 'फोटो खींचें';

  @override
  String get vehAddTypeBus => 'बस';

  @override
  String get vehAddTypeCar => 'कार';

  @override
  String get vehAddTypeMotorcycle => 'मोटरसाइकिल';

  @override
  String get vehAddTypeOther => 'अन्य';

  @override
  String get vehAddTypeSuv => 'SUV';

  @override
  String get vehAddTypeTruck => 'ट्रक';

  @override
  String get vehAddTypeVan => 'वैन';

  @override
  String get vehAddVehicleNumber => 'वाहन नंबर *';

  @override
  String get vehAddVehicleType => 'वाहन का प्रकार *';

  @override
  String get vehAddVin => 'VIN (ज़रूरी नहीं)';

  @override
  String get vehAddVinHint => '17 अक्षर का VIN';

  @override
  String get vehAddYear => 'साल *';

  @override
  String get vehListClearFilters => 'फ़िल्टर हटाएं';

  @override
  String get vehListEmptyHint => 'शुरू करने के लिए अपना पहला वाहन जोड़ें';

  @override
  String get vehListEmptyTitle => 'अभी कोई वाहन नहीं';

  @override
  String get vehListFilterAll => 'सभी वाहन';

  @override
  String vehListKm(String value) {
    return '$value किमी';
  }

  @override
  String get vehListNoDriver => 'कोई चालक नहीं';

  @override
  String get vehListNoDriverAssigned => 'कोई चालक असाइन नहीं है';

  @override
  String get vehListNotFoundHint => 'अपनी खोज या फ़िल्टर बदलकर देखें';

  @override
  String get vehListNotFoundTitle => 'कोई वाहन नहीं मिला';

  @override
  String vehListRegisteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वाहन रजिस्टर हैं',
    );
    return '$_temp0';
  }

  @override
  String get vehListSearchHint => 'रजिस्ट्रेशन, मेक, मॉडल से खोजें...';

  @override
  String get vehListSortMake => 'मेक';

  @override
  String get vehListSortMileage => 'माइलेज';

  @override
  String get vehListSortRegistration => 'रजिस्ट्रेशन';

  @override
  String get vehListStatusActive => 'एक्टिव';

  @override
  String get vehListStatusInactive => 'इनएक्टिव';

  @override
  String get vehListStatusMaintenance => 'मेंटेनेंस';

  @override
  String get vehListTitle => 'फ्लीट वाहन';

  @override
  String get bookingActionFailed => 'काम पूरा नहीं हो सका - फिर कोशिश करें';

  @override
  String get bookingReasonLabel => 'कारण (ज़रूरी)';

  @override
  String get bookingReasonHint => 'लिखें कि क्यों रद्द किया जा रहा है';

  @override
  String get bookingAreYouSure => 'क्या आप पक्का हैं?';

  @override
  String get bookingNoGoBack => 'नहीं, वापस जाएं';

  @override
  String get bookingWeightRecorded =>
      'ट्रक लोड हो चुका है (वज़न दर्ज है), इसलिए यह बुकिंग रद्द नहीं हो सकती।';

  @override
  String get bookingCancelTitle => 'ट्रक की बुकिंग रद्द करें';

  @override
  String get bookingCancelPointRr =>
      'बुकिंग RR web में तुरंत आपके कारण के साथ रद्द हो जाएगी।';

  @override
  String get bookingCancelPointTrip =>
      'इस ट्रिप से ट्रक, चालक और ट्रक ओनर, उनके स्टेज 1 के कागज़ और स्टेज 2-3 की ट्रक जांच हट जाएंगी। लोडिंग स्लिप, ई-वे बिल और इनवॉइस रहेंगे।';

  @override
  String get bookingCancelPointNext =>
      'फिर दूसरा ट्रक बुक करें या ट्रिप रद्द करें।';

  @override
  String get bookingCancelPointNoUndo => 'यह वापस नहीं हो सकता।';

  @override
  String bookingCancelSure(String vehicle) {
    return 'ट्रक $vehicle की बुकिंग रद्द करें? यह वापस नहीं हो सकता।';
  }

  @override
  String get bookingCancelYes => 'हां, बुकिंग रद्द करें';

  @override
  String get bookingCancelDone => 'बुकिंग रद्द हो गई';

  @override
  String get bookingCancelTripBookedFirst => 'पहले बुकिंग रद्द करें';

  @override
  String get bookingCancelTripTitle => 'ट्रिप रद्द करें';

  @override
  String get bookingCancelTripPointRr =>
      'ट्रिप RR web में तुरंत रद्द हो जाएगी।';

  @override
  String get bookingCancelTripPointReason =>
      'आपका कारण इस ऐप में रखा जाएगा (RR web में इसकी जगह नहीं है)।';

  @override
  String get bookingCancelTripPointNoUndo =>
      'रद्द हुई ट्रिप फिर कभी बुक या सिंक नहीं हो सकती।';

  @override
  String bookingCancelTripSure(String trip) {
    return 'ट्रिप $trip रद्द करें? यह वापस नहीं हो सकता।';
  }

  @override
  String get bookingCancelTripYes => 'हां, ट्रिप रद्द करें';

  @override
  String get bookingCancelTripDone => 'ट्रिप रद्द हो गई';

  @override
  String get bookingRebookTitle => 'दूसरा ट्रक बुक करें';

  @override
  String bookingRebookIntro(String trip) {
    return 'ट्रिप $trip: ट्रक ओनर की कंपनी, ट्रक, उसका चालक और बुकिंग रकम चुनें। ट्रक RR web में तुरंत बुक होगा; फिर नए ट्रक के लिए स्टेज 1 भरें।';
  }

  @override
  String get bookingRebookProviderPhone => 'ट्रक देने वाले का फ़ोन नंबर';

  @override
  String get bookingRebookFind => 'खोजें';

  @override
  String get bookingRebookCompany => 'ट्रक ओनर की कंपनी';

  @override
  String get bookingRebookNoCompany => 'इस व्यक्ति की RR में कोई कंपनी नहीं है';

  @override
  String get bookingRebookTruck => 'ट्रक';

  @override
  String get bookingRebookNoTrucks => 'इस कंपनी के RR में कोई ट्रक नहीं हैं';

  @override
  String get bookingRebookDriver => 'चालक';

  @override
  String get bookingRebookDriverHint =>
      'इस ट्रक का RR में कोई चालक नहीं है - नाम या फ़ोन से चालक खोजें';

  @override
  String get bookingRebookAmount => 'बुकिंग रकम';

  @override
  String bookingRebookSure(String vehicle, String driver) {
    return 'ट्रक $vehicle को चालक $driver के साथ अभी RR web में बुक करें?';
  }

  @override
  String get bookingRebookYes => 'ट्रक बुक करें';

  @override
  String get bookingRebookDone => 'ट्रक बुक हो गया - अब स्टेज 1 भरें';

  @override
  String get bookingMenuCancelBooking => 'बुकिंग रद्द करें';

  @override
  String get bookingMenuNoCancelWeight =>
      'बुकिंग रद्द नहीं हो सकती (वज़न दर्ज है)';

  @override
  String get bookingMenuRebook => 'दूसरा ट्रक बुक करें';

  @override
  String get bookingMenuCancelTrip => 'ट्रिप रद्द करें';

  @override
  String get bookingMenuCancelTripDisabled =>
      'ट्रिप रद्द करें (पहले बुकिंग रद्द करें)';

  @override
  String get bookingMoreActions => 'और विकल्प';

  @override
  String get bookingBannerCancelled => 'बुकिंग रद्द है - दूसरा ट्रक बुक करें';

  @override
  String get bookingHistoryTitle => 'रद्द करने का रिकॉर्ड';

  @override
  String bookingHistoryWhenBy(String when, String user) {
    return '$when · $user द्वारा';
  }

  @override
  String bookingHistoryReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String get stageS1AadhaarStart => 'आधार नंबर 0 या 1 से शुरू नहीं हो सकता';

  @override
  String get tripCardFeBookingCancelled => 'ट्रक की बुकिंग रद्द है';

  @override
  String get tripCardFeBookingCancelledHint => 'पहले दूसरा ट्रक बुक होने दें';

  @override
  String get tripCardFeTripCancelled => 'ट्रिप रद्द है';

  @override
  String get tripCardFeTripCancelledHint => 'दूसरी खुली ट्रिप भरें';

  @override
  String get stageBookingCancelledHint => 'पहले दूसरे वाहन ओनर को बुक करें';

  @override
  String get bookingHistoryTitleAll => 'बुकिंग का रिकॉर्ड';

  @override
  String get rrWebUpdatedEntry => 'RR वेब पर अपडेट हुआ';

  @override
  String rrWebChangedFields(String fields) {
    return 'बदला गया: $fields';
  }

  @override
  String get rrWebTripCancelled => 'RR वेब पर ट्रिप रद्द हुई';

  @override
  String get rrWebBookingCancelled => 'RR वेब पर बुकिंग रद्द हुई';

  @override
  String get rrWebRebooked => 'RR वेब पर दूसरा ट्रक बुक हुआ';

  @override
  String get rrWebDriverChanged => 'RR वेब पर चालक बदला गया';

  @override
  String rrWebTruckChange(String oldTruck, String newTruck) {
    return 'ट्रक: $oldTruck → $newTruck';
  }

  @override
  String rrWebNewDriver(String name) {
    return 'नया चालक: $name';
  }

  @override
  String get rrWebUpdated => 'RR वेब पर बदलाव हुआ - ट्रिप अपडेट हो गई';
}
