// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get back => 'Orqaga';

  @override
  String get navHome => 'Bosh sahifa';

  @override
  String get navPractice => 'Mashq';

  @override
  String get navProgress => 'Natijalar';

  @override
  String get navProfile => 'Profil';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsAppearance => 'Ko‘rinish';

  @override
  String get settingsAppearanceHint => 'Ilova qanday ko‘rinishini tanlang.';

  @override
  String get settingsLanguage => 'Til';

  @override
  String get settingsLanguageHint => 'Ilova tilini tanlang.';

  @override
  String get settingsAccount => 'Hisob';

  @override
  String get themeSystem => 'Tizim bo‘yicha';

  @override
  String get themeSystemHint => 'Telefon sozlamasiga ergashadi';

  @override
  String get themeLight => 'Yorug‘';

  @override
  String get themeLightHint => 'Doim yorug‘ ko‘rinish';

  @override
  String get themeDark => 'Qorong‘i';

  @override
  String get themeDarkHint => 'Doim qorong‘i ko‘rinish';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameUz => 'O‘zbekcha';

  @override
  String get languageNameRu => 'Русский';

  @override
  String get continueAction => 'Davom etish';

  @override
  String get confirmAction => 'Tasdiqlash';

  @override
  String get sendCode => 'Kod yuborish';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get signIn => 'Kirish';

  @override
  String get emailLabel => 'Elektron pochta';

  @override
  String get emailHint => 'Pochtangiz';

  @override
  String get passwordLabel => 'Parol';

  @override
  String get passwordHelper => 'Kamida 8 ta belgi';

  @override
  String get passwordHide => 'Parolni yashirish';

  @override
  String get passwordShow => 'Parolni ko‘rsatish';

  @override
  String get passwordConfirmLabel => 'Parolni tasdiqlang';

  @override
  String get passwordTooShort => 'Parol kamida 8 ta belgidan iborat bo‘lsin.';

  @override
  String get passwordsDontMatch => 'Parollar mos kelmadi.';

  @override
  String get codeSentPrefix => '6 xonali kod yuborildi: ';

  @override
  String codeSentToEmail(String email) {
    return 'Kod yuborildi: $email';
  }

  @override
  String get resend => 'Qayta yuborish';

  @override
  String resendIn(int seconds) {
    return 'Qayta yuborish ($seconds)';
  }

  @override
  String get authEntryTitle => 'Voca akkauntingizni yarating';

  @override
  String get authEntrySubtitle =>
      'Natijalaringiz saqlanadi va barcha qurilmalarda mavjud bo‘ladi.';

  @override
  String get continueWithGoogle => 'Google bilan kirish';

  @override
  String get comingSoon => 'Tez orada';

  @override
  String get continueWithEmail => 'Email bilan kirish';

  @override
  String get haveAccount => 'Akkauntingiz bormi? ';

  @override
  String get continueAsGuest => 'Mehmon sifatida kirish';

  @override
  String get guestNote =>
      'Mehmon sifatida ham mashq qilishingiz mumkin. Keyinroq akkaunt yaratsangiz, natijalaringiz saqlanib qoladi.';

  @override
  String get avatarRequired => 'Profil rasmi kerak.';

  @override
  String get firstNameRequired => 'Ismingizni kiriting.';

  @override
  String get lastNameRequired => 'Familiyangizni kiriting.';

  @override
  String get phoneRequired => 'Telefon raqamni kiriting.';

  @override
  String get phoneInvalid =>
      'Raqamni to‘g‘ri kiriting, masalan +998 90 123 45 67.';

  @override
  String get avatarUploadFailed =>
      'Akkaunt yaratildi, lekin rasm yuklanmadi. Uni sozlamalardan qo‘shishingiz mumkin.';

  @override
  String get createProfileTitle => 'Profilingizni to‘ldiring';

  @override
  String get createAccount => 'Akkaunt yaratish';

  @override
  String get verified => 'Tasdiqlangan';

  @override
  String get firstNameLabel => 'Ism';

  @override
  String get lastNameLabel => 'Familiya';

  @override
  String get phoneLabel => 'Telefon raqami';

  @override
  String get phoneHelper => 'Masalan +998 90 123 45 67';

  @override
  String get emailInvalid => 'Pochta manzilini to‘g‘ri kiriting.';

  @override
  String get enterEmailTitle => 'Pochtangizni kiriting';

  @override
  String get enterEmailSubtitle => 'Tasdiqlash uchun 6 xonali kod yuboramiz.';

  @override
  String get signInWithThisEmail => 'Shu pochta bilan kirish';

  @override
  String get verifyEmailTitle => 'Pochtangizni tasdiqlang';

  @override
  String get codeNotReceived => 'Kod kelmadimi? ';

  @override
  String get useAnotherEmail => 'Boshqa pochta kiritish';

  @override
  String get resetPasswordTitle => 'Parolni tiklash';

  @override
  String get resetPasswordSubtitle =>
      'Pochtangizga bir martalik kod yuboramiz.';

  @override
  String get enterCodeTitle => 'Kodni kiriting';

  @override
  String get newPassword => 'Yangi parol';

  @override
  String get newPasswordSubtitle =>
      'Barcha qurilmalardagi seanslar tugatiladi.';

  @override
  String get saveAndSignIn => 'Saqlash va kirish';

  @override
  String get welcomeBack => 'Xush kelibsiz';

  @override
  String get signInToContinue => 'Davom etish uchun kiring.';

  @override
  String get forgotPassword => 'Parolni unutdingizmi?';

  @override
  String get errorInvalidEmail => 'Elektron pochta manzili noto‘g‘ri.';

  @override
  String get errorEmailMismatch =>
      'Bu pochta hisobingizga tegishli emas. Hisob ochilgan pochtani kiriting.';

  @override
  String get errorEmailExists =>
      'Bu pochta bilan akkaunt allaqachon ochilgan. Kiring yoki parolni tiklang.';

  @override
  String get errorInvalidCode => 'Kod noto‘g‘ri. Qaytadan urinib ko‘ring.';

  @override
  String get errorCodeExpired => 'Kod muddati tugagan. Yangisini so‘rang.';

  @override
  String get errorTooManyAttempts => 'Juda ko‘p urinish. Yangi kod so‘rang.';

  @override
  String get errorTooManyRequests => 'Juda ko‘p so‘rov. Biroz kuting.';

  @override
  String get errorInvalidPassword =>
      'Parol kamida 8 ta belgidan iborat bo‘lishi kerak.';

  @override
  String get errorNotVerified => 'Avval pochtangizni tasdiqlang.';

  @override
  String get errorValidation => 'Kiritilgan ma’lumotlarda xatolik bor.';

  @override
  String get errorGeneric => 'Nimadir xato ketdi. Qaytadan urinib ko‘ring.';

  @override
  String get errorSessionExpired => 'Sessiya tugagan. Qaytadan kiring.';

  @override
  String get errorNoInternet => 'Internet aloqasi yo‘q.';

  @override
  String get errorServerUnreachable =>
      'Serverga ulanib bo‘lmadi. U ishlayotganini va bir tarmoqda ekaningizni tekshiring.';

  @override
  String get errorEmailDelivery =>
      'Bu manzilga xat yubora olmadik. Boshqa pochta kiriting yoki keyinroq urinib ko‘ring.';

  @override
  String get deleteAccount => 'Hisobni o‘chirish';

  @override
  String get deleteAccountIntro =>
      'Hisobni o‘chirish qaytarib bo‘lmaydigan amal.';

  @override
  String get deleteAccountEmailNote =>
      'Hisob ochilgan pochtani kiriting. Unga tasdiqlash kodi yuboramiz.';

  @override
  String get deleteConfirmTitle => 'Hisob o‘chirilsinmi?';

  @override
  String get deleteConfirmQuestion =>
      'Rostdan ham hisobingizni o‘chirmoqchimisiz?';

  @override
  String get deleteConfirmWarning =>
      'Hisob o‘chirilgach, avvalgi mashqlaringiz, natijalaringiz va premium obunangiz saqlanmaydi.';

  @override
  String get deleteConfirmYes => 'Ha, o‘chirilsin';

  @override
  String get answerNo => 'Yo‘q';

  @override
  String get languageSelectTitle => 'Tilni tanlang';

  @override
  String get signOut => 'Hisobdan chiqish';

  @override
  String get signOutQuestion => 'Rostdan ham hisobdan chiqmoqchimisiz?';

  @override
  String get signOutGuestWarning =>
      'Mehmon hisobida pochta yo‘q. Chiqqaningizdan keyin natijalaringizga qayta kira olmaysiz.';

  @override
  String get signOutCodeNote =>
      'Tasdiqlash uchun hisobingiz pochtasiga kod yuboramiz.';

  @override
  String get signOutConfirm => 'Ha, chiqish';

  @override
  String get signOutVerifyTitle => 'Chiqishni tasdiqlash';

  @override
  String get signOutEnterEmail =>
      'Hisob ochilgan pochtani kiriting. Unga tasdiqlash kodi yuboramiz.';

  @override
  String get skip => 'O‘tkazib yuborish';

  @override
  String get getStarted => 'Boshlash';

  @override
  String get next => 'Keyingi';

  @override
  String pageOf(int current, int total) {
    return 'Sahifa $current / $total';
  }

  @override
  String get splashSemantic => 'Voca. Yuklanmoqda.';

  @override
  String get splashTagline => 'Talaffuzni mashq qiling';

  @override
  String get onboardingTitle1 => 'Aniq talaffuz qiling';

  @override
  String get onboardingBody1 =>
      'Ingliz tilidagi so‘zlarni to‘g‘ri talaffuz qilishni mashq qiling. Har bir so‘z uchun namunani eshiting.';

  @override
  String get onboardingTitle2 => 'Ovozingiz tahlil qilinadi';

  @override
  String get onboardingBody2 =>
      'Talaffuzingizni yozib oling. Har bir tovush alohida baholanadi va qaysi joyda xato qilganingiz ko‘rsatiladi.';

  @override
  String get onboardingTitle3 => 'Har kuni bir oz';

  @override
  String get onboardingBody3 =>
      'Qiynalayotgan tovushlaringiz kuzatib boriladi. Kunlik mashq va ketma-ketlik natijani mustahkamlaydi.';

  @override
  String get levelTitle => 'Ingliz tilini qay darajada bilasiz?';

  @override
  String get levelSubtitle => 'Mashqlar shu darajaga moslashtiriladi.';

  @override
  String get goalTitle => 'Nima uchun ingliz tilini o‘rganyapsiz?';

  @override
  String get goalSubtitle => 'Bu tavsiyalarni shakllantiradi.';

  @override
  String get dailyGoalTitle => 'Kuniga qancha mashq qilasiz?';

  @override
  String get dailyGoalSubtitle =>
      'Buni keyin sozlamalardan o‘zgartirishingiz mumkin.';

  @override
  String wordsCount(int count) {
    return '$count ta so‘z';
  }

  @override
  String get recommended => 'Tavsiya etiladi';

  @override
  String aboutMinutes(int minutes) {
    return 'Taxminan $minutes daqiqa';
  }

  @override
  String cefrLevelName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'A1': 'Boshlang‘ich',
      'A2': 'Elementar',
      'B1': 'O‘rta',
      'B2': 'O‘rtadan yuqori',
      'C1': 'Yuqori',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String cefrLevelHint(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'A1': 'Oddiy so‘z va iboralar',
      'A2': 'Kundalik oddiy suhbat',
      'B1': 'Tanish mavzularda erkin gaplashaman',
      'B2': 'Murakkab matnlarni tushunaman',
      'C1': 'Deyarli erkin so‘zlashaman',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String learningGoalName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'pronunciation': 'Talaffuzimni yaxshilash',
      'confidence': 'Ishonchli gapirish',
      'ielts': 'IELTS ga tayyorgarlik',
      'vocabulary': 'So‘z boyligini oshirish',
      'work': 'Ish uchun ingliz tili',
      'everyday': 'Kundalik muloqot',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get learningSettings => 'O‘qish sozlamalari';

  @override
  String get levelLabel => 'Daraja';

  @override
  String get goalLabel => 'Maqsad';

  @override
  String get dailyGoalLabel => 'Kunlik maqsad';

  @override
  String get notChosen => 'Tanlanmagan';

  @override
  String get homeLoadFailed => 'Bosh sahifani yuklab bo‘lmadi.';

  @override
  String get recommendedPractice => 'Tavsiya etilgan mashqlar';

  @override
  String get recommendedPracticeHint => 'Zaif tovushlaringizga mos so‘zlar';

  @override
  String get weakSounds => 'Zaif tovushlar';

  @override
  String get weakSoundsHint => 'Ko‘proq e’tibor talab qiladi';

  @override
  String get goodMorning => 'Xayrli tong';

  @override
  String get goodAfternoon => 'Xayrli kun';

  @override
  String get goodEvening => 'Xayrli kech';

  @override
  String get readyToPractise => 'Mashq qilishga tayyormisiz?';

  @override
  String get openProfile => 'Profilni ochish';

  @override
  String todayGoalSemantic(int done, int goal) {
    return 'Bugungi maqsad: $done / $goal so‘z';
  }

  @override
  String get wordsUnit => 'so‘z';

  @override
  String get goalReached => 'Maqsad bajarildi';

  @override
  String get todayGoal => 'Bugungi maqsad';

  @override
  String get goalReachedNote => 'Ajoyib natija. Xohlasangiz davom eting.';

  @override
  String wordsLeft(int count) {
    return '$count ta so‘z qoldi';
  }

  @override
  String get startPractice => 'Mashqni boshlash';

  @override
  String get streak => 'Seriya';

  @override
  String daysCount(int count) {
    return '$count kun';
  }

  @override
  String get daysInARow => 'Ketma-ket mashq kunlari';

  @override
  String get latestScore => 'So‘nggi natija';

  @override
  String get noPracticeYet => 'Hali mashq qilinmagan';

  @override
  String get noPracticeYetSentence => 'Hali mashq qilinmagan.';

  @override
  String pointsThisWeek(String sign, int points) {
    return '$sign$points ball bu hafta';
  }

  @override
  String practiseWordSemantic(String word, String level) {
    return '$word so‘zini mashq qilish, $level daraja';
  }

  @override
  String get noWeakSoundsYet => 'Hozircha zaif tovush aniqlanmadi.';

  @override
  String get loading => 'Yuklanmoqda';

  @override
  String get practiceSubtitle => 'Bugun uchun tanlangan so‘zlar';

  @override
  String get wordsLoadFailed => 'So‘zlarni yuklab bo‘lmadi.';

  @override
  String get noWordsAtLevel => 'Bu darajada so‘z yo‘q';

  @override
  String get chooseAnotherLevel => 'Boshqa darajani tanlang.';

  @override
  String get showAll => 'Barchasini ko‘rsatish';

  @override
  String practiceSetSemantic(int total, int done) {
    return '$total ta so‘z, $done tasi yaxshi yoki o‘zlashtirilgan';
  }

  @override
  String practiceSetSummary(int total, int done) {
    return '$total ta so‘z · $done tasi yaxshi';
  }

  @override
  String get allLevels => 'Barchasi';

  @override
  String levelSemantic(String level) {
    return '$level darajasi';
  }

  @override
  String get statusNotStarted => 'Boshlanmagan';

  @override
  String get statusNeedsWork => 'Mashq kerak';

  @override
  String get statusGood => 'Yaxshi';

  @override
  String get statusMastered => 'O‘zlashtirilgan';

  @override
  String wordCardSemantic(String word, String level, String status) {
    return '$word, $level daraja, $status';
  }

  @override
  String bestScoreSemantic(int score) {
    return ', eng yaxshi natija $score';
  }

  @override
  String get practiseAction => 'Mashq qilish';

  @override
  String get recordingUnavailable => 'Ovozni yozib olish, hozircha mavjud emas';

  @override
  String get scoringComingNext =>
      'Talaffuzni baholash keyingi bosqichda ulanadi.';

  @override
  String get close => 'Yopish';

  @override
  String get profileLoadFailed => 'Profilni yuklab bo‘lmadi.';

  @override
  String get subscription => 'Obuna';

  @override
  String get appSection => 'Ilova';

  @override
  String get guest => 'Mehmon';

  @override
  String get noName => 'Ismsiz';

  @override
  String get viaGoogle => 'Google orqali';

  @override
  String get guestMode => 'Mehmon rejimi';

  @override
  String get viaEmail => 'Email orqali';

  @override
  String get progressNotSaved => 'Natijalar saqlanmaydi';

  @override
  String get freePlan => 'Bepul reja';

  @override
  String get premiumSoon => 'Premium imkoniyatlar tez orada';

  @override
  String get active => 'Faol';

  @override
  String get last7Days => 'So‘nggi 7 kun';

  @override
  String get progressLoadFailed => 'Natijalarni yuklab bo‘lmadi.';

  @override
  String get weeklyActivity => 'Haftalik faollik';

  @override
  String get againstDailyGoal => 'Kunlik maqsadga nisbatan';

  @override
  String get byAccuracy => 'Aniqlik bo‘yicha';

  @override
  String get recentPractice => 'So‘nggi mashqlar';

  @override
  String averageScoreSemantic(int score) {
    return 'O‘rtacha talaffuz balli $score / 100';
  }

  @override
  String get averageScore => 'O‘rtacha talaffuz balli';

  @override
  String pointsDelta(String sign, int points) {
    return '$sign$points ball';
  }

  @override
  String get comparedWithLastWeek => 'O‘tgan haftaga nisbatan';

  @override
  String get wordsPractised => 'Mashq qilingan so‘zlar';

  @override
  String get total => 'Jami';

  @override
  String bestStreak(int count) {
    return 'Eng yaxshisi: $count kun';
  }

  @override
  String get today => 'Bugun';

  @override
  String get yesterday => 'Kecha';

  @override
  String daysAgo(int count) {
    return '$count kun oldin';
  }

  @override
  String recordSemantic(String word, String when, int score) {
    return '$word, $when, $score ball';
  }

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Du',
      '2': 'Se',
      '3': 'Ch',
      '4': 'Pa',
      '5': 'Ju',
      '6': 'Sh',
      '7': 'Ya',
      'other': '$day',
    });
    return '$_temp0';
  }

  @override
  String get goalMetSuffix => ', maqsad bajarilgan';

  @override
  String get dailyGoalMet => 'Kunlik maqsad bajarilgan';

  @override
  String weakSoundSemantic(String symbol, String example, num accuracy) {
    return '/$symbol/ tovushi, masalan $example. Aniqlik $accuracy foiz';
  }

  @override
  String forExample(String example) {
    return 'Masalan: $example';
  }

  @override
  String get takePhoto => 'Suratga olish';

  @override
  String get chooseFromGallery => 'Galereyadan tanlash';

  @override
  String get removePhoto => 'Rasmni olib tashlash';

  @override
  String get chooseProfilePhoto => 'Profil rasmini tanlash';

  @override
  String get changeProfilePhoto => 'Profil rasmini almashtirish';

  @override
  String get addProfilePhoto => 'Profil rasmini qo‘shing';

  @override
  String get photoSelected => 'Rasm tanlandi';

  @override
  String get verificationCode => 'Tasdiqlash kodi';

  @override
  String soundSemantic(String symbol) {
    return '$symbol tovushi';
  }

  @override
  String get retry => 'Qayta urinish';

  @override
  String get notImplementedYet => 'Hali tayyor emas';

  @override
  String weakSoundOpen(String symbol) {
    return '/$symbol/ tovushi natijalarini ko‘rish';
  }
}
