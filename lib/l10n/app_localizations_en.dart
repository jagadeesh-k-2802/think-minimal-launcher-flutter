// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Think Launcher';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get pressSettingsButtonToStart => 'Press the settings button to start';

  @override
  String get numberOfApps => 'Number of apps';

  @override
  String get back => 'Back';

  @override
  String get searchApps => 'Search apps';

  @override
  String get showSearchButton => 'Show search button';

  @override
  String get longPressGestureDisabled => 'Long press gesture is disabled. Enable it in gesture settings to hide this button.';

  @override
  String get useBoldFont => 'Use bold font';

  @override
  String get enableListScrolling => 'Enable list scrolling';

  @override
  String get showIcons => 'Show icons';

  @override
  String get showFolderChevron => 'Show folder chevron';

  @override
  String get showStatusBar => 'Show status bar';

  @override
  String get clockFontSize => 'Clock font size';

  @override
  String get use24HourClock => 'Use 24-hour clock';

  @override
  String get appFontSize => 'App font size';

  @override
  String get appIconSize => 'App icon size';

  @override
  String get appTheme => 'App theme';

  @override
  String get appThemeAuto => 'Auto';

  @override
  String get appThemeLight => 'Light';

  @override
  String get appThemeDark => 'Dark';

  @override
  String get appList => 'App list';

  @override
  String appsSelected(int count, int total) {
    return '$count of $total apps selected';
  }

  @override
  String get reorderAppsFolders => 'Reorder apps & folders';

  @override
  String get manageFolders => 'Manage folders';

  @override
  String get createAndOrganizeFolders => 'Create and organize app folders';

  @override
  String get gestures => 'Gestures';

  @override
  String get configureGestures => 'Configure application gestures';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get pressSettingsToStart => 'Press the settings button to start';

  @override
  String get loading => 'Loading...';

  @override
  String get errorLoadingApps => 'Error loading applications';

  @override
  String get noAppsSelected => 'No applications selected';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get renameApp => 'Rename App';

  @override
  String get moveToFolder => 'Move to Folder';

  @override
  String get noOtherFoldersAvailable => 'No other folders available to move this app to.';

  @override
  String get selectFolder => 'Select Folder';

  @override
  String get resetAppName => 'Reset App Name';

  @override
  String get folderName => 'Folder Name';

  @override
  String get editFolder => 'Edit Folder';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String deleteFolderConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String manageAppsInFolder(String name) {
    return 'Manage Apps in $name';
  }

  @override
  String get reOrderApps => 'Reorder Apps';

  @override
  String get errorSavingSettings => 'Error saving settings';

  @override
  String get gestureSettings => 'Gesture Settings';

  @override
  String get swipeUp => 'Swipe Up';

  @override
  String get longPress => 'Long Press';

  @override
  String get doubleTap => 'Double Tap';

  @override
  String get selectAction => 'Select Action';

  @override
  String get noAction => 'No Action';

  @override
  String get folderManagement => 'Folder Management';

  @override
  String get addAppsToFolder => 'Add Apps to Folder';

  @override
  String get removeAppsFromFolder => 'Remove Apps from Folder';

  @override
  String get reorderAppsInFolder => 'Reorder Apps';

  @override
  String get noFolders => 'No Folders';

  @override
  String get selectAppsForFolder => 'Select apps for folder';

  @override
  String get folderCreated => 'Folder created successfully';

  @override
  String get folderUpdated => 'Folder updated successfully';

  @override
  String get folderDeleted => 'Folder deleted successfully';

  @override
  String get selectApps => 'Select Apps';

  @override
  String get searchAppsHint => 'Search apps by name';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get appInfo => 'App Info';

  @override
  String get uninstallApp => 'Uninstall App';

  @override
  String get clearNotification => 'Clear notification';

  @override
  String confirmUninstall(String appName) {
    return 'Are you sure you want to uninstall $appName?';
  }

  @override
  String get appOptions => 'App Options';

  @override
  String get couldNotOpenApp => 'Could not open the application';

  @override
  String get selectAppsTitle => 'Select apps';

  @override
  String get gesturesTitle => 'Gestures';

  @override
  String get selectAppTitle => 'Select app';

  @override
  String appsInFolder(int count) {
    return '$count apps';
  }

  @override
  String get notSelected => 'Not selected';

  @override
  String selectedAppsCount(int count) {
    return '$count apps selected';
  }

  @override
  String get autoFocusSearch => 'Auto focus search';

  @override
  String get autoFocusSearchDescription => 'Cursor will be positioned in the search field when opened';

  @override
  String errorGettingAppInfo(String packageName) {
    return 'Error getting app info for $packageName';
  }

  @override
  String get errorUpdatingWeather => 'Error updating weather';

  @override
  String get colorMode => 'Color mode';

  @override
  String get wakeOnNotification => 'Wake on notification';

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get selectWallpaper => 'Select wallpaper';

  @override
  String get removeWallpaper => 'Remove wallpaper';

  @override
  String get noWallpaperSet => 'No wallpaper set';

  @override
  String get wallpaperBlur => 'Wallpaper blur';

  @override
  String get wallpaperOpacity => 'Wallpaper opacity';

  @override
  String get scrollToTop => 'Auto scroll on folder close';

  @override
  String get exportSettings => 'Export settings';

  @override
  String get exportSettingsSubtitle => 'Save current settings to JSON file';

  @override
  String get importSettings => 'Import settings';

  @override
  String get importSettingsSubtitle => 'Load settings from JSON file';

  @override
  String get exportSuccess => 'Settings exported successfully.';

  @override
  String exportFallbackSaved(String fileName) {
    return 'Exported to app storage: $fileName';
  }

  @override
  String get exportFailed => 'Failed to export settings';

  @override
  String get invalidFileSelection => 'Invalid file selection';

  @override
  String get invalidJsonFile => 'Invalid JSON file';

  @override
  String get importSuccess => 'Settings imported successfully.';

  @override
  String get importFailed => 'Failed to import settings';

  @override
  String exportSavedToDownloads(String fileName) {
    return 'Saved to Downloads: $fileName';
  }

  @override
  String get weatherApp => 'Weather app';

  @override
  String get selectWeatherApp => 'Select app to open when tapping weather icon';

  @override
  String get noWeatherAppSelected => 'No app selected';

  @override
  String get appAlignment => 'App alignment';

  @override
  String get appAlignmentLeft => 'Left';

  @override
  String get appAlignmentCenter => 'Center';

  @override
  String get appAlignmentRight => 'Right';

  @override
  String get iconPackSettingLabel => 'Icon pack';

  @override
  String get iconPackScreenTitle => 'Icon pack';

  @override
  String get iconPackNote => 'Note: Not all third-party icon packs are supported.';

  @override
  String get iconPackSystemDefault => 'System default';

  @override
  String get iconPackErrorLoading => 'Failed to load icon packs.';

  @override
  String get iconPackColorModeWarning => 'Cannot apply color mode when custom icon is selected';

  @override
  String get weatherApiKeyTitle => 'Weather API key';

  @override
  String get weatherApiKeyNotSet => 'Not set';

  @override
  String get weatherApiKeyCustomSet => 'Custom key set';

  @override
  String get weatherApiKeyDialogTitle => 'OpenWeather API key';

  @override
  String get weatherApiKeyDialogLabel => 'OpenWeather API key';

  @override
  String get weatherApiKeyDialogHint => 'Enter API key';

  @override
  String get weatherApiKeyDialogHelp => 'You can get your free API key from https://openweathermap.org/api';

  @override
  String get aboutTitle => 'About';

  @override
  String get sendFeedbackTitle => 'Send Feedback';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutLoadError => 'Unable to load app information';

  @override
  String get licenseScreenTitle => 'Open Source Licenses';

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutPrivacyPolicy => 'Privacy Policy';

  @override
  String get nuxTitle => 'Initial Setup';

  @override
  String get nuxDescription => 'These steps are optional. You can continue at any time, but enabling them will unlock weather and notification features.';

  @override
  String get nuxLocationTitle => 'Location';

  @override
  String get nuxLocationBody => 'Used only to fetch your local weather using approximate location. Your location is never stored or sent anywhere else.';

  @override
  String get nuxNotificationTitle => 'Notification Access';

  @override
  String get nuxNotificationBody => 'Used to show your latest notifications under app names. Notification content never leaves your device.';

  @override
  String get nuxLauncherTitle => 'Set Think Launcher as Default';

  @override
  String get nuxLauncherBody => 'To use Think Launcher as your home screen, set it as the default launcher in Android settings.';

  @override
  String get nuxContinue => 'Get Started';

  @override
  String get nuxOptionalNote => 'Location and notification access are optional. You can change them later in Settings.';

  @override
  String get enableLocationForWeather => 'Enable location to configure weather.';

  @override
  String get openLocationSettings => 'Open location settings';

  @override
  String get donatePaypalTitle => 'Donate with PayPal';
}
