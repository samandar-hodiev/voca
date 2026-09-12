// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get back => 'Back';

  @override
  String get navHome => 'Home';

  @override
  String get navPractice => 'Practice';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceHint => 'Choose how the app looks.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHint => 'Choose the language of the app.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemHint => 'Follows your phone\'s setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightHint => 'Always light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkHint => 'Always dark';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameUz => 'O‘zbekcha';

  @override
  String get languageNameRu => 'Русский';

  @override
  String get continueAction => 'Continue';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get sendCode => 'Send code';

  @override
  String get cancel => 'Cancel';

  @override
  String get signIn => 'Sign in';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHelper => 'At least 8 characters';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordConfirmLabel => 'Confirm password';

  @override
  String get passwordTooShort => 'Your password must be at least 8 characters.';

  @override
  String get passwordsDontMatch => 'The passwords don’t match.';

  @override
  String get codeSentPrefix => 'We sent a 6-digit code to ';

  @override
  String codeSentToEmail(String email) {
    return 'Code sent to $email';
  }

  @override
  String get resend => 'Resend';

  @override
  String resendIn(int seconds) {
    return 'Resend ($seconds)';
  }

  @override
  String get authEntryTitle => 'Create your Voca account';

  @override
  String get authEntrySubtitle =>
      'Your progress is saved and available on all your devices.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get guestNote =>
      'You can practise as a guest too. If you create an account later, your progress is kept.';

  @override
  String get avatarRequired => 'A profile photo is required.';

  @override
  String get firstNameRequired => 'Enter your first name.';

  @override
  String get lastNameRequired => 'Enter your last name.';

  @override
  String get phoneRequired => 'Enter your phone number.';

  @override
  String get phoneInvalid => 'Enter a valid number, e.g. +998 90 123 45 67.';

  @override
  String get avatarUploadFailed =>
      'Your account was created, but the photo didn’t upload. You can add it later in settings.';

  @override
  String get createProfileTitle => 'Complete your profile';

  @override
  String get createAccount => 'Create account';

  @override
  String get verified => 'Verified';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHelper => 'e.g. +998 90 123 45 67';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get enterEmailTitle => 'Enter your email';

  @override
  String get enterEmailSubtitle => 'We’ll send a 6-digit code to confirm it.';

  @override
  String get signInWithThisEmail => 'Sign in with this email';

  @override
  String get verifyEmailTitle => 'Confirm your email';

  @override
  String get codeNotReceived => 'Didn’t get the code? ';

  @override
  String get useAnotherEmail => 'Use a different email';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordSubtitle =>
      'We’ll send a one-time code to your email.';

  @override
  String get enterCodeTitle => 'Enter the code';

  @override
  String get newPassword => 'New password';

  @override
  String get newPasswordSubtitle => 'You’ll be signed out on all your devices.';

  @override
  String get saveAndSignIn => 'Save and sign in';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue.';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get errorInvalidEmail => 'That email address isn’t valid.';

  @override
  String get errorEmailMismatch =>
      'This email isn’t the one on your account. Enter the email you signed up with.';

  @override
  String get errorEmailExists =>
      'An account with this email already exists. Sign in or reset your password.';

  @override
  String get errorInvalidCode => 'That code isn’t right. Try again.';

  @override
  String get errorCodeExpired => 'This code has expired. Ask for a new one.';

  @override
  String get errorTooManyAttempts => 'Too many attempts. Ask for a new code.';

  @override
  String get errorTooManyRequests => 'Too many requests. Please wait a moment.';

  @override
  String get errorInvalidPassword =>
      'The password must be at least 8 characters.';

  @override
  String get errorNotVerified => 'Confirm your email first.';

  @override
  String get errorValidation => 'Some of the details aren’t right.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorSessionExpired => 'Your session has ended. Sign in again.';

  @override
  String get errorNoInternet => 'No internet connection.';

  @override
  String get errorServerUnreachable =>
      'Couldn’t reach the server. Check that it is running and that you are on the same network.';

  @override
  String get errorEmailDelivery =>
      'We couldn’t send an email to this address. Try another email or try again later.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountIntro =>
      'Deleting your account is permanent. It cannot be undone.';

  @override
  String get deleteAccountEmailNote =>
      'Enter the email your account uses. We’ll send a confirmation code to it.';

  @override
  String get deleteConfirmTitle => 'Delete your account?';

  @override
  String get deleteConfirmQuestion =>
      'Are you sure you want to delete your account?';

  @override
  String get deleteConfirmWarning =>
      'Your previous practice data, progress and premium subscription will not be saved after account deletion.';

  @override
  String get deleteConfirmYes => 'Yes, delete';

  @override
  String get answerNo => 'No';

  @override
  String get languageSelectTitle => 'Choose language';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutQuestion => 'Are you sure you want to sign out?';

  @override
  String get signOutGuestWarning =>
      'A guest account has no email. Once you sign out, you won’t be able to get back to your progress.';

  @override
  String get signOutCodeNote =>
      'To confirm, we’ll send a code to your account’s email.';

  @override
  String get signOutConfirm => 'Yes, sign out';

  @override
  String get signOutVerifyTitle => 'Confirm sign-out';

  @override
  String get signOutEnterEmail =>
      'Enter the email your account uses. We’ll send a confirmation code to it.';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get started';

  @override
  String get next => 'Next';

  @override
  String pageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get splashSemantic => 'Voca. Loading.';

  @override
  String get splashTagline => 'Practise your pronunciation';

  @override
  String get onboardingTitle1 => 'Pronounce clearly';

  @override
  String get onboardingBody1 =>
      'Practise saying English words correctly. Listen to a model for every word.';

  @override
  String get onboardingTitle2 => 'Your voice is analysed';

  @override
  String get onboardingBody2 =>
      'Record your pronunciation. Every sound is scored on its own, and you see exactly where you went wrong.';

  @override
  String get onboardingTitle3 => 'A little every day';

  @override
  String get onboardingBody3 =>
      'The sounds you struggle with are tracked. Daily practice and a streak make the progress stick.';

  @override
  String get levelTitle => 'How well do you know English?';

  @override
  String get levelSubtitle => 'Practice will match your level.';

  @override
  String get goalTitle => 'Why are you learning English?';

  @override
  String get goalSubtitle => 'This shapes your recommendations.';

  @override
  String get dailyGoalTitle => 'How much will you practise each day?';

  @override
  String get dailyGoalSubtitle => 'You can change this later in settings.';

  @override
  String wordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get recommended => 'Recommended';

  @override
  String aboutMinutes(int minutes) {
    return 'About $minutes min';
  }

  @override
  String cefrLevelName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'A1': 'Beginner',
      'A2': 'Elementary',
      'B1': 'Intermediate',
      'B2': 'Upper intermediate',
      'C1': 'Advanced',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String cefrLevelHint(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'A1': 'Simple words and phrases',
      'A2': 'Everyday small talk',
      'B1': 'I talk freely on familiar topics',
      'B2': 'I understand complex texts',
      'C1': 'I speak almost fluently',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String learningGoalName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'pronunciation': 'Improve my pronunciation',
      'confidence': 'Speak with confidence',
      'ielts': 'Prepare for IELTS',
      'vocabulary': 'Grow my vocabulary',
      'work': 'English for work',
      'everyday': 'Everyday conversation',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get learningSettings => 'Learning settings';

  @override
  String get levelLabel => 'Level';

  @override
  String get goalLabel => 'Goal';

  @override
  String get dailyGoalLabel => 'Daily goal';

  @override
  String get notChosen => 'Not chosen';

  @override
  String get homeLoadFailed => 'Couldn’t load the home screen.';

  @override
  String get recommendedPractice => 'Recommended practice';

  @override
  String get recommendedPracticeHint => 'Words that target your weak sounds';

  @override
  String get weakSounds => 'Weak sounds';

  @override
  String get weakSoundsHint => 'Need more attention';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get readyToPractise => 'Ready to practise?';

  @override
  String get openProfile => 'Open profile';

  @override
  String todayGoalSemantic(int done, int goal) {
    return 'Today’s goal: $done of $goal words';
  }

  @override
  String get wordsUnit => 'words';

  @override
  String get goalReached => 'Goal reached';

  @override
  String get todayGoal => 'Today’s goal';

  @override
  String get goalReachedNote => 'Great work. Keep going if you like.';

  @override
  String wordsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words left',
      one: '1 word left',
    );
    return '$_temp0';
  }

  @override
  String get startPractice => 'Start practice';

  @override
  String get streak => 'Streak';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get daysInARow => 'Days in a row';

  @override
  String get latestScore => 'Latest score';

  @override
  String get noPracticeYet => 'No practice yet';

  @override
  String get noPracticeYetSentence => 'No practice yet.';

  @override
  String pointsThisWeek(String sign, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$sign$points points this week',
      one: '${sign}1 point this week',
    );
    return '$_temp0';
  }

  @override
  String practiseWordSemantic(String word, String level) {
    return 'Practise “$word”, level $level';
  }

  @override
  String get noWeakSoundsYet => 'No weak sounds found yet.';

  @override
  String get loading => 'Loading';

  @override
  String get practiceSubtitle => 'Words picked for today';

  @override
  String get wordsLoadFailed => 'Couldn’t load the words.';

  @override
  String get noWordsAtLevel => 'No words at this level';

  @override
  String get chooseAnotherLevel => 'Choose another level.';

  @override
  String get showAll => 'Show all';

  @override
  String practiceSetSemantic(int total, int done) {
    return '$total words, $done good or mastered';
  }

  @override
  String practiceSetSummary(int total, int done) {
    return '$total words · $done good';
  }

  @override
  String get allLevels => 'All';

  @override
  String levelSemantic(String level) {
    return 'Level $level';
  }

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get statusNeedsWork => 'Needs work';

  @override
  String get statusGood => 'Good';

  @override
  String get statusMastered => 'Mastered';

  @override
  String wordCardSemantic(String word, String level, String status) {
    return '$word, level $level, $status';
  }

  @override
  String bestScoreSemantic(int score) {
    return ', best score $score';
  }

  @override
  String get practiseAction => 'Practise';

  @override
  String get recordingUnavailable => 'Record your voice, not available yet';

  @override
  String get scoringComingNext =>
      'Pronunciation scoring arrives in the next stage.';

  @override
  String get close => 'Close';

  @override
  String get profileLoadFailed => 'Couldn’t load your profile.';

  @override
  String get subscription => 'Subscription';

  @override
  String get appSection => 'App';

  @override
  String get guest => 'Guest';

  @override
  String get noName => 'No name';

  @override
  String get viaGoogle => 'Via Google';

  @override
  String get guestMode => 'Guest mode';

  @override
  String get viaEmail => 'Via email';

  @override
  String get progressNotSaved => 'Progress isn’t saved';

  @override
  String get freePlan => 'Free plan';

  @override
  String get premiumSoon => 'Premium features coming soon';

  @override
  String get active => 'Active';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get progressLoadFailed => 'Couldn’t load your progress.';

  @override
  String get weeklyActivity => 'Weekly activity';

  @override
  String get againstDailyGoal => 'Against your daily goal';

  @override
  String get byAccuracy => 'By accuracy';

  @override
  String get recentPractice => 'Recent practice';

  @override
  String averageScoreSemantic(int score) {
    return 'Average pronunciation score $score out of 100';
  }

  @override
  String get averageScore => 'Average pronunciation score';

  @override
  String pointsDelta(String sign, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$sign$points points',
      one: '${sign}1 point',
    );
    return '$_temp0';
  }

  @override
  String get comparedWithLastWeek => 'Compared with last week';

  @override
  String get wordsPractised => 'Words practised';

  @override
  String get total => 'Total';

  @override
  String bestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Best: $count days',
      one: 'Best: 1 day',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String recordSemantic(String word, String when, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '1 point',
    );
    return '$word, $when, $_temp0';
  }

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      '7': 'Sun',
      'other': '$day',
    });
    return '$_temp0';
  }

  @override
  String get goalMetSuffix => ', goal met';

  @override
  String get dailyGoalMet => 'Daily goal met';

  @override
  String weakSoundSemantic(String symbol, String example, num accuracy) {
    return 'The /$symbol/ sound, as in $example. Accuracy $accuracy percent';
  }

  @override
  String forExample(String example) {
    return 'e.g. $example';
  }

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get chooseProfilePhoto => 'Choose a profile photo';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get addProfilePhoto => 'Add a profile photo';

  @override
  String get photoSelected => 'Photo selected';

  @override
  String get verificationCode => 'Verification code';

  @override
  String soundSemantic(String symbol) {
    return '$symbol sound';
  }

  @override
  String get retry => 'Retry';

  @override
  String get notImplementedYet => 'Not implemented yet';

  @override
  String weakSoundOpen(String symbol) {
    return 'See results for the /$symbol/ sound';
  }
}
