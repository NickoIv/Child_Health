// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'Бала дамуы мен денсаулық күнтізбесі';

  @override
  String get navDashboard => 'Шолу';

  @override
  String get navAssistant => 'Көмекші';

  @override
  String get navDiary => 'Күнделік';

  @override
  String get navGrowth => 'Даму';

  @override
  String get navIllness => 'Аурулар';

  @override
  String get navMedical => 'Медкарта';

  @override
  String get navReminders => 'Еске салу';

  @override
  String get navChildren => 'Балалар';

  @override
  String get navFamily => 'Отбасы';

  @override
  String get navMore => 'Тағы';

  @override
  String get authSignInSubtitle => 'Жалғастыру үшін кіріңіз';

  @override
  String get authRegisterSubtitle => 'Ата-ана тіркелгісін жасаңыз';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Құпия сөз';

  @override
  String get authSignIn => 'Кіру';

  @override
  String get authRegister => 'Тіркелу';

  @override
  String get authToRegister => 'Тіркелгі жоқ — тіркелу';

  @override
  String get authToSignIn => 'Тіркелгі бар — кіру';

  @override
  String get authForgotPassword => 'Құпия сөзді ұмыттыңыз ба?';

  @override
  String get authOr => 'немесе';

  @override
  String get authWithGoogle => 'Google арқылы кіру';

  @override
  String get authWithApple => 'Apple арқылы кіру';

  @override
  String get authEmailRequired => 'Email енгізіңіз';

  @override
  String get authEmailIncomplete => 'Мекенжай толық емес сияқты';

  @override
  String get authPasswordRequired => 'Құпия сөзді енгізіңіз';

  @override
  String get authPasswordTooShort => 'Кемінде 6 таңба';

  @override
  String get authResetNeedsEmail => 'Email енгізіңіз — сілтеме соған келеді';

  @override
  String authResetSent(String email) {
    return 'Құпия сөзді қалпына келтіру хаты $email мекенжайына жіберілді';
  }

  @override
  String authUnexpected(String error) {
    return 'Күтпеген қате: $error';
  }

  @override
  String get authErrorInvalidCredentials => 'Email не құпия сөз қате';

  @override
  String get authErrorInvalidEmail => 'Email мекенжайы дұрыс емес';

  @override
  String get authErrorEmailInUse => 'Бұл email тіркелген';

  @override
  String get authErrorWeakPassword =>
      'Құпия сөз тым қарапайым — кемінде 6 таңба';

  @override
  String get authErrorUserDisabled => 'Тіркелгі өшірілген';

  @override
  String get authErrorRequiresRecentLogin =>
      'Бұл әрекет үшін қайта кіру керек. Шығып, қайта кіріңіз';

  @override
  String get authErrorTooManyRequests =>
      'Тым көп әрекет. Бірнеше минуттан кейін қайталаңыз';

  @override
  String get authErrorNetwork =>
      'Сервермен байланыс жоқ. Интернетті тексеріңіз';

  @override
  String get authErrorOperationNotAllowed =>
      'Email және құпия сөзбен кіру Firebase консолінде өшірілген';

  @override
  String authErrorUnknown(String code) {
    return 'Әрекетті орындау мүмкін болмады: $code';
  }

  @override
  String get authErrorGoogleNotConfigured =>
      'Google арқылы кіру қолданбаның осы нұсқасында бапталмаған';

  @override
  String get authErrorGoogleProvider =>
      'Google бұл қолданбаны растай алмайды. Қолдау қызметіне хабарласыңыз';

  @override
  String get authErrorGoogleInterrupted =>
      'Google арқылы кіру үзілді. Байланысты тексеріп, қайталаңыз';

  @override
  String authErrorGoogleFailed(String detail) {
    return 'Google арқылы кіру мүмкін болмады: $detail';
  }

  @override
  String get authErrorGoogleNoToken =>
      'Google кіру токенін қайтармады. Қайталап көріңіз';

  @override
  String get authErrorSignInFirst => 'Алдымен тіркелгіңізге кіріңіз';

  @override
  String get authErrorNoPassword =>
      'Бұл тіркелгіде құпия сөз жоқ: кіру Google арқылы орындалады. Құпия сөз Google тіркелгісінің баптауларында өзгертіледі';

  @override
  String get authErrorUnknownProvider =>
      'Жеке басты растау мүмкін болмады: кіру тәсілі белгісіз. Шығып, қайта кіріңіз';

  @override
  String get accountMenu => 'Тіркелгі';

  @override
  String get settingsTitle => 'Профиль және баптаулар';

  @override
  String get settingsSignOut => 'Шығу';

  @override
  String get settingsNotifications => 'Хабарландырулар';

  @override
  String get settingsChangePassword => 'Құпия сөзді өзгерту';

  @override
  String get settingsDeleteAccount => 'Тіркелгіні жою';

  @override
  String get settingsLanguage => 'Интерфейс тілі';

  @override
  String get settingsNotificationsOff => 'Хабарландырулар өшірілді';

  @override
  String get settingsNotificationsOn => 'Хабарландырулар қосылды';

  @override
  String settingsLocalOnly(String reason) {
    return 'Осы құрылғыдағы еске салулар қосылды. Push әзірге қолжетімсіз: $reason';
  }

  @override
  String get settingsRemindMe => 'Екпелер мен дәрілер туралы еске салу';

  @override
  String get settingsConnecting => 'Қосылуда…';

  @override
  String get settingsNotificationsHint =>
      'Қолданба негізгі экранға орнатылған немесе браузерде ашық тұрғанда жұмыс істейді. Рұқсатты браузердің өзі сұрайды — бас тартсаңыз, қайта қосуды тек оның сайт баптауларынан жасауға болады.';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get themeAuto => 'Автоматты';

  @override
  String get themeAutoHint => '21:00-ден 7:00-ге дейін қараңғы';

  @override
  String get themeLight => 'Ашық';

  @override
  String get themeDark => 'Қараңғы';

  @override
  String get passwordCurrent => 'Ағымдағы құпия сөз';

  @override
  String get passwordNew => 'Жаңа құпия сөз';

  @override
  String get passwordRepeat => 'Жаңа құпия сөзді қайталаңыз';

  @override
  String get passwordCurrentRequired => 'Ағымдағы құпия сөзді енгізіңіз';

  @override
  String get passwordsDoNotMatch => 'Құпия сөздер сәйкес келмейді';

  @override
  String get passwordChanged => 'Құпия сөз өзгертілді';

  @override
  String get deleteAccountTitle => 'Тіркелгіні жою керек пе?';

  @override
  String get deleteAccountWarning =>
      'Балалар туралы барлық дерек біржола жойылады. Оны қайтару бізге де, сізге де мүмкін болмайды.';

  @override
  String get deleteAccountPassword => 'Құпия сөзіңіз';

  @override
  String get deleteAccountGoogleNote =>
      'Растағаннан кейін Google қайта кіруді сұрайды — жоюды нақ сіз жасап жатқаныңыз осылай тексеріледі.';

  @override
  String get deleteAccountWord => 'ЖОЮ';

  @override
  String deleteAccountWriteWord(String word) {
    return '$word деп жазыңыз';
  }

  @override
  String get deleteAccountConfirm => 'Біржола жою';

  @override
  String get commonCancel => 'Бас тарту';

  @override
  String get commonClose => 'Жабу';

  @override
  String get notificationChannelName => 'Еске салу';

  @override
  String get notificationChannelDescription =>
      'Екпелер, дәрі қабылдау және дәрігерге бару';

  @override
  String get reminderTypeVaccination => 'Екпе';

  @override
  String get reminderTypeMedication => 'Дәрі';

  @override
  String get reminderTypeAppointment => 'Дәрігерге бару';

  @override
  String get recurrenceNone => 'Бір рет';

  @override
  String get recurrenceDaily => 'Күн сайын';

  @override
  String get recurrenceTwiceDaily => 'Күніне екі рет';

  @override
  String get recurrenceWeekly => 'Апта сайын';

  @override
  String get remindersVaccinations => 'Екпе күнтізбесі';

  @override
  String get remindersMedications => 'Дәрі қабылдау';

  @override
  String get remindersAppointments => 'Дәрігерге бару';

  @override
  String get remindersNothingPlanned => 'Жоспарланған ештеңе жоқ';

  @override
  String get remindersShowCompleted => 'Орындалғандарды көрсету';

  @override
  String get quickFeed => 'Тамақтандырдым';

  @override
  String get quickNappy => 'Жаялық';

  @override
  String get quickSleep => 'Ұйықтады';

  @override
  String get quickTemperature => 'Дене қызуы';

  @override
  String get quickSheetFeeding => 'Тамақтандыру';

  @override
  String get quickSheetNappy => 'Жаялық';

  @override
  String get quickSheetSleep => 'Қанша ұйықтады';

  @override
  String get quickSheetSleepShort => 'Ұйқы';

  @override
  String get quickSheetTemperature => 'Дене қызуы';

  @override
  String get quickTimeNow => 'Қазір';

  @override
  String get quickTimeChoose => 'Уақытты таңдау';

  @override
  String get quickNowHint => 'Ағымдағы уақытпен белгіленеді';

  @override
  String get quickSaveButton => 'Жазу';

  @override
  String quickSaved(String what) {
    return 'Жазылды: $what';
  }

  @override
  String get quickSideLeft => 'Сол жақ';

  @override
  String get quickSideRight => 'Оң жақ';

  @override
  String get quickSideBottle => 'Бөтелке';

  @override
  String get quickNappyWet => 'Дымқыл';

  @override
  String get quickNappyDirty => 'Нәжіс';

  @override
  String get quickNappyBoth => 'Дымқыл және нәжіс';

  @override
  String get quickSleep30 => 'Жарты сағат';

  @override
  String get quickSleep60 => 'Бір сағат';

  @override
  String get quickSleep90 => 'Бір жарым сағат';

  @override
  String get quickSleep120 => 'Екі сағат';

  @override
  String get quickSleep180 => 'Үш сағат';

  @override
  String durationH(int h) {
    return '$h сағ';
  }

  @override
  String durationM(int m) {
    return '$m мин';
  }

  @override
  String durationHM(int h, int m) {
    return '$h сағ $m мин';
  }

  @override
  String get commonSave => 'Сақтау';

  @override
  String get commonCreate => 'Жасау';

  @override
  String get commonDelete => 'Жою';

  @override
  String get commonEdit => 'Өзгерту';

  @override
  String get commonAdd => 'Қосу';

  @override
  String get commonRetry => 'Қайталау';

  @override
  String get commonAll => 'Барлығы';

  @override
  String get commonMore => 'Толығырақ';

  @override
  String get commonBack => 'Артқа';

  @override
  String get commonHide => 'Жасыру';

  @override
  String get commonShow => 'Көрсету';

  @override
  String get commonDate => 'Күні';

  @override
  String get commonTime => 'Уақыты';

  @override
  String get commonAge => 'Жасы';

  @override
  String get commonToday => 'бүгін';

  @override
  String get commonTomorrow => 'ертең';

  @override
  String get commonNumberInvalid => 'Сан енгізіңіз';

  @override
  String get commonTechnical => 'Техникалық ақпарат';

  @override
  String get logTypeMilestone => 'Даму кезеңі';

  @override
  String get logTypeMeasurement => 'Өлшем';

  @override
  String get logTypeIllness => 'Ауру';

  @override
  String get logTypeFeeding => 'Тамақтандыру';

  @override
  String get logTypeNappy => 'Жаялық';

  @override
  String get logTypeSleep => 'Ұйқы';

  @override
  String get logTypeQuestion => 'Дәрігерге сұрақ';

  @override
  String get logTypeNote => 'Жазба';

  @override
  String get feedingLeft => 'Сол жақ';

  @override
  String get feedingRight => 'Оң жақ';

  @override
  String get feedingBottle => 'Бөтелке';

  @override
  String get nappyWet => 'Дымқыл';

  @override
  String get nappyDirty => 'Нәжіс';

  @override
  String get nappyBoth => 'Дымқыл және нәжіс';

  @override
  String get severityMild => 'Жеңіл';

  @override
  String get severityModerate => 'Орташа';

  @override
  String get severitySevere => 'Ауыр';

  @override
  String get genderMale => 'Ұл';

  @override
  String get genderFemale => 'Қыз';

  @override
  String get unitsMetric => 'Метрлік (см, кг)';

  @override
  String get unitsImperial => 'Империялық (in, lb)';

  @override
  String nightWakingsCount(int n) {
    return 'оянғаны: $n';
  }

  @override
  String nightFeedsCount(int n) {
    return 'тамақтандыруы: $n';
  }

  @override
  String ageYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n жас',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ай',
    );
    return '$_temp0';
  }

  @override
  String entriesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n жазба',
    );
    return '$_temp0';
  }

  @override
  String monthsShort(int n) {
    return '$n ай';
  }

  @override
  String get dashLayoutTitle => 'Негізгі экран блоктары';

  @override
  String get dashAllHidden => 'Барлық блок жасырылған';

  @override
  String get dashAllHiddenHint => 'Оларды баптаулардан қайтаруға болады';

  @override
  String get dashConfigure => 'Негізгі экранды баптау';

  @override
  String get dashNoneSelected => 'Бірде-бір блок таңдалмаған';

  @override
  String get dashHiddenBlocks => 'Жасырылған блоктар';

  @override
  String get dashReset => 'Әдепкі жинақты қайтару';

  @override
  String get widgetNow => 'Қазір';

  @override
  String get widgetSummary => 'Бала туралы жинақ';

  @override
  String get widgetGrowth => 'Бой мен салмақ';

  @override
  String get widgetVaccinations => 'Жақындағы егулер';

  @override
  String get widgetIllness => 'Аурушаңдық';

  @override
  String get widgetMilestones => 'Даму кезеңдері';

  @override
  String get widgetRecent => 'Соңғы жазбалар';

  @override
  String get widgetUpcoming => 'Жақындағы оқиғалар';

  @override
  String get summaryAge => 'жасы';

  @override
  String get summaryBirthDate => 'туған күні';

  @override
  String get summaryMilestonesCount => 'даму кезеңі';

  @override
  String get summaryEntriesCount => 'барлық жазба';

  @override
  String get growthNoMeasurements => 'Әзірге өлшем жоқ';

  @override
  String get growthWeight => 'Салмағы';

  @override
  String get growthHeight => 'Бойы';

  @override
  String get growthLastMeasurement => 'соңғы өлшем';

  @override
  String growthPercentileWith(String label, int p) {
    return '$label · $p-персентиль';
  }

  @override
  String get vaccinationsNone => 'Алдағы егулер жоқ';

  @override
  String get illnessDaysTotal => 'барлық ауру күні';

  @override
  String get illnessLast3Months => 'соңғы 3 айда';

  @override
  String get milestonesEmpty => 'Алғашқылары әлі алда';

  @override
  String get milestonesEmptyHint =>
      'Алғашқы күлкі, алғашқы тіс, алғашқы сөз — оларды күнделікке «Даму кезеңі» ретінде қосыңыз';

  @override
  String get recentEmpty => 'Әзірге жазба жоқ';

  @override
  String get upcomingEmptyHint =>
      'Бала профилі жасалған соң егулер осында өзі пайда болады';

  @override
  String get greetingNight => 'Қайырлы түн';

  @override
  String get greetingMorning => 'Қайырлы таң';

  @override
  String get greetingAfternoon => 'Қайырлы күн';

  @override
  String get greetingEvening => 'Қайырлы кеш';

  @override
  String get statusSick => 'Науқас';

  @override
  String get statusHealthy => 'Сау';

  @override
  String get statusLatest => 'соңғы';

  @override
  String nowTodayReminder(String title) {
    return 'Бүгін: $title';
  }

  @override
  String get nowNoEntries =>
      'Бүгін әзірге жазба жоқ. Төмендегі түймелер уақытты өзі белгілейді.';

  @override
  String nowSinceFeeding(String duration) {
    return 'Соңғы тамақтандырудан — $duration';
  }

  @override
  String get countFeedings => 'тамақтандыру';

  @override
  String get countWet => 'дымқыл';

  @override
  String get countDirty => 'нәжіс';

  @override
  String get countSleep => 'ұйқы';

  @override
  String get nightAsleepDate => 'Ұйықтады, күні';

  @override
  String get nightAwakeDate => 'Оянды, күні';

  @override
  String get nightWokeUp => 'Оянған саны';

  @override
  String get nightOfThoseFeeds => 'Оның ішінде тамақтандыру';

  @override
  String nightTotal(String duration) {
    return 'Барлық ұйқы: $duration';
  }

  @override
  String get nightInvalid => 'Ояну уақыты ұйықтағаннан кейін болуы керек';

  @override
  String get errorIndexBuilding =>
      'Дерекқор индекстерін құруда. Бұл алғашқы орналастырудан кейін бірнеше минут алады — бетті сәлден соң жаңартыңыз.';

  @override
  String get errorPermission =>
      'Бұл деректерге қолжетімділік жоқ. Шығып, қайта кіріп көріңіз.';

  @override
  String get errorOffline =>
      'Сервермен байланыс жоқ. Өзгерістер құрылғыда сақталып, байланыс оралғанда синхрондалады.';

  @override
  String get errorSession => 'Сессия аяқталды. Тіркелгіге қайта кіріңіз.';

  @override
  String get errorGeneric =>
      'Деректерді жүктеу мүмкін болмады. Бетті жаңартып көріңіз.';

  @override
  String get noChildTitle => 'Танысып алайық';

  @override
  String get noChildHint =>
      'Бөбегіңіз туралы айтыңыз — қосымша оның жасына бейімделіп, егу күнтізбесін өзі құрады';

  @override
  String get addChild => 'Бала қосу';

  @override
  String get diaryFeed => 'Оқиғалар лентасы';

  @override
  String get diaryEmpty => 'Мұнда бөбектің тарихы болады';

  @override
  String get diaryEmptyHint =>
      'Тамақтандыру мен жаялық негізгі экрандағы түймелермен белгіленеді, ал алғашқы сөз бен алғашқы тіс — осында';

  @override
  String get diaryAddEntry => 'Жазба қосу';

  @override
  String get diaryDeleteTitle => 'Жазбаны жою керек пе?';

  @override
  String diaryDeleteBody(String title) {
    return '«$title» жазбасы жойылады. Бұл әрекетті кері қайтару мүмкін емес.';
  }

  @override
  String get diaryPhotos => 'Фотосуреттер';

  @override
  String get diaryNewEntry => 'Жаңа жазба';

  @override
  String get diaryEditEntry => 'Жазбаны өзгерту';

  @override
  String get diaryType => 'Жазба түрі';

  @override
  String get diaryTitleField => 'Тақырыбы';

  @override
  String get diaryTitleRequired => 'Тақырыбын енгізіңіз';

  @override
  String get diaryDescription => 'Сипаттамасы';

  @override
  String get diaryTags => 'Тегтер, үтір арқылы';

  @override
  String get diaryTagsHint => 'моторика, сөйлеу';

  @override
  String fieldWeight(String unit) {
    return 'Салмағы, $unit';
  }

  @override
  String fieldHeight(String unit) {
    return 'Бойы, $unit';
  }

  @override
  String fieldHead(String unit) {
    return 'Бас шеңбері, $unit';
  }

  @override
  String fieldChest(String unit) {
    return 'Кеуде шеңбері, $unit';
  }

  @override
  String get fieldTemperature => 'Дене қызуы, °C';

  @override
  String get fieldSeverity => 'Ауырлығы';

  @override
  String pillHead(String value) {
    return 'бас $value';
  }

  @override
  String pillChest(String value) {
    return 'кеуде $value';
  }

  @override
  String photoUploadFailed(String error) {
    return 'Фотоны жүктеу мүмкін болмады: $error';
  }

  @override
  String get childrenTitle => 'Бала профильдері';

  @override
  String get childrenEmpty => 'Әзірге бірде-бір профиль жоқ';

  @override
  String get childrenEmptyHint => 'Бастау үшін «Бала қосу» түймесін басыңыз';

  @override
  String get childDeleteTitle => 'Профильді жою керек пе?';

  @override
  String childDeleteBody(String name) {
    return '«$name» профилі күнделіктегі барлық жазбамен, өлшемдермен, медициналық жазбалармен және еске салулармен бірге жойылады. Бұл әрекетті кері қайтару мүмкін емес.';
  }

  @override
  String get childSelected => 'Таңдалды';

  @override
  String get childProfileEdit => 'Бала профилі';

  @override
  String get childProfileNew => 'Жаңа профиль';

  @override
  String get childName => 'Аты';

  @override
  String get childNameRequired => 'Атын енгізіңіз';

  @override
  String get childBirthDate => 'Туған күні';

  @override
  String get childPickDate => 'Күнді таңдаңыз';

  @override
  String get childBirthDateRequired => 'Туған күнін енгізіңіз';

  @override
  String get photoAdd => 'Фото қосу';

  @override
  String get photoRemove => 'Фотоны алып тастау';

  @override
  String photoSaveFailed(String error) {
    return 'Фотоны сақтау мүмкін болмады: $error';
  }

  @override
  String get quickNoteOptional => 'Ескертпе (міндетті емес)';

  @override
  String get quickAssistant => 'Көмекші';

  @override
  String get quickNightSleep => 'Түнгі ұйқы';

  @override
  String get digestTitle => 'Бүгін';

  @override
  String get digestSubtitle => 'Күн туралы қысқаша';

  @override
  String get digestFeedings => 'Тамақтандыру';

  @override
  String get digestSleep => 'Күндізгі ұйқы';

  @override
  String get digestNappies => 'Жаялық';

  @override
  String get digestTemperature => 'Дене қызуы';

  @override
  String get digestPhotos => 'Жаңа фото';

  @override
  String get digestEmpty => 'Бүгін әзірге жазба жоқ';

  @override
  String get digestCalm => 'Бүгін тыныш күн болды.';

  @override
  String get digestBusy => 'Бүгін қарбалас күн болды.';

  @override
  String get digestHardNight => 'Түн сәл қиын өтті.';

  @override
  String get momentsTitle => 'Күннің сәттері';

  @override
  String get momentsLineOne => 'Бүгінгі күннің кішкентай сәті';

  @override
  String get momentsLineTwo => 'Бүгін жаңа күлкі болды';

  @override
  String get momentsLineMany => 'Сақтауға тұрарлық естелік';

  @override
  String get storyTitleCare => 'Қамқорлық аптасы';

  @override
  String get storyTitleGrowing => 'Бірге өсіп келеміз';

  @override
  String get storyTitleMoments => 'Кішкентай сәттер, үлкен махаббат';

  @override
  String get storyFeedings => 'Тамақтандыру';

  @override
  String get storySleep => 'Апталық ұйқы';

  @override
  String get storyNappies => 'Жаялық';

  @override
  String get storyBestNight => 'Ең жақсы түн';

  @override
  String get storyExport => 'PDF сақтау';

  @override
  String get storyPdfReady => 'Апта парағы дайын';

  @override
  String get appreciationHeavyDay =>
      'Бүгін оңай күн болмады. Сіз бала үшін өте көп нәрсе жасадыңыз.';

  @override
  String get appreciationThanks => 'Әке бүгінгі күн үшін сізге алғыс айтты ❤️';

  @override
  String get appreciationThankButton => 'Бүгінгі күн үшін рақмет';

  @override
  String get appreciationThankSent => 'Алғыс жіберілді';

  @override
  String get voiceQuickHint => 'Дауыспен жазу';

  @override
  String get voiceHoldHint => 'Түймені басып тұрып сөйлеңіз';

  @override
  String get voiceExample => '«сол көкірекпен 15 минут еміздім»';

  @override
  String get voiceHeard => 'Естілді';

  @override
  String get voiceMl => 'мл';

  @override
  String get voiceAsNote => 'Ескертпе ретінде сақталады';

  @override
  String get homeRecent => 'Соңғы оқиғалар';

  @override
  String get homeNothingYet => 'Әзірге ештеңе жазылмаған';

  @override
  String get homeMore => 'Қалғанының бәрі «Көмекші» бетінде';

  @override
  String get assistantInsights => 'Бақылаулар мен есептер';

  @override
  String get familyTitle => 'Отбасы';

  @override
  String get familySubtitle => 'Бала профилін тағы кім көреді';

  @override
  String get familyInvite => 'Шақыру';

  @override
  String get familyInviteEmail => 'Электрондық пошта';

  @override
  String get familyInviteHint => 'Ол кіретін мекенжай';

  @override
  String get familyInviteSent => 'Шақыру жіберілді';

  @override
  String get familyEmailInvalid => 'Мекенжайды тексеріңіз';

  @override
  String get familyPending => 'Растауды күтуде';

  @override
  String get familyAccepted => 'Қолжетімділік бар';

  @override
  String get familyNobody => 'Әзірге тек сіз';

  @override
  String get familyRemove => 'Қолжетімділікті алып тастау';

  @override
  String get familyRoleOwner => 'Анасы';

  @override
  String get familyRoleViewer => 'Әкесі';

  @override
  String get familyReadOnly => 'Тек қарау режимі';

  @override
  String get familyReadOnlyHint =>
      'Профильді көресіз, бірақ жазбаларды өзгертпейсіз';

  @override
  String get familyInviteBanner => 'Сізді бала профиліне шақырды';

  @override
  String get familyAccept => 'Қабылдау';

  @override
  String get familyLater => 'Кейінірек';

  @override
  String get familyAcceptedToast => 'Енді профильді көресіз';

  @override
  String get familyOwnerOnly => 'Мұны тек профиль иесі өзгерте алады';

  @override
  String get familyAlreadyMember => 'Бұл мекенжайда қолжетімділік бар';

  @override
  String get familySelfInvite => 'Бұл сіздің өз мекенжайыңыз';

  @override
  String get voiceListening => 'Тыңдап тұрмын…';

  @override
  String get voiceSpeakNow => 'Сөйлей беріңіз';

  @override
  String get voiceFailed => 'Сөйлеуді тану мүмкін болмады';

  @override
  String get voiceUnavailable => 'Микрофон қолжетімсіз — жазбаны теруге болады';

  @override
  String get voiceDictate => 'Жазбаны айтып жаздыру';

  @override
  String get voiceStop => 'Жазуды тоқтату';

  @override
  String get quickFeedHint => 'омырау не бөтелке';

  @override
  String get quickNappyHint => 'дымқыл не нәжіс';

  @override
  String get quickSleepHint => 'күндізгі демалыс';

  @override
  String get quickNightSleepHint => 'оянуларымен';

  @override
  String get quickTemperatureHint => 'бір өлшем';

  @override
  String get quickAssistantHint => 'бала туралы сұрау';

  @override
  String get phraseOfDay1 => 'Сіз жеткілікті нәрсе жасап жатырсыз.';

  @override
  String get phraseOfDay2 => 'Бүгін баяуырақ болуға болады.';

  @override
  String get phraseOfDay3 => 'Бала сіздің қамқорлығыңызды сезеді.';

  @override
  String get phraseOfDay4 => 'Демалу да — қамқорлық.';

  @override
  String get phraseOfDay5 => 'Күн сайын сәл жеңілдейді.';

  @override
  String get phraseOfDay6 => 'Сіз жанындасыз, осы жеткілікті.';

  @override
  String get quickFever => 'Бұл — қызба. Күн ауру күні деп белгіленеді.';

  @override
  String get quickFeverAction => 'Не істеу керек';

  @override
  String get growthChartTitle => 'Көрсеткіштер динамикасы';

  @override
  String get growthAddMeasurement => 'Өлшем қосу';

  @override
  String get growthEmpty => 'Графикте әзірге көрсететін дерек жоқ';

  @override
  String get growthEmptyHint =>
      'Күнделікке бой мен салмақты қосыңыз — қисық алғашқы өлшемнен кейін пайда болады, ал ДДҰ нормалары дайын тұр';

  @override
  String get growthAxisAge => 'жасы, ай';

  @override
  String get growthWhoMedian => 'ДДҰ медианасы';

  @override
  String get growthWhoBand => '±2 SD дәлізі';

  @override
  String get growthWhoLimit =>
      'ДДҰ нормалары 5 жасқа дейін анықталған, сондықтан анықтамалық қисықтар 60 айда аяқталады.';

  @override
  String get growthWhoAssessment => 'ДДҰ нормалары бойынша баға';

  @override
  String get growthAgeOutOfRange =>
      'Жас анықтамалық кестелер ауқымынан тыс (0–60 ай)';

  @override
  String growthPercentileOrdinal(int p) {
    return '$p-';
  }

  @override
  String get growthPercentileWord => 'персентиль';

  @override
  String get growthZScore => 'z-баға';

  @override
  String get growthDisclaimer =>
      'Есеп 0–5 жастағы балаларға арналған ДДҰ нормалары бойынша жүргізіледі. Персентиль құрбыларының арасындағы орнын көрсетеді, диагноз емес: ауытқу нақты баланың ерекшелігі де болуы мүмкін. Бағаны дәрігер береді.';

  @override
  String get growthHistory => 'Өлшемдер тарихы';

  @override
  String get illnessTitle => 'Аурушаңдық статистикасы';

  @override
  String illnessHeatmap(int months) {
    return '$months айдағы жылу картасы';
  }

  @override
  String get illnessEpisodes => 'Ауру эпизодтары';

  @override
  String get illnessEmpty => 'Ауру туралы жазба жоқ';

  @override
  String get illnessEmptyHint => 'Ауру күнін күнделікте белгілеуге болады';

  @override
  String get illnessEpisodesCount => 'эпизод';

  @override
  String get illnessDays12 => '12 айдағы күн';

  @override
  String get illnessDays3 => '3 айдағы күн';

  @override
  String get illnessWell => 'сау';

  @override
  String illnessDayWell(String date) {
    return '$date — сау';
  }

  @override
  String remindersActiveCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n белсенді еске салу',
    );
    return '$_temp0';
  }

  @override
  String remindersOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n күнге кешіккен',
    );
    return '$_temp0';
  }

  @override
  String remindersInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n күннен кейін',
    );
    return '$_temp0';
  }

  @override
  String get medicalTitle => 'Медициналық жазбалар';

  @override
  String get medicalEmpty => 'Әзірге медициналық жазба жоқ';

  @override
  String get medicalEmptyHint =>
      'Дәрігерге барғаныңызды не талдау нәтижелерін қосыңыз';

  @override
  String get medicalDeleteTitle => 'Жазбаны жою керек пе?';

  @override
  String medicalDeleteBody(String diagnosis, String date) {
    return '$date күнгі «$diagnosis» жазбасы талдау нәтижелерімен бірге жойылады. Бұл әрекетті кері қайтару мүмкін емес.';
  }

  @override
  String get medicalAskDoctor => 'Дәрігерден сұрау';

  @override
  String get medicalWriteDown => 'Жазып қою';

  @override
  String get medicalQuestionsHint =>
      'Сұрағыңыз келген нәрсенің бәрін осында жазыңыз. Тізім дәрігерге арналған есепке кіреді — кабинетте есіңізге түсірудің қажеті болмайды.';

  @override
  String get medicalAsked => 'Сұрадым';

  @override
  String get medicalQuestionHint =>
      'Мысалы: әр тамақтандырудан кейін құсуы қалыпты ма';

  @override
  String get medicalReport => 'Дәрігерге арналған есеп';

  @override
  String get medicalReportHint =>
      'Бір парақтағы жинақ: ДДҰ нормалары бойынша бағаланған өлшемдер, ауру статистикасы, ауытқулары бар талдаулар, вакцинация мәртебесі және даму кезеңдері.';

  @override
  String get medicalReportBuilding => 'Дайындалуда…';

  @override
  String get medicalReportDownload => 'PDF жүктеу';

  @override
  String medicalReportFailed(String error) {
    return 'Есепті құру мүмкін болмады: $error';
  }

  @override
  String get medicalPrescriptions => 'Тағайындаулар';

  @override
  String get medicalLabResults => 'Талдау нәтижелері';

  @override
  String medicalOutOfRange(int n) {
    return '$n нормадан тыс';
  }

  @override
  String get medicalScans => 'Бланк сканерлері';

  @override
  String get medicalIndicator => 'Көрсеткіш';

  @override
  String get medicalValue => 'Мәні';

  @override
  String get medicalReference => 'Норма';

  @override
  String get medicalRecordTitle => 'Медициналық жазба';

  @override
  String get medicalDiagnosis => 'Диагноз немесе бару себебі';

  @override
  String get medicalDiagnosisRequired => 'Диагнозды не бару себебін енгізіңіз';

  @override
  String get medicalDoctor => 'Дәрігер мен мекеме';

  @override
  String get medicalDoctorHint => 'Педиатр, №2 емхана';

  @override
  String get medicalLabs => 'Талдаулар';

  @override
  String get medicalAddRow => 'Жол қосу';

  @override
  String get medicalReferenceHint =>
      'Референстік мәндер міндетті емес, бірақ оларсыз қосымша ауытқуды белгілей алмайды.';

  @override
  String get medicalScan => 'Бланк сканері';

  @override
  String medicalUploadFailed(String error) {
    return 'Жүктеу мүмкін болмады: $error';
  }

  @override
  String medicalRowInvalid(String name) {
    return '«$name» жолын тексеріңіз: атауы мен сандық мәні керек.';
  }

  @override
  String get medicalUnitShort => 'Бірл.';

  @override
  String get medicalFrom => 'бастап';

  @override
  String get medicalTo => 'дейін';

  @override
  String get medicalRemoveRow => 'Жолды алып тастау';

  @override
  String get medicalAttach => 'Тіркеу';

  @override
  String get assistantSearchHint =>
      'Дене қызуы, бөртпе, ұйықтамайды, қосымша тамақ…';

  @override
  String get assistantNothingFound => 'Ештеңе табылмады';

  @override
  String assistantNoArticle(String query) {
    return '«$query» сұрауы бойынша базада әзірге мақала жоқ';
  }

  @override
  String get assistantTryAnother =>
      'Басқа сөзді байқап көріңіз — мысалы, «дене қызуы» немесе «бөртпе»';

  @override
  String get assistantFound => 'Табылды';

  @override
  String assistantArticlesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n мақала',
    );
    return '$_temp0';
  }

  @override
  String get assistantTriage => 'Қауіпті белгілерді тексеру';

  @override
  String get assistantTriageHint =>
      'Бірнеше сұрақ — сосын күту керек пе, әлде 103-ке қоңырау шалу керек пе, белгілі болады';

  @override
  String get assistantChat => 'Өз сөзіңізбен сұрау';

  @override
  String get assistantChatHint =>
      'Қосымшаның өз базасы бойынша жауап, мақалаларға сілтемелермен';

  @override
  String get assistantChatOff =>
      'ЖИ әзірге қосылмаған — қалай қосуды көру үшін ашыңыз';

  @override
  String get assistantRelevant => 'Қазір өзекті';

  @override
  String assistantChildAge(String name, int months) {
    return '$name, $months ай';
  }

  @override
  String get assistantAllTopics => 'Барлық тақырыптар';

  @override
  String get assistantDisclaimer =>
      'Материалдар ДДҰ, NICE және Америка педиатрия академиясының ұсынымдарына негізделген. Бұл — ата-аналарға арналған анықтамалық ақпарат, тексеруді алмастырмайды. Соңғы шешім әрқашан дәрігерде.';

  @override
  String get chatTitle => 'Көмекшіден сұрау';

  @override
  String get chatEmpty => 'Бала денсаулығы туралы бірдеңе сұраңыз';

  @override
  String chatHint(String name) {
    return '$name туралы сұраңыз: ұйқы, тамақ, дене қызуы…';
  }

  @override
  String get chatSend => 'Жіберу';

  @override
  String get chatDisclaimer =>
      'Көмекші тек қосымшаның тексерілген базасы бойынша жауап береді және диагноз қоймайды. Шешім әрқашан дәрігерде.';

  @override
  String get chatEmergency => 'Жедел жәрдем шақырыңыз — 103';

  @override
  String get chatEmergencyBody =>
      'Сұрағыңызда күтуге болмайтын белгі бар. Мұндай сұрақтар әдейі ЖИ-ге жіберілмейді — мұнда кеңес емес, дереу көмек керек.';

  @override
  String get chatWhatToDo => 'Жедел жәрдем келгенше не істеу керек';

  @override
  String get chatSources => 'Жауап мына мақалалар бойынша құрылған:';

  @override
  String get chatOpenKb => 'Білім базасын ашу';

  @override
  String get chatAiOff => 'ЖИ-көмекші әзірге қосылмаған';

  @override
  String get chatAiOffBody =>
      'Білім базасы мен қауіпті белгілерді тексеру онсыз да жұмыс істейді — оларға интернет мүлдем қажет емес.';

  @override
  String get chatAiOffHow =>
      'ЖИ-ді қосу үшін Cloudflare Workers-те тегін проксиді орналастырып, қосымшаны оның мекенжайымен қайта жинау керек. Нұсқаулық — worker/README.md файлында.';

  @override
  String get chatSuggestionsTitle => 'Ең жиі не сұрайды';

  @override
  String get chatSuggestion1 => 'Дене қызуы 38.5, не істеу керек';

  @override
  String get chatSuggestion2 => 'Алты айлық бала қанша ұйықтауы керек';

  @override
  String get chatSuggestion3 => 'Қосымша тамақты қашан бастау керек';

  @override
  String get chatSuggestion4 => 'Емізу кезінде антибиотик ішуге бола ма';

  @override
  String get chatSuggestion5 => 'Бала екі күн дәреті келмеді';

  @override
  String get triageTitle => 'Қауіпті белгілерді тексеру';

  @override
  String get triageNeedChild => 'Бала профилі қажет';

  @override
  String get triageNeedChildHint =>
      'Жас бағаға әсер етеді — әсіресе 3 айға дейін';

  @override
  String get triageNeedChildAction => '«Балалар» бөлімінде профиль жасаңыз';

  @override
  String get triageTemperatureHint =>
      'Өлшеген болсаңыз енгізіңіз — мысалы, 38.5';

  @override
  String get triageCheckAll => 'Барын белгілеңіз';

  @override
  String get triageEvaluate => 'Жағдайды бағалау';

  @override
  String get triageRestart => 'Қайта бастау';

  @override
  String get triageConsidered => 'Не ескерілді:';

  @override
  String get triageDisclaimer =>
      'Бұл диагноз емес. Баға формальды белгілер бойынша құрылған және тексеруді алмастырмайды. Егер сіз алаңдасаңыз, ал тексеру «үйде бақылау» деп көрсетсе — бәрібір дәрігерге барыңыз.';

  @override
  String get articleNotFound => 'Мақала табылмады';

  @override
  String get articleNotFoundBody => 'Мұндай мақала базада жоқ';

  @override
  String get articleToList => 'Тақырыптар тізіміне';

  @override
  String get articleEmergency => 'Жедел жәрдем — 103';

  @override
  String get articleWhatToDo => 'Қазір не істеу керек';

  @override
  String get articleWhenDoctor => 'Дәрігерге қашан бару керек';

  @override
  String get articleSources => 'Дереккөздер';

  @override
  String get articleDisclaimer =>
      'Бұл — анықтамалық ақпарат, диагноз да, тағайындау да емес. Бірдеңе алаңдатса — педиатрға барыңыз. Қауіпті белгілер болса, 103-ке қоңырау шалыңыз.';

  @override
  String get settingsParent => 'Ата-ана';

  @override
  String get settingsYourName => 'Атыңыз';

  @override
  String get settingsUnits => 'Өлшем бірліктері';

  @override
  String get settingsUnitsHint =>
      'Өлшемдер әрқашан метрлік бірліктерде сақталып, тек көрсету үшін қайта есептеледі — сондықтан ауыстыру енгізілген деректерге зиян тигізбейді.';

  @override
  String get settingsTemperatureHint =>
      'Дене қызуы екі жүйеде де °C күйінде қалады: қосымшадағы және ұсынымдардағы барлық шектер Цельсий бойынша берілген.';

  @override
  String get settingsAppearance => 'Безендіру';

  @override
  String get settingsDeleteSection => 'Тіркелгіні жою';

  @override
  String get settingsDeleteWarning =>
      'Тіркелгімен бірге барлық бала, күнделік, медкарта және еске салулар біржола жойылады. Мұны кері қайтару мүмкін емес, сондықтан қажет болса алдымен PDF есепті жүктеп алыңыз.';

  @override
  String get settingsChangeButton => 'Ауыстыру';

  @override
  String get growthVerdictSeverelyLow => 'Нормадан едәуір төмен';

  @override
  String get growthVerdictLow => 'Нормадан төмен';

  @override
  String get growthVerdictNormal => 'Норма шегінде';

  @override
  String get growthVerdictHigh => 'Нормадан жоғары';

  @override
  String get growthVerdictSeverelyHigh => 'Нормадан едәуір жоғары';

  @override
  String growthMetricWithDate(String metric, String date) {
    return '$metric, $date';
  }

  @override
  String get medicalAdd => 'Жазба қосу';

  @override
  String get photoNotAnImage =>
      'Суретті оқу мүмкін болмады. JPG, PNG және WebP қолдау табады.';

  @override
  String get photoStillTooLarge =>
      'Сурет сығылғаннан кейін де тым үлкен. Жақынырақ түсіріп көріңіз немесе қиып алыңыз.';

  @override
  String get nowLastFeeding => 'Соңғы тамақтандыру';

  @override
  String get nowLastSleep => 'Соңғы ұйқы';

  @override
  String get nowNothingYet => 'әзірге жоқ';

  @override
  String nowAgo(String duration) {
    return '$duration бұрын';
  }

  @override
  String get suggestionAfterSleep => 'Ұйқыдан кейін жиі тамақтандыру болады';

  @override
  String get suggestionNappy => 'Жөргек біраз уақыт белгіленбеген';

  @override
  String get suggestionDismiss => 'Жасыру';

  @override
  String get reflectionTitle => 'Бүгін';

  @override
  String reflectionSummary(int feedings, String sleep) {
    return 'Бүгін $feedings рет тамақтандыру және $sleep ұйқы тіркелді. Бұл күннің жалпы көрінісін қолмен есептемей көруге көмектеседі.';
  }

  @override
  String get reflectionSupport =>
      'Сіз күннің барлық маңызды оқиғаларын жаздыңыз. Бұл өзіңізге де, балаңызға да үлкен көмек.';

  @override
  String get reflectionNappies => 'жаялық';

  @override
  String get patternSleepThenFeeding =>
      'Күндізгі ұйқыдан кейін тамақтандыру көбіне 20–40 минуттан соң болады.';

  @override
  String patternNightStart(String time) {
    return 'Түнгі ұйқы көбіне $time шамасында басталады.';
  }

  @override
  String get patternStableSleep =>
      'Соңғы күндері жалпы ұйқы шамамен бірдей болып тұр.';

  @override
  String get contextTitle => 'Бала туралы контекст';

  @override
  String get contextNotRecorded => 'Белгіленбеген';

  @override
  String get chatContinueTitle => 'Әңгімені жалғастыру';

  @override
  String chatContinueLast(String question) {
    return 'Соңғы сұрақ: «$question»';
  }

  @override
  String get chatContinueResume => 'Жалғастыру';

  @override
  String get chatContinueNew => 'Жаңа';

  @override
  String get checkInTitle => 'Өзіңізді қалай сезінесіз?';

  @override
  String get checkInHoldingUp => 'Шыдап тұрмын';

  @override
  String get checkInTired => 'Шаршадым';

  @override
  String get checkInVeryHard => 'Өте ауыр';

  @override
  String get checkInReplyHoldingUp =>
      'Бүгін өзіңіз үшін кем дегенде бір тыныш сәт табылсын.';

  @override
  String get checkInReplyTired =>
      'Қиын түннен кейін шаршау — түсінікті жағдай. Мінсіз тәртіпке емес, ең маңыздысына сүйенуге тырысыңыз.';

  @override
  String get checkInReplyVeryHard =>
      'Мүмкіндік болса, біреуден аз уақытқа болса да жаныңызда болуын сұраңыз. Өзіңізге қамқор болу — балаға қамқорлықтың да бір бөлігі.';

  @override
  String get vaccineHepB1 => 'В гепатиті (ВГВ) — бірінші доза';

  @override
  String get vaccineNoteHepB1 => 'Өмірінің алғашқы тәулігінде';

  @override
  String get vaccineBcg => 'Туберкулёз (БЦЖ)';

  @override
  String get vaccineNoteBcg => 'Өмірінің 1–4 тәулігінде';

  @override
  String get vaccinePenta1 =>
      'Пентавакцина: АбЖКД + Хиб + ВГВ + ИПВ — бірінші доза';

  @override
  String get vaccineNotePenta1 =>
      'Көкжөтел, дифтерия, сіреспе, гемофильді инфекция, В гепатиті, полиомиелит';

  @override
  String get vaccinePcv1 => 'Пневмококк инфекциясы (ПНВ) — бірінші доза';

  @override
  String get vaccinePenta2 => 'АбЖКД + Хиб + ИПВ — екінші доза';

  @override
  String get vaccinePenta3 =>
      'Пентавакцина: АбЖКД + Хиб + ВГВ + ИПВ — үшінші доза';

  @override
  String get vaccinePcv2 => 'Пневмококк инфекциясы (ПНВ) — екінші доза';

  @override
  String get vaccineMmr1 => 'Қызылша, қызамық, паротит (ҚҚП) — бірінші доза';

  @override
  String get vaccineNoteMmr1 => '12–15 айда';

  @override
  String get vaccinePcvBooster => 'Пневмококк инфекциясы (ПНВ) — қайта екпе';

  @override
  String get vaccineOpv => 'Полиомиелит (ОПВ)';

  @override
  String get vaccinePentaBooster => 'АбЖКД + Хиб + ИПВ — қайта екпе';

  @override
  String get vaccineNotePentaBooster => '18 айда';

  @override
  String get vaccineHepA1 => 'А гепатиті (ВГА) — бірінші доза';

  @override
  String get vaccineNoteHepA1 => '2 жаста';

  @override
  String get vaccineHepA2 => 'А гепатиті (ВГА) — екінші доза';

  @override
  String get vaccineNoteHepA2 => '6 айдан кейін';

  @override
  String get vaccineDtapBooster => 'АбЖКД — қайта екпе';

  @override
  String get vaccineNoteDtapBooster => '6 жаста, мектепке дейін';

  @override
  String get vaccineMmr2 => 'Қызылша, қызамық, паротит (ҚҚП) — екінші доза';

  @override
  String get vaccineHpv1 => 'АПВ — бірінші доза (қыздар)';

  @override
  String get vaccineNoteHpv1 => '11 жаста, ата-ананың келісімімен';

  @override
  String get vaccineHpv2 => 'АПВ — екінші доза (қыздар)';

  @override
  String get vaccineNoteHpv2 => '6 айдан кейін';

  @override
  String get vaccineTdBooster => 'АДС-М — қайта екпе';

  @override
  String get vaccineNoteTdBooster => '16 жаста, содан кейін әр 10 жыл сайын';

  @override
  String get vaccineSource => 'ҚР екпе күнтізбесі';

  @override
  String get reportExport => 'PDF экспорттау';

  @override
  String reportPeriodDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n күн',
    );
    return '$_temp0';
  }

  @override
  String get reportPeriod => 'Есеп кезеңі';

  @override
  String reportRange(String from, String to) {
    return '$from — $to';
  }

  @override
  String get reportTitle => 'Дәрігерге арналған есеп';

  @override
  String get reportNothing => 'Бұл кезеңде жазба жоқ';

  @override
  String get reportPreparing => 'PDF дайындалуда…';

  @override
  String get reportReady => 'Есеп дайын';

  @override
  String get reportShareFailed => 'Есепті ашу мүмкін болмады';

  @override
  String get reportSectionSleep => 'Ұйқы';

  @override
  String get reportAvgNight => 'Орташа түнгі ұйқы';

  @override
  String get reportAvgDay => 'Орташа күндізгі ұйқы';

  @override
  String get reportAvgWakings => 'Орташа ояну саны';

  @override
  String get reportSectionFeeding => 'Тамақтандыру';

  @override
  String get reportFeedingsTotal => 'Барлық тамақтандыру';

  @override
  String get reportBreast => 'Емшек';

  @override
  String get reportBottle => 'Бөтелке';

  @override
  String get reportSectionNappies => 'Жаялықтар';

  @override
  String get reportSectionTemperature => 'Дене қызуы';

  @override
  String get reportTempMax => 'Ең жоғары';

  @override
  String get reportTempMin => 'Ең төмен';

  @override
  String get reportTempCount => 'Өлшеу саны';

  @override
  String get reportSectionMedicines => 'Дәрілер';

  @override
  String get reportSectionNotes => 'Ескертпелер';

  @override
  String get reportDisclaimer =>
      'Бұл есеп дәрігермен талқылауды жеңілдету үшін арналған және медициналық қорытынды болып табылмайды.';

  @override
  String reportPage(int page, int total) {
    return '$page-бет, барлығы $total';
  }
}
