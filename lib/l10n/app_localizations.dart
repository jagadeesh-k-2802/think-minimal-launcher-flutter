import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Think Launcher'**
  String get appTitle;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// content for initial text
  ///
  /// In en, this message translates to:
  /// **'Press the settings button to start'**
  String get pressSettingsButtonToStart;

  /// Label for number of apps setting
  ///
  /// In en, this message translates to:
  /// **'Number of apps'**
  String get numberOfApps;

  /// Label for back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Title for search apps
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchApps;

  /// Label for search button visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show search button'**
  String get showSearchButton;

  /// Message shown when long press gesture is disabled
  ///
  /// In en, this message translates to:
  /// **'Long press gesture is disabled. Enable it in gesture settings to hide this button.'**
  String get longPressGestureDisabled;

  /// Label for bold font setting
  ///
  /// In en, this message translates to:
  /// **'Use bold font'**
  String get useBoldFont;

  /// Label for list scrolling setting
  ///
  /// In en, this message translates to:
  /// **'Enable list scrolling'**
  String get enableListScrolling;

  /// Label for icon visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show icons'**
  String get showIcons;

  /// Label for folder chevron visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show folder chevron'**
  String get showFolderChevron;

  /// Label for status bar visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show status bar'**
  String get showStatusBar;

  /// Label for clock font size setting
  ///
  /// In en, this message translates to:
  /// **'Clock font size'**
  String get clockFontSize;

  /// Toggle to use 24-hour clock instead of 12-hour clock
  ///
  /// In en, this message translates to:
  /// **'Use 24-hour clock'**
  String get use24HourClock;

  /// Label for app font size setting
  ///
  /// In en, this message translates to:
  /// **'App font size'**
  String get appFontSize;

  /// Label for app icon size setting
  ///
  /// In en, this message translates to:
  /// **'App icon size'**
  String get appIconSize;

  /// Label for the app theme setting
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get appTheme;

  /// App theme option that follows the system theme
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get appThemeAuto;

  /// App theme option that forces light mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appThemeLight;

  /// App theme option that forces dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appThemeDark;

  /// Label for app list section
  ///
  /// In en, this message translates to:
  /// **'App list'**
  String get appList;

  /// Shows how many apps are selected out of total
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} apps selected'**
  String appsSelected(int count, int total);

  /// Label for reorder apps option
  ///
  /// In en, this message translates to:
  /// **'Reorder apps & folders'**
  String get reorderAppsFolders;

  /// Label for manage folders option
  ///
  /// In en, this message translates to:
  /// **'Manage folders'**
  String get manageFolders;

  /// Description for manage folders option
  ///
  /// In en, this message translates to:
  /// **'Create and organize app folders'**
  String get createAndOrganizeFolders;

  /// Label for gestures option
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get gestures;

  /// Description for gestures option
  ///
  /// In en, this message translates to:
  /// **'Configure application gestures'**
  String get configureGestures;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Message shown when no apps are selected
  ///
  /// In en, this message translates to:
  /// **'Press the settings button to start'**
  String get pressSettingsToStart;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message when apps fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading applications'**
  String get errorLoadingApps;

  /// Message shown when no apps are selected
  ///
  /// In en, this message translates to:
  /// **'No applications selected'**
  String get noAppsSelected;

  /// Title for create folder dialog
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// Title for rename app dialog
  ///
  /// In en, this message translates to:
  /// **'Rename App'**
  String get renameApp;

  /// Label identifying a launcher shortcut
  ///
  /// In en, this message translates to:
  /// **'Shortcut'**
  String get shortcut;

  /// Label identifying the app that published a launcher shortcut
  ///
  /// In en, this message translates to:
  /// **'Shortcut from {appName}'**
  String shortcutFromApp(String appName);

  /// Title for rename shortcut dialog and shortcut menu action
  ///
  /// In en, this message translates to:
  /// **'Rename Shortcut'**
  String get renameShortcut;

  /// Shortcut menu action to restore the original shortcut label
  ///
  /// In en, this message translates to:
  /// **'Reset Shortcut Name'**
  String get resetShortcutName;

  /// Shortcut menu action to remove a pinned shortcut
  ///
  /// In en, this message translates to:
  /// **'Remove Shortcut'**
  String get removeShortcut;

  /// Title for move to folder dialog
  ///
  /// In en, this message translates to:
  /// **'Move to Folder'**
  String get moveToFolder;

  /// content for move to folder dialog
  ///
  /// In en, this message translates to:
  /// **'No other folders available to move this app to.'**
  String get noOtherFoldersAvailable;

  /// Title for folder selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// Title for reset app name option
  ///
  /// In en, this message translates to:
  /// **'Reset App Name'**
  String get resetAppName;

  /// Label for folder name input
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// Title for edit folder dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Folder'**
  String get editFolder;

  /// Title for delete folder dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolder;

  /// Confirmation message for folder deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteFolderConfirm(String name);

  /// Title for manage apps in folder dialog
  ///
  /// In en, this message translates to:
  /// **'Manage Apps in {name}'**
  String manageAppsInFolder(String name);

  /// Title for reorder apps
  ///
  /// In en, this message translates to:
  /// **'Reorder Apps'**
  String get reOrderApps;

  /// Shortcut menu action to open the home screen reorder flow
  ///
  /// In en, this message translates to:
  /// **'Reorder Home Screen'**
  String get reorderHomeScreen;

  /// Error message shown when settings fail to save
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get errorSavingSettings;

  /// Title for gesture settings screen
  ///
  /// In en, this message translates to:
  /// **'Gesture Settings'**
  String get gestureSettings;

  /// Label for swipe up gesture
  ///
  /// In en, this message translates to:
  /// **'Swipe Up'**
  String get swipeUp;

  /// Label for long press gesture
  ///
  /// In en, this message translates to:
  /// **'Long Press'**
  String get longPress;

  /// Label for double tap gesture
  ///
  /// In en, this message translates to:
  /// **'Double Tap'**
  String get doubleTap;

  /// Label for selecting gesture action
  ///
  /// In en, this message translates to:
  /// **'Select Action'**
  String get selectAction;

  /// Label for no action option
  ///
  /// In en, this message translates to:
  /// **'No Action'**
  String get noAction;

  /// Title for folder management screen
  ///
  /// In en, this message translates to:
  /// **'Folder Management'**
  String get folderManagement;

  /// Button text for adding apps to folder
  ///
  /// In en, this message translates to:
  /// **'Add Apps to Folder'**
  String get addAppsToFolder;

  /// Button text for removing apps from folder
  ///
  /// In en, this message translates to:
  /// **'Remove Apps from Folder'**
  String get removeAppsFromFolder;

  /// Button text for reordering apps in folder
  ///
  /// In en, this message translates to:
  /// **'Reorder Apps'**
  String get reorderAppsInFolder;

  /// Message when no folders are there
  ///
  /// In en, this message translates to:
  /// **'No Folders'**
  String get noFolders;

  /// Title for app selection for folder
  ///
  /// In en, this message translates to:
  /// **'Select apps for folder'**
  String get selectAppsForFolder;

  /// Message shown when folder is created
  ///
  /// In en, this message translates to:
  /// **'Folder created successfully'**
  String get folderCreated;

  /// Message shown when folder is updated
  ///
  /// In en, this message translates to:
  /// **'Folder updated successfully'**
  String get folderUpdated;

  /// Message shown when folder is deleted
  ///
  /// In en, this message translates to:
  /// **'Folder deleted successfully'**
  String get folderDeleted;

  /// Title for app selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Apps'**
  String get selectApps;

  /// Hint text for app search field
  ///
  /// In en, this message translates to:
  /// **'Search apps by name'**
  String get searchAppsHint;

  /// Button text to select all apps
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Button text to deselect all apps
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// Label for app info option
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// Label for uninstall app option
  ///
  /// In en, this message translates to:
  /// **'Uninstall App'**
  String get uninstallApp;

  /// Label for clear notification option
  ///
  /// In en, this message translates to:
  /// **'Clear notification'**
  String get clearNotification;

  /// Confirmation message for app uninstallation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to uninstall {appName}?'**
  String confirmUninstall(String appName);

  /// Title for app options dialog
  ///
  /// In en, this message translates to:
  /// **'App Options'**
  String get appOptions;

  /// Error message when app cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open the application'**
  String get couldNotOpenApp;

  /// Title for app selection screen
  ///
  /// In en, this message translates to:
  /// **'Select apps'**
  String get selectAppsTitle;

  /// Title for gestures screen
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get gesturesTitle;

  /// Title for app selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select app'**
  String get selectAppTitle;

  /// Number of apps in a folder
  ///
  /// In en, this message translates to:
  /// **'{count} apps'**
  String appsInFolder(int count);

  /// Label for when no app is selected
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// Shows how many apps are selected
  ///
  /// In en, this message translates to:
  /// **'{count} apps selected'**
  String selectedAppsCount(int count);

  /// Label for auto focus search setting
  ///
  /// In en, this message translates to:
  /// **'Auto focus search'**
  String get autoFocusSearch;

  /// Description for auto focus search setting
  ///
  /// In en, this message translates to:
  /// **'Cursor will be positioned in the search field when opened'**
  String get autoFocusSearchDescription;

  /// Error message when app info fails to load
  ///
  /// In en, this message translates to:
  /// **'Error getting app info for {packageName}'**
  String errorGettingAppInfo(String packageName);

  /// Error message when weather update fails
  ///
  /// In en, this message translates to:
  /// **'Error updating weather'**
  String get errorUpdatingWeather;

  /// Toggle to show icons in full color instead of grayscale
  ///
  /// In en, this message translates to:
  /// **'Color mode'**
  String get colorMode;

  /// Toggle to briefly wake the screen when a notification arrives
  ///
  /// In en, this message translates to:
  /// **'Wake on notification'**
  String get wakeOnNotification;

  /// Section title for wallpaper settings
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get wallpaper;

  /// Action to pick a wallpaper image
  ///
  /// In en, this message translates to:
  /// **'Select wallpaper'**
  String get selectWallpaper;

  /// Action to clear wallpaper
  ///
  /// In en, this message translates to:
  /// **'Remove wallpaper'**
  String get removeWallpaper;

  /// Subtitle when no wallpaper is set
  ///
  /// In en, this message translates to:
  /// **'No wallpaper set'**
  String get noWallpaperSet;

  /// Label for wallpaper blur slider
  ///
  /// In en, this message translates to:
  /// **'Wallpaper blur'**
  String get wallpaperBlur;

  /// Label for wallpaper opacity slider
  ///
  /// In en, this message translates to:
  /// **'Wallpaper opacity'**
  String get wallpaperOpacity;

  /// Label for Scroll to top
  ///
  /// In en, this message translates to:
  /// **'Auto scroll on folder close'**
  String get scrollToTop;

  /// Title for export settings tile
  ///
  /// In en, this message translates to:
  /// **'Export settings'**
  String get exportSettings;

  /// Subtitle for export settings
  ///
  /// In en, this message translates to:
  /// **'Save current settings to JSON file'**
  String get exportSettingsSubtitle;

  /// Title for import settings tile
  ///
  /// In en, this message translates to:
  /// **'Import settings'**
  String get importSettings;

  /// Subtitle for import settings
  ///
  /// In en, this message translates to:
  /// **'Load settings from JSON file'**
  String get importSettingsSubtitle;

  /// Snack bar message after successful export
  ///
  /// In en, this message translates to:
  /// **'Settings exported successfully.'**
  String get exportSuccess;

  /// Message when export saved to app storage fallback
  ///
  /// In en, this message translates to:
  /// **'Exported to app storage: {fileName}'**
  String exportFallbackSaved(String fileName);

  /// Error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export settings'**
  String get exportFailed;

  /// Error when file path missing
  ///
  /// In en, this message translates to:
  /// **'Invalid file selection'**
  String get invalidFileSelection;

  /// Error when JSON parse fails
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON file'**
  String get invalidJsonFile;

  /// Snack bar message after successful import
  ///
  /// In en, this message translates to:
  /// **'Settings imported successfully.'**
  String get importSuccess;

  /// Error message when import fails
  ///
  /// In en, this message translates to:
  /// **'Failed to import settings'**
  String get importFailed;

  /// Message when export saved in Downloads directory
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads: {fileName}'**
  String exportSavedToDownloads(String fileName);

  /// Label for weather app selection setting
  ///
  /// In en, this message translates to:
  /// **'Weather app'**
  String get weatherApp;

  /// Description for weather app selection
  ///
  /// In en, this message translates to:
  /// **'Select app to open when tapping weather icon'**
  String get selectWeatherApp;

  /// Message when no weather app is selected
  ///
  /// In en, this message translates to:
  /// **'No app selected'**
  String get noWeatherAppSelected;

  /// Label for app alignment setting
  ///
  /// In en, this message translates to:
  /// **'App alignment'**
  String get appAlignment;

  /// Left alignment option
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get appAlignmentLeft;

  /// Center alignment option
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get appAlignmentCenter;

  /// Right alignment option
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get appAlignmentRight;

  /// Label for the icon pack setting in settings screen
  ///
  /// In en, this message translates to:
  /// **'Icon pack'**
  String get iconPackSettingLabel;

  /// Title for the icon pack selection screen
  ///
  /// In en, this message translates to:
  /// **'Icon pack'**
  String get iconPackScreenTitle;

  /// Note shown on the icon pack selection screen about limited support
  ///
  /// In en, this message translates to:
  /// **'Note: Not all third-party icon packs are supported.'**
  String get iconPackNote;

  /// Label for using the system default icons instead of an icon pack
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get iconPackSystemDefault;

  /// Error message when icon packs fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load icon packs.'**
  String get iconPackErrorLoading;

  /// Shown when color mode is not usable when custom icon pack is selected
  ///
  /// In en, this message translates to:
  /// **'Cannot apply color mode when custom icon is selected'**
  String get iconPackColorModeWarning;

  /// Title for the weather API key setting
  ///
  /// In en, this message translates to:
  /// **'Weather API key'**
  String get weatherApiKeyTitle;

  /// Subtitle when no weather API key is configured
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get weatherApiKeyNotSet;

  /// Subtitle when a custom weather API key is configured
  ///
  /// In en, this message translates to:
  /// **'Custom key set'**
  String get weatherApiKeyCustomSet;

  /// Title for the dialog where the user enters their OpenWeather API key
  ///
  /// In en, this message translates to:
  /// **'OpenWeather API key'**
  String get weatherApiKeyDialogTitle;

  /// Label for the weather API key text field
  ///
  /// In en, this message translates to:
  /// **'OpenWeather API key'**
  String get weatherApiKeyDialogLabel;

  /// Hint text for the weather API key text field
  ///
  /// In en, this message translates to:
  /// **'Enter API key'**
  String get weatherApiKeyDialogHint;

  /// Helper text shown below the weather API key field
  ///
  /// In en, this message translates to:
  /// **'You can get your free API key from https://openweathermap.org/api'**
  String get weatherApiKeyDialogHelp;

  /// Title for send feedback settings item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @sendFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedbackTitle;

  /// Label for the app version row in the About screen
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// Error message shown when the About screen cannot load app info
  ///
  /// In en, this message translates to:
  /// **'Unable to load app information'**
  String get aboutLoadError;

  /// Title for the license screen
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licenseScreenTitle;

  /// Label for the Privacy Policy item in the About screen
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacyPolicy;

  /// Title for the first-time NUX screen
  ///
  /// In en, this message translates to:
  /// **'Initial Setup'**
  String get nuxTitle;

  /// Intro text for the NUX screen
  ///
  /// In en, this message translates to:
  /// **'These steps are optional. You can continue at any time, but enabling them will unlock weather and notification features.'**
  String get nuxDescription;

  /// Title for the location permission row in NUX
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get nuxLocationTitle;

  /// Body text explaining why location is requested in NUX
  ///
  /// In en, this message translates to:
  /// **'Used only to fetch your local weather using approximate location. Your location is never stored or sent anywhere else.'**
  String get nuxLocationBody;

  /// Title for the notification permission row in NUX
  ///
  /// In en, this message translates to:
  /// **'Notification Access'**
  String get nuxNotificationTitle;

  /// Body text explaining why notification access is requested
  ///
  /// In en, this message translates to:
  /// **'Used to show your latest notifications under app names. Notification content never leaves your device.'**
  String get nuxNotificationBody;

  /// Title for the default launcher section in NUX
  ///
  /// In en, this message translates to:
  /// **'Set Think Launcher as Default'**
  String get nuxLauncherTitle;

  /// Body text explaining how to set default launcher
  ///
  /// In en, this message translates to:
  /// **'To use Think Launcher as your home screen, set it as the default launcher in Android settings.'**
  String get nuxLauncherBody;

  /// Label for the NUX continue button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get nuxContinue;

  /// Note at the bottom of the NUX screen about optional nature
  ///
  /// In en, this message translates to:
  /// **'Location and notification access are optional. You can change them later in Settings.'**
  String get nuxOptionalNote;

  /// Snackbar text asking user to enable location for weather
  ///
  /// In en, this message translates to:
  /// **'Enable location to configure weather.'**
  String get enableLocationForWeather;

  /// Label for the snackbar action that opens location settings
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get openLocationSettings;

  /// Title for the donate with PayPal item in settings
  ///
  /// In en, this message translates to:
  /// **'Donate with PayPal'**
  String get donatePaypalTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'nl': return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
