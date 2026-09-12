// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get back => 'Назад';

  @override
  String get navHome => 'Главная';

  @override
  String get navPractice => 'Практика';

  @override
  String get navProgress => 'Прогресс';

  @override
  String get navProfile => 'Профиль';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsAppearanceHint => 'Выберите, как выглядит приложение.';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageHint => 'Выберите язык приложения.';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeSystemHint => 'Следует настройке телефона';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeLightHint => 'Всегда светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeDarkHint => 'Всегда тёмная';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameUz => 'O‘zbekcha';

  @override
  String get languageNameRu => 'Русский';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get confirmAction => 'Подтвердить';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get cancel => 'Отмена';

  @override
  String get signIn => 'Войти';

  @override
  String get emailLabel => 'Эл. почта';

  @override
  String get emailHint => 'Ваша почта';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get passwordHelper => 'Минимум 8 символов';

  @override
  String get passwordHide => 'Скрыть пароль';

  @override
  String get passwordShow => 'Показать пароль';

  @override
  String get passwordConfirmLabel => 'Подтвердите пароль';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 8 символов.';

  @override
  String get passwordsDontMatch => 'Пароли не совпадают.';

  @override
  String get codeSentPrefix => 'Мы отправили 6-значный код на ';

  @override
  String codeSentToEmail(String email) {
    return 'Код отправлен на $email';
  }

  @override
  String get resend => 'Отправить ещё раз';

  @override
  String resendIn(int seconds) {
    return 'Отправить ещё раз ($seconds)';
  }

  @override
  String get authEntryTitle => 'Создайте аккаунт Voca';

  @override
  String get authEntrySubtitle =>
      'Ваши результаты сохраняются и доступны на всех устройствах.';

  @override
  String get continueWithGoogle => 'Войти через Google';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get continueWithEmail => 'Войти по почте';

  @override
  String get haveAccount => 'Уже есть аккаунт? ';

  @override
  String get continueAsGuest => 'Продолжить как гость';

  @override
  String get guestNote =>
      'Можно заниматься и как гость. Если позже создадите аккаунт, результаты сохранятся.';

  @override
  String get avatarRequired => 'Нужна фотография профиля.';

  @override
  String get firstNameRequired => 'Введите имя.';

  @override
  String get lastNameRequired => 'Введите фамилию.';

  @override
  String get phoneRequired => 'Введите номер телефона.';

  @override
  String get phoneInvalid =>
      'Введите номер правильно, например +998 90 123 45 67.';

  @override
  String get avatarUploadFailed =>
      'Аккаунт создан, но фото не загрузилось. Его можно добавить позже в настройках.';

  @override
  String get createProfileTitle => 'Заполните профиль';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get verified => 'Подтверждено';

  @override
  String get firstNameLabel => 'Имя';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get phoneLabel => 'Номер телефона';

  @override
  String get phoneHelper => 'Например, +998 90 123 45 67';

  @override
  String get emailInvalid => 'Введите корректный адрес почты.';

  @override
  String get enterEmailTitle => 'Введите почту';

  @override
  String get enterEmailSubtitle =>
      'Мы отправим 6-значный код для подтверждения.';

  @override
  String get signInWithThisEmail => 'Войти с этой почтой';

  @override
  String get verifyEmailTitle => 'Подтвердите почту';

  @override
  String get codeNotReceived => 'Не пришёл код? ';

  @override
  String get useAnotherEmail => 'Указать другую почту';

  @override
  String get resetPasswordTitle => 'Сброс пароля';

  @override
  String get resetPasswordSubtitle =>
      'Мы отправим одноразовый код на вашу почту.';

  @override
  String get enterCodeTitle => 'Введите код';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get newPasswordSubtitle =>
      'Вы выйдете из аккаунта на всех устройствах.';

  @override
  String get saveAndSignIn => 'Сохранить и войти';

  @override
  String get welcomeBack => 'С возвращением';

  @override
  String get signInToContinue => 'Войдите, чтобы продолжить.';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get errorInvalidEmail => 'Неверный адрес почты.';

  @override
  String get errorEmailMismatch =>
      'Эта почта не относится к вашему аккаунту. Введите почту, на которую открыт аккаунт.';

  @override
  String get errorEmailExists =>
      'Аккаунт с этой почтой уже есть. Войдите или восстановите пароль.';

  @override
  String get errorInvalidCode => 'Неверный код. Попробуйте ещё раз.';

  @override
  String get errorCodeExpired => 'Срок действия кода истёк. Запросите новый.';

  @override
  String get errorTooManyAttempts =>
      'Слишком много попыток. Запросите новый код.';

  @override
  String get errorTooManyRequests =>
      'Слишком много запросов. Подождите немного.';

  @override
  String get errorInvalidPassword =>
      'Пароль должен содержать не менее 8 символов.';

  @override
  String get errorNotVerified => 'Сначала подтвердите почту.';

  @override
  String get errorValidation => 'В данных есть ошибка.';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get errorSessionExpired => 'Сеанс завершён. Войдите снова.';

  @override
  String get errorNoInternet => 'Нет подключения к интернету.';

  @override
  String get errorServerUnreachable =>
      'Не удалось связаться с сервером. Проверьте, что он запущен и вы в одной сети.';

  @override
  String get errorEmailDelivery =>
      'Не удалось отправить письмо на этот адрес. Укажите другую почту или попробуйте позже.';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountIntro => 'Удаление аккаунта необратимо.';

  @override
  String get deleteAccountEmailNote =>
      'Введите почту вашего аккаунта. Мы отправим на неё код подтверждения.';

  @override
  String get deleteConfirmTitle => 'Удалить аккаунт?';

  @override
  String get deleteConfirmQuestion =>
      'Вы действительно хотите удалить аккаунт?';

  @override
  String get deleteConfirmWarning =>
      'После удаления аккаунта ваши занятия, прогресс и премиум-подписка не сохранятся.';

  @override
  String get deleteConfirmYes => 'Да, удалить';

  @override
  String get answerNo => 'Нет';

  @override
  String get languageSelectTitle => 'Выберите язык';

  @override
  String get viewProfilePhoto => 'Посмотреть фото профиля';

  @override
  String get appearanceSelectTitle => 'Выберите оформление';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get saveChanges => 'Сохранить';

  @override
  String get profileSaved => 'Профиль сохранён.';

  @override
  String get emailNotEditable =>
      'Почта — это ваш вход в аккаунт, поэтому изменить её здесь нельзя.';

  @override
  String get signOut => 'Выйти из аккаунта';

  @override
  String get signOutQuestion => 'Вы действительно хотите выйти?';

  @override
  String get signOutGuestWarning =>
      'У гостевого аккаунта нет почты. После выхода вы не сможете вернуться к своим результатам.';

  @override
  String get signOutCodeNote =>
      'Для подтверждения мы отправим код на почту аккаунта.';

  @override
  String get signOutConfirm => 'Да, выйти';

  @override
  String get signOutVerifyTitle => 'Подтвердите выход';

  @override
  String get signOutEnterEmail =>
      'Введите почту, на которую открыт аккаунт. Мы отправим на неё код подтверждения.';

  @override
  String get skip => 'Пропустить';

  @override
  String get getStarted => 'Начать';

  @override
  String get next => 'Далее';

  @override
  String pageOf(int current, int total) {
    return 'Страница $current из $total';
  }

  @override
  String get splashSemantic => 'Voca. Загрузка.';

  @override
  String get splashTagline => 'Тренируйте произношение';

  @override
  String get onboardingTitle1 => 'Произносите чётко';

  @override
  String get onboardingBody1 =>
      'Тренируйте правильное произношение английских слов. Слушайте образец для каждого слова.';

  @override
  String get onboardingTitle2 => 'Ваш голос анализируется';

  @override
  String get onboardingBody2 =>
      'Запишите своё произношение. Каждый звук оценивается отдельно, и видно, где именно была ошибка.';

  @override
  String get onboardingTitle3 => 'Понемногу каждый день';

  @override
  String get onboardingBody3 =>
      'Трудные звуки отслеживаются. Ежедневная практика и серия закрепляют результат.';

  @override
  String get levelTitle => 'Насколько хорошо вы знаете английский?';

  @override
  String get levelSubtitle => 'Упражнения подстроятся под ваш уровень.';

  @override
  String get goalTitle => 'Зачем вы учите английский?';

  @override
  String get goalSubtitle => 'От этого зависят рекомендации.';

  @override
  String get dailyGoalTitle => 'Сколько вы будете заниматься в день?';

  @override
  String get dailyGoalSubtitle => 'Это можно изменить позже в настройках.';

  @override
  String wordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String get recommended => 'Рекомендуется';

  @override
  String aboutMinutes(int minutes) {
    return 'Примерно $minutes мин';
  }

  @override
  String cefrLevelName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'A1': 'Начальный',
      'A2': 'Элементарный',
      'B1': 'Средний',
      'B2': 'Выше среднего',
      'C1': 'Продвинутый',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String cefrLevelHint(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'A1': 'Простые слова и фразы',
      'A2': 'Простой повседневный разговор',
      'B1': 'Свободно говорю на знакомые темы',
      'B2': 'Понимаю сложные тексты',
      'C1': 'Говорю почти свободно',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String learningGoalName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'pronunciation': 'Улучшить произношение',
      'confidence': 'Говорить уверенно',
      'ielts': 'Подготовка к IELTS',
      'vocabulary': 'Расширить словарный запас',
      'work': 'Английский для работы',
      'everyday': 'Повседневное общение',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get learningSettings => 'Настройки обучения';

  @override
  String get levelLabel => 'Уровень';

  @override
  String get goalLabel => 'Цель';

  @override
  String get dailyGoalLabel => 'Ежедневная цель';

  @override
  String get notChosen => 'Не выбрано';

  @override
  String get homeLoadFailed => 'Не удалось загрузить главную.';

  @override
  String get recommendedPractice => 'Рекомендуемые упражнения';

  @override
  String get recommendedPracticeHint => 'Слова для ваших слабых звуков';

  @override
  String get weakSounds => 'Слабые звуки';

  @override
  String get weakSoundsHint => 'Требуют больше внимания';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get readyToPractise => 'Готовы заниматься?';

  @override
  String get openProfile => 'Открыть профиль';

  @override
  String todayGoalSemantic(int done, int goal) {
    return 'Цель на сегодня: $done из $goal слов';
  }

  @override
  String get wordsUnit => 'слов';

  @override
  String get goalReached => 'Цель выполнена';

  @override
  String get todayGoal => 'Цель на сегодня';

  @override
  String get goalReachedNote => 'Отличный результат. Можно продолжить.';

  @override
  String wordsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count слова',
      many: 'Осталось $count слов',
      few: 'Осталось $count слова',
      one: 'Осталось $count слово',
    );
    return '$_temp0';
  }

  @override
  String get startPractice => 'Начать практику';

  @override
  String get streak => 'Серия';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get daysInARow => 'Дней подряд';

  @override
  String get latestScore => 'Последний результат';

  @override
  String get noPracticeYet => 'Ещё нет занятий';

  @override
  String get noPracticeYetSentence => 'Ещё нет занятий.';

  @override
  String pointsThisWeek(String sign, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$sign$points балла за неделю',
      many: '$sign$points баллов за неделю',
      few: '$sign$points балла за неделю',
      one: '$sign$points балл за неделю',
    );
    return '$_temp0';
  }

  @override
  String practiseWordSemantic(String word, String level) {
    return 'Практиковать «$word», уровень $level';
  }

  @override
  String get noWeakSoundsYet => 'Слабых звуков пока не найдено.';

  @override
  String get loading => 'Загрузка';

  @override
  String get practiceSubtitle => 'Слова на сегодня';

  @override
  String get wordsLoadFailed => 'Не удалось загрузить слова.';

  @override
  String get noWordsAtLevel => 'На этом уровне нет слов';

  @override
  String get chooseAnotherLevel => 'Выберите другой уровень.';

  @override
  String get showAll => 'Показать все';

  @override
  String practiceSetSemantic(int total, int done) {
    return 'Слов: $total, хорошо или освоено: $done';
  }

  @override
  String practiceSetSummary(int total, int done) {
    return 'Слов: $total · хорошо: $done';
  }

  @override
  String get allLevels => 'Все';

  @override
  String levelSemantic(String level) {
    return 'Уровень $level';
  }

  @override
  String get statusNotStarted => 'Не начато';

  @override
  String get statusNeedsWork => 'Нужна практика';

  @override
  String get statusGood => 'Хорошо';

  @override
  String get statusMastered => 'Освоено';

  @override
  String wordCardSemantic(String word, String level, String status) {
    return '$word, уровень $level, $status';
  }

  @override
  String bestScoreSemantic(int score) {
    return ', лучший результат $score';
  }

  @override
  String get practiseAction => 'Практиковать';

  @override
  String get recordingUnavailable => 'Запись голоса, пока недоступно';

  @override
  String get scoringComingNext =>
      'Оценка произношения появится на следующем этапе.';

  @override
  String get close => 'Закрыть';

  @override
  String get profileLoadFailed => 'Не удалось загрузить профиль.';

  @override
  String get subscription => 'Подписка';

  @override
  String get appSection => 'Приложение';

  @override
  String get guest => 'Гость';

  @override
  String get noName => 'Без имени';

  @override
  String get viaGoogle => 'Через Google';

  @override
  String get guestMode => 'Гостевой режим';

  @override
  String get viaEmail => 'Через почту';

  @override
  String get progressNotSaved => 'Результаты не сохраняются';

  @override
  String get freePlan => 'Бесплатный план';

  @override
  String get premiumSoon => 'Премиум-функции скоро';

  @override
  String get active => 'Активен';

  @override
  String get last7Days => 'Последние 7 дней';

  @override
  String get progressLoadFailed => 'Не удалось загрузить прогресс.';

  @override
  String get weeklyActivity => 'Активность за неделю';

  @override
  String get againstDailyGoal => 'Относительно дневной цели';

  @override
  String get byAccuracy => 'По точности';

  @override
  String get recentPractice => 'Последние занятия';

  @override
  String averageScoreSemantic(int score) {
    return 'Средний балл произношения $score из 100';
  }

  @override
  String get averageScore => 'Средний балл произношения';

  @override
  String pointsDelta(String sign, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$sign$points балла',
      many: '$sign$points баллов',
      few: '$sign$points балла',
      one: '$sign$points балл',
    );
    return '$_temp0';
  }

  @override
  String get comparedWithLastWeek => 'По сравнению с прошлой неделей';

  @override
  String get wordsPractised => 'Слов отработано';

  @override
  String get total => 'Всего';

  @override
  String bestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Лучшая: $count дня',
      many: 'Лучшая: $count дней',
      few: 'Лучшая: $count дня',
      one: 'Лучшая: $count день',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String recordSemantic(String word, String when, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score балла',
      many: '$score баллов',
      few: '$score балла',
      one: '$score балл',
    );
    return '$word, $when, $_temp0';
  }

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Пн',
      '2': 'Вт',
      '3': 'Ср',
      '4': 'Чт',
      '5': 'Пт',
      '6': 'Сб',
      '7': 'Вс',
      'other': '$day',
    });
    return '$_temp0';
  }

  @override
  String get goalMetSuffix => ', цель выполнена';

  @override
  String get dailyGoalMet => 'Дневная цель выполнена';

  @override
  String weakSoundSemantic(String symbol, String example, num accuracy) {
    return 'Звук /$symbol/, например $example. Точность $accuracy процентов';
  }

  @override
  String forExample(String example) {
    return 'Например: $example';
  }

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get removePhoto => 'Удалить фото';

  @override
  String get chooseProfilePhoto => 'Выбрать фото профиля';

  @override
  String get changeProfilePhoto => 'Изменить фото профиля';

  @override
  String get addProfilePhoto => 'Добавьте фото профиля';

  @override
  String get photoSelected => 'Фото выбрано';

  @override
  String get verificationCode => 'Код подтверждения';

  @override
  String soundSemantic(String symbol) {
    return 'звук $symbol';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get notImplementedYet => 'Пока не готово';

  @override
  String weakSoundOpen(String symbol) {
    return 'Результаты по звуку /$symbol/';
  }
}
