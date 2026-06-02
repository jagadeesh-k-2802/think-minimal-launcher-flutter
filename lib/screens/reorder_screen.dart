import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/models/folder.dart';
import 'package:think_launcher/models/app_info.dart';
import 'package:think_launcher/services/icon_pack_service.dart';
import 'package:installed_apps/installed_apps.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/models/reorderable_item.dart';
import 'package:think_launcher/models/shortcut_info.dart';

class ReorderAppsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Folder? folder;

  const ReorderAppsScreen({super.key, required this.prefs, this.folder});

  @override
  State<ReorderAppsScreen> createState() => _ReorderAppsScreenState();
}

class _ReorderAppsScreenState extends State<ReorderAppsScreen> {
  late List<ReorderableItem> _items;
  final Map<String, AppInfo> _appInfoCache = {};
  List<Folder> _folders = [];
  List<ShortcutInfo> _shortcuts = [];
  String? _appDocsDirPath;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  late double _appIconSize;
  late double _appFontSize;
  late bool _colorMode;

  @override
  void initState() {
    super.initState();
    _items = [];
    _loadSettings();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshAppInfoWithCustomNames();
  }

  void _loadSettings() {
    _appIconSize = widget.prefs.getDouble('appIconSize') ?? 18.0;
    _appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
    _colorMode = widget.prefs.getBool('colorMode') ?? true;
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final docsDir = await getApplicationDocumentsDirectory();
      _appDocsDirPath = docsDir.path;

      await _loadFolders();
      await _preloadAppInfo();
      _rebuildItems();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.errorLoadingApps;
      });
    }
  }

  Future<void> _loadFolders() async {
    try {
      final foldersJson = widget.prefs.getString('folders') ?? '[]';
      final List<dynamic> decoded = jsonDecode(foldersJson);
      _folders = decoded.map((f) => Folder.fromJson(f)).toList();
    } catch (e) {
      debugPrint('Error loading folders: $e');
      _folders = [];
    }
  }

  void _refreshAppInfoWithCustomNames() {
    final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
    final customNames = Map<String, String>.from(jsonDecode(customNamesJson));

    for (final packageName in _appInfoCache.keys) {
      final app = _appInfoCache[packageName]!;
      final customName = customNames[packageName];
      if (customName != null) {
        _appInfoCache[packageName] = app.copyWith(customName: customName);
      } else {
        _appInfoCache[packageName] = app.copyWith(customName: null);
      }
    }

    _rebuildItems();
  }

  /// Rebuilds the list of items based on the current mode.
  /// This handles three modes:
  /// 1. Folder mode: Shows only apps within a specific folder
  /// 2. Main screen mode: Shows folders and unorganized apps
  void _rebuildItems() {
    try {
      if (widget.folder != null) {
        // Folder mode: show only apps in the folder
        final folderApps = widget.folder!.appPackageNames;
        setState(() {
          _items = folderApps
              .where((packageName) => _appInfoCache.containsKey(packageName))
              .map((packageName) => ReorderableItem.fromApp(
                    _appInfoCache[packageName]!,
                    order: folderApps.indexOf(packageName),
                  ))
              .toList();
        });
      } else {
        // Main screen mode: show folders, shortcuts, and unorganized apps in their correct order
        final selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
        final foldersJson = widget.prefs.getString('folders') ?? '[]';
        final List<dynamic> decodedFolders = jsonDecode(foldersJson);
        _folders = decodedFolders.map((f) => Folder.fromJson(f)).toList();

        final shortcutsJson = widget.prefs.getString('shortcuts') ?? '[]';
        final List<dynamic> decodedShortcuts = jsonDecode(shortcutsJson);
        _shortcuts =
            decodedShortcuts.map((s) => ShortcutInfo.fromJson(s)).toList();

        // Map packageName → appInfo
        final appMap = _appInfoCache;

        // Collect apps in folders
        final appsInFolders =
            _folders.expand((folder) => folder.appPackageNames).toSet();

        // Unorganized apps in existing order
        final unorganizedApps = selectedApps
            .where((pkg) =>
                !appsInFolders.contains(pkg) && appMap.containsKey(pkg))
            .toList();

        // Sort folders and shortcuts together by order
        final List<dynamic> orderedItems = [..._folders, ..._shortcuts];
        orderedItems.sort((a, b) {
          int aOrder = a is Folder ? a.order : (a as ShortcutInfo).order;
          int bOrder = b is Folder ? b.order : (b as ShortcutInfo).order;
          return aOrder.compareTo(bOrder);
        });

        final List<ReorderableItem> items = [];

        int currentIndex = 0;
        int unorganizedIndex = 0;

        for (final item in orderedItems) {
          int targetOrder =
              item is Folder ? item.order : (item as ShortcutInfo).order;

          if (item is Folder && item.appPackageNames.isEmpty) {
            continue;
          }

          // Place unorganized apps until reaching this item’s order
          while (currentIndex < targetOrder &&
              unorganizedIndex < unorganizedApps.length) {
            final pkg = unorganizedApps[unorganizedIndex];
            items.add(
                ReorderableItem.fromApp(appMap[pkg]!, order: currentIndex));
            unorganizedIndex++;
            currentIndex++;
          }

          // Place the folder or shortcut
          if (item is Folder) {
            items.add(ReorderableItem.fromFolder(item, order: currentIndex));
          } else if (item is ShortcutInfo) {
            items.add(ReorderableItem.fromShortcut(item, order: currentIndex));
          }
          currentIndex++;
        }

        // Place remaining unorganized apps
        while (unorganizedIndex < unorganizedApps.length) {
          final pkg = unorganizedApps[unorganizedIndex];
          items.add(ReorderableItem.fromApp(appMap[pkg]!, order: currentIndex));
          unorganizedIndex++;
          currentIndex++;
        }

        // Final sort
        setState(() {
          _items = items..sort((a, b) => a.order.compareTo(b.order));
        });
      }
    } catch (e) {
      debugPrint('Error in _rebuildItems: $e');
    }
  }

  /// Preloads app information for all relevant apps based on the current mode.
  /// This includes apps in folders and unorganized apps for the main screen mode.
  Future<void> _preloadAppInfo() async {
    try {
      List<String> appPackageNames;

      if (widget.folder != null) {
        // Folder mode: load only folder apps
        appPackageNames = widget.folder!.appPackageNames;
      } else {
        // Main screen mode: load all apps (both in folders and unorganized)
        final selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
        final foldersJson = widget.prefs.getString('folders') ?? '[]';
        final List<dynamic> decodedFolders = jsonDecode(foldersJson);
        _folders = decodedFolders.map((f) => Folder.fromJson(f)).toList();

        // Get all apps (both in folders and unorganized)
        final appsInFolders = _folders.expand((f) => f.appPackageNames).toSet();
        appPackageNames = {...appsInFolders, ...selectedApps}.toList();
      }

      // Load app info in parallel for better performance
      final futures = appPackageNames
          .where((packageName) => !_appInfoCache.containsKey(packageName))
          .map((packageName) async {
        try {
          final app = await InstalledApps.getAppInfo(packageName);
          if (!mounted) return null;

          var appInfo = AppInfo.fromInstalledApps(app);

          // Apply icon pack override if configured
          appInfo =
              await IconPackService.applyIconPackToApp(appInfo, widget.prefs);
          final customNamesJson =
              widget.prefs.getString('customAppNames') ?? '{}';
          final customNames =
              Map<String, String>.from(jsonDecode(customNamesJson));
          final customName = customNames[packageName];

          return MapEntry(
            packageName,
            customName != null
                ? appInfo.copyWith(customName: customName)
                : appInfo,
          );
        } catch (e) {
          debugPrint('Error getting app info for $packageName: $e');
          return null;
        }
      });

      // Wait for all app info to load
      final results = await Future.wait(futures);

      // Update cache with successful results
      if (mounted) {
        setState(() {
          for (final result in results) {
            if (result != null) {
              _appInfoCache[result.key] = result.value;
            }
          }
        });

        // Reload folders to ensure we have the latest data
        final foldersJson = widget.prefs.getString('folders') ?? '[]';
        final List<dynamic> decodedFolders = jsonDecode(foldersJson);
        _folders = decodedFolders.map((f) => Folder.fromJson(f)).toList();

        // Rebuild items with updated cache and folders
        _rebuildItems();
      }
    } catch (e) {
      debugPrint('Error in _preloadAppInfo: $e');
    }
  }

  /// Saves the order of the apps and folders.
  /// This handles three modes:
  /// 1. Folder mode: Saves the order of the apps in the folder
  /// 2. Main screen mode: Saves the order of the apps and folders
  Future<void> _saveOrder() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.folder != null) {
        // Save folder app order
        final appPackageNames = _items
            .where((item) => item.type == ReorderableItemType.app)
            .map((item) => item.id)
            .toList();

        final updatedFolder =
            widget.folder!.copyWith(appPackageNames: appPackageNames);
        final folders =
            (jsonDecode(widget.prefs.getString('folders') ?? '[]') as List)
                .map((f) => Folder.fromJson(f))
                .toList();

        final index = folders.indexWhere((f) => f.id == widget.folder!.id);
        if (index != -1) {
          folders[index] = updatedFolder;
          final foldersJson =
              jsonEncode(folders.map((f) => f.toJson()).toList());
          await widget.prefs.setString('folders', foldersJson);
        }
      } else {
        // Save main screen order while preserving folder contents
        final currentFolders =
            (jsonDecode(widget.prefs.getString('folders') ?? '[]') as List)
                .map((f) => Folder.fromJson(f))
                .toList();

        // Create a map of folder ID to its contents
        final folderContents = {
          for (var folder in currentFolders) folder.id: folder.appPackageNames
        };

        // Go through the reordered items list, update order indices
        final List<Folder> reorderedFolders = [];
        final List<ShortcutInfo> reorderedShortcuts = [];
        final previousSelectedApps =
            widget.prefs.getStringList('selectedApps') ?? [];
        final List<String> allAppPackageNames = [];
        final Set<String> seenAppPackageNames = {};

        void addAppPackageName(String packageName) {
          if (seenAppPackageNames.add(packageName)) {
            allAppPackageNames.add(packageName);
          }
        }

        for (int i = 0; i < _items.length; i++) {
          final item = _items[i];
          if (item.type == ReorderableItemType.folder) {
            final folder = item.folder!;
            final folderAppPackageNames =
                folderContents[folder.id] ?? folder.appPackageNames;
            reorderedFolders.add(folder.copyWith(
              appPackageNames: folderAppPackageNames,
              order: i,
            ));
            for (final packageName in folderAppPackageNames) {
              addAppPackageName(packageName);
            }
          } else if (item.type == ReorderableItemType.shortcut) {
            final shortcut = item.shortcutInfo!;
            reorderedShortcuts.add(shortcut.copyWith(
              order: i,
            ));
          } else if (item.type == ReorderableItemType.app) {
            addAppPackageName(item.id);
          }
        }

        for (final packageName in previousSelectedApps) {
          addAppPackageName(packageName);
        }

        // Save the updated data
        final foldersJson =
            jsonEncode(reorderedFolders.map((f) => f.toJson()).toList());
        await widget.prefs.setString('folders', foldersJson);

        final shortcutsJson =
            jsonEncode(reorderedShortcuts.map((s) => s.toJson()).toList());
        await widget.prefs.setString('shortcuts', shortcutsJson);

        await widget.prefs.setStringList('selectedApps', allAppPackageNames);

        // Update local state
        setState(() {
          _folders = reorderedFolders;
          _shortcuts = reorderedShortcuts;
        });
      }

      // Add a small delay to show the saving indicator
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error saving order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingSettings),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildLoadingIndicator() {
    ThemeData theme = Theme.of(context);
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildErrorMessage() {
    ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage ?? AppLocalizations.of(context)!.errorLoadingApps,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadData,
              child: Text(AppLocalizations.of(context)!.save,
                  style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }

  String _shortcutIconPath(ShortcutInfo shortcut) {
    return '$_appDocsDirPath/shortcut_icons/${shortcut.packageName}_${shortcut.id}.png';
  }

  String _shortcutSourceIconPath(String packageName) {
    return '$_appDocsDirPath/shortcut_source_icons/$packageName.png';
  }

  Widget _buildShortcutIcon(ShortcutInfo shortcut, ThemeData theme) {
    final iconSize = _appIconSize * 0.9;
    final iconPath = _appDocsDirPath != null ? _shortcutIconPath(shortcut) : '';
    final file = File(iconPath);
    final baseIcon = iconPath.isNotEmpty && file.existsSync()
        ? Image.file(
            file,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          )
        : Icon(
            Icons.link,
            size: iconSize * 0.7,
            color: theme.colorScheme.onSurface,
          );
    final renderedIcon = _colorMode
        ? baseIcon
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
            child: baseIcon,
          );

    return _buildShortcutIconWithSourceBadge(
      shortcut,
      renderedIcon,
      iconSize,
    );
  }

  Widget _buildShortcutIconWithSourceBadge(
    ShortcutInfo shortcut,
    Widget baseIcon,
    double iconSize,
  ) {
    final sourceIconPath = _appDocsDirPath != null
        ? _shortcutSourceIconPath(shortcut.packageName)
        : '';
    final sourceIconFile = File(sourceIconPath);
    final hasSourceIcon =
        sourceIconPath.isNotEmpty && sourceIconFile.existsSync();
    final badgeSize = (iconSize * 0.68).clamp(7.0, 15.0).toDouble();
    final badgeContainerSize = badgeSize + 3;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: baseIcon,
          ),
        ),
        if (hasSourceIcon)
          Positioned(
            right: -5,
            bottom: -7,
            child: Container(
              width: badgeContainerSize,
              height: badgeContainerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(45),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.file(
                  sourceIconFile,
                  width: badgeSize,
                  height: badgeSize,
                  cacheHeight: badgeSize.ceil(),
                  cacheWidth: badgeSize.ceil(),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListItem(ReorderableItem item) {
    ThemeData theme = Theme.of(context);

    Widget? leadingIcon;
    if (item.type == ReorderableItemType.folder) {
      leadingIcon = Icon(
        Icons.folder,
        color: theme.colorScheme.onSurface.withAlpha(200),
        size: _appIconSize * 0.7,
      );
    } else if (item.type == ReorderableItemType.shortcut &&
        item.shortcutInfo != null) {
      leadingIcon = _buildShortcutIcon(item.shortcutInfo!, theme);
    } else if (item.appInfo?.icon != null) {
      final imageWidget = Image.memory(
        item.appInfo!.icon!,
        width: _appIconSize,
        height: _appIconSize,
        fit: BoxFit.cover,
      );
      leadingIcon = _colorMode
          ? imageWidget
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
              child: imageWidget,
            );
    }

    return Container(
      key: Key(item.id),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: ListTile(
          minVerticalPadding: 16,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drag_handle, color: theme.colorScheme.onSurface),
              const SizedBox(width: 16),
              if (leadingIcon != null)
                Container(
                  width: _appIconSize,
                  height: _appIconSize,
                  padding: EdgeInsets.all(_appIconSize * 0.15),
                  child: leadingIcon,
                ),
            ],
          ),
          title: Text(
            item.displayName,
            style: TextStyle(
              fontSize: _appFontSize,
              fontWeight: FontWeight.normal,
            ),
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
          appBar: AppBar(
            title: Text(widget.folder != null
                ? AppLocalizations.of(context)!.reorderAppsInFolder
                : AppLocalizations.of(context)!.reorderAppsFolders),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
              tooltip: AppLocalizations.of(context)!.back,
            ),
            actions: [
              if (_isSaving)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                ),
            ],
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
          ),
          body: SafeArea(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _errorMessage != null
                    ? _buildErrorMessage()
                    : _items.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.noAppsSelected,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface),
                            ),
                          )
                        : ReorderableListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) =>
                                _buildListItem(_items[index]),
                            onReorderItem: (oldIndex, newIndex) async {
                              setState(() {
                                final item = _items.removeAt(oldIndex);
                                _items.insert(newIndex, item);

                                // Update order values
                                for (int i = 0; i < _items.length; i++) {
                                  _items[i] = _items[i].copyWith(order: i);
                                }
                              });
                              // Auto-save after reordering
                              await _saveOrder();
                            },
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                elevation: 4,
                                color: theme.colorScheme.surface,
                                child: child,
                              );
                            },
                          ),
          ),
        ),
      ),
    );
  }
}
