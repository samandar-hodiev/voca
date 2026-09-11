import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

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
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get navPractice;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app looks.'**
  String get settingsAppearanceHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language of the app.'**
  String get settingsLanguageHint;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone\'s setting'**
  String get themeSystemHint;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeLightHint.
  ///
  /// In en, this message translates to:
  /// **'Always light'**
  String get themeLightHint;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDarkHint.
  ///
  /// In en, this message translates to:
  /// **'Always dark'**
  String get themeDarkHint;

  /// Always in its own language, so anyone can find it.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// Always in its own language, so anyone can find it.
  ///
  /// In en, this message translates to:
  /// **'O‘zbekcha'**
  String get languageNameUz;

  /// Always in its own language, so anyone can find it.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageNameRu;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHelper;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get passwordConfirmLabel;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don’t match.'**
  String get passwordsDontMatch;

  /// Followed by the email address in bold.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to '**
  String get codeSentPrefix;

  /// No description provided for @codeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String codeSentToEmail(String email);

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend ({seconds})'**
  String resendIn(int seconds);

  /// No description provided for @authEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your Voca account'**
  String get authEntryTitle;

  /// No description provided for @authEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved and available on all your devices.'**
  String get authEntrySubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccount;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @guestNote.
  ///
  /// In en, this message translates to:
  /// **'You can practise as a guest too. If you create an account later, your progress is kept.'**
  String get guestNote;

  /// No description provided for @avatarRequired.
  ///
  /// In en, this message translates to:
  /// **'A profile photo is required.'**
  String get avatarRequired;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name.'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name.'**
  String get lastNameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number.'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number, e.g. +998 90 123 45 67.'**
  String get phoneInvalid;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your account was created, but the photo didn’t upload. You can add it later in settings.'**
  String get avatarUploadFailed;

  /// No description provided for @createProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get createProfileTitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. +998 90 123 45 67'**
  String get phoneHelper;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @enterEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmailTitle;

  /// No description provided for @enterEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a 6-digit code to confirm it.'**
  String get enterEmailSubtitle;

  /// No description provided for @signInWithThisEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with this email'**
  String get signInWithThisEmail;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get verifyEmailTitle;

  /// No description provided for @codeNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Didn’t get the code? '**
  String get codeNotReceived;

  /// No description provided for @useAnotherEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useAnotherEmail;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a one-time code to your email.'**
  String get resetPasswordSubtitle;

  /// No description provided for @enterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get enterCodeTitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You’ll be signed out on all your devices.'**
  String get newPasswordSubtitle;

  /// No description provided for @saveAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Save and sign in'**
  String get saveAndSignIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue.'**
  String get signInToContinue;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address isn’t valid.'**
  String get errorInvalidEmail;

  /// No description provided for @errorEmailMismatch.
  ///
  /// In en, this message translates to:
  /// **'This email isn’t the one on your account. Enter the email you signed up with.'**
  String get errorEmailMismatch;

  /// No description provided for @errorEmailExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in or reset your password.'**
  String get errorEmailExists;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn’t right. Try again.'**
  String get errorInvalidCode;

  /// No description provided for @errorCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Ask for a new one.'**
  String get errorCodeExpired;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Ask for a new code.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get errorTooManyRequests;

  /// No description provided for @errorInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'The password must be at least 8 characters.'**
  String get errorInvalidPassword;

  /// No description provided for @errorNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first.'**
  String get errorNotVerified;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some of the details aren’t right.'**
  String get errorValidation;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoInternet;

  /// No description provided for @errorEmailDelivery.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t send an email to this address. Try another email or try again later.'**
  String get errorEmailDelivery;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutQuestion;

  /// No description provided for @signOutGuestWarning.
  ///
  /// In en, this message translates to:
  /// **'A guest account has no email. Once you sign out, you won’t be able to get back to your progress.'**
  String get signOutGuestWarning;

  /// No description provided for @signOutCodeNote.
  ///
  /// In en, this message translates to:
  /// **'To confirm, we’ll send a code to your account’s email.'**
  String get signOutCodeNote;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, sign out'**
  String get signOutConfirm;

  /// No description provided for @signOutVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm sign-out'**
  String get signOutVerifyTitle;

  /// No description provided for @signOutEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the email your account uses. We’ll send a confirmation code to it.'**
  String get signOutEnterEmail;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOf(int current, int total);

  /// No description provided for @splashSemantic.
  ///
  /// In en, this message translates to:
  /// **'Voca. Loading.'**
  String get splashSemantic;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Practise your pronunciation'**
  String get splashTagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Pronounce clearly'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Practise saying English words correctly. Listen to a model for every word.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Your voice is analysed'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Record your pronunciation. Every sound is scored on its own, and you see exactly where you went wrong.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'A little every day'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'The sounds you struggle with are tracked. Daily practice and a streak make the progress stick.'**
  String get onboardingBody3;

  /// No description provided for @levelTitle.
  ///
  /// In en, this message translates to:
  /// **'How well do you know English?'**
  String get levelTitle;

  /// No description provided for @levelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice will match your level.'**
  String get levelSubtitle;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you learning English?'**
  String get goalTitle;

  /// No description provided for @goalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This shapes your recommendations.'**
  String get goalSubtitle;

  /// No description provided for @dailyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'How much will you practise each day?'**
  String get dailyGoalTitle;

  /// No description provided for @dailyGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings.'**
  String get dailyGoalSubtitle;

  /// No description provided for @wordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordsCount(int count);

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @aboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min'**
  String aboutMinutes(int minutes);

  /// No description provided for @cefrLevelName.
  ///
  /// In en, this message translates to:
  /// **'{code, select, A1{Beginner} A2{Elementary} B1{Intermediate} B2{Upper intermediate} C1{Advanced} other{{code}}}'**
  String cefrLevelName(String code);

  /// No description provided for @cefrLevelHint.
  ///
  /// In en, this message translates to:
  /// **'{code, select, A1{Simple words and phrases} A2{Everyday small talk} B1{I talk freely on familiar topics} B2{I understand complex texts} C1{I speak almost fluently} other{{code}}}'**
  String cefrLevelHint(String code);

  /// No description provided for @learningGoalName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, pronunciation{Improve my pronunciation} confidence{Speak with confidence} ielts{Prepare for IELTS} vocabulary{Grow my vocabulary} work{English for work} everyday{Everyday conversation} other{{id}}}'**
  String learningGoalName(String id);

  /// No description provided for @learningSettings.
  ///
  /// In en, this message translates to:
  /// **'Learning settings'**
  String get learningSettings;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoalLabel;

  /// No description provided for @notChosen.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get notChosen;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the home screen.'**
  String get homeLoadFailed;

  /// No description provided for @recommendedPractice.
  ///
  /// In en, this message translates to:
  /// **'Recommended practice'**
  String get recommendedPractice;

  /// No description provided for @recommendedPracticeHint.
  ///
  /// In en, this message translates to:
  /// **'Words that target your weak sounds'**
  String get recommendedPracticeHint;

  /// No description provided for @weakSounds.
  ///
  /// In en, this message translates to:
  /// **'Weak sounds'**
  String get weakSounds;

  /// No description provided for @weakSoundsHint.
  ///
  /// In en, this message translates to:
  /// **'Need more attention'**
  String get weakSoundsHint;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @readyToPractise.
  ///
  /// In en, this message translates to:
  /// **'Ready to practise?'**
  String get readyToPractise;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @todayGoalSemantic.
  ///
  /// In en, this message translates to:
  /// **'Today’s goal: {done} of {goal} words'**
  String todayGoalSemantic(int done, int goal);

  /// Under a fraction such as 7/10.
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get wordsUnit;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get goalReached;

  /// No description provided for @todayGoal.
  ///
  /// In en, this message translates to:
  /// **'Today’s goal'**
  String get todayGoal;

  /// No description provided for @goalReachedNote.
  ///
  /// In en, this message translates to:
  /// **'Great work. Keep going if you like.'**
  String get goalReachedNote;

  /// No description provided for @wordsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word left} other{{count} words left}}'**
  String wordsLeft(int count);

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get startPractice;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @daysInARow.
  ///
  /// In en, this message translates to:
  /// **'Days in a row'**
  String get daysInARow;

  /// No description provided for @latestScore.
  ///
  /// In en, this message translates to:
  /// **'Latest score'**
  String get latestScore;

  /// No description provided for @noPracticeYet.
  ///
  /// In en, this message translates to:
  /// **'No practice yet'**
  String get noPracticeYet;

  /// No description provided for @noPracticeYetSentence.
  ///
  /// In en, this message translates to:
  /// **'No practice yet.'**
  String get noPracticeYetSentence;

  /// No description provided for @pointsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{{sign}1 point this week} other{{sign}{points} points this week}}'**
  String pointsThisWeek(String sign, int points);

  /// No description provided for @practiseWordSemantic.
  ///
  /// In en, this message translates to:
  /// **'Practise “{word}”, level {level}'**
  String practiseWordSemantic(String word, String level);

  /// No description provided for @noWeakSoundsYet.
  ///
  /// In en, this message translates to:
  /// **'No weak sounds found yet.'**
  String get noWeakSoundsYet;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @practiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Words picked for today'**
  String get practiceSubtitle;

  /// No description provided for @wordsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the words.'**
  String get wordsLoadFailed;

  /// No description provided for @noWordsAtLevel.
  ///
  /// In en, this message translates to:
  /// **'No words at this level'**
  String get noWordsAtLevel;

  /// No description provided for @chooseAnotherLevel.
  ///
  /// In en, this message translates to:
  /// **'Choose another level.'**
  String get chooseAnotherLevel;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @practiceSetSemantic.
  ///
  /// In en, this message translates to:
  /// **'{total} words, {done} good or mastered'**
  String practiceSetSemantic(int total, int done);

  /// No description provided for @practiceSetSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} words · {done} good'**
  String practiceSetSummary(int total, int done);

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLevels;

  /// No description provided for @levelSemantic.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelSemantic(String level);

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  /// No description provided for @statusNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get statusNeedsWork;

  /// No description provided for @statusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get statusGood;

  /// No description provided for @statusMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get statusMastered;

  /// No description provided for @wordCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{word}, level {level}, {status}'**
  String wordCardSemantic(String word, String level, String status);

  /// No description provided for @bestScoreSemantic.
  ///
  /// In en, this message translates to:
  /// **', best score {score}'**
  String bestScoreSemantic(int score);

  /// No description provided for @practiseAction.
  ///
  /// In en, this message translates to:
  /// **'Practise'**
  String get practiseAction;

  /// No description provided for @recordingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Record your voice, not available yet'**
  String get recordingUnavailable;

  /// No description provided for @scoringComingNext.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation scoring arrives in the next stage.'**
  String get scoringComingNext;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your profile.'**
  String get profileLoadFailed;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// No description provided for @viaGoogle.
  ///
  /// In en, this message translates to:
  /// **'Via Google'**
  String get viaGoogle;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @viaEmail.
  ///
  /// In en, this message translates to:
  /// **'Via email'**
  String get viaEmail;

  /// No description provided for @progressNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Progress isn’t saved'**
  String get progressNotSaved;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlan;

  /// No description provided for @premiumSoon.
  ///
  /// In en, this message translates to:
  /// **'Premium features coming soon'**
  String get premiumSoon;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @progressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your progress.'**
  String get progressLoadFailed;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly activity'**
  String get weeklyActivity;

  /// No description provided for @againstDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Against your daily goal'**
  String get againstDailyGoal;

  /// No description provided for @byAccuracy.
  ///
  /// In en, this message translates to:
  /// **'By accuracy'**
  String get byAccuracy;

  /// No description provided for @recentPractice.
  ///
  /// In en, this message translates to:
  /// **'Recent practice'**
  String get recentPractice;

  /// No description provided for @averageScoreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Average pronunciation score {score} out of 100'**
  String averageScoreSemantic(int score);

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average pronunciation score'**
  String get averageScore;

  /// No description provided for @pointsDelta.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{{sign}1 point} other{{sign}{points} points}}'**
  String pointsDelta(String sign, int points);

  /// No description provided for @comparedWithLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Compared with last week'**
  String get comparedWithLastWeek;

  /// No description provided for @wordsPractised.
  ///
  /// In en, this message translates to:
  /// **'Words practised'**
  String get wordsPractised;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Best: 1 day} other{Best: {count} days}}'**
  String bestStreak(int count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @recordSemantic.
  ///
  /// In en, this message translates to:
  /// **'{word}, {when}, {score, plural, =1{1 point} other{{score} points}}'**
  String recordSemantic(String word, String when, int score);

  /// No description provided for @weekdayShort.
  ///
  /// In en, this message translates to:
  /// **'{day, select, 1{Mon} 2{Tue} 3{Wed} 4{Thu} 5{Fri} 6{Sat} 7{Sun} other{{day}}}'**
  String weekdayShort(String day);

  /// No description provided for @goalMetSuffix.
  ///
  /// In en, this message translates to:
  /// **', goal met'**
  String get goalMetSuffix;

  /// No description provided for @dailyGoalMet.
  ///
  /// In en, this message translates to:
  /// **'Daily goal met'**
  String get dailyGoalMet;

  /// No description provided for @weakSoundSemantic.
  ///
  /// In en, this message translates to:
  /// **'The /{symbol}/ sound, as in {example}. Accuracy {accuracy} percent'**
  String weakSoundSemantic(String symbol, String example, num accuracy);

  /// No description provided for @forExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. {example}'**
  String forExample(String example);

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @chooseProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a profile photo'**
  String get chooseProfilePhoto;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo'**
  String get addProfilePhoto;

  /// No description provided for @photoSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get photoSelected;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @soundSemantic.
  ///
  /// In en, this message translates to:
  /// **'{symbol} sound'**
  String soundSemantic(String symbol);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @notImplementedYet.
  ///
  /// In en, this message translates to:
  /// **'Not implemented yet'**
  String get notImplementedYet;

  /// No description provided for @weakSoundOpen.
  ///
  /// In en, this message translates to:
  /// **'See results for the /{symbol}/ sound'**
  String weakSoundOpen(String symbol);
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
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
