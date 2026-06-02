// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Think Launcher';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get pressSettingsButtonToStart => 'Druk op de instellingenknop om te starten';

  @override
  String get numberOfApps => 'Aantal apps';

  @override
  String get back => 'Rug';

  @override
  String get searchApps => 'Zoek apps';

  @override
  String get showSearchButton => 'Toon zoekknop';

  @override
  String get longPressGestureDisabled => 'Lang indrukken is uitgeschakeld. Schakel het in bij gebarinstellingen om deze knop te verbergen.';

  @override
  String get useBoldFont => 'Gebruik vet lettertype';

  @override
  String get enableListScrolling => 'Scrollen in lijst inschakelen';

  @override
  String get showIcons => 'Toon pictogrammen';

  @override
  String get showFolderChevron => 'Map-chevron tonen';

  @override
  String get showStatusBar => 'Toon statusbalk';

  @override
  String get clockFontSize => 'Klok lettergrootte';

  @override
  String get use24HourClock => '24-uursklok gebruiken';

  @override
  String get appFontSize => 'App lettergrootte';

  @override
  String get appIconSize => 'App pictogramgrootte';

  @override
  String get appTheme => 'App-thema';

  @override
  String get appThemeAuto => 'Auto';

  @override
  String get appThemeLight => 'Licht';

  @override
  String get appThemeDark => 'Donker';

  @override
  String get appList => 'App lijst';

  @override
  String appsSelected(int count, int total) {
    return '$count van $total apps geselecteerd';
  }

  @override
  String get reorderAppsFolders => 'Apps en mappen opnieuw ordenen';

  @override
  String get manageFolders => 'Mappen beheren';

  @override
  String get createAndOrganizeFolders => 'Maak en organiseer app-mappen';

  @override
  String get gestures => 'Gebaren';

  @override
  String get configureGestures => 'Configureer app-gebaren';

  @override
  String get save => 'Opslaan';

  @override
  String get delete => 'Verwijderen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get pressSettingsToStart => 'Druk op de instellingenknop om te beginnen';

  @override
  String get loading => 'Laden...';

  @override
  String get errorLoadingApps => 'Fout bij laden van applicaties';

  @override
  String get noAppsSelected => 'Geen applicaties geselecteerd';

  @override
  String get createFolder => 'Map maken';

  @override
  String get renameApp => 'App hernoemen';

  @override
  String get moveToFolder => 'Verplaats naar map';

  @override
  String get noOtherFoldersAvailable => 'Er zijn geen andere mappen beschikbaar om deze app naartoe te verplaatsen.';

  @override
  String get selectFolder => 'Selecteer map';

  @override
  String get resetAppName => 'App-naam resetten';

  @override
  String get folderName => 'Mapnaam';

  @override
  String get editFolder => 'Map bewerken';

  @override
  String get deleteFolder => 'Map verwijderen';

  @override
  String deleteFolderConfirm(String name) {
    return 'Weet je zeker dat je \"$name\" wilt verwijderen?';
  }

  @override
  String manageAppsInFolder(String name) {
    return 'Apps beheren in $name';
  }

  @override
  String get reOrderApps => 'Apps en mappen opnieuw ordenen';

  @override
  String get errorSavingSettings => 'Fout bij opslaan van instellingen';

  @override
  String get gestureSettings => 'Gebareninstellingen';

  @override
  String get swipeUp => 'Omhoog vegen';

  @override
  String get longPress => 'Lang indrukken';

  @override
  String get doubleTap => 'Dubbeltikken';

  @override
  String get selectAction => 'Selecteer actie';

  @override
  String get noAction => 'Geen actie';

  @override
  String get folderManagement => 'Mappenbeheer';

  @override
  String get addAppsToFolder => 'Apps toevoegen aan map';

  @override
  String get removeAppsFromFolder => 'Apps verwijderen uit map';

  @override
  String get reorderAppsInFolder => 'Apps opnieuw ordenen';

  @override
  String get noFolders => 'Geen mappen';

  @override
  String get selectAppsForFolder => 'Selecteer apps voor map';

  @override
  String get folderCreated => 'Map succesvol aangemaakt';

  @override
  String get folderUpdated => 'Map succesvol bijgewerkt';

  @override
  String get folderDeleted => 'Map succesvol verwijderd';

  @override
  String get selectApps => 'Apps selecteren';

  @override
  String get searchAppsHint => 'Zoek apps op naam';

  @override
  String get selectAll => 'Alles selecteren';

  @override
  String get deselectAll => 'Alles deselecteren';

  @override
  String get appInfo => 'App-info';

  @override
  String get uninstallApp => 'App verwijderen';

  @override
  String get clearNotification => 'Melding wissen';

  @override
  String confirmUninstall(String appName) {
    return 'Weet je zeker dat je $appName wilt verwijderen?';
  }

  @override
  String get appOptions => 'App-opties';

  @override
  String get couldNotOpenApp => 'Kon de applicatie niet openen';

  @override
  String get selectAppsTitle => 'Apps selecteren';

  @override
  String get gesturesTitle => 'Gebaren';

  @override
  String get selectAppTitle => 'App selecteren';

  @override
  String appsInFolder(int count) {
    return '$count apps';
  }

  @override
  String get notSelected => 'Niet geselecteerd';

  @override
  String selectedAppsCount(int count) {
    return '$count apps geselecteerd';
  }

  @override
  String get autoFocusSearch => 'Automatisch zoeken focussen';

  @override
  String get autoFocusSearchDescription => 'Cursor wordt in het zoekveld geplaatst bij openen';

  @override
  String errorGettingAppInfo(String packageName) {
    return 'Fout bij ophalen van app-info voor $packageName';
  }

  @override
  String get errorUpdatingWeather => 'Fout bij bijwerken van het weer';

  @override
  String get colorMode => 'Kleurmodus';

  @override
  String get wakeOnNotification => 'Wakker worden met melding';

  @override
  String get wallpaper => 'Achtergrond';

  @override
  String get selectWallpaper => 'Achtergrond selecteren';

  @override
  String get removeWallpaper => 'Achtergrond verwijderen';

  @override
  String get noWallpaperSet => 'Geen achtergrond ingesteld';

  @override
  String get wallpaperBlur => 'Achtergrond vervagen';

  @override
  String get wallpaperOpacity => 'Achtergrond transparantie';

  @override
  String get scrollToTop => 'Automatisch scrollen bij het sluiten van een map';

  @override
  String get exportSettings => 'Instellingen exporteren';

  @override
  String get exportSettingsSubtitle => 'Huidige instellingen opslaan als JSON';

  @override
  String get importSettings => 'Instellingen importeren';

  @override
  String get importSettingsSubtitle => 'Instellingen laden uit JSON-bestand';

  @override
  String get exportSuccess => 'Instellingen succesvol geëxporteerd.';

  @override
  String exportFallbackSaved(String fileName) {
    return 'Geëxporteerd naar app-opslag: $fileName';
  }

  @override
  String get exportFailed => 'Exporteren van instellingen mislukt';

  @override
  String get invalidFileSelection => 'Ongeldige bestandsselectie';

  @override
  String get invalidJsonFile => 'Ongeldig JSON-bestand';

  @override
  String get importSuccess => 'Instellingen succesvol geïmporteerd.';

  @override
  String get importFailed => 'Importeren van instellingen mislukt';

  @override
  String exportSavedToDownloads(String fileName) {
    return 'Opgeslagen in Downloads: $fileName';
  }

  @override
  String get weatherApp => 'Weer-app';

  @override
  String get selectWeatherApp => 'Selecteer app om te openen bij tikken op weerpictogram';

  @override
  String get noWeatherAppSelected => 'Geen app geselecteerd';

  @override
  String get appAlignment => 'App-uitlijning';

  @override
  String get appAlignmentLeft => 'Links';

  @override
  String get appAlignmentCenter => 'Midden';

  @override
  String get appAlignmentRight => 'Rechts';

  @override
  String get iconPackSettingLabel => 'Pictogrampakket';

  @override
  String get iconPackScreenTitle => 'Pictogrampakket';

  @override
  String get iconPackNote => 'Let op: niet alle pictogrampakketten van derden worden ondersteund.';

  @override
  String get iconPackSystemDefault => 'Systeemstandaard';

  @override
  String get iconPackErrorLoading => 'Laden van pictogrampakketten mislukt.';

  @override
  String get iconPackColorModeWarning => 'Kan de kleurmodus niet toepassen als een aangepast pictogram is geselecteerd';

  @override
  String get weatherApiKeyTitle => 'Weer-API-sleutel';

  @override
  String get weatherApiKeyNotSet => 'Niet ingesteld';

  @override
  String get weatherApiKeyCustomSet => 'Aangepaste sleutel ingesteld';

  @override
  String get weatherApiKeyDialogTitle => 'OpenWeather API-sleutel';

  @override
  String get weatherApiKeyDialogLabel => 'OpenWeather API-sleutel';

  @override
  String get weatherApiKeyDialogHint => 'Voer API-sleutel in';

  @override
  String get weatherApiKeyDialogHelp => 'Je kunt je gratis API-sleutel verkrijgen via https://openweathermap.org/api';

  @override
  String get aboutTitle => 'Over';

  @override
  String get sendFeedbackTitle => 'Feedback verzenden';

  @override
  String get aboutVersionLabel => 'Versie';

  @override
  String get aboutLoadError => 'Kan app-informatie niet laden';

  @override
  String get licenseScreenTitle => 'Open source licenties';

  @override
  String get aboutOpenSourceLicenses => 'Open source licenties';

  @override
  String get aboutPrivacyPolicy => 'Privacybeleid';

  @override
  String get nuxTitle => 'Initiële installatie';

  @override
  String get nuxDescription => 'Deze stappen zijn optioneel. Je kunt altijd doorgaan, maar het inschakelen hiervan ontgrendelt weer- en meldingsfuncties.';

  @override
  String get nuxLocationTitle => 'Locatie';

  @override
  String get nuxLocationBody => 'Wordt alleen gebruikt om uw lokale weer op te halen op basis van uw geschatte locatie. Uw locatie wordt nooit opgeslagen of ergens anders naartoe verzonden.';

  @override
  String get nuxNotificationTitle => 'Meldingstoegang';

  @override
  String get nuxNotificationBody => 'Gebruikt om je laatste meldingen onder app-namen te tonen. Meldingsinhoud verlaat je apparaat nooit.';

  @override
  String get nuxLauncherTitle => 'Stel Think Launcher in als standaard';

  @override
  String get nuxLauncherBody => 'Om Think Launcher als je startscherm te gebruiken, stel je het in als standaard-launcher in de Android-instellingen.';

  @override
  String get nuxContinue => 'Aan de slag';

  @override
  String get nuxOptionalNote => 'Locatie- en meldingstoegang zijn optioneel. Je kunt dit later wijzigen in Instellingen.';

  @override
  String get enableLocationForWeather => 'Schakel locatie in om weer in te stellen.';

  @override
  String get openLocationSettings => 'Locatie-instellingen openen';

  @override
  String get donatePaypalTitle => 'Doneer met PayPal';
}
