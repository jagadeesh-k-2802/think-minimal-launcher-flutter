import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'dart:io';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/scheduler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:think_launcher/constants/app_theme.dart';
import 'package:think_launcher/models/app_info.dart';
import 'package:think_launcher/services/icon_pack_service.dart';
import 'package:think_launcher/models/folder.dart';
import 'package:think_launcher/models/notification_info.dart';
import 'package:think_launcher/screens/search_screen.dart';
import 'package:think_launcher/screens/settings_screen.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';
import 'package:think_launcher/models/weather_info.dart';
import 'package:think_launcher/services/weather_service.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/screens/reorder_screen.dart';
import 'package:think_launcher/constants/app_alignment.dart';
import 'package:think_launcher/constants/dialog_options.dart';
import 'package:think_launcher/models/shortcut_info.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';

class MainScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const MainScreen({super.key, required this.prefs});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  // Cache for app information
  static final Map<String, AppInfo> _appInfoCache = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _folderItemKeys = {};

  // State variables
  late List<String> _selectedApps;
  late int _numApps;
  List<Folder> _folders = [];
  final Set<String> _expandedFolders = {};
  late bool _showSearchButton;

  late double _appFontSize;
  late bool _enableScroll;
  late bool _showIcons;
  late bool _colorMode;
  late bool _showFolderChevron;
  late bool _showStatusBar;
  late double _clockFontSize;
  late bool _use24HourClock;
  late String _currentTime;
  late String _currentDate;
  late int _batteryLevel;
  WeatherInfo? _weatherInfo;
  late WeatherService _weatherService;

  late double _appIconSize;
  String? _wallpaperPath;
  Color _overlayTextColor = Colors.black;
  ImageProvider? _wallpaperProvider;
  bool _isPreparingWallpaper = false;
  double _wallpaperBlur = 0.0;
  String? _weatherAppPackageName;

  late AppAlignment _appAlignment;
  late AppThemeMode _appTheme;
  String? _weatherApiKey;
  String? _iconPackPackageName;
  double _wallpaperOpacity = 1.0;
  List<ShortcutInfo> _shortcuts = [];
  String? _appDocsDirPath;
  static const _shortcutChannel = MethodChannel(
    'com.jackappsdev.think_minimal_launcher/shortcuts',
  );

  // Notification state
  final Map<String, NotificationInfo> _notifications = {};

  static const MethodChannel _wakeChannel = MethodChannel(
    'com.jackappsdev.think_minimal_launcher/wake',
  );

  void _saveNotifications() {
    final notificationsJson =
        jsonEncode(_notifications.map((key, notification) => MapEntry(
              key,
              {
                'packageName': notification.packageName,
                'title': notification.title,
                'content': notification.content,
                'id': notification.id,
                'onGoing': notification.onGoing,
              },
            )));
    widget.prefs.setString('notifications', notificationsJson);
  }

  Widget _buildHeader() {
    final statusBarPadding =
        _showStatusBar ? MediaQuery.of(context).padding.top : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0 + statusBarPadding,
        16.0,
        16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTime,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: _clockFontSize,
                  fontWeight: FontWeight.normal,
                  color: _overlayTextColor,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      size: 26,
                      color: _overlayTextColor,
                    ),
                    onPressed: _openSettings,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (_showSearchButton)
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        size: 26,
                        color: _overlayTextColor,
                      ),
                      onPressed: _openSearch,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                _currentDate,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: _overlayTextColor,
                ),
              ),
              Text(
                ' | ',
                style: TextStyle(
                  fontSize: 18,
                  color: _overlayTextColor,
                ),
              ),
              Icon(
                _getBatteryIcon(_batteryLevel),
                size: 18,
                color: _overlayTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$_batteryLevel%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: _overlayTextColor,
                ),
              ),
              if (_weatherInfo != null) ...[
                Text(
                  ' | ',
                  style: TextStyle(fontSize: 18, color: _overlayTextColor),
                ),
                GestureDetector(
                  onTap: _weatherAppPackageName != null
                      ? () {
                          InstalledApps.startApp(_weatherAppPackageName!);
                        }
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _colorMode
                          ? Image.network(
                              _weatherInfo!.iconUrl,
                              width: 24,
                              height: 24,
                            )
                          : ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ]),
                              child: Image.network(
                                _weatherInfo!.iconUrl,
                                width: 24,
                                height: 24,
                              ),
                            ),
                      const SizedBox(width: 4),
                      Text(
                        '${_weatherInfo!.temperature.round()}°C',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: _overlayTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _loadNotifications() {
    final notificationsJson = widget.prefs.getString('notifications');
    if (notificationsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(notificationsJson);
      setState(() {
        _notifications.clear();
        decoded.forEach((key, value) {
          _notifications[key] = NotificationInfo(
            packageName: value['packageName'],
            title: value['title'],
            content: value['content'],
            id: value['id'],
            onGoing: value['onGoing'] ?? false,
          );
        });
      });
    }
  }

  // Timers
  Timer? _dateTimeTimer;
  Timer? _batteryTimer;
  Timer? _weatherTimer;
  bool _isNavigating = false;
  final Battery _battery = Battery();

  // Formatters
  static final _dateFormatter = DateFormat('EEE, dd MMM');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeState();

    // Load documents directory and set up shortcuts MethodChannel
    getApplicationDocumentsDirectory().then((dir) {
      if (mounted) {
        setState(() {
          _appDocsDirPath = dir.path;
        });
      }

      _shortcutChannel.setMethodCallHandler((call) async {
        if (call.method == 'onShortcutPinned') {
          await _handleNewPinnedShortcut(Map<String, dynamic>.from(call.arguments));
        }
      });

      _checkPendingShortcuts();
    });

    _setupTimers();
    _setupBatteryListener();
    _setupNotificationListener();
    _setupWeatherService();
    _cleanupUninstalledApps();
  }

  void _initializeState() {
    _selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
    _numApps = widget.prefs.getInt('numApps') ?? 5;
    _loadFolders();
    _loadNotifications();
    _loadShortcuts();
    _showSearchButton = widget.prefs.getBool('showSearchButton') ?? true;
    _appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
    _enableScroll = widget.prefs.getBool('enableScroll') ?? true;
    _showIcons = widget.prefs.getBool('showIcons') ?? true;
    _colorMode = widget.prefs.getBool('colorMode') ?? true;
    _showFolderChevron = widget.prefs.getBool('showFolderChevron') ?? true;
    _showStatusBar = widget.prefs.getBool('showStatusBar') ?? false;
    _clockFontSize = widget.prefs.getDouble('clockFontSize') ?? 18.0;
    _appIconSize = widget.prefs.getDouble('appIconSize') ?? 18.0;
    _use24HourClock = widget.prefs.getBool('use24HourClock') ?? false;
    final timeFormatter =
        DateFormat(_use24HourClock ? 'HH:mm' : 'h:mm a');
    _currentTime = timeFormatter.format(DateTime.now());
    _currentDate = _dateFormatter.format(DateTime.now());
    _batteryLevel = 0;
    _wallpaperPath = widget.prefs.getString('wallpaperPath');
    _wallpaperBlur = widget.prefs.getDouble('wallpaperBlur') ?? 0.0;
    _weatherAppPackageName = widget.prefs.getString('weatherAppPackageName');
    _appAlignment = appAlignmentFromStorage(widget.prefs.getString('appAlignment'));
    _appTheme = appThemeModeFromStorage(widget.prefs.getString('appTheme'));
    
    _weatherApiKey = widget.prefs.getString('weatherApiKey');
    _iconPackPackageName = widget.prefs.getString('iconPackPackageName');

    // Always prepare once on init (handles null/remove as well)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _prepareWallpaper();
    });
  }

  void _setupWeatherService() {
    _weatherService = WeatherService(apiKey: _weatherApiKey ?? '');
    _updateWeather();
  }

  void _setupTimers() {
    _dateTimeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateDateTime(),
    );
    _batteryTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updateBattery(),
    );
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _updateWeather(),
    );
  }

  void _setupBatteryListener() {
    _battery.onBatteryStateChanged.listen((_) => _updateBattery());
  }

  Future<void> _setupNotificationListener() async {
    // Request notification permission if not granted
    try {
      final bool granted =
          await NotificationListenerService.isPermissionGranted();
      if (!granted) {
        return;
      }
    } catch (e) {
      debugPrint('Error setting up notification listener: $e');
    }

    // Listen to notifications
    NotificationListenerService.notificationsStream.listen((event) {
      if (!mounted) return;

      setState(() {
        if (event.hasRemoved == true) {
          _notifications.remove('${event.packageName}_${event.id}');
        } else {
          _notifications['${event.packageName}_${event.id}'] = NotificationInfo(
            packageName: event.packageName ?? '',
            title: event.title ?? '',
            content: event.content ?? '',
            id: event.id ?? 0,
            onGoing: event.onGoing ?? false,
          );
        }
        _saveNotifications(); // Save notifications after any change
      });

      // Wake screen briefly if enabled and this is an addition
      final shouldWake = widget.prefs.getBool('wakeOnNotification') ?? false;
      if (shouldWake && (event.hasRemoved != true)) {
        _wakeScreen();
      }
    });
  }

  Future<void> _wakeScreen() async {
    try {
      await _wakeChannel.invokeMethod('wakeScreen', {'seconds': 2});
    } catch (_) {
      // ignore failures
    }
  }

  void _loadFolders() {
    final foldersJson = widget.prefs.getString('folders');
    if (foldersJson != null) {
      final List<dynamic> decoded = jsonDecode(foldersJson);
      setState(() {
        _folders = decoded.map((f) => Folder.fromJson(f)).toList();
        // Remove any expanded state for folders that no longer exist
        _expandedFolders.removeWhere(
          (id) => !_folders.any((f) => f.id == id),
        );
      });
      _syncFolderItemKeys();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateTimeTimer?.cancel();
    _batteryTimer?.cancel();
    _weatherTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Update status bar color when app resumes
      _updateStatusBarColor();
      // Clean up uninstalled apps first
      _cleanupUninstalledApps().then((_) {
        _loadData();
        // Refresh app info cache to get updated custom names
        _refreshAppInfoCache();
      });
    }
  }

  void _loadData() {
    _loadFolders();
    _buildAppList();
    _loadNotifications();
    _updateBattery();
    _updateDateTime();
    _updateWeather();
  }

  /// Refreshes the entire app info cache to get updated custom names
  Future<void> _refreshAppInfoCache() async {
    for (final packageName in _selectedApps) {
      await _refreshAppInfo(packageName);
    }
    setState(() {});
  }

  /// Gets app information for a package, handling various edge cases:
  /// - App uninstallation
  /// - App reinstallation
  /// - App updates
  /// - Custom names
  /// - Cache management
  Future<AppInfo?> _getAppInfo(String packageName) async {
    try {
      // First check if app is still installed
      final isInstalled = await InstalledApps.isAppInstalled(packageName);
      if (isInstalled == false) {
        await _handleUninstalledApp(packageName);
        return null;
      }

      // Check cache but verify app info is still valid
      if (_appInfoCache.containsKey(packageName)) {
        final cachedInfo = _appInfoCache[packageName]!;
        try {
          // Verify the cached app info is still valid
          final currentApp = await InstalledApps.getAppInfo(packageName);
          if (currentApp?.versionName != cachedInfo.versionName) {
            debugPrint('App $packageName updated, refreshing cache');
            _appInfoCache.remove(packageName); // Force refresh for updated app
          } else {
            return cachedInfo; // Cache is valid
          }
        } catch (e) {
          debugPrint('Error verifying cached app info: $e');
          _appInfoCache.remove(packageName); // Clear invalid cache
        }
      }

      // Get fresh app info
      final app = await InstalledApps.getAppInfo(packageName);
      if (app == null) {
        debugPrint('Could not get app info for $packageName');
        await _handleUninstalledApp(packageName);
        return null;
      }

      var appInfo = AppInfo.fromInstalledApps(app);

      // Apply icon pack override if configured
      appInfo = await IconPackService.applyIconPackToApp(appInfo, widget.prefs);

      // Handle custom names
      final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
      final customNames = Map<String, String>.from(jsonDecode(customNamesJson));
      final customName = customNames[packageName];

      final finalAppInfo = customName != null
          ? appInfo.copyWith(customName: customName)
          : appInfo;

      // Update cache
      _appInfoCache[packageName] = finalAppInfo;
      return finalAppInfo;
    } catch (e) {
      debugPrint('Error getting app info for $packageName: $e');
      if (!mounted) return null;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.errorGettingAppInfo(packageName)),
          duration: const Duration(seconds: 3),
        ),
      );

      // Handle as uninstalled app
      await _handleUninstalledApp(packageName);
      return null;
    }
  }

  /// Handles cleanup when an app is uninstalled or unavailable
  Future<void> _handleUninstalledApp(String packageName) async {
    if (!mounted) return;

    debugPrint('Handling uninstalled app: $packageName');

    // Update state in a single batch
    setState(() {
      // Remove from selected apps
      if (_selectedApps.remove(packageName)) {
        widget.prefs.setStringList('selectedApps', _selectedApps);
      }

      // Remove from cache
      _appInfoCache.remove(packageName);

      // Remove from custom names
      final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
      final customNames = Map<String, String>.from(jsonDecode(customNamesJson));
      if (customNames.remove(packageName) != null) {
        widget.prefs.setString('customAppNames', jsonEncode(customNames));
      }

      // Remove from folders and cleanup empty folders
      bool foldersChanged = false;
      for (int i = 0; i < _folders.length; i++) {
        final folder = _folders[i];
        if (folder.appPackageNames.contains(packageName)) {
          _folders[i] = folder.copyWith(
            appPackageNames: folder.appPackageNames
                .where((app) => app != packageName)
                .toList(),
          );
          foldersChanged = true;
        }
      }

      // Remove empty folders
      final oldFolderCount = _folders.length;
      _folders.removeWhere((folder) => folder.appPackageNames.isEmpty);
      if (_folders.length != oldFolderCount) {
        foldersChanged = true;
      }

      // Save updated folders if changed
      if (foldersChanged) {
        final foldersJson = jsonEncode(
          _folders.map((f) => f.toJson()).toList(),
        );
        widget.prefs.setString('folders', foldersJson);
      }
    });
  }

  /// Preloads app information for all selected apps that aren't in cache.
  /// This improves performance by loading app info in parallel.
  Future<void> _preloadAppInfo() async {
    if (_selectedApps.isEmpty) return;

    try {
      // Load apps in parallel for better performance
      final futures = _selectedApps
          .where((packageName) => !_appInfoCache.containsKey(packageName))
          .map((packageName) => _getAppInfo(packageName));

      // Wait for all app info to load
      final results = await Future.wait(futures, eagerError: true);

      // Remove any null results (uninstalled apps)
      final uninstalledApps = <String>[];
      for (int i = 0; i < _selectedApps.length; i++) {
        if (results[i] == null) {
          uninstalledApps.add(_selectedApps[i]);
        }
      }

      // Clean up if any apps were uninstalled
      if (uninstalledApps.isNotEmpty) {
        await _cleanupUninstalledApps(uninstalledApps);
      }
    } catch (e) {
      debugPrint('Error preloading app info: $e');
    }
  }

  /// Cleans up data for uninstalled apps from all storage locations.
  /// This ensures consistency across the app's state.
  Future<void> _cleanupUninstalledApps([
    List<String>? knownUninstalledApps,
  ]) async {
    try {
      final uninstalledApps = knownUninstalledApps ?? <String>[];

      // If not provided, check each app's installation status
      if (uninstalledApps.isEmpty) {
        for (final packageName in _selectedApps) {
          final isInstalled = await InstalledApps.isAppInstalled(packageName);
          if (isInstalled == false) {
            uninstalledApps.add(packageName);
          }
        }
      }

      // Check shortcuts as well
      final shortcutsToRemove = <ShortcutInfo>[];
      for (final shortcut in _shortcuts) {
        final isInstalled = await InstalledApps.isAppInstalled(shortcut.packageName);
        if (isInstalled == false) {
          shortcutsToRemove.add(shortcut);
        }
      }

      if (uninstalledApps.isEmpty && shortcutsToRemove.isEmpty) return;

      // Update all state in a single setState call
      setState(() {
        if (uninstalledApps.isNotEmpty) {
          // 1. Clean up selected apps
          _selectedApps.removeWhere((app) => uninstalledApps.contains(app));
          widget.prefs.setStringList('selectedApps', _selectedApps);

          // 2. Clean up app info cache
          for (final app in uninstalledApps) {
            _appInfoCache.remove(app);
          }

          // 3. Clean up custom names
          final customNamesJson = widget.prefs.getString('customAppNames');
          final customNames = Map<String, String>.from(
            jsonDecode(customNamesJson ?? '{}'),
          );
          customNames.removeWhere((key, _) => uninstalledApps.contains(key));
          widget.prefs.setString('customAppNames', jsonEncode(customNames));

          // 4. Clean up folders
          bool foldersChanged = false;
          for (int i = 0; i < _folders.length; i++) {
            final folder = _folders[i];
            final oldLength = folder.appPackageNames.length;
            final newAppPackageNames = folder.appPackageNames
                .where((app) => !uninstalledApps.contains(app))
                .toList();

            if (oldLength != newAppPackageNames.length) {
              _folders[i] = folder.copyWith(appPackageNames: newAppPackageNames);
              foldersChanged = true;
            }
          }

          // 5. Remove empty folders
          final oldFolderCount = _folders.length;
          _folders.removeWhere((folder) => folder.appPackageNames.isEmpty);
          if (_folders.length != oldFolderCount) {
            foldersChanged = true;
          }

          // 6. Save updated folders if changed
          if (foldersChanged) {
            final foldersJson = jsonEncode(
              _folders.map((f) => f.toJson()).toList(),
            );
            widget.prefs.setString('folders', foldersJson);
          }
        }

        // Clean up shortcuts
        if (shortcutsToRemove.isNotEmpty) {
          for (final shortcut in shortcutsToRemove) {
            _shortcuts.removeWhere((s) => s.id == shortcut.id && s.packageName == shortcut.packageName);
            
            // Delete icon file
            try {
              if (_appDocsDirPath != null) {
                final file = File('$_appDocsDirPath/shortcut_icons/${shortcut.packageName}_${shortcut.id}.png');
                if (file.existsSync()) {
                  file.deleteSync();
                }
              }
            } catch (_) {}
          }
          _saveShortcuts();
        }
      });
    } catch (e) {
      debugPrint('Error cleaning up uninstalled apps: $e');
    }
  }

  /// Returns the base overlay text color when no wallpaper is available
  /// or when wallpaper loading fails.
  ///
  /// For [AppThemeMode.auto], this uses the effective theme brightness from
  /// the current [BuildContext] so that Auto follows the actual light/dark
  /// mode in use.
  Color _getBaseOverlayTextColor() {
    bool isLight;
    switch (_appTheme) {
      case AppThemeMode.light:
        isLight = true;
        break;
      case AppThemeMode.dark:
        isLight = false;
        break;
      case AppThemeMode.auto:
        final brightness = Theme.of(context).brightness;
        isLight = brightness == Brightness.light;
        break;
    }
    return isLight ? Colors.black : Colors.white;
  }

  /// Refreshes app info cache for a specific app
  Future<void> _refreshAppInfo(String packageName) async {
    try {
      final app = await InstalledApps.getAppInfo(packageName);
      var appInfo = AppInfo.fromInstalledApps(app);

      // Apply icon pack override if configured
      appInfo = await IconPackService.applyIconPackToApp(appInfo, widget.prefs);

      // Load custom name if exists
      final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
      final customNames = Map<String, String>.from(jsonDecode(customNamesJson));
      final customName = customNames[packageName];

      final finalAppInfo = customName != null
          ? appInfo.copyWith(customName: customName)
          : appInfo;
      _appInfoCache[packageName] = finalAppInfo;
    } catch (e) {
      debugPrint('Error refreshing app info for $packageName: $e');
    }
  }

  /// Loads and applies all settings from SharedPreferences.
  /// This includes app list, display settings, and UI preferences.
  /// Also handles app cache invalidation and UI updates.
  Future<void> _loadSettings() async {
    if (!mounted) return;

    try {
      // Load all settings at once to minimize SharedPreferences access
      final prefs = widget.prefs;
      final settings = {
        'numApps': prefs.getInt('numApps') ?? 5,
        'showSearchButton': prefs.getBool('showSearchButton') ?? true,
        'appFontSize': prefs.getDouble('appFontSize') ?? 18.0,
        'enableScroll': prefs.getBool('enableScroll') ?? true,
        'showIcons': prefs.getBool('showIcons') ?? false,
        'colorMode': prefs.getBool('colorMode') ?? true,
        'showFolderChevron': prefs.getBool('showFolderChevron') ?? true,
        'selectedApps': prefs.getStringList('selectedApps') ?? <String>[],
        'appIconSize': prefs.getDouble('appIconSize') ?? 18.0,
        'clockFontSize': prefs.getDouble('clockFontSize') ?? 18.0,
        'use24HourClock': prefs.getBool('use24HourClock') ?? false,
        'showStatusBar': prefs.getBool('showStatusBar') ?? false,
        'wallpaperPath': prefs.getString('wallpaperPath'),
        'wallpaperBlur': prefs.getDouble('wallpaperBlur') ?? 0.0,
        'wallpaperOpacity': prefs.getDouble('wallpaperOpacity') ?? 1.0,
        'weatherAppPackageName': prefs.getString('weatherAppPackageName'),
        'weatherApiKey': prefs.getString('weatherApiKey'),
        'iconPackPackageName': prefs.getString('iconPackPackageName'),
      };

      final newAlignment =
          appAlignmentFromStorage(prefs.getString('appAlignment'));
      final newAppTheme = appThemeModeFromStorage(prefs.getString('appTheme'));

      // Check if any settings have changed
      final hasChanges = _numApps != settings['numApps'] ||
          _showSearchButton != settings['showSearchButton'] ||
          _appFontSize != settings['appFontSize'] ||
          _clockFontSize != settings['clockFontSize'] ||
          _use24HourClock != settings['use24HourClock'] ||
          _enableScroll != settings['enableScroll'] ||
          _showIcons != settings['showIcons'] ||
          _colorMode != settings['colorMode'] ||
          _showStatusBar != settings['showStatusBar'] ||
          !listEquals(_selectedApps, settings['selectedApps'] as List<String>) ||
          _appIconSize != settings['appIconSize'] ||
          _wallpaperPath != settings['wallpaperPath'] ||
          _showFolderChevron != settings['showFolderChevron'] ||
          _wallpaperBlur != settings['wallpaperBlur'] ||
          _wallpaperOpacity != settings['wallpaperOpacity'] ||
          _weatherAppPackageName != settings['weatherAppPackageName'] ||
          _appAlignment != newAlignment ||
          _appTheme != newAppTheme ||
          _weatherApiKey != settings['weatherApiKey'] ||
          _iconPackPackageName != settings['iconPackPackageName'];

      if (hasChanges) {
        // Update all state at once to minimize rebuilds
        setState(() {
          _numApps = settings['numApps'] as int;
          _showSearchButton = settings['showSearchButton'] as bool;
          _appFontSize = settings['appFontSize'] as double;
          _clockFontSize = settings['clockFontSize'] as double;
          _use24HourClock = settings['use24HourClock'] as bool;
          _enableScroll = settings['enableScroll'] as bool;
          _showIcons = settings['showIcons'] as bool;
          _colorMode = settings['colorMode'] as bool;
          _showFolderChevron = settings['showFolderChevron'] as bool;
          _showStatusBar = settings['showStatusBar'] as bool;
          _selectedApps = List.from(settings['selectedApps'] as List<String>);
          _appIconSize = settings['appIconSize'] as double;
          _wallpaperPath = settings['wallpaperPath'] as String?;
          _wallpaperBlur = settings['wallpaperBlur'] as double;
          _wallpaperOpacity = settings['wallpaperOpacity'] as double;
          _weatherAppPackageName = settings['weatherAppPackageName'] as String?;
          _appAlignment = newAlignment;
          _appTheme = newAppTheme;
        });

        // Update system UI
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: settings['showStatusBar'] as bool
              ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
              : [SystemUiOverlay.bottom],
        );

        // Only reload app info if selected apps changed
        if (!listEquals(_selectedApps, settings['selectedApps'] as List<String>)) {
          _appInfoCache.clear();
          await _preloadAppInfo();

          // Force UI update only if needed
          if (mounted) {
            setState(() {});
          }
        }
        // Always prepare wallpaper after settings update to ensure palette refresh
        _prepareWallpaper();

        // Refresh time immediately when clock settings change.
        _updateDateTime();
      }

      // Reconfigure weather service if API key changed
      if (_weatherApiKey != settings['weatherApiKey']) {
        _weatherApiKey = settings['weatherApiKey'] as String?;
        _setupWeatherService();
        _updateWeather();
      }

      // Reconfigure icon pack if package name changed
      if (_iconPackPackageName != settings['iconPackPackageName']) {
        _iconPackPackageName = settings['iconPackPackageName'] as String?;
        _appInfoCache.clear();
        await _preloadAppInfo();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  void _updateStatusBarColor() {
    final isLightText = _overlayTextColor.computeLuminance() > 0.5;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isLightText ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _setStatusBarForWhiteBackground() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _prepareWallpaper() async {
    if (_wallpaperPath == null) {
      setState(() {
        _overlayTextColor = _getBaseOverlayTextColor();
        _wallpaperProvider = null;
        _isPreparingWallpaper = false;
      });
      _wallpaperProvider = null;
      _updateStatusBarColor();
      return;
    }
    try {
      setState(() => _isPreparingWallpaper = true);
      final file = File(_wallpaperPath!);
      if (!await file.exists()) {
        setState(() {
          _overlayTextColor = _getBaseOverlayTextColor();
          _wallpaperProvider = null;
          _isPreparingWallpaper = false;
        });
        _wallpaperProvider = null;
        _updateStatusBarColor();
        return;
      }
      final imageProvider = FileImage(file);
      // Bust image cache by creating a new provider with unique key
      imageCache.clear();
      imageCache.clearLiveImages();
      // Prefer white text until palette analysis completes
      if (mounted) {
        setState(() => _overlayTextColor = _getBaseOverlayTextColor());
        _updateStatusBarColor();
      }
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 12,
      );
      final bg = palette.dominantColor?.color ?? Colors.white;
      // Compute luminance and choose contrasting color
      final double luminance = bg.computeLuminance();
      setState(() {
        _overlayTextColor = luminance > 0.6 ? Colors.black : Colors.white;
        _wallpaperProvider = imageProvider;
        _isPreparingWallpaper = false;
      });
      _updateStatusBarColor();

      // Precache after first frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final contextRef = context;
        if (_wallpaperProvider != null) {
          precacheImage(_wallpaperProvider!, contextRef);
        }
      });
    } catch (e) {
      setState(() {
        _overlayTextColor = _getBaseOverlayTextColor();
        _wallpaperProvider = null;
        _isPreparingWallpaper = false;
      });
      _updateStatusBarColor();
    }
  }

  void _updateDateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      final formatter = DateFormat(_use24HourClock ? 'HH:mm' : 'h:mm a');
      _currentTime = formatter.format(now);
      _currentDate = _dateFormatter.format(now);
    });
  }

  Future<void> _updateBattery() async {
    if (!mounted) return;
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() => _batteryLevel = level);
      }
    } catch (e) {
      // Error silently
    }
  }

  Future<void> _updateWeather() async {
    if (!mounted) return;
    try {
      final weather = await _weatherService.getCurrentWeather();
      if (mounted) {
        setState(() => _weatherInfo = weather);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('${AppLocalizations.of(context)!.errorUpdatingWeather}: $e');
    }
  }

  Future<void> _openSettings() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      if (!mounted) return;
      _setStatusBarForWhiteBackground();
      await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return SettingsScreen(prefs: widget.prefs);
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      if (mounted) {
        _reloadData();
      }
    } catch (e) {
      debugPrint('Error in settings flow: $e');
    } finally {
      if (mounted) {
        _updateStatusBarColor();
      }
      _isNavigating = false;
    }
  }

  Future<void> _reloadData() async {
    // Reload all state
    await _loadSettings();
    _loadFolders();
    _loadShortcuts();
    await _preloadAppInfo();

    // Force UI update
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSearch() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      if (!mounted) return;
      _setStatusBarForWhiteBackground();
      final autoFocus = widget.prefs.getBool('autoFocusSearch') ?? true;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return SearchScreen(
              prefs: widget.prefs,
              autoFocus: autoFocus,
            );
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      // Error silently
    } finally {
      if (mounted) {
        _updateStatusBarColor();
      }
      _isNavigating = false;
    }
  }

  Widget _buildAppList() {
    return FutureBuilder<List<AppInfo?>>(
      future: Future.wait(
        _selectedApps.map((packageName) => _getAppInfo(packageName)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _appInfoCache.isEmpty) {
          return Stack(
            children: [
              if (_wallpaperPath != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _buildBlurredWallpaper(),
                  ),
                ),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.loading,
                  style: TextStyle(fontSize: 18, color: _overlayTextColor),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading apps: ${snapshot.error}');
          return Center(
            child: Text(
              AppLocalizations.of(context)!.errorLoadingApps,
              style: TextStyle(
                fontSize: _appFontSize,
                fontWeight: FontWeight.normal,
                color: _overlayTextColor,
              ),
            ),
          );
        }

        final apps = (snapshot.data ?? [])
            .where((app) => app != null)
            .cast<AppInfo>()
            .toList();
        if (apps.isEmpty) {
          // While preparing wallpaper/palette, show loading instead of empty
          if (_isPreparingWallpaper) {
            return Stack(
              children: [
                if (_wallpaperPath != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _buildBlurredWallpaper(),
                    ),
                  ),
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.loading,
                    style: TextStyle(fontSize: 18, color: _overlayTextColor),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noAppsSelected,
                    style: TextStyle(
                      fontSize: _appFontSize,
                      fontWeight: FontWeight.normal,
                      color: _overlayTextColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return _buildListView(apps);
      },
    );
  }

  Widget _buildBlurredWallpaper() {
    if (_wallpaperPath == null) {
      return const SizedBox();
    }

    final Widget imageChild = _wallpaperProvider != null
        ? Image(
            image: _wallpaperProvider!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          )
        : Image.file(
            File(_wallpaperPath!),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          );

    return ClipRect(
      child: Container(
        color: Colors.black,
        child: ImageFiltered(
          imageFilter: _wallpaperBlur > 0
              ? ImageFilter.blur(
                  sigmaX: _wallpaperBlur,
                  sigmaY: _wallpaperBlur,
                  tileMode: TileMode.clamp,
                )
              : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
          child: Transform.scale(
            scale: 1.02,
            alignment: Alignment.center,
            child: Opacity(
              opacity: _wallpaperOpacity,
              child: imageChild,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<AppInfo> apps) {
    _syncFolderItemKeys();
    // Map of package name → app info
    final appMap = {for (var app in apps) app.packageName: app};

    // Collect apps already inside folders
    final appsInFolders = _folders.expand((f) => f.appPackageNames).toSet();

    // Remaining apps (already in desired order)
    final unorganizedApps =
        apps.where((app) => !appsInFolders.contains(app.packageName)).toList();

    // Prepare final ordered items list (header scrolls with items)
    final items = <Widget>[
      _buildHeader(),
    ];

    // Sort folders and shortcuts together by order
    final List<dynamic> orderedItems = [..._folders, ..._shortcuts];
    orderedItems.sort((a, b) {
      int aOrder = a is Folder ? a.order : (a as ShortcutInfo).order;
      int bOrder = b is Folder ? b.order : (b as ShortcutInfo).order;
      return aOrder.compareTo(bOrder);
    });

    int currentIndex = 0;
    int unorganizedIndex = 0;

    for (final item in orderedItems) {
      int targetOrder = item is Folder ? item.order : (item as ShortcutInfo).order;

      // Fill in unorganized apps until we reach this item's order index
      while (currentIndex < targetOrder &&
          unorganizedIndex < unorganizedApps.length) {
        items.add(_buildAppItem(unorganizedApps[unorganizedIndex]));
        unorganizedIndex++;
        currentIndex++;
      }

      // Insert the folder or shortcut
      if (item is Folder) {
        if (item.appPackageNames.isNotEmpty) {
          items.add(_buildFolderItem(currentIndex, item));
          currentIndex++;

          // If folder is expanded, add its apps
          if (_expandedFolders.contains(item.id)) {
            for (final packageName in item.appPackageNames) {
              final app = appMap[packageName];
              if (app != null) {
                items.add(
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: _buildAppItem(app),
                  ),
                );
                currentIndex++;
              }
            }
          }
        }
      } else if (item is ShortcutInfo) {
        items.add(_buildShortcutItem(currentIndex, item));
        currentIndex++;
      }
    }

    // Add any remaining unorganized apps
    while (unorganizedIndex < unorganizedApps.length) {
      items.add(_buildAppItem(unorganizedApps[unorganizedIndex]));
      unorganizedIndex++;
      currentIndex++;
    }

    return ScrollConfiguration(
      behavior: NoGlowScrollBehavior(),
      child: ListView(
        padding: EdgeInsets.zero,
        physics: _enableScroll
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        controller: _scrollController,
        children: items,
      ),
    );
  }

  void _scrollOnFolderExpand(String folderId) {
    try {
      final key = _folderItemKeys[folderId];
      final context = key?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('_scrollOnFolderExpand($folderId): $e');
    }
  }

  void _scrollToTopIfEnabled() {
    try {
      final shouldScroll = widget.prefs.getBool('scrollToTop') ?? false;
      if (!shouldScroll) return;
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (_) {
      // ignore
    }
  }

  void _syncFolderItemKeys() {
    try {
      final existingIds = _folders.map((f) => f.id).toSet();
      _folderItemKeys.removeWhere((id, _) => !existingIds.contains(id));
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> _showFolderOptionsDialog(Folder folder) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            folder.name,
            style: const TextStyle(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.editFolder),
                onTap: () => Navigator.pop(context, FolderDialogOptions.rename),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(AppLocalizations.of(context)!.deleteFolder),
                onTap: () => Navigator.pop(context, FolderDialogOptions.delete),
              ),
              ListTile(
                leading: const Icon(Icons.reorder),
                title: Text(AppLocalizations.of(context)!.reorderAppsInFolder),
                onTap: () =>
                    Navigator.pop(context, FolderDialogOptions.reorder),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    switch (result) {
      case FolderDialogOptions.rename:
        final newName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final controller = TextEditingController(text: folder.name);
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.editFolder),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.folderName,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );

        if (newName != null && newName.isNotEmpty) {
          setState(() {
            final index = _folders.indexWhere((f) => f.id == folder.id);
            if (index != -1) {
              _folders[index] = folder.copyWith(name: newName);
              final foldersJson =
                  jsonEncode(_folders.map((f) => f.toJson()).toList());
              widget.prefs.setString('folders', foldersJson);
            }
          });
        }
        break;

      case FolderDialogOptions.delete:
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.deleteFolder),
              content: Text(
                AppLocalizations.of(context)!.deleteFolderConfirm(folder.name),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.deleteFolder),
                ),
              ],
            );
          },
        );

        if (shouldDelete == true) {
          setState(() {
            _folders.removeWhere((f) => f.id == folder.id);
            _expandedFolders.remove(folder.id);
            _folderItemKeys.remove(folder.id);
            final foldersJson =
                jsonEncode(_folders.map((f) => f.toJson()).toList());
            widget.prefs.setString('folders', foldersJson);
          });
        }
        break;

      case FolderDialogOptions.reorder:
        // Navigate to reorder screen
        if (!mounted) return;
        _setStatusBarForWhiteBackground();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReorderAppsScreen(
              prefs: widget.prefs,
              folder: folder,
            ),
          ),
        );
        if (mounted) {
          _updateStatusBarColor();
          _loadFolders(); // Reload folders after returning from reorder screen
        }
        break;
    }
  }

  Widget _buildFolderItem(int currentIndex, Folder folder) {
    return Material(
      key: _folderItemKeys.putIfAbsent(folder.id, () => GlobalKey()),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_expandedFolders.contains(folder.id)) {
              _expandedFolders.remove(folder.id);
              _scrollToTopIfEnabled();
            } else {
              _expandedFolders.add(folder.id);
              _scrollOnFolderExpand(folder.id);
            }
          });
        },
        onLongPress: () => _showFolderOptionsDialog(folder),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            minHeight: _appIconSize + 16.0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: _getAppItemAlignment(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showIcons)
                        Container(
                          width: _appIconSize,
                          height: _appIconSize,
                          padding: EdgeInsets.all(_appIconSize * 0.15),
                          child: Icon(
                            Icons.folder,
                            size: _appIconSize * 0.7,
                            color: _overlayTextColor.withAlpha(200),
                          ),
                        ),
                      if (_showIcons) const SizedBox(width: 16.0),
                      Flexible(
                        child: Text(
                          folder.name,
                          style: TextStyle(
                            fontSize: _appFontSize,
                            fontWeight: FontWeight.normal,
                            color: _overlayTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: _getAppTextAlign(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showFolderChevron)
                Icon(
                  _expandedFolders.contains(folder.id)
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 24.0,
                  color: _overlayTextColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAppOptionsDialog(AppInfo app) async {
    // Check if app is already in a folder
    final isInFolder = _folders
        .any((folder) => folder.appPackageNames.contains(app.packageName));

    // Check if app has a notification (excluding ongoing ones)
    final hasNotification = _notifications.values
        .any((n) => n.packageName == app.packageName && !n.onGoing);

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            app.displayName,
            style: const TextStyle(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(AppLocalizations.of(context)!.appInfo),
                onTap: () => Navigator.pop(context, AppDialogOptions.info),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.renameApp),
                onTap: () => Navigator.pop(context, AppDialogOptions.rename),
              ),
              if (app.customName != null)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(AppLocalizations.of(context)!.resetAppName),
                  onTap: () =>
                      Navigator.pop(context, AppDialogOptions.resetAppName),
                ),
              if (hasNotification)
                ListTile(
                  leading: const Icon(Icons.notifications_off),
                  title: Text(AppLocalizations.of(context)!.clearNotification),
                  onTap: () => Navigator.pop(
                      context, AppDialogOptions.clearNotification),
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(AppLocalizations.of(context)!.uninstallApp),
                onTap: () => Navigator.pop(context, AppDialogOptions.uninstall),
              ),
              if (!isInFolder)
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: Text(AppLocalizations.of(context)!.createFolder),
                  onTap: () =>
                      Navigator.pop(context, AppDialogOptions.createFolder),
                ),
              if (_folders.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(AppLocalizations.of(context)!.moveToFolder),
                  onTap: () =>
                      Navigator.pop(context, AppDialogOptions.moveToFolder),
                ),
              if (!isInFolder)
                ListTile(
                  leading: const Icon(Icons.reorder),
                  title: Text(AppLocalizations.of(context)!.reOrderApps),
                  onTap: () =>
                      Navigator.pop(context, AppDialogOptions.reorderApps),
                ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    switch (result) {
      case AppDialogOptions.info:
        await AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:${app.packageName}',
        ).launch();
        break;
      case AppDialogOptions.uninstall:
        final shouldUninstall = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.uninstallApp),
              content: Text(
                AppLocalizations.of(context)!.confirmUninstall(app.name),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.uninstallApp),
                ),
              ],
            );
          },
        );

        if (shouldUninstall == true) {
          await InstalledApps.uninstallApp(app.packageName);
          setState(() {
            _selectedApps.remove(app.packageName);
            widget.prefs.setStringList('selectedApps', _selectedApps);
          });
        }
        break;
      case AppDialogOptions.createFolder:
        final folderName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.createFolder),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.folderName,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );

        if (folderName != null && folderName.isNotEmpty) {
          final newFolder = Folder(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: folderName,
            appPackageNames: [app.packageName],
          );

          setState(() {
            _folders.add(newFolder);
            final foldersJson =
                jsonEncode(_folders.map((f) => f.toJson()).toList());
            widget.prefs.setString('folders', foldersJson);
          });
        }
        break;
      case AppDialogOptions.rename:
        final newName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final controller = TextEditingController(text: app.displayName);
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.renameApp),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.folderName,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );

        if (newName != null && newName.isNotEmpty) {
          final updatedApp = app.copyWith(customName: newName);
          _appInfoCache[app.packageName] = updatedApp;

          // Save custom names to preferences
          final customNamesJson =
              widget.prefs.getString('customAppNames') ?? '{}';
          final customNames =
              Map<String, String>.from(jsonDecode(customNamesJson));
          customNames[app.packageName] = newName;
          widget.prefs.setString('customAppNames', jsonEncode(customNames));

          // Force refresh of the app grid to show updated names
          setState(() {});
        }
        break;
      case AppDialogOptions.resetAppName:
        // Remove custom name and reset to system name
        final updatedApp = app.copyWith(customName: null);
        _appInfoCache[app.packageName] = updatedApp;

        // Remove from custom names preferences
        final customNamesJson =
            widget.prefs.getString('customAppNames') ?? '{}';
        final customNames =
            Map<String, String>.from(jsonDecode(customNamesJson));
        customNames.remove(app.packageName);
        widget.prefs.setString('customAppNames', jsonEncode(customNames));

        // Refresh the app info to ensure system name is loaded
        await _refreshAppInfo(app.packageName);

        // Force refresh of the app grid to show updated names
        setState(() {});
        break;
      case AppDialogOptions.moveToFolder:
        // Filter out the folder the app is currently in
        final availableFolders = _folders
            .where(
                (folder) => !folder.appPackageNames.contains(app.packageName))
            .toList();

        if (availableFolders.isEmpty) {
          // Show message if no other folders available
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.moveToFolder),
                content:
                    Text(AppLocalizations.of(context)!.noOtherFoldersAvailable),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ],
              );
            },
          );
          return;
        }

        final selectedFolder = await showDialog<Folder>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectFolder),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableFolders
                    .map((folder) => ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(folder.name),
                          subtitle:
                              Text('${folder.appPackageNames.length} apps'),
                          onTap: () => Navigator.pop(context, folder),
                        ))
                    .toList(),
              ),
            );
          },
        );

        if (selectedFolder != null) {
          setState(() {
            // First, remove app from any existing folder
            for (int i = 0; i < _folders.length; i++) {
              if (_folders[i].appPackageNames.contains(app.packageName)) {
                _folders[i] = _folders[i].copyWith(
                  appPackageNames: _folders[i]
                      .appPackageNames
                      .where((packageName) => packageName != app.packageName)
                      .toList(),
                );
              }
            }

            // Then add app to selected folder
            final folderIndex =
                _folders.indexWhere((f) => f.id == selectedFolder.id);
            if (folderIndex != -1) {
              _folders[folderIndex] = selectedFolder.copyWith(
                appPackageNames: [
                  ...selectedFolder.appPackageNames,
                  app.packageName
                ],
              );
            }

            // Save updated folders
            final foldersJson =
                jsonEncode(_folders.map((f) => f.toJson()).toList());
            widget.prefs.setString('folders', foldersJson);
          });
        }
        break;
      case AppDialogOptions.clearNotification:
        // Remove all notifications for this app
        setState(() {
          _notifications.removeWhere(
            (key, notification) => notification.packageName == app.packageName,
          );
          _saveNotifications();
        });
        break;
      case AppDialogOptions.reorderApps:
        if (!mounted) return;
        _setStatusBarForWhiteBackground();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReorderAppsScreen(
              prefs: widget.prefs,
              folder: null,
            ),
          ),
        );
        if (mounted) {
          _updateStatusBarColor();
          _reloadData();
        }
        break;
    }
  }

  void _loadShortcuts() {
    try {
      final jsonText = widget.prefs.getString('shortcuts') ?? '[]';
      final List<dynamic> decoded = jsonDecode(jsonText);
      setState(() {
        _shortcuts = decoded.map((s) => ShortcutInfo.fromJson(s)).toList();
      });
    } catch (e) {
      debugPrint('Error loading shortcuts: $e');
      _shortcuts = [];
    }
  }

  Future<void> _checkPendingShortcuts() async {
    try {
      final List<dynamic>? pending = await _shortcutChannel.invokeMethod('getPendingShortcuts');
      if (pending != null && pending.isNotEmpty) {
        for (final item in pending) {
          await _handleNewPinnedShortcut(Map<String, dynamic>.from(item));
        }
      }
    } catch (e) {
      debugPrint('Error checking pending shortcuts: $e');
    }
  }

  Future<void> _handleNewPinnedShortcut(Map<String, dynamic> data) async {
    final String id = data['id'];
    final String packageName = data['packageName'];
    final String label = data['label'];
    final Uint8List iconBytes = data['iconBytes'];

    // Save icon to local file
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final iconDir = Directory('${appDocsDir.path}/shortcut_icons');
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }
      final iconFile = File('${iconDir.path}/${packageName}_$id.png');
      await iconFile.writeAsBytes(iconBytes);
    } catch (e) {
      debugPrint('Error saving shortcut icon: $e');
    }

    // Add to shortcuts list
    setState(() {
      // Check if already exists, if so update it
      final existingIndex = _shortcuts.indexWhere((s) => s.id == id && s.packageName == packageName);
      if (existingIndex != -1) {
        _shortcuts[existingIndex] = _shortcuts[existingIndex].copyWith(
          displayName: label,
          label: label,
        );
      } else {
        // Find max order to place it at the end
        int maxOrder = -1;
        for (final f in _folders) {
          if (f.order > maxOrder) maxOrder = f.order;
        }
        for (final s in _shortcuts) {
          if (s.order > maxOrder) maxOrder = s.order;
        }
        _shortcuts.add(ShortcutInfo(
          id: id,
          packageName: packageName,
          displayName: label,
          label: label,
          order: maxOrder + 1,
        ));
      }
      _saveShortcuts();
    });
  }

  void _saveShortcuts() {
    final jsonText = jsonEncode(_shortcuts.map((s) => s.toJson()).toList());
    widget.prefs.setString('shortcuts', jsonText);
  }

  Future<void> _launchShortcut(ShortcutInfo shortcut) async {
    try {
      await _shortcutChannel.invokeMethod('launchShortcut', {
        'packageName': shortcut.packageName,
        'shortcutId': shortcut.id,
      });
      setState(() {
        _expandedFolders.clear(); // Close all folders
      });
    } catch (e) {
      debugPrint('Error launching shortcut: $e');
    }
  }

  Future<void> _showShortcutOptionsDialog(ShortcutInfo shortcut) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            shortcut.name,
            style: const TextStyle(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.renameApp),
                onTap: () => Navigator.pop(context, 'rename'),
              ),
              if (shortcut.customName != null)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(AppLocalizations.of(context)!.resetAppName),
                  onTap: () => Navigator.pop(context, 'reset'),
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(AppLocalizations.of(context)!.removeWallpaper), // We reuse the "Remove" wording
                onTap: () => Navigator.pop(context, 'remove'),
              ),
              ListTile(
                leading: const Icon(Icons.reorder),
                title: Text(AppLocalizations.of(context)!.reOrderApps),
                onTap: () => Navigator.pop(context, 'reorder'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    switch (result) {
      case 'rename':
        final newName = await _showRenameShortcutDialog(shortcut);
        if (newName != null && newName.trim().isNotEmpty) {
          setState(() {
            final index = _shortcuts.indexWhere((s) => s.id == shortcut.id && s.packageName == shortcut.packageName);
            if (index != -1) {
              _shortcuts[index] = _shortcuts[index].copyWith(customName: newName.trim());
              _saveShortcuts();
            }
          });
        }
        break;
      case 'reset':
        setState(() {
          final index = _shortcuts.indexWhere((s) => s.id == shortcut.id && s.packageName == shortcut.packageName);
          if (index != -1) {
            _shortcuts[index] = _shortcuts[index].copyWith(customName: null);
            _saveShortcuts();
          }
        });
        break;
      case 'remove':
        await _removeShortcut(shortcut);
        break;
      case 'reorder':
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return ReorderAppsScreen(prefs: widget.prefs);
            },
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        _reloadData();
        break;
    }
  }

  Future<String?> _showRenameShortcutDialog(ShortcutInfo shortcut) async {
    final controller = TextEditingController(text: shortcut.name);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.renameApp),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: shortcut.displayName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeShortcut(ShortcutInfo shortcut) async {
    setState(() {
      _shortcuts.removeWhere((s) => s.id == shortcut.id && s.packageName == shortcut.packageName);
      _saveShortcuts();
    });

    // Notify Android system
    try {
      await _shortcutChannel.invokeMethod('unpinShortcut', {
        'packageName': shortcut.packageName,
        'shortcutId': shortcut.id,
      });
    } catch (e) {
      debugPrint('Error notifying android of shortcut removal: $e');
    }

    // Delete icon file
    try {
      if (_appDocsDirPath != null) {
        final file = File('$_appDocsDirPath/shortcut_icons/${shortcut.packageName}_${shortcut.id}.png');
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    } catch (e) {
      debugPrint('Error deleting shortcut icon file: $e');
    }
  }

  Widget _buildShortcutItem(int index, ShortcutInfo shortcut) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchShortcut(shortcut),
        onLongPress: () => _showShortcutOptionsDialog(shortcut),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            minHeight: _appIconSize + 16.0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: _buildListShortcutItem(shortcut),
        ),
      ),
    );
  }

  Widget _buildListShortcutItem(ShortcutInfo shortcut) {
    final textAlign = _getAppTextAlign();

    final textContent = Text(
      shortcut.name,
      style: TextStyle(
        fontSize: _appFontSize,
        fontWeight: FontWeight.normal,
        color: _overlayTextColor,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: textAlign,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: _getAppItemAlignment(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_showIcons)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Container(
                      width: _appIconSize,
                      height: _appIconSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Builder(
                          builder: (context) {
                            final iconPath = _appDocsDirPath != null
                                ? '$_appDocsDirPath/shortcut_icons/${shortcut.packageName}_${shortcut.id}.png'
                                : '';
                            final iconFile = File(iconPath);
                            final imageWidget = iconPath.isNotEmpty && iconFile.existsSync()
                                ? Image.file(
                                    iconFile,
                                    width: _appIconSize,
                                    height: _appIconSize,
                                    cacheHeight: _appIconSize.toInt(),
                                    cacheWidth: _appIconSize.toInt(),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  )
                                : Icon(
                                    Icons.link,
                                    size: _appIconSize * 0.7,
                                    color: Colors.black,
                                  );
                            return _colorMode
                                ? imageWidget
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0,      0,      0,      1, 0,
                                    ]),
                                    child: imageWidget,
                                  );
                          },
                        ),
                      ),
                    ),
                  ),
                Flexible(
                  child: textContent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppItem(AppInfo app) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          InstalledApps.startApp(app.packageName);
          setState(() {
            _expandedFolders.clear(); // Close all folders
          });
        },
        onLongPress: () => _showAppOptionsDialog(app),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            minHeight: _appIconSize + 16.0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: _buildListAppItem(app),
        ),
      ),
    );
  }

  Widget _buildListAppItem(AppInfo app) {
    // Find notification for this app (filter out ongoing notifications)
    final notification = _notifications.values
        .where((n) => n.packageName == app.packageName && !n.onGoing)
        .firstOrNull;

    final textAlign = _getAppTextAlign();
    final columnAlignment = _getAppColumnAlignment();

    final textContent = notification != null
        ? Column(
            crossAxisAlignment: columnAlignment,
            children: [
              Text(
                app.displayName,
                style: TextStyle(
                  fontSize: _appFontSize,
                  fontWeight: FontWeight.normal,
                  color: _overlayTextColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: textAlign,
              ),
              Text(
                notification.content,
                style: TextStyle(
                  fontSize: _appFontSize - 5,
                  color: _overlayTextColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: textAlign,
              ),
            ],
          )
        : Text(
            app.displayName,
            style: TextStyle(
              fontSize: _appFontSize,
              fontWeight: FontWeight.normal,
              color: _overlayTextColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: textAlign,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: _getAppItemAlignment(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_showIcons && app.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Container(
                      width: _appIconSize,
                      height: _appIconSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: _colorMode
                            ? Image.memory(
                                app.icon!,
                                width: _appIconSize,
                                height: _appIconSize,
                                cacheHeight: _appIconSize.toInt(),
                                cacheWidth: _appIconSize.toInt(),
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                            : ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: Image.memory(
                                  app.icon!,
                                  width: _appIconSize,
                                  height: _appIconSize,
                                  cacheHeight: _appIconSize.toInt(),
                                  cacheWidth: _appIconSize.toInt(),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                      ),
                    ),
                  ),
                Flexible(
                  child: textContent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Alignment _getAppItemAlignment() {
    switch (_appAlignment) {
      case AppAlignment.left:
        return Alignment.centerLeft;
      case AppAlignment.center:
        return Alignment.center;
      case AppAlignment.right:
        return Alignment.centerRight;
    }
  }

  TextAlign _getAppTextAlign() {
    switch (_appAlignment) {
      case AppAlignment.left:
        return TextAlign.left;
      case AppAlignment.center:
        return TextAlign.center;
      case AppAlignment.right:
        return TextAlign.right;
    }
  }

  CrossAxisAlignment _getAppColumnAlignment() {
    switch (_appAlignment) {
      case AppAlignment.left:
        return CrossAxisAlignment.start;
      case AppAlignment.center:
        return CrossAxisAlignment.center;
      case AppAlignment.right:
        return CrossAxisAlignment.end;
    }
  }

  IconData _getBatteryIcon(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 70) return Icons.battery_6_bar;
    if (level >= 50) return Icons.battery_5_bar;
    if (level >= 30) return Icons.battery_4_bar;
    if (level >= 20) return Icons.battery_3_bar;
    if (level >= 10) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Stack(
          children: [
            // Wallpaper layer
            if (_wallpaperPath != null)
              Positioned.fill(
                child: _buildBlurredWallpaper(),
              ),
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Keep wallpaper visible in both loading and loaded states
                      if (_wallpaperPath != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _buildBlurredWallpaper(),
                          ),
                        ),
                      _buildAppList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
