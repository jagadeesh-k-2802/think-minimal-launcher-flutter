import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';
import 'package:think_launcher/screens/app_selection_screen.dart';
import 'package:think_launcher/screens/folder_management_screen.dart';
import 'package:think_launcher/screens/gesture_settings_screen.dart';
import 'package:think_launcher/screens/reorder_screen.dart';
import 'package:think_launcher/screens/single_app_selection_screen.dart';
import 'package:think_launcher/screens/icon_pack_screen.dart';
import 'package:think_launcher/models/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:think_launcher/constants/app_alignment.dart';
import 'package:think_launcher/constants/app_theme.dart';
import 'package:think_launcher/screens/about_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool showSearchButton = true;
  double clockFontSize = 18.0;
  bool use24HourClock = false;
  double appFontSize = 18.0;
  double appIconSize = 35.0;
  bool enableScroll = true;
  bool showIcons = false;
  bool showFolderChevron = true;
  bool colorMode = true;
  bool wakeOnNotification = false;
  bool scrollToTop = false;
  List<String> selectedApps = [];
  bool isLoading = false;
  String? errorMessage;
  String? wallpaperPath;
  double wallpaperBlur = 0.0; // 0 = no blur when no wallpaper; 1-10 when set
  double wallpaperOpacity = 1.0; // 0.0 = completely transparent, 1.0 = fully opaque
  String? weatherAppPackageName;
  AppAlignment appAlignment = AppAlignment.left;
  AppThemeMode appTheme = AppThemeMode.auto;
  String? iconPackPackageName;
  String? iconPackAppName;
  String? weatherApiKey;
  bool _locationEnabledForWeather = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _refreshLocationPermission();
  }

  void _loadSettings() {
    setState(() {
      showSearchButton = widget.prefs.getBool('showSearchButton') ?? true;
      clockFontSize = widget.prefs.getDouble('clockFontSize') ?? 18.0;
      use24HourClock = widget.prefs.getBool('use24HourClock') ?? false;
      appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
      appIconSize = widget.prefs.getDouble('appIconSize') ?? 35.0;
      enableScroll = widget.prefs.getBool('enableScroll') ?? true;
      showIcons = widget.prefs.getBool('showIcons') ?? true;
      showFolderChevron = widget.prefs.getBool('showFolderChevron') ?? true;
      colorMode = widget.prefs.getBool('colorMode') ?? true;
      wakeOnNotification = widget.prefs.getBool('wakeOnNotification') ?? false;
      scrollToTop = widget.prefs.getBool('scrollToTop') ?? false;
      selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
      wallpaperPath = widget.prefs.getString('wallpaperPath');
      wallpaperBlur = wallpaperPath == null
          ? 0.0
          : (widget.prefs.getDouble('wallpaperBlur') ?? 3.0);
      if (wallpaperPath != null && wallpaperBlur < 1.0) {
        wallpaperBlur = 1.0;
      }
      wallpaperOpacity = widget.prefs.getDouble('wallpaperOpacity') ?? 1.0;
      weatherAppPackageName = widget.prefs.getString('weatherAppPackageName');
      appAlignment =
          appAlignmentFromStorage(widget.prefs.getString('appAlignment'));
      appTheme =
          appThemeModeFromStorage(widget.prefs.getString('appTheme'));
      iconPackPackageName = widget.prefs.getString('iconPackPackageName');
      iconPackAppName = widget.prefs.getString('iconPackAppName');
      weatherApiKey = widget.prefs.getString('weatherApiKey');
    });
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await widget.prefs.setBool('showSearchButton', showSearchButton);
      await widget.prefs.setDouble('clockFontSize', clockFontSize);
      await widget.prefs.setBool('use24HourClock', use24HourClock);
      await widget.prefs.setDouble('appFontSize', appFontSize);
      await widget.prefs.setDouble('appIconSize', appIconSize);
      await widget.prefs.setBool('enableScroll', enableScroll);
      await widget.prefs.setBool('showIcons', showIcons);
      await widget.prefs.setBool('showFolderChevron', showFolderChevron);
      await widget.prefs.setBool('colorMode', colorMode);
      await widget.prefs.setBool('wakeOnNotification', wakeOnNotification);
      await widget.prefs.setBool('scrollToTop', scrollToTop);
      await widget.prefs.setStringList('selectedApps', selectedApps);
      if (wallpaperPath == null) {
        await widget.prefs.remove('wallpaperPath');
      } else {
        await widget.prefs.setString('wallpaperPath', wallpaperPath!);
      }
      await widget.prefs.setDouble('wallpaperBlur', wallpaperBlur);
      await widget.prefs.setDouble('wallpaperOpacity', wallpaperOpacity);
      if (weatherAppPackageName == null) {
        await widget.prefs.remove('weatherAppPackageName');
      } else {
        await widget.prefs.setString('weatherAppPackageName', weatherAppPackageName!);
      }
      await widget.prefs.setString('appAlignment', appAlignment.storageKey);
      await widget.prefs.setString('appTheme', appTheme.storageKey);

      if (iconPackPackageName == null) {
        await widget.prefs.remove('iconPackPackageName');
        await widget.prefs.remove('iconPackAppName');
      } else {
        await widget.prefs.setString('iconPackPackageName', iconPackPackageName!);
        if (iconPackAppName != null && iconPackAppName!.isNotEmpty) {
          await widget.prefs.setString('iconPackAppName', iconPackAppName!);
        }
      }

      if (weatherApiKey == null || weatherApiKey!.isEmpty) {
        await widget.prefs.remove('weatherApiKey');
      } else {
        await widget.prefs.setString('weatherApiKey', weatherApiKey!);
      }

      // Notify app about theme changes so MaterialApp can update.
      appThemeNotifier.value = appTheme;

      // Update status bar visibility
      final showStatusBar = widget.prefs.getBool('showStatusBar') ?? false;
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: showStatusBar
            ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
            : [SystemUiOverlay.bottom],
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.errorSavingSettings;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationEnabledForWeather = false;
        });
        return;
      }

      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!mounted) return;
      setState(() {
        _locationEnabledForWeather = granted;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationEnabledForWeather = false;
      });
    }
  }

  void _showEnableLocationForWeatherSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.enableLocationForWeather,
        ),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.openLocationSettings,
          onPressed: () {
            Geolocator.openLocationSettings();
          },
        ),
      ),
    );
  }

  Future<void> _selectApps() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AppSelectionScreen(
            prefs: widget.prefs,
            selectedApps: List.from(selectedApps),
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedApps = List.from(result);
      });
      await _saveSettings();
    }
  }

  Future<void> _reorderApps() async {
    if (selectedApps.isEmpty) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ReorderAppsScreen(prefs: widget.prefs, folder: null);
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedApps = result;
        _saveSettings();
      });
    }
  }

  Future<void> _selectWeatherApp() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return SingleAppSelectionScreen(
            prefs: widget.prefs,
            currentlySelectedPackageName: weatherAppPackageName,
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is String) {
      setState(() {
        weatherAppPackageName = result;
      });
      await _saveSettings();
    }
    // If result is null, user pressed back - don't change anything
  }

  Future<void> _selectIconPack() async {
    final result = await Navigator.push<Map<String, String>?>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return IconPackScreen(
            selectedIconPackPackage: iconPackPackageName,
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!mounted || result == null) return;

    final selectedPackage = result['packageName'] ?? '';
    final selectedName = result['name'] ?? '';

    setState(() {
      if (selectedPackage.isEmpty) {
        // System default
        iconPackPackageName = null;
        iconPackAppName = null;
      } else {
        iconPackPackageName = selectedPackage;
        iconPackAppName =
            selectedName.isNotEmpty ? selectedName : selectedPackage;
      }
    });

    await _saveSettings();
  }

  Future<String?> _getWeatherAppName() async {
    if (weatherAppPackageName == null) return null;
    try {
      final app = await InstalledApps.getAppInfo(weatherAppPackageName!);
      if (app == null) return null;
      final appInfo = AppInfo.fromInstalledApps(app);
      // Check for custom name
      final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
      final customNames = Map<String, String>.from(jsonDecode(customNamesJson));
      final customName = customNames[weatherAppPackageName!];
      return customName ?? appInfo.name;
    } catch (e) {
      debugPrint('Error getting weather app name: $e');
      return null;
    }
  }

  Future<void> _editWeatherApiKey() async {
    final controller = TextEditingController(text: weatherApiKey ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.weatherApiKeyDialogTitle,
            style: const TextStyle(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.weatherApiKeyDialogLabel,
                  hintText:
                      AppLocalizations.of(context)!.weatherApiKeyDialogHint,
                ),
                autofocus: true,
                autocorrect: false,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final uri =
                      Uri.parse('https://openweathermap.org/api');
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    // ignore launch failures
                  }
                },
                child: Text(
                  AppLocalizations.of(context)!.weatherApiKeyDialogHelp,
                  style: const TextStyle(
                    fontSize: 12
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        weatherApiKey = result.isEmpty ? null : result;
      });
      await _saveSettings();
    }
  }

  Future<void> _exportSettings() async {
    try {
      final prefs = widget.prefs;
      final Map<String, dynamic> data = {
        'showSearchButton': prefs.getBool('showSearchButton') ?? true,
        'enableScroll': prefs.getBool('enableScroll') ?? true,
        'showIcons': prefs.getBool('showIcons') ?? true,
        'colorMode': prefs.getBool('colorMode') ?? true,
        'wakeOnNotification': prefs.getBool('wakeOnNotification') ?? false,
        'scrollToTop': prefs.getBool('scrollToTop') ?? false,
        'clockFontSize': prefs.getDouble('clockFontSize') ?? 18.0,
        'use24HourClock': prefs.getBool('use24HourClock') ?? false,
        'appFontSize': prefs.getDouble('appFontSize') ?? 18.0,
        'appIconSize': prefs.getDouble('appIconSize') ?? 35.0,
        'selectedApps': prefs.getStringList('selectedApps') ?? <String>[],
        'showStatusBar': prefs.getBool('showStatusBar') ?? false,
        'showFolderChevron': prefs.getBool('showFolderChevron') ?? true,
        'wallpaperBlur': prefs.getDouble('wallpaperBlur') ?? 0.0,
        'wallpaperOpacity': prefs.getDouble('wallpaperOpacity') ?? 1.0,
        'appAlignment':
            prefs.getString('appAlignment') ?? AppAlignment.left.storageKey,
        'appTheme':
            prefs.getString('appTheme') ?? AppThemeMode.auto.storageKey,
      };

      final String jsonText = const JsonEncoder.withIndent('  ').convert(data);

      String? savePath;
      final formattedDate = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
      final fileName = 'think_launcher_settings_$formattedDate.json';
      try {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context)!.exportSettings,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
      } catch (_) {
        savePath = null;
      }

      if (savePath == null) {
        // Try saving to public Downloads directory first (Android only)
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          final fallback = '${downloadsDir.path}/$fileName';
          await File(fallback).writeAsString(jsonText);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .exportSavedToDownloads(Uri.file(fallback).pathSegments.last),
            ),
          ));
          return;
        } catch (_) {
          // Fallback to app-specific external storage if Downloads isn't writable
          final dir = await getExternalStorageDirectory();
          final fallback = '${dir?.path}/$fileName';
          await File(fallback).writeAsString(jsonText);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .exportFallbackSaved(Uri.file(fallback).pathSegments.last),
            ),
          ));
          return;
        }
      }

      await File(savePath).writeAsString(jsonText);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.exportSuccess),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = AppLocalizations.of(context)!.exportFailed;
      });
    }
  }

  Future<void> _importSettings() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final String? path = result.files.single.path;
      if (path == null) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.invalidFileSelection;
        });
        return;
      }

      final String content = await File(path).readAsString();
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(content);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Root is not an object');
        }
        data = decoded;
      } catch (_) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.invalidJsonFile;
        });
        return;
      }

      // Helper getters with type safety and descriptive names
      bool? getBoolOrNull(String key) {
        return data[key] is bool ? data[key] as bool : null;
      }

      double? getDoubleOrNull(String key) {
        return data[key] is num ? data[key].toDouble() : null;
      }

      List<String>? getStringListOrNull(String key) {
        final value = data[key];
        if (value is List) {
          final list = value.whereType<String>().toList();
          return list.length == value.length ? list : null;
        }
        return null;
      }

      String? getStringOrNull(String key) {
        final value = data[key];
        return value is String ? value : null;
      }

      final prefs = widget.prefs;

      // Apply known keys only
      final bool? vShowSearchButton = getBoolOrNull('showSearchButton');
      if (vShowSearchButton != null) {
        await prefs.setBool('showSearchButton', vShowSearchButton);
      }

      final bool? vEnableScroll = getBoolOrNull('enableScroll');
      if (vEnableScroll != null) {
        await prefs.setBool('enableScroll', vEnableScroll);
      }

      final bool? vShowIcons = getBoolOrNull('showIcons');
      if (vShowIcons != null) {
        await prefs.setBool('showIcons', vShowIcons);
      }

      final bool? vColorMode = getBoolOrNull('colorMode');
      if (vColorMode != null) {
        await prefs.setBool('colorMode', vColorMode);
      }

      final bool? vShowFolderChevron = getBoolOrNull('showFolderChevron');
      if (vShowFolderChevron != null) {
        await prefs.setBool('showFolderChevron', vShowFolderChevron);
      }

      final bool? vWakeOnNotification = getBoolOrNull('wakeOnNotification');
      if (vWakeOnNotification != null) {
        await prefs.setBool('wakeOnNotification', vWakeOnNotification);
      }

      final bool? vScrollToTop = getBoolOrNull('scrollToTop');
      if (vScrollToTop != null) {
        await prefs.setBool('scrollToTop', vScrollToTop);
      }

      final bool? vUse24HourClock = getBoolOrNull('use24HourClock');
      if (vUse24HourClock != null) {
        await prefs.setBool('use24HourClock', vUse24HourClock);
      }

      final double? vClockFontSize = getDoubleOrNull('clockFontSize');
      if (vClockFontSize != null) {
        await prefs.setDouble('clockFontSize', vClockFontSize);
      }

      final double? vAppFontSize = getDoubleOrNull('appFontSize');
      if (vAppFontSize != null) {
        await prefs.setDouble('appFontSize', vAppFontSize);
      }

      final double? vAppIconSize = getDoubleOrNull('appIconSize');
      if (vAppIconSize != null) {
        await prefs.setDouble('appIconSize', vAppIconSize);
      }

      final List<String>? vSelectedApps = getStringListOrNull('selectedApps');
      if (vSelectedApps != null) {
        await prefs.setStringList('selectedApps', vSelectedApps);
      }

      final bool? vShowStatusBar = getBoolOrNull('showStatusBar');
      if (vShowStatusBar != null) {
        await prefs.setBool('showStatusBar', vShowStatusBar);
      }

      final double? vWallpaperBlur = getDoubleOrNull('wallpaperBlur');
      if (vWallpaperBlur != null) {
        await prefs.setDouble('wallpaperBlur', vWallpaperBlur);
      }

      final double? vWallpaperOpacity = getDoubleOrNull('wallpaperOpacity');
      if (vWallpaperOpacity != null) {
        await prefs.setDouble('wallpaperOpacity', vWallpaperOpacity);
      }

      final String? vAppAlignment = getStringOrNull('appAlignment');
      if (vAppAlignment != null) {
        final importedAlignment = appAlignmentFromStorage(vAppAlignment);
        await prefs.setString('appAlignment', importedAlignment.storageKey);
      }

      final String? vAppTheme = getStringOrNull('appTheme');
      if (vAppTheme != null) {
        final importedTheme = appThemeModeFromStorage(vAppTheme);
        await prefs.setString('appTheme', importedTheme.storageKey);
        appThemeNotifier.value = importedTheme;
      }

      // Refresh UI and system UI overlays
      if (!mounted) return;
      _loadSettings();
      final showStatusBar = prefs.getBool('showStatusBar') ?? false;
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: showStatusBar
            ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
            : [SystemUiOverlay.bottom],
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.importSuccess),
      ));
    } catch (e) {
      debugPrint('Error importing settings: $e');
      if (!mounted) return;
      setState(() {
        errorMessage = AppLocalizations.of(context)!.importFailed;
      });
    }
  }

  Widget _buildAlignmentOption(
    BuildContext context,
    AppAlignment value,
    String label,
  ) {
    final selected = appAlignment == value;
    ThemeData theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              appAlignment = value;
            });
            _saveSettings();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? theme.colorScheme.onSurface : theme.colorScheme.surface,
            foregroundColor: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppThemeMode value,
    String label,
  ) {
    ThemeData theme = Theme.of(context);
    final selected = appTheme == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              appTheme = value;
            });
            _saveSettings();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? theme.colorScheme.onSurface : theme.colorScheme.surface,
            foregroundColor: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settingsTitle),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                ),
                child: ScrollConfiguration(
                  behavior: NoGlowScrollBehavior(),
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    children: [
                      // Appearance: theme & colors
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.appTheme,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            _buildThemeOption(
                              context,
                              AppThemeMode.auto,
                              AppLocalizations.of(context)!.appThemeAuto,
                            ),
                            _buildThemeOption(
                              context,
                              AppThemeMode.light,
                              AppLocalizations.of(context)!.appThemeLight,
                            ),
                            _buildThemeOption(
                              context,
                              AppThemeMode.dark,
                              AppLocalizations.of(context)!.appThemeDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: iconPackPackageName == null ? 1.0 : 0.4,
                        child: SwitchListTile(
                          title: Text(
                            AppLocalizations.of(context)!.colorMode,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          value: colorMode,
                          onChanged: (value) {
                            if (iconPackPackageName != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .iconPackColorModeWarning,
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              colorMode = value;
                            });
                            _saveSettings();
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showIcons,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: showIcons,
                        onChanged: (value) {
                          setState(() {
                            showIcons = value;
                          });
                          _saveSettings();
                        },
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.iconPackSettingLabel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          iconPackAppName ??
                              AppLocalizations.of(context)!
                                  .iconPackSystemDefault,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface,
                        ),
                        onTap: _selectIconPack,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.wallpaper,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          wallpaperPath == null
                              ? AppLocalizations.of(context)!.noWallpaperSet
                              : Uri.file(wallpaperPath!).pathSegments.isNotEmpty
                                  ? Uri.file(wallpaperPath!).pathSegments.last
                                  : wallpaperPath!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: wallpaperPath == null
                            ? const Icon(Icons.chevron_right)
                            : IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  setState(() {
                                    wallpaperPath = null;
                                    wallpaperBlur = 0.0;
                                    wallpaperOpacity = 1.0;
                                  });
                                  await _saveSettings();
                                },
                              ),
                        onTap: () async {
                          final picker = ImagePicker();
                          final XFile? picked =
                              await picker.pickImage(
                            source: ImageSource.gallery,
                            requestFullMetadata: false,
                          );
                          if (picked != null) {
                            try {
                              final appDir =
                                  await getApplicationDocumentsDirectory();
                              final wallpapersDir =
                                  Directory('${appDir.path}/wallpapers');
                              if (!await wallpapersDir.exists()) {
                                await wallpapersDir.create(recursive: true);
                              }

                              final String filename =
                                  Uri.file(picked.path).pathSegments.last;
                              final String destPath =
                                  '${wallpapersDir.path}/$filename';

                              final savedFile =
                                  await File(picked.path).copy(destPath);

                              setState(() {
                                wallpaperPath = savedFile.path;
                                if (wallpaperBlur == 0.0) {
                                  wallpaperBlur = 3.0;
                                }
                                wallpaperOpacity = 1.0;
                              });
                              await _saveSettings();
                            } catch (e) {
                              setState(() {
                                wallpaperPath = picked.path;
                                if (wallpaperBlur == 0.0) {
                                  wallpaperBlur = 3.0;
                                }
                              });
                              await _saveSettings();
                            }
                          }
                        },
                      ),
                      if (wallpaperPath != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0,
                            16.0,
                            8.0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.wallpaperBlur,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: wallpaperBlur > 1.0
                                        ? () {
                                            setState(() {
                                              wallpaperBlur =
                                                  (wallpaperBlur - 1)
                                                      .clamp(1.0, 10.0);
                                            });
                                            _saveSettings();
                                          }
                                        : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        overlayShape:
                                            SliderComponentShape.noOverlay,
                                        valueIndicatorColor:
                                            Colors.transparent,
                                        valueIndicatorTextStyle: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        thumbShape:
                                            const RoundSliderThumbShape(
                                          enabledThumbRadius: 12,
                                          elevation: 0,
                                          pressedElevation: 0,
                                        ),
                                        trackHeight: 2,
                                        activeTrackColor:
                                            theme.colorScheme.onSurface,
                                        inactiveTrackColor:
                                            theme.colorScheme.onSurface,
                                        thumbColor:
                                            theme.colorScheme.onSurface,
                                        overlayColor: Colors.transparent,
                                        showValueIndicator:
                                            ShowValueIndicator.onDrag,
                                      ),
                                      child: Slider(
                                        value: wallpaperBlur,
                                        min: 1,
                                        max: 10,
                                        divisions: 9,
                                        label:
                                            wallpaperBlur.toStringAsFixed(0),
                                        onChanged: (value) {
                                          setState(() {
                                            wallpaperBlur = value;
                                          });
                                          _saveSettings();
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: wallpaperBlur < 10.0
                                        ? () {
                                            setState(() {
                                              wallpaperBlur =
                                                  (wallpaperBlur + 1)
                                                      .clamp(1.0, 10.0);
                                            });
                                            _saveSettings();
                                          }
                                        : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            8.0,
                            16.0,
                            8.0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.wallpaperOpacity,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: wallpaperOpacity > 0.1
                                        ? () {
                                            setState(() {
                                              wallpaperOpacity =
                                                  (wallpaperOpacity - 0.1)
                                                      .clamp(0.0, 1.0);
                                            });
                                            _saveSettings();
                                          }
                                        : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        overlayShape:
                                            SliderComponentShape.noOverlay,
                                        valueIndicatorColor:
                                            Colors.transparent,
                                        valueIndicatorTextStyle: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        thumbShape:
                                            const RoundSliderThumbShape(
                                          enabledThumbRadius: 12,
                                          elevation: 0,
                                          pressedElevation: 0,
                                        ),
                                        trackHeight: 2,
                                        activeTrackColor:
                                            theme.colorScheme.onSurface,
                                        inactiveTrackColor:
                                            theme.colorScheme.onSurface,
                                        thumbColor:
                                            theme.colorScheme.onSurface,
                                        overlayColor: Colors.transparent,
                                        showValueIndicator:
                                            ShowValueIndicator.onDrag,
                                      ),
                                      child: Slider(
                                        value: wallpaperOpacity,
                                        min: 0.0,
                                        max: 1.0,
                                        divisions: 10,
                                        label:
                                            '${(wallpaperOpacity * 100).toStringAsFixed(0)}%',
                                        onChanged: (value) {
                                          setState(() {
                                            wallpaperOpacity = value;
                                          });
                                          _saveSettings();
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: wallpaperOpacity < 1.0
                                        ? () {
                                            setState(() {
                                              wallpaperOpacity =
                                                  (wallpaperOpacity + 0.1)
                                                      .clamp(0.0, 1.0);
                                            });
                                            _saveSettings();
                                          }
                                        : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.clockFontSize,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: clockFontSize > 18
                                  ? () {
                                      setState(() {
                                        clockFontSize--;
                                      });
                                      _saveSettings();
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape:
                                      SliderComponentShape.noOverlay,
                                  valueIndicatorColor: Colors.transparent,
                                  valueIndicatorTextStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  trackHeight: 2,
                                  activeTrackColor:
                                      theme.colorScheme.onSurface,
                                  inactiveTrackColor:
                                      theme.colorScheme.onSurface,
                                  thumbColor: theme.colorScheme.onSurface,
                                  overlayColor: Colors.transparent,
                                  showValueIndicator:
                                      ShowValueIndicator.onlyForContinuous,
                                ),
                                child: Slider(
                                  value: clockFontSize,
                                  min: 18,
                                  max: 64,
                                  label: clockFontSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      clockFontSize =
                                          value.roundToDouble();
                                    });
                                    _saveSettings();
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: clockFontSize < 72
                                  ? () {
                                      setState(() {
                                        clockFontSize++;
                                      });
                                      _saveSettings();
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.use24HourClock,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: use24HourClock,
                        onChanged: (value) {
                          setState(() {
                            use24HourClock = value;
                          });
                          _saveSettings();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.appFontSize,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: appFontSize > 14
                                  ? () {
                                      setState(() {
                                        appFontSize--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape:
                                      SliderComponentShape.noOverlay,
                                  valueIndicatorColor: Colors.transparent,
                                  valueIndicatorTextStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  trackHeight: 2,
                                  activeTrackColor:
                                      theme.colorScheme.onSurface,
                                  inactiveTrackColor:
                                      theme.colorScheme.onSurface,
                                  thumbColor: theme.colorScheme.onSurface,
                                  overlayColor: Colors.transparent,
                                  showValueIndicator:
                                      ShowValueIndicator.onlyForContinuous,
                                ),
                                child: Slider(
                                  value: appFontSize,
                                  min: 14,
                                  max: 32,
                                  label: appFontSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      appFontSize =
                                          value.roundToDouble();
                                    });
                                    _saveSettings();
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: appFontSize < 32
                                  ? () {
                                      setState(() {
                                        appFontSize++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.appIconSize,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: appIconSize > 16
                                  ? () {
                                      setState(() {
                                        appIconSize--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape:
                                      SliderComponentShape.noOverlay,
                                  valueIndicatorColor: Colors.transparent,
                                  valueIndicatorTextStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  trackHeight: 2,
                                  activeTrackColor:
                                      theme.colorScheme.onSurface,
                                  inactiveTrackColor:
                                      theme.colorScheme.onSurface,
                                  thumbColor: theme.colorScheme.onSurface,
                                  overlayColor: Colors.transparent,
                                  showValueIndicator:
                                      ShowValueIndicator.onlyForContinuous,
                                ),
                                child: Slider(
                                  value: appIconSize,
                                  min: 16,
                                  max: 128,
                                  label: appIconSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      appIconSize =
                                          value.roundToDouble();
                                    });
                                    _saveSettings();
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: appIconSize < 128
                                  ? () {
                                      setState(() {
                                        appIconSize++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 32),

                      // General behavior
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showSearchButton,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: showSearchButton,
                        onChanged: (value) {
                          setState(() {
                            showSearchButton = value;
                          });
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.enableListScrolling,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: enableScroll,
                        onChanged: (value) {
                          setState(() {
                            enableScroll = value;
                          });
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showStatusBar,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: widget.prefs.getBool('showStatusBar') ?? false,
                        onChanged: (value) {
                          setState(() {
                            widget.prefs.setBool('showStatusBar', value);
                          });
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.wakeOnNotification,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: wakeOnNotification,
                        onChanged: (value) {
                          setState(() {
                            wakeOnNotification = value;
                          });
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.scrollToTop,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: scrollToTop,
                        onChanged: (value) {
                          setState(() {
                            scrollToTop = value;
                          });
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showFolderChevron,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: showFolderChevron,
                        onChanged: (value) {
                          setState(() {
                            showFolderChevron = value;
                          });
                          _saveSettings();
                        },
                      ),

                      const Divider(height: 32),

                      // Apps & folders
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.appAlignment,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            _buildAlignmentOption(
                              context,
                              AppAlignment.left,
                              AppLocalizations.of(context)!.appAlignmentLeft,
                            ),
                            _buildAlignmentOption(
                              context,
                              AppAlignment.center,
                              AppLocalizations.of(context)!.appAlignmentCenter,
                            ),
                            _buildAlignmentOption(
                              context,
                              AppAlignment.right,
                              AppLocalizations.of(context)!.appAlignmentRight,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.appList,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!
                              .selectedAppsCount(selectedApps.length),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface,
                        ),
                        onTap: _selectApps,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.reorderAppsFolders,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface,
                        ),
                        onTap: selectedApps.isEmpty ? null : _reorderApps,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.manageFolders,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!
                              .createAndOrganizeFolders,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  FolderManagementScreen(
                                prefs: widget.prefs,
                                selectedApps: selectedApps,
                              ),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.gestures,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!.configureGestures,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  GestureSettingsScreen(
                                prefs: widget.prefs,
                              ),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      ),

                      const Divider(height: 32),

                      // Weather
                      Opacity(
                        opacity: _locationEnabledForWeather ? 1.0 : 0.4,
                        child: FutureBuilder<String?>(
                          future: _getWeatherAppName(),
                          builder: (context, snapshot) {
                            return ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.weatherApp,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                weatherAppPackageName == null
                                    ? AppLocalizations.of(context)!
                                        .noWeatherAppSelected
                                    : snapshot.data ?? weatherAppPackageName!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              trailing: weatherAppPackageName == null
                                  ? Icon(
                                      Icons.chevron_right,
                                      color: theme.colorScheme.onSurface,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        if (!_locationEnabledForWeather) {
                                          _showEnableLocationForWeatherSnackbar();
                                          return;
                                        }
                                        setState(() {
                                          weatherAppPackageName = null;
                                        });
                                        await _saveSettings();
                                      },
                                    ),
                              onTap: () {
                                if (!_locationEnabledForWeather) {
                                  _showEnableLocationForWeatherSnackbar();
                                  return;
                                }
                                _selectWeatherApp();
                              },
                            );
                          },
                        ),
                      ),
                      Opacity(
                        opacity: _locationEnabledForWeather ? 1.0 : 0.4,
                        child: ListTile(
                          title: Text(
                            AppLocalizations.of(context)!.weatherApiKeyTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            (weatherApiKey == null || weatherApiKey!.isEmpty)
                                ? AppLocalizations.of(context)!
                                    .weatherApiKeyNotSet
                                : AppLocalizations.of(context)!
                                    .weatherApiKeyCustomSet,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          trailing: (weatherApiKey == null ||
                                  weatherApiKey!.isEmpty)
                              ? Icon(
                                  Icons.chevron_right,
                                  color: theme.colorScheme.onSurface,
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    if (!_locationEnabledForWeather) {
                                      _showEnableLocationForWeatherSnackbar();
                                      return;
                                    }
                                    setState(() {
                                      weatherApiKey = null;
                                    });
                                    await _saveSettings();
                                  },
                                ),
                          onTap: () {
                            if (!_locationEnabledForWeather) {
                              _showEnableLocationForWeatherSnackbar();
                              return;
                            }
                            _editWeatherApiKey();
                          },
                        ),
                      ),

                      // Backup & restore
                      const Divider(height: 32),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.exportSettings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!
                              .exportSettingsSubtitle,
                        ),
                        onTap: _exportSettings,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.importSettings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!
                              .importSettingsSubtitle,
                        ),
                        onTap: _importSettings,
                      ),

                      // About & support
                      const Divider(height: 32),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.aboutTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  const AboutScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.sendFeedbackTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'mailto:jack.apps.dev.2023@gmail.com',
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.donatePaypalTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'https://www.paypal.com/ncp/payment/39JV6M94ZNGNU',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (errorMessage != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.black),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              setState(() {
                                errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
