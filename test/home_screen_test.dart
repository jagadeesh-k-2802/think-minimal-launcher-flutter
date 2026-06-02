import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/models/folder.dart';
import 'package:think_launcher/models/shortcut_info.dart';
import 'package:think_launcher/screens/main_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockPathProvider();
    mockBattery();
    mockGeolocator();
    mockNotificationListener();
    mockShortcutChannel();
  });

  tearDown(clearCommonMethodChannelMocks);

  testWidgets(
      'renders selected apps added to the home screen and launches them',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedApps': ['com.example.calculator', 'com.example.notes'],
      'showIcons': false,
      'showSearchButton': true,
      'folders': '[]',
      'shortcuts': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    final installedAppsCalls = <MethodCall>[];

    mockInstalledApps(
      calls: installedAppsCalls,
      apps: [
        installedApp(
          name: 'Calculator',
          packageName: 'com.example.calculator',
          installedTimestamp: 100,
        ),
        installedApp(
          name: 'Notes',
          packageName: 'com.example.notes',
          installedTimestamp: 200,
        ),
      ],
    );

    await tester.pumpWidget(wrapForTest(MainScreen(prefs: prefs)));
    await tester.pumpAndSettle();

    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);

    await tester.tap(find.text('Calculator'));
    await tester.pumpAndSettle();

    expect(
      installedAppsCalls.any(
        (call) =>
            call.method == 'startApp' &&
            (call.arguments as Map)['package_name'] == 'com.example.calculator',
      ),
      isTrue,
    );
  });

  testWidgets('app options create a folder containing the selected app',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedApps': ['com.home.create.calculator', 'com.home.create.notes'],
      'showIcons': false,
      'folders': '[]',
      'shortcuts': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    mockInstalledApps(
      apps: [
        installedApp(
          name: 'Calculator',
          packageName: 'com.home.create.calculator',
        ),
        installedApp(name: 'Notes', packageName: 'com.home.create.notes'),
      ],
    );

    await tester.pumpWidget(wrapForTest(MainScreen(prefs: prefs)));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Calculator'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Work');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final folders = jsonDecode(prefs.getString('folders')!) as List<dynamic>;
    final folder = folders.single as Map<String, dynamic>;
    expect(folder['name'], 'Work');
    expect(folder['appPackageNames'], ['com.home.create.calculator']);
  });

  testWidgets('app options move an app into an existing folder',
      (tester) async {
    const folder = Folder(
      id: 'folder-work',
      name: 'Work',
      appPackageNames: [],
      order: 0,
    );
    SharedPreferences.setMockInitialValues({
      'selectedApps': ['com.home.move.notes'],
      'showIcons': false,
      'folders': jsonEncode([folder.toJson()]),
      'shortcuts': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    mockInstalledApps(
      apps: [
        installedApp(name: 'Notes', packageName: 'com.home.move.notes'),
      ],
    );

    await tester.pumpWidget(wrapForTest(MainScreen(prefs: prefs)));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    final folders = jsonDecode(prefs.getString('folders')!) as List<dynamic>;
    final updatedFolder = folders.single as Map<String, dynamic>;
    expect(updatedFolder['appPackageNames'], ['com.home.move.notes']);
  });

  testWidgets('folder item expands, renames, and deletes from home',
      (tester) async {
    const folder = Folder(
      id: 'folder-personal',
      name: 'Work',
      appPackageNames: ['com.home.folder.calculator'],
      order: 0,
    );
    SharedPreferences.setMockInitialValues({
      'selectedApps': ['com.home.folder.calculator'],
      'showIcons': false,
      'folders': jsonEncode([folder.toJson()]),
      'shortcuts': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    mockInstalledApps(
      apps: [
        installedApp(
          name: 'Calculator',
          packageName: 'com.home.folder.calculator',
        ),
      ],
    );

    await tester.pumpWidget(wrapForTest(MainScreen(prefs: prefs)));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Calculator'), findsNothing);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(find.text('Calculator'), findsOneWidget);

    await tester.longPress(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Personal');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    var folders = jsonDecode(prefs.getString('folders')!) as List<dynamic>;
    expect((folders.single as Map<String, dynamic>)['name'], 'Personal');
    expect(find.text('Personal'), findsOneWidget);

    await tester.longPress(find.text('Personal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Folder').last);
    await tester.pumpAndSettle();

    folders = jsonDecode(prefs.getString('folders')!) as List<dynamic>;
    expect(folders, isEmpty);
    expect(find.text('Personal'), findsNothing);
    expect(find.text('Calculator'), findsOneWidget);
  });

  testWidgets('shortcut options rename, reset, and remove a shortcut',
      (tester) async {
    final shortcutCalls = <MethodCall>[];
    mockShortcutChannel(calls: shortcutCalls);
    final shortcut = ShortcutInfo(
      id: 'youtube',
      packageName: 'com.home.shortcut.creator',
      displayName: 'YouTube',
      label: 'YouTube',
      sourceAppName: 'Gspace',
      order: 1,
    );
    SharedPreferences.setMockInitialValues({
      'selectedApps': ['com.home.shortcut.calculator'],
      'showIcons': false,
      'folders': '[]',
      'shortcuts': jsonEncode([shortcut.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();
    mockInstalledApps(
      apps: [
        installedApp(
          name: 'Calculator',
          packageName: 'com.home.shortcut.calculator',
        ),
        installedApp(name: 'Gspace', packageName: 'com.home.shortcut.creator'),
      ],
    );

    await tester.pumpWidget(wrapForTest(MainScreen(prefs: prefs)));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename Shortcut'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'YT');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    var shortcuts = jsonDecode(prefs.getString('shortcuts')!) as List<dynamic>;
    expect((shortcuts.single as Map<String, dynamic>)['customName'], 'YT');
    expect(find.text('YT'), findsOneWidget);

    await tester.longPress(find.text('YT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset Shortcut Name'));
    await tester.pumpAndSettle();

    shortcuts = jsonDecode(prefs.getString('shortcuts')!) as List<dynamic>;
    expect((shortcuts.single as Map<String, dynamic>)['customName'], isNull);
    expect(find.text('YouTube'), findsOneWidget);

    await tester.longPress(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Shortcut'));
    await tester.pumpAndSettle();

    shortcuts = jsonDecode(prefs.getString('shortcuts')!) as List<dynamic>;
    expect(shortcuts, isEmpty);
    expect(find.text('YouTube'), findsNothing);
    expect(
      shortcutCalls.any((call) => call.method == 'unpinShortcut'),
      isTrue,
    );
  });
}
