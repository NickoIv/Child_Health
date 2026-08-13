import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Календарь развития и здоровья ребёнка'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get navDashboard;

  /// No description provided for @navAssistant.
  ///
  /// In ru, this message translates to:
  /// **'Помощник'**
  String get navAssistant;

  /// No description provided for @navDiary.
  ///
  /// In ru, this message translates to:
  /// **'Дневник'**
  String get navDiary;

  /// No description provided for @navGrowth.
  ///
  /// In ru, this message translates to:
  /// **'Развитие'**
  String get navGrowth;

  /// No description provided for @navIllness.
  ///
  /// In ru, this message translates to:
  /// **'Болезни'**
  String get navIllness;

  /// No description provided for @navMedical.
  ///
  /// In ru, this message translates to:
  /// **'Медкарта'**
  String get navMedical;

  /// No description provided for @navReminders.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания'**
  String get navReminders;

  /// No description provided for @navChildren.
  ///
  /// In ru, this message translates to:
  /// **'Дети'**
  String get navChildren;

  /// No description provided for @navFamily.
  ///
  /// In ru, this message translates to:
  /// **'Семья'**
  String get navFamily;

  /// No description provided for @navMore.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get navMore;

  /// No description provided for @navAsk.
  ///
  /// In ru, this message translates to:
  /// **'ИИ'**
  String get navAsk;

  /// No description provided for @navPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get navPhotos;

  /// No description provided for @navGroupHealth.
  ///
  /// In ru, this message translates to:
  /// **'Здоровье'**
  String get navGroupHealth;

  /// No description provided for @navGroupMemory.
  ///
  /// In ru, this message translates to:
  /// **'Память'**
  String get navGroupMemory;

  /// No description provided for @navGroupProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navGroupProfile;

  /// No description provided for @navGrowthHint.
  ///
  /// In ru, this message translates to:
  /// **'Вес, рост и перцентили ВОЗ'**
  String get navGrowthHint;

  /// No description provided for @navIllnessHint.
  ///
  /// In ru, this message translates to:
  /// **'Дни болезни и температура'**
  String get navIllnessHint;

  /// No description provided for @navMedicalHint.
  ///
  /// In ru, this message translates to:
  /// **'Прививки, приёмы, отчёт для врача'**
  String get navMedicalHint;

  /// No description provided for @navVisit.
  ///
  /// In ru, this message translates to:
  /// **'Приём врача'**
  String get navVisit;

  /// No description provided for @navVisitHint.
  ///
  /// In ru, this message translates to:
  /// **'О чём спросить и что взять с собой'**
  String get navVisitHint;

  /// No description provided for @navRemindersHint.
  ///
  /// In ru, this message translates to:
  /// **'Лекарства и календарь прививок'**
  String get navRemindersHint;

  /// No description provided for @navPhotosHint.
  ///
  /// In ru, this message translates to:
  /// **'Альбом и недельная история'**
  String get navPhotosHint;

  /// No description provided for @navChildrenHint.
  ///
  /// In ru, this message translates to:
  /// **'Кто в приложении'**
  String get navChildrenHint;

  /// No description provided for @navSettingsHint.
  ///
  /// In ru, this message translates to:
  /// **'Язык, тема, единицы, доступ'**
  String get navSettingsHint;

  /// No description provided for @photosAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get photosAdd;

  /// No description provided for @photosEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить фото'**
  String get photosEdit;

  /// No description provided for @photosWhen.
  ///
  /// In ru, this message translates to:
  /// **'Когда снято'**
  String get photosWhen;

  /// No description provided for @photosAbout.
  ///
  /// In ru, this message translates to:
  /// **'Что здесь'**
  String get photosAbout;

  /// No description provided for @photosAboutHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, «первый раз сел сам»'**
  String get photosAboutHint;

  /// No description provided for @photosSaved.
  ///
  /// In ru, this message translates to:
  /// **'Фото сохранено'**
  String get photosSaved;

  /// No description provided for @photosDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Фото удалено'**
  String get photosDeleted;

  /// No description provided for @photosEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь будут фотографии малыша'**
  String get photosEmpty;

  /// No description provided for @photosEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Снимки из записей дневника попадут сюда сами, а отдельные можно добавить кнопкой ниже'**
  String get photosEmptyHint;

  /// No description provided for @photosCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} фото} few{{n} фото} many{{n} фото} other{{n} фото}}'**
  String photosCount(int n);

  /// No description provided for @authSignInSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы продолжить'**
  String get authSignInSubtitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Создайте учётную запись родителя'**
  String get authRegisterSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get authSignIn;

  /// No description provided for @authRegister.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get authRegister;

  /// No description provided for @authToRegister.
  ///
  /// In ru, this message translates to:
  /// **'Нет учётной записи — зарегистрироваться'**
  String get authToRegister;

  /// No description provided for @authToSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть учётная запись — войти'**
  String get authToSignIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get authForgotPassword;

  /// No description provided for @authOr.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get authOr;

  /// No description provided for @authWithGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Google'**
  String get authWithGoogle;

  /// No description provided for @authWithApple.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Apple'**
  String get authWithApple;

  /// No description provided for @authEmailRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get authEmailRequired;

  /// No description provided for @authEmailIncomplete.
  ///
  /// In ru, this message translates to:
  /// **'Похоже, адрес неполный'**
  String get authEmailIncomplete;

  /// No description provided for @authPasswordRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get authPasswordTooShort;

  /// No description provided for @authResetNeedsEmail.
  ///
  /// In ru, this message translates to:
  /// **'Введите email, на него придёт ссылка'**
  String get authResetNeedsEmail;

  /// No description provided for @authResetSent.
  ///
  /// In ru, this message translates to:
  /// **'Письмо для сброса пароля отправлено на {email}'**
  String authResetSent(String email);

  /// No description provided for @authUnexpected.
  ///
  /// In ru, this message translates to:
  /// **'Неожиданная ошибка: {error}'**
  String authUnexpected(String error);

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный email или пароль'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный адрес электронной почты'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In ru, this message translates to:
  /// **'Этот email уже зарегистрирован'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль слишком простой — минимум 6 символов'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Учётная запись отключена'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorRequiresRecentLogin.
  ///
  /// In ru, this message translates to:
  /// **'Для этого действия нужно войти заново. Выйдите и войдите ещё раз'**
  String get authErrorRequiresRecentLogin;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Попробуйте через несколько минут'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером. Проверьте интернет'**
  String get authErrorNetwork;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In ru, this message translates to:
  /// **'Вход по email и паролю выключен в консоли Firebase'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить операцию: {code}'**
  String authErrorUnknown(String code);

  /// No description provided for @authErrorGoogleNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Google не настроен для этой сборки приложения'**
  String get authErrorGoogleNotConfigured;

  /// No description provided for @authErrorGoogleProvider.
  ///
  /// In ru, this message translates to:
  /// **'Google не может подтвердить это приложение. Обратитесь в поддержку'**
  String get authErrorGoogleProvider;

  /// No description provided for @authErrorGoogleInterrupted.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Google прервался. Проверьте связь и попробуйте ещё раз'**
  String get authErrorGoogleInterrupted;

  /// No description provided for @authErrorGoogleFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти через Google: {detail}'**
  String authErrorGoogleFailed(String detail);

  /// No description provided for @authErrorGoogleNoToken.
  ///
  /// In ru, this message translates to:
  /// **'Google не вернул токен входа. Попробуйте ещё раз'**
  String get authErrorGoogleNoToken;

  /// No description provided for @authErrorSignInFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала войдите в свою учётную запись'**
  String get authErrorSignInFirst;

  /// No description provided for @authErrorNoPassword.
  ///
  /// In ru, this message translates to:
  /// **'У этой учётной записи нет пароля: вход выполняется через Google. Пароль меняется в настройках аккаунта Google'**
  String get authErrorNoPassword;

  /// No description provided for @authErrorUnknownProvider.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подтвердить личность: неизвестный способ входа. Выйдите и войдите заново'**
  String get authErrorUnknownProvider;

  /// No description provided for @accountMenu.
  ///
  /// In ru, this message translates to:
  /// **'Учётная запись'**
  String get accountMenu;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль и настройки'**
  String get settingsTitle;

  /// No description provided for @settingsSignOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get settingsSignOut;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsChangePassword.
  ///
  /// In ru, this message translates to:
  /// **'Сменить пароль'**
  String get settingsChangePassword;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить учётную запись'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get settingsLanguage;

  /// No description provided for @settingsNotificationsOff.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления выключены'**
  String get settingsNotificationsOff;

  /// No description provided for @settingsNotificationsOn.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления включены'**
  String get settingsNotificationsOn;

  /// No description provided for @settingsLocalOnly.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания на этом устройстве включены. Push пока недоступен: {reason}'**
  String settingsLocalOnly(String reason);

  /// No description provided for @settingsRemindMe.
  ///
  /// In ru, this message translates to:
  /// **'Напоминать о прививках и лекарствах'**
  String get settingsRemindMe;

  /// No description provided for @settingsConnecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключаю…'**
  String get settingsConnecting;

  /// No description provided for @settingsNotificationsHint.
  ///
  /// In ru, this message translates to:
  /// **'Работает, пока приложение установлено на домашний экран или открыто в браузере. Разрешение спрашивает сам браузер — если откажете, включить снова можно будет только в его настройках сайта.'**
  String get settingsNotificationsHint;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKazakh.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get languageKazakh;

  /// No description provided for @themeAuto.
  ///
  /// In ru, this message translates to:
  /// **'Автоматически'**
  String get themeAuto;

  /// No description provided for @themeAutoHint.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная с 21:00 до 7:00'**
  String get themeAutoHint;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @passwordCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get passwordNew;

  /// No description provided for @passwordRepeat.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль ещё раз'**
  String get passwordRepeat;

  /// No description provided for @passwordCurrentRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите текущий пароль'**
  String get passwordCurrentRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён'**
  String get passwordChanged;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить учётную запись?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In ru, this message translates to:
  /// **'Все данные о детях будут удалены навсегда. Восстановить их не сможем ни мы, ни вы.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountPassword.
  ///
  /// In ru, this message translates to:
  /// **'Ваш пароль'**
  String get deleteAccountPassword;

  /// No description provided for @deleteAccountGoogleNote.
  ///
  /// In ru, this message translates to:
  /// **'После подтверждения Google попросит вас войти ещё раз — так проверяется, что удаляете именно вы.'**
  String get deleteAccountGoogleNote;

  /// No description provided for @deleteAccountWord.
  ///
  /// In ru, this message translates to:
  /// **'УДАЛИТЬ'**
  String get deleteAccountWord;

  /// No description provided for @deleteAccountWriteWord.
  ///
  /// In ru, this message translates to:
  /// **'Напишите {word}'**
  String deleteAccountWriteWord(String word);

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить навсегда'**
  String get deleteAccountConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get commonClose;

  /// No description provided for @notificationChannelName.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In ru, this message translates to:
  /// **'Прививки, приём лекарств и визиты к врачу'**
  String get notificationChannelDescription;

  /// No description provided for @reminderTypeVaccination.
  ///
  /// In ru, this message translates to:
  /// **'Прививка'**
  String get reminderTypeVaccination;

  /// No description provided for @reminderTypeMedication.
  ///
  /// In ru, this message translates to:
  /// **'Лекарство'**
  String get reminderTypeMedication;

  /// No description provided for @reminderTypeAppointment.
  ///
  /// In ru, this message translates to:
  /// **'Визит к врачу'**
  String get reminderTypeAppointment;

  /// No description provided for @recurrenceNone.
  ///
  /// In ru, this message translates to:
  /// **'Однократно'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In ru, this message translates to:
  /// **'Ежедневно'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceTwiceDaily.
  ///
  /// In ru, this message translates to:
  /// **'Дважды в день'**
  String get recurrenceTwiceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In ru, this message translates to:
  /// **'Еженедельно'**
  String get recurrenceWeekly;

  /// No description provided for @reminderNew.
  ///
  /// In ru, this message translates to:
  /// **'Новое напоминание'**
  String get reminderNew;

  /// No description provided for @reminderWhat.
  ///
  /// In ru, this message translates to:
  /// **'О чём напомнить'**
  String get reminderWhat;

  /// No description provided for @reminderNameMedication.
  ///
  /// In ru, this message translates to:
  /// **'Что дать — например, «Нурофен, 2,5 мл»'**
  String get reminderNameMedication;

  /// No description provided for @reminderNameAppointment.
  ///
  /// In ru, this message translates to:
  /// **'К кому — например, «Педиатр, 9:00»'**
  String get reminderNameAppointment;

  /// No description provided for @reminderWhen.
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get reminderWhen;

  /// No description provided for @reminderInHours.
  ///
  /// In ru, this message translates to:
  /// **'через {h} ч'**
  String reminderInHours(int h);

  /// No description provided for @reminderTomorrowMorning.
  ///
  /// In ru, this message translates to:
  /// **'завтра утром'**
  String get reminderTomorrowMorning;

  /// No description provided for @reminderExactTime.
  ///
  /// In ru, this message translates to:
  /// **'выбрать время'**
  String get reminderExactTime;

  /// No description provided for @reminderRepeat.
  ///
  /// In ru, this message translates to:
  /// **'Повторять'**
  String get reminderRepeat;

  /// No description provided for @reminderSaved.
  ///
  /// In ru, this message translates to:
  /// **'Напомню {when}'**
  String reminderSaved(String when);

  /// No description provided for @reminderNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Напишите, о чём напомнить'**
  String get reminderNameRequired;

  /// No description provided for @reminderAdd.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание'**
  String get reminderAdd;

  /// No description provided for @reminderCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Отмечено выполненным'**
  String get reminderCompleted;

  /// No description provided for @reminderDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить «{title}»? Вернуть это будет нельзя.'**
  String reminderDeleteConfirm(String title);

  /// No description provided for @reminderDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить напоминание'**
  String get reminderDelete;

  /// No description provided for @reminderDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание удалено'**
  String get reminderDeleted;

  /// No description provided for @remindersVaccinations.
  ///
  /// In ru, this message translates to:
  /// **'Календарь прививок'**
  String get remindersVaccinations;

  /// No description provided for @remindersMedications.
  ///
  /// In ru, this message translates to:
  /// **'Приём лекарств'**
  String get remindersMedications;

  /// No description provided for @remindersAppointments.
  ///
  /// In ru, this message translates to:
  /// **'Визиты к врачу'**
  String get remindersAppointments;

  /// No description provided for @remindersNothingPlanned.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не запланировано'**
  String get remindersNothingPlanned;

  /// No description provided for @remindersShowCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Показать выполненные'**
  String get remindersShowCompleted;

  /// No description provided for @quickFeed.
  ///
  /// In ru, this message translates to:
  /// **'Покормила'**
  String get quickFeed;

  /// No description provided for @quickNappy.
  ///
  /// In ru, this message translates to:
  /// **'Подгузник'**
  String get quickNappy;

  /// No description provided for @quickSleep.
  ///
  /// In ru, this message translates to:
  /// **'Поспал'**
  String get quickSleep;

  /// No description provided for @quickTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Температура'**
  String get quickTemperature;

  /// No description provided for @quickSheetFeeding.
  ///
  /// In ru, this message translates to:
  /// **'Кормление'**
  String get quickSheetFeeding;

  /// No description provided for @quickSheetNappy.
  ///
  /// In ru, this message translates to:
  /// **'Подгузник'**
  String get quickSheetNappy;

  /// No description provided for @quickSheetSleep.
  ///
  /// In ru, this message translates to:
  /// **'Сколько поспал'**
  String get quickSheetSleep;

  /// No description provided for @quickSheetSleepShort.
  ///
  /// In ru, this message translates to:
  /// **'Сон'**
  String get quickSheetSleepShort;

  /// No description provided for @quickSheetTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Температура'**
  String get quickSheetTemperature;

  /// No description provided for @quickTimeNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get quickTimeNow;

  /// No description provided for @quickTimeChoose.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать время'**
  String get quickTimeChoose;

  /// No description provided for @quickNowHint.
  ///
  /// In ru, this message translates to:
  /// **'Отметится текущим временем'**
  String get quickNowHint;

  /// No description provided for @quickSaveButton.
  ///
  /// In ru, this message translates to:
  /// **'Записать'**
  String get quickSaveButton;

  /// No description provided for @quickSaved.
  ///
  /// In ru, this message translates to:
  /// **'Записано: {what}'**
  String quickSaved(String what);

  /// No description provided for @quickSideLeft.
  ///
  /// In ru, this message translates to:
  /// **'Левая'**
  String get quickSideLeft;

  /// No description provided for @quickSideRight.
  ///
  /// In ru, this message translates to:
  /// **'Правая'**
  String get quickSideRight;

  /// No description provided for @quickSideBottle.
  ///
  /// In ru, this message translates to:
  /// **'Бутылочка'**
  String get quickSideBottle;

  /// No description provided for @quickNappyWet.
  ///
  /// In ru, this message translates to:
  /// **'Мокрый'**
  String get quickNappyWet;

  /// No description provided for @quickNappyDirty.
  ///
  /// In ru, this message translates to:
  /// **'Стул'**
  String get quickNappyDirty;

  /// No description provided for @quickNappyBoth.
  ///
  /// In ru, this message translates to:
  /// **'Мокрый и стул'**
  String get quickNappyBoth;

  /// No description provided for @quickSleep30.
  ///
  /// In ru, this message translates to:
  /// **'Полчаса'**
  String get quickSleep30;

  /// No description provided for @quickSleep60.
  ///
  /// In ru, this message translates to:
  /// **'Час'**
  String get quickSleep60;

  /// No description provided for @quickSleep90.
  ///
  /// In ru, this message translates to:
  /// **'Полтора часа'**
  String get quickSleep90;

  /// No description provided for @quickSleep120.
  ///
  /// In ru, this message translates to:
  /// **'Два часа'**
  String get quickSleep120;

  /// No description provided for @quickSleep180.
  ///
  /// In ru, this message translates to:
  /// **'Три часа'**
  String get quickSleep180;

  /// No description provided for @pumpTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сцеживание'**
  String get pumpTitle;

  /// No description provided for @pumpAction.
  ///
  /// In ru, this message translates to:
  /// **'Я сцеживалась'**
  String get pumpAction;

  /// No description provided for @pumpHowMuch.
  ///
  /// In ru, this message translates to:
  /// **'Сколько сцежено'**
  String get pumpHowMuch;

  /// No description provided for @pumpMl.
  ///
  /// In ru, this message translates to:
  /// **'{n} мл'**
  String pumpMl(int n);

  /// No description provided for @pumpToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня сцежено {amount}'**
  String pumpToday(String amount);

  /// No description provided for @feedingSolid.
  ///
  /// In ru, this message translates to:
  /// **'Прикорм'**
  String get feedingSolid;

  /// No description provided for @solidsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Прикорм и реакции'**
  String get solidsTitle;

  /// No description provided for @logReaction.
  ///
  /// In ru, this message translates to:
  /// **'Реакция'**
  String get logReaction;

  /// No description provided for @solidsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Прикорма пока нет'**
  String get solidsEmpty;

  /// No description provided for @solidsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Первая ложка отмечается в «Покормила» → «Прикорм»'**
  String get solidsEmptyHint;

  /// No description provided for @solidWhat.
  ///
  /// In ru, this message translates to:
  /// **'Что ели'**
  String get solidWhat;

  /// No description provided for @solidWhatHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, кабачок'**
  String get solidWhatHint;

  /// No description provided for @solidTimesCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} раз} few{{n} раза} many{{n} раз} other{{n} раза}}'**
  String solidTimesCount(int n);

  /// No description provided for @solidFirstAt.
  ///
  /// In ru, this message translates to:
  /// **'Впервые {date}'**
  String solidFirstAt(String date);

  /// No description provided for @solidWatch.
  ///
  /// In ru, this message translates to:
  /// **'Новое — наблюдаем до {date}'**
  String solidWatch(String date);

  /// No description provided for @solidWatchHint.
  ///
  /// In ru, this message translates to:
  /// **'Три дня без нового продукта — так понятно, на что реакция'**
  String get solidWatchHint;

  /// No description provided for @solidReactionAdd.
  ///
  /// In ru, this message translates to:
  /// **'Была реакция'**
  String get solidReactionAdd;

  /// No description provided for @solidReactionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Реакция на «{food}»'**
  String solidReactionTitle(String food);

  /// No description provided for @solidReactionWhat.
  ///
  /// In ru, this message translates to:
  /// **'Что вы заметили'**
  String get solidReactionWhat;

  /// No description provided for @solidReactionHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, сыпь на щеках к вечеру'**
  String get solidReactionHint;

  /// No description provided for @solidReactionNone.
  ///
  /// In ru, this message translates to:
  /// **'Реакций не было'**
  String get solidReactionNone;

  /// No description provided for @sleepForecastTitle.
  ///
  /// In ru, this message translates to:
  /// **'Скоро сон'**
  String get sleepForecastTitle;

  /// No description provided for @sleepForecastOverdue.
  ///
  /// In ru, this message translates to:
  /// **'Не спит дольше обычного'**
  String get sleepForecastOverdue;

  /// No description provided for @sleepForecastAt.
  ///
  /// In ru, this message translates to:
  /// **'Обычно засыпает около {time}'**
  String sleepForecastAt(String time);

  /// No description provided for @sleepForecastAwake.
  ///
  /// In ru, this message translates to:
  /// **'Не спит {awake} · окно ≈ {window}'**
  String sleepForecastAwake(String awake, String window);

  /// No description provided for @sleepForecastFromHistory.
  ///
  /// In ru, this message translates to:
  /// **'По записям за две недели: {count} промежутков'**
  String sleepForecastFromHistory(int count);

  /// No description provided for @sleepForecastFromAge.
  ///
  /// In ru, this message translates to:
  /// **'Пока по возрастным нормам — записей ещё мало'**
  String get sleepForecastFromAge;

  /// No description provided for @timerStart.
  ///
  /// In ru, this message translates to:
  /// **'Засечь время'**
  String get timerStart;

  /// No description provided for @timerStartHint.
  ///
  /// In ru, this message translates to:
  /// **'Отсчёт пойдёт с этой секунды'**
  String get timerStartHint;

  /// No description provided for @timerFeeding.
  ///
  /// In ru, this message translates to:
  /// **'Кормление идёт'**
  String get timerFeeding;

  /// No description provided for @timerSleep.
  ///
  /// In ru, this message translates to:
  /// **'Сон идёт'**
  String get timerSleep;

  /// No description provided for @timerSince.
  ///
  /// In ru, this message translates to:
  /// **'с {time}'**
  String timerSince(String time);

  /// No description provided for @timerStarted.
  ///
  /// In ru, this message translates to:
  /// **'Отсчёт пошёл'**
  String get timerStarted;

  /// No description provided for @timerNothingRunning.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас ничего не отсчитывается'**
  String get timerNothingRunning;

  /// No description provided for @timerDiscard.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get timerDiscard;

  /// No description provided for @timerDiscarded.
  ///
  /// In ru, this message translates to:
  /// **'Отсчёт сброшен'**
  String get timerDiscarded;

  /// No description provided for @timerForgotten.
  ///
  /// In ru, this message translates to:
  /// **'Идёт очень долго — может, забыли остановить?'**
  String get timerForgotten;

  /// No description provided for @timerLastFeed.
  ///
  /// In ru, this message translates to:
  /// **'Прошлое кормление — {side}, {ago}'**
  String timerLastFeed(String side, String ago);

  /// No description provided for @durationH.
  ///
  /// In ru, this message translates to:
  /// **'{h} ч'**
  String durationH(int h);

  /// No description provided for @durationM.
  ///
  /// In ru, this message translates to:
  /// **'{m} мин'**
  String durationM(int m);

  /// No description provided for @durationHM.
  ///
  /// In ru, this message translates to:
  /// **'{h} ч {m} мин'**
  String durationHM(int h, int m);

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get commonCreate;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get commonAdd;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get commonAll;

  /// No description provided for @commonMore.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get commonMore;

  /// No description provided for @commonBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get commonBack;

  /// No description provided for @commonHide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get commonHide;

  /// No description provided for @commonShow.
  ///
  /// In ru, this message translates to:
  /// **'Показать'**
  String get commonShow;

  /// No description provided for @commonDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get commonDate;

  /// No description provided for @commonTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get commonTime;

  /// No description provided for @commonAge.
  ///
  /// In ru, this message translates to:
  /// **'Возраст'**
  String get commonAge;

  /// No description provided for @commonToday.
  ///
  /// In ru, this message translates to:
  /// **'сегодня'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In ru, this message translates to:
  /// **'завтра'**
  String get commonTomorrow;

  /// No description provided for @commonNumberInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите число'**
  String get commonNumberInvalid;

  /// No description provided for @commonTechnical.
  ///
  /// In ru, this message translates to:
  /// **'Техническая информация'**
  String get commonTechnical;

  /// No description provided for @logTypeMilestone.
  ///
  /// In ru, this message translates to:
  /// **'Веха развития'**
  String get logTypeMilestone;

  /// No description provided for @logTypeMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Измерение'**
  String get logTypeMeasurement;

  /// No description provided for @logTypeIllness.
  ///
  /// In ru, this message translates to:
  /// **'Болезнь'**
  String get logTypeIllness;

  /// No description provided for @logTypeFeeding.
  ///
  /// In ru, this message translates to:
  /// **'Кормление'**
  String get logTypeFeeding;

  /// No description provided for @logTypeNappy.
  ///
  /// In ru, this message translates to:
  /// **'Подгузник'**
  String get logTypeNappy;

  /// No description provided for @logTypeSleep.
  ///
  /// In ru, this message translates to:
  /// **'Сон'**
  String get logTypeSleep;

  /// No description provided for @logTypeQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос врачу'**
  String get logTypeQuestion;

  /// No description provided for @logTypeNote.
  ///
  /// In ru, this message translates to:
  /// **'Запись'**
  String get logTypeNote;

  /// No description provided for @feedingLeft.
  ///
  /// In ru, this message translates to:
  /// **'Левая'**
  String get feedingLeft;

  /// No description provided for @feedingRight.
  ///
  /// In ru, this message translates to:
  /// **'Правая'**
  String get feedingRight;

  /// No description provided for @feedingBottle.
  ///
  /// In ru, this message translates to:
  /// **'Бутылочка'**
  String get feedingBottle;

  /// No description provided for @nappyWet.
  ///
  /// In ru, this message translates to:
  /// **'Мокрый'**
  String get nappyWet;

  /// No description provided for @nappyDirty.
  ///
  /// In ru, this message translates to:
  /// **'Стул'**
  String get nappyDirty;

  /// No description provided for @nappyBoth.
  ///
  /// In ru, this message translates to:
  /// **'Мокрый и стул'**
  String get nappyBoth;

  /// No description provided for @severityMild.
  ///
  /// In ru, this message translates to:
  /// **'Лёгкая'**
  String get severityMild;

  /// No description provided for @severityModerate.
  ///
  /// In ru, this message translates to:
  /// **'Средняя'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In ru, this message translates to:
  /// **'Тяжёлая'**
  String get severitySevere;

  /// No description provided for @genderMale.
  ///
  /// In ru, this message translates to:
  /// **'Мальчик'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ru, this message translates to:
  /// **'Девочка'**
  String get genderFemale;

  /// No description provided for @unitsMetric.
  ///
  /// In ru, this message translates to:
  /// **'Метрическая'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In ru, this message translates to:
  /// **'Имперская'**
  String get unitsImperial;

  /// No description provided for @nightWakingsCount.
  ///
  /// In ru, this message translates to:
  /// **'пробуждений: {n}'**
  String nightWakingsCount(int n);

  /// No description provided for @nightFeedsCount.
  ///
  /// In ru, this message translates to:
  /// **'кормлений: {n}'**
  String nightFeedsCount(int n);

  /// No description provided for @ageYears.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} год} few{{n} года} many{{n} лет} other{{n} года}}'**
  String ageYears(int n);

  /// No description provided for @ageMonths.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} месяц} few{{n} месяца} many{{n} месяцев} other{{n} месяца}}'**
  String ageMonths(int n);

  /// No description provided for @entriesCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} запись} few{{n} записи} many{{n} записей} other{{n} записи}}'**
  String entriesCount(int n);

  /// No description provided for @monthsShort.
  ///
  /// In ru, this message translates to:
  /// **'{n} мес.'**
  String monthsShort(int n);

  /// No description provided for @dashLayoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Блоки на главном экране'**
  String get dashLayoutTitle;

  /// No description provided for @dashAllHidden.
  ///
  /// In ru, this message translates to:
  /// **'Все блоки скрыты'**
  String get dashAllHidden;

  /// No description provided for @dashAllHiddenHint.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть их можно в настройках'**
  String get dashAllHiddenHint;

  /// No description provided for @dashConfigure.
  ///
  /// In ru, this message translates to:
  /// **'Настроить главный экран'**
  String get dashConfigure;

  /// No description provided for @dashNoneSelected.
  ///
  /// In ru, this message translates to:
  /// **'Ни один блок не выбран'**
  String get dashNoneSelected;

  /// No description provided for @dashHiddenBlocks.
  ///
  /// In ru, this message translates to:
  /// **'Скрытые блоки'**
  String get dashHiddenBlocks;

  /// No description provided for @dashReset.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть стандартный набор'**
  String get dashReset;

  /// No description provided for @widgetNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get widgetNow;

  /// No description provided for @widgetSummary.
  ///
  /// In ru, this message translates to:
  /// **'Сводка о ребёнке'**
  String get widgetSummary;

  /// No description provided for @widgetGrowth.
  ///
  /// In ru, this message translates to:
  /// **'Рост и вес'**
  String get widgetGrowth;

  /// No description provided for @widgetVaccinations.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшие прививки'**
  String get widgetVaccinations;

  /// No description provided for @widgetIllness.
  ///
  /// In ru, this message translates to:
  /// **'Заболеваемость'**
  String get widgetIllness;

  /// No description provided for @widgetMilestones.
  ///
  /// In ru, this message translates to:
  /// **'Вехи развития'**
  String get widgetMilestones;

  /// No description provided for @widgetRecent.
  ///
  /// In ru, this message translates to:
  /// **'Последние записи'**
  String get widgetRecent;

  /// No description provided for @widgetUpcoming.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшие события'**
  String get widgetUpcoming;

  /// No description provided for @summaryAge.
  ///
  /// In ru, this message translates to:
  /// **'возраст'**
  String get summaryAge;

  /// No description provided for @summaryBirthDate.
  ///
  /// In ru, this message translates to:
  /// **'дата рождения'**
  String get summaryBirthDate;

  /// No description provided for @summaryMilestonesCount.
  ///
  /// In ru, this message translates to:
  /// **'вех развития'**
  String get summaryMilestonesCount;

  /// No description provided for @summaryEntriesCount.
  ///
  /// In ru, this message translates to:
  /// **'записей всего'**
  String get summaryEntriesCount;

  /// No description provided for @growthNoMeasurements.
  ///
  /// In ru, this message translates to:
  /// **'Измерений пока нет'**
  String get growthNoMeasurements;

  /// No description provided for @growthWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес'**
  String get growthWeight;

  /// No description provided for @growthHeight.
  ///
  /// In ru, this message translates to:
  /// **'Рост'**
  String get growthHeight;

  /// No description provided for @growthLastMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'последнее измерение'**
  String get growthLastMeasurement;

  /// No description provided for @growthPercentileWith.
  ///
  /// In ru, this message translates to:
  /// **'{label} · {p}-й перцентиль'**
  String growthPercentileWith(String label, int p);

  /// No description provided for @vaccinationsNone.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящих прививок нет'**
  String get vaccinationsNone;

  /// No description provided for @illnessDaysTotal.
  ///
  /// In ru, this message translates to:
  /// **'дней болезни всего'**
  String get illnessDaysTotal;

  /// No description provided for @illnessLast3Months.
  ///
  /// In ru, this message translates to:
  /// **'за последние 3 месяца'**
  String get illnessLast3Months;

  /// No description provided for @milestonesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Первое ещё впереди'**
  String get milestonesEmpty;

  /// No description provided for @milestonesEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Первая улыбка, первый зуб, первое слово — добавьте их в дневнике как «Веха развития»'**
  String get milestonesEmptyHint;

  /// No description provided for @recentEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Записей пока нет'**
  String get recentEmpty;

  /// No description provided for @upcomingEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Прививки появятся здесь сами, как только будет создан профиль ребёнка'**
  String get upcomingEmptyHint;

  /// No description provided for @feedbackTitle.
  ///
  /// In ru, this message translates to:
  /// **'Обратная связь'**
  String get feedbackTitle;

  /// No description provided for @feedbackExplain.
  ///
  /// In ru, this message translates to:
  /// **'Если что-то работает не так или чего-то не хватает — напишите. Откроется ваша почта, письмо уйдёт только когда вы сами нажмёте «Отправить».'**
  String get feedbackExplain;

  /// No description provided for @feedbackWrite.
  ///
  /// In ru, this message translates to:
  /// **'Написать разработчику'**
  String get feedbackWrite;

  /// No description provided for @feedbackSubject.
  ///
  /// In ru, this message translates to:
  /// **'Дневник ребёнка — обратная связь'**
  String get feedbackSubject;

  /// No description provided for @feedbackPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Напишите здесь, что случилось или чего не хватает.'**
  String get feedbackPlaceholder;

  /// No description provided for @feedbackNoMailApp.
  ///
  /// In ru, this message translates to:
  /// **'Почта не открылась. Адрес скопирован — напишите с любого устройства'**
  String get feedbackNoMailApp;

  /// No description provided for @feedbackAddressCopied.
  ///
  /// In ru, this message translates to:
  /// **'Адрес скопирован'**
  String get feedbackAddressCopied;

  /// No description provided for @settingsLocation.
  ///
  /// In ru, this message translates to:
  /// **'Где сделано'**
  String get settingsLocation;

  /// No description provided for @logTitle.
  ///
  /// In ru, this message translates to:
  /// **'Журнал ошибок'**
  String get logTitle;

  /// No description provided for @backupTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои данные'**
  String get backupTitle;

  /// No description provided for @backupExplain.
  ///
  /// In ru, this message translates to:
  /// **'Дневник хранится и на устройстве, и на сервере. Файл ниже — ваша собственная копия: он открывается без приложения и переживёт что угодно.'**
  String get backupExplain;

  /// No description provided for @backupSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить копию'**
  String get backupSave;

  /// No description provided for @backupRemindTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сохраните копию дневника'**
  String get backupRemindTitle;

  /// No description provided for @backupRemindBody.
  ///
  /// In ru, this message translates to:
  /// **'Один файл со всеми записями — на случай потерянного телефона. Копия остаётся у вас, никуда не отправляется.'**
  String get backupRemindBody;

  /// No description provided for @backupSaved.
  ///
  /// In ru, this message translates to:
  /// **'Копия сохранена: {file}'**
  String backupSaved(String file);

  /// No description provided for @backupFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить файл'**
  String get backupFailed;

  /// No description provided for @backupNoPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии в файл не входят — они лежат отдельно, а записи о них сохраняют ссылки.'**
  String get backupNoPhotos;

  /// No description provided for @backupStorageSafe.
  ///
  /// In ru, this message translates to:
  /// **'Браузер обещал не удалять данные этого приложения.'**
  String get backupStorageSafe;

  /// No description provided for @backupStorageEvictable.
  ///
  /// In ru, this message translates to:
  /// **'Браузер может очистить данные на устройстве при нехватке места. На сервере они останутся.'**
  String get backupStorageEvictable;

  /// No description provided for @logEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока ничего не сломалось.'**
  String get logEmpty;

  /// No description provided for @logExplain.
  ///
  /// In ru, this message translates to:
  /// **'Записывается только на этом телефоне и никуда не отправляется. Если приложение подвисло или закрылось — скопируйте и пришлите разработчику.'**
  String get logExplain;

  /// No description provided for @logCopy.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать'**
  String get logCopy;

  /// No description provided for @logCopied.
  ///
  /// In ru, this message translates to:
  /// **'Журнал скопирован'**
  String get logCopied;

  /// No description provided for @logClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get logClear;

  /// No description provided for @logCleared.
  ///
  /// In ru, this message translates to:
  /// **'Журнал очищен'**
  String get logCleared;

  /// No description provided for @logCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} запись} few{{n} записи} many{{n} записей} other{{n} записи}}'**
  String logCount(int n);

  /// No description provided for @milestonesUsualTitle.
  ///
  /// In ru, this message translates to:
  /// **'Обычно в этом возрасте'**
  String get milestonesUsualTitle;

  /// No description provided for @milestonesSpread.
  ///
  /// In ru, this message translates to:
  /// **'Это не срок, а окно: у большинства детей появляется где-то внутри этих месяцев. Позже — тоже бывает норма.'**
  String get milestonesSpread;

  /// No description provided for @milestonesNoted.
  ///
  /// In ru, this message translates to:
  /// **'записано'**
  String get milestonesNoted;

  /// No description provided for @milestonesSoon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро'**
  String get milestonesSoon;

  /// No description provided for @milestonesRange.
  ///
  /// In ru, this message translates to:
  /// **'{from}–{to} мес.'**
  String milestonesRange(int from, int to);

  /// No description provided for @milestonesAsk.
  ///
  /// In ru, this message translates to:
  /// **'Записать вопрос врачу'**
  String get milestonesAsk;

  /// No description provided for @greetingNamed.
  ///
  /// In ru, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingNamed(String greeting, String name);

  /// No description provided for @noticedRoundAge.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня {name} ровно {months, plural, one{{months} месяц} few{{months} месяца} many{{months} месяцев} other{{months} месяца}}'**
  String noticedRoundAge(String name, num months);

  /// No description provided for @noticedYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера — {feedings} и {sleep} сна'**
  String noticedYesterday(String feedings, String sleep);

  /// No description provided for @noticedYesterdayNoSleep.
  ///
  /// In ru, this message translates to:
  /// **'Вчера — {feedings}'**
  String noticedYesterdayNoSleep(String feedings);

  /// No description provided for @noticedLongestNight.
  ///
  /// In ru, this message translates to:
  /// **'Самая длинная ночь за месяц — {duration}'**
  String noticedLongestNight(String duration);

  /// No description provided for @greetingNight.
  ///
  /// In ru, this message translates to:
  /// **'Доброй ночи'**
  String get greetingNight;

  /// No description provided for @greetingMorning.
  ///
  /// In ru, this message translates to:
  /// **'Доброе утро'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In ru, this message translates to:
  /// **'Добрый день'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In ru, this message translates to:
  /// **'Добрый вечер'**
  String get greetingEvening;

  /// No description provided for @statusSick.
  ///
  /// In ru, this message translates to:
  /// **'Болеет'**
  String get statusSick;

  /// No description provided for @statusHealthy.
  ///
  /// In ru, this message translates to:
  /// **'Здоров'**
  String get statusHealthy;

  /// No description provided for @statusLatest.
  ///
  /// In ru, this message translates to:
  /// **'последняя'**
  String get statusLatest;

  /// No description provided for @nowTodayReminder.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня: {title}'**
  String nowTodayReminder(String title);

  /// No description provided for @nowNoEntries.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня записей ещё нет. Кнопки ниже отмечают время сами.'**
  String get nowNoEntries;

  /// No description provided for @nowSinceFeeding.
  ///
  /// In ru, this message translates to:
  /// **'С последнего кормления — {duration}'**
  String nowSinceFeeding(String duration);

  /// No description provided for @countFeedings.
  ///
  /// In ru, this message translates to:
  /// **'кормлений'**
  String get countFeedings;

  /// No description provided for @countWet.
  ///
  /// In ru, this message translates to:
  /// **'мокрых'**
  String get countWet;

  /// No description provided for @countDirty.
  ///
  /// In ru, this message translates to:
  /// **'стул'**
  String get countDirty;

  /// No description provided for @countSleep.
  ///
  /// In ru, this message translates to:
  /// **'сна'**
  String get countSleep;

  /// No description provided for @nightAsleepDate.
  ///
  /// In ru, this message translates to:
  /// **'Уснул, дата'**
  String get nightAsleepDate;

  /// No description provided for @nightAwakeDate.
  ///
  /// In ru, this message translates to:
  /// **'Проснулся, дата'**
  String get nightAwakeDate;

  /// No description provided for @nightWokeUp.
  ///
  /// In ru, this message translates to:
  /// **'Просыпался'**
  String get nightWokeUp;

  /// No description provided for @nightOfThoseFeeds.
  ///
  /// In ru, this message translates to:
  /// **'Из них кормлений'**
  String get nightOfThoseFeeds;

  /// No description provided for @nightTotal.
  ///
  /// In ru, this message translates to:
  /// **'Всего сна: {duration}'**
  String nightTotal(String duration);

  /// No description provided for @nightInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проснулся должен быть позже, чем уснул'**
  String get nightInvalid;

  /// No description provided for @errorIndexBuilding.
  ///
  /// In ru, this message translates to:
  /// **'База данных достраивает индексы. Это занимает несколько минут после первого развёртывания — обновите страницу чуть позже.'**
  String get errorIndexBuilding;

  /// No description provided for @errorPermission.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к этим данным. Попробуйте выйти и войти заново.'**
  String get errorPermission;

  /// No description provided for @errorOffline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером. Изменения сохранятся локально и синхронизируются, когда соединение вернётся.'**
  String get errorOffline;

  /// No description provided for @errorSession.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Войдите в учётную запись заново.'**
  String get errorSession;

  /// No description provided for @errorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные. Попробуйте обновить страницу.'**
  String get errorGeneric;

  /// No description provided for @noChildTitle.
  ///
  /// In ru, this message translates to:
  /// **'Давайте познакомимся'**
  String get noChildTitle;

  /// No description provided for @noChildHint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о малыше — дальше приложение подстроится под его возраст и само составит календарь прививок'**
  String get noChildHint;

  /// No description provided for @addChild.
  ///
  /// In ru, this message translates to:
  /// **'Добавить ребёнка'**
  String get addChild;

  /// No description provided for @diaryFeed.
  ///
  /// In ru, this message translates to:
  /// **'Лента событий'**
  String get diaryFeed;

  /// No description provided for @diaryFilterCare.
  ///
  /// In ru, this message translates to:
  /// **'Уход'**
  String get diaryFilterCare;

  /// No description provided for @diaryFilterHealth.
  ///
  /// In ru, this message translates to:
  /// **'Здоровье'**
  String get diaryFilterHealth;

  /// No description provided for @diaryFilterDevelopment.
  ///
  /// In ru, this message translates to:
  /// **'Развитие'**
  String get diaryFilterDevelopment;

  /// No description provided for @diaryFilterNotes.
  ///
  /// In ru, this message translates to:
  /// **'Заметки'**
  String get diaryFilterNotes;

  /// No description provided for @diaryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь будет история малыша'**
  String get diaryEmpty;

  /// No description provided for @diaryEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Кормления и подгузники отмечаются кнопками на главной, а первое слово и первый зуб — здесь'**
  String get diaryEmptyHint;

  /// No description provided for @diaryAddEntry.
  ///
  /// In ru, this message translates to:
  /// **'Добавить запись'**
  String get diaryAddEntry;

  /// No description provided for @diaryDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить запись?'**
  String get diaryDeleteTitle;

  /// No description provided for @diaryDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'Запись «{title}» будет удалена. Действие необратимо.'**
  String diaryDeleteBody(String title);

  /// No description provided for @diaryPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get diaryPhotos;

  /// No description provided for @diaryNewEntry.
  ///
  /// In ru, this message translates to:
  /// **'Новая запись'**
  String get diaryNewEntry;

  /// No description provided for @diaryEditEntry.
  ///
  /// In ru, this message translates to:
  /// **'Изменить запись'**
  String get diaryEditEntry;

  /// No description provided for @diaryType.
  ///
  /// In ru, this message translates to:
  /// **'Тип записи'**
  String get diaryType;

  /// No description provided for @diaryTitleField.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок'**
  String get diaryTitleField;

  /// No description provided for @diaryTitleRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите заголовок'**
  String get diaryTitleRequired;

  /// No description provided for @diaryDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get diaryDescription;

  /// No description provided for @diaryTags.
  ///
  /// In ru, this message translates to:
  /// **'Теги, через запятую'**
  String get diaryTags;

  /// No description provided for @diaryTagsHint.
  ///
  /// In ru, this message translates to:
  /// **'моторика, речь'**
  String get diaryTagsHint;

  /// No description provided for @fieldWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес, {unit}'**
  String fieldWeight(String unit);

  /// No description provided for @fieldHeight.
  ///
  /// In ru, this message translates to:
  /// **'Рост, {unit}'**
  String fieldHeight(String unit);

  /// No description provided for @fieldHead.
  ///
  /// In ru, this message translates to:
  /// **'Окружность головы, {unit}'**
  String fieldHead(String unit);

  /// No description provided for @fieldChest.
  ///
  /// In ru, this message translates to:
  /// **'Окружность груди, {unit}'**
  String fieldChest(String unit);

  /// No description provided for @fieldTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Температура, °C'**
  String get fieldTemperature;

  /// No description provided for @fieldSeverity.
  ///
  /// In ru, this message translates to:
  /// **'Тяжесть'**
  String get fieldSeverity;

  /// No description provided for @pillHead.
  ///
  /// In ru, this message translates to:
  /// **'голова {value}'**
  String pillHead(String value);

  /// No description provided for @pillChest.
  ///
  /// In ru, this message translates to:
  /// **'грудь {value}'**
  String pillChest(String value);

  /// No description provided for @photoUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото: {error}'**
  String photoUploadFailed(String error);

  /// No description provided for @childrenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профили детей'**
  String get childrenTitle;

  /// No description provided for @childrenEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет ни одного профиля'**
  String get childrenEmpty;

  /// No description provided for @childrenEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите «Добавить ребёнка», чтобы начать'**
  String get childrenEmptyHint;

  /// No description provided for @childDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль?'**
  String get childDeleteTitle;

  /// No description provided for @childDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'Профиль «{name}» будет удалён вместе со всеми записями дневника, измерениями, медицинскими записями и напоминаниями. Действие необратимо.'**
  String childDeleteBody(String name);

  /// No description provided for @childSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбран'**
  String get childSelected;

  /// No description provided for @childProfileEdit.
  ///
  /// In ru, this message translates to:
  /// **'Профиль ребёнка'**
  String get childProfileEdit;

  /// No description provided for @childProfileNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый профиль'**
  String get childProfileNew;

  /// No description provided for @childName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get childName;

  /// No description provided for @childNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя'**
  String get childNameRequired;

  /// No description provided for @childBirthDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get childBirthDate;

  /// No description provided for @childPickDate.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дату'**
  String get childPickDate;

  /// No description provided for @childBirthDateRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите дату рождения'**
  String get childBirthDateRequired;

  /// No description provided for @photoAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get photoAdd;

  /// No description provided for @photoRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать фото'**
  String get photoRemove;

  /// No description provided for @photoSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить фото: {error}'**
  String photoSaveFailed(String error);

  /// No description provided for @quickNoteOptional.
  ///
  /// In ru, this message translates to:
  /// **'Заметка (необязательно)'**
  String get quickNoteOptional;

  /// No description provided for @quickAssistant.
  ///
  /// In ru, this message translates to:
  /// **'Помощник'**
  String get quickAssistant;

  /// No description provided for @quickNightSleep.
  ///
  /// In ru, this message translates to:
  /// **'Ночной сон'**
  String get quickNightSleep;

  /// No description provided for @digestTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get digestTitle;

  /// No description provided for @digestSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Коротко о дне'**
  String get digestSubtitle;

  /// No description provided for @digestFeedings.
  ///
  /// In ru, this message translates to:
  /// **'Кормлений'**
  String get digestFeedings;

  /// No description provided for @digestSleep.
  ///
  /// In ru, this message translates to:
  /// **'Сон за день'**
  String get digestSleep;

  /// No description provided for @digestNappies.
  ///
  /// In ru, this message translates to:
  /// **'Подгузников'**
  String get digestNappies;

  /// No description provided for @digestTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Температура'**
  String get digestTemperature;

  /// No description provided for @digestPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Новых фото'**
  String get digestPhotos;

  /// No description provided for @digestEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня записей пока нет'**
  String get digestEmpty;

  /// No description provided for @digestCalm.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня был спокойный день.'**
  String get digestCalm;

  /// No description provided for @digestBusy.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня был насыщенный день.'**
  String get digestBusy;

  /// No description provided for @digestHardNight.
  ///
  /// In ru, this message translates to:
  /// **'Ночь была немного трудной.'**
  String get digestHardNight;

  /// No description provided for @momentsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Моменты дня'**
  String get momentsTitle;

  /// No description provided for @momentsLineOne.
  ///
  /// In ru, this message translates to:
  /// **'Маленький момент сегодняшнего дня'**
  String get momentsLineOne;

  /// No description provided for @momentsLineTwo.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня была новая улыбка'**
  String get momentsLineTwo;

  /// No description provided for @momentsLineMany.
  ///
  /// In ru, this message translates to:
  /// **'Воспоминание, которое стоит сохранить'**
  String get momentsLineMany;

  /// No description provided for @storyTitleCare.
  ///
  /// In ru, this message translates to:
  /// **'Неделя заботы'**
  String get storyTitleCare;

  /// No description provided for @storyTitleGrowing.
  ///
  /// In ru, this message translates to:
  /// **'Растём вместе'**
  String get storyTitleGrowing;

  /// No description provided for @storyTitleMoments.
  ///
  /// In ru, this message translates to:
  /// **'Маленькие моменты, большая любовь'**
  String get storyTitleMoments;

  /// No description provided for @storyFeedings.
  ///
  /// In ru, this message translates to:
  /// **'Кормлений'**
  String get storyFeedings;

  /// No description provided for @storySleep.
  ///
  /// In ru, this message translates to:
  /// **'Сна за неделю'**
  String get storySleep;

  /// No description provided for @storyNappies.
  ///
  /// In ru, this message translates to:
  /// **'Подгузников'**
  String get storyNappies;

  /// No description provided for @storyBestNight.
  ///
  /// In ru, this message translates to:
  /// **'Лучшая ночь'**
  String get storyBestNight;

  /// No description provided for @storyExport.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить PDF'**
  String get storyExport;

  /// No description provided for @storyPdfReady.
  ///
  /// In ru, this message translates to:
  /// **'Страница недели готова'**
  String get storyPdfReady;

  /// No description provided for @appreciationHeavyDay.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня был непростой день. Вы сделали очень много для малыша.'**
  String get appreciationHeavyDay;

  /// No description provided for @appreciationThanks.
  ///
  /// In ru, this message translates to:
  /// **'Папа поблагодарил вас за сегодняшний день ❤️'**
  String get appreciationThanks;

  /// No description provided for @appreciationThankButton.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за сегодняшний день'**
  String get appreciationThankButton;

  /// No description provided for @appreciationThankSent.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо отправлено'**
  String get appreciationThankSent;

  /// No description provided for @voiceQuickHint.
  ///
  /// In ru, this message translates to:
  /// **'Записать голосом'**
  String get voiceQuickHint;

  /// No description provided for @voiceHoldHint.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте кнопку и говорите'**
  String get voiceHoldHint;

  /// No description provided for @voiceExample.
  ///
  /// In ru, this message translates to:
  /// **'«покормила левой 15 минут»'**
  String get voiceExample;

  /// No description provided for @voiceBusy.
  ///
  /// In ru, this message translates to:
  /// **'Секунду — заканчиваю прошлую запись'**
  String get voiceBusy;

  /// No description provided for @voiceTraceHint.
  ///
  /// In ru, this message translates to:
  /// **'Что произошло. Пришлите этот список, если микрофон не работает'**
  String get voiceTraceHint;

  /// No description provided for @voiceTapHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите и говорите'**
  String get voiceTapHint;

  /// No description provided for @voiceTapToStop.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите ещё раз, когда закончите'**
  String get voiceTapToStop;

  /// No description provided for @voiceSheetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Скажите или напишите'**
  String get voiceSheetTitle;

  /// No description provided for @voiceKeyboardHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите микрофон на клавиатуре и продиктуйте — это диктовка вашего телефона'**
  String get voiceKeyboardHint;

  /// No description provided for @voiceNothingYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока пусто'**
  String get voiceNothingYet;

  /// No description provided for @voiceWillSave.
  ///
  /// In ru, this message translates to:
  /// **'Запишем'**
  String get voiceWillSave;

  /// No description provided for @voiceFieldHint.
  ///
  /// In ru, this message translates to:
  /// **'Скажите или напишите…'**
  String get voiceFieldHint;

  /// No description provided for @commonUndo.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get commonUndo;

  /// No description provided for @voiceSavingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Записать сейчас'**
  String get voiceSavingSoon;

  /// No description provided for @voiceOpening.
  ///
  /// In ru, this message translates to:
  /// **'Открываю микрофон…'**
  String get voiceOpening;

  /// No description provided for @voiceHeard.
  ///
  /// In ru, this message translates to:
  /// **'Услышано'**
  String get voiceHeard;

  /// No description provided for @voiceMl.
  ///
  /// In ru, this message translates to:
  /// **'мл'**
  String get voiceMl;

  /// No description provided for @voiceAsNote.
  ///
  /// In ru, this message translates to:
  /// **'Сохраним как заметку'**
  String get voiceAsNote;

  /// No description provided for @homeQuickLog.
  ///
  /// In ru, this message translates to:
  /// **'Быстрая запись'**
  String get homeQuickLog;

  /// No description provided for @homeSpeak.
  ///
  /// In ru, this message translates to:
  /// **'Напишите или продиктуйте…'**
  String get homeSpeak;

  /// No description provided for @homeRepeat.
  ///
  /// In ru, this message translates to:
  /// **'Как в прошлый раз'**
  String get homeRepeat;

  /// No description provided for @homeRecent.
  ///
  /// In ru, this message translates to:
  /// **'Последние события'**
  String get homeRecent;

  /// No description provided for @homeNothingYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока ничего не записано'**
  String get homeNothingYet;

  /// No description provided for @homeMore.
  ///
  /// In ru, this message translates to:
  /// **'Всё остальное — во вкладке «Помощник»'**
  String get homeMore;

  /// No description provided for @assistantInsights.
  ///
  /// In ru, this message translates to:
  /// **'Наблюдения и отчёты'**
  String get assistantInsights;

  /// No description provided for @assistantViewKnowledge.
  ///
  /// In ru, this message translates to:
  /// **'Справочник'**
  String get assistantViewKnowledge;

  /// No description provided for @assistantViewInsights.
  ///
  /// In ru, this message translates to:
  /// **'Сводка'**
  String get assistantViewInsights;

  /// No description provided for @familyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Семья'**
  String get familyTitle;

  /// No description provided for @familySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кто ещё видит профиль ребёнка'**
  String get familySubtitle;

  /// No description provided for @familyInvite.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить'**
  String get familyInvite;

  /// No description provided for @familyInviteEmail.
  ///
  /// In ru, this message translates to:
  /// **'Электронная почта'**
  String get familyInviteEmail;

  /// No description provided for @familyInviteEmailHint.
  ///
  /// In ru, this message translates to:
  /// **'например, papa@gmail.com'**
  String get familyInviteEmailHint;

  /// No description provided for @familyInviteHint.
  ///
  /// In ru, this message translates to:
  /// **'Адрес, которым он входит в приложение — по нему и открывается доступ'**
  String get familyInviteHint;

  /// No description provided for @familyInvitePhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон в WhatsApp'**
  String get familyInvitePhone;

  /// No description provided for @familyInvitePhoneHint.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно. Номер подставится в WhatsApp, чтобы не искать его в списке'**
  String get familyInvitePhoneHint;

  /// No description provided for @familyPhoneInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте номер'**
  String get familyPhoneInvalid;

  /// No description provided for @familyInviteWhatsApp.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено в WhatsApp'**
  String get familyInviteWhatsApp;

  /// No description provided for @familyInviteMailed.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено на {email}'**
  String familyInviteMailed(String email);

  /// No description provided for @familyInviteMailFailed.
  ///
  /// In ru, this message translates to:
  /// **'Отправить не удалось. Скопируйте приглашение и передайте сами'**
  String get familyInviteMailFailed;

  /// No description provided for @familyInviteCreated.
  ///
  /// In ru, this message translates to:
  /// **'Доступ уже открыт — осталось передать приглашение'**
  String get familyInviteCreated;

  /// No description provided for @familyInviteSending.
  ///
  /// In ru, this message translates to:
  /// **'Отправляю…'**
  String get familyInviteSending;

  /// No description provided for @familyInviteHandoff.
  ///
  /// In ru, this message translates to:
  /// **'Передайте приглашение сами — так вы увидите, что оно дошло:'**
  String get familyInviteHandoff;

  /// No description provided for @familyOpenWhatsApp.
  ///
  /// In ru, this message translates to:
  /// **'Открыть WhatsApp'**
  String get familyOpenWhatsApp;

  /// No description provided for @familyWhatsAppNotOpened.
  ///
  /// In ru, this message translates to:
  /// **'WhatsApp не открылся — скопируйте приглашение'**
  String get familyWhatsAppNotOpened;

  /// No description provided for @familyInviteExplain.
  ///
  /// In ru, this message translates to:
  /// **'Письма приложение не отправляет. Приглашение появится здесь же — его можно сразу открыть в WhatsApp или скопировать.'**
  String get familyInviteExplain;

  /// No description provided for @familyCopyInvite.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать приглашение'**
  String get familyCopyInvite;

  /// No description provided for @familyInviteCopied.
  ///
  /// In ru, this message translates to:
  /// **'Текст приглашения скопирован — вставьте в мессенджер'**
  String get familyInviteCopied;

  /// No description provided for @familyInviteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Я открыл доступ к дневнику ребёнка ({name}). Открой ссылку и войди почтой {email}: {link}'**
  String familyInviteMessage(String name, String email, String link);

  /// No description provided for @familyInviteSent.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено'**
  String get familyInviteSent;

  /// No description provided for @familyEmailInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте адрес'**
  String get familyEmailInvalid;

  /// No description provided for @familyEmailRequired.
  ///
  /// In ru, this message translates to:
  /// **'Нужна почта — по одному телефону доступ открыть некому. Впишите адрес, которым он входит в приложение'**
  String get familyEmailRequired;

  /// No description provided for @familyPending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает подтверждения'**
  String get familyPending;

  /// No description provided for @familyAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Есть доступ'**
  String get familyAccepted;

  /// No description provided for @familyNobody.
  ///
  /// In ru, this message translates to:
  /// **'Пока только вы'**
  String get familyNobody;

  /// No description provided for @familyRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать доступ'**
  String get familyRemove;

  /// No description provided for @familyRoleOwner.
  ///
  /// In ru, this message translates to:
  /// **'Мама'**
  String get familyRoleOwner;

  /// No description provided for @familyRoleViewer.
  ///
  /// In ru, this message translates to:
  /// **'Папа'**
  String get familyRoleViewer;

  /// No description provided for @familyReadOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только просмотр'**
  String get familyReadOnly;

  /// No description provided for @familyReadOnlyHint.
  ///
  /// In ru, this message translates to:
  /// **'Вы видите профиль, но не меняете записи'**
  String get familyReadOnlyHint;

  /// No description provided for @familyInviteBanner.
  ///
  /// In ru, this message translates to:
  /// **'Вас пригласили в профиль ребёнка'**
  String get familyInviteBanner;

  /// No description provided for @familyAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get familyAccept;

  /// No description provided for @familyLater.
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get familyLater;

  /// No description provided for @familyAcceptedToast.
  ///
  /// In ru, this message translates to:
  /// **'Теперь вы видите профиль'**
  String get familyAcceptedToast;

  /// No description provided for @familyOwnerOnly.
  ///
  /// In ru, this message translates to:
  /// **'Это может изменить только владелец профиля'**
  String get familyOwnerOnly;

  /// No description provided for @familyAlreadyMember.
  ///
  /// In ru, this message translates to:
  /// **'У этого адреса уже есть доступ'**
  String get familyAlreadyMember;

  /// No description provided for @familySelfInvite.
  ///
  /// In ru, this message translates to:
  /// **'Это ваш собственный адрес'**
  String get familySelfInvite;

  /// No description provided for @familyInviteLink.
  ///
  /// In ru, this message translates to:
  /// **'Создать приглашение'**
  String get familyInviteLink;

  /// No description provided for @familyInviteLinkExplain.
  ///
  /// In ru, this message translates to:
  /// **'Ничего вводить не нужно. Приложение создаст ссылку — отправьте её в WhatsApp, и человек войдёт своей почтой сам.'**
  String get familyInviteLinkExplain;

  /// No description provided for @familyLinkReady.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка готова. Действует 7 дней и открывается один раз'**
  String get familyLinkReady;

  /// No description provided for @familyCopyLink.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку'**
  String get familyCopyLink;

  /// No description provided for @familyLinkCopied.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка скопирована — вставьте в сообщение'**
  String get familyLinkCopied;

  /// No description provided for @familyLinkFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать ссылку. Попробуйте ещё раз'**
  String get familyLinkFailed;

  /// No description provided for @familyInviteLinkMessage.
  ///
  /// In ru, this message translates to:
  /// **'Открываю тебе доступ к дневнику ребёнка ({name}). Открой ссылку и войди своей почтой: {link}'**
  String familyInviteLinkMessage(String name, String link);

  /// No description provided for @joinTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение'**
  String get joinTitle;

  /// No description provided for @joinIntro.
  ///
  /// In ru, this message translates to:
  /// **'Вас приглашают в дневник ребёнка'**
  String get joinIntro;

  /// No description provided for @joinReadOnly.
  ///
  /// In ru, this message translates to:
  /// **'Вы будете видеть кормления, сон, рост и записи. Только смотреть — изменить или удалить ничего нельзя.'**
  String get joinReadOnly;

  /// No description provided for @joinAs.
  ///
  /// In ru, this message translates to:
  /// **'Вы вошли как {email}'**
  String joinAs(String email);

  /// No description provided for @joinAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять приглашение'**
  String get joinAccept;

  /// No description provided for @joinDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово. Теперь вы видите дневник'**
  String get joinDone;

  /// No description provided for @joinOpenDiary.
  ///
  /// In ru, this message translates to:
  /// **'Открыть дневник'**
  String get joinOpenDiary;

  /// No description provided for @joinSpent.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка больше не действует — попросите новую'**
  String get joinSpent;

  /// No description provided for @quickFeedHint.
  ///
  /// In ru, this message translates to:
  /// **'грудь или бутылочка'**
  String get quickFeedHint;

  /// No description provided for @quickNappyHint.
  ///
  /// In ru, this message translates to:
  /// **'мокрый или стул'**
  String get quickNappyHint;

  /// No description provided for @quickSleepHint.
  ///
  /// In ru, this message translates to:
  /// **'дневной отдых'**
  String get quickSleepHint;

  /// No description provided for @quickNightSleepHint.
  ///
  /// In ru, this message translates to:
  /// **'с пробуждениями'**
  String get quickNightSleepHint;

  /// No description provided for @quickTemperatureHint.
  ///
  /// In ru, this message translates to:
  /// **'одно измерение'**
  String get quickTemperatureHint;

  /// No description provided for @quickAssistantHint.
  ///
  /// In ru, this message translates to:
  /// **'спросить о малыше'**
  String get quickAssistantHint;

  /// No description provided for @phraseOfDay1.
  ///
  /// In ru, this message translates to:
  /// **'Вы делаете достаточно.'**
  String get phraseOfDay1;

  /// No description provided for @phraseOfDay2.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня можно медленнее.'**
  String get phraseOfDay2;

  /// No description provided for @phraseOfDay3.
  ///
  /// In ru, this message translates to:
  /// **'Малыш чувствует вашу заботу.'**
  String get phraseOfDay3;

  /// No description provided for @phraseOfDay4.
  ///
  /// In ru, this message translates to:
  /// **'Отдых — это тоже забота.'**
  String get phraseOfDay4;

  /// No description provided for @phraseOfDay5.
  ///
  /// In ru, this message translates to:
  /// **'Каждый день немного проще.'**
  String get phraseOfDay5;

  /// No description provided for @phraseOfDay6.
  ///
  /// In ru, this message translates to:
  /// **'Вы рядом, и этого хватает.'**
  String get phraseOfDay6;

  /// No description provided for @quickFever.
  ///
  /// In ru, this message translates to:
  /// **'Это лихорадка. День будет отмечен как день болезни.'**
  String get quickFever;

  /// No description provided for @quickFeverAction.
  ///
  /// In ru, this message translates to:
  /// **'Что делать'**
  String get quickFeverAction;

  /// No description provided for @growthChartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Динамика показателей'**
  String get growthChartTitle;

  /// No description provided for @growthAddMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Добавить измерение'**
  String get growthAddMeasurement;

  /// No description provided for @growthEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нечего показать на графике'**
  String get growthEmpty;

  /// No description provided for @growthEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте рост и вес в дневнике — кривая появится после первого измерения, а нормы ВОЗ уже ждут'**
  String get growthEmptyHint;

  /// No description provided for @growthAxisAge.
  ///
  /// In ru, this message translates to:
  /// **'возраст, месяцев'**
  String get growthAxisAge;

  /// No description provided for @growthWhoMedian.
  ///
  /// In ru, this message translates to:
  /// **'медиана ВОЗ'**
  String get growthWhoMedian;

  /// No description provided for @growthWhoBand.
  ///
  /// In ru, this message translates to:
  /// **'коридор ±2 SD'**
  String get growthWhoBand;

  /// No description provided for @growthWhoLimit.
  ///
  /// In ru, this message translates to:
  /// **'Нормы ВОЗ определены до 5 лет, поэтому справочные кривые обрываются на 60 месяцах.'**
  String get growthWhoLimit;

  /// No description provided for @growthWhoAssessment.
  ///
  /// In ru, this message translates to:
  /// **'Оценка по нормам ВОЗ'**
  String get growthWhoAssessment;

  /// No description provided for @growthAgeOutOfRange.
  ///
  /// In ru, this message translates to:
  /// **'Возраст вне диапазона справочных таблиц (0–60 месяцев)'**
  String get growthAgeOutOfRange;

  /// No description provided for @growthPercentileOrdinal.
  ///
  /// In ru, this message translates to:
  /// **'{p}-й'**
  String growthPercentileOrdinal(int p);

  /// No description provided for @growthPercentileWord.
  ///
  /// In ru, this message translates to:
  /// **'перцентиль'**
  String get growthPercentileWord;

  /// No description provided for @growthChangeSince.
  ///
  /// In ru, this message translates to:
  /// **'прибавка с {date}'**
  String growthChangeSince(String date);

  /// No description provided for @growthZScore.
  ///
  /// In ru, this message translates to:
  /// **'z-оценка'**
  String get growthZScore;

  /// No description provided for @growthDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Расчёт по нормам ВОЗ для детей 0–5 лет. Перцентиль показывает положение среди сверстников, а не диагноз: отклонение может быть и особенностью конкретного ребёнка. Оценивает врач.'**
  String get growthDisclaimer;

  /// No description provided for @growthHistory.
  ///
  /// In ru, this message translates to:
  /// **'История измерений'**
  String get growthHistory;

  /// No description provided for @illnessTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статистика заболеваемости'**
  String get illnessTitle;

  /// No description provided for @illnessHeatmap.
  ///
  /// In ru, this message translates to:
  /// **'Тепловая карта за {months} месяцев'**
  String illnessHeatmap(int months);

  /// No description provided for @illnessEpisodes.
  ///
  /// In ru, this message translates to:
  /// **'Эпизоды болезни'**
  String get illnessEpisodes;

  /// No description provided for @illnessAdd.
  ///
  /// In ru, this message translates to:
  /// **'Отметить болезнь'**
  String get illnessAdd;

  /// No description provided for @illnessEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Записей о болезнях нет'**
  String get illnessEmpty;

  /// No description provided for @illnessEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Отметить день болезни можно в дневнике'**
  String get illnessEmptyHint;

  /// No description provided for @illnessEpisodesCount.
  ///
  /// In ru, this message translates to:
  /// **'эпизодов'**
  String get illnessEpisodesCount;

  /// No description provided for @illnessDays12.
  ///
  /// In ru, this message translates to:
  /// **'дней за 12 месяцев'**
  String get illnessDays12;

  /// No description provided for @illnessDays3.
  ///
  /// In ru, this message translates to:
  /// **'дней за 3 месяца'**
  String get illnessDays3;

  /// No description provided for @illnessWell.
  ///
  /// In ru, this message translates to:
  /// **'здоров'**
  String get illnessWell;

  /// No description provided for @illnessDayWell.
  ///
  /// In ru, this message translates to:
  /// **'{date} — здоров'**
  String illnessDayWell(String date);

  /// No description provided for @remindersActiveCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} активное напоминание} few{{n} активных напоминания} many{{n} активных напоминаний} other{{n} активных напоминания}}'**
  String remindersActiveCount(int n);

  /// No description provided for @remindersOverdue.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{просрочено на {n} день} few{просрочено на {n} дня} many{просрочено на {n} дней} other{просрочено на {n} дня}}'**
  String remindersOverdue(int n);

  /// No description provided for @remindersInDays.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{через {n} день} few{через {n} дня} many{через {n} дней} other{через {n} дня}}'**
  String remindersInDays(int n);

  /// No description provided for @medicalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Медицинские записи'**
  String get medicalTitle;

  /// No description provided for @medicalEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Медицинских записей пока нет'**
  String get medicalEmpty;

  /// No description provided for @medicalEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте визит к врачу или результаты анализов'**
  String get medicalEmptyHint;

  /// No description provided for @medicalDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить запись?'**
  String get medicalDeleteTitle;

  /// No description provided for @medicalDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'Запись «{diagnosis}» от {date} будет удалена вместе с результатами анализов. Действие необратимо.'**
  String medicalDeleteBody(String diagnosis, String date);

  /// No description provided for @medicalAskDoctor.
  ///
  /// In ru, this message translates to:
  /// **'Спросить у врача'**
  String get medicalAskDoctor;

  /// No description provided for @medicalWriteDown.
  ///
  /// In ru, this message translates to:
  /// **'Записать'**
  String get medicalWriteDown;

  /// No description provided for @medicalQuestionsHint.
  ///
  /// In ru, this message translates to:
  /// **'Запишите сюда всё, что хотите спросить. Список попадёт в отчёт для врача — не придётся вспоминать в кабинете.'**
  String get medicalQuestionsHint;

  /// No description provided for @medicalQuestionAsked.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос отмечен как заданный'**
  String get medicalQuestionAsked;

  /// No description provided for @medicalQuestionSaved.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос записан — он попадёт в отчёт'**
  String get medicalQuestionSaved;

  /// No description provided for @entrySaved.
  ///
  /// In ru, this message translates to:
  /// **'Запись сохранена'**
  String get entrySaved;

  /// No description provided for @entryDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Запись удалена'**
  String get entryDeleted;

  /// No description provided for @medicalRecordSaved.
  ///
  /// In ru, this message translates to:
  /// **'Запись в медкарте сохранена'**
  String get medicalRecordSaved;

  /// No description provided for @medicalRecordDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Запись удалена из медкарты'**
  String get medicalRecordDeleted;

  /// No description provided for @medicalAsked.
  ///
  /// In ru, this message translates to:
  /// **'Спросила'**
  String get medicalAsked;

  /// No description provided for @medicalQuestionHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: нормально ли, что срыгивает после каждого кормления'**
  String get medicalQuestionHint;

  /// No description provided for @medicalReport.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт для врача'**
  String get medicalReport;

  /// No description provided for @medicalReportHint.
  ///
  /// In ru, this message translates to:
  /// **'Сводка на одном листе: антропометрия с оценкой по нормам ВОЗ, статистика болезней, анализы с отклонениями, статус вакцинации и вехи развития.'**
  String get medicalReportHint;

  /// No description provided for @medicalReportBuilding.
  ///
  /// In ru, this message translates to:
  /// **'Формирую…'**
  String get medicalReportBuilding;

  /// No description provided for @medicalReportDownload.
  ///
  /// In ru, this message translates to:
  /// **'Скачать PDF'**
  String get medicalReportDownload;

  /// No description provided for @medicalReportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сформировать отчёт: {error}'**
  String medicalReportFailed(String error);

  /// No description provided for @medicalPrescriptions.
  ///
  /// In ru, this message translates to:
  /// **'Назначения'**
  String get medicalPrescriptions;

  /// No description provided for @medicalLabResults.
  ///
  /// In ru, this message translates to:
  /// **'Результаты анализов'**
  String get medicalLabResults;

  /// No description provided for @medicalOutOfRange.
  ///
  /// In ru, this message translates to:
  /// **'{n} вне нормы'**
  String medicalOutOfRange(int n);

  /// No description provided for @medicalScans.
  ///
  /// In ru, this message translates to:
  /// **'Сканы бланков'**
  String get medicalScans;

  /// No description provided for @medicalIndicator.
  ///
  /// In ru, this message translates to:
  /// **'Показатель'**
  String get medicalIndicator;

  /// No description provided for @medicalValue.
  ///
  /// In ru, this message translates to:
  /// **'Значение'**
  String get medicalValue;

  /// No description provided for @medicalReference.
  ///
  /// In ru, this message translates to:
  /// **'Норма'**
  String get medicalReference;

  /// No description provided for @medicalRecordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Медицинская запись'**
  String get medicalRecordTitle;

  /// No description provided for @medicalDiagnosis.
  ///
  /// In ru, this message translates to:
  /// **'Диагноз или причина визита'**
  String get medicalDiagnosis;

  /// No description provided for @medicalDiagnosisRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите диагноз или причину визита'**
  String get medicalDiagnosisRequired;

  /// No description provided for @medicalDoctor.
  ///
  /// In ru, this message translates to:
  /// **'Врач и учреждение'**
  String get medicalDoctor;

  /// No description provided for @medicalDoctorHint.
  ///
  /// In ru, this message translates to:
  /// **'Педиатр, поликлиника №2'**
  String get medicalDoctorHint;

  /// No description provided for @medicalLabs.
  ///
  /// In ru, this message translates to:
  /// **'Анализы'**
  String get medicalLabs;

  /// No description provided for @medicalAddRow.
  ///
  /// In ru, this message translates to:
  /// **'Добавить строку'**
  String get medicalAddRow;

  /// No description provided for @medicalReferenceHint.
  ///
  /// In ru, this message translates to:
  /// **'Референсные значения не обязательны, но без них приложение не сможет отметить отклонение.'**
  String get medicalReferenceHint;

  /// No description provided for @medicalScan.
  ///
  /// In ru, this message translates to:
  /// **'Скан бланка'**
  String get medicalScan;

  /// No description provided for @medicalUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить: {error}'**
  String medicalUploadFailed(String error);

  /// No description provided for @medicalRowInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте строку «{name}»: нужно название и числовое значение.'**
  String medicalRowInvalid(String name);

  /// No description provided for @medicalUnitShort.
  ///
  /// In ru, this message translates to:
  /// **'Ед.'**
  String get medicalUnitShort;

  /// No description provided for @medicalFrom.
  ///
  /// In ru, this message translates to:
  /// **'от'**
  String get medicalFrom;

  /// No description provided for @medicalTo.
  ///
  /// In ru, this message translates to:
  /// **'до'**
  String get medicalTo;

  /// No description provided for @medicalRemoveRow.
  ///
  /// In ru, this message translates to:
  /// **'Убрать строку'**
  String get medicalRemoveRow;

  /// No description provided for @medicalAttach.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить'**
  String get medicalAttach;

  /// No description provided for @assistantSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по статьям: температура, сыпь, прикорм…'**
  String get assistantSearchHint;

  /// No description provided for @assistantSearchIsArticles.
  ///
  /// In ru, this message translates to:
  /// **'Это поиск по статьям приложения. На любой вопрос ответит помощник.'**
  String get assistantSearchIsArticles;

  /// No description provided for @assistantAskAi.
  ///
  /// In ru, this message translates to:
  /// **'Спросить помощника'**
  String get assistantAskAi;

  /// No description provided for @assistantNothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не нашлось'**
  String get assistantNothingFound;

  /// No description provided for @assistantNoArticle.
  ///
  /// In ru, this message translates to:
  /// **'По запросу «{query}» в базе пока нет статьи'**
  String assistantNoArticle(String query);

  /// No description provided for @assistantTryAnother.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другое слово — например, «температура» или «сыпь»'**
  String get assistantTryAnother;

  /// No description provided for @assistantFound.
  ///
  /// In ru, this message translates to:
  /// **'Найдено'**
  String get assistantFound;

  /// No description provided for @assistantArticlesCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} статья} few{{n} статьи} many{{n} статей} other{{n} статьи}}'**
  String assistantArticlesCount(int n);

  /// No description provided for @assistantTriage.
  ///
  /// In ru, this message translates to:
  /// **'Проверить тревожные признаки'**
  String get assistantTriage;

  /// No description provided for @assistantTriageHint.
  ///
  /// In ru, this message translates to:
  /// **'Несколько вопросов — и понятно, ждать или звонить 103'**
  String get assistantTriageHint;

  /// No description provided for @assistantChat.
  ///
  /// In ru, this message translates to:
  /// **'Спросить своими словами'**
  String get assistantChat;

  /// No description provided for @assistantChatHint.
  ///
  /// In ru, this message translates to:
  /// **'Ответит на любой вопрос — о ребёнке и не только'**
  String get assistantChatHint;

  /// No description provided for @assistantChatOff.
  ///
  /// In ru, this message translates to:
  /// **'ИИ пока не подключён — откройте, чтобы узнать как'**
  String get assistantChatOff;

  /// No description provided for @assistantRelevant.
  ///
  /// In ru, this message translates to:
  /// **'Актуально сейчас'**
  String get assistantRelevant;

  /// No description provided for @assistantChildAge.
  ///
  /// In ru, this message translates to:
  /// **'{name}, {months} мес.'**
  String assistantChildAge(String name, int months);

  /// No description provided for @assistantAllTopics.
  ///
  /// In ru, this message translates to:
  /// **'Все темы'**
  String get assistantAllTopics;

  /// No description provided for @assistantDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Материалы основаны на рекомендациях ВОЗ, NICE и Американской академии педиатрии. Это справочная информация для родителей, а не замена осмотру. Окончательное решение всегда за врачом.'**
  String get assistantDisclaimer;

  /// No description provided for @chatTitle.
  ///
  /// In ru, this message translates to:
  /// **'Спросить помощника'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Спросите что-нибудь о здоровье ребёнка'**
  String get chatEmpty;

  /// No description provided for @chatHint.
  ///
  /// In ru, this message translates to:
  /// **'Спросите о чём угодно — про {name} или про своё'**
  String chatHint(String name);

  /// No description provided for @chatSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get chatSend;

  /// No description provided for @chatAsk.
  ///
  /// In ru, this message translates to:
  /// **'Спросите о чём угодно'**
  String get chatAsk;

  /// No description provided for @chatOrRecord.
  ///
  /// In ru, this message translates to:
  /// **'Или продиктуйте запись — «покормила левой 15 минут», «спал 2 часа», «температура 37.2». Запишу в дневник.'**
  String get chatOrRecord;

  /// No description provided for @chatRecordUndone.
  ///
  /// In ru, this message translates to:
  /// **'Запись удалена'**
  String get chatRecordUndone;

  /// No description provided for @chatOpening.
  ///
  /// In ru, this message translates to:
  /// **'Спросите о чём угодно — про {name} или про своё'**
  String chatOpening(String name);

  /// No description provided for @chatDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Помощник отвечает на любые вопросы. О здоровье ребёнка он опирается на проверенную базу приложения, где она есть, и не ставит диагнозов — решение всегда за врачом.'**
  String get chatDisclaimer;

  /// No description provided for @chatGeneralAnswer.
  ///
  /// In ru, this message translates to:
  /// **'Ответ из знаний ИИ, а не из проверенной базы приложения. Если вопрос о здоровье — уточните у врача.'**
  String get chatGeneralAnswer;

  /// No description provided for @chatEmergency.
  ///
  /// In ru, this message translates to:
  /// **'Вызывайте скорую — 103'**
  String get chatEmergency;

  /// No description provided for @chatEmergencyBody.
  ///
  /// In ru, this message translates to:
  /// **'В вашем вопросе есть признак, при котором нельзя ждать. Я намеренно не передаю такие вопросы ИИ — здесь нужен не совет, а немедленная помощь.'**
  String get chatEmergencyBody;

  /// No description provided for @chatWhatToDo.
  ///
  /// In ru, this message translates to:
  /// **'Что делать до приезда скорой'**
  String get chatWhatToDo;

  /// No description provided for @chatSources.
  ///
  /// In ru, this message translates to:
  /// **'Ответ построен по статьям:'**
  String get chatSources;

  /// No description provided for @chatOpenKb.
  ///
  /// In ru, this message translates to:
  /// **'Открыть базу знаний'**
  String get chatOpenKb;

  /// No description provided for @chatAiOff.
  ///
  /// In ru, this message translates to:
  /// **'ИИ-помощник пока не подключён'**
  String get chatAiOff;

  /// No description provided for @chatAiOffBody.
  ///
  /// In ru, this message translates to:
  /// **'База знаний и проверка тревожных признаков работают без него — они не требуют интернета вообще.'**
  String get chatAiOffBody;

  /// No description provided for @chatAiOffHow.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы включить ИИ, нужно развернуть бесплатный прокси на Cloudflare Workers и пересобрать приложение с его адресом. Инструкция — в файле worker/README.md.'**
  String get chatAiOffHow;

  /// No description provided for @chatSuggestionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'С чего начать'**
  String get chatSuggestionsTitle;

  /// No description provided for @askTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Температура {value} — что делать и когда звонить врачу'**
  String askTemperature(String value);

  /// No description provided for @askWhyTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня вы отметили {value}'**
  String askWhyTemperature(String value);

  /// No description provided for @askHardNight.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{Ребёнок просыпался {n} раз за ночь — что можно сделать} few{Ребёнок просыпался {n} раза за ночь — что можно сделать} many{Ребёнок просыпался {n} раз за ночь — что можно сделать} other{Ребёнок просыпался {n} раза за ночь — что можно сделать}}'**
  String askHardNight(int n);

  /// No description provided for @askWhyHardNight.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{Прошлой ночью {n} пробуждение} few{Прошлой ночью {n} пробуждения} many{Прошлой ночью {n} пробуждений} other{Прошлой ночью {n} пробуждения}}'**
  String askWhyHardNight(int n);

  /// No description provided for @askQuietNappies.
  ///
  /// In ru, this message translates to:
  /// **'Ребёнок давно не какал — когда это повод беспокоиться'**
  String get askQuietNappies;

  /// No description provided for @askWhyQuietNappies.
  ///
  /// In ru, this message translates to:
  /// **'Подгузник не отмечали больше суток'**
  String get askWhyQuietNappies;

  /// No description provided for @askNewbornFeeding.
  ///
  /// In ru, this message translates to:
  /// **'Как понять, что новорождённый наедается'**
  String get askNewbornFeeding;

  /// No description provided for @askSleepNeeds.
  ///
  /// In ru, this message translates to:
  /// **'Сколько сна нужно ребёнку в этом возрасте'**
  String get askSleepNeeds;

  /// No description provided for @askSolids.
  ///
  /// In ru, this message translates to:
  /// **'Когда начинать прикорм и с чего'**
  String get askSolids;

  /// No description provided for @askMilestones.
  ///
  /// In ru, this message translates to:
  /// **'Что ребёнок обычно умеет в этом возрасте'**
  String get askMilestones;

  /// No description provided for @askWhyAge.
  ///
  /// In ru, this message translates to:
  /// **'По возрасту малыша'**
  String get askWhyAge;

  /// No description provided for @chatSuggestionsHint.
  ///
  /// In ru, this message translates to:
  /// **'Собрано из ваших записей'**
  String get chatSuggestionsHint;

  /// No description provided for @chatSuggestion1.
  ///
  /// In ru, this message translates to:
  /// **'Температура 38.5, что делать'**
  String get chatSuggestion1;

  /// No description provided for @chatSuggestion2.
  ///
  /// In ru, this message translates to:
  /// **'Составь список покупок на неделю'**
  String get chatSuggestion2;

  /// No description provided for @chatSuggestion3.
  ///
  /// In ru, this message translates to:
  /// **'Напиши поздравление бабушке на юбилей'**
  String get chatSuggestion3;

  /// No description provided for @chatSuggestion4.
  ///
  /// In ru, this message translates to:
  /// **'Можно ли мне антибиотик при ГВ'**
  String get chatSuggestion4;

  /// No description provided for @chatSuggestion5.
  ///
  /// In ru, this message translates to:
  /// **'Ребёнок не какал два дня'**
  String get chatSuggestion5;

  /// No description provided for @actionSuggested.
  ///
  /// In ru, this message translates to:
  /// **'Помощник предлагает'**
  String get actionSuggested;

  /// No description provided for @actionConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get actionConfirm;

  /// No description provided for @actionDismiss.
  ///
  /// In ru, this message translates to:
  /// **'Не надо'**
  String get actionDismiss;

  /// No description provided for @actionReadOnly.
  ///
  /// In ru, this message translates to:
  /// **'У вас доступ только для просмотра — записать может родитель, который вас пригласил.'**
  String get actionReadOnly;

  /// No description provided for @actionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить'**
  String get actionFailed;

  /// No description provided for @actionWrite.
  ///
  /// In ru, this message translates to:
  /// **'Записать: {what}'**
  String actionWrite(String what);

  /// No description provided for @actionCreateReminder.
  ///
  /// In ru, this message translates to:
  /// **'Создать напоминание «{title}» — {when}'**
  String actionCreateReminder(String title, String when);

  /// No description provided for @actionOpenScreen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть раздел «{screen}»'**
  String actionOpenScreen(String screen);

  /// No description provided for @actionOpenArticle.
  ///
  /// In ru, this message translates to:
  /// **'Открыть статью «{title}»'**
  String actionOpenArticle(String title);

  /// No description provided for @actionBuildReport.
  ///
  /// In ru, this message translates to:
  /// **'Собрать PDF-отчёт для врача'**
  String get actionBuildReport;

  /// No description provided for @actionStartTimer.
  ///
  /// In ru, this message translates to:
  /// **'Засечь время'**
  String get actionStartTimer;

  /// No description provided for @actionStopTimer.
  ///
  /// In ru, this message translates to:
  /// **'Остановить таймер и записать'**
  String get actionStopTimer;

  /// No description provided for @triageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверка тревожных признаков'**
  String get triageTitle;

  /// No description provided for @triageNeedChild.
  ///
  /// In ru, this message translates to:
  /// **'Нужен профиль ребёнка'**
  String get triageNeedChild;

  /// No description provided for @triageNeedChildHint.
  ///
  /// In ru, this message translates to:
  /// **'Возраст влияет на оценку — особенно до 3 месяцев'**
  String get triageNeedChildHint;

  /// No description provided for @triageNeedChildAction.
  ///
  /// In ru, this message translates to:
  /// **'Создайте профиль в разделе «Дети»'**
  String get triageNeedChildAction;

  /// No description provided for @triageTemperatureHint.
  ///
  /// In ru, this message translates to:
  /// **'Если измеряли — введите, например 38.5'**
  String get triageTemperatureHint;

  /// No description provided for @triageCheckAll.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте всё, что есть'**
  String get triageCheckAll;

  /// No description provided for @triageEvaluate.
  ///
  /// In ru, this message translates to:
  /// **'Оценить состояние'**
  String get triageEvaluate;

  /// No description provided for @triageRestart.
  ///
  /// In ru, this message translates to:
  /// **'Начать заново'**
  String get triageRestart;

  /// No description provided for @triageConsidered.
  ///
  /// In ru, this message translates to:
  /// **'Что учтено:'**
  String get triageConsidered;

  /// No description provided for @triageDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Это не диагноз. Оценка построена по формальным признакам и не заменяет осмотр. Если вам тревожно, а проверка показала «наблюдать дома» — всё равно обратитесь к врачу.'**
  String get triageDisclaimer;

  /// No description provided for @articleNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Статья не найдена'**
  String get articleNotFound;

  /// No description provided for @articleNotFoundBody.
  ///
  /// In ru, this message translates to:
  /// **'Такой статьи в базе нет'**
  String get articleNotFoundBody;

  /// No description provided for @articleToList.
  ///
  /// In ru, this message translates to:
  /// **'К списку тем'**
  String get articleToList;

  /// No description provided for @articleEmergency.
  ///
  /// In ru, this message translates to:
  /// **'Скорая помощь — 103'**
  String get articleEmergency;

  /// No description provided for @articleWhatToDo.
  ///
  /// In ru, this message translates to:
  /// **'Что делать сейчас'**
  String get articleWhatToDo;

  /// No description provided for @articleWhenDoctor.
  ///
  /// In ru, this message translates to:
  /// **'Когда обратиться к врачу'**
  String get articleWhenDoctor;

  /// No description provided for @articleSources.
  ///
  /// In ru, this message translates to:
  /// **'Источники'**
  String get articleSources;

  /// No description provided for @articleDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Это справочная информация, а не диагноз и не назначение. Если что-то беспокоит — обратитесь к педиатру. При тревожных признаках звоните 103.'**
  String get articleDisclaimer;

  /// No description provided for @settingsParent.
  ///
  /// In ru, this message translates to:
  /// **'Родитель'**
  String get settingsParent;

  /// No description provided for @settingsYourName.
  ///
  /// In ru, this message translates to:
  /// **'Как вас зовут'**
  String get settingsYourName;

  /// No description provided for @settingsUnits.
  ///
  /// In ru, this message translates to:
  /// **'Единицы измерения'**
  String get settingsUnits;

  /// No description provided for @settingsUnitsHint.
  ///
  /// In ru, this message translates to:
  /// **'Метрическая — сантиметры и килограммы, имперская — дюймы и фунты. Измерения всегда хранятся в метрических единицах и пересчитываются только для показа, поэтому переключение ничего не портит в уже введённых данных.'**
  String get settingsUnitsHint;

  /// No description provided for @settingsTemperatureHint.
  ///
  /// In ru, this message translates to:
  /// **'Температура остаётся в °C в обеих системах: все пороги в приложении и в рекомендациях указаны в градусах Цельсия.'**
  String get settingsTemperatureHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingsAppearance;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAbout;

  /// No description provided for @settingsAuthor.
  ///
  /// In ru, this message translates to:
  /// **'Разработчик'**
  String get settingsAuthor;

  /// No description provided for @settingsVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get settingsVersion;

  /// No description provided for @settingsDeleteSection.
  ///
  /// In ru, this message translates to:
  /// **'Удаление учётной записи'**
  String get settingsDeleteSection;

  /// No description provided for @settingsDeleteWarning.
  ///
  /// In ru, this message translates to:
  /// **'Вместе с записью безвозвратно удаляются все дети, дневник, медкарта и напоминания. Отменить это будет нельзя, поэтому сначала выгрузите PDF-отчёт, если он вам нужен.'**
  String get settingsDeleteWarning;

  /// No description provided for @settingsChangeButton.
  ///
  /// In ru, this message translates to:
  /// **'Сменить'**
  String get settingsChangeButton;

  /// No description provided for @growthVerdictSeverelyLow.
  ///
  /// In ru, this message translates to:
  /// **'Значительно ниже нормы'**
  String get growthVerdictSeverelyLow;

  /// No description provided for @growthVerdictLow.
  ///
  /// In ru, this message translates to:
  /// **'Ниже нормы'**
  String get growthVerdictLow;

  /// No description provided for @growthVerdictNormal.
  ///
  /// In ru, this message translates to:
  /// **'В пределах нормы'**
  String get growthVerdictNormal;

  /// No description provided for @growthVerdictHigh.
  ///
  /// In ru, this message translates to:
  /// **'Выше нормы'**
  String get growthVerdictHigh;

  /// No description provided for @growthVerdictSeverelyHigh.
  ///
  /// In ru, this message translates to:
  /// **'Значительно выше нормы'**
  String get growthVerdictSeverelyHigh;

  /// No description provided for @growthMetricWithDate.
  ///
  /// In ru, this message translates to:
  /// **'{metric}, {date}'**
  String growthMetricWithDate(String metric, String date);

  /// No description provided for @medicalAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить запись'**
  String get medicalAdd;

  /// No description provided for @photoNotAnImage.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать изображение. Поддерживаются JPG, PNG и WebP.'**
  String get photoNotAnImage;

  /// No description provided for @photoStillTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Изображение слишком большое даже после сжатия. Попробуйте снять кадр ближе или обрезать его.'**
  String get photoStillTooLarge;

  /// No description provided for @nowLastFeeding.
  ///
  /// In ru, this message translates to:
  /// **'Последнее кормление'**
  String get nowLastFeeding;

  /// No description provided for @nowLastSleep.
  ///
  /// In ru, this message translates to:
  /// **'Последний сон'**
  String get nowLastSleep;

  /// No description provided for @nowNothingYet.
  ///
  /// In ru, this message translates to:
  /// **'пока нет'**
  String get nowNothingYet;

  /// No description provided for @nowAgo.
  ///
  /// In ru, this message translates to:
  /// **'{duration} назад'**
  String nowAgo(String duration);

  /// No description provided for @suggestionAfterSleep.
  ///
  /// In ru, this message translates to:
  /// **'Часто после сна бывает кормление'**
  String get suggestionAfterSleep;

  /// No description provided for @suggestionNappy.
  ///
  /// In ru, this message translates to:
  /// **'Давно не отмечали подгузник'**
  String get suggestionNappy;

  /// No description provided for @suggestionDismiss.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get suggestionDismiss;

  /// No description provided for @reflectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get reflectionTitle;

  /// No description provided for @reflectionFeedingsCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} кормление} few{{n} кормления} many{{n} кормлений} other{{n} кормления}}'**
  String reflectionFeedingsCount(int n);

  /// No description provided for @reflectionSummary.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня: {feedings} и {sleep} сна. Это помогает видеть картину дня, не считая в уме.'**
  String reflectionSummary(String feedings, String sleep);

  /// No description provided for @reflectionSummaryNoSleep.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня: {feedings}. Сон за день никто не отмечал.'**
  String reflectionSummaryNoSleep(String feedings);

  /// No description provided for @reflectionSupport.
  ///
  /// In ru, this message translates to:
  /// **'Вы записали все важные события дня. Это уже большая помощь себе и ребёнку.'**
  String get reflectionSupport;

  /// No description provided for @reflectionNappies.
  ///
  /// In ru, this message translates to:
  /// **'подгузников'**
  String get reflectionNappies;

  /// No description provided for @patternSleepThenFeeding.
  ///
  /// In ru, this message translates to:
  /// **'Похоже, после дневного сна кормление обычно появляется через 20–40 минут.'**
  String get patternSleepThenFeeding;

  /// No description provided for @patternNightStart.
  ///
  /// In ru, this message translates to:
  /// **'Ночной сон чаще всего начинается около {time}.'**
  String patternNightStart(String time);

  /// No description provided for @patternStableSleep.
  ///
  /// In ru, this message translates to:
  /// **'Суммарный сон последние дни остаётся примерно одинаковым.'**
  String get patternStableSleep;

  /// No description provided for @contextTitle.
  ///
  /// In ru, this message translates to:
  /// **'Контекст ребёнка'**
  String get contextTitle;

  /// No description provided for @contextNotRecorded.
  ///
  /// In ru, this message translates to:
  /// **'Не отмечалась'**
  String get contextNotRecorded;

  /// No description provided for @chatContinueTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить разговор'**
  String get chatContinueTitle;

  /// No description provided for @chatContinueLast.
  ///
  /// In ru, this message translates to:
  /// **'Последний вопрос: «{question}»'**
  String chatContinueLast(String question);

  /// No description provided for @chatContinueResume.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get chatContinueResume;

  /// No description provided for @chatContinueNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый'**
  String get chatContinueNew;

  /// No description provided for @checkInTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как вы себя чувствуете?'**
  String get checkInTitle;

  /// No description provided for @checkInHoldingUp.
  ///
  /// In ru, this message translates to:
  /// **'Держусь'**
  String get checkInHoldingUp;

  /// No description provided for @checkInTired.
  ///
  /// In ru, this message translates to:
  /// **'Устала'**
  String get checkInTired;

  /// No description provided for @checkInVeryHard.
  ///
  /// In ru, this message translates to:
  /// **'Очень тяжело'**
  String get checkInVeryHard;

  /// No description provided for @checkInReplyHoldingUp.
  ///
  /// In ru, this message translates to:
  /// **'Пусть сегодня у вас найдётся хотя бы один спокойный момент для себя.'**
  String get checkInReplyHoldingUp;

  /// No description provided for @checkInReplyTired.
  ///
  /// In ru, this message translates to:
  /// **'Усталость после тяжёлой ночи очень понятна. Постарайтесь опираться на самое важное, а не на идеальный порядок.'**
  String get checkInReplyTired;

  /// No description provided for @checkInReplyVeryHard.
  ///
  /// In ru, this message translates to:
  /// **'Если есть возможность, попросите кого-то побыть рядом хотя бы ненадолго. Забота о себе — тоже часть заботы о ребёнке.'**
  String get checkInReplyVeryHard;

  /// No description provided for @vaccineHepB1.
  ///
  /// In ru, this message translates to:
  /// **'Гепатит B (ВГВ) — первая доза'**
  String get vaccineHepB1;

  /// No description provided for @vaccineNoteHepB1.
  ///
  /// In ru, this message translates to:
  /// **'В первые сутки жизни'**
  String get vaccineNoteHepB1;

  /// No description provided for @vaccineBcg.
  ///
  /// In ru, this message translates to:
  /// **'Туберкулёз (БЦЖ)'**
  String get vaccineBcg;

  /// No description provided for @vaccineNoteBcg.
  ///
  /// In ru, this message translates to:
  /// **'На 1-4 сутки жизни'**
  String get vaccineNoteBcg;

  /// No description provided for @vaccinePenta1.
  ///
  /// In ru, this message translates to:
  /// **'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — первая доза'**
  String get vaccinePenta1;

  /// No description provided for @vaccineNotePenta1.
  ///
  /// In ru, this message translates to:
  /// **'Коклюш, дифтерия, столбняк, гемофильная инфекция, гепатит B, полиомиелит'**
  String get vaccineNotePenta1;

  /// No description provided for @vaccinePcv1.
  ///
  /// In ru, this message translates to:
  /// **'Пневмококковая инфекция (ПНВ) — первая доза'**
  String get vaccinePcv1;

  /// No description provided for @vaccinePenta2.
  ///
  /// In ru, this message translates to:
  /// **'АбКДС + Хиб + ИПВ — вторая доза'**
  String get vaccinePenta2;

  /// No description provided for @vaccinePenta3.
  ///
  /// In ru, this message translates to:
  /// **'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — третья доза'**
  String get vaccinePenta3;

  /// No description provided for @vaccinePcv2.
  ///
  /// In ru, this message translates to:
  /// **'Пневмококковая инфекция (ПНВ) — вторая доза'**
  String get vaccinePcv2;

  /// No description provided for @vaccineMmr1.
  ///
  /// In ru, this message translates to:
  /// **'Корь, краснуха, паротит (ККП) — первая доза'**
  String get vaccineMmr1;

  /// No description provided for @vaccineNoteMmr1.
  ///
  /// In ru, this message translates to:
  /// **'В 12-15 месяцев'**
  String get vaccineNoteMmr1;

  /// No description provided for @vaccinePcvBooster.
  ///
  /// In ru, this message translates to:
  /// **'Пневмококковая инфекция (ПНВ) — ревакцинация'**
  String get vaccinePcvBooster;

  /// No description provided for @vaccineOpv.
  ///
  /// In ru, this message translates to:
  /// **'Полиомиелит (ОПВ)'**
  String get vaccineOpv;

  /// No description provided for @vaccinePentaBooster.
  ///
  /// In ru, this message translates to:
  /// **'АбКДС + Хиб + ИПВ — ревакцинация'**
  String get vaccinePentaBooster;

  /// No description provided for @vaccineNotePentaBooster.
  ///
  /// In ru, this message translates to:
  /// **'В 18 месяцев'**
  String get vaccineNotePentaBooster;

  /// No description provided for @vaccineHepA1.
  ///
  /// In ru, this message translates to:
  /// **'Гепатит A (ВГА) — первая доза'**
  String get vaccineHepA1;

  /// No description provided for @vaccineNoteHepA1.
  ///
  /// In ru, this message translates to:
  /// **'В 2 года'**
  String get vaccineNoteHepA1;

  /// No description provided for @vaccineHepA2.
  ///
  /// In ru, this message translates to:
  /// **'Гепатит A (ВГА) — вторая доза'**
  String get vaccineHepA2;

  /// No description provided for @vaccineNoteHepA2.
  ///
  /// In ru, this message translates to:
  /// **'Через 6 месяцев'**
  String get vaccineNoteHepA2;

  /// No description provided for @vaccineDtapBooster.
  ///
  /// In ru, this message translates to:
  /// **'АбКДС — ревакцинация'**
  String get vaccineDtapBooster;

  /// No description provided for @vaccineNoteDtapBooster.
  ///
  /// In ru, this message translates to:
  /// **'В 6 лет, перед школой'**
  String get vaccineNoteDtapBooster;

  /// No description provided for @vaccineMmr2.
  ///
  /// In ru, this message translates to:
  /// **'Корь, краснуха, паротит (ККП) — вторая доза'**
  String get vaccineMmr2;

  /// No description provided for @vaccineHpv1.
  ///
  /// In ru, this message translates to:
  /// **'ВПЧ — первая доза (девочки)'**
  String get vaccineHpv1;

  /// No description provided for @vaccineNoteHpv1.
  ///
  /// In ru, this message translates to:
  /// **'В 11 лет, по согласию родителей'**
  String get vaccineNoteHpv1;

  /// No description provided for @vaccineHpv2.
  ///
  /// In ru, this message translates to:
  /// **'ВПЧ — вторая доза (девочки)'**
  String get vaccineHpv2;

  /// No description provided for @vaccineNoteHpv2.
  ///
  /// In ru, this message translates to:
  /// **'Через 6 месяцев'**
  String get vaccineNoteHpv2;

  /// No description provided for @vaccineTdBooster.
  ///
  /// In ru, this message translates to:
  /// **'АДС-М — ревакцинация'**
  String get vaccineTdBooster;

  /// No description provided for @vaccineNoteTdBooster.
  ///
  /// In ru, this message translates to:
  /// **'В 16 лет, далее каждые 10 лет'**
  String get vaccineNoteTdBooster;

  /// No description provided for @vaccineSource.
  ///
  /// In ru, this message translates to:
  /// **'Календарь прививок РК'**
  String get vaccineSource;

  /// No description provided for @reportExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт PDF'**
  String get reportExport;

  /// No description provided for @reportPeriodDays.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} день} few{{n} дня} many{{n} дней} other{{n} дня}}'**
  String reportPeriodDays(int n);

  /// No description provided for @reportPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Период отчёта'**
  String get reportPeriod;

  /// No description provided for @reportRange.
  ///
  /// In ru, this message translates to:
  /// **'{from} — {to}'**
  String reportRange(String from, String to);

  /// No description provided for @reportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт для врача'**
  String get reportTitle;

  /// No description provided for @reportNothing.
  ///
  /// In ru, this message translates to:
  /// **'За этот период записей нет'**
  String get reportNothing;

  /// No description provided for @reportPreparing.
  ///
  /// In ru, this message translates to:
  /// **'Готовим PDF…'**
  String get reportPreparing;

  /// No description provided for @reportReady.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт готов'**
  String get reportReady;

  /// No description provided for @reportShareFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть отчёт'**
  String get reportShareFailed;

  /// No description provided for @reportSectionSleep.
  ///
  /// In ru, this message translates to:
  /// **'Сон'**
  String get reportSectionSleep;

  /// No description provided for @reportAvgNight.
  ///
  /// In ru, this message translates to:
  /// **'Средний ночной сон'**
  String get reportAvgNight;

  /// No description provided for @reportAvgDay.
  ///
  /// In ru, this message translates to:
  /// **'Средний дневной сон'**
  String get reportAvgDay;

  /// No description provided for @reportAvgWakings.
  ///
  /// In ru, this message translates to:
  /// **'Среднее число пробуждений'**
  String get reportAvgWakings;

  /// No description provided for @reportSectionFeeding.
  ///
  /// In ru, this message translates to:
  /// **'Кормление'**
  String get reportSectionFeeding;

  /// No description provided for @reportFeedingsTotal.
  ///
  /// In ru, this message translates to:
  /// **'Всего кормлений'**
  String get reportFeedingsTotal;

  /// No description provided for @reportBreast.
  ///
  /// In ru, this message translates to:
  /// **'Грудь'**
  String get reportBreast;

  /// No description provided for @reportBottle.
  ///
  /// In ru, this message translates to:
  /// **'Бутылочка'**
  String get reportBottle;

  /// No description provided for @reportSectionNappies.
  ///
  /// In ru, this message translates to:
  /// **'Подгузники'**
  String get reportSectionNappies;

  /// No description provided for @reportSectionTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Температура'**
  String get reportSectionTemperature;

  /// No description provided for @reportTempMax.
  ///
  /// In ru, this message translates to:
  /// **'Максимум'**
  String get reportTempMax;

  /// No description provided for @reportTempMin.
  ///
  /// In ru, this message translates to:
  /// **'Минимум'**
  String get reportTempMin;

  /// No description provided for @reportTempCount.
  ///
  /// In ru, this message translates to:
  /// **'Измерений'**
  String get reportTempCount;

  /// No description provided for @reportSectionMedicines.
  ///
  /// In ru, this message translates to:
  /// **'Лекарства'**
  String get reportSectionMedicines;

  /// No description provided for @reportSectionNotes.
  ///
  /// In ru, this message translates to:
  /// **'Заметки'**
  String get reportSectionNotes;

  /// No description provided for @reportFoodName.
  ///
  /// In ru, this message translates to:
  /// **'Продукт'**
  String get reportFoodName;

  /// No description provided for @reportFoodFirst.
  ///
  /// In ru, this message translates to:
  /// **'Впервые'**
  String get reportFoodFirst;

  /// No description provided for @reportFoodTimes.
  ///
  /// In ru, this message translates to:
  /// **'Раз'**
  String get reportFoodTimes;

  /// No description provided for @reportFoodReaction.
  ///
  /// In ru, this message translates to:
  /// **'Что было после'**
  String get reportFoodReaction;

  /// No description provided for @reportSectionQuestions.
  ///
  /// In ru, this message translates to:
  /// **'Вопросы врачу'**
  String get reportSectionQuestions;

  /// No description provided for @reportQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос'**
  String get reportQuestion;

  /// No description provided for @reportAnswer.
  ///
  /// In ru, this message translates to:
  /// **'Ответ врача'**
  String get reportAnswer;

  /// No description provided for @importTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перенос из другого приложения'**
  String get importTitle;

  /// No description provided for @importPickTitle.
  ///
  /// In ru, this message translates to:
  /// **'Файл с записями'**
  String get importPickTitle;

  /// No description provided for @importHint.
  ///
  /// In ru, this message translates to:
  /// **'Выгрузите записи из прежнего приложения и выберите файл здесь. Ничего не запишется, пока вы не подтвердите — сначала покажу, что нашлось.'**
  String get importHint;

  /// No description provided for @importFormats.
  ///
  /// In ru, this message translates to:
  /// **'Подойдёт CSV или текстовый файл с колонками: дата, время, тип записи, длительность, комментарий'**
  String get importFormats;

  /// No description provided for @importPickButton.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать файл'**
  String get importPickButton;

  /// No description provided for @importFoundTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что нашлось'**
  String get importFoundTitle;

  /// No description provided for @importColumns.
  ///
  /// In ru, this message translates to:
  /// **'Как поняты колонки'**
  String get importColumns;

  /// No description provided for @importSkipped.
  ///
  /// In ru, this message translates to:
  /// **'Строк пропущено: {n}'**
  String importSkipped(int n);

  /// No description provided for @importNothingFound.
  ///
  /// In ru, this message translates to:
  /// **'В файле не нашлось ни одной записи с датой'**
  String get importNothingFound;

  /// No description provided for @importWriteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перенести в дневник'**
  String get importWriteTitle;

  /// No description provided for @importWriteHint.
  ///
  /// In ru, this message translates to:
  /// **'Будет добавлено записей: {n}. Они появятся в дневнике своими датами.'**
  String importWriteHint(int n);

  /// No description provided for @importWriteButton.
  ///
  /// In ru, this message translates to:
  /// **'Перенести {n}'**
  String importWriteButton(int n);

  /// No description provided for @importDone.
  ///
  /// In ru, this message translates to:
  /// **'Перенесено записей: {n}'**
  String importDone(int n);

  /// No description provided for @importRoleDate.
  ///
  /// In ru, this message translates to:
  /// **'дата'**
  String get importRoleDate;

  /// No description provided for @importRoleTime.
  ///
  /// In ru, this message translates to:
  /// **'время'**
  String get importRoleTime;

  /// No description provided for @importRoleKind.
  ///
  /// In ru, this message translates to:
  /// **'тип записи'**
  String get importRoleKind;

  /// No description provided for @importRoleDuration.
  ///
  /// In ru, this message translates to:
  /// **'длительность'**
  String get importRoleDuration;

  /// No description provided for @importRoleAmount.
  ///
  /// In ru, this message translates to:
  /// **'объём'**
  String get importRoleAmount;

  /// No description provided for @importRoleNote.
  ///
  /// In ru, this message translates to:
  /// **'комментарий'**
  String get importRoleNote;

  /// No description provided for @importRoleIgnored.
  ///
  /// In ru, this message translates to:
  /// **'не используется'**
  String get importRoleIgnored;

  /// No description provided for @settingsImport.
  ///
  /// In ru, this message translates to:
  /// **'Перенести данные'**
  String get settingsImport;

  /// No description provided for @settingsImportHint.
  ///
  /// In ru, this message translates to:
  /// **'Из другого дневника — по файлу выгрузки'**
  String get settingsImportHint;

  /// No description provided for @teethDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Сроки — средние по педиатрическим таблицам, а не мерка для конкретного ребёнка. Если что-то беспокоит — спросите педиатра или стоматолога.'**
  String get teethDisclaimer;

  /// No description provided for @teethTitle.
  ///
  /// In ru, this message translates to:
  /// **'Зубы'**
  String get teethTitle;

  /// No description provided for @teethCount.
  ///
  /// In ru, this message translates to:
  /// **'Прорезалось {n} из 20'**
  String teethCount(int n);

  /// No description provided for @teethNone.
  ///
  /// In ru, this message translates to:
  /// **'Пока ни одного'**
  String get teethNone;

  /// No description provided for @teethUsual.
  ///
  /// In ru, this message translates to:
  /// **'В этом возрасте обычно {from}–{to}'**
  String teethUsual(int from, int to);

  /// No description provided for @teethNext.
  ///
  /// In ru, this message translates to:
  /// **'Дальше обычно — {tooth}'**
  String teethNext(String tooth);

  /// No description provided for @teethLegendThrough.
  ///
  /// In ru, this message translates to:
  /// **'прорезался'**
  String get teethLegendThrough;

  /// No description provided for @teethLegendNotYet.
  ///
  /// In ru, this message translates to:
  /// **'ещё нет'**
  String get teethLegendNotYet;

  /// No description provided for @teethLegendAge.
  ///
  /// In ru, this message translates to:
  /// **'цифра — возраст в месяцах'**
  String get teethLegendAge;

  /// No description provided for @teethHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на зуб, когда он прорежется'**
  String get teethHint;

  /// No description provided for @teethWhen.
  ///
  /// In ru, this message translates to:
  /// **'Когда прорезался?'**
  String get teethWhen;

  /// No description provided for @teethToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get teethToday;

  /// No description provided for @teethYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get teethYesterday;

  /// No description provided for @teethPickDate.
  ///
  /// In ru, this message translates to:
  /// **'Другая дата'**
  String get teethPickDate;

  /// No description provided for @teethUnmarked.
  ///
  /// In ru, this message translates to:
  /// **'Отметка убрана'**
  String get teethUnmarked;

  /// No description provided for @teethRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать отметку'**
  String get teethRemove;

  /// No description provided for @teethMarked.
  ///
  /// In ru, this message translates to:
  /// **'{tooth} — отмечен'**
  String teethMarked(String tooth);

  /// No description provided for @teethAtAge.
  ///
  /// In ru, this message translates to:
  /// **'в {months} мес.'**
  String teethAtAge(int months);

  /// No description provided for @teethExpected.
  ///
  /// In ru, this message translates to:
  /// **'Обычно {from}–{to} мес.'**
  String teethExpected(int from, int to);

  /// No description provided for @teethUpperJaw.
  ///
  /// In ru, this message translates to:
  /// **'Верхние'**
  String get teethUpperJaw;

  /// No description provided for @teethLowerJaw.
  ///
  /// In ru, this message translates to:
  /// **'Нижние'**
  String get teethLowerJaw;

  /// No description provided for @toothName.
  ///
  /// In ru, this message translates to:
  /// **'{jaw} {type}, {side}'**
  String toothName(String jaw, String type, String side);

  /// No description provided for @toothCentralIncisor.
  ///
  /// In ru, this message translates to:
  /// **'центральный резец'**
  String get toothCentralIncisor;

  /// No description provided for @toothLateralIncisor.
  ///
  /// In ru, this message translates to:
  /// **'боковой резец'**
  String get toothLateralIncisor;

  /// No description provided for @toothCanine.
  ///
  /// In ru, this message translates to:
  /// **'клык'**
  String get toothCanine;

  /// No description provided for @toothFirstMolar.
  ///
  /// In ru, this message translates to:
  /// **'первый моляр'**
  String get toothFirstMolar;

  /// No description provided for @toothSecondMolar.
  ///
  /// In ru, this message translates to:
  /// **'второй моляр'**
  String get toothSecondMolar;

  /// No description provided for @toothUpper.
  ///
  /// In ru, this message translates to:
  /// **'Верхний'**
  String get toothUpper;

  /// No description provided for @toothLower.
  ///
  /// In ru, this message translates to:
  /// **'Нижний'**
  String get toothLower;

  /// No description provided for @toothLeft.
  ///
  /// In ru, this message translates to:
  /// **'слева'**
  String get toothLeft;

  /// No description provided for @toothRight.
  ///
  /// In ru, this message translates to:
  /// **'справа'**
  String get toothRight;

  /// No description provided for @visitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подготовка к приёму'**
  String get visitTitle;

  /// No description provided for @visitCardHint.
  ///
  /// In ru, this message translates to:
  /// **'Вопросы, прививки, прикорм и что было с прошлого раза — на одном экране'**
  String get visitCardHint;

  /// No description provided for @visitOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get visitOpen;

  /// No description provided for @visitQuestionsWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Записано вопросов: {n}'**
  String visitQuestionsWaiting(int n);

  /// No description provided for @visitMeasureTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вес и рост'**
  String get visitMeasureTitle;

  /// No description provided for @visitMeasuredAt.
  ///
  /// In ru, this message translates to:
  /// **'Измеряли {date} — {days} дн. назад'**
  String visitMeasuredAt(String date, int days);

  /// No description provided for @visitMeasureNone.
  ///
  /// In ru, this message translates to:
  /// **'Измерений ещё нет'**
  String get visitMeasureNone;

  /// No description provided for @visitVaccinesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Прививки'**
  String get visitVaccinesTitle;

  /// No description provided for @visitVaccinesNone.
  ///
  /// In ru, this message translates to:
  /// **'На ближайшие две недели ничего не запланировано'**
  String get visitVaccinesNone;

  /// No description provided for @visitVaccineDue.
  ///
  /// In ru, this message translates to:
  /// **'{name} — {date}'**
  String visitVaccineDue(String name, String date);

  /// No description provided for @visitVaccineOverdue.
  ///
  /// In ru, this message translates to:
  /// **'{name} — срок был {date}'**
  String visitVaccineOverdue(String name, String date);

  /// No description provided for @visitFoodsNew.
  ///
  /// In ru, this message translates to:
  /// **'Новых продуктов за этот период: {n}'**
  String visitFoodsNew(int n);

  /// No description provided for @visitHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что было'**
  String get visitHistoryTitle;

  /// No description provided for @visitSinceVisit.
  ///
  /// In ru, this message translates to:
  /// **'С приёма {date}'**
  String visitSinceVisit(String date);

  /// No description provided for @visitSinceDays.
  ///
  /// In ru, this message translates to:
  /// **'За последние {days} дн.'**
  String visitSinceDays(int days);

  /// No description provided for @visitHistoryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'За это время записей о болезни, температуре и лекарствах нет'**
  String get visitHistoryEmpty;

  /// No description provided for @visitSickDays.
  ///
  /// In ru, this message translates to:
  /// **'Дней с болезнью: {n}'**
  String visitSickDays(int n);

  /// No description provided for @visitMaxTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Максимальная температура: {value} °C'**
  String visitMaxTemperature(String value);

  /// No description provided for @visitMedicines.
  ///
  /// In ru, this message translates to:
  /// **'Записей о лекарствах: {n}'**
  String visitMedicines(int n);

  /// No description provided for @visitTakeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Взять с собой'**
  String get visitTakeTitle;

  /// No description provided for @visitTakeHint.
  ///
  /// In ru, this message translates to:
  /// **'Один лист: цифры за период, прикорм и ваши вопросы с местом для ответов врача.'**
  String get visitTakeHint;

  /// No description provided for @reportDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт предназначен для удобства обсуждения с врачом и не является медицинским заключением.'**
  String get reportDisclaimer;

  /// No description provided for @reportPage.
  ///
  /// In ru, this message translates to:
  /// **'Страница {page} из {total}'**
  String reportPage(int page, int total);
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
