// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Календарь развития и здоровья ребёнка';

  @override
  String get navDashboard => 'Обзор';

  @override
  String get navAssistant => 'Помощник';

  @override
  String get navDiary => 'Дневник';

  @override
  String get navGrowth => 'Развитие';

  @override
  String get navIllness => 'Болезни';

  @override
  String get navMedical => 'Медкарта';

  @override
  String get navReminders => 'Напоминания';

  @override
  String get navChildren => 'Дети';

  @override
  String get navFamily => 'Семья';

  @override
  String get navMore => 'Ещё';

  @override
  String get navAsk => 'ИИ';

  @override
  String get navPhotos => 'Фотографии';

  @override
  String get navGroupHealth => 'Здоровье';

  @override
  String get navGroupMemory => 'Память';

  @override
  String get navGroupProfile => 'Профиль';

  @override
  String get navGrowthHint => 'Вес, рост и перцентили ВОЗ';

  @override
  String get navIllnessHint => 'Дни болезни и температура';

  @override
  String get navMedicalHint => 'Прививки, приёмы, отчёт для врача';

  @override
  String get navVisit => 'Приём врача';

  @override
  String get navVisitHint => 'О чём спросить и что взять с собой';

  @override
  String get navRemindersHint => 'Лекарства и календарь прививок';

  @override
  String get navPhotosHint => 'Альбом и недельная история';

  @override
  String get navChildrenHint => 'Кто в приложении';

  @override
  String get navSettingsHint => 'Язык, тема, единицы, доступ';

  @override
  String get photosAdd => 'Добавить фото';

  @override
  String get photosEdit => 'Изменить фото';

  @override
  String get photosWhen => 'Когда снято';

  @override
  String get photosAbout => 'Что здесь';

  @override
  String get photosAboutHint => 'Например, «первый раз сел сам»';

  @override
  String get photosSaved => 'Фото сохранено';

  @override
  String get photosDeleted => 'Фото удалено';

  @override
  String get photosEmpty => 'Здесь будут фотографии малыша';

  @override
  String get photosEmptyHint =>
      'Снимки из записей дневника попадут сюда сами, а отдельные можно добавить кнопкой ниже';

  @override
  String photosCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n фото',
      many: '$n фото',
      few: '$n фото',
      one: '$n фото',
    );
    return '$_temp0';
  }

  @override
  String get authSignInSubtitle => 'Войдите, чтобы продолжить';

  @override
  String get authRegisterSubtitle => 'Создайте учётную запись родителя';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authSignIn => 'Войти';

  @override
  String get authRegister => 'Зарегистрироваться';

  @override
  String get authToRegister => 'Нет учётной записи — зарегистрироваться';

  @override
  String get authToSignIn => 'Уже есть учётная запись — войти';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authOr => 'или';

  @override
  String get authWithGoogle => 'Войти через Google';

  @override
  String get authWithApple => 'Войти через Apple';

  @override
  String get authEmailRequired => 'Введите email';

  @override
  String get authEmailIncomplete => 'Похоже, адрес неполный';

  @override
  String get authPasswordRequired => 'Введите пароль';

  @override
  String get authPasswordTooShort => 'Минимум 6 символов';

  @override
  String get authResetNeedsEmail => 'Введите email, на него придёт ссылка';

  @override
  String authResetSent(String email) {
    return 'Письмо для сброса пароля отправлено на $email';
  }

  @override
  String authUnexpected(String error) {
    return 'Неожиданная ошибка: $error';
  }

  @override
  String get authErrorInvalidCredentials => 'Неверный email или пароль';

  @override
  String get authErrorInvalidEmail => 'Некорректный адрес электронной почты';

  @override
  String get authErrorEmailInUse => 'Этот email уже зарегистрирован';

  @override
  String get authErrorWeakPassword =>
      'Пароль слишком простой — минимум 6 символов';

  @override
  String get authErrorUserDisabled => 'Учётная запись отключена';

  @override
  String get authErrorRequiresRecentLogin =>
      'Для этого действия нужно войти заново. Выйдите и войдите ещё раз';

  @override
  String get authErrorTooManyRequests =>
      'Слишком много попыток. Попробуйте через несколько минут';

  @override
  String get authErrorNetwork => 'Нет связи с сервером. Проверьте интернет';

  @override
  String get authErrorOperationNotAllowed =>
      'Вход по email и паролю выключен в консоли Firebase';

  @override
  String authErrorUnknown(String code) {
    return 'Не удалось выполнить операцию: $code';
  }

  @override
  String get authErrorGoogleNotConfigured =>
      'Вход через Google не настроен для этой сборки приложения';

  @override
  String get authErrorGoogleProvider =>
      'Google не может подтвердить это приложение. Обратитесь в поддержку';

  @override
  String get authErrorGoogleInterrupted =>
      'Вход через Google прервался. Проверьте связь и попробуйте ещё раз';

  @override
  String authErrorGoogleFailed(String detail) {
    return 'Не удалось войти через Google: $detail';
  }

  @override
  String get authErrorGoogleNoToken =>
      'Google не вернул токен входа. Попробуйте ещё раз';

  @override
  String get authErrorSignInFirst => 'Сначала войдите в свою учётную запись';

  @override
  String get authErrorNoPassword =>
      'У этой учётной записи нет пароля: вход выполняется через Google. Пароль меняется в настройках аккаунта Google';

  @override
  String get authErrorUnknownProvider =>
      'Не удалось подтвердить личность: неизвестный способ входа. Выйдите и войдите заново';

  @override
  String get accountMenu => 'Учётная запись';

  @override
  String get settingsTitle => 'Профиль и настройки';

  @override
  String get settingsSignOut => 'Выйти';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsChangePassword => 'Сменить пароль';

  @override
  String get settingsDeleteAccount => 'Удалить учётную запись';

  @override
  String get settingsLanguage => 'Язык интерфейса';

  @override
  String get settingsNotificationsOff => 'Уведомления выключены';

  @override
  String get settingsNotificationsOn => 'Уведомления включены';

  @override
  String settingsLocalOnly(String reason) {
    return 'Напоминания на этом устройстве включены. Push пока недоступен: $reason';
  }

  @override
  String get settingsRemindMe => 'Напоминать о прививках и лекарствах';

  @override
  String get settingsConnecting => 'Подключаю…';

  @override
  String get settingsNotificationsHint =>
      'Работает, пока приложение установлено на домашний экран или открыто в браузере. Разрешение спрашивает сам браузер — если откажете, включить снова можно будет только в его настройках сайта.';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get themeAuto => 'Автоматически';

  @override
  String get themeAutoHint => 'Тёмная с 21:00 до 7:00';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get passwordCurrent => 'Текущий пароль';

  @override
  String get passwordNew => 'Новый пароль';

  @override
  String get passwordRepeat => 'Новый пароль ещё раз';

  @override
  String get passwordCurrentRequired => 'Введите текущий пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get passwordChanged => 'Пароль изменён';

  @override
  String get deleteAccountTitle => 'Удалить учётную запись?';

  @override
  String get deleteAccountWarning =>
      'Все данные о детях будут удалены навсегда. Восстановить их не сможем ни мы, ни вы.';

  @override
  String get deleteAccountPassword => 'Ваш пароль';

  @override
  String get deleteAccountGoogleNote =>
      'После подтверждения Google попросит вас войти ещё раз — так проверяется, что удаляете именно вы.';

  @override
  String get deleteAccountWord => 'УДАЛИТЬ';

  @override
  String deleteAccountWriteWord(String word) {
    return 'Напишите $word';
  }

  @override
  String get deleteAccountConfirm => 'Удалить навсегда';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get notificationChannelName => 'Напоминания';

  @override
  String get notificationChannelDescription =>
      'Прививки, приём лекарств и визиты к врачу';

  @override
  String get reminderTypeVaccination => 'Прививка';

  @override
  String get reminderTypeMedication => 'Лекарство';

  @override
  String get reminderTypeAppointment => 'Визит к врачу';

  @override
  String get recurrenceNone => 'Однократно';

  @override
  String get recurrenceDaily => 'Ежедневно';

  @override
  String get recurrenceTwiceDaily => 'Дважды в день';

  @override
  String get recurrenceWeekly => 'Еженедельно';

  @override
  String get reminderNew => 'Новое напоминание';

  @override
  String get reminderWhat => 'О чём напомнить';

  @override
  String get reminderNameMedication => 'Что дать — например, «Нурофен, 2,5 мл»';

  @override
  String get reminderNameAppointment => 'К кому — например, «Педиатр, 9:00»';

  @override
  String get reminderWhen => 'Когда';

  @override
  String reminderInHours(int h) {
    return 'через $h ч';
  }

  @override
  String get reminderTomorrowMorning => 'завтра утром';

  @override
  String get reminderExactTime => 'выбрать время';

  @override
  String get reminderRepeat => 'Повторять';

  @override
  String reminderSaved(String when) {
    return 'Напомню $when';
  }

  @override
  String get reminderNameRequired => 'Напишите, о чём напомнить';

  @override
  String get reminderAdd => 'Напоминание';

  @override
  String get reminderCompleted => 'Отмечено выполненным';

  @override
  String reminderDeleteConfirm(String title) {
    return 'Удалить «$title»? Вернуть это будет нельзя.';
  }

  @override
  String get reminderDelete => 'Удалить напоминание';

  @override
  String get reminderDeleted => 'Напоминание удалено';

  @override
  String get remindersVaccinations => 'Календарь прививок';

  @override
  String get remindersMedications => 'Приём лекарств';

  @override
  String get remindersAppointments => 'Визиты к врачу';

  @override
  String get remindersNothingPlanned => 'Ничего не запланировано';

  @override
  String get remindersShowCompleted => 'Показать выполненные';

  @override
  String get quickFeed => 'Покормила';

  @override
  String get quickNappy => 'Подгузник';

  @override
  String get quickSleep => 'Поспал';

  @override
  String get quickTemperature => 'Температура';

  @override
  String get quickSheetFeeding => 'Кормление';

  @override
  String get quickSheetNappy => 'Подгузник';

  @override
  String get quickSheetSleep => 'Сколько поспал';

  @override
  String get quickSheetSleepShort => 'Сон';

  @override
  String get quickSheetTemperature => 'Температура';

  @override
  String get quickTimeNow => 'Сейчас';

  @override
  String get quickTimeChoose => 'Выбрать время';

  @override
  String get quickNowHint => 'Отметится текущим временем';

  @override
  String get quickSaveButton => 'Записать';

  @override
  String quickSaved(String what) {
    return 'Записано: $what';
  }

  @override
  String get quickSideLeft => 'Левая';

  @override
  String get quickSideRight => 'Правая';

  @override
  String get quickSideBottle => 'Бутылочка';

  @override
  String get quickNappyWet => 'Мокрый';

  @override
  String get quickNappyDirty => 'Стул';

  @override
  String get quickNappyBoth => 'Мокрый и стул';

  @override
  String get quickSleep30 => 'Полчаса';

  @override
  String get quickSleep60 => 'Час';

  @override
  String get quickSleep90 => 'Полтора часа';

  @override
  String get quickSleep120 => 'Два часа';

  @override
  String get quickSleep180 => 'Три часа';

  @override
  String get nightModeTitle => 'Ночной режим';

  @override
  String get nightModeHint =>
      'Тёмно-красный экран: не будит ребёнка и не сбивает ночное зрение';

  @override
  String get nightModeOff => 'Выключен';

  @override
  String get nightModeAuto => 'Ночью автоматически';

  @override
  String get nightModeOn => 'Включён';

  @override
  String get nightModeAutoHint => 'С 21:00 до 7:00';

  @override
  String get pumpTitle => 'Сцеживание';

  @override
  String get pumpAction => 'Я сцеживалась';

  @override
  String get pumpHowMuch => 'Сколько сцежено';

  @override
  String pumpMl(int n) {
    return '$n мл';
  }

  @override
  String pumpToday(String amount) {
    return 'Сегодня сцежено $amount';
  }

  @override
  String get feedingSolid => 'Прикорм';

  @override
  String get solidsTitle => 'Прикорм и реакции';

  @override
  String get logReaction => 'Реакция';

  @override
  String get solidsEmpty => 'Прикорма пока нет';

  @override
  String get solidsEmptyHint =>
      'Первая ложка отмечается в «Покормила» → «Прикорм»';

  @override
  String get solidWhat => 'Что ели';

  @override
  String get solidWhatHint => 'Например, кабачок';

  @override
  String solidTimesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n раза',
      many: '$n раз',
      few: '$n раза',
      one: '$n раз',
    );
    return '$_temp0';
  }

  @override
  String solidFirstAt(String date) {
    return 'Впервые $date';
  }

  @override
  String solidWatch(String date) {
    return 'Новое — наблюдаем до $date';
  }

  @override
  String get solidWatchHint =>
      'Три дня без нового продукта — так понятно, на что реакция';

  @override
  String get solidReactionAdd => 'Была реакция';

  @override
  String solidReactionTitle(String food) {
    return 'Реакция на «$food»';
  }

  @override
  String get solidReactionWhat => 'Что вы заметили';

  @override
  String get solidReactionHint => 'Например, сыпь на щеках к вечеру';

  @override
  String get solidReactionNone => 'Реакций не было';

  @override
  String get sleepForecastTitle => 'Скоро сон';

  @override
  String get sleepForecastOverdue => 'Не спит дольше обычного';

  @override
  String sleepForecastAt(String time) {
    return 'Обычно засыпает около $time';
  }

  @override
  String sleepForecastAwake(String awake, String window) {
    return 'Не спит $awake · окно ≈ $window';
  }

  @override
  String sleepForecastFromHistory(int count) {
    return 'По записям за две недели: $count промежутков';
  }

  @override
  String get sleepForecastFromAge =>
      'Пока по возрастным нормам — записей ещё мало';

  @override
  String get timerStart => 'Засечь время';

  @override
  String get timerStartHint => 'Отсчёт пойдёт с этой секунды';

  @override
  String get timerFeeding => 'Кормление идёт';

  @override
  String get timerSleep => 'Сон идёт';

  @override
  String timerSince(String time) {
    return 'с $time';
  }

  @override
  String get timerStarted => 'Отсчёт пошёл';

  @override
  String get timerDiscard => 'Сбросить';

  @override
  String get timerDiscarded => 'Отсчёт сброшен';

  @override
  String get timerForgotten => 'Идёт очень долго — может, забыли остановить?';

  @override
  String timerLastFeed(String side, String ago) {
    return 'Прошлое кормление — $side, $ago';
  }

  @override
  String durationH(int h) {
    return '$h ч';
  }

  @override
  String durationM(int m) {
    return '$m мин';
  }

  @override
  String durationHM(int h, int m) {
    return '$h ч $m мин';
  }

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonCreate => 'Создать';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonEdit => 'Изменить';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonAll => 'Все';

  @override
  String get commonMore => 'Подробнее';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonHide => 'Скрыть';

  @override
  String get commonShow => 'Показать';

  @override
  String get commonDate => 'Дата';

  @override
  String get commonTime => 'Время';

  @override
  String get commonAge => 'Возраст';

  @override
  String get commonToday => 'сегодня';

  @override
  String get commonTomorrow => 'завтра';

  @override
  String get commonNumberInvalid => 'Введите число';

  @override
  String get commonTechnical => 'Техническая информация';

  @override
  String get logTypeMilestone => 'Веха развития';

  @override
  String get logTypeMeasurement => 'Измерение';

  @override
  String get logTypeIllness => 'Болезнь';

  @override
  String get logTypeFeeding => 'Кормление';

  @override
  String get logTypeNappy => 'Подгузник';

  @override
  String get logTypeSleep => 'Сон';

  @override
  String get logTypeQuestion => 'Вопрос врачу';

  @override
  String get logTypeNote => 'Запись';

  @override
  String get feedingLeft => 'Левая';

  @override
  String get feedingRight => 'Правая';

  @override
  String get feedingBottle => 'Бутылочка';

  @override
  String get nappyWet => 'Мокрый';

  @override
  String get nappyDirty => 'Стул';

  @override
  String get nappyBoth => 'Мокрый и стул';

  @override
  String get severityMild => 'Лёгкая';

  @override
  String get severityModerate => 'Средняя';

  @override
  String get severitySevere => 'Тяжёлая';

  @override
  String get genderMale => 'Мальчик';

  @override
  String get genderFemale => 'Девочка';

  @override
  String get unitsMetric => 'Метрическая (см, кг)';

  @override
  String get unitsImperial => 'Имперская (in, lb)';

  @override
  String nightWakingsCount(int n) {
    return 'пробуждений: $n';
  }

  @override
  String nightFeedsCount(int n) {
    return 'кормлений: $n';
  }

  @override
  String ageYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n года',
      many: '$n лет',
      few: '$n года',
      one: '$n год',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n месяца',
      many: '$n месяцев',
      few: '$n месяца',
      one: '$n месяц',
    );
    return '$_temp0';
  }

  @override
  String entriesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n записи',
      many: '$n записей',
      few: '$n записи',
      one: '$n запись',
    );
    return '$_temp0';
  }

  @override
  String monthsShort(int n) {
    return '$n мес.';
  }

  @override
  String get dashLayoutTitle => 'Блоки на главном экране';

  @override
  String get dashAllHidden => 'Все блоки скрыты';

  @override
  String get dashAllHiddenHint => 'Вернуть их можно в настройках';

  @override
  String get dashConfigure => 'Настроить главный экран';

  @override
  String get dashNoneSelected => 'Ни один блок не выбран';

  @override
  String get dashHiddenBlocks => 'Скрытые блоки';

  @override
  String get dashReset => 'Вернуть стандартный набор';

  @override
  String get widgetNow => 'Сейчас';

  @override
  String get widgetSummary => 'Сводка о ребёнке';

  @override
  String get widgetGrowth => 'Рост и вес';

  @override
  String get widgetVaccinations => 'Ближайшие прививки';

  @override
  String get widgetIllness => 'Заболеваемость';

  @override
  String get widgetMilestones => 'Вехи развития';

  @override
  String get widgetRecent => 'Последние записи';

  @override
  String get widgetUpcoming => 'Ближайшие события';

  @override
  String get summaryAge => 'возраст';

  @override
  String get summaryBirthDate => 'дата рождения';

  @override
  String get summaryMilestonesCount => 'вех развития';

  @override
  String get summaryEntriesCount => 'записей всего';

  @override
  String get growthNoMeasurements => 'Измерений пока нет';

  @override
  String get growthWeight => 'Вес';

  @override
  String get growthHeight => 'Рост';

  @override
  String get growthLastMeasurement => 'последнее измерение';

  @override
  String growthPercentileWith(String label, int p) {
    return '$label · $p-й перцентиль';
  }

  @override
  String get vaccinationsNone => 'Предстоящих прививок нет';

  @override
  String get illnessDaysTotal => 'дней болезни всего';

  @override
  String get illnessLast3Months => 'за последние 3 месяца';

  @override
  String get milestonesEmpty => 'Первое ещё впереди';

  @override
  String get milestonesEmptyHint =>
      'Первая улыбка, первый зуб, первое слово — добавьте их в дневнике как «Веха развития»';

  @override
  String get recentEmpty => 'Записей пока нет';

  @override
  String get upcomingEmptyHint =>
      'Прививки появятся здесь сами, как только будет создан профиль ребёнка';

  @override
  String get feedbackTitle => 'Обратная связь';

  @override
  String get feedbackExplain =>
      'Если что-то работает не так или чего-то не хватает — напишите. Откроется ваша почта, письмо уйдёт только когда вы сами нажмёте «Отправить».';

  @override
  String get feedbackWrite => 'Написать разработчику';

  @override
  String get feedbackSubject => 'Дневник ребёнка — обратная связь';

  @override
  String get feedbackPlaceholder =>
      'Напишите здесь, что случилось или чего не хватает.';

  @override
  String get feedbackNoMailApp =>
      'Почта не открылась. Адрес скопирован — напишите с любого устройства';

  @override
  String get feedbackAddressCopied => 'Адрес скопирован';

  @override
  String get settingsLocation => 'Разработчик находится';

  @override
  String get logTitle => 'Журнал ошибок';

  @override
  String get logEmpty => 'Пока ничего не сломалось.';

  @override
  String get logExplain =>
      'Записывается только на этом телефоне и никуда не отправляется. Если приложение подвисло или закрылось — скопируйте и пришлите разработчику.';

  @override
  String get logCopy => 'Скопировать';

  @override
  String get logCopied => 'Журнал скопирован';

  @override
  String get logClear => 'Очистить';

  @override
  String get logCleared => 'Журнал очищен';

  @override
  String logCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n записи',
      many: '$n записей',
      few: '$n записи',
      one: '$n запись',
    );
    return '$_temp0';
  }

  @override
  String get milestonesUsualTitle => 'Обычно в этом возрасте';

  @override
  String get milestonesSpread =>
      'Это не срок, а окно: у большинства детей появляется где-то внутри этих месяцев. Позже — тоже бывает норма.';

  @override
  String get milestonesNoted => 'записано';

  @override
  String get milestonesSoon => 'Скоро';

  @override
  String milestonesRange(int from, int to) {
    return '$from–$to мес.';
  }

  @override
  String get milestonesAsk => 'Записать вопрос врачу';

  @override
  String greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String noticedRoundAge(String name, num months) {
    final intl.NumberFormat monthsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String monthsString = monthsNumberFormat.format(months);

    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$monthsString месяца',
      many: '$monthsString месяцев',
      few: '$monthsString месяца',
      one: '$monthsString месяц',
    );
    return 'Сегодня $name ровно $_temp0';
  }

  @override
  String noticedYesterday(String feedings, String sleep) {
    return 'Вчера — $feedings и $sleep сна';
  }

  @override
  String noticedYesterdayNoSleep(String feedings) {
    return 'Вчера — $feedings';
  }

  @override
  String noticedLongestNight(String duration) {
    return 'Самая длинная ночь за месяц — $duration';
  }

  @override
  String get greetingNight => 'Доброй ночи';

  @override
  String get greetingMorning => 'Доброе утро';

  @override
  String get greetingAfternoon => 'Добрый день';

  @override
  String get greetingEvening => 'Добрый вечер';

  @override
  String get statusSick => 'Болеет';

  @override
  String get statusHealthy => 'Здоров';

  @override
  String get statusLatest => 'последняя';

  @override
  String nowTodayReminder(String title) {
    return 'Сегодня: $title';
  }

  @override
  String get nowNoEntries =>
      'Сегодня записей ещё нет. Кнопки ниже отмечают время сами.';

  @override
  String nowSinceFeeding(String duration) {
    return 'С последнего кормления — $duration';
  }

  @override
  String get countFeedings => 'кормлений';

  @override
  String get countWet => 'мокрых';

  @override
  String get countDirty => 'стул';

  @override
  String get countSleep => 'сна';

  @override
  String get nightAsleepDate => 'Уснул, дата';

  @override
  String get nightAwakeDate => 'Проснулся, дата';

  @override
  String get nightWokeUp => 'Просыпался';

  @override
  String get nightOfThoseFeeds => 'Из них кормлений';

  @override
  String nightTotal(String duration) {
    return 'Всего сна: $duration';
  }

  @override
  String get nightInvalid => 'Проснулся должен быть позже, чем уснул';

  @override
  String get errorIndexBuilding =>
      'База данных достраивает индексы. Это занимает несколько минут после первого развёртывания — обновите страницу чуть позже.';

  @override
  String get errorPermission =>
      'Нет доступа к этим данным. Попробуйте выйти и войти заново.';

  @override
  String get errorOffline =>
      'Нет связи с сервером. Изменения сохранятся локально и синхронизируются, когда соединение вернётся.';

  @override
  String get errorSession => 'Сессия истекла. Войдите в учётную запись заново.';

  @override
  String get errorGeneric =>
      'Не удалось загрузить данные. Попробуйте обновить страницу.';

  @override
  String get noChildTitle => 'Давайте познакомимся';

  @override
  String get noChildHint =>
      'Расскажите о малыше — дальше приложение подстроится под его возраст и само составит календарь прививок';

  @override
  String get addChild => 'Добавить ребёнка';

  @override
  String get diaryFeed => 'Лента событий';

  @override
  String get diaryFilterCare => 'Уход';

  @override
  String get diaryFilterHealth => 'Здоровье';

  @override
  String get diaryFilterDevelopment => 'Развитие';

  @override
  String get diaryFilterNotes => 'Заметки';

  @override
  String get diaryEmpty => 'Здесь будет история малыша';

  @override
  String get diaryEmptyHint =>
      'Кормления и подгузники отмечаются кнопками на главной, а первое слово и первый зуб — здесь';

  @override
  String get diaryAddEntry => 'Добавить запись';

  @override
  String get diaryDeleteTitle => 'Удалить запись?';

  @override
  String diaryDeleteBody(String title) {
    return 'Запись «$title» будет удалена. Действие необратимо.';
  }

  @override
  String get diaryPhotos => 'Фотографии';

  @override
  String get diaryNewEntry => 'Новая запись';

  @override
  String get diaryEditEntry => 'Изменить запись';

  @override
  String get diaryType => 'Тип записи';

  @override
  String get diaryTitleField => 'Заголовок';

  @override
  String get diaryTitleRequired => 'Укажите заголовок';

  @override
  String get diaryDescription => 'Описание';

  @override
  String get diaryTags => 'Теги, через запятую';

  @override
  String get diaryTagsHint => 'моторика, речь';

  @override
  String fieldWeight(String unit) {
    return 'Вес, $unit';
  }

  @override
  String fieldHeight(String unit) {
    return 'Рост, $unit';
  }

  @override
  String fieldHead(String unit) {
    return 'Окружность головы, $unit';
  }

  @override
  String fieldChest(String unit) {
    return 'Окружность груди, $unit';
  }

  @override
  String get fieldTemperature => 'Температура, °C';

  @override
  String get fieldSeverity => 'Тяжесть';

  @override
  String pillHead(String value) {
    return 'голова $value';
  }

  @override
  String pillChest(String value) {
    return 'грудь $value';
  }

  @override
  String photoUploadFailed(String error) {
    return 'Не удалось загрузить фото: $error';
  }

  @override
  String get childrenTitle => 'Профили детей';

  @override
  String get childrenEmpty => 'Пока нет ни одного профиля';

  @override
  String get childrenEmptyHint => 'Нажмите «Добавить ребёнка», чтобы начать';

  @override
  String get childDeleteTitle => 'Удалить профиль?';

  @override
  String childDeleteBody(String name) {
    return 'Профиль «$name» будет удалён вместе со всеми записями дневника, измерениями, медицинскими записями и напоминаниями. Действие необратимо.';
  }

  @override
  String get childSelected => 'Выбран';

  @override
  String get childProfileEdit => 'Профиль ребёнка';

  @override
  String get childProfileNew => 'Новый профиль';

  @override
  String get childName => 'Имя';

  @override
  String get childNameRequired => 'Укажите имя';

  @override
  String get childBirthDate => 'Дата рождения';

  @override
  String get childPickDate => 'Выберите дату';

  @override
  String get childBirthDateRequired => 'Укажите дату рождения';

  @override
  String get photoAdd => 'Добавить фото';

  @override
  String get photoRemove => 'Убрать фото';

  @override
  String photoSaveFailed(String error) {
    return 'Не удалось сохранить фото: $error';
  }

  @override
  String get quickNoteOptional => 'Заметка (необязательно)';

  @override
  String get quickAssistant => 'Помощник';

  @override
  String get quickNightSleep => 'Ночной сон';

  @override
  String get digestTitle => 'Сегодня';

  @override
  String get digestSubtitle => 'Коротко о дне';

  @override
  String get digestFeedings => 'Кормлений';

  @override
  String get digestSleep => 'Сон за день';

  @override
  String get digestNappies => 'Подгузников';

  @override
  String get digestTemperature => 'Температура';

  @override
  String get digestPhotos => 'Новых фото';

  @override
  String get digestEmpty => 'Сегодня записей пока нет';

  @override
  String get digestCalm => 'Сегодня был спокойный день.';

  @override
  String get digestBusy => 'Сегодня был насыщенный день.';

  @override
  String get digestHardNight => 'Ночь была немного трудной.';

  @override
  String get momentsTitle => 'Моменты дня';

  @override
  String get momentsLineOne => 'Маленький момент сегодняшнего дня';

  @override
  String get momentsLineTwo => 'Сегодня была новая улыбка';

  @override
  String get momentsLineMany => 'Воспоминание, которое стоит сохранить';

  @override
  String get storyTitleCare => 'Неделя заботы';

  @override
  String get storyTitleGrowing => 'Растём вместе';

  @override
  String get storyTitleMoments => 'Маленькие моменты, большая любовь';

  @override
  String get storyFeedings => 'Кормлений';

  @override
  String get storySleep => 'Сна за неделю';

  @override
  String get storyNappies => 'Подгузников';

  @override
  String get storyBestNight => 'Лучшая ночь';

  @override
  String get storyExport => 'Сохранить PDF';

  @override
  String get storyPdfReady => 'Страница недели готова';

  @override
  String get appreciationHeavyDay =>
      'Сегодня был непростой день. Вы сделали очень много для малыша.';

  @override
  String get appreciationThanks =>
      'Папа поблагодарил вас за сегодняшний день ❤️';

  @override
  String get appreciationThankButton => 'Спасибо за сегодняшний день';

  @override
  String get appreciationThankSent => 'Спасибо отправлено';

  @override
  String get voiceQuickHint => 'Записать голосом';

  @override
  String get voiceHoldHint => 'Удерживайте кнопку и говорите';

  @override
  String get voiceExample => '«покормила левой 15 минут»';

  @override
  String get voiceBusy => 'Секунду — заканчиваю прошлую запись';

  @override
  String get voiceTraceHint =>
      'Что произошло. Пришлите этот список, если микрофон не работает';

  @override
  String get voiceTapHint => 'Нажмите и говорите';

  @override
  String get voiceTapToStop => 'Нажмите ещё раз, когда закончите';

  @override
  String get voiceSheetTitle => 'Скажите или напишите';

  @override
  String get voiceKeyboardHint =>
      'Нажмите микрофон на клавиатуре и продиктуйте — это диктовка вашего телефона';

  @override
  String get voiceNothingYet => 'Пока пусто';

  @override
  String get voiceWillSave => 'Запишем';

  @override
  String get voiceFieldHint => 'Скажите или напишите…';

  @override
  String get commonUndo => 'Отменить';

  @override
  String get voiceSavingSoon => 'Записать сейчас';

  @override
  String get voiceOpening => 'Открываю микрофон…';

  @override
  String get voiceHeard => 'Услышано';

  @override
  String get voiceMl => 'мл';

  @override
  String get voiceAsNote => 'Сохраним как заметку';

  @override
  String get homeQuickLog => 'Быстрая запись';

  @override
  String get homeRecent => 'Последние события';

  @override
  String get homeNothingYet => 'Пока ничего не записано';

  @override
  String get homeMore => 'Всё остальное — во вкладке «Помощник»';

  @override
  String get assistantInsights => 'Наблюдения и отчёты';

  @override
  String get assistantViewKnowledge => 'Справочник';

  @override
  String get assistantViewInsights => 'Сводка';

  @override
  String get familyTitle => 'Семья';

  @override
  String get familySubtitle => 'Кто ещё видит профиль ребёнка';

  @override
  String get familyInvite => 'Пригласить';

  @override
  String get familyInviteEmail => 'Электронная почта';

  @override
  String get familyInviteHint =>
      'Адрес, которым он входит в приложение — по нему и открывается доступ';

  @override
  String get familyInvitePhone => 'Телефон в WhatsApp';

  @override
  String get familyInvitePhoneHint =>
      'Куда отправить приглашение. Без телефона его придётся передать самому — приложение сразу предложит скопировать';

  @override
  String get familyPhoneInvalid => 'Проверьте номер';

  @override
  String get familyInviteWhatsApp => 'Приглашение отправлено в WhatsApp';

  @override
  String familyInviteMailed(String email) {
    return 'Приглашение отправлено на $email';
  }

  @override
  String get familyInviteMailFailed =>
      'Отправить не удалось. Скопируйте приглашение и передайте сами';

  @override
  String get familyInviteCreated =>
      'Доступ уже открыт — осталось передать приглашение';

  @override
  String get familyInviteExplain =>
      'Письма приложение не отправляет. Укажите телефон — приглашение придёт в WhatsApp; иначе скопируйте его и передайте сами.';

  @override
  String get familyCopyInvite => 'Скопировать приглашение';

  @override
  String get familyInviteCopied =>
      'Текст приглашения скопирован — вставьте в мессенджер';

  @override
  String familyInviteMessage(String name, String email, String link) {
    return 'Я открыл доступ к дневнику ребёнка ($name). Открой ссылку и войди почтой $email: $link';
  }

  @override
  String get familyInviteSent => 'Приглашение отправлено';

  @override
  String get familyEmailInvalid => 'Проверьте адрес';

  @override
  String get familyPending => 'Ожидает подтверждения';

  @override
  String get familyAccepted => 'Есть доступ';

  @override
  String get familyNobody => 'Пока только вы';

  @override
  String get familyRemove => 'Убрать доступ';

  @override
  String get familyRoleOwner => 'Мама';

  @override
  String get familyRoleViewer => 'Папа';

  @override
  String get familyReadOnly => 'Только просмотр';

  @override
  String get familyReadOnlyHint => 'Вы видите профиль, но не меняете записи';

  @override
  String get familyInviteBanner => 'Вас пригласили в профиль ребёнка';

  @override
  String get familyAccept => 'Принять';

  @override
  String get familyLater => 'Позже';

  @override
  String get familyAcceptedToast => 'Теперь вы видите профиль';

  @override
  String get familyOwnerOnly => 'Это может изменить только владелец профиля';

  @override
  String get familyAlreadyMember => 'У этого адреса уже есть доступ';

  @override
  String get familySelfInvite => 'Это ваш собственный адрес';

  @override
  String get voiceListening => 'Слушаю…';

  @override
  String get voiceSpeakNow => 'Говорите';

  @override
  String get voiceFailed => 'Не удалось распознать речь';

  @override
  String get voiceUnavailable => 'Микрофон недоступен — заметку можно написать';

  @override
  String get voiceDictate => 'Продиктовать заметку';

  @override
  String get voiceStop => 'Остановить запись';

  @override
  String get quickFeedHint => 'грудь или бутылочка';

  @override
  String get quickNappyHint => 'мокрый или стул';

  @override
  String get quickSleepHint => 'дневной отдых';

  @override
  String get quickNightSleepHint => 'с пробуждениями';

  @override
  String get quickTemperatureHint => 'одно измерение';

  @override
  String get quickAssistantHint => 'спросить о малыше';

  @override
  String get phraseOfDay1 => 'Вы делаете достаточно.';

  @override
  String get phraseOfDay2 => 'Сегодня можно медленнее.';

  @override
  String get phraseOfDay3 => 'Малыш чувствует вашу заботу.';

  @override
  String get phraseOfDay4 => 'Отдых — это тоже забота.';

  @override
  String get phraseOfDay5 => 'Каждый день немного проще.';

  @override
  String get phraseOfDay6 => 'Вы рядом, и этого хватает.';

  @override
  String get quickFever =>
      'Это лихорадка. День будет отмечен как день болезни.';

  @override
  String get quickFeverAction => 'Что делать';

  @override
  String get growthChartTitle => 'Динамика показателей';

  @override
  String get growthAddMeasurement => 'Добавить измерение';

  @override
  String get growthEmpty => 'Пока нечего показать на графике';

  @override
  String get growthEmptyHint =>
      'Добавьте рост и вес в дневнике — кривая появится после первого измерения, а нормы ВОЗ уже ждут';

  @override
  String get growthAxisAge => 'возраст, месяцев';

  @override
  String get growthWhoMedian => 'медиана ВОЗ';

  @override
  String get growthWhoBand => 'коридор ±2 SD';

  @override
  String get growthWhoLimit =>
      'Нормы ВОЗ определены до 5 лет, поэтому справочные кривые обрываются на 60 месяцах.';

  @override
  String get growthWhoAssessment => 'Оценка по нормам ВОЗ';

  @override
  String get growthAgeOutOfRange =>
      'Возраст вне диапазона справочных таблиц (0–60 месяцев)';

  @override
  String growthPercentileOrdinal(int p) {
    return '$p-й';
  }

  @override
  String get growthPercentileWord => 'перцентиль';

  @override
  String growthChangeSince(String date) {
    return 'прибавка с $date';
  }

  @override
  String get growthZScore => 'z-оценка';

  @override
  String get growthDisclaimer =>
      'Расчёт по нормам ВОЗ для детей 0–5 лет. Перцентиль показывает положение среди сверстников, а не диагноз: отклонение может быть и особенностью конкретного ребёнка. Оценивает врач.';

  @override
  String get growthHistory => 'История измерений';

  @override
  String get illnessTitle => 'Статистика заболеваемости';

  @override
  String illnessHeatmap(int months) {
    return 'Тепловая карта за $months месяцев';
  }

  @override
  String get illnessEpisodes => 'Эпизоды болезни';

  @override
  String get illnessAdd => 'Отметить болезнь';

  @override
  String get illnessEmpty => 'Записей о болезнях нет';

  @override
  String get illnessEmptyHint => 'Отметить день болезни можно в дневнике';

  @override
  String get illnessEpisodesCount => 'эпизодов';

  @override
  String get illnessDays12 => 'дней за 12 месяцев';

  @override
  String get illnessDays3 => 'дней за 3 месяца';

  @override
  String get illnessWell => 'здоров';

  @override
  String illnessDayWell(String date) {
    return '$date — здоров';
  }

  @override
  String remindersActiveCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n активных напоминания',
      many: '$n активных напоминаний',
      few: '$n активных напоминания',
      one: '$n активное напоминание',
    );
    return '$_temp0';
  }

  @override
  String remindersOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'просрочено на $n дня',
      many: 'просрочено на $n дней',
      few: 'просрочено на $n дня',
      one: 'просрочено на $n день',
    );
    return '$_temp0';
  }

  @override
  String remindersInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'через $n дня',
      many: 'через $n дней',
      few: 'через $n дня',
      one: 'через $n день',
    );
    return '$_temp0';
  }

  @override
  String get medicalTitle => 'Медицинские записи';

  @override
  String get medicalEmpty => 'Медицинских записей пока нет';

  @override
  String get medicalEmptyHint =>
      'Добавьте визит к врачу или результаты анализов';

  @override
  String get medicalDeleteTitle => 'Удалить запись?';

  @override
  String medicalDeleteBody(String diagnosis, String date) {
    return 'Запись «$diagnosis» от $date будет удалена вместе с результатами анализов. Действие необратимо.';
  }

  @override
  String get medicalAskDoctor => 'Спросить у врача';

  @override
  String get medicalWriteDown => 'Записать';

  @override
  String get medicalQuestionsHint =>
      'Запишите сюда всё, что хотите спросить. Список попадёт в отчёт для врача — не придётся вспоминать в кабинете.';

  @override
  String get medicalQuestionAsked => 'Вопрос отмечен как заданный';

  @override
  String get medicalQuestionSaved => 'Вопрос записан — он попадёт в отчёт';

  @override
  String get entrySaved => 'Запись сохранена';

  @override
  String get entryDeleted => 'Запись удалена';

  @override
  String get medicalRecordSaved => 'Запись в медкарте сохранена';

  @override
  String get medicalRecordDeleted => 'Запись удалена из медкарты';

  @override
  String get medicalAsked => 'Спросила';

  @override
  String get medicalQuestionHint =>
      'Например: нормально ли, что срыгивает после каждого кормления';

  @override
  String get medicalReport => 'Отчёт для врача';

  @override
  String get medicalReportHint =>
      'Сводка на одном листе: антропометрия с оценкой по нормам ВОЗ, статистика болезней, анализы с отклонениями, статус вакцинации и вехи развития.';

  @override
  String get medicalReportBuilding => 'Формирую…';

  @override
  String get medicalReportDownload => 'Скачать PDF';

  @override
  String medicalReportFailed(String error) {
    return 'Не удалось сформировать отчёт: $error';
  }

  @override
  String get medicalPrescriptions => 'Назначения';

  @override
  String get medicalLabResults => 'Результаты анализов';

  @override
  String medicalOutOfRange(int n) {
    return '$n вне нормы';
  }

  @override
  String get medicalScans => 'Сканы бланков';

  @override
  String get medicalIndicator => 'Показатель';

  @override
  String get medicalValue => 'Значение';

  @override
  String get medicalReference => 'Норма';

  @override
  String get medicalRecordTitle => 'Медицинская запись';

  @override
  String get medicalDiagnosis => 'Диагноз или причина визита';

  @override
  String get medicalDiagnosisRequired => 'Укажите диагноз или причину визита';

  @override
  String get medicalDoctor => 'Врач и учреждение';

  @override
  String get medicalDoctorHint => 'Педиатр, поликлиника №2';

  @override
  String get medicalLabs => 'Анализы';

  @override
  String get medicalAddRow => 'Добавить строку';

  @override
  String get medicalReferenceHint =>
      'Референсные значения не обязательны, но без них приложение не сможет отметить отклонение.';

  @override
  String get medicalScan => 'Скан бланка';

  @override
  String medicalUploadFailed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String medicalRowInvalid(String name) {
    return 'Проверьте строку «$name»: нужно название и числовое значение.';
  }

  @override
  String get medicalUnitShort => 'Ед.';

  @override
  String get medicalFrom => 'от';

  @override
  String get medicalTo => 'до';

  @override
  String get medicalRemoveRow => 'Убрать строку';

  @override
  String get medicalAttach => 'Прикрепить';

  @override
  String get assistantSearchHint =>
      'Поиск по статьям: температура, сыпь, прикорм…';

  @override
  String get assistantSearchIsArticles =>
      'Это поиск по статьям приложения. На любой вопрос ответит помощник.';

  @override
  String get assistantAskAi => 'Спросить помощника';

  @override
  String get assistantNothingFound => 'Ничего не нашлось';

  @override
  String assistantNoArticle(String query) {
    return 'По запросу «$query» в базе пока нет статьи';
  }

  @override
  String get assistantTryAnother =>
      'Попробуйте другое слово — например, «температура» или «сыпь»';

  @override
  String get assistantFound => 'Найдено';

  @override
  String assistantArticlesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n статьи',
      many: '$n статей',
      few: '$n статьи',
      one: '$n статья',
    );
    return '$_temp0';
  }

  @override
  String get assistantTriage => 'Проверить тревожные признаки';

  @override
  String get assistantTriageHint =>
      'Несколько вопросов — и понятно, ждать или звонить 103';

  @override
  String get assistantChat => 'Спросить своими словами';

  @override
  String get assistantChatHint =>
      'Ответит на любой вопрос — о ребёнке и не только';

  @override
  String get assistantChatOff =>
      'ИИ пока не подключён — откройте, чтобы узнать как';

  @override
  String get assistantRelevant => 'Актуально сейчас';

  @override
  String assistantChildAge(String name, int months) {
    return '$name, $months мес.';
  }

  @override
  String get assistantAllTopics => 'Все темы';

  @override
  String get assistantDisclaimer =>
      'Материалы основаны на рекомендациях ВОЗ, NICE и Американской академии педиатрии. Это справочная информация для родителей, а не замена осмотру. Окончательное решение всегда за врачом.';

  @override
  String get chatTitle => 'Спросить помощника';

  @override
  String get chatEmpty => 'Спросите что-нибудь о здоровье ребёнка';

  @override
  String chatHint(String name) {
    return 'Спросите о чём угодно — про $name или про своё';
  }

  @override
  String get chatSend => 'Отправить';

  @override
  String get chatAsk => 'Спросите о чём угодно';

  @override
  String get chatOrRecord =>
      'Или продиктуйте запись — «покормила левой 15 минут», «спал 2 часа», «температура 37.2». Запишу в дневник.';

  @override
  String get chatRecordUndone => 'Запись удалена';

  @override
  String chatOpening(String name) {
    return 'Спросите о чём угодно — про $name или про своё';
  }

  @override
  String get chatDisclaimer =>
      'Помощник отвечает на любые вопросы. О здоровье ребёнка он опирается на проверенную базу приложения, где она есть, и не ставит диагнозов — решение всегда за врачом.';

  @override
  String get chatGeneralAnswer =>
      'Ответ из знаний ИИ, а не из проверенной базы приложения. Если вопрос о здоровье — уточните у врача.';

  @override
  String get chatEmergency => 'Вызывайте скорую — 103';

  @override
  String get chatEmergencyBody =>
      'В вашем вопросе есть признак, при котором нельзя ждать. Я намеренно не передаю такие вопросы ИИ — здесь нужен не совет, а немедленная помощь.';

  @override
  String get chatWhatToDo => 'Что делать до приезда скорой';

  @override
  String get chatSources => 'Ответ построен по статьям:';

  @override
  String get chatOpenKb => 'Открыть базу знаний';

  @override
  String get chatAiOff => 'ИИ-помощник пока не подключён';

  @override
  String get chatAiOffBody =>
      'База знаний и проверка тревожных признаков работают без него — они не требуют интернета вообще.';

  @override
  String get chatAiOffHow =>
      'Чтобы включить ИИ, нужно развернуть бесплатный прокси на Cloudflare Workers и пересобрать приложение с его адресом. Инструкция — в файле worker/README.md.';

  @override
  String get chatSuggestionsTitle => 'С чего начать';

  @override
  String askTemperature(String value) {
    return 'Температура $value — что делать и когда звонить врачу';
  }

  @override
  String askWhyTemperature(String value) {
    return 'Сегодня вы отметили $value';
  }

  @override
  String askHardNight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ребёнок просыпался $n раза за ночь — что можно сделать',
      many: 'Ребёнок просыпался $n раз за ночь — что можно сделать',
      few: 'Ребёнок просыпался $n раза за ночь — что можно сделать',
      one: 'Ребёнок просыпался $n раз за ночь — что можно сделать',
    );
    return '$_temp0';
  }

  @override
  String askWhyHardNight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Прошлой ночью $n пробуждения',
      many: 'Прошлой ночью $n пробуждений',
      few: 'Прошлой ночью $n пробуждения',
      one: 'Прошлой ночью $n пробуждение',
    );
    return '$_temp0';
  }

  @override
  String get askQuietNappies =>
      'Ребёнок давно не какал — когда это повод беспокоиться';

  @override
  String get askWhyQuietNappies => 'Подгузник не отмечали больше суток';

  @override
  String get askNewbornFeeding => 'Как понять, что новорождённый наедается';

  @override
  String get askSleepNeeds => 'Сколько сна нужно ребёнку в этом возрасте';

  @override
  String get askSolids => 'Когда начинать прикорм и с чего';

  @override
  String get askMilestones => 'Что ребёнок обычно умеет в этом возрасте';

  @override
  String get askWhyAge => 'По возрасту малыша';

  @override
  String get chatSuggestionsHint => 'Собрано из ваших записей';

  @override
  String get chatSuggestion1 => 'Температура 38.5, что делать';

  @override
  String get chatSuggestion2 => 'Составь список покупок на неделю';

  @override
  String get chatSuggestion3 => 'Напиши поздравление бабушке на юбилей';

  @override
  String get chatSuggestion4 => 'Можно ли мне антибиотик при ГВ';

  @override
  String get chatSuggestion5 => 'Ребёнок не какал два дня';

  @override
  String get actionSuggested => 'Помощник предлагает';

  @override
  String get actionConfirm => 'Подтвердить';

  @override
  String get actionDismiss => 'Не надо';

  @override
  String get actionReadOnly =>
      'У вас доступ только для просмотра — записать может родитель, который вас пригласил.';

  @override
  String get actionFailed => 'Не удалось выполнить';

  @override
  String actionWrite(String what) {
    return 'Записать: $what';
  }

  @override
  String actionCreateReminder(String title, String when) {
    return 'Создать напоминание «$title» — $when';
  }

  @override
  String actionOpenScreen(String screen) {
    return 'Открыть раздел «$screen»';
  }

  @override
  String actionOpenArticle(String title) {
    return 'Открыть статью «$title»';
  }

  @override
  String get actionBuildReport => 'Собрать PDF-отчёт для врача';

  @override
  String get triageTitle => 'Проверка тревожных признаков';

  @override
  String get triageNeedChild => 'Нужен профиль ребёнка';

  @override
  String get triageNeedChildHint =>
      'Возраст влияет на оценку — особенно до 3 месяцев';

  @override
  String get triageNeedChildAction => 'Создайте профиль в разделе «Дети»';

  @override
  String get triageTemperatureHint => 'Если измеряли — введите, например 38.5';

  @override
  String get triageCheckAll => 'Отметьте всё, что есть';

  @override
  String get triageEvaluate => 'Оценить состояние';

  @override
  String get triageRestart => 'Начать заново';

  @override
  String get triageConsidered => 'Что учтено:';

  @override
  String get triageDisclaimer =>
      'Это не диагноз. Оценка построена по формальным признакам и не заменяет осмотр. Если вам тревожно, а проверка показала «наблюдать дома» — всё равно обратитесь к врачу.';

  @override
  String get articleNotFound => 'Статья не найдена';

  @override
  String get articleNotFoundBody => 'Такой статьи в базе нет';

  @override
  String get articleToList => 'К списку тем';

  @override
  String get articleEmergency => 'Скорая помощь — 103';

  @override
  String get articleWhatToDo => 'Что делать сейчас';

  @override
  String get articleWhenDoctor => 'Когда обратиться к врачу';

  @override
  String get articleSources => 'Источники';

  @override
  String get articleDisclaimer =>
      'Это справочная информация, а не диагноз и не назначение. Если что-то беспокоит — обратитесь к педиатру. При тревожных признаках звоните 103.';

  @override
  String get settingsParent => 'Родитель';

  @override
  String get settingsYourName => 'Как вас зовут';

  @override
  String get settingsUnits => 'Единицы измерения';

  @override
  String get settingsUnitsHint =>
      'Измерения всегда хранятся в метрических единицах и пересчитываются только для показа — поэтому переключение ничего не портит в уже введённых данных.';

  @override
  String get settingsTemperatureHint =>
      'Температура остаётся в °C в обеих системах: все пороги в приложении и в рекомендациях указаны в градусах Цельсия.';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsAuthor => 'Разработчик';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsDeleteSection => 'Удаление учётной записи';

  @override
  String get settingsDeleteWarning =>
      'Вместе с записью безвозвратно удаляются все дети, дневник, медкарта и напоминания. Отменить это будет нельзя, поэтому сначала выгрузите PDF-отчёт, если он вам нужен.';

  @override
  String get settingsChangeButton => 'Сменить';

  @override
  String get growthVerdictSeverelyLow => 'Значительно ниже нормы';

  @override
  String get growthVerdictLow => 'Ниже нормы';

  @override
  String get growthVerdictNormal => 'В пределах нормы';

  @override
  String get growthVerdictHigh => 'Выше нормы';

  @override
  String get growthVerdictSeverelyHigh => 'Значительно выше нормы';

  @override
  String growthMetricWithDate(String metric, String date) {
    return '$metric, $date';
  }

  @override
  String get medicalAdd => 'Добавить запись';

  @override
  String get photoNotAnImage =>
      'Не удалось прочитать изображение. Поддерживаются JPG, PNG и WebP.';

  @override
  String get photoStillTooLarge =>
      'Изображение слишком большое даже после сжатия. Попробуйте снять кадр ближе или обрезать его.';

  @override
  String get nowLastFeeding => 'Последнее кормление';

  @override
  String get nowLastSleep => 'Последний сон';

  @override
  String get nowNothingYet => 'пока нет';

  @override
  String nowAgo(String duration) {
    return '$duration назад';
  }

  @override
  String get suggestionAfterSleep => 'Часто после сна бывает кормление';

  @override
  String get suggestionNappy => 'Давно не отмечали подгузник';

  @override
  String get suggestionDismiss => 'Скрыть';

  @override
  String get reflectionTitle => 'Сегодня';

  @override
  String reflectionFeedingsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n кормления',
      many: '$n кормлений',
      few: '$n кормления',
      one: '$n кормление',
    );
    return '$_temp0';
  }

  @override
  String reflectionSummary(String feedings, String sleep) {
    return 'Сегодня: $feedings и $sleep сна. Это помогает видеть картину дня, не считая в уме.';
  }

  @override
  String reflectionSummaryNoSleep(String feedings) {
    return 'Сегодня: $feedings. Сон за день никто не отмечал.';
  }

  @override
  String get reflectionSupport =>
      'Вы записали все важные события дня. Это уже большая помощь себе и ребёнку.';

  @override
  String get reflectionNappies => 'подгузников';

  @override
  String get patternSleepThenFeeding =>
      'Похоже, после дневного сна кормление обычно появляется через 20–40 минут.';

  @override
  String patternNightStart(String time) {
    return 'Ночной сон чаще всего начинается около $time.';
  }

  @override
  String get patternStableSleep =>
      'Суммарный сон последние дни остаётся примерно одинаковым.';

  @override
  String get contextTitle => 'Контекст ребёнка';

  @override
  String get contextNotRecorded => 'Не отмечалась';

  @override
  String get chatContinueTitle => 'Продолжить разговор';

  @override
  String chatContinueLast(String question) {
    return 'Последний вопрос: «$question»';
  }

  @override
  String get chatContinueResume => 'Продолжить';

  @override
  String get chatContinueNew => 'Новый';

  @override
  String get checkInTitle => 'Как вы себя чувствуете?';

  @override
  String get checkInHoldingUp => 'Держусь';

  @override
  String get checkInTired => 'Устала';

  @override
  String get checkInVeryHard => 'Очень тяжело';

  @override
  String get checkInReplyHoldingUp =>
      'Пусть сегодня у вас найдётся хотя бы один спокойный момент для себя.';

  @override
  String get checkInReplyTired =>
      'Усталость после тяжёлой ночи очень понятна. Постарайтесь опираться на самое важное, а не на идеальный порядок.';

  @override
  String get checkInReplyVeryHard =>
      'Если есть возможность, попросите кого-то побыть рядом хотя бы ненадолго. Забота о себе — тоже часть заботы о ребёнке.';

  @override
  String get vaccineHepB1 => 'Гепатит B (ВГВ) — первая доза';

  @override
  String get vaccineNoteHepB1 => 'В первые сутки жизни';

  @override
  String get vaccineBcg => 'Туберкулёз (БЦЖ)';

  @override
  String get vaccineNoteBcg => 'На 1-4 сутки жизни';

  @override
  String get vaccinePenta1 =>
      'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — первая доза';

  @override
  String get vaccineNotePenta1 =>
      'Коклюш, дифтерия, столбняк, гемофильная инфекция, гепатит B, полиомиелит';

  @override
  String get vaccinePcv1 => 'Пневмококковая инфекция (ПНВ) — первая доза';

  @override
  String get vaccinePenta2 => 'АбКДС + Хиб + ИПВ — вторая доза';

  @override
  String get vaccinePenta3 =>
      'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — третья доза';

  @override
  String get vaccinePcv2 => 'Пневмококковая инфекция (ПНВ) — вторая доза';

  @override
  String get vaccineMmr1 => 'Корь, краснуха, паротит (ККП) — первая доза';

  @override
  String get vaccineNoteMmr1 => 'В 12-15 месяцев';

  @override
  String get vaccinePcvBooster =>
      'Пневмококковая инфекция (ПНВ) — ревакцинация';

  @override
  String get vaccineOpv => 'Полиомиелит (ОПВ)';

  @override
  String get vaccinePentaBooster => 'АбКДС + Хиб + ИПВ — ревакцинация';

  @override
  String get vaccineNotePentaBooster => 'В 18 месяцев';

  @override
  String get vaccineHepA1 => 'Гепатит A (ВГА) — первая доза';

  @override
  String get vaccineNoteHepA1 => 'В 2 года';

  @override
  String get vaccineHepA2 => 'Гепатит A (ВГА) — вторая доза';

  @override
  String get vaccineNoteHepA2 => 'Через 6 месяцев';

  @override
  String get vaccineDtapBooster => 'АбКДС — ревакцинация';

  @override
  String get vaccineNoteDtapBooster => 'В 6 лет, перед школой';

  @override
  String get vaccineMmr2 => 'Корь, краснуха, паротит (ККП) — вторая доза';

  @override
  String get vaccineHpv1 => 'ВПЧ — первая доза (девочки)';

  @override
  String get vaccineNoteHpv1 => 'В 11 лет, по согласию родителей';

  @override
  String get vaccineHpv2 => 'ВПЧ — вторая доза (девочки)';

  @override
  String get vaccineNoteHpv2 => 'Через 6 месяцев';

  @override
  String get vaccineTdBooster => 'АДС-М — ревакцинация';

  @override
  String get vaccineNoteTdBooster => 'В 16 лет, далее каждые 10 лет';

  @override
  String get vaccineSource => 'Календарь прививок РК';

  @override
  String get reportExport => 'Экспорт PDF';

  @override
  String reportPeriodDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня',
      many: '$n дней',
      few: '$n дня',
      one: '$n день',
    );
    return '$_temp0';
  }

  @override
  String get reportPeriod => 'Период отчёта';

  @override
  String reportRange(String from, String to) {
    return '$from — $to';
  }

  @override
  String get reportTitle => 'Отчёт для врача';

  @override
  String get reportNothing => 'За этот период записей нет';

  @override
  String get reportPreparing => 'Готовим PDF…';

  @override
  String get reportReady => 'Отчёт готов';

  @override
  String get reportShareFailed => 'Не удалось открыть отчёт';

  @override
  String get reportSectionSleep => 'Сон';

  @override
  String get reportAvgNight => 'Средний ночной сон';

  @override
  String get reportAvgDay => 'Средний дневной сон';

  @override
  String get reportAvgWakings => 'Среднее число пробуждений';

  @override
  String get reportSectionFeeding => 'Кормление';

  @override
  String get reportFeedingsTotal => 'Всего кормлений';

  @override
  String get reportBreast => 'Грудь';

  @override
  String get reportBottle => 'Бутылочка';

  @override
  String get reportSectionNappies => 'Подгузники';

  @override
  String get reportSectionTemperature => 'Температура';

  @override
  String get reportTempMax => 'Максимум';

  @override
  String get reportTempMin => 'Минимум';

  @override
  String get reportTempCount => 'Измерений';

  @override
  String get reportSectionMedicines => 'Лекарства';

  @override
  String get reportSectionNotes => 'Заметки';

  @override
  String get reportFoodName => 'Продукт';

  @override
  String get reportFoodFirst => 'Впервые';

  @override
  String get reportFoodTimes => 'Раз';

  @override
  String get reportFoodReaction => 'Что было после';

  @override
  String get reportSectionQuestions => 'Вопросы врачу';

  @override
  String get reportQuestion => 'Вопрос';

  @override
  String get reportAnswer => 'Ответ врача';

  @override
  String get importTitle => 'Перенос из другого приложения';

  @override
  String get importPickTitle => 'Файл с записями';

  @override
  String get importHint =>
      'Выгрузите записи из прежнего приложения и выберите файл здесь. Ничего не запишется, пока вы не подтвердите — сначала покажу, что нашлось.';

  @override
  String get importFormats =>
      'Подойдёт CSV или текстовый файл с колонками: дата, время, тип записи, длительность, комментарий';

  @override
  String get importPickButton => 'Выбрать файл';

  @override
  String get importFoundTitle => 'Что нашлось';

  @override
  String get importColumns => 'Как поняты колонки';

  @override
  String importSkipped(int n) {
    return 'Строк пропущено: $n';
  }

  @override
  String get importNothingFound => 'В файле не нашлось ни одной записи с датой';

  @override
  String get importWriteTitle => 'Перенести в дневник';

  @override
  String importWriteHint(int n) {
    return 'Будет добавлено записей: $n. Они появятся в дневнике своими датами.';
  }

  @override
  String importWriteButton(int n) {
    return 'Перенести $n';
  }

  @override
  String importDone(int n) {
    return 'Перенесено записей: $n';
  }

  @override
  String get importRoleDate => 'дата';

  @override
  String get importRoleTime => 'время';

  @override
  String get importRoleKind => 'тип записи';

  @override
  String get importRoleDuration => 'длительность';

  @override
  String get importRoleAmount => 'объём';

  @override
  String get importRoleNote => 'комментарий';

  @override
  String get importRoleIgnored => 'не используется';

  @override
  String get settingsImport => 'Перенести данные';

  @override
  String get settingsImportHint => 'Из другого дневника — по файлу выгрузки';

  @override
  String get teethDisclaimer =>
      'Сроки — средние по педиатрическим таблицам, а не мерка для конкретного ребёнка. Если что-то беспокоит — спросите педиатра или стоматолога.';

  @override
  String get teethTitle => 'Зубы';

  @override
  String teethCount(int n) {
    return 'Прорезалось $n из 20';
  }

  @override
  String get teethNone => 'Пока ни одного';

  @override
  String teethUsual(int from, int to) {
    return 'В этом возрасте обычно $from–$to';
  }

  @override
  String teethNext(String tooth) {
    return 'Дальше обычно — $tooth';
  }

  @override
  String get teethLegendThrough => 'прорезался';

  @override
  String get teethLegendNotYet => 'ещё нет';

  @override
  String get teethLegendAge => 'цифра — возраст в месяцах';

  @override
  String get teethHint => 'Нажмите на зуб, когда он прорежется';

  @override
  String get teethWhen => 'Когда прорезался?';

  @override
  String get teethToday => 'Сегодня';

  @override
  String get teethYesterday => 'Вчера';

  @override
  String get teethPickDate => 'Другая дата';

  @override
  String get teethUnmarked => 'Отметка убрана';

  @override
  String get teethRemove => 'Убрать отметку';

  @override
  String teethMarked(String tooth) {
    return '$tooth — отмечен';
  }

  @override
  String teethAtAge(int months) {
    return 'в $months мес.';
  }

  @override
  String teethExpected(int from, int to) {
    return 'Обычно $from–$to мес.';
  }

  @override
  String get teethUpperJaw => 'Верхние';

  @override
  String get teethLowerJaw => 'Нижние';

  @override
  String toothName(String jaw, String type, String side) {
    return '$jaw $type, $side';
  }

  @override
  String get toothCentralIncisor => 'центральный резец';

  @override
  String get toothLateralIncisor => 'боковой резец';

  @override
  String get toothCanine => 'клык';

  @override
  String get toothFirstMolar => 'первый моляр';

  @override
  String get toothSecondMolar => 'второй моляр';

  @override
  String get toothUpper => 'Верхний';

  @override
  String get toothLower => 'Нижний';

  @override
  String get toothLeft => 'слева';

  @override
  String get toothRight => 'справа';

  @override
  String get visitTitle => 'Подготовка к приёму';

  @override
  String get visitCardHint =>
      'Вопросы, прививки, прикорм и что было с прошлого раза — на одном экране';

  @override
  String get visitOpen => 'Открыть';

  @override
  String visitQuestionsWaiting(int n) {
    return 'Записано вопросов: $n';
  }

  @override
  String get visitMeasureTitle => 'Вес и рост';

  @override
  String visitMeasuredAt(String date, int days) {
    return 'Измеряли $date — $days дн. назад';
  }

  @override
  String get visitMeasureNone => 'Измерений ещё нет';

  @override
  String get visitVaccinesTitle => 'Прививки';

  @override
  String get visitVaccinesNone =>
      'На ближайшие две недели ничего не запланировано';

  @override
  String visitVaccineDue(String name, String date) {
    return '$name — $date';
  }

  @override
  String visitVaccineOverdue(String name, String date) {
    return '$name — срок был $date';
  }

  @override
  String visitFoodsNew(int n) {
    return 'Новых продуктов за этот период: $n';
  }

  @override
  String get visitHistoryTitle => 'Что было';

  @override
  String visitSinceVisit(String date) {
    return 'С приёма $date';
  }

  @override
  String visitSinceDays(int days) {
    return 'За последние $days дн.';
  }

  @override
  String get visitHistoryEmpty =>
      'За это время записей о болезни, температуре и лекарствах нет';

  @override
  String visitSickDays(int n) {
    return 'Дней с болезнью: $n';
  }

  @override
  String visitMaxTemperature(String value) {
    return 'Максимальная температура: $value °C';
  }

  @override
  String visitMedicines(int n) {
    return 'Записей о лекарствах: $n';
  }

  @override
  String get visitTakeTitle => 'Взять с собой';

  @override
  String get visitTakeHint =>
      'Один лист: цифры за период, прикорм и ваши вопросы с местом для ответов врача.';

  @override
  String get reportDisclaimer =>
      'Отчёт предназначен для удобства обсуждения с врачом и не является медицинским заключением.';

  @override
  String reportPage(int page, int total) {
    return 'Страница $page из $total';
  }
}
