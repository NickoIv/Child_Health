// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Child development and health calendar';

  @override
  String get navDashboard => 'Overview';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navDiary => 'Diary';

  @override
  String get navGrowth => 'Growth';

  @override
  String get navIllness => 'Illness';

  @override
  String get navMedical => 'Records';

  @override
  String get navReminders => 'Reminders';

  @override
  String get navChildren => 'Children';

  @override
  String get navFamily => 'Family';

  @override
  String get navMore => 'More';

  @override
  String get navAsk => 'AI';

  @override
  String get navPhotos => 'Photos';

  @override
  String get navGroupHealth => 'Health';

  @override
  String get navGroupMemory => 'Memories';

  @override
  String get navGroupProfile => 'Profile';

  @override
  String get navGrowthHint => 'Weight, height and WHO percentiles';

  @override
  String get navIllnessHint => 'Sick days and temperature';

  @override
  String get navMedicalHint => 'Vaccines, visits, a report for the doctor';

  @override
  String get navRemindersHint => 'Medicines and the vaccination calendar';

  @override
  String get navPhotosHint => 'The album and the week\'s story';

  @override
  String get navChildrenHint => 'Who is in the app';

  @override
  String get navSettingsHint => 'Language, theme, units, access';

  @override
  String get photosAdd => 'Add a photo';

  @override
  String get photosEdit => 'Edit photo';

  @override
  String get photosWhen => 'When it was taken';

  @override
  String get photosAbout => 'What is here';

  @override
  String get photosAboutHint =>
      '“Sat up on his own for the first time”, for example';

  @override
  String get photosSaved => 'Photo saved';

  @override
  String get photosDeleted => 'Photo deleted';

  @override
  String get photosEmpty => 'Your baby\'s photos will live here';

  @override
  String get photosEmptyHint =>
      'Pictures from diary entries arrive here on their own; add any others with the button below';

  @override
  String photosCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '$n photo',
    );
    return '$_temp0';
  }

  @override
  String get authSignInSubtitle => 'Sign in to continue';

  @override
  String get authRegisterSubtitle => 'Create a parent account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegister => 'Sign up';

  @override
  String get authToRegister => 'No account yet — sign up';

  @override
  String get authToSignIn => 'Already have an account — sign in';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authOr => 'or';

  @override
  String get authWithGoogle => 'Continue with Google';

  @override
  String get authWithApple => 'Continue with Apple';

  @override
  String get authEmailRequired => 'Enter your email';

  @override
  String get authEmailIncomplete => 'That address looks incomplete';

  @override
  String get authPasswordRequired => 'Enter your password';

  @override
  String get authPasswordTooShort => 'At least 6 characters';

  @override
  String get authResetNeedsEmail => 'Enter your email — the link goes there';

  @override
  String authResetSent(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String authUnexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get authErrorInvalidCredentials => 'Wrong email or password';

  @override
  String get authErrorInvalidEmail => 'That email address is not valid';

  @override
  String get authErrorEmailInUse => 'This email is already registered';

  @override
  String get authErrorWeakPassword =>
      'That password is too simple — at least 6 characters';

  @override
  String get authErrorUserDisabled => 'This account has been disabled';

  @override
  String get authErrorRequiresRecentLogin =>
      'This needs a fresh sign-in. Sign out and back in, then try again';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Try again in a few minutes';

  @override
  String get authErrorNetwork =>
      'No connection to the server. Check your internet';

  @override
  String get authErrorOperationNotAllowed =>
      'Email and password sign-in is turned off in the Firebase console';

  @override
  String authErrorUnknown(String code) {
    return 'The operation failed: $code';
  }

  @override
  String get authErrorGoogleNotConfigured =>
      'Google sign-in is not set up for this build of the app';

  @override
  String get authErrorGoogleProvider =>
      'Google cannot verify this app. Please contact support';

  @override
  String get authErrorGoogleInterrupted =>
      'Google sign-in was interrupted. Check your connection and try again';

  @override
  String authErrorGoogleFailed(String detail) {
    return 'Could not sign in with Google: $detail';
  }

  @override
  String get authErrorGoogleNoToken =>
      'Google returned no sign-in token. Please try again';

  @override
  String get authErrorSignInFirst => 'Sign in to your account first';

  @override
  String get authErrorNoPassword =>
      'This account has no password: it signs in through Google. Change the password in your Google account settings';

  @override
  String get authErrorUnknownProvider =>
      'Could not verify who you are: unknown sign-in method. Sign out and back in';

  @override
  String get accountMenu => 'Account';

  @override
  String get settingsTitle => 'Profile and settings';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsNotificationsOff => 'Notifications turned off';

  @override
  String get settingsNotificationsOn => 'Notifications are on';

  @override
  String settingsLocalOnly(String reason) {
    return 'Reminders on this device are on. Push is not available yet: $reason';
  }

  @override
  String get settingsRemindMe => 'Remind me about vaccinations and medicines';

  @override
  String get settingsConnecting => 'Connecting…';

  @override
  String get settingsNotificationsHint =>
      'Works while the app is installed on the home screen or open in a browser. The browser itself asks for permission — if you refuse, it can only be turned back on in its site settings.';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get themeAuto => 'Automatic';

  @override
  String get themeAutoHint => 'Dark from 21:00 to 7:00';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordRepeat => 'New password again';

  @override
  String get passwordCurrentRequired => 'Enter your current password';

  @override
  String get passwordsDoNotMatch => 'The passwords do not match';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountWarning =>
      'Everything about your children will be deleted for good. Neither we nor you will be able to get it back.';

  @override
  String get deleteAccountPassword => 'Your password';

  @override
  String get deleteAccountGoogleNote =>
      'After you confirm, Google will ask you to sign in once more — that is how we check it is really you.';

  @override
  String get deleteAccountWord => 'DELETE';

  @override
  String deleteAccountWriteWord(String word) {
    return 'Type $word';
  }

  @override
  String get deleteAccountConfirm => 'Delete for good';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get notificationChannelName => 'Reminders';

  @override
  String get notificationChannelDescription =>
      'Vaccinations, medicines and doctor visits';

  @override
  String get reminderTypeVaccination => 'Vaccination';

  @override
  String get reminderTypeMedication => 'Medicine';

  @override
  String get reminderTypeAppointment => 'Doctor visit';

  @override
  String get recurrenceNone => 'Once';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceTwiceDaily => 'Twice a day';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get reminderNew => 'New reminder';

  @override
  String get reminderWhat => 'What to remind about';

  @override
  String get reminderNameMedication => 'What to give — say “Nurofen, 2.5 ml”';

  @override
  String get reminderNameAppointment =>
      'Who to see — say “Paediatrician, 9:00”';

  @override
  String get reminderWhen => 'When';

  @override
  String reminderInHours(int h) {
    return 'in $h h';
  }

  @override
  String get reminderTomorrowMorning => 'tomorrow morning';

  @override
  String get reminderExactTime => 'pick a time';

  @override
  String get reminderRepeat => 'Repeat';

  @override
  String reminderSaved(String when) {
    return 'I will remind you $when';
  }

  @override
  String get reminderNameRequired => 'Say what to remind about';

  @override
  String get reminderAdd => 'Reminder';

  @override
  String get reminderDelete => 'Delete reminder';

  @override
  String get reminderDeleted => 'Reminder deleted';

  @override
  String get remindersVaccinations => 'Vaccination schedule';

  @override
  String get remindersMedications => 'Medicines';

  @override
  String get remindersAppointments => 'Doctor visits';

  @override
  String get remindersNothingPlanned => 'Nothing planned';

  @override
  String get remindersShowCompleted => 'Show completed';

  @override
  String get quickFeed => 'Fed';

  @override
  String get quickNappy => 'Nappy';

  @override
  String get quickSleep => 'Slept';

  @override
  String get quickTemperature => 'Temperature';

  @override
  String get quickSheetFeeding => 'Feeding';

  @override
  String get quickSheetNappy => 'Nappy';

  @override
  String get quickSheetSleep => 'How long was the nap';

  @override
  String get quickSheetSleepShort => 'Sleep';

  @override
  String get quickSheetTemperature => 'Temperature';

  @override
  String get quickTimeNow => 'Now';

  @override
  String get quickTimeChoose => 'Pick a time';

  @override
  String get quickNowHint => 'Will be recorded with the current time';

  @override
  String get quickSaveButton => 'Record';

  @override
  String quickSaved(String what) {
    return 'Recorded: $what';
  }

  @override
  String get quickSideLeft => 'Left';

  @override
  String get quickSideRight => 'Right';

  @override
  String get quickSideBottle => 'Bottle';

  @override
  String get quickNappyWet => 'Wet';

  @override
  String get quickNappyDirty => 'Dirty';

  @override
  String get quickNappyBoth => 'Wet and dirty';

  @override
  String get quickSleep30 => 'Half an hour';

  @override
  String get quickSleep60 => 'An hour';

  @override
  String get quickSleep90 => 'An hour and a half';

  @override
  String get quickSleep120 => 'Two hours';

  @override
  String get quickSleep180 => 'Three hours';

  @override
  String get nightModeTitle => 'Night mode';

  @override
  String get nightModeHint =>
      'A deep red screen: it does not wake the baby or cost you your night vision';

  @override
  String get nightModeOff => 'Off';

  @override
  String get nightModeAuto => 'Automatic at night';

  @override
  String get nightModeOn => 'On';

  @override
  String get nightModeAutoHint => 'From 21:00 to 7:00';

  @override
  String get pumpTitle => 'Pumping';

  @override
  String get pumpAction => 'I expressed milk';

  @override
  String get pumpHowMuch => 'How much was expressed';

  @override
  String pumpMl(int n) {
    return '$n ml';
  }

  @override
  String pumpToday(String amount) {
    return 'Expressed today: $amount';
  }

  @override
  String get feedingSolid => 'Solids';

  @override
  String get solidsTitle => 'Solids and reactions';

  @override
  String get logReaction => 'Reaction';

  @override
  String get solidsEmpty => 'No solids recorded yet';

  @override
  String get solidsEmptyHint =>
      'The first spoon is recorded under «Fed» → «Solids»';

  @override
  String get solidWhat => 'What was eaten';

  @override
  String get solidWhatHint => 'Courgette, for example';

  @override
  String solidTimesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n times',
      one: '$n time',
    );
    return '$_temp0';
  }

  @override
  String solidFirstAt(String date) {
    return 'First given $date';
  }

  @override
  String solidWatch(String date) {
    return 'New — watching until $date';
  }

  @override
  String get solidWatchHint =>
      'Three days before the next new food, so a reaction has one cause';

  @override
  String get solidReactionAdd => 'There was a reaction';

  @override
  String solidReactionTitle(String food) {
    return 'Reaction to «$food»';
  }

  @override
  String get solidReactionWhat => 'What did you notice';

  @override
  String get solidReactionHint =>
      'A rash on the cheeks by evening, for example';

  @override
  String get solidReactionNone => 'No reactions';

  @override
  String get sleepForecastTitle => 'Sleep is due soon';

  @override
  String get sleepForecastOverdue => 'Awake longer than usual';

  @override
  String sleepForecastAt(String time) {
    return 'Usually falls asleep around $time';
  }

  @override
  String sleepForecastAwake(String awake, String window) {
    return 'Awake $awake · window ≈ $window';
  }

  @override
  String sleepForecastFromHistory(int count) {
    return 'From two weeks of entries: $count gaps';
  }

  @override
  String get sleepForecastFromAge =>
      'From the age norms for now — too few entries yet';

  @override
  String get timerStart => 'Time it';

  @override
  String get timerStartHint => 'The clock starts from this second';

  @override
  String get timerFeeding => 'Feeding in progress';

  @override
  String get timerSleep => 'Sleeping now';

  @override
  String timerSince(String time) {
    return 'since $time';
  }

  @override
  String get timerStarted => 'The clock is running';

  @override
  String get timerDiscard => 'Discard';

  @override
  String get timerDiscarded => 'Timer discarded';

  @override
  String get timerForgotten =>
      'This has been running a long time — left on by mistake?';

  @override
  String timerLastFeed(String side, String ago) {
    return 'Last feed — $side, $ago';
  }

  @override
  String durationH(int h) {
    return '$h h';
  }

  @override
  String durationM(int m) {
    return '$m min';
  }

  @override
  String durationHM(int h, int m) {
    return '$h h $m min';
  }

  @override
  String get commonSave => 'Save';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonAll => 'All';

  @override
  String get commonMore => 'Details';

  @override
  String get commonBack => 'Back';

  @override
  String get commonHide => 'Hide';

  @override
  String get commonShow => 'Show';

  @override
  String get commonDate => 'Date';

  @override
  String get commonTime => 'Time';

  @override
  String get commonAge => 'Age';

  @override
  String get commonToday => 'today';

  @override
  String get commonTomorrow => 'tomorrow';

  @override
  String get commonNumberInvalid => 'Enter a number';

  @override
  String get commonTechnical => 'Technical details';

  @override
  String get logTypeMilestone => 'Milestone';

  @override
  String get logTypeMeasurement => 'Measurement';

  @override
  String get logTypeIllness => 'Illness';

  @override
  String get logTypeFeeding => 'Feeding';

  @override
  String get logTypeNappy => 'Nappy';

  @override
  String get logTypeSleep => 'Sleep';

  @override
  String get logTypeQuestion => 'Question for the doctor';

  @override
  String get logTypeNote => 'Note';

  @override
  String get feedingLeft => 'Left';

  @override
  String get feedingRight => 'Right';

  @override
  String get feedingBottle => 'Bottle';

  @override
  String get nappyWet => 'Wet';

  @override
  String get nappyDirty => 'Dirty';

  @override
  String get nappyBoth => 'Wet and dirty';

  @override
  String get severityMild => 'Mild';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severitySevere => 'Severe';

  @override
  String get genderMale => 'Boy';

  @override
  String get genderFemale => 'Girl';

  @override
  String get unitsMetric => 'Metric (cm, kg)';

  @override
  String get unitsImperial => 'Imperial (in, lb)';

  @override
  String nightWakingsCount(int n) {
    return 'wake-ups: $n';
  }

  @override
  String nightFeedsCount(int n) {
    return 'feeds: $n';
  }

  @override
  String ageYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years',
      one: '$n year',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '$n month',
    );
    return '$_temp0';
  }

  @override
  String entriesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n entries',
      one: '$n entry',
    );
    return '$_temp0';
  }

  @override
  String monthsShort(int n) {
    return '$n mo';
  }

  @override
  String get dashLayoutTitle => 'Home screen blocks';

  @override
  String get dashAllHidden => 'Every block is hidden';

  @override
  String get dashAllHiddenHint => 'You can bring them back in settings';

  @override
  String get dashConfigure => 'Customise the home screen';

  @override
  String get dashNoneSelected => 'No blocks are selected';

  @override
  String get dashHiddenBlocks => 'Hidden blocks';

  @override
  String get dashReset => 'Restore the default set';

  @override
  String get widgetNow => 'Right now';

  @override
  String get widgetSummary => 'Child summary';

  @override
  String get widgetGrowth => 'Height and weight';

  @override
  String get widgetVaccinations => 'Upcoming vaccinations';

  @override
  String get widgetIllness => 'Illness';

  @override
  String get widgetMilestones => 'Milestones';

  @override
  String get widgetRecent => 'Latest entries';

  @override
  String get widgetUpcoming => 'Upcoming events';

  @override
  String get summaryAge => 'age';

  @override
  String get summaryBirthDate => 'date of birth';

  @override
  String get summaryMilestonesCount => 'milestones';

  @override
  String get summaryEntriesCount => 'entries in total';

  @override
  String get growthNoMeasurements => 'No measurements yet';

  @override
  String get growthWeight => 'Weight';

  @override
  String get growthHeight => 'Height';

  @override
  String get growthLastMeasurement => 'last measurement';

  @override
  String growthPercentileWith(String label, int p) {
    return '$label · ${p}th percentile';
  }

  @override
  String get vaccinationsNone => 'No vaccinations coming up';

  @override
  String get illnessDaysTotal => 'sick days in total';

  @override
  String get illnessLast3Months => 'over the last 3 months';

  @override
  String get milestonesEmpty => 'The firsts are still ahead';

  @override
  String get milestonesEmptyHint =>
      'First smile, first tooth, first word — add them in the diary as a milestone';

  @override
  String get recentEmpty => 'No entries yet';

  @override
  String get upcomingEmptyHint =>
      'Vaccinations appear here on their own once a child profile exists';

  @override
  String get greetingNight => 'Good night';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get statusSick => 'Unwell';

  @override
  String get statusHealthy => 'Well';

  @override
  String get statusLatest => 'latest';

  @override
  String nowTodayReminder(String title) {
    return 'Today: $title';
  }

  @override
  String get nowNoEntries =>
      'Nothing recorded today yet. The buttons below stamp the time for you.';

  @override
  String nowSinceFeeding(String duration) {
    return 'Since the last feed — $duration';
  }

  @override
  String get countFeedings => 'feeds';

  @override
  String get countWet => 'wet';

  @override
  String get countDirty => 'dirty';

  @override
  String get countSleep => 'sleep';

  @override
  String get nightAsleepDate => 'Fell asleep, date';

  @override
  String get nightAwakeDate => 'Woke up, date';

  @override
  String get nightWokeUp => 'Wake-ups';

  @override
  String get nightOfThoseFeeds => 'Of those, feeds';

  @override
  String nightTotal(String duration) {
    return 'Total sleep: $duration';
  }

  @override
  String get nightInvalid => 'Waking up has to come after falling asleep';

  @override
  String get errorIndexBuilding =>
      'The database is still building its indexes. That takes a few minutes after the first deployment — refresh the page a little later.';

  @override
  String get errorPermission =>
      'No access to this data. Try signing out and back in.';

  @override
  String get errorOffline =>
      'No connection to the server. Changes are kept on this device and sync when it returns.';

  @override
  String get errorSession => 'Your session has expired. Sign in again.';

  @override
  String get errorGeneric =>
      'Could not load the data. Try refreshing the page.';

  @override
  String get noChildTitle => 'Let us get acquainted';

  @override
  String get noChildHint =>
      'Tell us about your baby — the app then adapts to their age and builds the vaccination calendar itself';

  @override
  String get addChild => 'Add a child';

  @override
  String get diaryFeed => 'Event feed';

  @override
  String get diaryFilterCare => 'Care';

  @override
  String get diaryFilterHealth => 'Health';

  @override
  String get diaryFilterDevelopment => 'Development';

  @override
  String get diaryFilterNotes => 'Notes';

  @override
  String get diaryEmpty => 'Your baby\'s story will live here';

  @override
  String get diaryEmptyHint =>
      'Feeds and nappies are logged with the buttons on the home screen; first words and first teeth belong here';

  @override
  String get diaryAddEntry => 'Add an entry';

  @override
  String get diaryDeleteTitle => 'Delete this entry?';

  @override
  String diaryDeleteBody(String title) {
    return 'The entry “$title” will be deleted. This cannot be undone.';
  }

  @override
  String get diaryPhotos => 'Photos';

  @override
  String get diaryNewEntry => 'New entry';

  @override
  String get diaryEditEntry => 'Edit entry';

  @override
  String get diaryType => 'Entry type';

  @override
  String get diaryTitleField => 'Title';

  @override
  String get diaryTitleRequired => 'Enter a title';

  @override
  String get diaryDescription => 'Description';

  @override
  String get diaryTags => 'Tags, comma separated';

  @override
  String get diaryTagsHint => 'motor skills, speech';

  @override
  String fieldWeight(String unit) {
    return 'Weight, $unit';
  }

  @override
  String fieldHeight(String unit) {
    return 'Height, $unit';
  }

  @override
  String fieldHead(String unit) {
    return 'Head circumference, $unit';
  }

  @override
  String fieldChest(String unit) {
    return 'Chest circumference, $unit';
  }

  @override
  String get fieldTemperature => 'Temperature, °C';

  @override
  String get fieldSeverity => 'Severity';

  @override
  String pillHead(String value) {
    return 'head $value';
  }

  @override
  String pillChest(String value) {
    return 'chest $value';
  }

  @override
  String photoUploadFailed(String error) {
    return 'Could not upload the photo: $error';
  }

  @override
  String get childrenTitle => 'Child profiles';

  @override
  String get childrenEmpty => 'No profiles yet';

  @override
  String get childrenEmptyHint => 'Tap “Add a child” to begin';

  @override
  String get childDeleteTitle => 'Delete profile?';

  @override
  String childDeleteBody(String name) {
    return 'The profile “$name” will be deleted along with every diary entry, measurement, medical record and reminder. This cannot be undone.';
  }

  @override
  String get childSelected => 'Selected';

  @override
  String get childProfileEdit => 'Child profile';

  @override
  String get childProfileNew => 'New profile';

  @override
  String get childName => 'Name';

  @override
  String get childNameRequired => 'Enter a name';

  @override
  String get childBirthDate => 'Date of birth';

  @override
  String get childPickDate => 'Pick a date';

  @override
  String get childBirthDateRequired => 'Enter the date of birth';

  @override
  String get photoAdd => 'Add a photo';

  @override
  String get photoRemove => 'Remove the photo';

  @override
  String photoSaveFailed(String error) {
    return 'Could not save the photo: $error';
  }

  @override
  String get quickNoteOptional => 'Note (optional)';

  @override
  String get quickAssistant => 'Assistant';

  @override
  String get quickNightSleep => 'Night sleep';

  @override
  String get digestTitle => 'Today';

  @override
  String get digestSubtitle => 'The day in short';

  @override
  String get digestFeedings => 'Feedings';

  @override
  String get digestSleep => 'Sleep today';

  @override
  String get digestNappies => 'Nappies';

  @override
  String get digestTemperature => 'Temperature';

  @override
  String get digestPhotos => 'New photos';

  @override
  String get digestEmpty => 'Nothing recorded today yet';

  @override
  String get digestCalm => 'Today was a calm day.';

  @override
  String get digestBusy => 'Today was a busy day.';

  @override
  String get digestHardNight => 'The night was a little difficult.';

  @override
  String get momentsTitle => 'Moments of the day';

  @override
  String get momentsLineOne => 'A small moment from today';

  @override
  String get momentsLineTwo => 'Today brought a new smile';

  @override
  String get momentsLineMany => 'A memory worth keeping';

  @override
  String get storyTitleCare => 'A week of care';

  @override
  String get storyTitleGrowing => 'Growing together';

  @override
  String get storyTitleMoments => 'Little moments, big love';

  @override
  String get storyFeedings => 'Feedings';

  @override
  String get storySleep => 'Sleep this week';

  @override
  String get storyNappies => 'Nappies';

  @override
  String get storyBestNight => 'Best night';

  @override
  String get storyExport => 'Save as PDF';

  @override
  String get storyPdfReady => 'The week\'s page is ready';

  @override
  String get appreciationHeavyDay =>
      'Today was not an easy day. You did a lot for your baby.';

  @override
  String get appreciationThanks => 'Dad thanked you for today ❤️';

  @override
  String get appreciationThankButton => 'Thank you for today';

  @override
  String get appreciationThankSent => 'Thank you sent';

  @override
  String get voiceQuickHint => 'Record by voice';

  @override
  String get voiceHoldHint => 'Hold the button and speak';

  @override
  String get voiceExample => '“fed on the left for 15 minutes”';

  @override
  String get voiceBusy => 'One moment — finishing the last recording';

  @override
  String get voiceTraceHint =>
      'What happened. Send this list if the microphone is not working';

  @override
  String get voiceTapHint => 'Tap and speak';

  @override
  String get voiceTapToStop => 'Tap again when you are done';

  @override
  String get voiceSheetTitle => 'Say it or write it';

  @override
  String get voiceKeyboardHint =>
      'Tap the microphone on the keyboard and dictate — that is your phone\'s own dictation';

  @override
  String get voiceNothingYet => 'Nothing yet';

  @override
  String get voiceWillSave => 'Will be saved as';

  @override
  String get voiceFieldHint => 'Say it or write it…';

  @override
  String get commonUndo => 'Undo';

  @override
  String get voiceSavingSoon => 'Save now';

  @override
  String get voiceOpening => 'Opening the microphone…';

  @override
  String get voiceHeard => 'Heard';

  @override
  String get voiceMl => 'ml';

  @override
  String get voiceAsNote => 'Will be saved as a note';

  @override
  String get homeQuickLog => 'Quick log';

  @override
  String get homeRecent => 'Recent events';

  @override
  String get homeNothingYet => 'Nothing recorded yet';

  @override
  String get homeMore => 'Everything else is in the Assistant tab';

  @override
  String get assistantInsights => 'Insights and reports';

  @override
  String get assistantViewKnowledge => 'Library';

  @override
  String get assistantViewInsights => 'Insights';

  @override
  String get familyTitle => 'Family';

  @override
  String get familySubtitle => 'Who else sees this child profile';

  @override
  String get familyInvite => 'Invite';

  @override
  String get familyInviteEmail => 'Email';

  @override
  String get familyInviteHint => 'The address they sign in with';

  @override
  String get familyInviteSent => 'Invitation sent';

  @override
  String get familyEmailInvalid => 'Check the address';

  @override
  String get familyPending => 'Pending';

  @override
  String get familyAccepted => 'Has access';

  @override
  String get familyNobody => 'Only you so far';

  @override
  String get familyRemove => 'Remove access';

  @override
  String get familyRoleOwner => 'Mom';

  @override
  String get familyRoleViewer => 'Dad';

  @override
  String get familyReadOnly => 'Read-only mode';

  @override
  String get familyReadOnlyHint =>
      'You can see the profile but not change entries';

  @override
  String get familyInviteBanner =>
      'You were invited to join this child profile';

  @override
  String get familyAccept => 'Accept';

  @override
  String get familyLater => 'Later';

  @override
  String get familyAcceptedToast => 'You can see the profile now';

  @override
  String get familyOwnerOnly => 'Only the profile owner can change this';

  @override
  String get familyAlreadyMember => 'That address already has access';

  @override
  String get familySelfInvite => 'That is your own address';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceSpeakNow => 'Speak now';

  @override
  String get voiceFailed => 'Could not recognize speech';

  @override
  String get voiceUnavailable =>
      'The microphone is unavailable — you can type the note';

  @override
  String get voiceDictate => 'Dictate the note';

  @override
  String get voiceStop => 'Stop recording';

  @override
  String get quickFeedHint => 'breast or bottle';

  @override
  String get quickNappyHint => 'wet or dirty';

  @override
  String get quickSleepHint => 'a daytime rest';

  @override
  String get quickNightSleepHint => 'with wake-ups';

  @override
  String get quickTemperatureHint => 'one reading';

  @override
  String get quickAssistantHint => 'ask about your baby';

  @override
  String get phraseOfDay1 => 'You are doing enough.';

  @override
  String get phraseOfDay2 => 'Today can be slower.';

  @override
  String get phraseOfDay3 => 'Your baby feels your care.';

  @override
  String get phraseOfDay4 => 'Resting is caring too.';

  @override
  String get phraseOfDay5 => 'A little easier every day.';

  @override
  String get phraseOfDay6 => 'You are here, and that is enough.';

  @override
  String get quickFever =>
      'That is a fever. The day will be marked as an illness day.';

  @override
  String get quickFeverAction => 'What to do';

  @override
  String get growthChartTitle => 'Growth over time';

  @override
  String get growthAddMeasurement => 'Add a measurement';

  @override
  String get growthEmpty => 'Nothing to plot yet';

  @override
  String get growthEmptyHint =>
      'Add height and weight in the diary — the curve appears after the first measurement, and the WHO bands are already waiting';

  @override
  String get growthAxisAge => 'age, months';

  @override
  String get growthWhoMedian => 'WHO median';

  @override
  String get growthWhoBand => '±2 SD band';

  @override
  String get growthWhoLimit =>
      'The WHO standards run to five years, so the reference curves stop at 60 months.';

  @override
  String get growthWhoAssessment => 'WHO assessment';

  @override
  String get growthAgeOutOfRange =>
      'Age is outside the reference tables (0–60 months)';

  @override
  String growthPercentileOrdinal(int p) {
    return '${p}th';
  }

  @override
  String get growthPercentileWord => 'percentile';

  @override
  String growthChangeSince(String date) {
    return 'gain since $date';
  }

  @override
  String get growthZScore => 'z-score';

  @override
  String get growthDisclaimer =>
      'Calculated against the WHO standards for children aged 0–5. A percentile shows where a child sits among peers; it is not a diagnosis, and a deviation may simply be how this child is built. Your doctor makes the call.';

  @override
  String get growthHistory => 'Measurement history';

  @override
  String get illnessTitle => 'Illness statistics';

  @override
  String illnessHeatmap(int months) {
    return 'Heat map over $months months';
  }

  @override
  String get illnessEpisodes => 'Illness episodes';

  @override
  String get illnessAdd => 'Log illness';

  @override
  String get illnessEmpty => 'No illness entries';

  @override
  String get illnessEmptyHint => 'A sick day can be marked in the diary';

  @override
  String get illnessEpisodesCount => 'episodes';

  @override
  String get illnessDays12 => 'days over 12 months';

  @override
  String get illnessDays3 => 'days over 3 months';

  @override
  String get illnessWell => 'well';

  @override
  String illnessDayWell(String date) {
    return '$date — well';
  }

  @override
  String remindersActiveCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n active reminders',
      one: '$n active reminder',
    );
    return '$_temp0';
  }

  @override
  String remindersOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days overdue',
      one: '$n day overdue',
    );
    return '$_temp0';
  }

  @override
  String remindersInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $n days',
      one: 'in $n day',
    );
    return '$_temp0';
  }

  @override
  String get medicalTitle => 'Medical records';

  @override
  String get medicalEmpty => 'No medical records yet';

  @override
  String get medicalEmptyHint => 'Add a doctor visit or lab results';

  @override
  String get medicalDeleteTitle => 'Delete this record?';

  @override
  String medicalDeleteBody(String diagnosis, String date) {
    return 'The record “$diagnosis” from $date will be deleted along with its lab results. This cannot be undone.';
  }

  @override
  String get medicalAskDoctor => 'Ask the doctor';

  @override
  String get medicalWriteDown => 'Write it down';

  @override
  String get medicalQuestionsHint =>
      'Write down anything you want to ask. The list goes into the report for the doctor, so you do not have to remember it in the room.';

  @override
  String get medicalAsked => 'Asked';

  @override
  String get medicalQuestionHint =>
      'For example: is it normal to spit up after every feed';

  @override
  String get medicalReport => 'Report for the doctor';

  @override
  String get medicalReportHint =>
      'A one-page summary: measurements against the WHO standards, illness statistics, out-of-range lab results, vaccination status and milestones.';

  @override
  String get medicalReportBuilding => 'Preparing…';

  @override
  String get medicalReportDownload => 'Download PDF';

  @override
  String medicalReportFailed(String error) {
    return 'Could not build the report: $error';
  }

  @override
  String get medicalPrescriptions => 'Prescriptions';

  @override
  String get medicalLabResults => 'Lab results';

  @override
  String medicalOutOfRange(int n) {
    return '$n out of range';
  }

  @override
  String get medicalScans => 'Form scans';

  @override
  String get medicalIndicator => 'Test';

  @override
  String get medicalValue => 'Value';

  @override
  String get medicalReference => 'Reference';

  @override
  String get medicalRecordTitle => 'Medical record';

  @override
  String get medicalDiagnosis => 'Diagnosis or reason for the visit';

  @override
  String get medicalDiagnosisRequired =>
      'Enter a diagnosis or a reason for the visit';

  @override
  String get medicalDoctor => 'Doctor and clinic';

  @override
  String get medicalDoctorHint => 'Paediatrician, clinic no. 2';

  @override
  String get medicalLabs => 'Lab tests';

  @override
  String get medicalAddRow => 'Add a row';

  @override
  String get medicalReferenceHint =>
      'Reference values are optional, but without them the app cannot flag anything as out of range.';

  @override
  String get medicalScan => 'Form scan';

  @override
  String medicalUploadFailed(String error) {
    return 'Could not upload: $error';
  }

  @override
  String medicalRowInvalid(String name) {
    return 'Check the row “$name”: it needs a name and a numeric value.';
  }

  @override
  String get medicalUnitShort => 'Unit';

  @override
  String get medicalFrom => 'from';

  @override
  String get medicalTo => 'to';

  @override
  String get medicalRemoveRow => 'Remove the row';

  @override
  String get medicalAttach => 'Attach';

  @override
  String get assistantSearchHint =>
      'Search the articles: temperature, rash, solids…';

  @override
  String get assistantSearchIsArticles =>
      'This searches the app’s articles. The assistant answers anything.';

  @override
  String get assistantAskAi => 'Ask the assistant';

  @override
  String get assistantNothingFound => 'Nothing found';

  @override
  String assistantNoArticle(String query) {
    return 'There is no article for “$query” yet';
  }

  @override
  String get assistantTryAnother =>
      'Try another word — “temperature” or “rash”, for example';

  @override
  String get assistantFound => 'Found';

  @override
  String assistantArticlesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n articles',
      one: '$n article',
    );
    return '$_temp0';
  }

  @override
  String get assistantTriage => 'Check the warning signs';

  @override
  String get assistantTriageHint =>
      'A few questions, and you will know whether to wait or to call 103';

  @override
  String get assistantChat => 'Ask in your own words';

  @override
  String get assistantChatHint =>
      'Answers anything — about your child and beyond';

  @override
  String get assistantChatOff => 'AI is not connected yet — open to see how';

  @override
  String get assistantRelevant => 'Relevant right now';

  @override
  String assistantChildAge(String name, int months) {
    return '$name, $months mo';
  }

  @override
  String get assistantAllTopics => 'All topics';

  @override
  String get assistantDisclaimer =>
      'The material follows guidance from the WHO, NICE and the American Academy of Pediatrics. It is reference information for parents, not a substitute for an examination. The final call is always your doctor’s.';

  @override
  String get chatTitle => 'Ask the assistant';

  @override
  String get chatEmpty => 'Ask anything about your child’s health';

  @override
  String chatHint(String name) {
    return 'Ask anything — about $name or about your own day';
  }

  @override
  String get chatSend => 'Send';

  @override
  String get chatAsk => 'Ask anything';

  @override
  String get chatOrRecord =>
      'Or dictate an entry — “fed left 15 minutes”, “slept 2 hours”, “temperature 37.2”. I will write it in the diary.';

  @override
  String get chatRecordUndone => 'Entry deleted';

  @override
  String chatOpening(String name) {
    return 'Ask anything — about $name or about your own day';
  }

  @override
  String get chatDisclaimer =>
      'The assistant answers any question. On your child’s health it leans on the app’s vetted base where there is one, and it does not diagnose — the decision is always your doctor’s.';

  @override
  String get chatGeneralAnswer =>
      'This answer comes from the AI’s own knowledge, not from the app’s vetted base. If it is about health, check with a doctor.';

  @override
  String get chatEmergency => 'Call an ambulance — 103';

  @override
  String get chatEmergencyBody =>
      'Your question contains a sign that cannot wait. Questions like this are deliberately never sent to the AI — what is needed here is help, not advice.';

  @override
  String get chatWhatToDo => 'What to do until the ambulance arrives';

  @override
  String get chatSources => 'The answer is based on these articles:';

  @override
  String get chatOpenKb => 'Open the knowledge base';

  @override
  String get chatAiOff => 'The AI assistant is not connected yet';

  @override
  String get chatAiOffBody =>
      'The knowledge base and the warning-sign check work without it — they need no internet at all.';

  @override
  String get chatAiOffHow =>
      'To switch the AI on, deploy the free proxy on Cloudflare Workers and rebuild the app with its address. The instructions are in worker/README.md.';

  @override
  String get chatSuggestionsTitle => 'Where to start';

  @override
  String askTemperature(String value) {
    return 'Temperature $value — what to do and when to call a doctor';
  }

  @override
  String askWhyTemperature(String value) {
    return 'You logged $value today';
  }

  @override
  String askHardNight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'The baby woke $n times last night — what can help',
      one: 'The baby woke $n time last night — what can help',
    );
    return '$_temp0';
  }

  @override
  String askWhyHardNight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n wakings last night',
      one: '$n waking last night',
    );
    return '$_temp0';
  }

  @override
  String get askQuietNappies =>
      'No bowel movement for a while — when is it worth worrying';

  @override
  String get askWhyQuietNappies => 'No nappy logged for over a day';

  @override
  String get askNewbornFeeding => 'How to tell a newborn is getting enough';

  @override
  String get askSleepNeeds => 'How much sleep a baby needs at this age';

  @override
  String get askSolids => 'When to start solids, and with what';

  @override
  String get askMilestones => 'What babies usually do at this age';

  @override
  String get askWhyAge => 'For your baby\'s age';

  @override
  String get chatSuggestionsHint => 'Drawn from your own entries';

  @override
  String get chatSuggestion1 => 'Temperature is 38.5, what do I do';

  @override
  String get chatSuggestion2 => 'Make me a shopping list for the week';

  @override
  String get chatSuggestion3 => 'Write a birthday message for grandma';

  @override
  String get chatSuggestion4 => 'Can I take antibiotics while breastfeeding';

  @override
  String get chatSuggestion5 => 'My baby has not pooed for two days';

  @override
  String get actionSuggested => 'The assistant suggests';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionDismiss => 'No thanks';

  @override
  String get actionReadOnly =>
      'You have view-only access — the parent who invited you can write this.';

  @override
  String get actionFailed => 'Could not do that';

  @override
  String actionWrite(String what) {
    return 'Log: $what';
  }

  @override
  String actionCreateReminder(String title, String when) {
    return 'Create the reminder “$title” — $when';
  }

  @override
  String actionOpenScreen(String screen) {
    return 'Open “$screen”';
  }

  @override
  String actionOpenArticle(String title) {
    return 'Open the article “$title”';
  }

  @override
  String get actionBuildReport => 'Build a PDF report for the doctor';

  @override
  String get triageTitle => 'Warning-sign check';

  @override
  String get triageNeedChild => 'A child profile is needed';

  @override
  String get triageNeedChildHint =>
      'Age changes the assessment — especially under three months';

  @override
  String get triageNeedChildAction => 'Create one in the Children section';

  @override
  String get triageTemperatureHint =>
      'If you measured it, enter it — 38.5 for example';

  @override
  String get triageCheckAll => 'Tick everything that applies';

  @override
  String get triageEvaluate => 'Assess';

  @override
  String get triageRestart => 'Start over';

  @override
  String get triageConsidered => 'What was taken into account:';

  @override
  String get triageDisclaimer =>
      'This is not a diagnosis. The assessment follows formal signs and does not replace an examination. If you are worried and the check said “watch at home” — see a doctor anyway.';

  @override
  String get articleNotFound => 'Article not found';

  @override
  String get articleNotFoundBody => 'There is no such article in the base';

  @override
  String get articleToList => 'Back to the topics';

  @override
  String get articleEmergency => 'Emergency — 103';

  @override
  String get articleWhatToDo => 'What to do now';

  @override
  String get articleWhenDoctor => 'When to see a doctor';

  @override
  String get articleSources => 'Sources';

  @override
  String get articleDisclaimer =>
      'This is reference information, not a diagnosis and not a prescription. If something worries you, see your paediatrician. If you see warning signs, call 103.';

  @override
  String get settingsParent => 'Parent';

  @override
  String get settingsYourName => 'Your name';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsUnitsHint =>
      'Measurements are always stored in metric and converted only for display, so switching never disturbs anything you have already entered.';

  @override
  String get settingsTemperatureHint =>
      'Temperature stays in °C in both systems: every threshold in the app and in the guidance is given in Celsius.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAuthor => 'Author';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsDeleteSection => 'Deleting your account';

  @override
  String get settingsDeleteWarning =>
      'Deleting the account permanently removes every child, the diary, the medical records and the reminders. It cannot be undone, so export the PDF report first if you want it.';

  @override
  String get settingsChangeButton => 'Change';

  @override
  String get growthVerdictSeverelyLow => 'Well below the norm';

  @override
  String get growthVerdictLow => 'Below the norm';

  @override
  String get growthVerdictNormal => 'Within the norm';

  @override
  String get growthVerdictHigh => 'Above the norm';

  @override
  String get growthVerdictSeverelyHigh => 'Well above the norm';

  @override
  String growthMetricWithDate(String metric, String date) {
    return '$metric, $date';
  }

  @override
  String get medicalAdd => 'Add a record';

  @override
  String get photoNotAnImage =>
      'Could not read the image. JPG, PNG and WebP are supported.';

  @override
  String get photoStillTooLarge =>
      'The image is still too large even after compression. Try a closer shot or crop it.';

  @override
  String get nowLastFeeding => 'Last feed';

  @override
  String get nowLastSleep => 'Last sleep';

  @override
  String get nowNothingYet => 'not yet';

  @override
  String nowAgo(String duration) {
    return '$duration ago';
  }

  @override
  String get suggestionAfterSleep => 'Feeding is often needed after sleep';

  @override
  String get suggestionNappy => 'No diaper entry for a while';

  @override
  String get suggestionDismiss => 'Hide';

  @override
  String get reflectionTitle => 'Today';

  @override
  String reflectionFeedingsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n feeds',
      one: '$n feed',
    );
    return '$_temp0';
  }

  @override
  String reflectionSummary(String feedings, String sleep) {
    return 'Today: $feedings and $sleep of sleep. It helps to see the shape of the day without counting it up.';
  }

  @override
  String reflectionSummaryNoSleep(String feedings) {
    return 'Today: $feedings. Nobody logged any sleep.';
  }

  @override
  String get reflectionSupport =>
      'You recorded the important events of the day. That is already a meaningful help for both you and your baby.';

  @override
  String get reflectionNappies => 'nappies';

  @override
  String get patternSleepThenFeeding =>
      'After daytime sleep, feeding usually happens about 20–40 minutes later.';

  @override
  String patternNightStart(String time) {
    return 'Night sleep most often starts around $time.';
  }

  @override
  String get patternStableSleep =>
      'Total sleep has been staying about the same over the last few days.';

  @override
  String get contextTitle => 'Child context';

  @override
  String get contextNotRecorded => 'Not recorded';

  @override
  String get chatContinueTitle => 'Continue conversation';

  @override
  String chatContinueLast(String question) {
    return 'Last question: “$question”';
  }

  @override
  String get chatContinueResume => 'Continue';

  @override
  String get chatContinueNew => 'New';

  @override
  String get checkInTitle => 'How are you feeling?';

  @override
  String get checkInHoldingUp => 'Holding up';

  @override
  String get checkInTired => 'Tired';

  @override
  String get checkInVeryHard => 'Very hard';

  @override
  String get checkInReplyHoldingUp =>
      'May you find at least one quiet moment for yourself today.';

  @override
  String get checkInReplyTired =>
      'Feeling tired after a difficult night is completely understandable. Try to focus on what matters most, not on perfect order.';

  @override
  String get checkInReplyVeryHard =>
      'If possible, ask someone to stay with you for a little while. Taking care of yourself is also part of taking care of your baby.';

  @override
  String get vaccineHepB1 => 'Hepatitis B (HepB) — first dose';

  @override
  String get vaccineNoteHepB1 => 'Within the first day of life';

  @override
  String get vaccineBcg => 'Tuberculosis (BCG)';

  @override
  String get vaccineNoteBcg => 'On days 1–4 of life';

  @override
  String get vaccinePenta1 =>
      'Pentavalent: DTaP + Hib + HepB + IPV — first dose';

  @override
  String get vaccineNotePenta1 =>
      'Whooping cough, diphtheria, tetanus, Hib, hepatitis B, polio';

  @override
  String get vaccinePcv1 => 'Pneumococcal (PCV) — first dose';

  @override
  String get vaccinePenta2 => 'DTaP + Hib + IPV — second dose';

  @override
  String get vaccinePenta3 =>
      'Pentavalent: DTaP + Hib + HepB + IPV — third dose';

  @override
  String get vaccinePcv2 => 'Pneumococcal (PCV) — second dose';

  @override
  String get vaccineMmr1 => 'Measles, rubella, mumps (MMR) — first dose';

  @override
  String get vaccineNoteMmr1 => 'At 12–15 months';

  @override
  String get vaccinePcvBooster => 'Pneumococcal (PCV) — booster';

  @override
  String get vaccineOpv => 'Polio (OPV)';

  @override
  String get vaccinePentaBooster => 'DTaP + Hib + IPV — booster';

  @override
  String get vaccineNotePentaBooster => 'At 18 months';

  @override
  String get vaccineHepA1 => 'Hepatitis A (HepA) — first dose';

  @override
  String get vaccineNoteHepA1 => 'At 2 years';

  @override
  String get vaccineHepA2 => 'Hepatitis A (HepA) — second dose';

  @override
  String get vaccineNoteHepA2 => 'Six months later';

  @override
  String get vaccineDtapBooster => 'DTaP — booster';

  @override
  String get vaccineNoteDtapBooster => 'At 6 years, before school';

  @override
  String get vaccineMmr2 => 'Measles, rubella, mumps (MMR) — second dose';

  @override
  String get vaccineHpv1 => 'HPV — first dose (girls)';

  @override
  String get vaccineNoteHpv1 => 'At 11 years, with parental consent';

  @override
  String get vaccineHpv2 => 'HPV — second dose (girls)';

  @override
  String get vaccineNoteHpv2 => 'Six months later';

  @override
  String get vaccineTdBooster => 'Td — booster';

  @override
  String get vaccineNoteTdBooster => 'At 16 years, then every 10 years';

  @override
  String get vaccineSource => 'National immunisation schedule of Kazakhstan';

  @override
  String get reportExport => 'Export PDF';

  @override
  String reportPeriodDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '$n day',
    );
    return '$_temp0';
  }

  @override
  String get reportPeriod => 'Report period';

  @override
  String reportRange(String from, String to) {
    return '$from — $to';
  }

  @override
  String get reportTitle => 'Report for the doctor';

  @override
  String get reportNothing => 'No entries in this period';

  @override
  String get reportPreparing => 'Preparing the PDF…';

  @override
  String get reportReady => 'The report is ready';

  @override
  String get reportShareFailed => 'Could not open the report';

  @override
  String get reportSectionSleep => 'Sleep';

  @override
  String get reportAvgNight => 'Average night sleep';

  @override
  String get reportAvgDay => 'Average daytime sleep';

  @override
  String get reportAvgWakings => 'Average wake-ups';

  @override
  String get reportSectionFeeding => 'Feeding';

  @override
  String get reportFeedingsTotal => 'Feedings in total';

  @override
  String get reportBreast => 'Breast';

  @override
  String get reportBottle => 'Bottle';

  @override
  String get reportSectionNappies => 'Nappies';

  @override
  String get reportSectionTemperature => 'Temperature';

  @override
  String get reportTempMax => 'Highest';

  @override
  String get reportTempMin => 'Lowest';

  @override
  String get reportTempCount => 'Measurements';

  @override
  String get reportSectionMedicines => 'Medicines';

  @override
  String get reportSectionNotes => 'Notes';

  @override
  String get reportDisclaimer =>
      'This report is intended to support discussion with a doctor and is not a medical conclusion.';

  @override
  String reportPage(int page, int total) {
    return 'Page $page of $total';
  }
}
